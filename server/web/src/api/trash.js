import { apiGet, apiPost, apiDelete } from './client.js';

export const trashApi = {
  async listTrash({ scope = 'private', q = '' } = {}) {
    const params = new URLSearchParams({ scope });
    if (q) params.append('q', q);
    return apiGet(`/api/trash?${params.toString()}`);
  },

  async checkRestoreConflicts(ids) {
    return apiPost('/api/trash/restore-check', { ids });
  },

  async restoreTrash(ids, overwrite = false) {
    return apiPost('/api/trash/restore', { ids, overwrite });
  },

  async deleteTrash(ids) {
    return apiDelete('/api/trash', { ids });
  },

  async getTrashSettings() {
    return apiGet('/api/trash/settings');
  }
};
