import { apiGet, apiPost, apiDelete } from './client.js';
import { get } from 'svelte/store';
import { authStore } from '../stores/auth.js';

export const filesApi = {
  async listDir({ scope = 'private', path = '', type = 'all', q = '', sort = 'name', order = 'asc' } = {}) {
    const params = new URLSearchParams({ scope });
    if (path) params.append('path', path);
    if (type && type !== 'all') params.append('type', type);
    if (q) params.append('q', q);
    if (sort) params.append('sort', sort);
    if (order) params.append('order', order);

    return apiGet(`/api/dir?${params.toString()}`);
  },

  getDownloadUrl({ scope = 'private', path }) {
    const params = new URLSearchParams({ scope, path });
    const token = get(authStore.accessToken);
    if (token) params.append('token', token);
    return `/api/files?${params.toString()}`;
  },

  getZipDownloadUrl({ scope = 'private', path = '' }) {
    const params = new URLSearchParams({ scope });
    if (path) params.append('path', path);
    const token = get(authStore.accessToken);
    if (token) params.append('token', token);
    return `/api/files/zip?${params.toString()}`;
  },

  async downloadFile({ scope = 'private', path, filename }) {
    const url = this.getDownloadUrl({ scope, path });
    const blob = await apiGet(url);
    
    // Create temporary download link
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = filename || path.split('/').pop() || 'download';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(link.href);
  },

  async downloadZip({ scope = 'private', path = '', filename }) {
    const url = this.getZipDownloadUrl({ scope, path });
    const blob = await apiGet(url);

    const defaultName = path ? `${path.split('/').pop()}.zip` : 'files.zip';
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = filename || defaultName;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(link.href);
  },

  uploadFileSingle({ scope = 'private', path, file, onProgress }, isRetry = false) {
    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest();
      const params = new URLSearchParams({ scope, path });
      xhr.open('POST', `/api/files?${params.toString()}`);

      const token = get(authStore.accessToken);
      if (token) {
        xhr.setRequestHeader('Authorization', `Bearer ${token}`);
      }

      if (onProgress && xhr.upload) {
        xhr.upload.onprogress = (event) => {
          if (event.lengthComputable) {
            onProgress(event.loaded, event.total);
          }
        };
      }

      xhr.onload = async () => {
        if (xhr.status >= 200 && xhr.status < 300) {
          try {
            resolve(JSON.parse(xhr.responseText));
          } catch (e) {
            resolve({ ok: true });
          }
        } else if (xhr.status === 401 && !isRetry) {
          try {
            const refreshToken = get(authStore.refreshToken);
            if (!refreshToken) {
              authStore.clearSession();
              reject(new Error('Upload failed with status 401'));
              return;
            }

            const refreshRes = await fetch('/api/refresh', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ refresh_token: refreshToken })
            });

            if (!refreshRes.ok) {
              authStore.clearSession();
              reject(new Error('Upload failed with status 401'));
              return;
            }

            const refreshData = await refreshRes.json();
            authStore.setSession({
              accessToken: refreshData.access_token,
              refreshToken: refreshData.refresh_token
            });

            const retryResult = await this.uploadFileSingle({ scope, path, file, onProgress }, true);
            resolve(retryResult);
          } catch (err) {
            authStore.clearSession();
            reject(new Error('Upload failed with status 401'));
          }
        } else {
          reject(new Error(`Upload failed with status ${xhr.status}`));
        }
      };

      xhr.onerror = () => reject(new Error('Network upload error'));
      xhr.send(file);
    });
  },

  uploadFilesBatch({ scope = 'private', path = '', files, onProgress }) {
    return new Promise((resolve, reject) => {
      const formData = new FormData();
      const filesArr = Array.from(files || []);
      filesArr.forEach((file) => {
        const itemFile = file.file || file;
        formData.append('files', itemFile, itemFile.name);
      });

      const params = new URLSearchParams({ scope });
      if (path) params.append('path', path);

      const xhr = new XMLHttpRequest();
      xhr.open('POST', `/api/files/upload?${params.toString()}`);

      const token = localStorage.getItem('cc_access_token');
      if (token) {
        xhr.setRequestHeader('Authorization', `Bearer ${token}`);
      }

      if (onProgress && xhr.upload) {
        xhr.upload.onprogress = (event) => {
          if (event.lengthComputable) {
            onProgress(event.loaded, event.total);
          }
        };
      }

      xhr.onload = () => {
        if (xhr.status >= 200 && xhr.status < 300) {
          try {
            const data = JSON.parse(xhr.responseText);
            resolve(data);
          } catch (e) {
            resolve({ ok: true });
          }
        } else {
          try {
            const data = JSON.parse(xhr.responseText);
            reject(new Error(data.error || `Batch upload failed (${xhr.status})`));
          } catch (e) {
            reject(new Error(`Batch upload failed (${xhr.status})`));
          }
        }
      };

      xhr.onerror = () => reject(new Error('Network batch upload error'));
      xhr.send(formData);
    });
  },

  async uploadFileChunked({ scope = 'private', path, file, chunkSize = 5 * 1024 * 1024, onProgress }) {
    const totalSize = file.size;
    let offset = 0;

    // Check resume status first
    try {
      const status = await this.getUploadStatus({ scope, path });
      if (status && typeof status.bytes_received === 'number') {
        offset = status.bytes_received;
      }
    } catch (e) {
      // Offset remains 0 if status query fails
    }

    while (offset < totalSize) {
      const chunkEnd = Math.min(offset + chunkSize, totalSize);
      const isLast = chunkEnd >= totalSize;
      const chunk = file.slice(offset, chunkEnd);

      const params = new URLSearchParams({
        scope,
        path,
        offset: offset.toString(),
        total: totalSize.toString(),
        is_last: isLast.toString()
      });

      await apiPost(`/api/files?${params.toString()}`, chunk);
      offset = chunkEnd;

      if (onProgress) {
        onProgress(offset, totalSize);
      }
    }

    return { ok: true, completed: true };
  },

  async getUploadStatus({ scope = 'private', path }) {
    const params = new URLSearchParams({ scope, path });
    return apiGet(`/api/files/upload-status?${params.toString()}`);
  },

  getThumbnailUrl({ scope = 'private', path, trashId, size = 256 }) {
    const params = new URLSearchParams({ s: size.toString() });
    if (trashId) {
      params.append('trash_id', trashId.toString());
    } else {
      params.append('scope', scope);
      if (path) params.append('path', path);
    }
    const token = get(authStore.accessToken);
    if (token) params.append('token', token);
    return `/api/thumb?${params.toString()}`;
  },

  async createFolder({ scope = 'private', path }) {
    const params = new URLSearchParams({ scope, path });
    return apiPost(`/api/folders?${params.toString()}`);
  },

  async renameFile({ scope = 'private', path, newName }) {
    const dirPath = path.includes('/') ? path.substring(0, path.lastIndexOf('/')) : '';
    const newPath = dirPath ? `${dirPath}/${newName}` : newName;
    const params = new URLSearchParams({ scope, src: path, dest: newPath });
    return apiPost(`/api/files/move?${params.toString()}`);
  },

  async moveFile({ scope = 'private', srcPath, destFolder }) {
    const filename = srcPath.split('/').pop();
    const cleanDest = destFolder.replace(/\/+$/, '');
    const destPath = cleanDest ? `${cleanDest}/${filename}` : filename;
    const params = new URLSearchParams({ scope, src: srcPath, dest: destPath });
    return apiPost(`/api/files/move?${params.toString()}`);
  },

  async deleteFile({ scope = 'private', path }) {
    const params = new URLSearchParams({ scope, path });
    return apiDelete(`/api/files?${params.toString()}`);
  },


  async toggleServerShared({ path, isShared }) {
    const params = new URLSearchParams({ path, shared: isShared ? '1' : '0' });
    return apiPost(`/api/files/share?${params.toString()}`);
  },

  async getAccountStats() {
    return apiGet('/api/account/stats');
  }
};
