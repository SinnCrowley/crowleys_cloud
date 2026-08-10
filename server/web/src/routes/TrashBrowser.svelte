<script>
  import { onMount, createEventDispatcher } from 'svelte';
  import { trashApi } from '../api/trash.js';
  import { filesApi } from '../api/files.js';

  const dispatch = createEventDispatcher();

  export let scope = 'private';

  let trashEntries = [];
  let isLoading = true;
  let errorMsg = '';
  let searchQuery = '';
  let selectedIds = new Set();
  let trashRetentionDays = 30; // default fallback

  // Custom modal dialog state
  let confirmDeleteModal = null; // null | { ids, title, message }

  $: filteredEntries = trashEntries.filter((item) => {
    if (!searchQuery.trim()) return true;
    const q = searchQuery.toLowerCase();
    return (
      item.name.toLowerCase().includes(q) ||
      (item.original_path && item.original_path.toLowerCase().includes(q))
    );
  });

  onMount(async () => {
    await loadTrash();
    await loadTrashSettings();
  });

  async function loadTrashSettings() {
    try {
      const res = await filesApi.getTrashSettings();
      if (res && res.trash_retention_days !== undefined) {
        trashRetentionDays = res.trash_retention_days;
      }
    } catch (e) {
      console.warn('Failed to load trash settings:', e);
    }
  }

  async function loadTrash() {
    isLoading = true;
    errorMsg = '';
    try {
      const res = await trashApi.listTrash({ scope });
      trashEntries = res.entries || [];
      selectedIds.clear();
      selectedIds = selectedIds;
    } catch (err) {
      errorMsg = err.message || 'Failed to load trash';
    } finally {
      isLoading = false;
    }
  }

  function toggleSelect(id) {
    if (selectedIds.has(id)) {
      selectedIds.delete(id);
    } else {
      selectedIds.add(id);
    }
    selectedIds = selectedIds;
  }

  function toggleSelectAll() {
    if (selectedIds.size === filteredEntries.length) {
      selectedIds.clear();
    } else {
      selectedIds = new Set(filteredEntries.map((e) => e.id));
    }
    selectedIds = selectedIds;
  }

  async function handleRestore(ids) {
    if (ids.length === 0) return;
    isLoading = true;
    try {
      await trashApi.restoreTrash(ids);
      dispatch('toast', { message: `Successfully restored ${ids.length} item(s).`, type: 'success' });
      await loadTrash();
    } catch (err) {
      dispatch('toast', { message: err.message || 'Failed to restore items', type: 'error' });
    } finally {
      isLoading = false;
    }
  }

  function requestDelete(ids) {
    if (ids.length === 0) return;
    confirmDeleteModal = {
      ids,
      title: 'Delete Permanently',
      message: `Are you sure you want to permanently delete ${ids.length} item(s)? This action cannot be undone.`
    };
  }

  function requestEmptyTrash() {
    if (trashEntries.length === 0) return;
    confirmDeleteModal = {
      ids: trashEntries.map((e) => e.id),
      title: 'Empty Trash Bin',
      message: 'Are you sure you want to permanently delete all items in the trash bin? This action cannot be undone.'
    };
  }

  async function confirmDeleteAction() {
    if (!confirmDeleteModal) return;
    const { ids } = confirmDeleteModal;
    confirmDeleteModal = null;
    isLoading = true;
    try {
      await trashApi.deleteTrash(ids);
      dispatch('toast', { message: `Permanently deleted ${ids.length} item(s).`, type: 'success' });
      await loadTrash();
    } catch (err) {
      dispatch('toast', { message: err.message || 'Failed to delete items', type: 'error' });
    } finally {
      isLoading = false;
    }
  }

  function getMaterialIcon(item) {
    if (item.is_dir) return 'folder';
    if (item.type === 'photo') return 'image';
    if (item.type === 'video') return 'movie';
    if (item.type === 'audio') return 'music_note';
    if (item.type === 'archive') return 'archive';
    return 'description';
  }

  function formatSize(bytes) {
    if (bytes === 0) return '0 B';
    if (!bytes || isNaN(bytes)) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.min(Math.floor(Math.log(bytes) / Math.log(k)), sizes.length - 1);
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  }

  function formatDate(timestamp) {
    if (!timestamp || isNaN(timestamp)) return '--';
    const d = new Date(timestamp);
    return isNaN(d.getTime()) ? '--' : d.toLocaleDateString();
  }
</script>

