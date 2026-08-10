import { writable } from 'svelte/store';

const initialTheme = typeof localStorage !== 'undefined' ? localStorage.getItem('cc_theme') || 'dark' : 'dark';
const initialFontScale = typeof localStorage !== 'undefined' ? parseFloat(localStorage.getItem('cc_font_scale') || '1.0') : 1.0;
const initialAccent = typeof localStorage !== 'undefined' ? localStorage.getItem('cc_accent') || '#FA5252' : '#FA5252';

const themeStore = writable(initialTheme);
const fontScaleStore = writable(initialFontScale);
const accentStore = writable(initialAccent);

if (typeof localStorage !== 'undefined') {
  themeStore.subscribe((theme) => {
    localStorage.setItem('cc_theme', theme);
    if (typeof document !== 'undefined') {
      document.documentElement.setAttribute('data-theme', theme);
    }
  });

  fontScaleStore.subscribe((scale) => {
    localStorage.setItem('cc_font_scale', scale.toString());
    if (typeof document !== 'undefined') {
      document.documentElement.style.setProperty('--font-scale', scale.toString());
    }
  });

  accentStore.subscribe((accent) => {
    localStorage.setItem('cc_accent', accent);
    if (typeof document !== 'undefined') {
      document.documentElement.style.setProperty('--color-primary', accent);
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
