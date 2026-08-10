<script>
  import { onMount, createEventDispatcher } from 'svelte';
  import { filesApi } from '../api/files.js';

  const dispatch = createEventDispatcher();

  let stats = {
    totalCount: 0,
    totalSize: 0,
    photoCount: 0,
    photoSize: 0,
    videoCount: 0,
    videoSize: 0,
    audioCount: 0,
    audioSize: 0,
    documentCount: 0,
    documentSize: 0,
    sharedCount: 0,
    sharedSize: 0,
    otherCount: 0,
    otherSize: 0
  };

  let isLoading = true;
  let isDragActive = false;
  let dragCounter = 0;

  onMount(async () => {
    await loadStats();
  });

  async function loadStats() {
    isLoading = true;
    try {
      const res = await filesApi.listDir({ scope: 'private', path: '', type: 'all' });
      const entries = res.entries || [];
      
      let totalCount = 0;
      let totalSize = 0;
      let photoCount = 0;
      let photoSize = 0;
      let videoCount = 0;
      let videoSize = 0;
      let audioCount = 0;
      let audioSize = 0;
      let documentCount = 0;
      let documentSize = 0;
      let otherCount = 0;
      let otherSize = 0;

      entries.forEach((item) => {
        if (!item.is_dir) {
          totalCount++;
          totalSize += item.size || 0;
          
          if (item.type === 'photo' || item.name.match(/\.(jpg|jpeg|png|gif|webp|svg)$/i)) {
            photoCount++;
            photoSize += item.size || 0;
          } else if (item.type === 'video' || item.name.match(/\.(mp4|mkv|mov|avi|webm)$/i)) {
            videoCount++;
            videoSize += item.size || 0;
          } else if (item.type === 'audio' || item.name.match(/\.(mp3|wav|flac|ogg|m4a)$/i)) {
            audioCount++;
            audioSize += item.size || 0;
          } else if (item.type === 'document' || item.name.match(/\.(pdf|doc|docx|xls|xlsx|ppt|pptx|txt|md)$/i)) {
            documentCount++;
            documentSize += item.size || 0;
          } else {
            otherCount++;
            otherSize += item.size || 0;
          }
        } else {
          totalCount++; // count folders too
        }
      });

      let sharedCount = 0;
      let sharedSize = 0;
      try {
        const sharedRes = await filesApi.listDir({ scope: 'shared', path: '', type: 'all' });
        const sharedEntries = sharedRes.entries || [];
        sharedEntries.forEach((item) => {
          if (!item.is_dir) {
            sharedCount++;
            sharedSize += item.size || 0;
          }
        });
      } catch (e) {
        console.warn('Failed to load shared stats:', e);
      }

      stats = {
        totalCount,
        totalSize,
        photoCount,
        photoSize,
        videoCount,
        videoSize,
        audioCount,
        audioSize,
        documentCount,
        documentSize,
        sharedCount,
        sharedSize,
        otherCount,
        otherSize
      };
    } catch (err) {
      console.error('Failed to load stats for dashboard:', err);
    } finally {
      isLoading = false;
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

  function handleNavigate(filterType = 'all', scope = 'private') {
    dispatch('navigate', { route: 'files', filterType, scope });
  }

  function handleDragEnter(e) {
    e.preventDefault();
    dragCounter++;
    isDragActive = true;
  }

  function handleDragOver(e) {
    e.preventDefault();
  }

  function handleDragLeave(e) {
    e.preventDefault();
    dragCounter--;
    if (dragCounter <= 0) {
      isDragActive = false;
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
    e.preventDefault();
    isDragActive = false;
    dragCounter = 0;

    const filesToUpload = [];
    const itemsList = e.dataTransfer.items;
    
    // Synchronously capture entries/files before event loop yields thread
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
  class="dashboard-wrapper {isDragActive ? 'drag-active' : ''}"
  on:dragenter={handleDragEnter}
  on:dragover={handleDragOver}
  on:dragleave={handleDragLeave}
  on:drop={handleDrop}
>
  {#if isDragActive}
    <div class="drag-over-overlay">
      <div class="drag-drop-card">
        <span class="material-symbols-outlined drop-icon">cloud_upload</span>
        <h3 class="text-title" style="margin-top: 12px;">Drop files to upload</h3>
        <p class="text-sub">Items will be queued for upload to root directory</p>
      </div>
    </div>
  {/if}

  <div class="canvas-header">
    <div class="canvas-header-info">
      <h2>Dashboard</h2>
      <p>Overview of your central file repository.</p>
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
        <button class="bento-card-action">
          <span class="material-symbols-outlined">more_vert</span>
        </button>
      </div>
      <div>
        <h3 class="bento-card-title">All Files</h3>
        <div class="bento-card-info">
          <span>{stats.totalCount} items</span>
          <span>•</span>
          <span>Last modified recently</span>
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
        <h3 class="bento-card-title">Photos</h3>
        <div class="bento-card-info">{stats.photoCount} items ({formatSize(stats.photoSize)})</div>
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
        <h3 class="bento-card-title">Videos</h3>
        <div class="bento-card-info">{stats.videoCount} items ({formatSize(stats.videoSize)})</div>
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
        <h3 class="bento-card-title">Audio</h3>
        <div class="bento-card-info">{stats.audioCount} items ({formatSize(stats.audioSize)})</div>
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
        <h3 class="bento-card-title">Documents</h3>
        <div class="bento-card-info">{stats.documentCount} items ({formatSize(stats.documentSize)})</div>
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
        <h3 class="bento-card-title">Shared with me</h3>
        <div class="bento-card-info">{stats.sharedCount} items ({formatSize(stats.sharedSize)})</div>
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
        <h3 class="bento-card-title">Other</h3>
        <div class="bento-card-info">{stats.otherCount} items ({formatSize(stats.otherSize)})</div>
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
</style>
