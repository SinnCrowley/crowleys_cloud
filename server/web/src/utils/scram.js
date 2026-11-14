// Copyright (C) 2026 Sinn Crowley
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

/**
 * SCRAM client authentication utilities using Argon2id (WebAssembly) and PBKDF2 (Web Crypto API).
 */

import { argon2id } from 'hash-wasm';

export function bytesToHex(bytes) {
  const arr = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes);
  return Array.from(arr)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

export function hexToBytes(hex) {
  const cleanHex = hex.trim();
  if (cleanHex.length % 2 !== 0) {
    throw new Error('Invalid hex string length');
  }
  const bytes = new Uint8Array(cleanHex.length / 2);
  for (let i = 0; i < cleanHex.length; i += 2) {
    bytes[i / 2] = parseInt(cleanHex.substring(i, i + 2), 16);
  }
  return bytes;
}

export function generateRandomHex(byteCount = 16) {
  const bytes = new Uint8Array(byteCount);
  (globalThis.crypto || window.crypto).getRandomValues(bytes);
  return bytesToHex(bytes);
}

export function scramAuthMessage(username, nonce, saltHex, iterations) {
  return `n=${username},r=${nonce},s=${saltHex},i=${iterations}`;
}

export function scramArgon2idAuthMessage(username, nonce, saltHex, memCostKb, timeCost, lanes) {
  return `n=${username},r=${nonce},s=${saltHex},k=argon2id,m=${memCostKb},t=${timeCost},p=${lanes}`;
}

export async function deriveArgon2id(password, salt, memCostKb = 19456, timeCost = 2, lanes = 1, hashLength = 32) {
  const saltBytes = typeof salt === 'string' ? hexToBytes(salt) : salt;
  return argon2id({
    password,
    salt: saltBytes,
    parallelism: lanes,
    iterations: timeCost,
    memorySize: memCostKb,
    hashLength,
    outputType: 'binary',
  });
}

