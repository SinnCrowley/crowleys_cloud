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

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { get } from 'svelte/store';
import {
  clampDimensions,
  isVideoFile,
  blobToBase64,
  extractVideoPoster
} from '../src/utils/videoThumbnail.js';

let serial = 1000;

async function loadTransfersStore(api, videoUtil = {}) {
  const apiKey = `stressApi${serial++}`;
  const videoKey = `stressVideoUtil${serial++}`;
  globalThis[apiKey] = api;
  globalThis[videoKey] = videoUtil;

  let source = await readFile(new URL('../src/stores/transfers.js', import.meta.url), 'utf8');
  source = source
    .replace("from 'svelte/store'", `from '${import.meta.resolve('svelte/store')}'`)
    .replace("import { filesApi } from '../api/files.js';", `const filesApi = globalThis.${apiKey};`)
    .replace(
      /import\s*\{\s*isVideoFile,\s*extractVideoPoster\s*\}\s*from\s*['"]\.\.\/utils\/videoThumbnail\.js['"];?/,
      `const { isVideoFile = () => false, extractVideoPoster = async () => null } = globalThis.${videoKey};`
    )
    .replace(/import\s*\{\s*apiGet(?:,\s*apiMessage)?\s*\}\s*from\s*'\.\.\/api\/client\.js';/, 'const apiGet = async () => ({}); const apiMessage = (k) => k;')
    .replace("import { authStore } from './auth.js';", 'const authStore = { user: { set() {} } };')
    .replace("import { refreshStats } from './stats.js';", 'const refreshStats = async () => {};');

  return import(`data:text/javascript;base64,${Buffer.from(source).toString('base64')}`);
}

async function loadFilesApi(client = {}) {
  const key = `stressFilesApi${serial++}`;
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
      `const authStore = globalThis.${key}.authStore || { accessToken: { subscribe: cb => { cb('stress-token'); return () => {}; } }, refreshToken: { subscribe: cb => { cb('stress-refresh'); return () => {}; } }, setSession: () => {}, clearSession: () => {} };`
    )
    .replace("from '../utils/videoThumbnail.js'", `from '${import.meta.resolve('../src/utils/videoThumbnail.js')}'`);

  return import(`data:text/javascript;base64,${Buffer.from(source).toString('base64')}`);
}

const settle = () => new Promise(resolve => setImmediate(resolve));
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));

function createDomMockHarness({
  width = 1920,
  height = 1080,
  duration = 10,
  triggerError = false,
  hang = false,
  toBlobResult = new Blob(['mock-webp-frame-data'], { type: 'image/webp' }),
  context2dNull = false,
  toBlobNull = false
} = {}) {
  const revokedUrls = [];
  let videoInstance = null;
  let canvasInstance = null;

  class MockVideo {
    constructor() {
      videoInstance = this;
      this.videoWidth = width;
      this.videoHeight = height;
      this.duration = duration;
      this._src = '';
      this._currentTime = 0;
      this.paused = false;
      this.loaded = false;
      this.muted = false;
      this.playsInline = false;
      this.preload = '';
    }
    set src(val) {
      this._src = val;
      if (val) {
        queueMicrotask(() => {
          if (triggerError) {
            this.onerror?.();
          } else if (!hang) {
            this.onloadedmetadata?.();
          }
        });
      }
    }
    get src() { return this._src; }
    set currentTime(val) {
      this._currentTime = val;
      queueMicrotask(() => {
        if (!hang) this.onseeked?.();
      });
    }
    get currentTime() { return this._currentTime; }
    pause() { this.paused = true; }
    removeAttribute(attr) { if (attr === 'src') this._src = ''; }
    load() { this.loaded = true; }
  }

  class MockCanvas {
    constructor() {
      canvasInstance = this;
      this.width = 0;
      this.height = 0;
    }
    getContext(type) {
      if (type !== '2d' || context2dNull) return null;
      return {
        drawImage: (v, x, y, w, h) => {
          this.drawn = { v, x, y, w, h };
        }
      };
    }
    toBlob(cb, type, quality) {
      this.exported = { type, quality };
      queueMicrotask(() => cb(toBlobNull ? null : toBlobResult));
    }
  }

  const document = {
    createElement(tag) {
      if (tag === 'video') return new MockVideo();
      if (tag === 'canvas') return new MockCanvas();
      return {};
    }
  };

  const urlApi = {
    createObjectURL: (f) => 'blob:mock-' + (f.name || 'video'),
    revokeObjectURL: (u) => revokedUrls.push(u),
  };

  return {
    document,
    urlApi,
    get video() { return videoInstance; },
    get canvas() { return canvasInstance; },
    get revokedUrls() { return revokedUrls; },
  };
}

