<script>
  import { createEventDispatcher } from 'svelte';
  import { authApi } from '../api/auth.js';
  import { authStore } from '../stores/auth.js';
  import { filesStore } from '../stores/files.js';

  const dispatch = createEventDispatcher();
  const { isAuthenticated, user, refreshToken } = authStore;

  let activeTab = 'login'; // 'login' | 'register'
  let username = '';
  let password = '';
  let confirmPassword = '';
  let serverUrl = window.location.origin;
  let errorMessage = '';
  let isLoading = false;

  async function handleSubmit() {
    errorMessage = '';
    if (!username || !password) {
      errorMessage = 'Please fill in all required fields.';
      return;
    }
    if (activeTab === 'register' && password !== confirmPassword) {
      errorMessage = 'Passwords do not match.';
      return;
    }

    isLoading = true;
    try {
      let res;
      if (activeTab === 'login') {
        res = await authApi.login({ username, password });
      } else {
        res = await authApi.register({ username, password });
      }

      const payload = {
        accessToken: res.access_token,
        refreshToken: res.refresh_token,
        access_token: res.access_token,
        refresh_token: res.refresh_token,
        user: { username }
      };

      authStore.setSession(payload);
      dispatch('success', payload);
      dispatch('authenticated', payload);
    } catch (err) {
      errorMessage = err.message || 'Authentication failed. Please check your credentials.';
    } finally {
      isLoading = false;
    }
  }

  async function handleLogout() {
    isLoading = true;
    try {
      if ($refreshToken) {
        await authApi.logout($refreshToken);
      }
    } catch (err) {
      console.warn('Logout API call failed:', err);
    } finally {
      authStore.clearSession();
      filesStore.clear();
      isLoading = false;
      dispatch('close');
    }
  }
</script>

<!-- svelte-ignore a11y-click-events-have-key-events -->
<!-- svelte-ignore a11y-no-static-element-interactions -->
<div class="modal-backdrop" on:click|self={() => { if ($isAuthenticated) dispatch('close'); }}>
  <div class="card-auth">
    <div class="auth-header">
      <h2 class="text-display">Crowley's Cloud</h2>
      <p class="text-sub">Access your multi-server storage</p>
    </div>

    {#if $isAuthenticated}
      <div class="account-info">
        <p class="text-body">Logged in as: <strong>{$user?.username || 'User'}</strong></p>
        <button
          type="button"
          class="btn btn-danger full-width"
          disabled={isLoading}
          on:click={handleLogout}
        >
          {isLoading ? 'Signing out...' : 'Sign Out'}
        </button>
      </div>
    {:else}
      <div class="tab-buttons">
        <button
          type="button"
          class="tab-btn {activeTab === 'login' ? 'active' : ''}"
          on:click={() => (activeTab = 'login')}
        >
          Sign In
        </button>
        <button
          type="button"
          class="tab-btn {activeTab === 'register' ? 'active' : ''}"
          on:click={() => (activeTab = 'register')}
        >
          Register
        </button>
      </div>

      {#if errorMessage}
        <div class="error-banner text-sub">
          {errorMessage}
        </div>
      {/if}

      <form on:submit|preventDefault={handleSubmit}>
        <div class="form-group">
          <label class="form-label" for="serverUrl">Server URL</label>
          <input
            id="serverUrl"
            type="text"
            class="form-input"
            bind:value={serverUrl}
            placeholder="http://localhost:8080"
          />
        </div>

        <div class="form-group">
          <label class="form-label" for="username">Username</label>
          <input
            id="username"
            type="text"
            class="form-input"
            bind:value={username}
            placeholder="Enter username"
            required
          />
        </div>

        <div class="form-group">
          <label class="form-label" for="password">Password</label>
          <input
            id="password"
            type="password"
            class="form-input"
            bind:value={password}
            placeholder="Enter password"
            required
          />
        </div>

        {#if activeTab === 'register'}
          <div class="form-group">
            <label class="form-label" for="confirmPassword">Confirm Password</label>
            <input
              id="confirmPassword"
              type="password"
              class="form-input"
              bind:value={confirmPassword}
              placeholder="Confirm password"
              required
            />
          </div>
        {/if}

        <div class="auth-actions">
          <button type="submit" class="btn btn-primary full-width" disabled={isLoading}>
            {isLoading ? 'Connecting...' : activeTab === 'login' ? 'Sign In' : 'Create Account'}
          </button>
        </div>
      </form>
    {/if}
  </div>
</div>

<style>
  .card-auth {
    max-height: 90vh;
    overflow-y: auto;
  }

  .auth-header {
    text-align: center;
    margin-bottom: var(--spacing-lg);
  }

  .auth-header h2 {
    margin: 0 0 4px 0;
  }

  .account-info {
    display: flex;
    flex-direction: column;
    gap: var(--spacing-md);
    padding: var(--spacing-md) 0;
  }

  .tab-buttons {
    display: flex;
    border-bottom: 1px solid var(--border-color);
    margin-bottom: var(--spacing-lg);
  }

  .tab-btn {
    flex: 1;
    padding: 10px;
    background: none;
    border: none;
    color: var(--text-sub);
    font-weight: 600;
    font-size: calc(14px * var(--font-scale));
    cursor: pointer;
    border-bottom: 2px solid transparent;
    transition: all 0.15s ease;
  }

  .tab-btn.active {
    color: var(--accent-color);
    border-bottom-color: var(--accent-color);
  }

  .error-banner {
    background-color: rgba(255, 82, 82, 0.1);
    color: var(--color-danger);
    padding: var(--spacing-sm) var(--spacing-md);
    border-radius: var(--radius-md);
    margin-bottom: var(--spacing-md);
    border: 1px solid var(--color-danger);
  }

  .full-width {
    width: 100%;
    height: 44px;
    margin-top: var(--spacing-md);
  }

  .btn-danger {
    background-color: var(--color-danger);
    color: #FFFFFF;
  }

  .btn-danger:hover {
    background-color: var(--color-danger-hover);
  }

  .auth-actions {
    margin-top: var(--spacing-md);
  }
</style>
