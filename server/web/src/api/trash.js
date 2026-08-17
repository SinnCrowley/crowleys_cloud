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
