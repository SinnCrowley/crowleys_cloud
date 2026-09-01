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
  import { filesApi } from '../api/files.js';
  import { t, i18n } from '../stores/i18n.js';
  import SmartThumbnail from './SmartThumbnail.svelte';

  export let items = [];
  export let selectedItems = new Set();
  export let scope = 'private';
  export let filterType = 'all';
  export let currentPath = '';
  export let searchQuery = '';

  const dispatch = createEventDispatcher();

  let isDragOver = false;
  let dragCounter = 0;
  let justLongPressed = false;
  let hoveredFolderTarget = null;

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

  function handleItemClick(item) {
    if (justLongPressed) {
      justLongPressed = false;
      return;
    }
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

  function longpress(node, threshold = 500) {
    let timer = null;
    let startX = 0;
    let startY = 0;
    let didLongPress = false;

    const handleStart = (e) => {
      if (e.type === 'mousedown' && e.button !== 0) return;
      const point = e.touches ? e.touches[0] : e;
      startX = point.clientX;
      startY = point.clientY;
      didLongPress = false;

      clearTimeout(timer);
      timer = setTimeout(() => {
        didLongPress = true;
        justLongPressed = true;
        node.dispatchEvent(new CustomEvent('longpress'));
      }, threshold);
    };

    const handleMove = (e) => {
      if (!timer) return;
      const point = e.touches ? e.touches[0] : e;
      const diffX = Math.abs(point.clientX - startX);
      const diffY = Math.abs(point.clientY - startY);
      if (diffX > 10 || diffY > 10) {
        clearTimeout(timer);
        timer = null;
      }
    };

    const handleEnd = () => {
      clearTimeout(timer);
      timer = null;
    };

    const handleClickCapture = (e) => {
      if (didLongPress || justLongPressed) {
        e.preventDefault();
        e.stopPropagation();
        e.stopImmediatePropagation();
        justLongPressed = false;
        didLongPress = false;
      }
    };

    node.addEventListener('mousedown', handleStart);
    node.addEventListener('touchstart', handleStart, { passive: true });
    node.addEventListener('mousemove', handleMove);
    node.addEventListener('touchmove', handleMove, { passive: true });
    node.addEventListener('mouseup', handleEnd);
    node.addEventListener('mouseleave', handleEnd);
    node.addEventListener('touchend', handleEnd);
    node.addEventListener('touchcancel', handleEnd);
    node.addEventListener('click', handleClickCapture, { capture: true });

    return {
      destroy() {
        clearTimeout(timer);
        node.removeEventListener('mousedown', handleStart);
        node.removeEventListener('touchstart', handleStart);
        node.removeEventListener('mousemove', handleMove);
        node.removeEventListener('touchmove', handleMove);
        node.removeEventListener('mouseup', handleEnd);
        node.removeEventListener('mouseleave', handleEnd);
        node.removeEventListener('touchend', handleEnd);
        node.removeEventListener('touchcancel', handleEnd);
        node.removeEventListener('click', handleClickCapture, { capture: true });
      }
    };
  }

  function handleLongPress(item) {
    if (navigator.vibrate) navigator.vibrate(40);
    dispatch('select', item);
  }

  function createDragGhost(count) {
    const ghost = document.createElement('div');
    ghost.className = 'drag-ghost-badge';
    ghost.innerHTML = `<span class="material-symbols-outlined" style="font-size: 18px;">drive_file_move</span><span>${i18n.format('common.items', { count })}</span>`;
    ghost.style.position = 'absolute';
    ghost.style.top = '-1000px';
    ghost.style.left = '-1000px';
    ghost.style.backgroundColor = 'var(--accent-color, #FA5252)';
    ghost.style.color = '#FFFFFF';
    ghost.style.padding = '6px 14px';
    ghost.style.borderRadius = '20px';
    ghost.style.fontWeight = '600';
    ghost.style.fontSize = '13px';
    ghost.style.boxShadow = '0 8px 24px rgba(0,0,0,0.3)';
    ghost.style.display = 'flex';
    ghost.style.alignItems = 'center';
    ghost.style.gap = '6px';
    ghost.style.zIndex = '9999';
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
  class="grid-wrapper {isDragOver ? 'drag-active' : ''}"
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
        <h3 class="text-title" style="margin-top: 12px;">{$t('files.drop_to_upload')}</h3>
        <p class="text-sub">{$t('files.drop_to_upload_sub')}</p>
      </div>
    </div>
  {/if}

  {#if items.length === 0 && !showParentItem}
    <div class="empty-state">
      <span class="material-symbols-outlined empty-icon">folder_open</span>
      <p class="empty-title text-title">{searchQuery ? $t('files.no_results_title') : $t('files.empty_title')}</p>
      <p class="empty-sub text-sub">
        {searchQuery ? $t('files.no_results_sub', { query: searchQuery }) : $t('files.empty_sub')}
      </p>
    </div>
  {:else}
    <div class="grid-container">
      {#if showParentItem}
        <div
          class="grid-item parent-item {hoveredFolderTarget === parentPath ? 'folder-drop-target' : ''}"
          on:click|stopPropagation={() => handleItemClick({ name: '..', path: parentPath, is_dir: true, is_parent: true })}
          on:dragover={(e) => handleFolderDragOver(e, parentPath)}
          on:dragleave={(e) => handleFolderDragLeave(e, parentPath)}
          on:drop={(e) => handleFolderDrop(e, parentPath)}
          title={$t('files.home_root')}
        >
          <div class="grid-item-thumbnail">
            <span
              class="material-symbols-outlined grid-item-icon icon-folder"
              style="font-variation-settings: 'FILL' 1;"
            >
              drive_folder_upload
            </span>
          </div>
          
          <div class="grid-item-info">
            <div class="grid-item-name">..</div>
            <div class="grid-item-meta-row">
              <span class="grid-item-meta">{$t('common.folder')}</span>
            </div>
          </div>
        </div>
      {/if}

      {#each items as item (item.path)}
        <div
          class="grid-item {selectedItems.has(item.path) ? 'selected' : ''} {hoveredFolderTarget === item.path ? 'folder-drop-target' : ''}"
          draggable={filterType === 'all'}
          on:dragstart={(e) => handleItemDragStart(e, item)}
          on:dragover={(e) => item.is_dir ? handleFolderDragOver(e, item.path) : null}
          on:dragleave={(e) => item.is_dir ? handleFolderDragLeave(e, item.path) : null}
          on:drop={(e) => item.is_dir ? handleFolderDrop(e, item.path) : null}
          use:longpress
          on:longpress={() => handleLongPress(item)}
          on:click|stopPropagation={() => handleItemClick(item)}
          on:contextmenu={(e) => handleContextMenu(e, item)}
          title={item.name}
        >
          <div class="grid-item-thumbnail">
            <SmartThumbnail {item} {scope} viewMode="grid" size={256} />
          </div>
          
          <div class="grid-item-info">
            <div class="grid-item-name">{item.name}</div>
            <div class="grid-item-meta-row">
              <span class="grid-item-meta">{item.is_dir ? $t('common.folder') : formatSize(item.size)}</span>
              {#if scope === 'shared' && (item.owner_name || item.uploader_user_id)}
                <span class="grid-owner-tag" title="{$t('common.owner')}: {item.owner_name || `${$t('nav.user')} #${item.uploader_user_id}`}">
                  <span class="material-symbols-outlined" style="font-size: 11px; margin-right: 2px;">person</span>
                  {item.owner_name || `${$t('nav.user')} #${item.uploader_user_id}`}
                </span>
              {/if}
              
              <!-- More Options Menu Button in Bottom Right Corner -->
              <button
                class="btn-icon grid-item-more-btn"
                title={$t('common.actions')}
                on:click={(e) => handleMoreClick(e, item)}
              >
                <span class="material-symbols-outlined" style="font-size: 16px;">more_vert</span>
              </button>
            </div>
          </div>
        </div>
      {/each}
    </div>
  {/if}
</div>

<style>
  .grid-wrapper {
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

  .grid-container {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    gap: 16px;
    padding: 16px;
    overflow-y: auto;
    flex: 1;
    align-content: start;
  }

  .grid-item {
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
    position: relative;
  }

  .grid-item:hover {
    background-color: var(--bg-surface-hover);
    border-color: rgba(250, 82, 82, 0.15);
  }

  .grid-item.selected {
    background-color: var(--selection-bg);
    border-color: var(--selection-border);
  }

  .grid-item.folder-drop-target {
    border-color: var(--accent-color) !important;
    background-color: rgba(250, 82, 82, 0.15) !important;
    transform: scale(1.02);
    box-shadow: 0 0 12px rgba(250, 82, 82, 0.4);
  }

  .grid-item-thumbnail {
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
    position: relative;
  }

  .grid-item-icon {
    font-size: 52px;
    color: var(--text-sub);
  }

  .grid-item-icon.icon-folder {
    color: var(--accent-color);
  }

  .grid-item-info {
    width: 100%;
  }

  .grid-item-name {
    font-size: 14px;
    font-weight: 600;
    color: var(--text-main);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    width: 100%;
    text-align: left;
  }

  .grid-item.selected .grid-item-name {
    color: var(--accent-color);
  }

  .grid-item-meta-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    width: 100%;
    margin-top: 4px;
    height: 24px;
  }

  .grid-item-meta {
    font-size: 11px;
    color: var(--text-sub);
  }

  .grid-owner-tag {
    display: inline-flex;
    align-items: center;
    font-size: 11px;
    font-weight: 500;
    color: var(--accent-color);
    background-color: var(--bg-input);
    border: 1px solid var(--border-color);
    padding: 1px 6px;
    border-radius: var(--radius-full);
    max-width: 90px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .grid-item-more-btn {
    width: 24px;
    height: 24px;
    border-radius: var(--radius-full);
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--text-sub);
    transition: background-color 0.15s ease, color 0.15s ease;
  }

  .grid-item-more-btn:hover {
    background-color: var(--bg-background);
    color: var(--accent-color);
  }
</style>
