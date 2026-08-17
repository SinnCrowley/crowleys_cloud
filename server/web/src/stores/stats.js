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

import { writable } from 'svelte/store';
import { filesApi } from '../api/files.js';

const STORAGE_KEY = 'cc_user_stats';

function getInitialStats() {
  const defaultStats = {
    totalCount: 0,
    totalSize: 0,
    photoCount: 0,
    photoSize: 0,
    videoCount: 0,
    videoSize: 0,
    audioCount: 0,
    audioSize: 0,
    documentCount: 0,
    documentSize: 0,
    sharedCount: 0,
    sharedSize: 0,
    otherCount: 0,
    otherSize: 0,
    isLoading: false
  };

  if (typeof localStorage !== 'undefined') {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) {
        const parsed = JSON.parse(raw);
        return { ...defaultStats, ...parsed, isLoading: false };
      }
    } catch (e) {
      // Fallback
    }
  }
  return defaultStats;
}

export const statsStore = writable(getInitialStats());

if (typeof localStorage !== 'undefined') {
  statsStore.subscribe((val) => {
    if (val && (val.totalCount > 0 || val.totalSize > 0)) {
      try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(val));
      } catch (e) {}
    }
  });
}

export async function refreshStats() {
  statsStore.update((s) => ({ ...s, isLoading: true }));
  try {
    const res = await filesApi.getAccountStats();
    if (res) {
      const newStats = {
        totalCount: res.total_count || 0,
        totalSize: res.total_size || 0,
        photoCount: res.photo_count || 0,
        photoSize: res.photo_size || 0,
        videoCount: res.video_count || 0,
        videoSize: res.video_size || 0,
        audioCount: res.audio_count || 0,
        audioSize: res.audio_size || 0,
        documentCount: res.document_count || 0,
        documentSize: res.document_size || 0,
        sharedCount: res.shared_count || 0,
        sharedSize: res.shared_size || 0,
        otherCount: res.other_count || 0,
        otherSize: res.other_size || 0,
        isLoading: false
      };
      statsStore.set(newStats);
    }
  } catch (err) {
    console.error('Failed to load storage stats:', err);
    statsStore.update((s) => ({ ...s, isLoading: false }));
  }
}
