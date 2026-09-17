import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { get } from 'svelte/store';

let serial = 0;
async function loadStore(name, api) {
  const key = `reviewApi${serial++}`;
  globalThis[key] = api;
  let source = await readFile(new URL(`../src/stores/${name}.js`, import.meta.url), 'utf8');
  source = source.replace("from 'svelte/store'", `from '${import.meta.resolve('svelte/store')}'`)
    .replace("import { filesApi } from '../api/files.js';", `const filesApi = globalThis.${key};`);
  return import(`data:text/javascript;base64,${Buffer.from(source).toString('base64')}`);
}
const settle = () => new Promise(resolve => setImmediate(resolve));

test('out-of-order directory responses and clear do not restore stale entries', async () => {
  const pending = [];
  const { filesStore } = await loadStore('files', {
    listDir: () => new Promise(resolve => pending.push(resolve)),
  });
  const a = filesStore.navigateTo('A');
  const b = filesStore.navigateTo('B');
  pending[1]({ entries: ['B/file'] }); await b;
  pending[0]({ entries: ['A/file'] }); await a;
  assert.equal(get(filesStore.currentPath), 'B');
  assert.deepEqual(get(filesStore.entries), ['B/file']);
  const c = filesStore.loadDirectory(); filesStore.clear();
  pending[2]({ entries: ['B/file'] }); await c;
  assert.deepEqual(get(filesStore.entries), []);
});

test('pause/resume waits for aborted upload and cancellation reaches the request', async () => {
  const requests = [];
  let running = 0, peak = 0;
  const upload = ({ signal }) => new Promise((resolve, reject) => {
    running++; peak = Math.max(peak, running);
    requests.push({ signal, finish: () => { running--; resolve(); } });
    signal.addEventListener('abort', () => setImmediate(() => {
      running--; reject(new DOMException('Aborted', 'AbortError'));
    }), { once: true });
  });
  const { transfersStore } = await loadStore('transfers', { uploadFileSingle: upload, uploadFileChunked: upload });
  const id = transfersStore.enqueueUpload({ name: 'test', size: 20 });
  transfersStore.pauseTransfer(id); transfersStore.resumeTransfer(id);
  assert.equal(requests.length, 1);
  assert.equal(requests[0].signal.aborted, true);
  await settle(); await settle();
  assert.equal(requests.length, 2);
  assert.equal(peak, 1);
  transfersStore.cancelTransfer(id); await settle(); await settle();
  assert.equal(running, 0);
  assert.equal(get(transfersStore.queue)[0].status, 'cancelled');
});

test('pause all and resume all preserve the three-request concurrency limit', async () => {
  let running = 0, peak = 0;
  const upload = ({ signal }) => new Promise((resolve, reject) => {
    running++; peak = Math.max(peak, running);
    signal.addEventListener('abort', () => setImmediate(() => {
      running--; reject(new DOMException('Aborted', 'AbortError'));
    }), { once: true });
  });
  const { transfersStore } = await loadStore('transfers', { uploadFileSingle: upload });
  transfersStore.enqueueBatch(Array.from({ length: 5 }, (_, i) => ({ name: `${i}`, size: 20 })));
  transfersStore.pauseAll(); transfersStore.resumeAll();
  await settle(); await settle();
  assert.equal(peak, 3);
  transfersStore.cancelAll(); await settle(); await settle();
  assert.equal(running, 0);
  assert.ok(get(transfersStore.queue).every(item => item.status === 'cancelled'));
});

async function loadApi(client) {
  const key = `reviewApi${serial++}`;
  globalThis[key] = client;
  let source = await readFile(new URL('../src/api/files.js', import.meta.url), 'utf8');
  source = source.replace("from 'svelte/store'", `from '${import.meta.resolve('svelte/store')}'`)
    .replace("import { apiGet, apiPost, apiDelete, apiMessage } from './client.js';",
      `const { apiGet, apiPost, apiDelete, apiMessage } = globalThis.${key};`)
    .replace("import { authStore } from '../stores/auth.js';",
      `const authStore = {accessToken: { subscribe: callback => {callback('token'); return () => {};}}};`);
  return import(`data:text/javascript;base64,${Buffer.from(source).toString('base64')}`);
}

test('single upload aborts its XHR and rejects instead of completing', async () => {
  let xhr;
  const original = globalThis.XMLHttpRequest;
  globalThis.XMLHttpRequest = class {
    constructor() { xhr = this; this.upload = {}; }
    open() {}
    setRequestHeader() {}
    send() { this.sent = true; }
    abort() { this.aborted = true; this.onabort(); this.onloadend(); }
  };
  try {
    const { filesApi } = await loadApi({});
    const controller = new AbortController();
    const pending = filesApi.uploadFileSingle({ path: 'test', file: new Blob(['test']), signal: controller.signal });
    const rejected = assert.rejects(pending, { name: 'AbortError' });
    controller.abort(); await rejected;
    assert.equal(xhr.sent, true); assert.equal(xhr.aborted, true);
  } finally { globalThis.XMLHttpRequest = original; }
});

test('chunk upload forwards cancellation and does not send remaining chunks', async () => {
  const controller = new AbortController();
  let chunks = 0;
  const { filesApi } = await loadApi({
    apiGet: async (url, options) => {
      assert.equal(options.signal, controller.signal);
      return { bytes_received: 0 };
    },
    apiPost: async (url, blob, options) => {
      assert.equal(options.signal, controller.signal);
      chunks++; controller.abort();
    },
  });
  await assert.rejects(filesApi.uploadFileChunked({
    path: 'test', file: new Blob(['abcdef']), chunkSize: 2, signal: controller.signal,
  }), { name: 'AbortError' });
  assert.equal(chunks, 1);
});
