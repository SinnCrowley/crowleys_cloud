"""Test a disposable installed package, first startup and upgrade (stdlib only)."""
import http.client
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import tempfile
import time

source = Path(sys.argv[1]).resolve()
with tempfile.TemporaryDirectory(prefix='crowley release test ') as temporary:
    root = Path(temporary) / 'server with spaces'
    automatic_config = source.is_dir()
    if automatic_config:
        shutil.copytree(source, root)
        binary = root / ('crowleys_cloud_server.exe' if os.name == 'nt' else 'crowleys_cloud_server')
        assert not (root / 'config/config.local.json').exists(), 'Archive contains local secrets'
    else:
        root.mkdir()
        binary = source
        (root / 'config').mkdir()
        shutil.copyfile(Path(__file__).resolve().parents[1] / 'config/config.json', root / 'config/config.json')
        (root / 'public').mkdir()
        (root / 'public/index.html').write_text('release smoke test')
    base = root / 'config/config.json'
    local = root / 'config/config.local.json'
    with socket.socket() as sock:
        sock.bind(('127.0.0.1', 0))
        port = sock.getsockname()[1]
    # Preserve user settings while adding keys; all paths stay package-relative.
    settings = dict(host='127.0.0.1', port=port, log_level='WARN', video_thumbs_enabled=False)
    local.write_text(json.dumps(settings))
    env = {k: v for k, v in os.environ.items() if k not in ('CROWLEYS_JWT_SECRET', 'CROWLEYS_ENCRYPTION_KEY')}
    # No developer tools or Homebrew executables may be required at runtime.
    env['PATH'] = os.path.join(env.get('SystemRoot', 'C:\\Windows'), 'System32') if os.name == 'nt' else '/usr/bin:/bin'
    for name in ('DYLD_LIBRARY_PATH', 'DYLD_FALLBACK_LIBRARY_PATH', 'LD_LIBRARY_PATH'):
        env.pop(name, None)

    def request(path, data=None, token=None):
        headers = {}
        if isinstance(data, dict):
            data = json.dumps(data).encode()
            headers['Content-Type'] = 'application/json'
        elif data is not None:
            headers['Content-Type'] = 'application/octet-stream'
        if token:
            headers['Authorization'] = 'Bearer ' + token
        connection = http.client.HTTPConnection('127.0.0.1', port, timeout=3)
        try:
            connection.request('POST' if data is not None else 'GET', path, data, headers)
            response = connection.getresponse()
            return response.status, response.read()
        finally:
            connection.close()

    def launch(action):
        with (root / 'smoke.log').open('wb') as log:
            command = [str(binary)] if automatic_config else [str(binary), str(base)]
            process = subprocess.Popen(command, cwd=temporary, env=env, stdout=log, stderr=log)
            try:
                for _ in range(200):
                    assert process.poll() is None, 'Packaged server exited; inspect dependency/startup configuration'
                    try:
                        status, _ = request('/')
                        assert status == 200, 'Packaged web assets unavailable'
                        break
                    except OSError:
                        time.sleep(.05)
                else:
                    raise AssertionError('Server startup timed out')
                action()
            finally:
                process.terminate()
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()

    tokens = []
    def first_launch():
        generated = json.loads(local.read_text())
        for key, value in settings.items():
            assert generated[key] == value
        for key in ('jwt_secret', 'encryption_key'):
            assert len(generated[key]) == 64
            int(generated[key], 16)
        assert generated['jwt_secret'] != generated['encryption_key']
        if os.name != 'nt':
            assert local.stat().st_mode & 0o777 == 0o600
        status, body = request('/api/register', dict(username='smoke', password='release-test-password'))
        assert status < 300
        tokens.append(json.loads(body)['access_token'])
        assert request('/api/files?scope=private&path=roundtrip.txt', b'preserve encrypted data', tokens[0])[0] == 201
    launch(first_launch)
    saved = local.read_bytes()
    # Simulate replacing the shipped defaults during an upgrade.
    updated = json.loads(base.read_text())
    updated['log_retention_days'] = 17
    base.write_text(json.dumps(updated))
    def after_update():
        assert local.read_bytes() == saved, 'Upgrade regenerated or rewrote secrets'
        assert request('/api/files?scope=private&path=roundtrip.txt', token=tokens[0]) == (200, b'preserve encrypted data')
    launch(after_update)
    # Missing keys with existing data must fail instead of silently generating new ones.
    local.write_text(json.dumps(settings))
    with (root / 'smoke.log').open('wb') as log:
        result = subprocess.run([str(binary), str(base)], cwd=temporary, env=env, stdout=log, stderr=log, timeout=15)
    assert result.returncode != 0
    assert json.loads(local.read_text()) == settings
    # Environment secrets override an incomplete local config without persisting them.
    original = json.loads(saved)
    env['CROWLEYS_JWT_SECRET'] = original['jwt_secret']
    env['CROWLEYS_ENCRYPTION_KEY'] = original['encryption_key']
    def environment_launch():
        assert json.loads(local.read_text()) == settings
        assert request('/api/files?scope=private&path=roundtrip.txt', token=tokens[0]) == (200, b'preserve encrypted data')
    launch(environment_launch)
    env.pop('CROWLEYS_JWT_SECRET')
    env.pop('CROWLEYS_ENCRYPTION_KEY')
    # An invalid file must not be overwritten, even when keys are absent.
    local.write_text('{invalid local JSON')
    with (root / 'smoke.log').open('wb') as log:
        result = subprocess.run([str(binary), str(base)], cwd=temporary, env=env, stdout=log, stderr=log, timeout=15)
    assert result.returncode != 0 and local.read_text() == '{invalid local JSON'

    # Also cover a completely absent local file and shipped placeholder secrets.
    fresh = Path(temporary) / 'fresh instance'
    fresh.mkdir()
    updated.update(settings)
    updated.update(storage_root=str(fresh / 'storage'), db_path=str(fresh / 'data/db.sqlite'),
                   log_dir=str(fresh / 'logs'), temp_upload_dir=str(fresh / 'uploads'),
                   public_dir=str(root / 'public'), jwt_secret='change-this-secret',
                   encryption_key='default-local-encryption-key-for-testing')
    automatic_config = False
    base = fresh / 'config.json'
    local = fresh / 'config.local.json'
    base.write_text(json.dumps(updated))
    def absent_local_launch():
        generated = json.loads(local.read_text())
        assert set(generated) == {'jwt_secret', 'encryption_key'}
        assert all(len(value) == 64 for value in generated.values())
        assert generated['jwt_secret'] != original['jwt_secret']
    lock = local.with_name(local.name + '.init-lock')
    lock.mkdir()
    with (root / 'smoke.log').open('wb') as log:
        result = subprocess.run([str(binary), str(base)], cwd=temporary, env=env, stdout=log, stderr=log, timeout=15)
    assert result.returncode != 0 and not local.exists()
    assert lock.is_dir(), 'A competing initializer must not remove the active lock'
    lock.rmdir()
    launch(absent_local_launch)
print('Release startup, assets, persistent secrets, environment overrides and data protection: OK')
