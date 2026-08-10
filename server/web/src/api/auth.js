import { apiPost } from './client.js';

export const authApi = {
  async login({ username, password }) {
    return apiPost('/api/login', { username, password });
  },

  async register({ username, password }) {
    return apiPost('/api/register', { username, password });
  },

  async refresh(refreshToken) {
    return apiPost('/api/refresh', { refresh_token: refreshToken });
  },

  async logout(refreshToken) {
    return apiPost('/api/logout', { refresh_token: refreshToken });
  },

  async changePassword(newPassword) {
    return apiPost('/api/account/password', { new_password: newPassword });
  }
};
