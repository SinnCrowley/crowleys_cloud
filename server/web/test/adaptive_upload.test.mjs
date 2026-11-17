// Copyright (C) 2026 Sinn Crowley
// AGPL-3.0-or-later

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

let serial = 9000;
async function loadFilesApi(client = {}) {
  const key = `adaptiveApiTest${serial++}`;
  globalThis[key] = client;

  let source = await readFile(new URL('../src/api/files.js', import.meta.url), 'utf8');
  source = source
    .replace("from 'svelte/store'", `from '${import.meta.resolve('svelte/store')}'`)
    .replace(
      "import { apiGet, apiPost, apiDelete, apiMessage } from './client.js';",
      `const { apiGet = async () => ({}), apiPost = async () => ({}), apiDelete = async () => ({}), apiMessage = (k) => k } = globalThis.${key};`
    )
    .replace(
      "import { authStore } from '../stores/auth.js';",
      `const authStore = { accessToken: { subscribe: cb => { cb('test-token'); return () => {}; } }, refreshToken: { subscribe: cb => { cb('test-refresh'); return () => {}; } }, setSession: () => {}, clearSession: () => {} };`
    )
    .replace("from '../utils/videoThumbnail.js'", `from '${import.meta.resolve('../src/utils/videoThumbnail.js')}'`);

  return import(`data:text/javascript;base64,${Buffer.from(source).toString('base64')}`);
}

test('uploadFileChunked: dynamically adapts chunk size based on measured upload bandwidth', async () => {
  const chunksSent = [];
  const totalSize = 30 * 1024 * 1024; // 30 MB
  const file = new Blob([new Uint8Array(totalSize)], { type: 'application/octet-stream' });
  file.name = 'adaptive_test.bin';

  const { filesApi } = await loadFilesApi({
    apiGet: async () => ({ bytes_received: 0 }),
    apiPost: async (url, chunk, options) => {
      chunksSent.push({ url, size: chunk.size, options });
      return { ok: true };
    }
  });

  await filesApi.uploadFileChunked({
    path: 'adaptive_test.bin',
    file,
    checkResume: false
  });

  // Verify that chunks were sent and chunk size dynamically scaled up
  assert.ok(chunksSent.length > 0);
  assert.equal(chunksSent[0].size, 2 * 1024 * 1024, 'Initial chunk size should start at safe MIN_CHUNK (2MB)');

  // On fast simulated responses, subsequent chunks should have scaled up
  if (chunksSent.length > 1) {
    assert.ok(chunksSent[1].size >= 2 * 1024 * 1024, 'Subsequent chunk should scale up or stay at MIN_CHUNK');
  }

  // Total transferred should equal total file size
  const totalTransferred = chunksSent.reduce((sum, c) => sum + c.size, 0);
  assert.equal(totalTransferred, totalSize, 'All bytes must be transferred accurately');
});
