"""Recover exact durable rotation checkpoints, with real encrypted objects and restarts.

No production failpoints: reconstruct each possible on-disk crash boundary while
stopped, then let the normal startup recovery validate it. Also kill the process
while an active download keeps rotation waiting, and simulate insufficient space
with a sparse file (without consuming the machine's free disk space).
"""
import contextlib
import hashlib
import http.client
import json
import os
from pathlib import Path
import secrets
import shutil
import socket
import sqlite3
import subprocess
import sys
import tempfile
import time

binary = Path(sys.argv[1]).resolve()
sha = lambda value: hashlib.sha256(value).hexdigest()

cleanup_kwargs = {'ignore_cleanup_errors': True} if sys.version_info >= (3, 10) else {}
with tempfile.TemporaryDirectory(prefix='crowley-rotation-recovery-', **cleanup_kwargs) as temporary:
    root = Path(os.path.realpath(temporary))
    with socket.socket() as sock:
        sock.bind(('127.0.0.1', 0))
        port = sock.getsockname()[1]
    config = dict(host='127.0.0.1', port=port, storage_root=str(root/'storage'),
                  db_path=str(root/'db.sqlite'), temp_upload_dir=str(root/'uploads'),
                  public_dir=str(root/'public'), log_dir=str(root/'logs'),
                  jwt_secret=secrets.token_hex(32), encryption_key=secrets.token_hex(32),
                  hash_files=True, registration_mode='approval', rate_limit_per_minute=10000,
                  video_thumbs_enabled=False)
    path = root/'config.json'
    path.write_text(json.dumps(config))
    env = {k: v for k, v in os.environ.items() if k not in ('CROWLEYS_JWT_SECRET', 'CROWLEYS_ENCRYPTION_KEY')}
    log = (root/'output.log').open('w')
    process = None
    token = None

    def request(route, data=None, method=None):
        headers = {'Authorization': 'Bearer ' + token} if token else {}
        if isinstance(data, dict):
            data = json.dumps(data).encode()
            headers['Content-Type'] = 'application/json'
        conn = http.client.HTTPConnection('127.0.0.1', port, timeout=10)
        try:
            conn.request(method or ('POST' if data is not None else 'GET'), route, data, headers)
            response = conn.getresponse()
            body = response.read()
            if 'application/json' in response.getheader('Content-Type', ''):
                body = json.loads(body)
            return response.status, body, dict(response.getheaders())
        finally:
            conn.close()

    def ok(*args, **kwargs):
        status, body, _ = request(*args, **kwargs)
        assert status < 300, (args[0], status, body)
        return body

    def create_sparse_oversized_file(path, size):
        if os.name == 'nt':
            import ctypes
            from ctypes import wintypes
            kernel32 = ctypes.WinDLL('kernel32', use_last_error=True)
            GENERIC_READ = 0x80000000
            GENERIC_WRITE = 0x40000000
            CREATE_ALWAYS = 2
            FILE_ATTRIBUTE_NORMAL = 0x80
            FSCTL_SET_SPARSE = 0x000900C4
            FILE_BEGIN = 0

            kernel32.CreateFileW.argtypes = [
                wintypes.LPCWSTR, wintypes.DWORD, wintypes.DWORD,
                wintypes.LPVOID, wintypes.DWORD, wintypes.DWORD, wintypes.HANDLE
            ]
            kernel32.CreateFileW.restype = wintypes.HANDLE

            kernel32.DeviceIoControl.argtypes = [
                wintypes.HANDLE, wintypes.DWORD,
                wintypes.LPVOID, wintypes.DWORD,
                wintypes.LPVOID, wintypes.DWORD,
                ctypes.POINTER(wintypes.DWORD), wintypes.LPVOID
            ]
            kernel32.DeviceIoControl.restype = wintypes.BOOL

            kernel32.SetFilePointerEx.argtypes = [
                wintypes.HANDLE, ctypes.c_int64,
                ctypes.POINTER(ctypes.c_int64), wintypes.DWORD
            ]
            kernel32.SetFilePointerEx.restype = wintypes.BOOL

            kernel32.SetEndOfFile.argtypes = [wintypes.HANDLE]
            kernel32.SetEndOfFile.restype = wintypes.BOOL

            kernel32.CloseHandle.argtypes = [wintypes.HANDLE]
            kernel32.CloseHandle.restype = wintypes.BOOL

            handle = kernel32.CreateFileW(
                str(path), GENERIC_READ | GENERIC_WRITE, 0, None,
                CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, None
            )
            if handle == -1 or handle == wintypes.HANDLE(-1).value:
                raise ctypes.WinError(ctypes.get_last_error())
            try:
                bytes_returned = wintypes.DWORD(0)
                if not kernel32.DeviceIoControl(
                    handle, FSCTL_SET_SPARSE,
                    None, 0, None, 0,
                    ctypes.byref(bytes_returned), None
                ):
                    raise ctypes.WinError(ctypes.get_last_error())

                li = ctypes.c_int64(size)
                if not kernel32.SetFilePointerEx(handle, li, None, FILE_BEGIN):
                    raise ctypes.WinError(ctypes.get_last_error())
                if not kernel32.SetEndOfFile(handle):
                    raise ctypes.WinError(ctypes.get_last_error())
            finally:
                kernel32.CloseHandle(handle)
        else:
            with open(path, 'wb') as f:
                f.truncate(size)

    def start():
        global process
        process = subprocess.Popen([str(binary), str(path)], stdout=log, stderr=log, env=env)
        for _ in range(200):
            assert process.poll() is None, (root/'output.log').read_text()
            try:
                request('/api/account')
                return
            except OSError:
                time.sleep(.025)
        raise AssertionError('Server did not start')

    def stop(kill=False):
        global process
        if process is None or process.poll() is not None:
            return
        process.kill() if kill else process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
        if os.name == 'nt':
            time.sleep(0.1)

    def settled():
        for _ in range(600):
            state = ok('/api/admin/maintenance')
            if not state['running']:
                return state
            time.sleep(.02)
        raise AssertionError('Rotation did not settle')

    def complete():
        state = settled()
        assert state['phase'] == 'complete' and not state['maintenance'], state
        assert not (root/'encryption-rotation.keys.json').exists()
        return state

    def rotate(key):
        revision = ok('/api/admin/config')['revision']
        ok('/api/admin/encryption-key', dict(revision=revision, secret=key))

    try:
        # Old schema: promote the earliest surviving account once; do not alter
        # existing users' activation state or promote again on later startups.
        with contextlib.closing(sqlite3.connect(root/'db.sqlite')) as db:
            db.execute("CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT UNIQUE NOT NULL, password_hash TEXT NOT NULL, role TEXT NOT NULL DEFAULT 'user', created_at INTEGER NOT NULL)")
            for uid, name, created in [(7, 'first', 100), (2, 'second', 200)]:
                db.execute('INSERT INTO users VALUES(?,?,?,?,?)', (uid, name, sha(b'pw|test-password'), 'user', created))
            db.commit()
        start()
        token = ok('/api/login', dict(username='first', password='test-password'))['access_token']
        server_config = {field['name']: field['effective'] for field in ok('/api/admin/config')['fields']}
        config['storage_root'] = server_config['storage_root']
        people = ok('/api/admin/users')
        assert [(u['username'], u['role'], u['status']) for u in sorted(people, key=lambda u: u['created_at'])] == [('first', 'superuser', 'active'), ('second', 'user', 'active')]
        # Move the role to the other account, proving restart does not re-bootstrap.
        ok('/api/admin/users/2', dict(role='admin'), 'PATCH')
        assert request('/api/admin/users/7', dict(role='user'), method='PATCH')[1]['code'] == 'cannot_modify_superuser'
        stop(); start()
        assert next(u for u in ok('/api/admin/users') if u['id'] == 7)['role'] == 'superuser'
        contents = {'private.txt': b'private plaintext', 'shared.txt': b'shared plaintext', 'trash.txt': b'trash plaintext'}
        for name, data in contents.items():
            ok('/api/files?scope=private&path=' + name, data)
        ok('/api/files/share?path=shared.txt&shared=true', b'')
        share = ok('/api/share', dict(scope='private', path='shared.txt'))['token']
        ok('/api/files?scope=private', dict(paths=['trash.txt']), 'DELETE')
        trash_id = ok('/api/trash?scope=private')['entries'][0]['id']
        objects = root/'storage'/'data'
        old = {p.name: p.read_bytes() for p in objects.iterdir() if len(p.name) == 64}
        old_key, new_key = config['encryption_key'], secrets.token_hex(32)
        rotate(new_key); complete()
        new = {p.name: p.read_bytes() for p in objects.iterdir() if len(p.name) == 64}
        assert old.keys() == new.keys() and all(old[k] != new[k] for k in old)

        def verify_files():
            assert ok('/api/files?scope=private&path=private.txt') == contents['private.txt']
            assert ok('/s/' + share + '/raw') == contents['shared.txt']
            assert ok('/api/files?trash_id=' + str(trash_id)) == contents['trash.txt']

        verify_files(); stop()
        stages = ['keys_only', 'pending_copy', 'prepared', 'replaced', 'done', 'finalizing', 'config_switched', 'complete_key_retained', 'missing_keys']
        for stage in stages:
            config['encryption_key'] = old_key
            path.write_text(json.dumps(config))
            local = {'encryption_key': new_key} if stage in ('config_switched', 'complete_key_retained') else {}
            (root/'config.local.json').write_text(json.dumps(local))
            keys = dict(job_id=secrets.token_hex(16), actor=2, old_key=old_key, new_key=new_key,
                        storage_root=config['storage_root'], hash_files=True)
            keyfile = root/'encryption-rotation.keys.json'
            keyfile.write_text(json.dumps(keys)); keyfile.chmod(0o600)
            with contextlib.closing(sqlite3.connect(root/'db.sqlite')) as db:
                db.execute('DELETE FROM encryption_objects'); db.execute('DELETE FROM encryption_rotation')
                phase = 'complete' if stage == 'complete_key_retained' else 'finalizing' if stage in ('finalizing', 'config_switched') else 'rotating'
                if stage != 'keys_only':
                    db.execute('INSERT INTO encryption_rotation VALUES(1,?,?,?,?,?)', (keys['job_id'], phase, 2, int(time.time()), ''))
                for name, before in old.items():
                    after = new[name]
                    replaced = stage in ('replaced', 'done', 'finalizing', 'config_switched', 'complete_key_retained', 'missing_keys')
                    (objects/name).write_bytes(after if replaced else before)
                    staged = objects/(name+'.rotate-new')
                    staged.unlink(missing_ok=True)
                    if stage == 'pending_copy': staged.write_bytes(b'partial interrupted ciphertext')
                    if stage == 'prepared': staged.write_bytes(after)
                    if stage != 'keys_only':
                        state = 'pending' if stage == 'pending_copy' else 'prepared' if stage in ('prepared', 'replaced') else 'done'
                        plain_size = next(len(data) for data in contents.values() if sha(data) == name)
                        db.execute('INSERT INTO encryption_objects VALUES(?,?,?,?,?,?)',
                                   (name, state, len(before), plain_size, sha(before), sha(after)))
                db.commit()
            if stage == 'missing_keys': keyfile.unlink()
            start()
            if stage == 'missing_keys':
                state = settled()
                assert state['maintenance'] and state['error_code'] == 'rotation_keys_unreadable', state
                keyfile.write_text(json.dumps(keys)); keyfile.chmod(0o600)
                ok('/api/admin/encryption-key/resume', {})
            complete(); verify_files()
            assert not list(objects.glob('*.rotate-new')), stage
            stop()
            print('Recovered checkpoint:', stage, flush=True)

        # A sparse oversized object makes the real free-space check fail, without
        # filling the disk. Restoring its ciphertext is the operator's repair.
        start()
        name = sha(contents['private.txt']); backup = (objects/name).read_bytes()
        create_sparse_oversized_file(objects/name, shutil.disk_usage(objects).free + 1024 * 1024)
        print('Sparse oversized file created, rotating...', flush=True)
        rotate(secrets.token_hex(32))
        state = settled()
        assert state['maintenance'] and state['error_code'] == 'rotation_disk_full', state
        status, body, headers = request('/s/' + share + '/raw')
        assert status == 503 and body['code'] == 'maintenance'
        assert any(k.lower() == 'retry-after' for k in headers)
        assert ok('/api/account')['role'] == 'superuser'
        (objects/name).write_bytes(backup)
        stop(kill=True); start(); complete(); verify_files()
        print('Insufficient space preserves maintenance; restart resumes after repair.', flush=True)
        print('Testing streaming download during rotation...', flush=True)

        # A real streamed download must keep the old key/object readable until
        # its response finishes. New reads fail with a retryable maintenance code.
        large = b'0123456789abcdef' * (1024 * 1024)
        ok('/api/files?scope=private&path=large.bin', large)
        def streaming_download():
            conn = http.client.HTTPConnection('127.0.0.1', port, timeout=20)
            conn.connect()
            conn.sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 65536)
            conn.request('GET', '/api/files?scope=private&path=large.bin', headers={'Authorization': 'Bearer ' + token})
            response = conn.getresponse()
            assert response.status == 200
            return conn, response
        conn, response = streaming_download()
        rotate(secrets.token_hex(32))
        state = ok('/api/admin/maintenance')
        assert state['maintenance'] and state['running'] and state['files_done'] == 0, state
        assert request('/api/files?scope=private&path=private.txt')[0] == 503
        assert response.read() == large
        conn.close(); complete(); verify_files()
        conn, response = streaming_download()
        rotate(secrets.token_hex(32))
        assert ok('/api/admin/maintenance')['maintenance']
        stop(kill=True)
        response.close(); conn.close()
        start(); complete(); verify_files()
        assert ok('/api/files?scope=private&path=large.bin') == large
        print('Active download drains safely; forced process exit resumes rotation.', flush=True)
    finally:
        stop()
        log.close()
