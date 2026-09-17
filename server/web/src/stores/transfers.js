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

import { writable, derived, get } from 'svelte/store';
import { filesApi } from '../api/files.js';

const queue = writable([]);
const activeRequests = new Map();
const isDrawerOpen = writable(false);

/**
 * Derived count of active transfers (running or queued).
 */
export const activeCount = derived(queue, ($q) =>
  $q.filter((t) => t.status === 'running' || t.status === 'queued').length
);

/**
 * Derived total rolling speed across all active transfers (in bytes/sec).
 */
export const totalSpeed = derived(queue, ($q) =>
  $q
    .filter((t) => t.status === 'running')
    .reduce((sum, t) => sum + (t.speed || 0), 0)
);

export const transfersStore = {
  queue,
  isDrawerOpen,
  activeCount,
  totalSpeed,

  toggleDrawer() {
    isDrawerOpen.update((open) => !open);
  },

  enqueueUpload(file, scope = 'private', targetPath = '') {
    const id = `up_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const fullPath = targetPath ? `${targetPath}/${file.name}` : file.name;

    const transferItem = {
      id,
      name: file.name,
      type: 'upload',
      scope,
      path: fullPath,
      file,
      size: file.size,
      transferred: 0,
      progress: 0,
      speed: 0,
      status: 'queued',
      error: null,
      startTime: Date.now(),
      lastLoaded: 0,
      lastTime: Date.now()
    };

    queue.update((q) => [...q, transferItem]);
    this.processQueue();
    return id;
  },

  enqueueBatch(filesArray, scope = 'private', targetPath = '') {
    const arr = Array.from(filesArray || []);
    const newItems = arr.map((item) => {
      const file = item.file || item;
      const relPath = item.path || file.name;
      const id = `up_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
      const cleanTarget = targetPath.replace(/\/+$/, '');
      const fullPath = cleanTarget ? `${cleanTarget}/${relPath}` : relPath;

      return {
        id,
        name: file.name,
        type: 'upload',
        scope,
        path: fullPath,
        file,
        size: file.size,
        transferred: 0,
        progress: 0,
        speed: 0,
        status: 'queued',
        error: null,
        startTime: Date.now(),
        lastLoaded: 0,
        lastTime: Date.now()
      };
    });

    queue.update((q) => [...q, ...newItems]);
    this.processQueue();
  },

  processQueue() {
    for (const item of get(queue)) {
      if (activeRequests.size >= 3) break;
      if (item.status !== 'queued' || activeRequests.has(item.id)) continue;
      const controller = new AbortController();
      activeRequests.set(item.id, controller);
      queue.update(q => q.map(t => t.id === item.id
        ? { ...t, status: 'running', lastTime: Date.now(), lastLoaded: 0, speed: 0 } : t));
      this.executeUpload(item, controller);
    }
  },

  async executeUpload(item, controller) {
    const updateProgress = (loaded, total) => {
      const now = Date.now();
      queue.update((q) =>
        q.map((t) => {
          if (t.id !== item.id) return t;
          if (t.status !== 'running' || controller.signal.aborted) return t;

          const dt = (now - (t.lastTime || now)) / 1000;
          let newSpeed = t.speed || 0;

          if (dt >= 0.3) {
            const dBytes = loaded - (t.lastLoaded || 0);
            newSpeed = Math.max(0, Math.round(dBytes / dt));
          }

          return {
            ...t,
            transferred: loaded,
            progress: total > 0 ? Math.round((loaded / total) * 100) : 0,
            speed: newSpeed,
            lastLoaded: dt >= 0.3 ? loaded : t.lastLoaded,
            lastTime: dt >= 0.3 ? now : t.lastTime
          };
        })
      );
    };

    try {
      if (item.size > 10 * 1024 * 1024) {
        // Chunked upload for files > 10MB
        await filesApi.uploadFileChunked({
          scope: item.scope,
          path: item.path,
          file: item.file,
          onProgress: updateProgress,
          signal: controller.signal
        });
      } else {
        // Single upload for small files
        await filesApi.uploadFileSingle({
          scope: item.scope,
          path: item.path,
          file: item.file,
          onProgress: updateProgress,
          signal: controller.signal
        });
      }

      queue.update((q) =>
        q.map((t) => {
          if (t.id !== item.id) return t;
          if (t.status !== 'running' || controller.signal.aborted) return t;
          return { ...t, status: 'completed', progress: 100, transferred: item.size, speed: 0 };
        })
      );
    } catch (err) {
      queue.update((q) =>
        q.map((t) => {
          if (t.id !== item.id) return t;
          if (controller.signal.aborted || t.status === 'cancelled' || t.status === 'paused') return t;
          return { ...t, status: 'failed', error: err.message || 'Upload failed', speed: 0 };
        })
      );
    } finally {
      activeRequests.delete(item.id);
      this.processQueue();
    }
  },

  pauseTransfer(id) {
    queue.update((q) =>
      q.map((t) => (t.id === id && (t.status === 'running' || t.status === 'queued') ? { ...t, status: 'paused', speed: 0 } : t))
    );
    activeRequests.get(id)?.abort();
  },

  resumeTransfer(id) {
    queue.update((q) =>
      q.map((t) => (t.id === id && t.status === 'paused' ? { ...t, status: 'queued' } : t))
    );
    this.processQueue();
  },

  cancelTransfer(id) {
    queue.update((q) =>
      q.map((t) => (t.id === id && t.status !== 'completed' && t.status !== 'failed' && t.status !== 'cancelled' ? { ...t, status: 'cancelled', speed: 0 } : t))
    );
    activeRequests.get(id)?.abort();
    this.processQueue();
  },

  pauseAll() {
    queue.update((q) =>
      q.map((t) =>
        t.status === 'running' || t.status === 'queued'
          ? { ...t, status: 'paused', speed: 0 }
          : t
      )
    );
    for (const controller of activeRequests.values()) controller.abort();
  },

  resumeAll() {
    queue.update((q) =>
      q.map((t) => (t.status === 'paused' ? { ...t, status: 'queued' } : t))
    );
    this.processQueue();
  },

  togglePauseAll() {
    let hasActive = false;
    queue.subscribe((q) => {
      hasActive = q.some((t) => t.status === 'running' || t.status === 'queued');
    })();

    if (hasActive) {
      this.pauseAll();
    } else {
      this.resumeAll();
    }
  },

  cancelAll() {
    queue.update((q) =>
      q.map((t) =>
        t.status === 'running' || t.status === 'queued' || t.status === 'paused'
          ? { ...t, status: 'cancelled', speed: 0 }
          : t
      )
    );
    for (const controller of activeRequests.values()) controller.abort();
    this.processQueue();
  },

  clearCompleted() {
    queue.update((q) =>
      q.filter((t) => t.status !== 'completed' && t.status !== 'failed' && t.status !== 'cancelled')
    );
  }
};
