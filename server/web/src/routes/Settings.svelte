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
  import { createEventDispatcher, onMount } from 'svelte';
  import { themeState } from '../stores/theme.js';
  import { filesStore } from '../stores/files.js';
  import { authStore } from '../stores/auth.js';
  import { filesApi } from '../api/files.js';
  import { authApi } from '../api/auth.js';
  import { languagePreference, i18n, t, selectableLanguages } from '../stores/i18n.js';
  import CustomSelect from '../components/CustomSelect.svelte';

  const dispatch = createEventDispatcher();

  const { theme, fontScale, accent } = themeState;
  const { isAuthenticated, user } = authStore;

  let showHiddenFiles = false;
  let biometricLogin = true; // mapped to Automatic Sign In
  let tokenLifetime = '30days'; // mapped to Require login duration
  let cacheMaxBytes = 500 * 1024 * 1024; // 500 MB default
  let trashRetentionDays = 30;

  $: languageOptions = [
    { value: 'system', label: $t('settings.language_auto') },
    { value: 'en', label: $t('settings.language_en') },
    { value: 'ru', label: $t('settings.language_ru') },
    ...selectableLanguages.filter((language) => !['en', 'ru'].includes(language)).map((language) => ({
      value: language,
      label: $t(`settings.language_${language}`)
    }))
  ];

  const cacheOptions = [
    { value: 50 * 1024 * 1024, label: '50 MB' },
    { value: 100 * 1024 * 1024, label: '100 MB' },
    { value: 500 * 1024 * 1024, label: '500 MB (default)' },
    { value: 1024 * 1024 * 1024, label: '1 GB' },
    { value: 5 * 1024 * 1024 * 1024, label: '5 GB' }
  ];

  const loginOptions = [
    { value: 'everyOpen', label: 'Every app close' },
    { value: '15min', label: '15 minutes' },
    { value: '1hour', label: '1 hour' },
    { value: '1day', label: '1 day' },
    { value: '30days', label: '30 days (default)' },
    { value: 'never', label: 'Never' }
  ];

  let isRebuilding = false;
  let rebuildMessage = '';
  let rebuildSuccess = false;

  // Change password modal state
  let showPasswordModal = false;
  let newPassword = '';
  let confirmNewPassword = '';
  let passwordError = '';

  const presetColors = [
    '#FA5252', // Red/Coral (default)
    '#E64980', // Pink
    '#BE4BDB', // Grape
    '#7950F2', // Violet
    '#4C6EF5', // Indigo
    '#228BE6', // Blue
    '#15AABF', // Cyan
    '#12B886', // Teal
    '#40C057', // Green
    '#82C91E', // Lime
    '#FAB005', // Yellow
    '#FD7E14'  // Orange
  ];

  onMount(async () => {
    if (typeof localStorage !== 'undefined') {
      showHiddenFiles = localStorage.getItem('cc_show_hidden') === 'true';
      biometricLogin = localStorage.getItem('cc_biometric_login') !== 'false';
      tokenLifetime = localStorage.getItem('cc_token_lifetime') || '30days';
      cacheMaxBytes = parseInt(localStorage.getItem('cc_cache_max_bytes') || (500 * 1024 * 1024).toString());
    }

    if ($isAuthenticated) {
      try {
        const res = await filesApi.getTrashSettings();
        if (res && res.trash_retention_days !== undefined) {
          trashRetentionDays = res.trash_retention_days;
        }
      } catch (err) {
        console.warn('Failed to load server trash retention:', err);
      }
    }
  });

  function handleThemeChange(e) {
    themeState.toggleTheme();
  }

  function handleFontScaleChange(e) {
    const scale = parseFloat(e.target.value);
    themeState.setFontScale(scale);
  }

  function changeAccent(color) {
    themeState.setAccent(color);
  }

  function updateLocalSetting(key, val) {
    if (typeof localStorage !== 'undefined') {
      localStorage.setItem(key, val.toString());
    }
  }

  function handleLanguageChange(e) {
    i18n.setLanguage(e.detail);
  }

  async function handleTrashRetentionChange(e) {
    const days = parseInt(e.target.value);
    trashRetentionDays = days;
    try {
      await filesApi.setTrashSettings(days);
      dispatch('toast', { message: i18n.format('toasts.trash_retention_updated'), type: 'success' });
    } catch (err) {
      dispatch('toast', { message: err.message || i18n.format('toasts.trash_retention_failed'), type: 'error' });
    }
  }

  async function handleRebuildIndex() {
    isRebuilding = true;
    rebuildMessage = '';
    try {
      const res = await filesApi.rebuildIndex({ scope: 'private' });
      rebuildSuccess = true;
      rebuildMessage = res.message || i18n.format('toasts.search_rebuilt');
      dispatch('toast', { message: i18n.format('toasts.search_rebuilt'), type: 'success' });
      filesStore.loadDirectory();
    } catch (err) {
      rebuildSuccess = false;
      rebuildMessage = err.message || i18n.format('toasts.search_rebuild_failed');
      dispatch('toast', { message: i18n.format('toasts.search_rebuild_failed'), type: 'error' });
    } finally {
      isRebuilding = false;
    }
  }

  async function handleChangePassword() {
    if (!newPassword.trim()) {
      passwordError = $t('settings.password_error_empty');
      return;
    }
    if (newPassword !== confirmNewPassword) {
      passwordError = $t('settings.password_error_mismatch');
      return;
    }
    passwordError = '';
    try {
      await authApi.changePassword(newPassword.trim());
      showPasswordModal = false;
      newPassword = '';
      confirmNewPassword = '';
      dispatch('toast', { message: $t('toasts.password_updated'), type: 'success' });
      authStore.clearSession();
    } catch (err) {
      passwordError = err.message || 'Failed to update password';
    }
  }

  function clearThumbnailCache() {
    let count = 0;
    if (typeof localStorage !== 'undefined') {
      const keys = Object.keys(localStorage);
      keys.forEach((k) => {
        if (k.startsWith('cc_thumb_cache_') || k.startsWith('cc_dir_cache_')) {
          localStorage.removeItem(k);
          count++;
        }
      });
    }
    dispatch('toast', { message: i18n.format('toasts.cache_cleared', { count }), type: 'success' });
  }
