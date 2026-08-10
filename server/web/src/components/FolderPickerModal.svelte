<script>
  import { createEventDispatcher, onMount } from 'svelte';
  import { filesApi } from '../api/files.js';

  export let scope = 'private';
  export let title = 'Select Destination Folder';
  export let currentPath = '';

  const dispatch = createEventDispatcher();

  let folderPath = currentPath || '';
  let subfolders = [];
  let isLoading = false;
  let errorMsg = '';
  let showNewFolderInput = false;
  let newFolderName = '';

  $: pathSegments = folderPath ? folderPath.split('/').filter(Boolean) : [];

  async function loadFolders() {
    isLoading = true;
    errorMsg = '';
    try {
      // Query type: 'all' to ensure directory listings are correctly populated on C++ server
      const res = await filesApi.listDir({
        scope,
        path: folderPath,
        type: 'all'
      });
      // Filter for directories on the client-side
      subfolders = (res.entries || []).filter((e) => e.is_dir);
    } catch (err) {
      errorMsg = err.message || 'Failed to load folders';
      subfolders = [];
    } finally {
      isLoading = false;
    }
  }

  onMount(() => {
    loadFolders();
  });

  function navigateTo(path) {
    folderPath = path;
    loadFolders();
  }

  function navigateUp() {
    if (!folderPath) return;
    const parts = folderPath.split('/').filter(Boolean);
    parts.pop();
    folderPath = parts.join('/');
    loadFolders();
  }

  async function handleCreateFolder() {
    if (!newFolderName.trim()) return;
    const target = folderPath
      ? `${folderPath}/${newFolderName.trim()}`
      : newFolderName.trim();
    try {
      await filesApi.createFolder({ scope, path: target });
      newFolderName = '';
      showNewFolderInput = false;
      await loadFolders();
    } catch (err) {
      errorMsg = err.message || 'Failed to create folder';
    }
  }

  function handleSelect() {
    dispatch('confirm', folderPath);
  }

  function handleClose() {
    dispatch('close');
  }
</script>