// ============================================================================
// 1. CANCELLATION BOUNDARY STRESS TESTS
// ============================================================================

test('cancellation boundary: cancelTransfer DURING poster extraction stops upload and cleans up', async () => {
  let uploadCalled = false;
  let extractionAborted = false;
  let extractResolve;

  const { transfersStore } = await loadTransfersStore(
    {
      uploadFileSingle: async () => {
        uploadCalled = true;
        return { ok: true };
      }
    },
    {
      isVideoFile: () => true,
      extractVideoPoster: async (_file, { signal }) => {
        return new Promise((resolve) => {
          extractResolve = resolve;
          if (signal?.aborted) {
            extractionAborted = true;
            resolve(null);
          } else {
            signal?.addEventListener('abort', () => {
              extractionAborted = true;
              resolve(null);
            });
          }
        });
      }
    }
  );

  const file = { name: 'cancel_during_extract.mp4', size: 2 * 1024 * 1024 };
  const id = transfersStore.enqueueUpload(file);

  await settle();

  // Transfer is currently running and awaiting extractVideoPoster
  const qMid = get(transfersStore.queue);
  assert.equal(qMid[0].status, 'running');
  assert.equal(uploadCalled, false);

  // Cancel while extraction is pending
  transfersStore.cancelTransfer(id);

  await settle(); await settle();

  assert.equal(extractionAborted, true, 'Extraction should observe signal.aborted');
  assert.equal(uploadCalled, false, 'Upload must NOT be invoked when cancelled during extraction');

  const qEnd = get(transfersStore.queue);
  assert.equal(qEnd[0].status, 'cancelled', 'Status must remain cancelled');
  assert.equal(qEnd[0].error, null, 'Cancelled transfer must not set error message');
});

test('cancellation boundary: pauseTransfer DURING extraction stops upload and allows subsequent resume', async () => {
  let uploadCallCount = 0;
  let extractCallCount = 0;
  let abortObserved = false;

  const { transfersStore } = await loadTransfersStore(
    {
      uploadFileSingle: async () => {
        uploadCallCount++;
        return { ok: true };
      }
    },
    {
      isVideoFile: () => true,
      extractVideoPoster: async (_file, { signal }) => {
        extractCallCount++;
        if (extractCallCount === 1) {
          // First attempt: simulate long extraction that will be paused
          return new Promise((resolve) => {
            signal?.addEventListener('abort', () => {
              abortObserved = true;
              resolve(null);
            });
          });
        }
        // Second attempt on resume: fast success
        return new Blob(['resumed-webp'], { type: 'image/webp' });
      }
    }
  );

  const file = { name: 'pause_and_resume.mp4', size: 1024 * 1024 };
  const id = transfersStore.enqueueUpload(file);

  await settle();

  // Pause during first extraction
  transfersStore.pauseTransfer(id);
  await settle(); await settle();

  assert.equal(abortObserved, true, 'First extraction observed abort');
  assert.equal(uploadCallCount, 0, 'No upload called yet');
  assert.equal(get(transfersStore.queue)[0].status, 'paused');

  // Now resume
  transfersStore.resumeTransfer(id);
  await settle(); await settle();

  assert.equal(extractCallCount, 2, 'Extraction was called again on resume');
  assert.equal(uploadCallCount, 1, 'Upload called after resume');
  assert.equal(get(transfersStore.queue)[0].status, 'completed');
});

