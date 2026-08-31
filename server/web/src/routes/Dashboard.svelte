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
  import { onMount, createEventDispatcher } from 'svelte';
  import { statsStore, refreshStats } from '../stores/stats.js';
  import { t } from '../stores/i18n.js';

  const dispatch = createEventDispatcher();

  let isDragActive = false;
  let dragCounter = 0;

  onMount(() => {
    refreshStats();
  });

  function formatSize(bytes) {
    if (!bytes || bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  }

  function handleNavigate(filterType = 'all', scope = 'private') {
    dispatch('navigate', { route: 'files', filterType, scope });
  }

  function handleDragEnter(e) {
    e.preventDefault();
    e.stopPropagation();
    dragCounter++;
    if (e.dataTransfer && e.dataTransfer.types && Array.from(e.dataTransfer.types).includes('Files')) {
      isDragActive = true;
    }
  }

  function handleDragOver(e) {
    e.preventDefault();
    e.stopPropagation();
    if (e.dataTransfer) {
      e.dataTransfer.dropEffect = 'copy';
    }
  }

  function handleDragLeave(e) {
    e.preventDefault();
    e.stopPropagation();
    dragCounter--;
    if (dragCounter <= 0) {
      isDragActive = false;
      dragCounter = 0;
    }
  }

  function handleDrop(e) {
    e.preventDefault();
    e.stopPropagation();
    isDragActive = false;
    dragCounter = 0;

    if (e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files.length > 0) {
      const files = Array.from(e.dataTransfer.files);
      dispatch('uploadFiles', { files });
    }
  }
</script>

<!-- svelte-ignore a11y-click-events-have-key-events -->
<!-- svelte-ignore a11y-no-static-element-interactions -->
<div
  class="dashboard-wrapper"
  on:dragenter={handleDragEnter}
  on:dragover={handleDragOver}
  on:dragleave={handleDragLeave}
  on:drop={handleDrop}
>
  {#if isDragActive}
    <div class="drag-over-overlay">
      <div class="drag-drop-card">
        <span class="material-symbols-outlined drop-icon">cloud_upload</span>
        <h3 class="text-title" style="margin-top: 12px;">{$t('dashboard.drop_title')}</h3>
        <p class="text-sub">{$t('dashboard.drop_subtitle')}</p>
      </div>
    </div>
  {/if}

  <div class="canvas-header">
    <div class="canvas-header-info">
      <h2>{$t('dashboard.title')}</h2>
      <p>{$t('dashboard.subtitle')}</p>
    </div>

    <div class="dashboard-storage-widget">
      <div class="storage-widget-header">
        <div class="storage-widget-title">
          <span class="material-symbols-outlined storage-icon">cloud</span>
          <span>{$t('dashboard.storage_used')}</span>
        </div>
        <span class="storage-widget-size">{formatSize($statsStore.totalSize)} / ∞</span>
      </div>
      <div class="storage-widget-bar">
        <div class="storage-widget-fill" style="width: 100%;"></div>
      </div>
      <div class="storage-widget-footer">
        <span>{$t('dashboard.items_stored', { count: $statsStore.totalCount })}</span>
      </div>
    </div>
  </div>

  <div class="bento-grid">
    <!-- Large Summary Card (All Files) -->
    <!-- svelte-ignore a11y-click-events-have-key-events -->
    <!-- svelte-ignore a11y-no-static-element-interactions -->
    <div class="bento-card bento-card-large" on:click={() => handleNavigate('all', 'private')}>
      <div style="display: flex; justify-content: space-between; align-items: flex-start;">
        <div class="bento-card-icon-container primary-light">
          <span class="material-symbols-outlined">folder_open</span>
        </div>
      </div>
      <div>
        <h3 class="bento-card-title">{$t('dashboard.all_files')}</h3>
        <div class="bento-card-info">
          <span>{$t('common.items', { count: $statsStore.totalCount })}</span>
          <span>•</span>
          <span>{$t('dashboard.all_files_desc')}</span>
        </div>
      </div>
    </div>

    <!-- Photos Card -->
    <!-- svelte-ignore a11y-click-events-have-key-events -->
    <!-- svelte-ignore a11y-no-static-element-interactions -->
    <div class="bento-card bento-card-medium" on:click={() => handleNavigate('photo', 'private')}>
      <div class="bento-card-icon-container neutral-light">
        <span class="material-symbols-outlined">image</span>
      </div>
      <div>
        <h3 class="bento-card-title">{$t('dashboard.photos')}</h3>
        <div class="bento-card-info">{$t('common.items', { count: $statsStore.photoCount })} ({formatSize($statsStore.photoSize)})</div>
      </div>
    </div>

    <!-- Videos Card -->
    <!-- svelte-ignore a11y-click-events-have-key-events -->
    <!-- svelte-ignore a11y-no-static-element-interactions -->
    <div class="bento-card bento-card-small" on:click={() => handleNavigate('video', 'private')}>
      <div class="bento-card-icon-container neutral-light">
        <span class="material-symbols-outlined">movie</span>
      </div>
      <div>
        <h3 class="bento-card-title">{$t('dashboard.videos')}</h3>
        <div class="bento-card-info">{$t('common.items', { count: $statsStore.videoCount })} ({formatSize($statsStore.videoSize)})</div>
      </div>
    </div>

    <!-- Audio Card -->
    <!-- svelte-ignore a11y-click-events-have-key-events -->
    <!-- svelte-ignore a11y-no-static-element-interactions -->
    <div class="bento-card bento-card-small" on:click={() => handleNavigate('audio', 'private')}>
      <div class="bento-card-icon-container neutral-light">
        <span class="material-symbols-outlined">music_note</span>
      </div>
      <div>
        <h3 class="bento-card-title">{$t('dashboard.audio')}</h3>
        <div class="bento-card-info">{$t('common.items', { count: $statsStore.audioCount })} ({formatSize($statsStore.audioSize)})</div>
      </div>
    </div>

    <!-- Documents Card -->
    <!-- svelte-ignore a11y-click-events-have-key-events -->
    <!-- svelte-ignore a11y-no-static-element-interactions -->
    <div class="bento-card bento-card-small" on:click={() => handleNavigate('document', 'private')}>
      <div class="bento-card-icon-container neutral-light">
        <span class="material-symbols-outlined">description</span>
      </div>
      <div>
        <h3 class="bento-card-title">{$t('dashboard.documents')}</h3>
        <div class="bento-card-info">{$t('common.items', { count: $statsStore.documentCount })} ({formatSize($statsStore.documentSize)})</div>
      </div>
    </div>

    <!-- Shared Card -->
    <!-- svelte-ignore a11y-click-events-have-key-events -->
    <!-- svelte-ignore a11y-no-static-element-interactions -->
    <div class="bento-card bento-card-half" on:click={() => handleNavigate('all', 'shared')}>
      <div style="display: flex; justify-content: space-between; align-items: flex-start;">
        <div class="bento-card-icon-container neutral-light">
          <span class="material-symbols-outlined">group</span>
        </div>
        <div class="collaborator-stack">
          <span class="material-symbols-outlined" style="opacity: 0.5; margin-right: 8px;">groups</span>
        </div>
      </div>
      <div>
        <h3 class="bento-card-title">{$t('dashboard.shared')}</h3>
        <div class="bento-card-info">{$t('common.items', { count: $statsStore.sharedCount })} ({formatSize($statsStore.sharedSize)})</div>
      </div>
    </div>

    <!-- Other Card -->
    <!-- svelte-ignore a11y-click-events-have-key-events -->
    <!-- svelte-ignore a11y-no-static-element-interactions -->
    <div class="bento-card bento-card-half" on:click={() => handleNavigate('other', 'private')}>
      <div class="bento-card-icon-container neutral-light">
        <span class="material-symbols-outlined">category</span>
      </div>
      <div>
        <h3 class="bento-card-title">{$t('nav.other')}</h3>
        <div class="bento-card-info">{$t('common.items', { count: $statsStore.otherCount })} ({formatSize($statsStore.otherSize)})</div>
      </div>
    </div>
  </div>
</div>

<style>
  .dashboard-wrapper {
    position: relative;
    width: 100%;
    min-height: 100%;
    padding: 24px;
    box-sizing: border-box;
  }

  .drag-over-overlay {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    z-index: 800;
    background-color: rgba(250, 82, 82, 0.1);
    border: 2px dashed var(--accent-color);
    backdrop-filter: blur(4px);
    display: flex;
    align-items: center;
    justify-content: center;
    pointer-events: none;
    border-radius: var(--radius-lg);
  }

  .drag-drop-card {
    background-color: var(--bg-surface);
    border-radius: var(--radius-xl);
    border: 1px solid var(--border-color);
    padding: 32px 48px;
    text-align: center;
    box-shadow: var(--shadow-card);
    display: flex;
    flex-direction: column;
    align-items: center;
  }

  .drop-icon {
    font-size: 48px;
    color: var(--accent-color);
  }

  .canvas-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 24px;
    margin-bottom: 28px;
  }

  .dashboard-storage-widget {
    min-width: 320px;
    padding: 16px 22px;
    background: rgba(255, 255, 255, 0.04);
    border: 1px solid var(--border-color, rgba(255, 255, 255, 0.1));
    border-radius: 16px;
    display: flex;
    flex-direction: column;
    gap: 10px;
    backdrop-filter: blur(12px);
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
    user-select: none;
  }

  .storage-widget-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
  }

  .storage-widget-title {
    display: flex;
    align-items: center;
    gap: 8px;
    font-weight: 700;
    font-size: 14px;
    color: var(--text-main, #ffffff);
  }

  .storage-icon {
    font-size: 20px;
    color: var(--accent-color, #fa5252);
  }

  .storage-widget-size {
    font-weight: 700;
    font-size: 15px;
    color: var(--accent-color, #fa5252);
  }

  .storage-widget-bar {
    width: 100%;
    height: 8px;
    background-color: rgba(255, 255, 255, 0.1);
    border-radius: 4px;
    overflow: hidden;
  }

  .storage-widget-fill {
    height: 100%;
    background: linear-gradient(90deg, var(--accent-color, #fa5252) 0%, #ff8787 100%);
    border-radius: 4px;
    box-shadow: 0 0 12px rgba(250, 82, 82, 0.6);
  }

  .storage-widget-footer {
    font-size: 12px;
    color: var(--text-sub, #868e96);
    font-weight: 500;
  }
</style>
