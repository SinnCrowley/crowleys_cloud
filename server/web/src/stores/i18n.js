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

import { writable, derived, get } from 'svelte/store';
import { broadcastChannel } from './broadcast.js';
import en from '../i18n/en.json';
import ru from '../i18n/ru.json';
import zhCN from '../i18n/zh-CN.json';
import es from '../i18n/es.json';
import ja from '../i18n/ja.json';
import ptBR from '../i18n/pt-BR.json';
import pt from '../i18n/pt.json';
import zh from '../i18n/zh.json';
import de from '../i18n/de.json';
import ar from '../i18n/ar.json';
import fr from '../i18n/fr.json';
import ko from '../i18n/ko.json';
import hi from '../i18n/hi.json';
import it from '../i18n/it.json';
import tr from '../i18n/tr.json';
import id from '../i18n/id.json';
import vi from '../i18n/vi.json';
import bn from '../i18n/bn.json';
import fa from '../i18n/fa.json';
import uk from '../i18n/uk.json';
import pl from '../i18n/pl.json';
import cs from '../i18n/cs.json';

const dictionaries = { en, ru, zh, 'zh-CN': zhCN, es, ja, pt, 'pt-BR': ptBR, de, ar, fr, ko, hi, it, tr, id, vi, bn, fa, uk, pl, cs };
export const supportedLanguages = Object.keys(dictionaries);
export const selectableLanguages = supportedLanguages.filter((language) => !['pt', 'zh'].includes(language));
const rtlLanguages = new Set(['ar', 'fa']);

export function detectSystemLanguage() {
  if (typeof navigator !== 'undefined') {
    const navLang = (navigator.language || navigator.userLanguage || '').toLowerCase();
    if (navLang.startsWith('ru') || navLang.startsWith('be') || navLang.startsWith('kk')) return 'ru';
    if (navLang.startsWith('uk')) return 'uk';
    if (navLang.startsWith('zh')) return 'zh-CN';
    if (navLang.startsWith('pt')) return 'pt-BR';
    for (const language of supportedLanguages) if (navLang.startsWith(language.toLowerCase())) return language;
  }
  return 'en';
}

const initialSaved =
  typeof localStorage !== 'undefined'
    ? localStorage.getItem('cc_language') || 'system'
    : 'system';

// 'system' or one of supportedLanguages
export const languagePreference = writable(initialSaved);

export const currentLocale = derived(languagePreference, ($pref) => {
  if (supportedLanguages.includes($pref)) {
    if (typeof document !== 'undefined') document.documentElement.dir = rtlLanguages.has($pref) ? 'rtl' : 'ltr';
    return $pref;
  }
  const detected = detectSystemLanguage();
  if (typeof document !== 'undefined') document.documentElement.dir = rtlLanguages.has(detected) ? 'rtl' : 'ltr';
  return detected;
});

let isInternalSync = false;

if (typeof localStorage !== 'undefined') {
  languagePreference.subscribe((pref) => {
    localStorage.setItem('cc_language', pref);
    if (broadcastChannel && !isInternalSync) {
      broadcastChannel.postMessage({ type: 'LANGUAGE_CHANGE', language: pref });
    }
  });
}

if (broadcastChannel) {
  broadcastChannel.addEventListener('message', (event) => {
    if (!event.data || !event.data.type) return;
    const { type, language } = event.data;
    if (type === 'LANGUAGE_CHANGE' && language) {
      isInternalSync = true;
      try {
        languagePreference.set(language);
      } finally {
        isInternalSync = false;
      }
    }
  });
}

function resolveKey(obj, path) {
  if (!obj || !path) return null;
  const parts = path.split('.');
  let curr = obj;
  for (const part of parts) {
    if (curr && typeof curr === 'object' && part in curr) {
      curr = curr[part];
    } else {
      return null;
    }
  }
  return typeof curr === 'string' ? curr : null;
}

function formatString(template, params) {
  if (!template || !params) return template || '';
  return template.replace(/\{(\w+)\}/g, (match, key) => {
    return params[key] !== undefined ? String(params[key]) : match;
  });
}

/**
 * Reactive translation store:
 * Usage in Svelte:
 * import { t } from '../stores/i18n.js';
 * <span>{$t('nav.dashboard')}</span>
 * <span>{$t('files.selected_count', { count: 5 })}</span>
 */
export const t = derived(currentLocale, ($locale) => {
  return (key, params = null) => {
    const dict = dictionaries[$locale] || dictionaries.en;
    let text = resolveKey(dict, key);
    if (!text && $locale !== 'en') {
      text = resolveKey(dictionaries.en, key);
    }
    if (!text) {
      return key;
    }
    return formatString(text, params);
  };
});

export const i18n = {
  preference: languagePreference,
  locale: currentLocale,
  t,

  setLanguage(lang) {
    languagePreference.set(lang);
  },

  getLanguage() {
    return get(languagePreference);
  },

  getResolvedLanguage() {
    return get(currentLocale);
  },

  format(key, params = null) {
    const locale = get(currentLocale);
    const dict = dictionaries[locale] || dictionaries.en;
    let text = resolveKey(dict, key);
    if (!text && locale !== 'en') {
      text = resolveKey(dictionaries.en, key);
    }
    if (!text) return key;
    return formatString(text, params);
  }
};