<!-- svelte-ignore a11y-click-events-have-key-events -->
<!-- svelte-ignore a11y-no-static-element-interactions -->
<div class="modal-backdrop" on:click|self={handleClose}>
  <div class="folder-picker-card">
    <div class="picker-header">
      <h3 class="picker-title text-title">{title}</h3>
      <button class="btn-icon" on:click={handleClose} title="Close">
        <span class="material-symbols-outlined" style="font-size: 20px;">close</span>
      </button>
    </div>

    <!-- Breadcrumb path inside picker using Material Symbols -->
    <div class="picker-breadcrumbs text-body">
      <button
        class="crumb-btn {folderPath === '' ? 'active' : ''}"
        on:click={() => navigateTo('')}
        style="display: inline-flex; align-items: center;"
      >
        <span class="material-symbols-outlined" style="font-size: 16px; margin-right: 4px;">home</span>
        Root
      </button>
      {#each pathSegments as segment, index}
        <span class="crumb-separator">/</span>
        <button
          class="crumb-btn {index === pathSegments.length - 1 ? 'active' : ''}"
          on:click={() => navigateTo(pathSegments.slice(0, index + 1).join('/'))}
        >
          {segment}
        </button>
      {/each}
    </div>

    {#if errorMsg}
      <div class="error-banner text-sub">{errorMsg}</div>
    {/if}

    <div class="folder-list">
      {#if folderPath !== ''}
        <div class="folder-item up-item" on:click={navigateUp}>
          <span class="folder-icon" style="display: flex; align-items: center;">
            <span class="material-symbols-outlined" style="font-size: 18px; color: var(--text-sub);">arrow_upward</span>
          </span>
          <span class="folder-name text-body">.. (Up one level)</span>
        </div>
      {/if}

      {#if isLoading}
        <div class="loading-state text-sub">Loading folders...</div>
      {:else if subfolders.length === 0}
        <div class="empty-state-picker text-sub">No subfolders here</div>
      {:else}
        {#each subfolders as folder}
          <div
            class="folder-item"
            on:click={() => navigateTo(folder.path)}
          >
            <span class="folder-icon" style="display: flex; align-items: center;">
              <span class="material-symbols-outlined" style="color: var(--accent-color); font-variation-settings: 'FILL' 1; font-size: 20px;">folder</span>
            </span>
            <span class="folder-name text-body">{folder.name}</span>
            <span class="folder-arrow" style="display: flex; align-items: center; margin-left: auto;">
              <span class="material-symbols-outlined" style="font-size: 18px; color: var(--text-sub);">chevron_right</span>
            </span>
          </div>
        {/each}
      {/if}
    </div>

    {#if showNewFolderInput}
      <div class="new-folder-row">
        <input
          type="text"
          class="form-input text-body"
          placeholder="New folder name..."
          bind:value={newFolderName}
          on:keydown={(e) => e.key === 'Enter' && handleCreateFolder()}
        />
        <button class="btn btn-primary" on:click={handleCreateFolder}>Create</button>
        <button class="btn btn-secondary" on:click={() => (showNewFolderInput = false)}>Cancel</button>
      </div>
    {/if}

    <div class="picker-footer">
      <button
        class="btn btn-secondary"
        on:click={() => (showNewFolderInput = !showNewFolderInput)}
      >
        + New Folder
      </button>

      <div class="footer-actions">
        <button class="btn btn-secondary" on:click={handleClose}>Cancel</button>
        <button class="btn btn-primary" on:click={handleSelect}>
          Move Here ({folderPath || 'Root'})
        </button>
      </div>
    </div>
  </div>
</div>

<style>
  .folder-picker-card {
    width: 100%;
    max-width: 520px;
    max-height: 85vh;
    background-color: var(--bg-surface);
    border-radius: var(--radius-xl);
    border: 1px solid var(--border-color);
    box-shadow: var(--shadow-card);
    display: flex;
    flex-direction: column;
    overflow: hidden;
  }

  .picker-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: var(--spacing-md) var(--spacing-lg);
    border-bottom: 1px solid var(--border-color);
  }

  .picker-title {
    margin: 0;
    color: var(--text-main);
  }

  .picker-breadcrumbs {
    display: flex;
    align-items: center;
    flex-wrap: wrap;
    gap: var(--spacing-xs);
    padding: var(--spacing-sm) var(--spacing-lg);
    background-color: var(--bg-input);
    border-bottom: 1px solid var(--border-color);
  }

  .crumb-btn {
    background: none;
    border: none;
    color: var(--accent-color);
    cursor: pointer;
    padding: 2px 6px;
    border-radius: var(--radius-sm);
    font-size: calc(13px * var(--font-scale));
  }

  .crumb-btn.active {
    color: var(--text-main);
    font-weight: 700;
  }

  .crumb-separator {
    color: var(--text-sub);
    font-size: calc(12px * var(--font-scale));
  }

  .folder-list {
    flex: 1;
    min-height: 240px;
    max-height: 340px;
    overflow-y: auto;
    padding: var(--spacing-sm) var(--spacing-md);
    display: flex;
    flex-direction: column;
    gap: var(--spacing-xs);
  }

  .folder-item {
    display: flex;
    align-items: center;
    gap: var(--spacing-md);
    padding: var(--spacing-sm) var(--spacing-md);
    border-radius: var(--radius-md);
    cursor: pointer;
    transition: background-color 0.15s ease;
  }

  .folder-item:hover {
    background-color: var(--bg-surface-hover);
  }

  .folder-icon {
    display: flex;
    align-items: center;
  }

  .folder-name {
    color: var(--text-main);
    font-weight: 500;
  }

  .new-folder-row {
    display: flex;
    gap: var(--spacing-sm);
    padding: var(--spacing-md) var(--spacing-lg);
    border-top: 1px solid var(--border-color);
    background-color: var(--bg-background);
  }

  .new-folder-row .form-input {
    flex: 1;
  }

  .picker-footer {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: var(--spacing-md) var(--spacing-lg);
    border-top: 1px solid var(--border-color);
    background-color: var(--bg-surface);
  }

  .footer-actions {
    display: flex;
    gap: var(--spacing-sm);
  }
</style>
