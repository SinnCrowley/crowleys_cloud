import contextlib
import hashlib
import hmac
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

def pbkdf2_sha256(password: str, salt: bytes, iterations: int = 4096) -> bytes:
    return hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt, iterations, 32)

def scram_sha256_generate_keys(password: str, salt_hex: str, iterations: int = 4096):
    salt = bytes.fromhex(salt_hex)
    salted_password = pbkdf2_sha256(password, salt, iterations)
    client_key = hmac.new(salted_password, b"Client Key", hashlib.sha256).digest()
    stored_key = hashlib.sha256(client_key).digest()
    server_key = hmac.new(salted_password, b"Server Key", hashlib.sha256).digest()
    return stored_key.hex(), server_key.hex()

def scram_sha256_client_proof(password: str, salt_hex: str, iterations: int, auth_message: str):
    salt = bytes.fromhex(salt_hex)
    salted_password = pbkdf2_sha256(password, salt, iterations)
    client_key = hmac.new(salted_password, b"Client Key", hashlib.sha256).digest()
    stored_key = hashlib.sha256(client_key).digest()
    client_signature = hmac.new(stored_key, auth_message.encode('utf-8'), hashlib.sha256).digest()
    client_proof = bytes(a ^ b for a, b in zip(client_key, client_signature))
    server_key = hmac.new(salted_password, b"Server Key", hashlib.sha256).digest()
    server_signature = hmac.new(server_key, auth_message.encode('utf-8'), hashlib.sha256).digest()
    return client_proof.hex(), server_signature.hex()

def argon2id_kdf(password: str, salt_hex: str, memcost: int = 19456, time_cost: int = 2, lanes: int = 1, keylen: int = 32) -> bytes:
    res = subprocess.run([
        'openssl', 'kdf', '-keylen', str(keylen),
        '-kdfopt', f'pass:{password}',
        '-kdfopt', f'hexsalt:{salt_hex}',
        '-kdfopt', f'memcost:{memcost}',
        '-kdfopt', f'iter:{time_cost}',
        '-kdfopt', f'lanes:{lanes}',
        'ARGON2ID'
    ], capture_output=True, text=True, check=True)
    hex_str = res.stdout.strip().replace(':', '')
    return bytes.fromhex(hex_str)

def scram_argon2id_generate_keys(password: str, salt_hex: str, memcost: int = 19456, time_cost: int = 2, lanes: int = 1):
    salted_password = argon2id_kdf(password, salt_hex, memcost, time_cost, lanes, 32)
    client_key = hmac.new(salted_password, b"Client Key", hashlib.sha256).digest()
    stored_key = hashlib.sha256(client_key).digest()
    server_key = hmac.new(salted_password, b"Server Key", hashlib.sha256).digest()
    return stored_key.hex(), server_key.hex()

def scram_argon2id_client_proof(password: str, salt_hex: str, memcost: int, time_cost: int, lanes: int, auth_message: str):
    salted_password = argon2id_kdf(password, salt_hex, memcost, time_cost, lanes, 32)
    client_key = hmac.new(salted_password, b"Client Key", hashlib.sha256).digest()
    stored_key = hashlib.sha256(client_key).digest()
    client_signature = hmac.new(stored_key, auth_message.encode('utf-8'), hashlib.sha256).digest()
    client_proof = bytes(a ^ b for a, b in zip(client_key, client_signature))
    server_key = hmac.new(salted_password, b"Server Key", hashlib.sha256).digest()
    server_signature = hmac.new(server_key, auth_message.encode('utf-8'), hashlib.sha256).digest()
    return client_proof.hex(), server_signature.hex()

