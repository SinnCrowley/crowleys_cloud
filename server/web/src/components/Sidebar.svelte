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
  import { t } from '../stores/i18n.js';
  import { authStore } from '../stores/auth.js';
  import { statsStore } from '../stores/stats.js';
  const { user } = authStore;

  export let currentRoute = 'dashboard';
  export let filterType = 'all';
  export let scope = 'private';

  function formatSize(bytes) {
    if (!bytes || bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  }

  $: quotaLimit = Number($user?.quota_bytes ?? $statsStore.limitBytes ?? 0);
  $: quotaUsed = Number($user?.used_bytes ?? $statsStore.usedBytes ?? $statsStore.totalSize ?? 0);
  $: quotaPercent = quotaLimit > 0 ? Math.min(100, Math.round((quotaUsed / quotaLimit) * 100)) : 100;

  const dispatch = createEventDispatcher();

  function closeMobileSidebar() {
    if (typeof document !== 'undefined') {
      const sidebar = document.querySelector('.sidebar-nav');
      if (sidebar) sidebar.classList.remove('open');
      const backdrop = document.querySelector('.sidebar-mobile-backdrop');
      if (backdrop) backdrop.classList.remove('open');
    }
  }

  function selectRoute(route, newFilterType = 'all', newScope = 'private') {
    closeMobileSidebar();
    dispatch('navigate', { route, filterType: newFilterType, scope: newScope });
  }

  function handleUploadTrigger() {
    closeMobileSidebar();
    dispatch('uploadTrigger');
  }
</script>

<aside class="sidebar-nav">
  <div class="sidebar-brand">
    <div class="sidebar-brand-logo">
      <img src="/logo.png" alt="Crowley's Cloud Logo" />
    </div>
  </div>

  <div class="sidebar-add-btn-container">
    <button class="sidebar-add-btn" on:click={handleUploadTrigger}>
      <span class="material-symbols-outlined">upload</span>
      {$t('nav.upload_file')}
    </button>
  </div>

  <nav class="sidebar-menu">
    <button
      class="sidebar-item {currentRoute === 'dashboard' ? 'active' : ''}"
      on:click={() => selectRoute('dashboard')}
    >
      <span class="material-symbols-outlined">dashboard</span>
      <span>{$t('nav.dashboard')}</span>
    </button>

    <div class="sidebar-storage-widget-container" style="padding: 2px 4px 6px 4px;">
      <div class="storage-quota-widget" title="{formatSize(quotaUsed)} / {quotaLimit > 0 ? formatSize(quotaLimit) : '∞'}" style="padding: 8px 12px; border-radius: var(--radius-md); background: var(--bg-surface-hover); flex-direction: column; align-items: stretch; gap: 6px;">
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <span style="display: flex; align-items: center; gap: 6px;">
            <span class="material-symbols-outlined" style="font-size: 15px; color: var(--accent-color);">cloud</span>
            <span style="font-size: 11px; font-weight: 600;">{$t('dashboard.storage_used')}</span>
          </span>
          <span style="font-size: 11px; opacity: 0.85;">{formatSize(quotaUsed)} / {quotaLimit > 0 ? formatSize(quotaLimit) : '∞'}</span>
        </div>
        {#if quotaLimit > 0}
          <div class="storage-quota-progress-container" style="width: 100%; height: 4px;">
            <div class="storage-quota-progress-fill" style="width: {quotaPercent}%;"></div>
          </div>
        {/if}
      </div>
    </div>

    <div class="sidebar-divider"></div>

    <button
      class="sidebar-item {currentRoute === 'files' && scope === 'private' && filterType === 'all' ? 'active' : ''}"
      on:click={() => selectRoute('files', 'all', 'private')}
    >
      <span class="material-symbols-outlined">folder</span>
      <span>{$t('nav.all_files')}</span>
    </button>

    <button
      class="sidebar-item {currentRoute === 'files' && scope === 'private' && filterType === 'photo' ? 'active' : ''}"
      on:click={() => selectRoute('files', 'photo', 'private')}
    >
      <span class="material-symbols-outlined">photo</span>
      <span>{$t('nav.photos')}</span>
    </button>

    <button
      class="sidebar-item {currentRoute === 'files' && scope === 'private' && filterType === 'video' ? 'active' : ''}"
      on:click={() => selectRoute('files', 'video', 'private')}
    >
      <span class="material-symbols-outlined">videocam</span>
      <span>{$t('nav.videos')}</span>
    </button>

    <button
      class="sidebar-item {currentRoute === 'files' && scope === 'private' && filterType === 'audio' ? 'active' : ''}"
      on:click={() => selectRoute('files', 'audio', 'private')}
    >
      <span class="material-symbols-outlined">audiotrack</span>
      <span>{$t('nav.audio')}</span>
    </button>

    <button
      class="sidebar-item {currentRoute === 'files' && scope === 'private' && filterType === 'document' ? 'active' : ''}"
      on:click={() => selectRoute('files', 'document', 'private')}
    >
      <span class="material-symbols-outlined">description</span>
      <span>{$t('nav.documents')}</span>
    </button>

    <button
      class="sidebar-item {currentRoute === 'files' && scope === 'private' && filterType === 'other' ? 'active' : ''}"
      on:click={() => selectRoute('files', 'other', 'private')}
    >
      <span class="material-symbols-outlined">insert_drive_file</span>
      <span>{$t('nav.other')}</span>
    </button>

    <div class="sidebar-divider"></div>

    <button
      class="sidebar-item {currentRoute === 'files' && scope === 'shared' ? 'active' : ''}"
      on:click={() => selectRoute('files', 'all', 'shared')}
    >
      <span class="material-symbols-outlined">group</span>
      <span>{$t('nav.shared')}</span>
    </button>
  </nav>

  <div class="sidebar-footer">
    {#if $user?.role === 'admin' || $user?.role === 'superuser'}
      <button class="sidebar-item {currentRoute === 'admin' ? 'active' : ''}" on:click={() => selectRoute('admin')}>
        <span class="material-symbols-outlined" aria-hidden="true">admin_panel_settings</span><span>{$t('admin.title')}</span>
      </button>
    {/if}
    <button
      class="sidebar-item {currentRoute === 'trash' ? 'active' : ''}"
      on:click={() => selectRoute('trash')}
    >
      <span class="material-symbols-outlined">delete</span>
      <span>{$t('nav.trash')}</span>
    </button>

    <button
      class="sidebar-item {currentRoute === 'settings' ? 'active' : ''}"
      on:click={() => selectRoute('settings')}
    >
      <span class="material-symbols-outlined">settings</span>
      <span>{$t('nav.settings')}</span>
    </button>
  </div>
</aside>
