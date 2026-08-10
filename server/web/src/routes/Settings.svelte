<script>
  import { createEventDispatcher, onMount } from 'svelte';
  import { themeState } from '../stores/theme.js';
  import { filesStore } from '../stores/files.js';
  import { authStore } from '../stores/auth.js';
  import { filesApi } from '../api/files.js';
  import { authApi } from '../api/auth.js';
  import CustomSelect from '../components/CustomSelect.svelte';

  const dispatch = createEventDispatcher();

  const { theme, fontScale, accent } = themeState;
  const { isAuthenticated, user } = authStore;

  let showHiddenFiles = false;
  let biometricLogin = true; // mapped to Automatic Sign In
  let tokenLifetime = '30days'; // mapped to Require login duration
  let cacheMaxBytes = 500 * 1024 * 1024; // 500 MB default
  let trashRetentionDays = 30; // default server policy

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

  const trashOptions = [
    { value: 7, label: '7 days' },
    { value: 14, label: '14 days' },
    { value: 30, label: '30 days (default)' },
    { value: 90, label: '90 days' },
    { value: -1, label: 'Never delete automatically' }
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

  async function handleTrashRetentionChange(e) {
    const days = parseInt(e.target.value);
    trashRetentionDays = days;
    try {
      await filesApi.setTrashSettings(days);
      dispatch('toast', { message: 'Trash retention policy updated on server.', type: 'success' });
    } catch (err) {
      dispatch('toast', { message: err.message || 'Failed to update trash retention policy', type: 'error' });
    }
  }

  async function handleRebuildIndex() {
    isRebuilding = true;
    rebuildMessage = '';
    try {
      const res = await filesApi.rebuildIndex({ scope: 'private' });
      rebuildSuccess = true;
      rebuildMessage = res.message || 'Index rebuilt successfully!';
      dispatch('toast', { message: 'Search index rebuilt successfully.', type: 'success' });
      filesStore.loadDirectory();
    } catch (err) {
      rebuildSuccess = false;
      rebuildMessage = err.message || 'Failed to rebuild search index';
      dispatch('toast', { message: 'Failed to rebuild search index.', type: 'error' });
    } finally {
      isRebuilding = false;
    }
  }

  async function handleChangePassword() {
    if (!newPassword.trim()) {
      passwordError = 'Password cannot be empty';
      return;
    }
    if (newPassword !== confirmNewPassword) {
      passwordError = 'Passwords do not match';
      return;
    }
    passwordError = '';
    try {
      await authApi.changePassword(newPassword.trim());
      showPasswordModal = false;
      newPassword = '';
      confirmNewPassword = '';
      dispatch('toast', { message: 'Password updated. Please sign in again.', type: 'success' });
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
    dispatch('toast', { message: `Cache cleared successfully! Removed ${count} temporary items.`, type: 'success' });
  }
</script>

<div class="settings-wrapper" style="padding: 24px;">
  <div class="canvas-header">
    <div class="canvas-header-info">
      <h2>Settings</h2>
      <p>Configure interface options, storage preferences, and server utilities.</p>
    </div>
  </div>

  <div class="settings-layout">
    <!-- Group 1: Appearance & Theme -->
    <div class="settings-card">
      <h3 class="settings-card-title">Appearance & Theme</h3>
      
      <!-- Theme Mode -->
      <div class="settings-row">
        <div class="settings-row-info">
          <span class="settings-row-title">Dark Mode</span>
          <span class="settings-row-desc">Switch between light and dark visual themes.</span>
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
          <span class="settings-row-title">Accent Color Scheme</span>
          <span class="settings-row-desc">Choose a primary color preset that matches the mobile app.</span>
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
          <span class="settings-row-title">Text Scale</span>
          <span class="settings-row-desc">Adjust the global interface text scaling ({($fontScale * 100).toFixed(0)}%).</span>
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
      <h3 class="settings-card-title">Cache & Storage Management</h3>
      
      <!-- Cache Limit -->
      <div class="settings-row">
        <div class="settings-row-info">
          <span class="settings-row-title">Cache Size Limit</span>
          <span class="settings-row-desc">Define the maximum local storage allocation for previews and thumbnails.</span>
        </div>
        <div class="settings-row-control">
          <CustomSelect
            bind:value={cacheMaxBytes}
            options={cacheOptions}
            on:change={() => updateLocalSetting('cc_cache_max_bytes', cacheMaxBytes)}
          />
        </div>
      </div>

      <!-- Clear Cache Button -->
      <div class="settings-row">
        <div class="settings-row-info">
          <span class="settings-row-title">Clear Temporary Cache</span>
          <span class="settings-row-desc">Instantly delete all local thumbnails and folder cache descriptors.</span>
        </div>
        <div class="settings-row-control">
          <button class="btn btn-secondary" on:click={clearThumbnailCache}>Clear Cache</button>
        </div>
      </div>
    </div>

    <!-- Group 3: Security & Behavior -->
    <div class="settings-card">
      <h3 class="settings-card-title">Security & Behavior</h3>
      
      <!-- Require login (formerly Token Lifetime) -->
      <div class="settings-row">
        <div class="settings-row-info">
          <span class="settings-row-title">Require login</span>
          <span class="settings-row-desc">Define session credential expiration duration.</span>
        </div>
        <div class="settings-row-control">
          <CustomSelect
            bind:value={tokenLifetime}
            options={loginOptions}
            on:change={() => updateLocalSetting('cc_token_lifetime', tokenLifetime)}
          />
        </div>
      </div>

      <!-- Automatic Sign In -->
      <div class="settings-row">
        <div class="settings-row-info">
          <span class="settings-row-title">Automatic Sign In</span>
          <span class="settings-row-desc">Keep your session active and automatically log in on this device.</span>
        </div>
        <div class="settings-row-control">
          <label class="custom-checkbox">
            <input
              type="checkbox"
              bind:checked={biometricLogin}
              on:change={() => updateLocalSetting('cc_biometric_login', biometricLogin)}
            />
            <span class="checkbox-indicator"></span>
          </label>
        </div>
      </div>

      <!-- Show Hidden Files -->
      <div class="settings-row">
        <div class="settings-row-info">
          <span class="settings-row-title">Show Hidden Files</span>
          <span class="settings-row-desc">Display files and folders starting with a dot (e.g., .git, .env).</span>
        </div>
        <div class="settings-row-control">
          <label class="custom-checkbox">
            <input
              type="checkbox"
              bind:checked={showHiddenFiles}
              on:change={() => updateLocalSetting('cc_show_hidden', showHiddenFiles)}
            />
            <span class="checkbox-indicator"></span>
          </label>
        </div>
      </div>
    </div>

    <!-- Group 4: User Account -->
    <div class="settings-card">
      <h3 class="settings-card-title">User Account</h3>
      {#if $isAuthenticated}
        <!-- Account Info -->
        <div class="settings-row">
          <div class="settings-row-info">
            <span class="settings-row-title">Signed In User</span>
            <span class="settings-row-desc">Username: <strong>{$user?.username || 'User'}</strong></span>
          </div>
          <div class="settings-row-control">
            <button class="btn btn-secondary" on:click={() => authStore.clearSession()}>Sign Out</button>
          </div>
        </div>

        <!-- Change password button -->
        <div class="settings-row">
          <div class="settings-row-info">
            <span class="settings-row-title">Change password</span>
            <span class="settings-row-desc">Update password for your account. All sessions will be revoked.</span>
          </div>
          <div class="settings-row-control">
            <button class="btn btn-secondary" on:click={() => (showPasswordModal = true)}>Change Password</button>
          </div>
        </div>
      {:else}
        <div class="settings-row">
          <div class="settings-row-info">
            <span class="settings-row-title">Anonymous Access</span>
            <span class="settings-row-desc">Sign in to sync files and manage your personal repository.</span>
          </div>
        </div>
      {/if}
    </div>

    <!-- Group 5: Server Administration -->
    <div class="settings-card">
      <h3 class="settings-card-title">Server Administration</h3>
      
      <!-- Rebuild Index -->
      <div class="settings-row">
        <div class="settings-row-info">
          <span class="settings-row-title">Rebuild Search Index</span>
          <span class="settings-row-desc">Force the server to re-scan physical directories and rebuild search SQLite tables.</span>
        </div>
        <div class="settings-row-control">
          <button
            class="btn btn-primary"
            disabled={isRebuilding}
            on:click={handleRebuildIndex}
          >
            {isRebuilding ? 'Running...' : 'Rebuild Index'}
          </button>
        </div>
      </div>

      <!-- Server Trash retention -->
      {#if $isAuthenticated}
        <div class="settings-row">
          <div class="settings-row-info">
            <span class="settings-row-title">Trash Retention Policy</span>
            <span class="settings-row-desc">Server-side deletion period for trashed files.</span>
          </div>
          <div class="settings-row-control">
            <CustomSelect
              bind:value={trashRetentionDays}
              options={trashOptions}
              on:change={handleTrashRetentionChange}
            />
          </div>
        </div>
      {/if}
      
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
      <h3 class="text-title" style="margin: 0; color: var(--text-main); font-weight: 700;">Change Password</h3>
      <div style="display: flex; flex-direction: column; gap: 12px; margin-top: 16px;">
        <div>
          <label class="text-caption" style="display: block; margin-bottom: 4px; font-weight: 600; color: var(--text-sub);">New Password</label>
          <input
            type="password"
            class="form-input text-body"
            placeholder="Enter new password"
            bind:value={newPassword}
          />
        </div>
        <div>
          <label class="text-caption" style="display: block; margin-bottom: 4px; font-weight: 600; color: var(--text-sub);">Confirm New Password</label>
          <input
            type="password"
            class="form-input text-body"
            placeholder="Confirm new password"
            bind:value={confirmNewPassword}
            on:keydown={(e) => e.key === 'Enter' && handleChangePassword()}
          />
        </div>
      </div>
      {#if passwordError}
        <div class="text-caption" style="color: var(--color-danger); font-weight: 600; margin-top: 8px;">{passwordError}</div>
      {/if}
      <div class="dialog-actions" style="display: flex; justify-content: flex-end; gap: var(--spacing-sm); margin-top: 20px;">
        <button class="btn btn-secondary" on:click={() => { showPasswordModal = false; passwordError = ''; }}>Cancel</button>
        <button class="btn btn-primary" on:click={handleChangePassword}>Update Password</button>
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