test('cancellation boundary: cancelTransfer during upload aborts request and preserves cancelled status', async () => {
  let singleUploadStarted = false;
  let singleUploadAborted = false;

  const { transfersStore } = await loadTransfersStore(
    {
      uploadFileSingle: async ({ signal }) => {
        singleUploadStarted = true;
        return new Promise((_, reject) => {
          signal?.addEventListener('abort', () => {
            singleUploadAborted = true;
            reject(new DOMException('Upload aborted', 'AbortError'));
          });
        });
      }
    },
    {
      isVideoFile: () => true,
      extractVideoPoster: async () => new Blob(['poster'], { type: 'image/webp' })
    }
  );

  const file = { name: 'abort_in_upload.mp4', size: 1024 * 1024 };
  const id = transfersStore.enqueueUpload(file);

  await settle();
  assert.equal(singleUploadStarted, true);

  transfersStore.cancelTransfer(id);
  await settle(); await settle();

  assert.equal(singleUploadAborted, true);
  const q = get(transfersStore.queue);
  assert.equal(q[0].status, 'cancelled');
  assert.equal(q[0].error, null);
});

// ============================================================================
// 2. NON-BLOCKING UPLOAD ON EXTRACTION FAILURE / TIMEOUT
// ============================================================================

test('graceful degradation: catastrophic extraction error falls back to null thumbnail and uploads successfully', async () => {
  let passedThumbnail = 'INIT';

  const { transfersStore } = await loadTransfersStore(
    {
      uploadFileSingle: async ({ thumbnail }) => {
        passedThumbnail = thumbnail;
        return { ok: true };
      }
    },
    {
      isVideoFile: () => true,
      extractVideoPoster: async () => {
        throw new TypeError('Canvas rendering context is corrupted (GPU out of memory)');
      }
    }
  );

  const file = { name: 'codec_failure.mov', size: 5 * 1024 * 1024 };
  transfersStore.enqueueUpload(file);
  await settle(); await settle();

  assert.equal(passedThumbnail, null, 'Must pass null thumbnail on failure');
  assert.equal(get(transfersStore.queue)[0].status, 'completed');
});

test('graceful degradation: extraction with zero or NaN dimensions returns null and cleans up', async () => {
  const harness = createDomMockHarness({ width: 0, height: 0 });
  const file = new Blob(['empty-dim-video'], { type: 'video/mp4' });
  file.name = 'zero_dim.mp4';

  const result = await extractVideoPoster(file, {
    document: harness.document,
    urlApi: harness.urlApi
  });

  assert.equal(result, null);
  assert.deepEqual(harness.revokedUrls, ['blob:mock-zero_dim.mp4']);
  assert.equal(harness.video.src, '');
});

test('graceful degradation: canvas getContext 2d failure returns null gracefully', async () => {
  const harness = createDomMockHarness({ context2dNull: true });
  const file = new Blob(['video-payload'], { type: 'video/mp4' });
  file.name = 'no_context.mp4';

  const result = await extractVideoPoster(file, {
    document: harness.document,
    urlApi: harness.urlApi
  });

  assert.equal(result, null);
  assert.deepEqual(harness.revokedUrls, ['blob:mock-no_context.mp4']);
});

test('graceful degradation: canvas toBlob returning null produces null poster', async () => {
  const harness = createDomMockHarness({ toBlobNull: true });
  const file = new Blob(['video-payload'], { type: 'video/mp4' });
  file.name = 'to_blob_null.mp4';

  const result = await extractVideoPoster(file, {
    document: harness.document,
    urlApi: harness.urlApi
  });

  assert.equal(result, null);
  assert.deepEqual(harness.revokedUrls, ['blob:mock-to_blob_null.mp4']);
});

