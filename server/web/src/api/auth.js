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
