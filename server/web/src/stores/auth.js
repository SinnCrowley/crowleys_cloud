import { writable, derived } from 'svelte/store';
import { resetClientAuthState } from '../api/client.js';
import { broadcastChannel } from './broadcast.js';

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

let isInternalSync = false;

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

if (broadcastChannel) {
  broadcastChannel.addEventListener('message', (event) => {
    if (!event.data || !event.data.type) return;

    isInternalSync = true;
    try {
      if (event.data.type === 'AUTH_LOGOUT') {
        authStore.clearSession();
      } else if (event.data.type === 'AUTH_LOGIN' && event.data.session) {
        authStore.setSession(event.data.session);
      }
    } finally {
      isInternalSync = false;
    }
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

    if (broadcastChannel && !isInternalSync) {
      broadcastChannel.postMessage({ type: 'AUTH_LOGIN', session: data });
    }
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

    if (broadcastChannel && !isInternalSync) {
      broadcastChannel.postMessage({ type: 'AUTH_LOGOUT' });
    }
  }
};