// ============================================================================
// 3. NULL / FALSY THUMBNAIL HANDLING IN UPLOAD FILES
// ============================================================================

test('uploadFileSingle: undefined, null, or empty thumbnail transmits raw File without FormData', async () => {
  const sentPayloads = [];
  const originalXhr = globalThis.XMLHttpRequest;

  globalThis.XMLHttpRequest = class {
    constructor() { this.upload = {}; }
    open() {}
    setRequestHeader() {}
    send(payload) {
      sentPayloads.push(payload);
      this.status = 200;
      this.responseText = JSON.stringify({ ok: true });
      queueMicrotask(() => this.onload());
    }
  };

  try {
    const { filesApi } = await loadFilesApi({});

    const file = new Blob(['raw-binary'], { type: 'video/mp4' });
    file.name = 'raw_test.mp4';

    // Test with null
    await filesApi.uploadFileSingle({ path: 'raw_test.mp4', file, thumbnail: null });
    // Test with undefined (default parameter)
    await filesApi.uploadFileSingle({ path: 'raw_test.mp4', file });
    // Test with false
    await filesApi.uploadFileSingle({ path: 'raw_test.mp4', file, thumbnail: false });

    assert.equal(sentPayloads.length, 3);
    for (const p of sentPayloads) {
      assert.ok(!(p instanceof FormData), 'Must NOT be FormData');
      assert.equal(p, file, 'Must be the raw file blob directly');
    }
  } finally {
    globalThis.XMLHttpRequest = originalXhr;
  }
});

// ============================================================================

// ============================================================================
// 4. CHUNK BOUNDARY OFFSETS & HEADERS IN UPLOADFILECHUNKED
// ============================================================================

test('uploadFileChunked: exact boundary slicing (fileSize 15MB, chunkSize 5MB -> exactly 3 chunks)', async () => {
  const posts = [];
  const thumbBase64 = Buffer.from('WEBP_POSTER').toString('base64');
  const thumbBlob = new Blob(['WEBP_POSTER'], { type: 'image/webp' });

  const totalSize = 15 * 1024 * 1024; // 15,728,640 bytes
  const chunkSize = 5 * 1024 * 1024;  // 5,242,880 bytes
  const dummyData = new Uint8Array(totalSize);
  const file = new Blob([dummyData], { type: 'video/mp4' });
  file.name = 'exact_chunks.mp4';

  const { filesApi } = await loadFilesApi({
    apiGet: async () => ({ bytes_received: 0 }),
    apiPost: async (url, chunk, options) => {
      posts.push({ url, chunk, options });
      return { ok: true };
    }
  });

  await filesApi.uploadFileChunked({
    path: 'exact_chunks.mp4',
    file,
    thumbnail: thumbBlob,
    chunkSize
  });

  assert.equal(posts.length, 3, 'Must be exactly 3 chunks');

  // Chunk 0: offset 0..5MB
  const u0 = new URL('http://localhost' + posts[0].url);
  assert.equal(u0.searchParams.get('offset'), '0');
  assert.equal(u0.searchParams.get('total'), totalSize.toString());
  assert.equal(u0.searchParams.get('is_last'), 'false');
  assert.equal(posts[0].chunk.size, chunkSize);
  assert.equal(posts[0].options?.headers?.['X-Thumbnail'], undefined);

  // Chunk 1: offset 5MB..10MB
  const u1 = new URL('http://localhost' + posts[1].url);
  assert.equal(u1.searchParams.get('offset'), chunkSize.toString());
  assert.equal(u1.searchParams.get('total'), totalSize.toString());
  assert.equal(u1.searchParams.get('is_last'), 'false');
  assert.equal(posts[1].chunk.size, chunkSize);
  assert.equal(posts[1].options?.headers?.['X-Thumbnail'], undefined);

  // Chunk 2: offset 10MB..15MB (is_last = true)
  const u2 = new URL('http://localhost' + posts[2].url);
  assert.equal(u2.searchParams.get('offset'), (chunkSize * 2).toString());
  assert.equal(u2.searchParams.get('total'), totalSize.toString());
  assert.equal(u2.searchParams.get('is_last'), 'true');
  assert.equal(posts[2].chunk.size, chunkSize);
  assert.equal(posts[2].options?.headers?.['X-Thumbnail'], thumbBase64);
});