def test_scram():
    with tempfile.TemporaryDirectory(prefix='crowley-scram-test-') as tmp:
        root = Path(tmp)
        with socket.socket() as sock:
            sock.bind(('127.0.0.1', 0))
            port = sock.getsockname()[1]
        config = dict(host='127.0.0.1', port=port, storage_root=str(root/'storage'),
                      db_path=str(root/'db.sqlite'), temp_upload_dir=str(root/'uploads'),
                      public_dir=str(root/'public'), log_dir=str(root/'logs'),
                      hash_files=False, jwt_secret=secrets.token_hex(32),
                      registration_mode='open',
                      encryption_key=secrets.token_hex(32), rate_limit_per_minute=200,
                      trash_retention_days=7, video_thumbs_enabled=False)
        config_path = root/'config.json'
        config_path.write_text(json.dumps(config))
        env = {k:v for k,v in os.environ.items() if k not in ('CROWLEYS_JWT_SECRET', 'CROWLEYS_ENCRYPTION_KEY')}
        with (root/'output.log').open('w') as log:
            process = subprocess.Popen([str(binary), str(config_path)], stdout=log, stderr=log, env=env)
            try:
                def req(method, path, body=None, token=None):
                    conn = http.client.HTTPConnection('127.0.0.1', port, timeout=5)
                    headers = {}
                    payload = None
                    if body is not None:
                        headers['Content-Type'] = 'application/json'
                        payload = json.dumps(body).encode('utf-8')
                    if token:
                        headers['Authorization'] = 'Bearer ' + token
                    conn.request(method, path, body=payload, headers=headers)
                    resp = conn.getresponse()
                    data = resp.read()
                    conn.close()
                    try:
                        return resp.status, json.loads(data.decode('utf-8'))
                    except Exception:
                        return resp.status, data.decode('utf-8')

                # Wait for server to come up
                for _ in range(50):
                    try:
                        s, _ = req('GET', '/api/auth/challenge?username=test&nonce=123')
                        if s in (200, 400):
                            break
                    except Exception:
                        time.sleep(0.1)
                else:
                    raise RuntimeError("Server failed to start")

                # ==========================================
                # PART 1: SCRAM-Argon2id (Default standard)
                # ==========================================

                # 1. Register first admin using SCRAM-Argon2id
                salt_hex = secrets.token_hex(16)
                m = 19456
                t = 2
                p = 1
                admin_pw = "SuperSecurePassword123!"
                stored_key, server_key = scram_argon2id_generate_keys(admin_pw, salt_hex, m, t, p)

                status, body = req('POST', '/api/register', {
                    'username': 'admin',
                    'salt': salt_hex,
                    'kdf': 'argon2id',
                    'm': m,
                    't': t,
                    'p': p,
                    'stored_key': stored_key,
                    'server_key': server_key
                })
                assert status == 200, f"Register failed: {status}, {body}"
                assert body.get('user', {}).get('role') in ('admin', 'superuser')
                assert body.get('access_token') is not None

                # 2. Challenge endpoint for admin
                client_nonce = secrets.token_hex(16)
                status, challenge = req('GET', f'/api/auth/challenge?username=admin&nonce={client_nonce}')
                assert status == 200, f"Challenge failed: {status}, {challenge}"
                assert challenge.get('auth_mode') == 'scram-argon2id'
                assert challenge.get('salt') == salt_hex
                assert challenge.get('m') == m
                assert challenge.get('t') == t
                assert challenge.get('p') == p
                combined_nonce = challenge.get('nonce')
                assert combined_nonce.startswith(client_nonce)
                challenge_token = challenge.get('challenge_token')
                assert challenge_token is not None

                # 3. Compute client proof and login
                auth_message = f"n=admin,r={combined_nonce},s={salt_hex},k=argon2id,m={m},t={t},p={p}"
                client_proof, expected_server_sig = scram_argon2id_client_proof(admin_pw, salt_hex, m, t, p, auth_message)

                status, login_res = req('POST', '/api/login', {
                    'username': 'admin',
                    'nonce': combined_nonce,
                    'client_proof': client_proof,
                    'challenge_token': challenge_token
                })
                assert status == 200, f"Login failed: {status}, {login_res}"
                assert login_res.get('access_token') is not None
                assert login_res.get('server_signature') == expected_server_sig, "Server signature mismatch!"
                admin_token = login_res.get('access_token')

                # 4. Verify replay attack prevention (reusing the same nonce)
                status, replay_res = req('POST', '/api/login', {
                    'username': 'admin',
                    'nonce': combined_nonce,
                    'client_proof': client_proof,
                    'challenge_token': challenge_token
                })
                assert status == 400 or status == 401, f"Replay attack should fail! Status: {status}"

                # 5. Invalid password proof must fail
                bad_client_nonce = secrets.token_hex(16)
                status, bad_challenge = req('GET', f'/api/auth/challenge?username=admin&nonce={bad_client_nonce}')
                bad_auth_msg = f"n=admin,r={bad_challenge['nonce']},s={salt_hex},k=argon2id,m={m},t={t},p={p}"
                bad_proof, _ = scram_argon2id_client_proof("WrongPassword", salt_hex, m, t, p, bad_auth_msg)
                status, bad_login = req('POST', '/api/login', {
                    'username': 'admin',
                    'nonce': bad_challenge['nonce'],
                    'client_proof': bad_proof,
                    'challenge_token': bad_challenge['challenge_token']
                })
                assert status == 401, f"Wrong password should be 401, got {status}: {bad_login}"

                # 6. Password change with SCRAM-Argon2id (Variant A: Zero-Knowledge Re-authentication)
                new_pw = "EvenBetterPassword456!"
                new_salt = secrets.token_hex(16)
                new_stored, new_server = scram_argon2id_generate_keys(new_pw, new_salt, m, t, p)

                # Attempt change without current password proof must fail (400)
                status, chg_res = req('POST', '/api/account/password', {
                    'salt': new_salt,
                    'kdf': 'argon2id',
                    'm': m,
                    't': t,
                    'p': p,
                    'stored_key': new_stored,
                    'server_key': new_server
                }, token=admin_token)
                assert status == 400, f"Password change without proof should be 400, got {status}: {chg_res}"

                # Attempt change with wrong current password proof must fail (401)
                status, bad_reauth_chal = req('GET', f'/api/account/reauth/challenge?nonce={secrets.token_hex(16)}', token=admin_token)
                assert status == 200, f"Reauth challenge failed: {status}, {bad_reauth_chal}"
                bad_auth_msg = f"n=admin,r={bad_reauth_chal['nonce']},s={bad_reauth_chal['salt']},k=argon2id,m={m},t={t},p={p}"
                bad_reauth_proof, _ = scram_argon2id_client_proof("WrongCurrentPassword", bad_reauth_chal['salt'], m, t, p, bad_auth_msg)
                status, bad_chg_res = req('POST', '/api/account/password', {
                    'current_nonce': bad_reauth_chal['nonce'],
                    'current_client_proof': bad_reauth_proof,
                    'current_challenge_token': bad_reauth_chal['challenge_token'],
                    'salt': new_salt,
                    'kdf': 'argon2id',
                    'm': m,
                    't': t,
                    'p': p,
                    'stored_key': new_stored,
                    'server_key': new_server
                }, token=admin_token)
                assert status == 401, f"Password change with wrong proof should be 401, got {status}: {bad_chg_res}"

                # Successful password change with valid current password proof
                status, reauth_chal = req('GET', f'/api/account/reauth/challenge?nonce={secrets.token_hex(16)}', token=admin_token)
                assert status == 200, f"Reauth challenge failed: {status}, {reauth_chal}"
                cur_auth_msg = f"n=admin,r={reauth_chal['nonce']},s={reauth_chal['salt']},k=argon2id,m={m},t={t},p={p}"
                cur_proof, _ = scram_argon2id_client_proof(admin_pw, reauth_chal['salt'], m, t, p, cur_auth_msg)
                status, chg_res = req('POST', '/api/account/password', {
                    'current_nonce': reauth_chal['nonce'],
                    'current_client_proof': cur_proof,
                    'current_challenge_token': reauth_chal['challenge_token'],
                    'salt': new_salt,
                    'kdf': 'argon2id',
                    'm': m,
                    't': t,
                    'p': p,
                    'stored_key': new_stored,
                    'server_key': new_server
                }, token=admin_token)
                assert status == 200, f"Change password failed: {status}, {chg_res}"

                # 7. Login with new password
                status, new_chal = req('GET', f'/api/auth/challenge?username=admin&nonce={secrets.token_hex(16)}')
                assert new_chal.get('salt') == new_salt
                assert new_chal.get('auth_mode') == 'scram-argon2id'
                new_auth_msg = f"n=admin,r={new_chal['nonce']},s={new_salt},k=argon2id,m={m},t={t},p={p}"
                new_proof, new_expected_sig = scram_argon2id_client_proof(new_pw, new_salt, m, t, p, new_auth_msg)
                status, new_login = req('POST', '/api/login', {
                    'username': 'admin',
                    'nonce': new_chal['nonce'],
                    'client_proof': new_proof,
                    'challenge_token': new_chal['challenge_token']
                })
                assert status == 200, f"Login with new password failed: {status}, {new_login}"
                assert new_login.get('server_signature') == new_expected_sig

                # 8. Password reset with SCRAM-Argon2id
                status, reset_req_res = req('POST', '/api/auth/reset-password/request', {'username': 'admin'})
                assert status == 200, f"Reset request failed: {status}, {reset_req_res}"

                # Read code from db
                db_conn = sqlite3.connect(root/'db.sqlite')
                cur = db_conn.cursor()
                cur.execute("SELECT raw_code FROM password_resets WHERE user_id = 1 ORDER BY id DESC LIMIT 1")
                row = cur.fetchone()
                db_conn.close()
                assert row is not None, "Reset code not found in db"
                reset_code = row[0]

                # Verify reset with SCRAM-Argon2id
                reset_pw = "ResetPassword789!"
                reset_salt = secrets.token_hex(16)
                reset_stored, reset_server = scram_argon2id_generate_keys(reset_pw, reset_salt, m, t, p)
                status, reset_ver_res = req('POST', '/api/auth/reset-password/verify', {
                    'username': 'admin',
                    'code': reset_code,
                    'salt': reset_salt,
                    'kdf': 'argon2id',
                    'm': m,
                    't': t,
                    'p': p,
                    'stored_key': reset_stored,
                    'server_key': reset_server
                })
                assert status == 200, f"Reset verify failed: {status}, {reset_ver_res}"

                # Login with reset password
                status, rst_chal = req('GET', f'/api/auth/challenge?username=admin&nonce={secrets.token_hex(16)}')
                assert rst_chal.get('salt') == reset_salt
                rst_auth_msg = f"n=admin,r={rst_chal['nonce']},s={reset_salt},k=argon2id,m={m},t={t},p={p}"
                rst_proof, rst_expected_sig = scram_argon2id_client_proof(reset_pw, reset_salt, m, t, p, rst_auth_msg)
                status, rst_login = req('POST', '/api/login', {
                    'username': 'admin',
                    'nonce': rst_chal['nonce'],
                    'client_proof': rst_proof,
                    'challenge_token': rst_chal['challenge_token']
                })
                assert status == 200, f"Login with reset password failed: {status}, {rst_login}"
                assert rst_login.get('server_signature') == rst_expected_sig

                # ==========================================
                # PART 2: Backward Compatibility (SCRAM-SHA-256)
                # ==========================================
                legacy_user = "legacy_user"
                legacy_pw = "LegacyPass123!"
                legacy_salt = secrets.token_hex(16)
                legacy_iterations = 4096
                leg_stored, leg_server = scram_sha256_generate_keys(legacy_pw, legacy_salt, legacy_iterations)

                # Register legacy user using iterations (without m/kdf)
                status, leg_reg = req('POST', '/api/register', {
                    'username': legacy_user,
                    'salt': legacy_salt,
                    'iterations': legacy_iterations,
                    'stored_key': leg_stored,
                    'server_key': leg_server
                })
                assert status == 200, f"Legacy register failed: {status}, {leg_reg}"

                # Challenge for legacy user should return auth_mode == 'scram' and iterations
                status, leg_chal = req('GET', f'/api/auth/challenge?username={legacy_user}&nonce={secrets.token_hex(16)}')
                assert status == 200, f"Legacy challenge failed: {status}, {leg_chal}"
                assert leg_chal.get('auth_mode') == 'scram'
                assert leg_chal.get('salt') == legacy_salt
                assert leg_chal.get('iterations') == legacy_iterations

                # Login legacy user
                leg_auth_msg = f"n={legacy_user},r={leg_chal['nonce']},s={legacy_salt},i={legacy_iterations}"
                leg_proof, leg_expected_sig = scram_sha256_client_proof(legacy_pw, legacy_salt, legacy_iterations, leg_auth_msg)
                status, leg_login = req('POST', '/api/login', {
                    'username': legacy_user,
                    'nonce': leg_chal['nonce'],
                    'client_proof': leg_proof,
                    'challenge_token': leg_chal['challenge_token']
                })
                assert status == 200, f"Legacy login failed: {status}, {leg_login}"
                assert leg_login.get('server_signature') == leg_expected_sig

                # ==========================================
                # PART 3: Seamless upgrade of pre-SCRAM $argon2id$ direct hash
                # ==========================================
                direct_argon_user = "pre_scram_user"
                direct_argon_pw = "PreScramPass777!"
                direct_salt_hex = secrets.token_hex(16)
                direct_derived = argon2id_kdf(direct_argon_pw, direct_salt_hex, 65536, 3, 1, 32)
                direct_hash = f"$argon2id$v=19$m=65536,t=3,p=1${direct_salt_hex}${direct_derived.hex()}"

                # Insert user directly into DB with old pre-SCRAM hash format
                db_conn = sqlite3.connect(root/'db.sqlite')
                db_conn.execute("INSERT INTO users (username, password_hash, role, status, created_at) VALUES (?, ?, 'user', 'active', ?)",
                                (direct_argon_user, direct_hash, int(time.time())))
                db_conn.commit()
                db_conn.close()

                # 1. Challenge for pre-SCRAM user should return auth_mode == 'legacy'
                status, pre_chal = req('GET', f'/api/auth/challenge?username={direct_argon_user}&nonce={secrets.token_hex(16)}')
                assert status == 200, f"Pre-scram challenge failed: {status}, {pre_chal}"
                assert pre_chal.get('auth_mode') == 'legacy'

                # 2. Login with plaintext password (legacy mode)
                status, pre_login = req('POST', '/api/login', {
                    'username': direct_argon_user,
                    'password': direct_argon_pw
                })
                assert status == 200, f"Pre-scram login failed: {status}, {pre_login}"
                assert pre_login.get('access_token') is not None

                # 3. Verify user's hash in DB was upgraded to $scram-argon2id$
                db_conn = sqlite3.connect(root/'db.sqlite')
                cur = db_conn.cursor()
                cur.execute("SELECT password_hash FROM users WHERE username = ?", (direct_argon_user,))
                row = cur.fetchone()
                db_conn.close()
                assert row is not None
                upgraded_hash = row[0]
                assert upgraded_hash.startswith("$scram-argon2id$"), f"Hash was not upgraded: {upgraded_hash}"

                # 4. Next challenge for that same user MUST now return auth_mode == 'scram-argon2id'
                next_client_nonce = secrets.token_hex(16)
                status, next_chal = req('GET', f'/api/auth/challenge?username={direct_argon_user}&nonce={next_client_nonce}')
                assert status == 200, f"Upgraded challenge failed: {status}, {next_chal}"
                assert next_chal.get('auth_mode') == 'scram-argon2id', f"Expected scram-argon2id, got {next_chal.get('auth_mode')}"
                assert next_chal.get('m') == 19456
                assert next_chal.get('t') == 2
                assert next_chal.get('p') == 1

                # 5. Next login MUST succeed via SCRAM-Argon2id (WITHOUT plaintext password)
                upg_auth_msg = f"n={direct_argon_user},r={next_chal['nonce']},s={next_chal['salt']},k=argon2id,m={next_chal['m']},t={next_chal['t']},p={next_chal['p']}"
                upg_proof, upg_expected_sig = scram_argon2id_client_proof(
                    direct_argon_pw, next_chal['salt'], next_chal['m'], next_chal['t'], next_chal['p'], upg_auth_msg
                )
                status, upg_login = req('POST', '/api/login', {
                    'username': direct_argon_user,
                    'nonce': next_chal['nonce'],
                    'client_proof': upg_proof,
                    'challenge_token': next_chal['challenge_token']
                })
                assert status == 200, f"Upgraded SCRAM login failed: {status}, {upg_login}"
                assert upg_login.get('server_signature') == upg_expected_sig

                print("SCRAM-Argon2id, backward compatibility, and seamless pre-SCRAM upgrade E2E tests passed successfully!")
            finally:
                process.terminate()
                try:
                    process.wait(timeout=2)
                except subprocess.TimeoutExpired:
                    process.kill()

if __name__ == '__main__':
    test_scram()
