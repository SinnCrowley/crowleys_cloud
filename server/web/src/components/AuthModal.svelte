<!-- Copyright (C) 2026 Sinn Crowley

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>. -->

<script>
  import { createEventDispatcher } from 'svelte';
  import { authApi } from '../api/auth.js';
  import { authStore } from '../stores/auth.js';
  import { filesStore } from '../stores/files.js';
  import { t } from '../stores/i18n.js';

  const dispatch = createEventDispatcher();
  const { isAuthenticated, user, refreshToken } = authStore;

  let activeTab = 'login'; // 'login' | 'register' | 'recovery'
  let recoveryCode = '';
  let username = '';
  let password = '';
  let confirmPassword = '';
  let serverUrl = window.location.origin;
  let errorMessage = '';
  let statusMessage = '';
  let isLoading = false;

  async function handleSubmit() {
    errorMessage = '';
    statusMessage = '';
    if (!username || !password) {
      errorMessage = $t('modals.auth.fill_all_fields');
      return;
    }
    if (activeTab !== 'login' && password !== confirmPassword) {
      errorMessage = $t('modals.auth.passwords_mismatch');
      return;
    }

    isLoading = true;
    try {
      if (activeTab === 'recovery') {
        await authApi.resetPassword({ username, code: recoveryCode, newPassword: password });
        statusMessage = $t('recovery.passwordResetSuccessfully');
        activeTab = 'login'; password = ''; confirmPassword = ''; recoveryCode = '';
        return;
      }
      let res;
      if (activeTab === 'login') {
        res = await authApi.login({ username, password });
      } else {
        res = await authApi.register({ username, password });
      }

      if (res.status === 'pending') {
        statusMessage = $t('account_status.registrationPending');
        activeTab = 'login';
        password = '';
        confirmPassword = '';
        return;
      }
      const payload = {
        accessToken: res.access_token,
        refreshToken: res.refresh_token,
        access_token: res.access_token,
        refresh_token: res.refresh_token,
        user: res.user || { username }
      };

      authStore.setSession(payload);
      dispatch('success', payload);
      dispatch('authenticated', payload);
    } catch (err) {
      const msg = err.message || '';
      if (msg.toLowerCase().includes('invalid credential') || msg.toLowerCase().includes('invalid username or password')) {
        errorMessage = $t('modals.auth.invalid_credentials');
      } else {
        errorMessage = msg || $t('common.error');
      }
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
      <p class="text-sub">{$t('modals.auth.access_storage')}</p>
    </div>

    {#if $isAuthenticated}
      <div class="account-info">
        <p class="text-body">{$t('modals.auth.logged_in_as', { username: $user?.username || $t('nav.user') })}</p>
        <button
          type="button"
          class="btn btn-primary full-width"
          style="display: flex; align-items: center; justify-content: center; gap: 8px;"
          disabled={isLoading}
          on:click={handleLogout}
        >
          {#if !isLoading}
            <span class="material-symbols-outlined" style="font-size: 18px;">logout</span>
          {/if}
          {isLoading ? $t('common.loading') : $t('nav.sign_out')}
        </button>
      </div>
    {:else}
      <div class="tab-buttons">
        <button
          type="button"
          class="tab-btn {activeTab === 'login' ? 'active' : ''}"
          on:click={() => (activeTab = 'login')}
        >
          {$t('nav.sign_in')}
        </button>
        <button
          type="button"
          class="tab-btn {activeTab === 'register' ? 'active' : ''}"
          on:click={() => (activeTab = 'register')}
        >
          {$t('modals.auth.register_btn')}
        </button>
        <button type="button" class="tab-btn {activeTab === 'recovery' ? 'active' : ''}" on:click={() => { activeTab = 'recovery'; errorMessage = ''; statusMessage = ''; }}>
          {$t('recovery.resetPasswordTitle')}
        </button>
      </div>

      {#if activeTab === 'recovery'}<p>{$t('account_status.resetPasswordStep2Body')}</p>{/if}
      {#if statusMessage}
        <p role="status">{statusMessage}</p>
      {/if}
      {#if errorMessage}
        <div class="error-banner text-sub">
          {errorMessage}
        </div>
      {/if}

      <form on:submit|preventDefault={handleSubmit}>
        <div class="form-group">
          <label class="form-label" for="serverUrl">{$t('modals.auth.server_url')}</label>
          <input
            id="serverUrl"
            type="text"
            class="form-input"
            bind:value={serverUrl}
            placeholder="http://localhost:8080"
          />
        </div>

        <div class="form-group">
          <label class="form-label" for="username">{$t('modals.auth.username')}</label>
          <input
            id="username"
            type="text"
            class="form-input"
            bind:value={username}
            placeholder={$t('modals.auth.username_placeholder')}
            required
          />
        </div>

        <div class="form-group">
          <label class="form-label" for="password">{$t(activeTab === 'recovery' ? 'recovery.newPasswordLabel' : 'modals.auth.password')}</label>
          <input
            id="password"
            type="password"
            class="form-input"
            bind:value={password}
            placeholder={$t('modals.auth.password_placeholder')}
            required
          />
        </div>

        {#if activeTab === 'recovery'}
          <div class="form-group">
            <label class="form-label" for="recoveryCode">{$t('recovery.resetCodeLabel')}</label>
            <input id="recoveryCode" class="form-input" type="text" inputmode="numeric" autocomplete="one-time-code" pattern={'[0-9]{6}'} maxlength="6" bind:value={recoveryCode} required />
          </div>
        {/if}
        {#if activeTab !== 'login'}
          <div class="form-group">
            <label class="form-label" for="confirmPassword">{$t('modals.auth.confirm_password')}</label>
            <input
              id="confirmPassword"
              type="password"
              class="form-input"
              bind:value={confirmPassword}
              placeholder={$t('modals.auth.confirm_password_placeholder')}
              required
            />
          </div>
        {/if}

        <div class="auth-actions">
          <button type="submit" class="btn btn-primary full-width" disabled={isLoading}>
            {isLoading ? $t('common.loading') : activeTab === 'login' ? $t('nav.sign_in') : activeTab === 'recovery' ? $t('recovery.resetPasswordTitle') : $t('modals.auth.register_btn')}
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

  .auth-actions {
    margin-top: var(--spacing-md);
  }
</style>
