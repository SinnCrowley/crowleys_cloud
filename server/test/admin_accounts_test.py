"""Administration account contract, including concurrent bootstrap and recovery."""
from concurrent.futures import ThreadPoolExecutor
import hashlib
import http.client
import json
import os
from pathlib import Path
import secrets
import socket
import sqlite3
import subprocess
import sys
import tempfile
import time

binary = Path(sys.argv[1]).resolve()


def run(mode='approval', hashed=False, environment_secrets=False):
    with tempfile.TemporaryDirectory(prefix='crowley-admin-') as tmp:
        root = Path(tmp)
        with socket.socket() as sock:
            sock.bind(('127.0.0.1', 0))
            port = sock.getsockname()[1]
        config = dict(host='127.0.0.1', port=port, storage_root=str(root/'storage'),
                      db_path=str(root/'db.sqlite'), temp_upload_dir=str(root/'uploads'),
                      public_dir=str(root/'public'), log_dir=str(root/'logs'),
                      jwt_secret=secrets.token_hex(32), registration_mode=mode,
                      hash_files=hashed, encryption_key=secrets.token_hex(32),
                      rate_limit_per_minute=1000, video_thumbs_enabled=False)
        config_path = root/'config.json'
        config_path.write_text(json.dumps(config))
        env = {k: v for k, v in os.environ.items() if k not in ('CROWLEYS_JWT_SECRET', 'CROWLEYS_ENCRYPTION_KEY')}
        if environment_secrets:
            env['CROWLEYS_JWT_SECRET'] = config['jwt_secret']
            env['CROWLEYS_ENCRYPTION_KEY'] = config['encryption_key']
        with (root/'output.log').open('w') as log:
            process = subprocess.Popen([str(binary), str(config_path)], stdout=log, stderr=log, env=env)
            def request(path, data=None, token=None, method=None):
                headers = {}
                if isinstance(data, dict):
                    data = json.dumps(data).encode()
                    headers['Content-Type'] = 'application/json'
                if token:
                    headers['Authorization'] = 'Bearer ' + token
                conn = http.client.HTTPConnection('127.0.0.1', port, timeout=15)
                try:
                    conn.request(method or ('POST' if data is not None else 'GET'), path, data, headers)
                    response = conn.getresponse()
                    raw = response.read()
                    try:
                        body = json.loads(raw) if raw and 'application/json' in response.getheader('Content-Type', '') else raw
                    except (ValueError, UnicodeDecodeError):
                        body = raw
                    return response.status, body
                finally:
                    conn.close()
            def ok(path, data=None, token=None, method=None):
                status, body = request(path, data, token, method)
                assert status < 300, (path, status, body)
                return body
            def login(name, password='test-password'):
                return ok('/api/login', dict(username=name, password=password))['access_token']
            try:
                for _ in range(100):
                    if process.poll() is not None:
                        raise AssertionError((root/'output.log').read_text())
                    try:
                        request('/api/account')
                        break
                    except OSError:
                        time.sleep(.05)
                names = [f'user{i}' for i in range(6)]
                with ThreadPoolExecutor(max_workers=6) as pool:
                    results = list(pool.map(lambda name: request('/api/register', dict(username=name, password='test-password')), names))
                active = [(name, body) for name, (status, body) in zip(names, results) if status == 200]
                if mode == 'open':
                    assert len(active) == 6
                else:
                    assert len(active) == 1, results
                admins = [(name, body) for name, body in active if body['user']['role'] == 'admin']
                assert len(admins) == 1
                admin_name, admin = admins[0]
                token, admin_id = admin['access_token'], admin['user']['id']
                assert request('/api/admin/users')[0] == 401
                assert request(f'/api/admin/users/{admin_id}', dict(role='user'), token, 'PATCH')[1]['code'] == 'last_admin'
                assert request(f'/api/admin/users/{admin_id}', dict(status='blocked'), token, 'PATCH')[1]['code'] == 'cannot_block_self'
                assert request('/api/account', token=token, method='DELETE')[0] == 409
                assert request(f'/api/admin/users/{admin_id}/reset-password', {}, token)[1]['code'] == 'last_admin'
                if mode == 'closed':
                    assert all(status == 403 for name, (status, _) in zip(names, results) if name != admin_name)
                    return
                if mode == 'approval':
                    pending = ok('/api/admin/applications', token=token)
                    assert len(pending) == 5
                    chosen = pending[0]
                    assert request('/api/login', dict(username=chosen['username'], password='test-password'))[1]['code'] == 'registration_pending'
                    ok(f"/api/admin/users/{chosen['id']}/approve", {}, token)
                    rejected = pending[1]
                    ok(f"/api/admin/users/{rejected['id']}/reject", {}, token)
                    assert request('/api/register', dict(username=rejected['username'], password='new'))[0] == 202
                else:
                    chosen = next(u for u in ok('/api/admin/users', token=token) if u['id'] != admin_id)
                uid = chosen['id']
                user = login(chosen['username'])
                assert request('/api/admin/users', token=user)[0] in (401, 403)
                sync = ok('/api/account/sync-token', token=token)['sync_token']
                assert request('/api/admin/users', token=sync)[0] in (401, 403)
                ok(f'/api/admin/users/{uid}', dict(role='admin', quota_bytes=1024), token, 'PATCH')
                assert ok('/api/account', token=user)['role'] == 'admin'
                ok('/api/admin/users', token=user)  # Existing token sees promotion.
                ok(f'/api/admin/users/{uid}', dict(role='user'), token, 'PATCH')
                assert request('/api/admin/users', token=user)[0] in (401, 403)
                ok(f'/api/admin/users/{uid}', dict(status='blocked'), token, 'PATCH')
                assert request('/api/account', token=user)[0] == 401
                assert request('/api/login', dict(username=chosen['username'], password='test-password'))[1]['code'] == 'account_blocked'
                ok(f'/api/admin/users/{uid}', dict(status='active'), token, 'PATCH')
                assert request('/api/account', token=user)[0] == 401  # Old token must stay revoked.
                user = login(chosen['username'])
                code = ok(f'/api/admin/users/{uid}/reset-password', {}, token)['code']
                assert request('/api/account', token=user)[0] == 401
                assert request('/api/login', dict(username=chosen['username'], password='test-password'))[1]['code'] == 'password_reset_required'
                with sqlite3.connect(root/'db.sqlite') as db:
                    stored = db.execute('SELECT code FROM password_resets WHERE user_id=?', (uid,)).fetchone()[0]
                assert stored != code and len(stored) == 64
                for _ in range(5):
                    assert request('/api/auth/reset-password/verify', dict(username=chosen['username'], code='wrong', new_password='updated'))[0] == 400
                assert request('/api/auth/reset-password/verify', dict(username=chosen['username'], code=code, new_password='updated'))[0] == 400
                code = ok(f'/api/admin/users/{uid}/reset-password', {}, token)['code']
                # A public request must not invalidate an admin-issued recovery code.
                ok('/api/auth/reset-password/request', dict(username=chosen['username']))
                ok('/api/auth/reset-password/verify', dict(username=chosen['username'], code=code, new_password='updated'))
                assert request('/api/auth/reset-password/verify', dict(username=chosen['username'], code=code, new_password='again'))[0] == 400
                user = login(chosen['username'], 'updated')
                ok(f'/api/admin/users/{uid}/revoke-sessions', {}, token)
                assert request('/api/account', token=user)[0] == 401
                code = ok(f'/api/admin/users/{uid}/reset-password', {}, token)['code']
                with sqlite3.connect(root/'db.sqlite') as db:
                    db.execute('UPDATE password_resets SET expires_at=0 WHERE user_id=?', (uid,))
                assert request('/api/auth/reset-password/verify', dict(username=chosen['username'], code=code, new_password='updated'))[0] == 400
                with sqlite3.connect(root/'db.sqlite') as db:
                    assert db.execute('SELECT count(*) FROM admin_audit').fetchone()[0] > 5
                # Reservations survive between chunks and account for parallel growth.
                ok(f'/api/admin/users/{admin_id}', dict(quota_bytes=10), token, 'PATCH')
                stats = ok('/api/account/stats', token=token)
                assert (stats['used_bytes'], stats['reserved_bytes'], stats['limit_bytes']) == (0, 0, 10), stats
                ok('/api/files?scope=private&path=partial&offset=0&total=6', b'abc', token)
                assert ok('/api/account', token=token)['reserved_bytes'] == 6
                assert request('/api/files?scope=private&path=too-big', b'12345', token)[1]['code'] == 'quota_exceeded'
                ok('/api/files?scope=private&path=small', b'1234', token)
                ok('/api/files?scope=private&path=partial&offset=3&total=6&is_last=true', b'def', token)
                account = ok('/api/account', token=token)
                assert (account['used_bytes'], account['reserved_bytes']) == (10, 0), account
                ok(f'/api/admin/users/{admin_id}', dict(quota_bytes=5), token, 'PATCH')
                ok('/api/files?scope=private&path=small', b'123', token)
                assert request('/api/files?scope=private&path=small', b'1234', token)[1]['code'] == 'quota_exceeded'
                ok('/api/files?scope=private', dict(paths=['partial']), token, 'DELETE')
                assert ok('/api/account', token=token)['used_bytes'] == 9
                trash = ok('/api/trash?scope=private', token=token)
                trash_items = trash['entries']
                ok('/api/trash', dict(ids=[item['id'] for item in trash_items]), token, 'DELETE')
                assert ok('/api/account', token=token)['used_bytes'] == 3
                # One of two competing 2-byte uploads can fit into the remaining 2 bytes.
                with ThreadPoolExecutor(max_workers=2) as pool:
                    statuses = list(pool.map(lambda path: request('/api/files?scope=private&path='+path, b'xx', token)[0], ['one', 'two']))
                assert sorted(statuses) == [201, 413], statuses
                ok(f'/api/admin/users/{admin_id}', dict(quota_bytes=0), token, 'PATCH')
                # Logical copies are charged separately even with identical blobs;
                # moving a copy into and out of trash must preserve its charge.
                before_copies = ok('/api/account', token=token)['used_bytes']
                ok('/api/files?scope=shared&path=shared-copy.txt', b'copy', token)
                ok('/api/files?scope=private&path=private-copy.txt', b'copy', token)
                assert ok('/api/account', token=token)['used_bytes'] == before_copies + 8
                ok('/api/files?scope=private', dict(paths=['private-copy.txt']), token, 'DELETE')
                assert ok('/api/account', token=token)['used_bytes'] == before_copies + 8
                copy_id = next(item['id'] for item in ok('/api/trash?scope=private', token=token)['entries'] if item['name'] == 'private-copy.txt')
                ok('/api/trash/restore', dict(ids=[copy_id]), token)
                assert ok('/api/account', token=token)['used_bytes'] == before_copies + 8
                assert ok('/api/files?scope=private&path=private-copy.txt', token=token) == b'copy'
                registration = ok('/api/register', dict(username='transfer', password='test-password'))
                if registration.get('status') == 'pending':
                    transfer_user = next(u for u in ok('/api/admin/applications', token=token) if u['username'] == 'transfer')
                    ok(f"/api/admin/users/{transfer_user['id']}/approve", {}, token)
                transfer_token = login('transfer')
                transfer_id = ok('/api/account', token=transfer_token)['id']
                ok('/api/files?scope=private&path=keep.txt', b'keep!', transfer_token)
                ok('/api/files?scope=private&path=private.txt', b'private', transfer_token)
                ok('/api/files/share?path=keep.txt&shared=true', b'', transfer_token)
                share = ok('/api/share', dict(scope='private', path='keep.txt'), transfer_token)['token']
                assert ok('/s/'+share+'/raw') == b'keep!'
                ok(f'/api/admin/users/{transfer_id}', dict(status='blocked'), token, 'PATCH')
                assert request('/s/'+share+'/raw')[0] == 404
                ok(f'/api/admin/users/{transfer_id}', dict(status='active'), token, 'PATCH')
                assert ok('/s/'+share+'/raw') == b'keep!'
                assert request('/api/account', token=transfer_token)[0] == 401
                transfer_token = login('transfer')
                ok(f'/api/admin/users/{admin_id}', dict(quota_bytes=1), token, 'PATCH')
                assert request(f'/api/admin/users/{transfer_id}', token=token, method='DELETE')[1]['code'] == 'quota_exceeded'
                assert ok('/api/account', token=transfer_token)['status'] == 'active'
                ok(f'/api/admin/users/{admin_id}', dict(quota_bytes=0), token, 'PATCH')
                if not hashed:
                    # A copy failure leaves the source account disabled and a durable job.
                    source = root/'storage'/'users'/str(transfer_id)/'keep.txt'
                    source.unlink()
                    assert request(f'/api/admin/users/{transfer_id}', token=token, method='DELETE')[1]['code'] == 'deletion_incomplete'
                    with sqlite3.connect(root/'db.sqlite') as db:
                        assert db.execute('SELECT phase FROM account_deletions WHERE user_id=?', (transfer_id,)).fetchone()[0] == 'copying'
                    source.write_bytes(b'keep!')
                    process.terminate()
                    process.wait(timeout=5)
                    process = subprocess.Popen([str(binary), str(config_path)], stdout=log, stderr=log, env=env)
                    for _ in range(100):
                        if process.poll() is not None:
                            raise AssertionError((root/'output.log').read_text())
                        try:
                            request('/api/account')
                            break
                        except OSError:
                            time.sleep(.05)
                else:
                    # Fail physical cleanup after the shared transfer commits.
                    # The disabled user must remain visible and retryable.
                    private_object = root/'storage'/'data'/hashlib.sha256(b'private').hexdigest()
                    backup = private_object.read_bytes()
                    private_object.unlink(); private_object.mkdir()
                    (private_object/'blocked').write_text('cleanup failure')
                    assert request(f'/api/admin/users/{transfer_id}', token=token, method='DELETE')[1]['code'] == 'deletion_incomplete'
                    assert next(u for u in ok('/api/admin/users', token=token) if u['id'] == transfer_id)['status'] == 'deleting'
                    with sqlite3.connect(root/'db.sqlite') as db:
                        assert db.execute('SELECT phase FROM account_deletions WHERE user_id=?', (transfer_id,)).fetchone()[0] == 'cleanup'
                    (private_object/'blocked').unlink(); private_object.rmdir(); private_object.write_bytes(backup)
                    ok(f'/api/admin/users/{transfer_id}', token=token, method='DELETE')
                assert request('/api/account', token=transfer_token)[0] == 401
                assert request('/s/'+share+'/raw')[0] == 404
                with sqlite3.connect(root/'db.sqlite') as db:
                    transferred = db.execute("SELECT rel_path FROM file_index WHERE owner_user_id=? AND is_shared=1 AND name='keep.txt'", (admin_id,)).fetchone()[0]
                    assert db.execute('SELECT count(*) FROM account_deletions').fetchone()[0] == 0
                    assert db.execute('SELECT count(*) FROM users WHERE id=?', (transfer_id,)).fetchone()[0] == 0
                assert ok('/api/files?scope=private&path='+transferred, token=token) == b'keep!'
                assert not (root/'storage'/'users'/str(transfer_id)).exists()
                if hashed and not environment_secrets:
                    def await_rotation():
                        for _ in range(400):
                            state = ok('/api/admin/maintenance', token=token)
                            if not state['running']:
                                return state
                            time.sleep(.025)
                        raise AssertionError('Rotation did not finish')
                    object_path = root/'storage'/'data'/hashlib.sha256(b'123').hexdigest()
                    before = object_path.read_bytes()
                    revision = ok('/api/admin/config', token=token)['revision']
                    ok('/api/admin/encryption-key', dict(revision=revision, secret=secrets.token_hex(32)), token)
                    state = await_rotation()
                    assert state['phase'] == 'complete' and not state['maintenance'], state
                    assert object_path.read_bytes() != before
                    assert ok('/api/files?scope=private&path=small', token=token) == b'123'
                    assert ok('/api/files?scope=private&path='+transferred, token=token) == b'keep!'
                    assert not (root/'encryption-rotation.keys.json').exists()
                    # Corruption must preserve maintenance and allow a safe retry after repair.
                    before = object_path.read_bytes()
                    object_path.write_bytes(b'broken ciphertext')
                    revision = ok('/api/admin/config', token=token)['revision']
                    ok('/api/admin/encryption-key', dict(revision=revision, secret=secrets.token_hex(32)), token)
                    state = await_rotation()
                    assert state['maintenance'] and state['error_code'], state
                    assert request('/api/files?scope=private&path=small', token=token)[0] == 503
                    assert ok('/api/account', token=token)['role'] == 'admin'
                    object_path.write_bytes(before)
                    ok('/api/admin/encryption-key/resume', {}, token)
                    state = await_rotation()
                    assert state['phase'] == 'complete' and not state['maintenance'], state
                    assert ok('/api/files?scope=private&path=small', token=token) == b'123'
                settings = ok('/api/admin/config', token=token)
                original_revision = settings['revision']
                fields = {field['name']: field for field in settings['fields']}
                assert fields['jwt_secret']['value'] is None and fields['encryption_key']['effective'] is None
                assert fields['registration_mode']['apply'] == 'live'
                saved = ok('/api/admin/config', dict(revision=original_revision, changes={'registration_mode': 'closed', 'default_quota_bytes': 2048, 'access_token_ttl_seconds': 60, 'refresh_token_ttl_seconds': 120}), token, 'PATCH')
                assert request('/api/register', dict(username='closed-now', password='test-password'))[1]['code'] == 'registration_closed'
                new_session = ok('/api/login', dict(username=admin_name, password='test-password'))
                assert 58 <= int(new_session['access_token'].split('|')[2]) - int(time.time()) <= 60
                assert int(token.split('|')[2]) > int(new_session['access_token'].split('|')[2])
                assert ok('/api/account', token=token)['role'] == 'admin'
                with sqlite3.connect(root/'db.sqlite') as db:
                    expiry = db.execute('SELECT expires_at FROM refresh_tokens WHERE token_hash=?', (hashlib.sha256(new_session['refresh_token'].encode()).hexdigest(),)).fetchone()[0]
                assert 118 <= expiry - int(time.time()) <= 120
                assert request('/api/admin/config', dict(revision=original_revision, changes={'registration_mode': 'open'}), token, 'PATCH')[0] == 409
                assert request('/api/admin/config', dict(revision=saved['revision'], changes={'port': 99999}), token, 'PATCH')[1]['code'] == 'invalid_config_value'
                assert request('/api/admin/config', dict(revision=saved['revision'], changes={'hash_files': not hashed}), token, 'PATCH')[1]['code'] == 'manual_migration_required'
                assert request('/api/admin/config', dict(revision=saved['revision'], changes={'jwt_secret': secrets.token_hex(32)}), token, 'PATCH')[1]['code'] == ('config_from_environment' if environment_secrets else 'rotation_required')
                with socket.socket() as sock:
                    sock.bind(('127.0.0.1', 0))
                    next_port = sock.getsockname()[1]
                saved = ok('/api/admin/config', dict(revision=saved['revision'], changes={'port': next_port}), token, 'PATCH')
                field = next(field for field in saved['fields'] if field['name'] == 'port')
                assert field['pending'] and field['effective'] == port and field['value'] == next_port
                assert json.loads(config_path.read_text())['port'] == port
                local = json.loads((root/'config.local.json').read_text())
                assert local['default_quota_bytes'] == 2048 and local['registration_mode'] == 'closed'
                if environment_secrets:
                    fields = {field['name']: field for field in saved['fields']}
                    assert fields['jwt_secret']['source'] == 'environment' and not fields['jwt_secret']['editable']
                    assert fields['encryption_key']['source'] == 'environment' and not fields['encryption_key']['editable']
                    assert request('/api/admin/signing-secret', dict(revision=saved['revision'], secret=secrets.token_hex(32)), token)[1]['code'] == 'config_from_environment'
                    assert request('/api/admin/encryption-key', dict(revision=saved['revision'], secret=secrets.token_hex(32)), token)[1]['code'] == 'config_from_environment'
                else:
                    reset_code = ok(f'/api/admin/users/{uid}/reset-password', {}, token)['code']
                    signing_secret = secrets.token_hex(32)
                    ok('/api/admin/signing-secret', dict(revision=saved['revision'], secret=signing_secret), token)
                    assert request('/api/auth/reset-password/verify', dict(username=chosen['username'], code=reset_code, new_password='must-not-work'))[0] == 400
                    assert request('/api/account', token=token)[0] == 401
                    assert request('/api/account', token=sync)[0] == 401
                    assert request('/api/refresh', dict(refresh_token=admin['refresh_token']))[0] == 401
                    token = login(admin_name)
                    assert ok('/api/account', token=token)['role'] == 'admin'
                    reset_code = ok(f'/api/admin/users/{uid}/reset-password', {}, token)['code']
                    ok('/api/auth/reset-password/verify', dict(username=chosen['username'], code=reset_code, new_password='recovered-again'))
                    assert request('/api/login', dict(username=chosen['username'], password='must-not-work'))[0] in (401, 403)
                    user = login(chosen['username'], 'recovered-again')
                # Saved infrastructure and live settings survive an actual restart.
                process.terminate(); process.wait(timeout=5)
                port = next_port
                process = subprocess.Popen([str(binary), str(config_path)], stdout=log, stderr=log, env=env)
                for _ in range(100):
                    assert process.poll() is None, (root/'output.log').read_text()
                    try:
                        request('/api/account')
                        break
                    except OSError:
                        time.sleep(.025)
                token = login(admin_name)
                restarted = {field['name']: field for field in ok('/api/admin/config', token=token)['fields']}
                assert restarted['port']['effective'] == next_port and not restarted['port']['pending']
                assert restarted['registration_mode']['effective'] == 'closed'
                assert restarted['default_quota_bytes']['effective'] == 2048
                print('Admin account, quota, deletion and configuration contracts passed:', mode, hashed, flush=True)
            finally:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()


for mode in ('approval', 'open', 'closed'):
    run(mode)
run('approval', True)

run('approval', True, True)