test('uploadFileChunked: uneven boundary slicing (fileSize 11MB, chunkSize 5MB -> 5MB, 5MB, 1MB)', async () => {
  const posts = [];
  const totalSize = 11 * 1024 * 1024;
  const chunkSize = 5 * 1024 * 1024;
  const file = new Blob([new Uint8Array(totalSize)], { type: 'video/mp4' });
  file.name = 'uneven_chunks.mp4';
  const thumbBlob = new Blob(['THUMB'], { type: 'image/webp' });

  const { filesApi } = await loadFilesApi({
    apiGet: async () => ({ bytes_received: 0 }),
    apiPost: async (url, chunk, options) => {
      posts.push({ url, chunk, options });
      return { ok: true };
    }
  });

  await filesApi.uploadFileChunked({
    path: 'uneven_chunks.mp4',
    file,
    thumbnail: thumbBlob,
    chunkSize
  });

  assert.equal(posts.length, 3);
  assert.equal(posts[0].chunk.size, 5 * 1024 * 1024);
  assert.equal(posts[1].chunk.size, 5 * 1024 * 1024);
  assert.equal(posts[2].chunk.size, 1 * 1024 * 1024);

  const uTerminal = new URL('http://localhost' + posts[2].url);
  assert.equal(uTerminal.searchParams.get('offset'), (10 * 1024 * 1024).toString());
  assert.equal(uTerminal.searchParams.get('is_last'), 'true');
  assert.ok(posts[2].options?.headers?.['X-Thumbnail']);
});

test('uploadFileChunked: single chunk when totalSize <= chunkSize', async () => {
  const posts = [];
  const totalSize = 3 * 1024 * 1024;
  const chunkSize = 5 * 1024 * 1024;
  const file = new Blob([new Uint8Array(totalSize)], { type: 'video/mp4' });
  file.name = 'small_chunked.mp4';
  const thumbBlob = new Blob(['THUMB_SINGLE'], { type: 'image/webp' });

  const { filesApi } = await loadFilesApi({
    apiGet: async () => ({ bytes_received: 0 }),
    apiPost: async (url, chunk, options) => {
      posts.push({ url, chunk, options });
      return { ok: true };
    }
  });

  await filesApi.uploadFileChunked({
    path: 'small_chunked.mp4',
    file,
    thumbnail: thumbBlob,
    chunkSize
  });

  assert.equal(posts.length, 1, 'Must send exactly 1 chunk');
  const u = new URL('http://localhost' + posts[0].url);
  assert.equal(u.searchParams.get('offset'), '0');
  assert.equal(u.searchParams.get('total'), totalSize.toString());
  assert.equal(u.searchParams.get('is_last'), 'true');
  assert.ok(posts[0].options?.headers?.['X-Thumbnail']);
});

