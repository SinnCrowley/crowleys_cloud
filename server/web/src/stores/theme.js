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
import { broadcastChannel } from './broadcast.js';

const initialTheme = typeof localStorage !== 'undefined' ? localStorage.getItem('cc_theme') || 'dark' : 'dark';
const initialFontScale = typeof localStorage !== 'undefined' ? parseFloat(localStorage.getItem('cc_font_scale') || '1.0') : 1.0;
const initialAccent = typeof localStorage !== 'undefined' ? localStorage.getItem('cc_accent') || '#FA5252' : '#FA5252';

const themeStore = writable(initialTheme);
const fontScaleStore = writable(initialFontScale);
const accentStore = writable(initialAccent);

let isInternalSync = false;

if (typeof localStorage !== 'undefined') {
  themeStore.subscribe((theme) => {
    localStorage.setItem('cc_theme', theme);
    if (typeof document !== 'undefined') {
      document.documentElement.setAttribute('data-theme', theme);
    }
    if (broadcastChannel && !isInternalSync) {
      broadcastChannel.postMessage({ type: 'THEME_CHANGE', theme });
    }
  });

  fontScaleStore.subscribe((scale) => {
    localStorage.setItem('cc_font_scale', scale.toString());
    if (typeof document !== 'undefined') {
      document.documentElement.style.setProperty('--font-scale', scale.toString());
    }
    if (broadcastChannel && !isInternalSync) {
      broadcastChannel.postMessage({ type: 'FONT_SCALE_CHANGE', scale });
    }
  });

  accentStore.subscribe((accent) => {
    localStorage.setItem('cc_accent', accent);
    if (typeof document !== 'undefined') {
      document.documentElement.style.setProperty('--color-primary', accent);
    }
    if (broadcastChannel && !isInternalSync) {
      broadcastChannel.postMessage({ type: 'ACCENT_CHANGE', accent });
    }
  });
}

if (broadcastChannel) {
  broadcastChannel.addEventListener('message', (event) => {
    if (!event.data || !event.data.type) return;
    const { type, theme, scale, accent } = event.data;

    isInternalSync = true;
    try {
      if (type === 'THEME_CHANGE' && theme) {
        themeStore.set(theme);
      } else if (type === 'FONT_SCALE_CHANGE' && scale != null) {
        fontScaleStore.set(scale);
      } else if (type === 'ACCENT_CHANGE' && accent) {
        accentStore.set(accent);
      }
    } finally {
      isInternalSync = false;
    }
  });
}

export const themeState = {
  theme: themeStore,
  fontScale: fontScaleStore,
  accent: accentStore,

  toggleTheme() {
    themeStore.update((t) => (t === 'dark' ? 'light' : 'dark'));
  },

  setFontScale(scale) {
    fontScaleStore.set(scale);
  },

  setAccent(color) {
    accentStore.set(color);
  }
};
