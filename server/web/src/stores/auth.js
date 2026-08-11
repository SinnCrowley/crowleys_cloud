import { writable, derived } from 'svelte/store';
import { resetClientAuthState } from '../api/client.js';

const initialAccessToken = typeof localStorage !== 'undefined' ? localStorage.getItem('cc_access_token') || null : null;
const initialRefreshToken = typeof localStorage !== 'undefined' ? localStorage.getItem('cc_refresh_token') || null : null;
let initialUser = null;
if (typeof localStorage !== 'undefined') {
  try {
    const raw = localStorage.getItem('cc_user');
    if (raw) initialUser = JSON.parse(raw);
  } catch (e) {
    initialUser = null;
  }
}

const accessTokenStore = writable(initialAccessToken);
const refreshTokenStore = writable(initialRefreshToken);
const userStore = writable(initialUser);

if (typeof localStorage !== 'undefined') {
  accessTokenStore.subscribe((val) => {
    if (val) localStorage.setItem('cc_access_token', val);
    else localStorage.removeItem('cc_access_token');
  });

  refreshTokenStore.subscribe((val) => {
    if (val) localStorage.setItem('cc_refresh_token', val);
    else localStorage.removeItem('cc_refresh_token');
  });

  userStore.subscribe((val) => {
    if (val) localStorage.setItem('cc_user', JSON.stringify(val));
    else localStorage.removeItem('cc_user');
  });
}

export const isAuthenticated = derived(accessTokenStore, ($token) => !!$token);

export const authStore = {
  accessToken: accessTokenStore,
  refreshToken: refreshTokenStore,
  user: userStore,
  isAuthenticated,

  setSession(data = {}) {
    if (!data) return;
    const token = data.accessToken || data.access_token || null;
    const refresh = data.refreshToken || data.refresh_token || null;
    const usr = data.user || null;

    if (token) accessTokenStore.set(token);
    if (refresh) refreshTokenStore.set(refresh);
    if (usr) userStore.set(usr);
  },

  clearSession() {
    accessTokenStore.set(null);
    refreshTokenStore.set(null);
    userStore.set(null);
    resetClientAuthState();

    if (typeof localStorage !== 'undefined') {
      localStorage.removeItem('cc_access_token');
      localStorage.removeItem('cc_refresh_token');
      localStorage.removeItem('cc_user');
      localStorage.removeItem('cc_user_stats');
    }
  }
};
