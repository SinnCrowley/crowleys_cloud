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

import { writable, get } from 'svelte/store';
import { filesApi } from '../api/files.js';

const scope = writable(typeof localStorage !== 'undefined' ? localStorage.getItem('cc_current_scope') || 'private' : 'private');
const currentPath = writable(typeof localStorage !== 'undefined' ? localStorage.getItem('cc_current_path') || '' : '');
const entries = writable([]);
const searchQuery = writable('');
const sortOption = writable({ field: 'name', order: 'asc' });
const filterType = writable(typeof localStorage !== 'undefined' ? localStorage.getItem('cc_current_filter') || 'all' : 'all');
const selectedPaths = writable(new Set());
const isLoading = writable(false);
const error = writable(null);

export const filesStore = {
  scope,
  currentPath,
  entries,
  searchQuery,
  sortOption,
  filterType,
  selectedPaths,
  isLoading,
  error,

  clear() {
    entries.set([]);
    selectedPaths.set(new Set());
    error.set(null);
    isLoading.set(false);
  },

  async loadDirectory(silent = false) {
    if (!silent) {
      isLoading.set(true);
      error.set(null);
    }
    try {
      const currentScope = get(scope);
      const path = get(currentPath);
      const q = get(searchQuery);
      const sort = get(sortOption);
      const type = get(filterType);

      const res = await filesApi.listDir({
        scope: currentScope,
        path,
        type,
        q,
        sort: sort.field,
        order: sort.order
      });

      entries.set(res.entries || []);
    } catch (err) {
      if (!silent) {
        error.set(err.message || 'Failed to load directory');
      }
    } finally {
      if (!silent) {
        isLoading.set(false);
      }
    }
  },

  navigateTo(path) {
    selectedPaths.set(new Set());
    currentPath.set(path);
    if (typeof localStorage !== 'undefined') {
      localStorage.setItem('cc_current_path', path);
    }
    return this.loadDirectory();
  },

  setScope(newScope) {
    selectedPaths.set(new Set());
    scope.set(newScope);
    currentPath.set('');
    if (typeof localStorage !== 'undefined') {
      localStorage.setItem('cc_current_scope', newScope);
      localStorage.setItem('cc_current_path', '');
    }
    return this.loadDirectory();
  },

  toggleSelection(path, multi = false) {
    selectedPaths.update((set) => {
      const next = multi ? new Set(set) : new Set();
      if (next.has(path)) {
        next.delete(path);
      } else {
        next.add(path);
      }
      return next;
    });
  },

  selectAll() {
    const all = get(entries).map((e) => e.path);
    selectedPaths.set(new Set(all));
  },

  clearSelection() {
    selectedPaths.set(new Set());
  },

  async deleteSelected() {
    const selected = Array.from(get(selectedPaths));
    if (selected.length === 0) return;
    const currentScope = get(scope);
    isLoading.set(true);
    try {
      await filesApi.deleteFiles({ scope: currentScope, paths: selected });
      this.clearSelection();
      await this.loadDirectory();
    } catch (err) {
      error.set(err.message || 'Failed to delete selected items');
    } finally {
      isLoading.set(false);
    }
  },

  async moveSelected(destFolder) {
    const selected = Array.from(get(selectedPaths));
    if (selected.length === 0) return;
    const currentScope = get(scope);
    isLoading.set(true);
    try {
      for (const srcPath of selected) {
        await filesApi.moveFile({ scope: currentScope, srcPath, destFolder });
      }
      this.clearSelection();
      await this.loadDirectory();
    } catch (err) {
      error.set(err.message || 'Failed to move selected items');
    } finally {
      isLoading.set(false);
    }
  }
};
