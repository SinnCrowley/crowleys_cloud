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
