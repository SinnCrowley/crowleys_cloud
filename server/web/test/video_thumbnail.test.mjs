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

// ============================================================================
// Mock Infrastructure & Dependency Loaders
// ============================================================================

let serial = 0;

async function loadTransfersStore(api, videoUtil = {}) {
  const apiKey = `testApi${serial++}`;
  const videoKey = `testVideoUtil${serial++}`;
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
  const key = `testApi${serial++}`;
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
      `const authStore = globalThis.${key}.authStore || { accessToken: { subscribe: cb => { cb('mock-token'); return () => {}; } }, refreshToken: { subscribe: cb => { cb('mock-refresh'); return () => {}; } } };`
    )
    .replace("from '../utils/videoThumbnail.js'", `from '${import.meta.resolve('../src/utils/videoThumbnail.js')}'`);

  return import(`data:text/javascript;base64,${Buffer.from(source).toString('base64')}`);
}

const settle = () => new Promise(resolve => setImmediate(resolve));

function createDomMockHarness({
  width = 1920,
  height = 1080,
  duration = 10,
  triggerError = false,
  hang = false,
  toBlobResult = new Blob(['mock-webp-frame-data'], { type: 'image/webp' })
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
      if (type !== '2d') return null;
      return {
        drawImage: (v, x, y, w, h) => {
          this.drawn = { v, x, y, w, h };
        }
      };
    }
    toBlob(cb, type, quality) {
      this.exported = { type, quality };
      queueMicrotask(() => cb(toBlobResult));
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
// Unit Tests: clampDimensions
// ============================================================================

test('clampDimensions: clamps landscape video (1920x1080) to max 512x288 preserving aspect ratio', () => {
  const result = clampDimensions(1920, 1080, 512);
  assert.deepEqual(result, { width: 512, height: 288 });
});

test('clampDimensions: clamps portrait video (1080x1920) to max 288x512 preserving aspect ratio', () => {
  const result = clampDimensions(1080, 1920, 512);
  assert.deepEqual(result, { width: 288, height: 512 });
});

test('clampDimensions: clamps square video (1000x1000) to max 512x512', () => {
  const result = clampDimensions(1000, 1000, 512);
  assert.deepEqual(result, { width: 512, height: 512 });
});

test('clampDimensions: preserves smaller video dimensions without upscaling', () => {
  assert.deepEqual(clampDimensions(320, 240, 512), { width: 320, height: 240 });
  assert.deepEqual(clampDimensions(512, 512, 512), { width: 512, height: 512 });
  assert.deepEqual(clampDimensions(200, 400, 512), { width: 200, height: 400 });
});

test('clampDimensions: handles non-positive and non-finite dimensions gracefully', () => {
  assert.deepEqual(clampDimensions(0, 100, 512), { width: 0, height: 0 });
  assert.deepEqual(clampDimensions(100, -10, 512), { width: 0, height: 0 });
  assert.deepEqual(clampDimensions(NaN, 100, 512), { width: 0, height: 0 });
  assert.deepEqual(clampDimensions(100, Infinity, 512), { width: 0, height: 0 });
});

// ============================================================================
// Unit Tests: isVideoFile
// ============================================================================

test('isVideoFile: identifies video files by common extensions (case-insensitive)', () => {
  const exts = ['mp4', 'mkv', 'avi', 'mov', 'webm', 'flv', 'wmv', 'm4v', '3gp', 'ts', 'ogg'];
  for (const ext of exts) {
    assert.equal(isVideoFile(`video.${ext}`), true, `Failed for .${ext}`);
    assert.equal(isVideoFile(`video.${ext.toUpperCase()}`), true, `Failed for uppercase .${ext.toUpperCase()}`);
    assert.equal(isVideoFile({ name: `sample.${ext}` }), true, `Failed for object with .${ext}`);
  }
});

test('isVideoFile: identifies video files by MIME type prefix', () => {
  const mimes = ['video/mp4', 'video/webm', 'video/quicktime', 'video/x-matroska', 'video/ogg'];
  for (const type of mimes) {
    assert.equal(isVideoFile({ type }), true, `Failed for type: ${type}`);
    assert.equal(isVideoFile({ name: 'unknown_ext.bin', type }), true, `Failed for bin with type: ${type}`);
  }
});

test('isVideoFile: returns false for non-video files and falsy inputs', () => {
  const nonVideos = [
    'document.pdf', 'photo.jpg', 'image.png', 'audio.mp3', 'archive.zip',
    { name: 'picture.webp', type: 'image/webp' },
    { name: 'audio.wav', type: 'audio/wav' },
    { name: 'doc.txt', type: 'text/plain' },
    null, undefined, '', '   ', {}, { name: '' }, 42
  ];
  for (const item of nonVideos) {
    assert.equal(isVideoFile(item), false, `Expected false for ${JSON.stringify(item)}`);
  }
});

// ============================================================================
// Unit Tests: blobToBase64
// ============================================================================

test('blobToBase64: converts Blob to base64 string accurately', async () => {
  const sampleText = 'WebP binary simulation data';
  const blob = new Blob([sampleText], { type: 'image/webp' });
  const b64 = await blobToBase64(blob);
  const expected = Buffer.from(sampleText).toString('base64');
  assert.equal(b64, expected);
});

test('blobToBase64: handles data URI string input by stripping prefix', async () => {
  const dataUri = 'data:image/webp;base64,QUJDREVGRw==';
  assert.equal(await blobToBase64(dataUri), 'QUJDREVGRw==');
  assert.equal(await blobToBase64('plainBase64String'), 'plainBase64String');
});

test('blobToBase64: returns null for null or undefined input', async () => {
  assert.equal(await blobToBase64(null), null);
  assert.equal(await blobToBase64(undefined), null);
});

// ============================================================================
// Unit Tests: extractVideoPoster
// ============================================================================

test('extractVideoPoster: extracts and clamps landscape video to 512x288', async () => {
  const harness = createDomMockHarness({ width: 1920, height: 1080 });
  const file = new Blob(['video-payload'], { type: 'video/mp4' });
  file.name = 'movie.mp4';

  const posterBlob = await extractVideoPoster(file, {
    maxDimension: 512,
    document: harness.document,
    urlApi: harness.urlApi
  });

  assert.ok(posterBlob);
  assert.equal(posterBlob.type, 'image/webp');
  assert.equal(harness.canvas.drawn.w, 512);
  assert.equal(harness.canvas.drawn.h, 288);
  assert.deepEqual(harness.revokedUrls, ['blob:mock-movie.mp4']);
  assert.equal(harness.video.src, '');
});

test('extractVideoPoster: extracts and clamps portrait video to 288x512', async () => {
  const harness = createDomMockHarness({ width: 1080, height: 1920 });
  const file = new Blob(['video-payload'], { type: 'video/mp4' });
  file.name = 'story.mp4';

  const posterBlob = await extractVideoPoster(file, {
    maxSize: 512,
    document: harness.document,
    urlApi: harness.urlApi
  });

  assert.ok(posterBlob);
  assert.equal(harness.canvas.drawn.w, 288);
  assert.equal(harness.canvas.drawn.h, 512);
  assert.deepEqual(harness.revokedUrls, ['blob:mock-story.mp4']);
});

test('extractVideoPoster: preserves small dimensions without upscaling (320x240)', async () => {
  const harness = createDomMockHarness({ width: 320, height: 240 });
  const file = new Blob(['video-payload'], { type: 'video/webm' });
  file.name = 'clip.webm';

  const posterBlob = await extractVideoPoster(file, {
    maxDimension: 512,
    document: harness.document,
    urlApi: harness.urlApi
  });

  assert.ok(posterBlob);
  assert.equal(harness.canvas.drawn.w, 320);
  assert.equal(harness.canvas.drawn.h, 240);
});

test('extractVideoPoster: returns null gracefully and cleans up on decode error', async () => {
  const harness = createDomMockHarness({ triggerError: true });
  const file = new Blob(['corrupted'], { type: 'video/mp4' });
  file.name = 'corrupted.mp4';

  const result = await extractVideoPoster(file, {
    document: harness.document,
    urlApi: harness.urlApi
  });

  assert.equal(result, null);
  assert.deepEqual(harness.revokedUrls, ['blob:mock-corrupted.mp4']);
  assert.equal(harness.video.src, '');
});

test('extractVideoPoster: returns null gracefully on timeout and cleans up resources', async () => {
  const harness = createDomMockHarness({ hang: true });
  const file = new Blob(['hang'], { type: 'video/mp4' });
  file.name = 'hang.mp4';

  const result = await extractVideoPoster(file, {
    timeout: 30,
    document: harness.document,
    urlApi: harness.urlApi
  });

  assert.equal(result, null);
  assert.deepEqual(harness.revokedUrls, ['blob:mock-hang.mp4']);
});

test('extractVideoPoster: returns null immediately when signal is aborted', async () => {
  const harness = createDomMockHarness();
  const file = new Blob(['video'], { type: 'video/mp4' });
  file.name = 'aborted.mp4';

  const ac = new AbortController();
  ac.abort();

  const result = await extractVideoPoster(file, {
    signal: ac.signal,
    document: harness.document,
    urlApi: harness.urlApi
  });

  assert.equal(result, null);
});

test('extractVideoPoster: rejects non-webp fallback blob format', async () => {
  const harness = createDomMockHarness({
    toBlobResult: new Blob(['png-data'], { type: 'image/png' })
  });
  const file = new Blob(['video'], { type: 'video/mp4' });
  file.name = 'unsupported_export.mp4';

  const result = await extractVideoPoster(file, {
    document: harness.document,
    urlApi: harness.urlApi
  });

  assert.equal(result, null);
});

test('extractVideoPoster: returns null immediately for non-video files or missing DOM', async () => {
  // Non-video file
  const docFile = new Blob(['text'], { type: 'text/plain' });
  docFile.name = 'doc.txt';
  assert.equal(await extractVideoPoster(docFile), null);

  // Video file in headless Node without custom document
  const videoFile = new Blob(['video'], { type: 'video/mp4' });
  videoFile.name = 'video.mp4';
  assert.equal(await extractVideoPoster(videoFile), null);
});

// ============================================================================
// Wire Integration Tests: filesApi Payloads
// ============================================================================

test('filesApi.uploadFileSingle sends FormData with thumbnail part when thumbnail is present', async () => {
  let sentPayload = null;
  const originalXhr = globalThis.XMLHttpRequest;

  globalThis.XMLHttpRequest = class {
    constructor() { this.upload = {}; }
    open(method, url) { this.url = url; }
    setRequestHeader() {}
    send(payload) {
      sentPayload = payload;
      this.status = 200;
      this.responseText = JSON.stringify({ ok: true });
      queueMicrotask(() => this.onload());
    }
  };

  try {
    const { filesApi } = await loadFilesApi({});
    const file = new Blob(['video-bytes'], { type: 'video/mp4' });
    file.name = 'sample.mp4';
    const thumbnail = new Blob(['thumbnail-bytes'], { type: 'image/webp' });

    await filesApi.uploadFileSingle({ path: 'sample.mp4', file, thumbnail });

    assert.ok(sentPayload instanceof FormData, 'Payload must be FormData');
    assert.ok(sentPayload.has('file'), 'Must have file field');
    assert.ok(sentPayload.has('thumbnail'), 'Must have thumbnail field');
    const thumbPart = sentPayload.get('thumbnail');
    assert.equal(thumbPart.name, 'thumbnail.webp');
  } finally {
    globalThis.XMLHttpRequest = originalXhr;
  }
});

test('filesApi.uploadFileSingle sends raw file Blob when thumbnail is null or omitted', async () => {
  let sentPayload = null;
  const originalXhr = globalThis.XMLHttpRequest;

  globalThis.XMLHttpRequest = class {
    constructor() { this.upload = {}; }
    open() {}
    setRequestHeader() {}
    send(payload) {
      sentPayload = payload;
      this.status = 200;
      this.responseText = JSON.stringify({ ok: true });
      queueMicrotask(() => this.onload());
    }
  };

  try {
    const { filesApi } = await loadFilesApi({});
    const file = new Blob(['plain-bytes'], { type: 'application/octet-stream' });
    file.name = 'archive.zip';

    await filesApi.uploadFileSingle({ path: 'archive.zip', file, thumbnail: null });

    assert.ok(!(sentPayload instanceof FormData), 'Payload must NOT be FormData');
    assert.equal(sentPayload, file);
  } finally {
    globalThis.XMLHttpRequest = originalXhr;
  }
});

test('filesApi.uploadFileChunked injects X-Thumbnail header strictly on is_last=true', async () => {
  const posts = [];
  const thumbnailBytes = 'MOCK_WEBP_CHUNK_DATA';
  const expectedBase64 = Buffer.from(thumbnailBytes).toString('base64');
  const thumbnailBlob = new Blob([thumbnailBytes], { type: 'image/webp' });

  // 1000 bytes with 400 chunkSize -> 3 chunks (chunk 0, 1: is_last=false, chunk 2: is_last=true)
  const fileContent = 'X'.repeat(1000);
  const file = new Blob([fileContent], { type: 'video/mp4' });
  file.name = 'stream.mp4';

  const { filesApi } = await loadFilesApi({
    apiGet: async () => ({ bytes_received: 0 }),
    apiPost: async (url, chunk, options) => {
      posts.push({ url, chunk, options });
      return { ok: true };
    }
  });

  await filesApi.uploadFileChunked({
    path: 'stream.mp4',
    file,
    thumbnail: thumbnailBlob,
    chunkSize: 400
  });

  assert.equal(posts.length, 3, 'Must send 3 chunks');

  // Chunks 0 & 1 must omit X-Thumbnail
  assert.ok(posts[0].url.includes('is_last=false'));
  assert.equal(posts[0].options?.headers?.['X-Thumbnail'], undefined);

  assert.ok(posts[1].url.includes('is_last=false'));
  assert.equal(posts[1].options?.headers?.['X-Thumbnail'], undefined);

  // Terminal Chunk 2 must include X-Thumbnail
  assert.ok(posts[2].url.includes('is_last=true'));
  const xThumb = posts[2].options?.headers?.['X-Thumbnail'] ||
                 (posts[2].options?.headers instanceof Headers && posts[2].options.headers.get('x-thumbnail'));
  assert.equal(xThumb, expectedBase64);
});

test('filesApi.uploadFileChunked omits X-Thumbnail header on terminal chunk when thumbnail is null', async () => {
  const posts = [];
  const file = new Blob(['A'.repeat(500)], { type: 'video/mp4' });
  file.name = 'no_thumb.mp4';

  const { filesApi } = await loadFilesApi({
    apiGet: async () => ({ bytes_received: 0 }),
    apiPost: async (url, chunk, options) => {
      posts.push({ url, chunk, options });
      return { ok: true };
    }
  });

  await filesApi.uploadFileChunked({
    path: 'no_thumb.mp4',
    file,
    thumbnail: null,
    chunkSize: 200
  });

  assert.equal(posts.length, 3);
  const terminalPost = posts[posts.length - 1];
  assert.ok(terminalPost.url.includes('is_last=true'));
  assert.equal(terminalPost.options?.headers?.['X-Thumbnail'], undefined);
});

// ============================================================================
// Store Integration Tests: transfersStore Pipeline
// ============================================================================

test('transfersStore: poster extraction failure or timeout does not block upload completion', async () => {
  let uploadCalled = false;
  let passedThumbnail = 'UNSET';

  const { transfersStore } = await loadTransfersStore(
    {
      uploadFileSingle: async ({ file, thumbnail }) => {
        uploadCalled = true;
        passedThumbnail = thumbnail;
        return { ok: true };
      }
    },
    {
      isVideoFile: () => true,
      extractVideoPoster: async () => {
        throw new Error('Decoder crashed');
      }
    }
  );

  const file = { name: 'unsupported.mkv', size: 2 * 1024 * 1024 };
  transfersStore.enqueueUpload(file);
  await settle(); await settle();

  const queue = get(transfersStore.queue);
  assert.equal(uploadCalled, true, 'uploadFileSingle must be called even if extraction fails');
  assert.equal(passedThumbnail, null, 'Passed thumbnail must fall back to null');
  assert.equal(queue[0].status, 'completed', 'Transfer status must complete');
  assert.equal(queue[0].error, null, 'Error must remain null');
});

test('transfersStore: passes extracted thumbnail blob to single upload when extraction succeeds', async () => {
  let receivedThumbnail = null;
  const mockBlob = new Blob(['sample-webp-data'], { type: 'image/webp' });

  const { transfersStore } = await loadTransfersStore(
    {
      uploadFileSingle: async ({ file, thumbnail }) => {
        receivedThumbnail = thumbnail;
        return { ok: true };
      }
    },
    {
      isVideoFile: () => true,
      extractVideoPoster: async () => mockBlob
    }
  );

  const file = { name: 'clip.mp4', size: 1024 * 1024 };
  transfersStore.enqueueUpload(file);
  await settle(); await settle();

  assert.equal(receivedThumbnail, mockBlob);
  assert.equal(get(transfersStore.queue)[0].status, 'completed');
});

test('transfersStore: passes extracted thumbnail blob to chunked upload for files > 10MB', async () => {
  let chunkedCalled = false;
  let receivedThumbnail = null;
  const mockBlob = new Blob(['large-video-webp'], { type: 'image/webp' });

  const { transfersStore } = await loadTransfersStore(
    {
      uploadFileChunked: async ({ file, thumbnail }) => {
        chunkedCalled = true;
        receivedThumbnail = thumbnail;
        return { ok: true, completed: true };
      }
    },
    {
      isVideoFile: () => true,
      extractVideoPoster: async () => mockBlob
    }
  );

  const file = { name: 'huge.mp4', size: 12 * 1024 * 1024 }; // 12MB > 10MB
  transfersStore.enqueueUpload(file);
  await settle(); await settle();

  assert.equal(chunkedCalled, true);
  assert.equal(receivedThumbnail, mockBlob);
  assert.equal(get(transfersStore.queue)[0].status, 'completed');
});

test('transfersStore: pre-extraction cancellation aborts immediately without calling upload', async () => {
  let uploadCalled = false;

  const { transfersStore } = await loadTransfersStore(
    {
      uploadFileSingle: async () => {
        uploadCalled = true;
        return { ok: true };
      }
    },
    {
      isVideoFile: () => true,
      extractVideoPoster: async () => new Blob(['webp'], { type: 'image/webp' })
    }
  );

  const file = { name: 'abort_me.mp4', size: 1024 };
  const id = transfersStore.enqueueUpload(file);
  transfersStore.cancelTransfer(id);
  await settle(); await settle();

  assert.equal(uploadCalled, false, 'upload must not be called when cancelled before/during extraction');
  assert.equal(get(transfersStore.queue)[0].status, 'cancelled');
});
