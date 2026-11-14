import test from 'node:test';
import assert from 'node:assert/strict';

import {
  bytesToHex,
  hexToBytes,
  generateRandomHex,
  scramAuthMessage,
  scramGenerateKeys,
  scramComputeProof,
  scramArgon2idAuthMessage,
  deriveArgon2id,
  scramArgon2idGenerateKeys,
  scramArgon2idComputeProof
} from '../src/utils/scram.js';

test('scramGenerateKeys matches standard RFC / OpenSSL test vectors', async () => {
  const password = 'pencil';
  const saltHex = '0102030405060708090a0b0c0d0e0f10';
  const iterations = 4096;

  const { storedKeyHex, serverKeyHex } = await scramGenerateKeys(password, saltHex, iterations);

  assert.equal(
    storedKeyHex,
    '07d31bf134a40ecbe975d4c3d010e6483a49028d3cfa0bcaf33712086463099c'
  );
  assert.equal(
    serverKeyHex,
    'd33e248e09dd4722509c0f771ed604dfbe85d6f303239f503359c370fcaef11c'
  );
});

test('deriveArgon2id matches OpenSSL and Dart test vector exactly', async () => {
  const password = 'pencil';
  const saltHex = '0102030405060708090a0b0c0d0e0f10';
  const memCostKb = 19456;
  const timeCost = 2;
  const lanes = 1;

  const derived = await deriveArgon2id(password, saltHex, memCostKb, timeCost, lanes, 32);
  const derivedHex = bytesToHex(derived);

  assert.equal(
    derivedHex,
    '802b124da21836ed1c1ac795287da053047c99e90854e2f189e622efadb020db'
  );
});

test('scramArgon2idGenerateKeys generates valid keys', async () => {
  const password = 'pencil';
  const saltHex = '0102030405060708090a0b0c0d0e0f10';
  const memCostKb = 19456;
  const timeCost = 2;
  const lanes = 1;

  const { storedKeyHex, serverKeyHex } = await scramArgon2idGenerateKeys(
    password,
    saltHex,
    memCostKb,
    timeCost,
    lanes
  );

  assert.equal(storedKeyHex.length, 64);
  assert.equal(serverKeyHex.length, 64);
});

test('scramArgon2idComputeProof generates valid client proof and expected server signature', async () => {
  const username = 'admin';
  const password = 'pencil';
  const nonce = 'r12345';
  const saltHex = '0102030405060708090a0b0c0d0e0f10';
  const memCostKb = 19456;
  const timeCost = 2;
  const lanes = 1;

  const authMessage = scramArgon2idAuthMessage(username, nonce, saltHex, memCostKb, timeCost, lanes);
  assert.equal(
    authMessage,
    'n=admin,r=r12345,s=0102030405060708090a0b0c0d0e0f10,k=argon2id,m=19456,t=2,p=1'
  );

  const { clientProofHex, expectedServerSignatureHex } = await scramArgon2idComputeProof(
    password,
    saltHex,
    memCostKb,
    timeCost,
    lanes,
    authMessage
  );

  assert.equal(clientProofHex.length, 64);
  assert.equal(expectedServerSignatureHex.length, 64);
});

test('scramComputeProof generates valid client proof and expected server signature (legacy)', async () => {
  const username = 'admin';
  const password = 'pencil';
  const nonce = 'r12345';
  const saltHex = '0102030405060708090a0b0c0d0e0f10';
  const iterations = 4096;

  const authMessage = scramAuthMessage(username, nonce, saltHex, iterations);
  assert.equal(authMessage, 'n=admin,r=r12345,s=0102030405060708090a0b0c0d0e0f10,i=4096');

  const { clientProofHex, expectedServerSignatureHex } = await scramComputeProof(
    password,
    saltHex,
    iterations,
    authMessage
  );

  assert.equal(clientProofHex.length, 64);
  assert.equal(expectedServerSignatureHex.length, 64);
});

test('hexToBytes and bytesToHex roundtrip', () => {
  const randomHex = generateRandomHex(16);
  assert.equal(randomHex.length, 32);

  const bytes = hexToBytes(randomHex);
  assert.equal(bytes.length, 16);
  assert.equal(bytesToHex(bytes), randomHex);
});
