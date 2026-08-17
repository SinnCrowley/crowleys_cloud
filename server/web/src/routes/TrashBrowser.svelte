<script>
  import { onMount, createEventDispatcher } from 'svelte';
  import { trashApi } from '../api/trash.js';
  import { filesApi } from '../api/files.js';
  import RestoreConflictModal from '../components/RestoreConflictModal.svelte';
  import MediaPreviewModal from '../components/MediaPreviewModal.svelte';

  const dispatch = createEventDispatcher();

  export let scope = 'private';
  export let searchQuery = '';
  export let layoutMode = 'list'; // 'list' | 'grid'
  export let sortBy = 'name'; // 'name' | 'date' | 'size' | 'type'
  export let sortOrder = 'asc'; // 'asc' | 'desc'

  let trashEntries = [];
  let isLoading = true;
  let errorMsg = '';
  let selectedIds = new Set();
  let trashRetentionDays = 30; // default fallback
  let thumbnailErrors = new Set();
  let activePreviewItem = null;

  // Custom modal dialog state
  let confirmDeleteModal = null; // null | { ids, title, message }
  let restoreConflictModal = null; // null | { conflicts, allIds }

  $: filteredEntries = trashEntries
    .filter((item) => {
      if (!searchQuery.trim()) return true;
      const q = searchQuery.toLowerCase();
      return (
        item.name.toLowerCase().includes(q) ||
        (item.original_path && item.original_path.toLowerCase().includes(q))
      );
    })
    .sort((a, b) => {
      let cmp = 0;
      if (sortBy === 'name') {
        cmp = a.name.localeCompare(b.name);
      } else if (sortBy === 'size') {
        cmp = (a.size || 0) - (b.size || 0);
      } else if (sortBy === 'date') {
        const da = new Date(a.deleted_at || 0).getTime();
        const db = new Date(b.deleted_at || 0).getTime();
        cmp = da - db;
      } else if (sortBy === 'type') {
        cmp = (a.type || '').localeCompare(b.type || '');
      }
      return sortOrder === 'desc' ? -cmp : cmp;
    });

  onMount(async () => {
    await loadTrash();
    await loadTrashSettings();
  });

  async function loadTrashSettings() {
    try {
      const res = await trashApi.getTrashSettings();
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
      const checkRes = await trashApi.checkRestoreConflicts(ids);
      if (checkRes.has_conflicts && checkRes.conflicts && checkRes.conflicts.length > 0) {
        isLoading = false;
        restoreConflictModal = {
          conflicts: checkRes.conflicts,
          allIds: ids
        };
        return;
      }
      await trashApi.restoreTrash(ids, false);
      selectedIds.clear();
      selectedIds = selectedIds;
      dispatch('toast', { message: `Successfully restored ${ids.length} item(s).`, type: 'success' });
      await loadTrash();
    } catch (err) {
      dispatch('toast', { message: err.message || 'Failed to restore items', type: 'error' });
    } finally {
      isLoading = false;
    }
  }

  async function handleRestoreConflictResolved(e) {
    const { decisions, allIds } = e.detail;
    restoreConflictModal = null;
    isLoading = true;
    try {
      const overwriteIds = [];
      const copyIds = [];

      for (const id of allIds) {
        if (decisions[id] === true) {
          overwriteIds.push(id);
        } else {
          copyIds.push(id);
        }
      }

      if (overwriteIds.length > 0) {
        await trashApi.restoreTrash(overwriteIds, true);
      }
      if (copyIds.length > 0) {
        await trashApi.restoreTrash(copyIds, false);
      }

      selectedIds.clear();
      selectedIds = selectedIds;
      dispatch('toast', { message: `Successfully restored ${allIds.length} item(s).`, type: 'success' });
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
    if (!item) return 'insert_drive_file';
    if (item.is_dir) return 'folder';
    const filename = item.name || item.original_path || '';
    const ext = filename.includes('.') ? filename.split('.').pop().toLowerCase() : '';

    switch (ext) {
      case 'pdf': return 'picture_as_pdf';
      case 'doc': case 'docx': return 'description';
      case 'xls': case 'xlsx': return 'table_chart';
      case 'ppt': case 'pptx': return 'slideshow';
      case 'zip': case 'tar': case 'gz': case '7z': case 'rar': case 'bz2': case 'xz': return 'folder_zip';
      case 'mp3': case 'wav': case 'ogg': case 'flac': case 'm4a': case 'aac': return 'audiotrack';
      case 'mp4': case 'mkv': case 'avi': case 'mov': case 'webm': case 'flv': return 'movie';
      case 'jpg': case 'jpeg': case 'png': case 'webp': case 'gif': case 'bmp': case 'heic': case 'avif': case 'heif': return 'image';
      case 'txt': case 'md': case 'json': case 'yaml': case 'yml': case 'xml': case 'log': case 'csv': case 'js': case 'ts': case 'html': case 'css': case 'dart': case 'cpp': case 'c': case 'h': case 'hpp': case 'py': case 'sh': return 'article';
      default:
        if (item.type === 'photo') return 'image';
        if (item.type === 'video') return 'movie';
        if (item.type === 'audio') return 'audiotrack';
        if (item.type === 'archive') return 'folder_zip';
        return 'insert_drive_file';
    }
  }

  function handleThumbnailError(id) {
    thumbnailErrors.add(id);
    thumbnailErrors = thumbnailErrors;
  }

  function isMediaItem(item) {
    if (!item || item.is_dir) return false;
    const name = item.name || '';
    return /\.(jpg|jpeg|png|webp|gif|bmp|heic|avif|heif|mp4|mkv|avi|mov|webm|flv|mp3|wav|ogg|flac|m4a|aac)$/i.test(name);
  }

  function handleItemClick(item) {
    if (selectedIds.size > 0) {
      toggleSelect(item.id);
      return;
    }
    if (item && !item.is_dir) {
      activePreviewItem = item;
    }
  }

  function handleItemDblClick(item) {
    if (item && !item.is_dir) {
      activePreviewItem = item;
    }
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

<div class="trash-wrapper">
  <div class="canvas-header">
    <div class="canvas-header-info">
      <h2>Trash Bin</h2>
      <p>
        {#if trashRetentionDays === -1}
          Items in trash are retained indefinitely until manually emptied.
        {:else}
          Items in trash are automatically deleted after {trashRetentionDays} days.
        {/if}
      </p>
    </div>

    <div class="trash-actions">
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

  {#if isLoading}
    <div class="loading-state text-sub">Loading trash...</div>
  {:else if filteredEntries.length === 0}
    <div class="empty-state">
      <span class="material-symbols-outlined empty-icon">delete_sweep</span>
      <h3 class="empty-title text-title">Trash is empty</h3>
      <p class="empty-sub text-sub">Deleted files will appear here before permanent erasure.</p>
    </div>
  {:else if layoutMode === 'grid'}
    <div class="trash-grid-container">
      {#each filteredEntries as item (item.id)}
        <!-- svelte-ignore a11y-click-events-have-key-events -->
        <!-- svelte-ignore a11y-no-static-element-interactions -->
        <div
          class="trash-grid-card {selectedIds.has(item.id) ? 'selected' : ''}"
          on:click={() => handleItemClick(item)}
          on:dblclick={() => handleItemDblClick(item)}
        >
          <div class="trash-grid-thumbnail">
            {#if (item.type === 'photo' || item.type === 'video' || isMediaItem(item)) && !thumbnailErrors.has(item.id)}
              <img
                src={filesApi.getThumbnailUrl({ trashId: item.id })}
                alt={item.name}
                on:error={() => handleThumbnailError(item.id)}
              />
            {:else}
              <span class="material-symbols-outlined grid-icon">{getMaterialIcon(item)}</span>
            {/if}
          </div>
          <div class="trash-grid-info">
            <div class="trash-grid-name" title={item.name}>{item.name}</div>
            <div class="trash-grid-footer">
              <span class="trash-grid-size text-sub">{item.is_dir ? 'Folder' : formatSize(item.size)}</span>
              <div class="trash-grid-actions" on:click|stopPropagation>
                <button
                  class="btn-icon card-action-btn"
                  title="Restore item"
                  on:click={() => handleRestore([item.id])}
                >
                  <span class="material-symbols-outlined" style="font-size: 16px; color: var(--color-success)">restore</span>
                </button>
                <button
                  class="btn-icon card-action-btn"
                  title="Delete permanently"
                  on:click={() => requestDelete([item.id])}
                >
                  <span class="material-symbols-outlined" style="font-size: 16px; color: var(--color-danger)">delete_forever</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      {/each}
    </div>
  {:else}
    <div class="trash-table">
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
          <!-- svelte-ignore a11y-click-events-have-key-events -->
          <!-- svelte-ignore a11y-no-static-element-interactions -->
          <div
            class="trash-table-row {selectedIds.has(item.id) ? 'selected' : ''}"
            on:click={() => handleItemClick(item)}
            on:dblclick={() => handleItemDblClick(item)}
          >
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
              <div class="list-item-thumbnail">
                {#if (item.type === 'photo' || item.type === 'video' || isMediaItem(item)) && !thumbnailErrors.has(item.id)}
                  <img
                    src={filesApi.getThumbnailUrl({ trashId: item.id })}
                    alt={item.name}
                    on:error={() => handleThumbnailError(item.id)}
                  />
                {:else}
                  <span class="material-symbols-outlined file-type-icon">{getMaterialIcon(item)}</span>
                {/if}
              </div>
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
    </div>
  {/if}
</div>

<!-- Floating Selection Action Bar for multi-selection -->
{#if selectedIds.size > 0}
  <div class="selection-action-bar">
    <div class="selection-info text-body">
      <span class="count-badge">{selectedIds.size}</span> selected
    </div>

    <div class="selection-buttons">
      <button class="btn btn-secondary" on:click={() => handleRestore(Array.from(selectedIds))}>
        <span class="material-symbols-outlined" style="font-size: 18px; color: var(--color-success)">restore</span>
        Restore Selected
      </button>

      <button class="btn btn-secondary danger-btn" on:click={() => requestDelete(Array.from(selectedIds))}>
        <span class="material-symbols-outlined" style="font-size: 18px; color: var(--color-danger)">delete_forever</span>
        Delete Selected
      </button>

      <button
        class="btn-icon"
        on:click={() => { selectedIds.clear(); selectedIds = selectedIds; }}
        title="Deselect all"
        style="display: flex; align-items: center; justify-content: center;"
      >
        <span class="material-symbols-outlined" style="font-size: 20px;">close</span>
      </button>
    </div>
  </div>
{/if}

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

<!-- Custom restore conflict modal -->
{#if restoreConflictModal}
  <RestoreConflictModal
    conflicts={restoreConflictModal.conflicts}
    allIds={restoreConflictModal.allIds}
    on:resolve={handleRestoreConflictResolved}
    on:close={() => (restoreConflictModal = null)}
  />
{/if}

<!-- Media & Text Preview Modal for Trash -->
{#if activePreviewItem}
  <MediaPreviewModal
    file={activePreviewItem}
    items={filteredEntries.filter((e) => !e.is_dir)}
    scope={scope}
    isTrash={true}
    on:close={() => (activePreviewItem = null)}
    on:changeItem={(e) => (activePreviewItem = e.detail)}
    on:restore={async (e) => {
      const target = e.detail;
      activePreviewItem = null;
      await handleRestore([target.id]);
    }}
    on:delete={(e) => {
      const target = e.detail;
      activePreviewItem = null;
      requestDelete([target.id]);
    }}
  />
{/if}

<style>
  .trash-wrapper {
    position: relative;
    width: 100%;
    min-height: 100%;
    padding: 24px;
    box-sizing: border-box;
    display: flex;
    flex-direction: column;
  }

  .trash-actions {
    display: flex;
    align-items: center;
    gap: var(--spacing-sm);
  }

  .danger-btn {
    color: #ffffff;
  }

  .loading-state {
    text-align: center;
    padding: 64px;
  }

  .error-banner {
    background-color: rgba(244, 67, 54, 0.1);
    color: var(--color-danger);
    padding: 12px 16px;
    border-radius: var(--radius-md);
    margin-bottom: 16px;
    border: 1px solid rgba(244, 67, 54, 0.2);
  }

  .trash-table {
    display: flex;
    flex-direction: column;
    flex: 1;
  }

  .trash-table-row {
    display: grid;
    grid-template-columns: 48px 4.5fr 3fr 2fr 1fr 100px;
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
    gap: 6px;
    overflow-y: auto;
    flex: 1;
    padding-bottom: 16px;
  }

  /* Trash Grid View - Matching FileGrid.svelte dimensions */
  .trash-grid-container {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    gap: 16px;
    overflow-y: auto;
    flex: 1;
    align-content: start;
    padding-bottom: 40px;
  }

  .trash-grid-card {
    position: relative;
    background-color: var(--bg-surface);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-lg);
    padding: 12px;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: space-between;
    aspect-ratio: 1 / 1.12;
    cursor: pointer;
    user-select: none;
    transition: background-color 0.1s ease, border-color 0.1s ease;
    min-width: 0;
  }

  .trash-grid-card:hover {
    background-color: var(--bg-surface-hover);
    border-color: rgba(250, 82, 82, 0.15);
  }

  .trash-grid-card.selected {
    background-color: var(--selection-bg);
    border-color: var(--selection-border);
  }

  .trash-grid-thumbnail {
    width: 100%;
    flex: 1;
    min-height: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    overflow: hidden;
    border-radius: var(--radius-md);
    background-color: var(--bg-background);
    margin-bottom: 8px;
  }

  .trash-grid-thumbnail img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    display: block;
  }

  .trash-grid-thumbnail .grid-icon {
    font-size: 56px;
    color: var(--accent-color);
  }

  .list-item-thumbnail {
    width: 32px;
    height: 32px;
    border-radius: var(--radius-sm);
    background-color: var(--bg-surface-variant, rgba(255, 255, 255, 0.04));
    display: flex;
    align-items: center;
    justify-content: center;
    overflow: hidden;
    flex-shrink: 0;
    margin-right: 8px;
  }

  .list-item-thumbnail img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    display: block;
  }

  .trash-grid-info {
    width: 100%;
  }

  .trash-grid-name {
    font-size: 14px;
    font-weight: 600;
    color: var(--text-main);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    width: 100%;
    text-align: left;
  }

  .trash-grid-card.selected .trash-grid-name {
    color: var(--accent-color);
  }

  .trash-grid-footer {
    display: flex;
    align-items: center;
    justify-content: space-between;
    width: 100%;
    margin-top: 4px;
    height: 24px;
  }

  .trash-grid-size {
    font-size: 11px;
    color: var(--text-sub);
  }

  .trash-grid-actions {
    display: flex;
    align-items: center;
    gap: 4px;
  }

  .card-action-btn {
    width: 24px;
    height: 24px;
    border-radius: var(--radius-full);
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--text-sub);
    transition: background-color 0.15s ease, color 0.15s ease;
  }

  .card-action-btn:hover {
    background-color: var(--bg-background);
  }

  .trash-table-row:not(.table-header) {
    background-color: var(--bg-surface);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    cursor: pointer;
    transition: background-color 0.15s ease, border-color 0.15s ease;
  }

  .trash-table-row:not(.table-header):hover {
    background-color: var(--bg-surface-hover);
    border-color: var(--border-color);
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
    color: var(--accent-color);
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
    background-color: rgba(76, 175, 80, 0.15);
  }

  .delete-single-btn:hover {
    background-color: rgba(244, 67, 54, 0.15);
  }

  /* Selection action bar styles matching SelectionActionBar.svelte */
  .selection-action-bar {
    position: fixed;
    bottom: 24px;
    left: 50%;
    transform: translateX(-50%);
    z-index: 850;
    display: flex;
    align-items: center;
    gap: 20px;
    background-color: var(--bg-surface);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-full);
    padding: 10px 24px;
    box-shadow: 0 10px 36px rgba(0, 0, 0, 0.45);
    backdrop-filter: blur(12px);
    user-select: none;
    animation: slideUp 0.2s ease-out;
  }

  @keyframes slideUp {
    from {
      transform: translate(-50%, 20px);
      opacity: 0;
    }
    to {
      transform: translate(-50%, 0);
      opacity: 1;
    }
  }

  .selection-info {
    display: flex;
    align-items: center;
    gap: 8px;
    font-size: 15px;
    font-weight: 600;
    color: var(--text-main);
  }

  .count-badge {
    background-color: var(--accent-color);
    color: #ffffff;
    padding: 3px 10px;
    border-radius: var(--radius-full);
    font-size: 13px;
    font-weight: 700;
  }

  .action-buttons {
    display: flex;
    align-items: center;
    gap: 10px;
  }

  .action-btn {
    padding: 8px 18px;
    font-size: 14px;
    font-weight: 700;
    border-radius: var(--radius-full);
  }

  .close-btn {
    width: 32px;
    height: 32px;
    border-radius: var(--radius-full);
    color: var(--text-sub);
    transition: background-color 0.15s ease, color 0.15s ease;
  }

  .close-btn:hover {
    background-color: var(--bg-surface-hover);
    color: var(--accent-color);
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
      grid-template-columns: 48px 1fr 80px;
    }
    .col-path, .col-date, .col-size {
      display: none;
    }
  }
</style>
