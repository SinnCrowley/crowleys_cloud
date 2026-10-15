"""End-to-end regressions against a disposable loopback server (stdlib only)."""
import base64
import contextlib
import http.client
import io
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
from urllib.parse import urlencode
import zipfile

binary = Path(sys.argv[1]).resolve()

cleanup_kwargs = {'ignore_cleanup_errors': True} if sys.version_info >= (3, 10) else {}

def run(hash_files):
    with tempfile.TemporaryDirectory(prefix='crowley-http-test-', **cleanup_kwargs) as tmp:
        root = Path(tmp)
        with socket.socket() as sock:
            sock.bind(('127.0.0.1', 0))
            port = sock.getsockname()[1]
        config = dict(host='127.0.0.1', port=port, storage_root=str(root/'storage'),
                      db_path=str(root/'db.sqlite'), temp_upload_dir=str(root/'uploads'),
                      public_dir=str(root/'public'), log_dir=str(root/'logs'),
                      hash_files=hash_files, jwt_secret=secrets.token_hex(32),
                      encryption_key=secrets.token_hex(32), rate_limit_per_minute=20,
                      trash_retention_days=7, video_thumbs_enabled=False)
        config_path = root/'config.json'
        config_path.write_text(json.dumps(config))
        env = {k:v for k,v in os.environ.items() if k not in ('CROWLEYS_JWT_SECRET', 'CROWLEYS_ENCRYPTION_KEY')}
        with (root/'output.log').open('w') as log:
            process = subprocess.Popen([str(binary), str(config_path)], stdout=log, stderr=log, env=env)
            def request(path, data=None, token=None, method=None, close=False, extra_headers=None):
                headers = {}
                if isinstance(data, dict):
                    data = json.dumps(data).encode(); headers['Content-Type'] = 'application/json'
                elif data is not None:
                    headers['Content-Type'] = 'application/octet-stream'
                if token: headers['Authorization'] = 'Bearer '+token
                if close: headers['Connection'] = 'close'
                if extra_headers: headers.update(extra_headers)
                conn = http.client.HTTPConnection('127.0.0.1', port, timeout=8)
                try:
                    conn.request(method or ('POST' if data is not None else 'GET'), path, data, headers)
                    response = conn.getresponse()
                    return response.status, response.read()
                finally: conn.close()
            def obj(*args, **kw):
                status, body = request(*args, **kw)
                assert status < 300, (status, body)
                return json.loads(body)
            try:
                for _ in range(100):
                    if process.poll() is not None: raise AssertionError((root/'output.log').read_text())
                    try: request('/'); break
                    except OSError: time.sleep(.05)
                token = obj('/api/register', {'username':'review', 'password':'test-password'})['access_token']
                def upload(path, content, extra_headers=None, **params):
                    return request('/api/files?'+urlencode(dict(scope='private',path=path,**params)),content,token,extra_headers=extra_headers)
                def upload_multipart(path, file_data, thumb_data=None):
                    boundary = '----WebKitFormBoundary' + secrets.token_hex(16)
                    parts = []
                    parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{path}"\r\nContent-Type: video/mp4\r\n\r\n'.encode() + file_data + b'\r\n')
                    if thumb_data is not None:
                        parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="thumbnail"; filename="thumb.webp"\r\nContent-Type: image/webp\r\n\r\n'.encode() + thumb_data + b'\r\n')
                    parts.append(f'--{boundary}--\r\n'.encode())
                    body = b''.join(parts)
                    return request('/api/files?' + urlencode(dict(scope='private', path=path)), body, token, extra_headers={'Content-Type': f'multipart/form-data; boundary={boundary}'})
                def download(path, **kw):
                    return request('/api/files?'+urlencode(dict(scope='private',path=path)),token=token,**kw)
                for content in (b'hello world', b'x'*150001, b''):
                    assert upload('file.txt',content)[0] == 201
                    for close in (False, True): assert download('file.txt',close=close) == (200,content)
                assert upload('chunks.txt',b'ABC',offset=0,total=9)[0] < 300
                assert upload('chunks.txt',b'DEF',offset=3,total=9)[0] < 300
                assert upload('chunks.txt',b'DEF',offset=3,total=9)[0] == 409
                assert upload('chunks.txt',b'GHI',offset=6,total=9,is_last='true')[0] == 201
                assert download('chunks.txt',close=True) == (200,b'ABCDEFGHI')
                assert upload('bad.txt',b'AB',offset=0,total=9,is_last='true')[0] == 400

                # Video Thumbnail Ingestion Tests
                webp_bytes = b'RIFF<\x00\x00\x00WEBPVP8 0\x00\x00\x00\xd0\x01\x00\x9d\x01*\x04\x00\x04\x00\x01@&%\xa0\x02t\xba\x01\xf8\x00\x03\xb0\x00\xfe\xf2\xeb\x7f\xfc\xd8\x15\xcds\xef\xf7\xff\xd2\xe0\xfd.\x0f\xd2\xe0\xff\xd2\x90\x00\x00'
                webp_b64 = 'UklGRjwAAABXRUJQVlA4IDAAAADQAQCdASoEAAQAAUAmJaACdLoB+AADsAD+8ut//NgVzXPv9//S4P0uD9Lg/9KQAAA='

                # 1. Multipart single upload with thumbnail part
                status, _ = upload_multipart('video_client.mp4', b'DUMMY_MP4_VIDEO_STREAM', webp_bytes)
                assert status == 201
                status, thumb_body = request('/api/thumb?' + urlencode(dict(scope='private', path='video_client.mp4', s=256)), token=token)
                assert status == 200, f'Expected 200 for multipart client thumbnail, got {status}'
                assert thumb_body == webp_bytes

                # 2. Chunked upload with X-Thumbnail header on final chunk
                assert upload('chunk_vid.mp4', b'PART1', offset=0, total=10)[0] < 300
                status, _ = upload('chunk_vid.mp4', b'PART2', offset=5, total=10, is_last='true', extra_headers={'X-Thumbnail': webp_b64})
                assert status == 201
                status, thumb_body = request('/api/thumb?' + urlencode(dict(scope='private', path='chunk_vid.mp4', s=256)), token=token)
                assert status == 200, f'Expected 200 for chunked client thumbnail, got {status}'
                assert thumb_body == webp_bytes

                # 3. Single raw upload with X-Thumbnail header
                status, _ = upload('single_vid.mp4', b'RAW_VIDEO_STREAM', extra_headers={'X-Thumbnail': webp_b64})
                assert status == 201
                status, thumb_body = request('/api/thumb?' + urlencode(dict(scope='private', path='single_vid.mp4', s=256)), token=token)
                assert status == 200, f'Expected 200 for single raw client thumbnail, got {status}'
                assert thumb_body == webp_bytes

                # 4. Upload without thumbnail (video thumbs disabled in config, falls back to queue, cache miss)
                status, _ = upload('no_thumb.mp4', b'NO_THUMB_STREAM')
                assert status == 201
                status, _ = request('/api/thumb?' + urlencode(dict(scope='private', path='no_thumb.mp4', s=256)), token=token)
                assert status != 200

                # 5. Upload with invalid/corrupt thumbnail (falls back gracefully)
                status, _ = upload('bad_thumb.mp4', b'BAD_THUMB_STREAM', extra_headers={'X-Thumbnail': 'NOT_BASE64_NOT_WEBP'})
                assert status == 201
                status, _ = request('/api/thumb?' + urlencode(dict(scope='private', path='bad_thumb.mp4', s=256)), token=token)
                assert status != 200

                # 6. Upload with truncated WebP in X-Thumbnail header (header intact, bitstream truncated)
                trunc_webp_bytes = webp_bytes[:40]
                trunc_webp_b64 = base64.b64encode(trunc_webp_bytes).decode('ascii')
                assert upload('trunc_chunk_vid.mp4', b'PART1', offset=0, total=10)[0] < 300
                status, _ = upload('trunc_chunk_vid.mp4', b'PART2', offset=5, total=10, is_last='true', extra_headers={'X-Thumbnail': trunc_webp_b64})
                assert status == 201
                # Must reject truncated WebP from cache (falls back gracefully, does NOT serve broken payload with 200)
                status, _ = request('/api/thumb?' + urlencode(dict(scope='private', path='trunc_chunk_vid.mp4', s=256)), token=token)
                assert status != 200, f'Expected non-200 for truncated thumbnail, got {status}'

                # 7. Upload multipart with truncated WebP thumbnail part
                status, _ = upload_multipart('trunc_mp_vid.mp4', b'TRUNC_MP4_VIDEO_STREAM', trunc_webp_bytes)
                assert status == 201
                status, _ = request('/api/thumb?' + urlencode(dict(scope='private', path='trunc_mp_vid.mp4', s=256)), token=token)
                assert status != 200, f'Expected non-200 for multipart truncated thumbnail, got {status}'

                # 8. Upload with data URI scheme in X-Thumbnail header
                data_uri_b64 = 'data:image/webp;base64,' + webp_b64
                status, _ = upload('datauri_vid.mp4', b'DATAURI_VIDEO_STREAM', extra_headers={'X-Thumbnail': data_uri_b64})
                assert status == 201
                status, thumb_body = request('/api/thumb?' + urlencode(dict(scope='private', path='datauri_vid.mp4', s=256)), token=token)
                assert status == 200, f'Expected 200 for data URI thumbnail, got {status}'
                assert thumb_body == webp_bytes
                sync = obj('/api/account/sync-token',token=token)['sync_token']
                assert upload('resume.txt',b'ABC',offset=0,total=9)[0] < 300
                assert obj('/api/files/upload-status?scope=private&path=resume.txt',token=sync)['bytes_received'] == 3
                assert obj('/api/files/upload-status?scope=shared&path=resume.txt',token=sync)['bytes_received'] == 0
                for path in ('Фото/a.txt','public_/sub/ok.txt','publicX/sub/private.txt','secret.txt'):
                    assert upload(path,b'contents')[0] == 201
                status,_ = request('/api/files/move?'+urlencode(dict(scope='private',src='Фото',dest='New')),b'',token)
                assert status == 200
                assert download('New/a.txt') == (200,b'contents')
                share = obj('/api/share',dict(scope='private',path='public_'),token)['token']
                assert request('/s/'+share+'/raw?p=../secret.txt')[0] == 404
                assert request('/s/'+share+'/raw?p=sub/ok.txt',close=True) == (200,b'contents')
                if not hash_files and os.name != 'nt':
                    (root/'storage/users/1/public_/outside.txt').symlink_to(root/'storage/users/1/secret.txt')
                    assert request('/s/'+share+'/raw?p=outside.txt')[0] == 404
                status,body=request('/s/'+share+'/zip')
                assert status==200,(status,body)
                with zipfile.ZipFile(io.BytesIO(body)) as archive:
                    assert archive.namelist()==['sub/ok.txt'],archive.namelist()
                if hash_files:
                    # Literal prefixes must also isolate move/delete operations.
                    assert request('/api/files/move?'+urlencode(dict(scope='private',src='public_',dest='Moved')),b'',token)[0] == 200
                    assert download('publicX/sub/private.txt')[0] == 200
                    assert request('/api/files?scope=private',dict(paths=['Moved']),token,method='DELETE')[0] == 200
                    assert download('publicX/sub/private.txt')[0] == 200
                obj('/api/account/password',dict(new_password='changed-password'),token)
                assert download('chunks.txt')[0] == 401
                assert request('/api/files?scope=private&path=chunks.txt',token=sync)[0] == 401
                token=obj('/api/login',dict(username='review',password='changed-password'))['access_token']
                obj('/api/register', dict(username='helper',password='helper-password'))
                obj('/api/admin/users/2/approve', {}, token)
                status, body = request('/api/admin/users/2', dict(role='admin'), token, method='PATCH')
                assert status == 200, (status, body)
                helper = obj('/api/login',dict(username='helper',password='helper-password'))['access_token']
                assert json.loads(request('/api/admin/users/1/reset-password', {}, helper)[1])['code'] == 'cannot_modify_superuser'
                assert json.loads(request('/api/admin/users/1', {}, helper, method='DELETE')[1])['code'] == 'cannot_delete_superuser'
                code = obj('/api/admin/users/2/reset-password', {}, token)['code']
                obj('/api/auth/reset-password/request',dict(username='helper'))
                with contextlib.closing(sqlite3.connect(root/'db.sqlite')) as db:
                    assert db.execute('select count(*) from password_resets').fetchone()[0] == 1
                    stored=db.execute('select code from password_resets order by id desc limit 1').fetchone()[0]
                assert stored != code and len(stored) == 64
                assert len(code)==6 and code.isdigit()
                obj('/api/auth/reset-password/verify',dict(username='helper',code=code,new_password='reset-password'))
                assert request('/api/account', token=helper)[0] == 401
                assert request('/api/auth/reset-password/verify',dict(username='helper',code=code,new_password='again'))[0] == 400
                helper=obj('/api/login',dict(username='helper',password='reset-password'))['access_token']
                helper_sync=obj('/api/account/sync-token',token=helper)['sync_token']
                assert request('/api/account',token=helper,method='DELETE')[0] == 200
                assert request('/api/account',token=helper_sync)[0] == 401
                statuses=[request('/api/auth/reset-password/verify',dict(username='helper',code='000000',new_password='bad'))[0] for _ in range(21)]
                assert 429 in statuses
                print('HTTP regressions passed; hash_files =',hash_files,flush=True)
            finally:
                process.terminate()
                try: process.wait(timeout=5)
                except subprocess.TimeoutExpired: process.kill(); process.wait()
                if os.name == 'nt':
                    time.sleep(0.1)

with tempfile.TemporaryDirectory(prefix='crowley-secrets-test-', **cleanup_kwargs) as tmp:
    config_path=Path(tmp)/'config.json'
    config_path.write_text(json.dumps(dict(jwt_secret='short-secret')))
    env={k:v for k,v in os.environ.items() if k not in ('CROWLEYS_JWT_SECRET','CROWLEYS_ENCRYPTION_KEY')}
    result=subprocess.run([str(binary),str(config_path)],env=env,capture_output=True,timeout=10)
    assert result.returncode == 1, 'Invalid non-placeholder signing secret must be rejected'
run(True)
run(False)