export async function scramArgon2idGenerateKeys(password, saltHex, memCostKb = 19456, timeCost = 2, lanes = 1) {
  const cryptoObj = globalThis.crypto || window.crypto;
  const encoder = new TextEncoder();
  const saltedPw = await deriveArgon2id(password, saltHex, memCostKb, timeCost, lanes, 32);

  const hmacPwKey = await cryptoObj.subtle.importKey(
    'raw',
    saltedPw,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const clientKey = await cryptoObj.subtle.sign(
    'HMAC',
    hmacPwKey,
    encoder.encode('Client Key')
  );
  const storedKey = await cryptoObj.subtle.digest('SHA-256', clientKey);
  const serverKey = await cryptoObj.subtle.sign(
    'HMAC',
    hmacPwKey,
    encoder.encode('Server Key')
  );

  return {
    storedKeyHex: bytesToHex(storedKey),
    serverKeyHex: bytesToHex(serverKey),
  };
}

export async function scramArgon2idComputeProof(password, saltHex, memCostKb, timeCost, lanes, authMessage) {
  const cryptoObj = globalThis.crypto || window.crypto;
  const encoder = new TextEncoder();
  const saltedPw = await deriveArgon2id(password, saltHex, memCostKb, timeCost, lanes, 32);

  const hmacPwKey = await cryptoObj.subtle.importKey(
    'raw',
    saltedPw,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const clientKey = new Uint8Array(
    await cryptoObj.subtle.sign('HMAC', hmacPwKey, encoder.encode('Client Key'))
  );
  const storedKey = new Uint8Array(
    await cryptoObj.subtle.digest('SHA-256', clientKey)
  );

  const storedHmacKey = await cryptoObj.subtle.importKey(
    'raw',
    storedKey,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );
  const clientSig = new Uint8Array(
    await cryptoObj.subtle.sign('HMAC', storedHmacKey, encoder.encode(authMessage))
  );

  const clientProof = new Uint8Array(32);
  for (let i = 0; i < 32; i++) {
    clientProof[i] = clientKey[i] ^ clientSig[i];
  }

  const serverKey = new Uint8Array(
    await cryptoObj.subtle.sign('HMAC', hmacPwKey, encoder.encode('Server Key'))
  );
  const serverHmacKey = await cryptoObj.subtle.importKey(
    'raw',
    serverKey,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );
  const serverSig = new Uint8Array(
    await cryptoObj.subtle.sign('HMAC', serverHmacKey, encoder.encode(authMessage))
  );

  return {
    clientProofHex: bytesToHex(clientProof),
    expectedServerSignatureHex: bytesToHex(serverSig),
  };
}

export async function scramGenerateKeys(password, saltHex, iterations = 4096) {
  const cryptoObj = globalThis.crypto || window.crypto;
  const encoder = new TextEncoder();
  const salt = typeof saltHex === 'string' ? hexToBytes(saltHex) : saltHex;

  const pwKey = await cryptoObj.subtle.importKey(
    'raw',
    encoder.encode(password),
    { name: 'PBKDF2' },
    false,
    ['deriveBits']
  );

  const saltedPw = await cryptoObj.subtle.deriveBits(
    { name: 'PBKDF2', salt, iterations, hash: 'SHA-256' },
    pwKey,
    256
  );

  const hmacPwKey = await cryptoObj.subtle.importKey(
    'raw',
    saltedPw,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const clientKey = await cryptoObj.subtle.sign(
    'HMAC',
    hmacPwKey,
    encoder.encode('Client Key')
  );
  const storedKey = await cryptoObj.subtle.digest('SHA-256', clientKey);
  const serverKey = await cryptoObj.subtle.sign(
    'HMAC',
    hmacPwKey,
    encoder.encode('Server Key')
  );

  return {
    storedKeyHex: bytesToHex(storedKey),
    serverKeyHex: bytesToHex(serverKey),
  };
}

export async function scramComputeProof(password, saltHex, iterations, authMessage) {
  const cryptoObj = globalThis.crypto || window.crypto;
  const encoder = new TextEncoder();
  const salt = typeof saltHex === 'string' ? hexToBytes(saltHex) : saltHex;

  const pwKey = await cryptoObj.subtle.importKey(
    'raw',
    encoder.encode(password),
    { name: 'PBKDF2' },
    false,
    ['deriveBits']
  );

  const saltedPw = await cryptoObj.subtle.deriveBits(
    { name: 'PBKDF2', salt, iterations, hash: 'SHA-256' },
    pwKey,
    256
  );

  const hmacPwKey = await cryptoObj.subtle.importKey(
    'raw',
    saltedPw,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const clientKey = new Uint8Array(
    await cryptoObj.subtle.sign('HMAC', hmacPwKey, encoder.encode('Client Key'))
  );
  const storedKey = new Uint8Array(
    await cryptoObj.subtle.digest('SHA-256', clientKey)
  );

  const storedHmacKey = await cryptoObj.subtle.importKey(
    'raw',
    storedKey,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );
  const clientSig = new Uint8Array(
    await cryptoObj.subtle.sign('HMAC', storedHmacKey, encoder.encode(authMessage))
  );

  const clientProof = new Uint8Array(32);
  for (let i = 0; i < 32; i++) {
    clientProof[i] = clientKey[i] ^ clientSig[i];
  }

  const serverKey = new Uint8Array(
    await cryptoObj.subtle.sign('HMAC', hmacPwKey, encoder.encode('Server Key'))
  );
  const serverHmacKey = await cryptoObj.subtle.importKey(
    'raw',
    serverKey,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );
  const serverSig = new Uint8Array(
    await cryptoObj.subtle.sign('HMAC', serverHmacKey, encoder.encode(authMessage))
  );

  return {
    clientProofHex: bytesToHex(clientProof),
    expectedServerSignatureHex: bytesToHex(serverSig),
  };
}