test('uploadFileChunked: resumed upload from midpoint attaches X-Thumbnail strictly on terminal chunk', async () => {
  const posts = [];
  const totalSize = 15 * 1024 * 1024;
  const chunkSize = 5 * 1024 * 1024;
  const file = new Blob([new Uint8Array(totalSize)], { type: 'video/mp4' });
  file.name = 'resumed.mp4';
  const thumbBlob = new Blob(['RESUMED_THUMB'], { type: 'image/webp' });

  const { filesApi } = await loadFilesApi({
    // Server reports 5MB already received
    apiGet: async () => ({ bytes_received: 5 * 1024 * 1024 }),
    apiPost: async (url, chunk, options) => {
      posts.push({ url, chunk, options });
      return { ok: true };
    }
  });

  await filesApi.uploadFileChunked({
    path: 'resumed.mp4',
    file,
    thumbnail: thumbBlob,
    chunkSize
  });

  // Only remaining 10MB (2 chunks) should be sent
  assert.equal(posts.length, 2);

  const u0 = new URL('http://localhost' + posts[0].url);
  assert.equal(u0.searchParams.get('offset'), (5 * 1024 * 1024).toString());
  assert.equal(u0.searchParams.get('is_last'), 'false');
  assert.equal(posts[0].options?.headers?.['X-Thumbnail'], undefined);

  const u1 = new URL('http://localhost' + posts[1].url);
  assert.equal(u1.searchParams.get('offset'), (10 * 1024 * 1024).toString());
  assert.equal(u1.searchParams.get('is_last'), 'true');
  assert.ok(posts[1].options?.headers?.['X-Thumbnail']);
});

test('uploadFileChunked: corrupt thumbnail object gracefully omits header without failing upload', async () => {
  const posts = [];
  const totalSize = 2000;
  const file = new Blob(['A'.repeat(totalSize)], { type: 'video/mp4' });
  file.name = 'corrupt_thumb.mp4';

  // Object claiming to be Blob but throwing on arrayBuffer
  const badThumbnail = {
    arrayBuffer: async () => {
      throw new Error('Storage read failure');
    }
  };

  const { filesApi } = await loadFilesApi({
    apiGet: async () => ({ bytes_received: 0 }),
    apiPost: async (url, chunk, options) => {
      posts.push({ url, chunk, options });
      return { ok: true };
    }
  });

  const res = await filesApi.uploadFileChunked({
    path: 'corrupt_thumb.mp4',
    file,
    thumbnail: badThumbnail,
    chunkSize: 1000
  });

  assert.deepEqual(res, { ok: true, completed: true });
  assert.equal(posts.length, 2);
  const terminalPost = posts[1];
  assert.ok(terminalPost.url.includes('is_last=true'));
  assert.equal(terminalPost.options?.headers?.['X-Thumbnail'], undefined);
});

// ============================================================================
// 5. RAPID CONCURRENCY & CHURN STRESS
// ============================================================================

test('concurrency stress: 15 mixed uploads with concurrent extractions enforce max 3 active concurrency', async () => {
  let activeUploads = 0;
  let maxConcurrentUploads = 0;
  let completedCount = 0;

  const { transfersStore } = await loadTransfersStore(
    {
      uploadFileSingle: async () => {
        activeUploads++;
        if (activeUploads > maxConcurrentUploads) {
          maxConcurrentUploads = activeUploads;
        }
        await sleep(15);
        activeUploads--;
        completedCount++;
        return { ok: true };
      }
    },
    {
      isVideoFile: (f) => f.name.endsWith('.mp4'),
      extractVideoPoster: async () => {
        await sleep(10);
        return new Blob(['poster'], { type: 'image/webp' });
      }
    }
  );

  const files = Array.from({ length: 15 }, (_, i) => ({
    name: `video_${i}.${i % 2 === 0 ? 'mp4' : 'txt'}`,
    size: 1024 * 1024
  }));

  transfersStore.enqueueBatch(files);

  // Poll until all completed
  for (let i = 0; i < 50; i++) {
    await sleep(20);
    const q = get(transfersStore.queue);
    if (q.every(t => t.status === 'completed')) break;
  }

  const q = get(transfersStore.queue);
  assert.equal(q.length, 15);
  assert.ok(q.every(t => t.status === 'completed'), 'All 15 transfers must complete');
  assert.ok(maxConcurrentUploads <= 3, `Max concurrent uploads (${maxConcurrentUploads}) must not exceed 3`);
});
