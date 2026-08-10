import { writable, derived } from 'svelte/store';

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

  setSession({ accessToken, refreshToken, user = null }) {
    accessTokenStore.set(accessToken);
    refreshTokenStore.set(refreshToken);
    if (user) userStore.set(user);
  },

  clearSession() {
    accessTokenStore.set(null);
    refreshTokenStore.set(null);
    userStore.set(null);
  }
};
