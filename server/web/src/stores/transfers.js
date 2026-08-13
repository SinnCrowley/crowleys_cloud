import { writable, derived } from 'svelte/store';
import { filesApi } from '../api/files.js';

const queue = writable([]);
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

  async processQueue() {
    queue.update((q) => {
      const runningCount = q.filter((t) => t.status === 'running').length;
      let available = Math.max(0, 3 - runningCount);

      if (available <= 0) return q;

      return q.map((item) => {
        if (item.status === 'queued' && available > 0) {
          available--;
          this.executeUpload(item);
          return { ...item, status: 'running', lastTime: Date.now(), lastLoaded: 0, speed: 0 };
        }
        return item;
      });
    });
  },

  async executeUpload(item) {
    const updateProgress = (loaded, total) => {
      const now = Date.now();
      queue.update((q) =>
        q.map((t) => {
          if (t.id !== item.id) return t;
          if (t.status !== 'running') return t;

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
          onProgress: updateProgress
        });
      } else {
        // Single upload for small files
        await filesApi.uploadFileSingle({
          scope: item.scope,
          path: item.path,
          file: item.file,
          onProgress: updateProgress
        });
      }

      queue.update((q) =>
        q.map((t) => {
          if (t.id !== item.id) return t;
          if (t.status !== 'running') return t;
          return { ...t, status: 'completed', progress: 100, transferred: item.size, speed: 0 };
        })
      );
    } catch (err) {
      queue.update((q) =>
        q.map((t) => {
          if (t.id !== item.id) return t;
          if (t.status === 'cancelled' || t.status === 'paused') return t;
          return { ...t, status: 'failed', error: err.message || 'Upload failed', speed: 0 };
        })
      );
    } finally {
      this.processQueue();
    }
  },

  pauseTransfer(id) {
    queue.update((q) =>
      q.map((t) => (t.id === id && (t.status === 'running' || t.status === 'queued') ? { ...t, status: 'paused', speed: 0 } : t))
    );
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
    this.processQueue();
  },

  clearCompleted() {
    queue.update((q) =>
      q.filter((t) => t.status !== 'completed' && t.status !== 'failed' && t.status !== 'cancelled')
    );
  }
};