<div class="trash-browser-layout">
  <!-- Top Utility Header adapting Reference 3 layout -->
  <div class="trash-toolbar">
    <div class="trash-title-section">
      <button class="btn-icon back-btn" on:click={() => dispatch('back')} title="Back to Files">
        <span class="material-symbols-outlined">arrow_back</span>
      </button>
      <h2 class="trash-title text-title">Trash Bin</h2>
      <span class="trash-badge-desc">
        {#if trashRetentionDays === -1}
          Never auto-deleted
        {:else}
          Auto-deleted after {trashRetentionDays} days
        {/if}
      </span>
    </div>

    <div class="trash-search-section">
      <div class="search-wrapper">
        <span class="material-symbols-outlined search-icon">search</span>
        <input
          type="text"
          class="form-input search-input text-body"
          placeholder="Search trash..."
          bind:value={searchQuery}
        />
      </div>
    </div>

    <div class="trash-actions">
      {#if selectedIds.size > 0}
        <button
          class="btn btn-secondary"
          on:click={() => handleRestore(Array.from(selectedIds))}
          title="Restore selected items"
        >
          <span class="material-symbols-outlined" style="color: var(--color-success)">restore</span>
          Restore ({selectedIds.size})
        </button>
        <button
          class="btn btn-secondary danger-btn"
          on:click={() => requestDelete(Array.from(selectedIds))}
          title="Permanently delete selected items"
        >
          <span class="material-symbols-outlined">delete_forever</span>
          Delete ({selectedIds.size})
        </button>
      {/if}

      <button
        class="btn btn-primary danger-btn"
        disabled={trashEntries.length === 0}
        on:click={requestEmptyTrash}
      >
        <span class="material-symbols-outlined">delete_sweep</span>
        Empty Trash
      </button>
    </div>
  </div>

  {#if errorMsg}
    <div class="error-banner text-sub">{errorMsg}</div>
  {/if}

  <main class="trash-content">
    {#if isLoading}
      <div class="loading-state text-sub">Loading trash...</div>
    {:else if filteredEntries.length === 0}
      <div class="empty-state-container">
        <span class="material-symbols-outlined empty-icon">delete_sweep</span>
        <h3 class="empty-title text-title">Trash is empty</h3>
        <p class="empty-sub text-sub">Deleted files will appear here before permanent erasure.</p>
      </div>
    {:else}
      <div class="trash-table-row table-header">
        <div class="col-check">
          <label class="custom-checkbox">
            <input
              type="checkbox"
              checked={selectedIds.size === filteredEntries.length && filteredEntries.length > 0}
              on:change={toggleSelectAll}
            />
            <span class="checkbox-indicator"></span>
          </label>
        </div>
        <div class="col-name">Name</div>
        <div class="col-path">Original Location</div>
        <div class="col-date">Date Deleted</div>
        <div class="col-size">Size</div>
        <div class="col-actions">Actions</div>
      </div>

      <div class="trash-list-container">
        {#each filteredEntries as item (item.id)}
          <div class="trash-table-row {selectedIds.has(item.id) ? 'selected' : ''}">
            <div class="col-check" on:click|stopPropagation>
              <label class="custom-checkbox">
                <input
                  type="checkbox"
                  checked={selectedIds.has(item.id)}
                  on:change={() => toggleSelect(item.id)}
                />
                <span class="checkbox-indicator"></span>
              </label>
            </div>
            <div class="col-name cell-content font-medium">
              <span class="material-symbols-outlined file-type-icon">{getMaterialIcon(item)}</span>
              <span class="file-name-text" title={item.name}>{item.name}</span>
            </div>
            <div class="col-path cell-content text-sub" title={item.original_path}>
              {item.original_path || '--'}
            </div>
            <div class="col-date cell-content text-sub">
              {formatDate(item.deleted_at)}
            </div>
            <div class="col-size cell-content text-sub">
              {item.is_dir ? '--' : formatSize(item.size)}
            </div>
            <div class="col-actions cell-content" on:click|stopPropagation>
              <button
                class="btn-icon restore-single-btn"
                title="Restore item"
                on:click={() => handleRestore([item.id])}
              >
                <span class="material-symbols-outlined" style="font-size: 18px; color: var(--color-success)">restore</span>
              </button>
              <button
                class="btn-icon delete-single-btn"
                title="Delete permanently"
                on:click={() => requestDelete([item.id])}
              >
                <span class="material-symbols-outlined" style="font-size: 18px; color: var(--color-danger)">delete_forever</span>
              </button>
            </div>
          </div>
        {/each}
      </div>
    {/if}
  </main>
</div>

<!-- Custom confirmation modal for trash deletions -->
{#if confirmDeleteModal}
  <div class="modal-backdrop" on:click|self={() => (confirmDeleteModal = null)}>
    <div class="dialog-card">
      <h3 class="text-title" style="margin: 0; color: var(--text-main); font-weight: 700;">{confirmDeleteModal.title}</h3>
      <p class="text-sub" style="margin: 8px 0 0 0; color: var(--text-sub); font-size: 14px; line-height: 1.5;">
        {confirmDeleteModal.message}
      </p>
      <div class="dialog-actions" style="display: flex; justify-content: flex-end; gap: var(--spacing-sm); margin-top: 16px;">
        <button class="btn btn-secondary" on:click={() => (confirmDeleteModal = null)}>Cancel</button>
        <button class="btn btn-primary danger-btn" on:click={confirmDeleteAction}>Delete Permanently</button>
      </div>
    </div>
  </div>
{/if}

<style>
  .trash-browser-layout {
    display: flex;
    flex-direction: column;
    height: 100%;
    flex: 1;
    background-color: var(--bg-background);
  }

  .trash-toolbar {
    height: 64px;
    background-color: var(--bg-surface);
    border-bottom: 1px solid var(--border-color);
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 24px;
    gap: var(--spacing-md);
    flex-shrink: 0;
  }

  .trash-title-section {
    display: flex;
    align-items: center;
    gap: var(--spacing-md);
  }

  .back-btn {
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .trash-title {
    margin: 0;
    color: var(--text-main);
  }

  .trash-badge-desc {
    font-size: 11px;
    font-weight: 600;
    background-color: var(--bg-background);
    padding: 4px 8px;
    border-radius: var(--radius-full);
    color: var(--text-sub);
  }

  .trash-search-section {
    flex: 1;
    max-width: 300px;
  }

  .search-wrapper {
    position: relative;
    display: flex;
    align-items: center;
    width: 100%;
  }

  .search-icon {
    position: absolute;
    left: 12px;
    color: var(--text-sub);
    pointer-events: none;
    font-size: 18px;
  }

  .search-input {
    width: 100%;
    height: 38px;
    padding: 0 12px 0 38px;
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    background-color: var(--bg-input);
    color: var(--text-main);
  }

  .trash-actions {
    display: flex;
    align-items: center;
    gap: var(--spacing-sm);
  }

  .trash-content {
    flex: 1;
    padding: 24px;
    display: flex;
    flex-direction: column;
    overflow: hidden;
  }

  .loading-state {
    text-align: center;
    padding: 64px;
  }

  .empty-state-container {
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;
    padding: 64px;
  }

  .empty-icon {
    font-size: 56px;
    color: var(--text-sub);
    opacity: 0.5;
    margin-bottom: var(--spacing-md);
  }

  .empty-title {
    margin: 0 0 8px 0;
    color: var(--text-main);
  }

  .empty-sub {
    margin: 0;
    color: var(--text-sub);
  }

  .trash-table-row {
    display: grid;
    grid-template-columns: 48px 4.5fr 3fr 2fr 1fr 1fr;
    gap: var(--spacing-md);
    padding: 12px 16px;
    align-items: center;
    border: 1px solid transparent;
  }

  .trash-table-row.table-header {
    border-bottom: 1px solid var(--border-color);
    color: var(--text-sub);
    font-size: 12px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    margin-bottom: 8px;
  }

  .trash-list-container {
    display: flex;
    flex-direction: column;
    gap: 4px;
    overflow-y: auto;
    flex: 1;
  }

  .trash-table-row:not(.table-header) {
    background-color: var(--bg-surface);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    cursor: pointer;
    transition: background-color 0.1s ease, border-color 0.1s ease;
  }

  .trash-table-row:not(.table-header):hover {
    background-color: var(--bg-surface-hover);
    border-color: rgba(250, 82, 82, 0.15);
  }

  .trash-table-row.selected {
    background-color: var(--selection-bg);
    border-color: var(--selection-border);
  }

  .col-check {
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .cell-content {
    display: flex;
    align-items: center;
    min-width: 0;
  }

  .col-date, .col-size {
    justify-content: flex-end;
    text-align: right;
  }

  .col-actions {
    display: flex;
    justify-content: flex-end;
    align-items: center;
    gap: 8px;
    text-align: right;
  }

  .file-type-icon {
    font-size: 20px;
    margin-right: 12px;
    color: var(--text-sub);
    flex-shrink: 0;
  }

  .file-name-text {
    font-size: 14px;
    font-weight: 600;
    color: var(--text-main);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .col-path {
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .restore-single-btn, .delete-single-btn {
    width: 32px;
    height: 32px;
    border-radius: var(--radius-full);
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .restore-single-btn:hover {
    background-color: rgba(76, 175, 80, 0.12);
  }

  .delete-single-btn:hover {
    background-color: rgba(244, 67, 54, 0.12);
  }

  .dialog-card {
    width: 100%;
    max-width: 440px;
    background-color: var(--bg-surface);
    border-radius: var(--radius-xl);
    border: 1px solid var(--border-color);
    box-shadow: var(--shadow-card);
    padding: var(--spacing-xl);
    display: flex;
    flex-direction: column;
    gap: var(--spacing-md);
  }

  @media (max-width: 768px) {
    .trash-table-row {
      grid-template-columns: 48px 8fr 48px;
    }
    .col-path, .col-date, .col-size {
      display: none;
    }
  }
</style>
