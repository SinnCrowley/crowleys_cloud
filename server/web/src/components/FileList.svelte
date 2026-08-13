<script>
  import { createEventDispatcher } from 'svelte';
  import { filesApi } from '../api/files.js';

  export let items = [];
  export let selectedItems = new Set();
  export let filterType = 'all';
  export let currentPath = '';
  export let searchQuery = '';
  export let scope = 'private';

  const dispatch = createEventDispatcher();

  let isDragOver = false;
  let dragCounter = 0;
  let hoveredFolderTarget = null;
  let thumbnailErrors = new Set();

  function handleThumbnailError(path) {
    thumbnailErrors.add(path);
    thumbnailErrors = thumbnailErrors;
  }

  $: parentPath = currentPath && currentPath.includes('/')
    ? currentPath.substring(0, currentPath.lastIndexOf('/'))
    : '';
  $: showParentItem = filterType === 'all' && currentPath !== '' && !searchQuery;

  function getMaterialIcon(item) {
    if (!item) return 'insert_drive_file';
    if (item.is_dir) return 'folder';
    const filename = item.name || item.path || '';
    const ext = filename.includes('.') ? filename.split('.').pop().toLowerCase() : '';

    switch (ext) {
      case 'pdf':
        return 'picture_as_pdf';
      case 'doc':
      case 'docx':
        return 'description';
      case 'xls':
      case 'xlsx':
        return 'table_chart';
      case 'ppt':
      case 'pptx':
        return 'slideshow';
      case 'zip':
      case 'tar':
      case 'gz':
      case '7z':
      case 'rar':
      case 'bz2':
      case 'xz':
        return 'folder_zip';
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'flac':
      case 'm4a':
      case 'aac':
        return 'audiotrack';
      case 'mp4':
      case 'mkv':
      case 'avi':
      case 'mov':
      case 'webm':
      case 'flv':
        return 'movie';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'gif':
      case 'bmp':
      case 'heic':
      case 'avif':
      case 'heif':
        return 'image';
      case 'txt':
      case 'md':
      case 'json':
      case 'yaml':
      case 'yml':
      case 'xml':
      case 'log':
      case 'csv':
      case 'js':
      case 'ts':
      case 'html':
      case 'css':
      case 'dart':
      case 'cpp':
      case 'c':
      case 'h':
      case 'hpp':
      case 'py':
      case 'sh':
        return 'article';
      default:
        if (item.type === 'photo') return 'image';
        if (item.type === 'video') return 'movie';
        if (item.type === 'audio') return 'audiotrack';
        if (item.type === 'archive') return 'folder_zip';
        return 'insert_drive_file';
    }
  }

  function formatSize(bytes) {
    if (bytes === 0) return '0 B';
    if (!bytes || isNaN(bytes) || bytes < 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    const i = Math.min(Math.floor(Math.log(bytes) / Math.log(k)), sizes.length - 1);
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  }

  function formatDate(timestamp) {
    if (!timestamp || isNaN(timestamp)) return '--';
    const d = new Date(timestamp);
    return isNaN(d.getTime()) ? '--' : d.toLocaleDateString();
  }

  function toggleAll() {
    if (selectedItems.size === items.length) {
      dispatch('clearSelection');
    } else {
      dispatch('selectAll', items);
    }
  }

  function handleRowClick(item) {
    if (item.is_parent) {
      dispatch('open', item);
      return;
    }
    if (selectedItems.size > 0) {
      dispatch('select', item);
    } else {
      dispatch('open', item);
    }
  }

  function handleContextMenu(e, item) {
    e.preventDefault();
    e.stopPropagation();
    dispatch('contextmenu', {
      x: e.clientX,
      y: e.clientY,
      item
    });
  }

  function handleMoreClick(e, item) {
    e.stopPropagation();
    const rect = e.currentTarget.getBoundingClientRect();
    dispatch('contextmenu', {
      x: rect.left,
      y: rect.bottom,
      item
    });
  }

  function createDragGhost(count) {
    const ghost = document.createElement('div');
    ghost.className = 'drag-ghost-badge';
    ghost.innerHTML = `<span class="material-symbols-outlined" style="font-size:18px;margin-right:6px;">drive_file_move</span> Moving ${count} item${count > 1 ? 's' : ''}`;
    ghost.style.position = 'absolute';
    ghost.style.top = '-9999px';
    ghost.style.left = '-9999px';
    ghost.style.padding = '8px 16px';
    ghost.style.background = 'var(--accent-color, #fa5252)';
    ghost.style.color = '#ffffff';
    ghost.style.borderRadius = '20px';
    ghost.style.fontWeight = '600';
    ghost.style.fontSize = '13px';
    ghost.style.boxShadow = '0 4px 16px rgba(0,0,0,0.3)';
    ghost.style.display = 'flex';
    ghost.style.alignItems = 'center';
    ghost.style.zIndex = '99999';
    ghost.style.pointerEvents = 'none';
    document.body.appendChild(ghost);
    return ghost;
  }

  function handleItemDragStart(e, item) {
    if (filterType !== 'all' || scope === 'shared') return;
    let pathsToMove = [];
    if (selectedItems.has(item.path) && selectedItems.size > 0) {
      pathsToMove = Array.from(selectedItems);
    } else {
      pathsToMove = [item.path];
    }
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('application/x-crowleys-cloud-move', JSON.stringify({ paths: pathsToMove }));

    if (pathsToMove.length > 1) {
      const ghost = createDragGhost(pathsToMove.length);
      if (e.dataTransfer.setDragImage) {
        e.dataTransfer.setDragImage(ghost, 20, 20);
      }
      setTimeout(() => ghost.remove(), 0);
    }
  }

  function handleFolderDragOver(e, destFolder) {
    if (filterType !== 'all') return;
    if (e.dataTransfer.types && e.dataTransfer.types.includes('application/x-crowleys-cloud-move')) {
      e.preventDefault();
      e.stopPropagation();
      e.dataTransfer.dropEffect = 'move';
      hoveredFolderTarget = destFolder;
    }
  }

  function handleFolderDragLeave(e, destFolder) {
    if (hoveredFolderTarget === destFolder) {
      hoveredFolderTarget = null;
    }
  }

  function handleFolderDrop(e, destFolder) {
    if (filterType !== 'all') return;
    if (e.dataTransfer.types && e.dataTransfer.types.includes('application/x-crowleys-cloud-move')) {
      e.preventDefault();
      e.stopPropagation();
      hoveredFolderTarget = null;
      try {
        const data = JSON.parse(e.dataTransfer.getData('application/x-crowleys-cloud-move'));
        if (data && Array.isArray(data.paths) && data.paths.length > 0) {
          dispatch('moveItems', { paths: data.paths, destFolder });
        }
      } catch (err) {
        console.error('Failed to parse drag data:', err);
      }
    }
  }

  function handleDragEnter(e) {
    if (e.dataTransfer.types && e.dataTransfer.types.includes('application/x-crowleys-cloud-move')) {
      return;
    }
    e.preventDefault();
    dragCounter++;
    isDragOver = true;
  }

  function handleDragOver(e) {
    if (e.dataTransfer.types && e.dataTransfer.types.includes('application/x-crowleys-cloud-move')) {
      return;
    }
    e.preventDefault();
  }

  function handleDragLeave(e) {
    if (e.dataTransfer.types && e.dataTransfer.types.includes('application/x-crowleys-cloud-move')) {
      return;
    }
    e.preventDefault();
    dragCounter--;
    if (dragCounter <= 0) {
      isDragOver = false;
      dragCounter = 0;
    }
  }

  async function traverseEntry(entry, currentPath, results) {
    if (entry.isFile) {
      return new Promise((resolve) => {
        entry.file((file) => {
          const relPath = currentPath ? `${currentPath}/${file.name}` : file.name;
          results.push({ file, path: relPath });
          resolve();
        });
      });
    } else if (entry.isDirectory) {
      const dirReader = entry.createReader();
      const relPath = currentPath ? `${currentPath}/${entry.name}` : entry.name;
      
      const readAll = async () => {
        return new Promise((resolve, reject) => {
          dirReader.readEntries(async (entries) => {
            if (!entries || entries.length === 0) {
              resolve();
              return;
            }
            for (const childEntry of entries) {
              await traverseEntry(childEntry, relPath, results);
            }
            await readAll();
            resolve();
          }, reject);
        });
      };
      await readAll();
    }
  }

  async function handleDrop(e) {
    if (e.dataTransfer.types && e.dataTransfer.types.includes('application/x-crowleys-cloud-move')) {
      e.preventDefault();
      return;
    }
    e.preventDefault();
    isDragOver = false;
    dragCounter = 0;

    const filesToUpload = [];
    const itemsList = e.dataTransfer.items;

    // Synchronously copy items/entries before event loop yields thread
    const entries = [];
    if (itemsList && itemsList.length > 0) {
      for (let i = 0; i < itemsList.length; i++) {
        const item = itemsList[i];
        if (item.kind === 'file') {
          const entry = item.webkitGetAsEntry ? item.webkitGetAsEntry() : null;
          if (entry) {
            entries.push(entry);
          } else {
            const file = item.getAsFile();
            if (file) filesToUpload.push({ file, path: file.name });
          }
        }
      }
    } else if (e.dataTransfer.files) {
      for (let i = 0; i < e.dataTransfer.files.length; i++) {
        const file = e.dataTransfer.files[i];
        filesToUpload.push({ file, path: file.name });
      }
    }

    // Process entries asynchronously
    for (const entry of entries) {
      await traverseEntry(entry, '', filesToUpload);
    }

    if (filesToUpload.length > 0) {
      dispatch('uploadFiles', filesToUpload);
    }
  }
</script>

<!-- svelte-ignore a11y-click-events-have-key-events -->
<!-- svelte-ignore a11y-no-static-element-interactions -->
<div
  class="list-wrapper {isDragOver ? 'drag-active' : ''}"
  on:dragenter={handleDragEnter}
  on:dragover={handleDragOver}
  on:dragleave={handleDragLeave}
  on:drop={handleDrop}
  on:contextmenu={(e) => handleContextMenu(e, null)}
>
  {#if isDragOver}
    <div class="drag-over-overlay">
      <div class="drag-drop-card">
        <span class="material-symbols-outlined drop-icon">cloud_upload</span>
        <h3 class="text-title" style="margin-top: 12px;">Drop files or folders here</h3>
        <p class="text-sub">Items will be queued for upload</p>
      </div>
    </div>
  {/if}

  {#if items.length === 0 && !showParentItem}
    <div class="empty-state">
      <span class="material-symbols-outlined empty-icon">folder_open</span>
      <p class="empty-title text-title">No files found</p>
      <p class="empty-sub text-sub">
        This directory is empty. Drag & drop files here to upload!
      </p>
    </div>
  {:else}
    <!-- Table Header matching Reference 2 -->
    <div class="table-header-row {scope === 'shared' ? 'is-shared-view' : ''}">
      <div class="header-col col-check">
        <label class="custom-checkbox">
          <input
            type="checkbox"
            checked={items.length > 0 && selectedItems.size === items.length}
            on:change={toggleAll}
          />
          <span class="checkbox-indicator"></span>
        </label>
      </div>
      <div class="header-col col-name">Name</div>
      {#if scope === 'shared'}
        <div class="header-col col-owner">Owner</div>
      {/if}
      <div class="header-col col-date">Date Modified</div>
      <div class="header-col col-size">Size</div>
      <div class="header-col col-more"></div>
    </div>

    <div class="list-container">
      {#if showParentItem}
        <div
          class="list-item parent-item {scope === 'shared' ? 'is-shared-view' : ''} {hoveredFolderTarget === parentPath ? 'folder-drop-target' : ''}"
          on:click={() => handleRowClick({ name: '..', path: parentPath, is_dir: true, is_parent: true })}
          on:dragover={(e) => handleFolderDragOver(e, parentPath)}
          on:dragleave={(e) => handleFolderDragLeave(e, parentPath)}
          on:drop={(e) => handleFolderDrop(e, parentPath)}
          title="Go to parent directory"
        >
          <div class="col-check cell-content"></div>
          <div class="col-name cell-content">
            <span
              class="material-symbols-outlined file-type-icon icon-folder"
              style="font-variation-settings: 'FILL' 1;"
            >
              drive_folder_upload
            </span>
            <span class="file-name-text">..</span>
          </div>
          {#if scope === 'shared'}
            <div class="col-owner cell-content text-sub">--</div>
          {/if}
          <div class="col-date cell-content text-sub">--</div>
          <div class="col-size cell-content text-sub">Folder</div>
          <div class="col-more cell-content"></div>
        </div>
      {/if}

      {#each items as item (item.path)}
        <div
          class="list-item {scope === 'shared' ? 'is-shared-view' : ''} {selectedItems.has(item.path) ? 'selected' : ''} {hoveredFolderTarget === item.path ? 'folder-drop-target' : ''}"
          draggable={filterType === 'all'}
          on:dragstart={(e) => handleItemDragStart(e, item)}
          on:dragover={(e) => item.is_dir ? handleFolderDragOver(e, item.path) : null}
          on:dragleave={(e) => item.is_dir ? handleFolderDragLeave(e, item.path) : null}
          on:drop={(e) => item.is_dir ? handleFolderDrop(e, item.path) : null}
          on:click={() => handleRowClick(item)}
          on:contextmenu={(e) => handleContextMenu(e, item)}
          title={item.name}
        >
          <!-- Styled Selection Checkbox -->
          <div class="col-check cell-content" on:click|stopPropagation>
            <label class="custom-checkbox">
              <input
                type="checkbox"
                checked={selectedItems.has(item.path)}
                on:change={() => dispatch('select', item)}
              />
              <span class="checkbox-indicator"></span>
            </label>
          </div>

          <div class="col-name cell-content">
            <div class="list-item-thumbnail">
              {#if (item.type === 'photo' || item.type === 'video') && !thumbnailErrors.has(item.path)}
                <img
                  src={filesApi.getThumbnailUrl({ scope, path: item.path })}
                  alt={item.name}
                  on:error={() => handleThumbnailError(item.path)}
                />
              {:else}
                <span
                  class="material-symbols-outlined file-type-icon {item.is_dir ? 'icon-folder' : ''}"
                  style={item.is_dir ? "font-variation-settings: 'FILL' 1;" : ''}
                >
                  {getMaterialIcon(item)}
                </span>
              {/if}
            </div>
            <span class="file-name-text">{item.name}</span>
          </div>

          {#if scope === 'shared'}
            <div class="col-owner cell-content text-sub">
              <span class="owner-pill">
                <span class="material-symbols-outlined owner-icon">person</span>
                <span class="owner-text">{item.owner_name || (item.uploader_user_id ? `User #${item.uploader_user_id}` : 'Shared')}</span>
              </span>
            </div>
          {/if}

          <div class="col-date cell-content text-sub">{formatDate(item.modified_at)}</div>
          
          <div class="col-size cell-content text-sub">{item.is_dir ? '--' : formatSize(item.size)}</div>

          <!-- Explicit Context Menu Trigger (Three dots) -->
          <div class="col-more cell-content" on:click|stopPropagation>
            <button
              class="btn-icon list-item-more-btn"
              title="More Actions"
              on:click={(e) => handleMoreClick(e, item)}
            >
              <span class="material-symbols-outlined" style="font-size: 20px;">more_vert</span>
            </button>
          </div>
        </div>
      {/each}
    </div>
  {/if}
</div>

<style>
  .list-wrapper {
    position: relative;
    min-height: 100%;
    height: 100%;
    flex: 1;
    display: flex;
    flex-direction: column;
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

  .empty-icon {
    font-size: 56px;
    color: var(--text-sub);
    opacity: 0.5;
    margin-bottom: var(--spacing-md);
  }

  .table-header-row {
    display: grid;
    grid-template-columns: 48px 5fr 3fr 2fr 48px;
    gap: var(--spacing-md);
    padding: 12px 16px;
    border-bottom: 1px solid var(--border-color);
    color: var(--text-sub);
    font-size: 12px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .table-header-row.is-shared-view {
    grid-template-columns: 48px 4fr 2fr 2.5fr 1.5fr 48px;
  }

  .header-col {
    display: flex;
    align-items: center;
  }

  .col-owner {
    justify-content: flex-start;
  }

  .col-date, .col-size {
    justify-content: flex-end;
    text-align: right;
  }

  .list-container {
    display: flex;
    flex-direction: column;
    padding: 8px 16px;
    gap: 4px;
    overflow-y: auto;
    flex: 1;
  }

  .list-item {
    display: grid;
    grid-template-columns: 48px 5fr 3fr 2fr 48px;
    gap: var(--spacing-md);
    padding: 10px 14px;
    border-radius: var(--radius-md);
    cursor: pointer;
    user-select: none;
    transition: background-color 0.1s ease, border-color 0.1s ease;
    border: 1px solid transparent;
    align-items: center;
  }

  .list-item.is-shared-view {
    grid-template-columns: 48px 4fr 2fr 2.5fr 1.5fr 48px;
  }

  .owner-pill {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    padding: 3px 10px;
    border-radius: var(--radius-full);
    background-color: var(--bg-input);
    border: 1px solid var(--border-color);
    font-size: 12px;
    font-weight: 500;
    color: var(--text-main);
    max-width: 140px;
  }

  .owner-icon {
    font-size: 14px;
    color: var(--accent-color);
    flex-shrink: 0;
  }

  .owner-text {
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .list-item:hover {
    background-color: var(--bg-surface-hover);
    border-color: rgba(250, 82, 82, 0.15);
  }

  .list-item.selected {
    background-color: var(--selection-bg);
    border-color: var(--selection-border);
  }

  .list-item.folder-drop-target {
    border-color: var(--accent-color) !important;
    background-color: rgba(250, 82, 82, 0.15) !important;
    box-shadow: 0 0 10px rgba(250, 82, 82, 0.3);
  }

  .cell-content {
    display: flex;
    align-items: center;
    min-width: 0;
  }

  .col-check {
    justify-content: center;
  }

  .col-more {
    justify-content: center;
  }

  .list-item-thumbnail {
    width: 36px;
    height: 36px;
    border-radius: var(--radius-sm);
    overflow: hidden;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    margin-right: 12px;
    background-color: var(--bg-background);
  }

  .list-item-thumbnail img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  /* Custom styled checkboxes in the application theme style */
  .custom-checkbox {
    display: inline-flex;
    align-items: center;
    cursor: pointer;
    position: relative;
  }

  .custom-checkbox input {
    position: absolute;
    opacity: 0;
    cursor: pointer;
    height: 0;
    width: 0;
  }


  .list-item-more-btn {
    width: 32px;
    height: 32px;
    border-radius: var(--radius-full);
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--text-sub);
    transition: background-color 0.15s ease, color 0.15s ease;
  }

  .list-item-more-btn:hover {
    background-color: var(--bg-background);
    color: var(--accent-color);
  }

  .file-type-icon {
    font-size: 24px;
    color: var(--text-sub);
    flex-shrink: 0;
  }

  .file-type-icon.icon-folder {
    color: var(--accent-color);
  }

  .file-name-text {
    font-size: 14px;
    font-weight: 600;
    color: var(--text-main);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .list-item.selected .file-name-text {
    color: var(--accent-color);
  }

  @media (max-width: 768px) {
    .table-header-row, .list-item {
      grid-template-columns: 48px 8fr 48px;
    }
    .col-date, .col-size {
      display: none;
    }
  }
</style>