</script>

<div class="settings-wrapper" style="padding: 24px;">
  <div class="canvas-header">
    <div class="canvas-header-info">
      <h2>{$t('settings.title')}</h2>
      <p>{$t('settings.subtitle')}</p>
    </div>
  </div>

  <div class="settings-layout">
    <!-- Group 1: Appearance & Theme -->
    <div class="settings-card">
      <h3 class="settings-card-title">{$t('settings.appearance')}</h3>

      <!-- Language Selector -->
      <div class="settings-row">
        <div class="settings-row-info">
          <span class="settings-row-title">{$t('settings.language')}</span>
          <span class="settings-row-desc">{$t('settings.language_desc')}</span>
        </div>
        <div class="settings-row-control">
          <CustomSelect
            value={$languagePreference}
            options={languageOptions}
            on:change={handleLanguageChange}
          />
        </div>
      </div>
      
      <!-- Theme Mode -->
      <div class="settings-row">
        <div class="settings-row-info">
          <span class="settings-row-title">{$t('settings.dark_mode')}</span>
          <span class="settings-row-desc">{$t('settings.dark_mode_desc')}</span>
        </div>
        <div class="settings-row-control">
          <label class="custom-checkbox">
            <input
              type="checkbox"
              checked={$theme === 'dark'}
              on:change={handleThemeChange}
            />
            <span class="checkbox-indicator"></span>
          </label>
        </div>
      </div>

      <!-- Accent Color Selection -->
      <div class="settings-row" style="flex-direction: column; align-items: flex-start; gap: 8px;">
        <div class="settings-row-info">
          <span class="settings-row-title">{$t('settings.accent_color')}</span>
          <span class="settings-row-desc">{$t('settings.accent_color_desc')}</span>
        </div>
        <div class="preset-theme-grid">
          {#each presetColors as color}
            <button
              class="preset-theme-btn {($accent || '#FA5252').toUpperCase() === color.toUpperCase() ? 'active' : ''}"
              style="background-color: {color};"
              title={color}
              on:click={() => changeAccent(color)}
            >
              {#if ($accent || '#FA5252').toUpperCase() === color.toUpperCase()}
                <span class="preset-theme-dot"></span>
              {/if}
            </button>
          {/each}
        </div>
      </div>

      <!-- Text Font Scale -->
      <div class="settings-row">
        <div class="settings-row-info">
          <span class="settings-row-title">{$t('settings.font_scale')}</span>
          <span class="settings-row-desc">{$t('settings.font_scale_desc')} ({($fontScale * 100).toFixed(0)}%).</span>
        </div>
        <div class="settings-row-control">
          <input
            type="range"
            min="0.8"
            max="1.4"
            step="0.05"
            value={$fontScale}
            on:input={handleFontScaleChange}
            class="settings-slider"
          />
        </div>
      </div>
    </div>

    <!-- Group 2: Cache & Storage Management -->
    <div class="settings-card">
      <h3 class="settings-card-title">{$t('settings.cache')}</h3>
      
      <!-- Clear Cache Button -->
      <div class="settings-row">
        <div class="settings-row-info">
          <span class="settings-row-title">{$t('settings.cache')}</span>
          <span class="settings-row-desc">{$t('settings.cache_desc')}</span>
        </div>
        <div class="settings-row-control">
          <button class="btn btn-secondary" on:click={clearThumbnailCache}>{$t('settings.clear_cache')}</button>
        </div>
      </div>
    </div>

    <!-- Group 3: User Account -->
    <div class="settings-card">
      <h3 class="settings-card-title">{$t('settings.account')}</h3>
      {#if $isAuthenticated}
        <!-- Account Info -->
        <div class="settings-row">
          <div class="settings-row-info">
            <span class="settings-row-title">{$t('settings.logged_in')}</span>
            <span class="settings-row-desc"><strong>{$user?.username || $t('nav.user')}</strong></span>
          </div>
          <div class="settings-row-control">
            <button class="btn btn-secondary" on:click={() => authStore.clearSession()}>{$t('settings.sign_out')}</button>
          </div>
        </div>

        <!-- Change password button -->
        <div class="settings-row">
          <div class="settings-row-info">
            <span class="settings-row-title">{$t('settings.change_password')}</span>
            <span class="settings-row-desc">{$t('modals.auth.password')}</span>
          </div>
          <div class="settings-row-control">
            <button class="btn btn-secondary" on:click={() => (showPasswordModal = true)}>{$t('settings.change_password')}</button>
          </div>
        </div>
      {/if}
    </div>

    <!-- Group 4: Server Administration -->
    <div class="settings-card">
      <h3 class="settings-card-title">{$t('settings.file_mgmt')}</h3>
      
      <!-- Rebuild Index -->
      <div class="settings-row">
        <div class="settings-row-info">
          <span class="settings-row-title">{$t('settings.search_index')}</span>
          <span class="settings-row-desc">{$t('settings.search_index_desc')}</span>
        </div>
        <div class="settings-row-control">
          <button
            class="btn btn-primary"
            disabled={isRebuilding}
            on:click={handleRebuildIndex}
          >
            {isRebuilding ? $t('settings.rebuilding') : $t('settings.rebuild_index')}
          </button>
        </div>
      </div>

      {#if rebuildMessage}
        <div
          style="margin-top: 12px; padding: 12px; border-radius: var(--radius-md); font-size: 13px; font-weight: 500;
                 background-color: {rebuildSuccess ? 'rgba(76, 175, 80, 0.15)' : 'rgba(255, 82, 82, 0.15)'};
                 color: {rebuildSuccess ? 'var(--color-success)' : 'var(--color-danger)'};"
        >
          {rebuildMessage}
        </div>
      {/if}
    </div>
  </div>
</div>

<!-- Change Password Modal Dialog -->
{#if showPasswordModal}
  <div class="modal-backdrop" on:click|self={() => (showPasswordModal = false)}>
    <div class="dialog-card">
      <h3 class="text-title" style="margin: 0; color: var(--text-main); font-weight: 700;">{$t('settings.change_password')}</h3>
      <div style="display: flex; flex-direction: column; gap: 12px; margin-top: 16px;">
        <div>
          <label class="text-caption" style="display: block; margin-bottom: 4px; font-weight: 600; color: var(--text-sub);">{$t('settings.new_password')}</label>
          <input
            type="password"
            class="form-input text-body"
            placeholder={$t('modals.auth.password_placeholder')}
            bind:value={newPassword}
          />
        </div>
        <div>
          <label class="text-caption" style="display: block; margin-bottom: 4px; font-weight: 600; color: var(--text-sub);">{$t('settings.confirm_new_password')}</label>
          <input
            type="password"
            class="form-input text-body"
            placeholder={$t('modals.auth.confirm_password_placeholder')}
            bind:value={confirmNewPassword}
            on:keydown={(e) => e.key === 'Enter' && handleChangePassword()}
          />
        </div>
      </div>
      {#if passwordError}
        <div class="text-caption" style="color: var(--color-danger); font-weight: 600; margin-top: 8px;">{passwordError}</div>
      {/if}
      <div class="dialog-actions" style="display: flex; justify-content: flex-end; gap: var(--spacing-sm); margin-top: 20px;">
        <button class="btn btn-secondary" on:click={() => { showPasswordModal = false; passwordError = ''; }}>{$t('common.cancel')}</button>
        <button class="btn btn-primary" on:click={handleChangePassword}>{$t('common.save')}</button>
      </div>
    </div>
  </div>
{/if}

<style>
  .settings-wrapper {
    width: 100%;
    min-height: 100%;
  }

  .dialog-card {
    width: 100%;
    max-width: 400px;
    background-color: var(--bg-surface);
    border-radius: var(--radius-xl);
    border: 1px solid var(--border-color);
    box-shadow: var(--shadow-card);
    padding: var(--spacing-xl);
    display: flex;
    flex-direction: column;
  }
</style>
