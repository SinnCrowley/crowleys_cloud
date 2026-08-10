import { apiPost, apiGet } from './client.js';

export const shareApi = {
  async createShare({ scope = 'private', path, expiresInSeconds = 86400 }) {
    return apiPost('/api/share', {
      scope,
      path,
      expires_in_seconds: expiresInSeconds
    });
  },

  async getPublicShareInfo(token, subpath = '') {
    const params = new URLSearchParams();
    if (subpath) params.append('p', subpath);
    const queryString = params.toString() ? `?${params.toString()}` : '';
    return apiGet(`/api/public/share/${token}/info${queryString}`);
  }
};
