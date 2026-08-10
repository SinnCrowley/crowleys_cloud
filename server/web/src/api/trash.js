import { apiGet, apiPost, apiDelete } from './client.js';

export const trashApi = {
  async listTrash({ scope = 'private', q = '' } = {}) {
    const params = new URLSearchParams({ scope });
    if (q) params.append('q', q);
    return apiGet(`/api/trash?${params.toString()}`);
  },

  async restoreTrash(ids) {
    return apiPost('/api/trash/restore', { ids });
  },

  async deleteTrash(ids) {
    return apiDelete('/api/trash', { ids });
  }
};
