/**
 * Zero-dependency Fetch Client with automatic Bearer token injection and 401 Refresh Retry.
 */
import { authStore } from '../stores/auth.js';
import { get } from 'svelte/store';

export class ApiError extends Error {
  constructor(status, message, data = null) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.data = data;
  }
}

let isRefreshing = false;
let failedQueue = [];

function processQueue(error, token = null) {
  failedQueue.forEach((prom) => {
    if (error) {
      prom.reject(error);
    } else {
      prom.resolve(token);
    }
  });
  failedQueue = [];
}

async function parseResponse(response) {
  if (response.status === 204) return null;

  const contentType = response.headers.get('Content-Type') || '';
  let body;

  if (contentType.includes('application/json')) {
    body = await response.json();
  } else if (contentType.includes('text/')) {
    body = await response.text();
  } else {
    body = await response.blob();
  }

  if (!response.ok) {
    const errorMsg = (body && typeof body === 'object' && body.error) ? body.error : response.statusText;
    throw new ApiError(response.status, errorMsg, body);
  }

  return body;
}

export async function apiFetch(endpoint, options = {}) {
  const url = endpoint.startsWith('/') ? endpoint : `/${endpoint}`;
  
  const headers = new Headers(options.headers || {});
  
  // Set default content-type if not binary/form payload
  if (!headers.has('Content-Type') && !(options.body instanceof FormData) && !(options.body instanceof Blob)) {
    headers.set('Content-Type', 'application/json');
  }

  // Inject Bearer token
  const token = get(authStore.accessToken);
  if (token && !headers.has('Authorization')) {
    headers.set('Authorization', `Bearer ${token}`);
  }

  const fetchOptions = {
    ...options,
    headers
  };

  let response;
  try {
    response = await fetch(url, fetchOptions);
  } catch (err) {
    throw new ApiError(0, `Network failure: ${err.message}`);
  }

  // Handle 401 Token Refresh retry
  if (response.status === 401 && !endpoint.includes('/api/login') && !endpoint.includes('/api/refresh')) {
    if (isRefreshing) {
      return new Promise((resolve, reject) => {
        failedQueue.push({ resolve, reject });
      })
        .then((newToken) => {
          headers.set('Authorization', `Bearer ${newToken}`);
          return fetch(url, { ...fetchOptions, headers }).then(parseResponse);
        })
        .catch((err) => Promise.reject(err));
    }

    isRefreshing = true;
    const currentRefreshToken = get(authStore.refreshToken);

    if (!currentRefreshToken) {
      isRefreshing = false;
      processQueue(new ApiError(401, 'Session expired'), null);
      authStore.clearSession();
      throw new ApiError(401, 'Session expired');
    }

    try {
      const refreshRes = await fetch('/api/refresh', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refresh_token: currentRefreshToken })
      });

      if (!refreshRes.ok) {
        throw new Error('Refresh failed');
      }

      const refreshData = await refreshRes.json();
      authStore.setSession({
        accessToken: refreshData.access_token,
        refreshToken: refreshData.refresh_token
      });

      processQueue(null, refreshData.access_token);
      isRefreshing = false;

      // Retry original request with new token
      headers.set('Authorization', `Bearer ${refreshData.access_token}`);
      const retryResponse = await fetch(url, { ...fetchOptions, headers });
      return parseResponse(retryResponse);
    } catch (refreshErr) {
      processQueue(refreshErr, null);
      isRefreshing = false;
      authStore.clearSession();
      throw new ApiError(401, 'Session expired. Please log in again.');
    }
  }

  return parseResponse(response);
}

export const apiGet = (url, options = {}) => apiFetch(url, { ...options, method: 'GET' });

export const apiPost = (url, body = null, options = {}) => {
  const isObject = body !== null && typeof body === 'object' && !(body instanceof FormData) && !(body instanceof Blob);
  return apiFetch(url, {
    ...options,
    method: 'POST',
    body: isObject ? JSON.stringify(body) : body
  });
};

export const apiDelete = (url, body = null, options = {}) => {
  const isObject = body !== null && typeof body === 'object' && !(body instanceof FormData) && !(body instanceof Blob);
  return apiFetch(url, {
    ...options,
    method: 'DELETE',
    body: isObject ? JSON.stringify(body) : body
  });
};
