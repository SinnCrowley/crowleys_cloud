import test from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import net from 'node:net';

import {
  generateRandomHex,
  scramArgon2idAuthMessage,
  scramArgon2idGenerateKeys,
  scramArgon2idComputeProof,
  scramAuthMessage,
  scramGenerateKeys,
  scramComputeProof
} from '../src/utils/scram.js';

function getFreePort() {
  return new Promise((resolve, reject) => {
    const srv = net.createServer();
    srv.listen(0, '127.0.0.1', () => {
      const port = srv.address().port;
      srv.close(() => resolve(port));
    });
    srv.on('error', reject);
  });
}

test('Full E2E SCRAM auth between Web client crypto and C++ server binary', async () => {
  const binaryPath = path.resolve('../build/crowleys_cloud_server');
  if (!fs.existsSync(binaryPath)) {
    console.warn('Binary not found, skipping e2e server test');
    return;
  }

  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'crowley-web-e2e-'));
  const port = await getFreePort();
  const config = {
    host: '127.0.0.1',
    port,
    storage_root: path.join(tmpDir, 'storage'),
    db_path: path.join(tmpDir, 'db.sqlite'),
    temp_upload_dir: path.join(tmpDir, 'uploads'),
    public_dir: path.join(tmpDir, 'public'),
    log_dir: path.join(tmpDir, 'logs'),
    hash_files: false,
    jwt_secret: generateRandomHex(32),
    encryption_key: generateRandomHex(32),
    rate_limit_per_minute: 200,
    registration_mode: 'open',
    trash_retention_days: 7,
    video_thumbs_enabled: false
  };

  const configPath = path.join(tmpDir, 'config.json');
  fs.writeFileSync(configPath, JSON.stringify(config));

  const serverProc = spawn(binaryPath, [configPath], {
    stdio: 'ignore'
  });

  try {
    const baseUrl = `http://127.0.0.1:${port}`;

    // Poll until server ready
    let ready = false;
    for (let i = 0; i < 50; i++) {
      try {
        const res = await fetch(`${baseUrl}/api/auth/challenge?username=test&nonce=123`);
        if (res.status === 200 || res.status === 400) {
          ready = true;
          break;
        }
      } catch (e) {
        await new Promise((r) => setTimeout(r, 100));
      }
    }
    assert.ok(ready, 'Server did not become ready');

    // 1. Register with SCRAM-Argon2id
    const username = 'webuser';
    const password = 'WebPassword_2026!';
    const regSalt = generateRandomHex(16);
    const m = 19456;
    const t = 2;
    const p = 1;
    const { storedKeyHex, serverKeyHex } = await scramArgon2idGenerateKeys(password, regSalt, m, t, p);

    const regRes = await fetch(`${baseUrl}/api/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username,
        salt: regSalt,
        kdf: 'argon2id',
        m,
        t,
        p,
        stored_key: storedKeyHex,
        server_key: serverKeyHex
      })
    });
    assert.equal(regRes.status, 200);
    const regData = await regRes.json();
    assert.ok(regData.access_token);

    // 2. Challenge endpoint
    const clientNonce = generateRandomHex(16);
    const chalRes = await fetch(`${baseUrl}/api/auth/challenge?username=${username}&nonce=${clientNonce}`);
    assert.equal(chalRes.status, 200);
    const chalData = await chalRes.json();
    assert.equal(chalData.auth_mode, 'scram-argon2id');
    assert.equal(chalData.salt, regSalt);
    assert.equal(chalData.m, m);
    assert.equal(chalData.t, t);
    assert.equal(chalData.p, p);
    assert.ok(chalData.nonce.startsWith(clientNonce));

    // 3. Login with SCRAM-Argon2id proof
    const authMsg = scramArgon2idAuthMessage(
      username,
      chalData.nonce,
      chalData.salt,
      chalData.m,
      chalData.t,
      chalData.p
    );
    const { clientProofHex, expectedServerSignatureHex } = await scramArgon2idComputeProof(
      password,
      chalData.salt,
      chalData.m,
      chalData.t,
      chalData.p,
      authMsg
    );

    const loginRes = await fetch(`${baseUrl}/api/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username,
        nonce: chalData.nonce,
        client_proof: clientProofHex,
        challenge_token: chalData.challenge_token
      })
    });
    assert.equal(loginRes.status, 200);
    const loginData = await loginRes.json();
    assert.ok(loginData.access_token);
    assert.equal(loginData.server_signature, expectedServerSignatureHex, 'Server signature verified!');

    // 4. Change password using SCRAM-Argon2id
    const newPassword = 'BrandNewWebPassword_999!';
    const newSalt = generateRandomHex(16);
    const newKeys = await scramArgon2idGenerateKeys(newPassword, newSalt, m, t, p);

    const chgRes = await fetch(`${baseUrl}/api/account/password`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${loginData.access_token}`
      },
      body: JSON.stringify({
        salt: newSalt,
        kdf: 'argon2id',
        m,
        t,
        p,
        stored_key: newKeys.storedKeyHex,
        server_key: newKeys.serverKeyHex
      })
    });
    assert.equal(chgRes.status, 200);

    // 5. Login with new password
    const newChalRes = await fetch(`${baseUrl}/api/auth/challenge?username=${username}&nonce=${generateRandomHex(16)}`);
    assert.equal(newChalRes.status, 200);
    const newChal = await newChalRes.json();
    assert.equal(newChal.auth_mode, 'scram-argon2id');
    assert.equal(newChal.salt, newSalt);

    const newAuthMsg = scramArgon2idAuthMessage(
      username,
      newChal.nonce,
      newChal.salt,
      newChal.m,
      newChal.t,
      newChal.p
    );
    const newProof = await scramArgon2idComputeProof(
      newPassword,
      newChal.salt,
      newChal.m,
      newChal.t,
      newChal.p,
      newAuthMsg
    );

    const newLoginRes = await fetch(`${baseUrl}/api/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username,
        nonce: newChal.nonce,
        client_proof: newProof.clientProofHex,
        challenge_token: newChal.challenge_token
      })
    });
    assert.equal(newLoginRes.status, 200);
    const newLoginData = await newLoginRes.json();
    assert.equal(newLoginData.server_signature, newProof.expectedServerSignatureHex);
  } finally {
    serverProc.kill();
    fs.rmSync(tmpDir, { recursive: true, force: true });
  }
});
