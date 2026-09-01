<!-- Copyright (C) 2026 Sinn Crowley
     AGPL-3.0-or-later -->

<script>
  import { onMount, onDestroy } from 'svelte';
  import { filesApi } from '../api/files.js';
  import BlurHashCanvas from './BlurHashCanvas.svelte';

  export let item = null;
  export let scope = 'private';
  export let trashId = undefined;
  export let size = 256;
  export let viewMode = 'grid'; // 'grid' | 'list'

  let isLoaded = false;
  let hasError = false;
  let retryCount = 0;
  let retryTimer = null;
  let imageUrl = '';
  let activeKey = '';

  const MAX_RETRIES = 5;
  const RETRY_DELAYS = [600, 1200, 2000, 3000, 4000];

  function isImageExt(filename) {
    return /\.(jpg|jpeg|png|gif|webp|bmp|heic|heif|avif|svg|ico)$/i.test(filename || '');
  }

  function isVideoExt(filename) {
    return /\.(mp4|mkv|avi|mov|webm|flv|wmv|m4v|3gp)$/i.test(filename || '');
  }

  $: isMedia = item && !item.is_dir && (
    item.type === 'photo' || 
    item.type === 'video' || 
    isImageExt(item.name || item.path) || 
    isVideoExt(item.name || item.path)
  );

  $: currentKey = item ? `${scope}:${trashId || item.id || ''}:${item.path || ''}:${item.modified_at || item.deleted_at || ''}` : '';

  $: if (currentKey !== activeKey) {
    activeKey = currentKey;
    resetState();
  }

  function getBaseUrl() {
    if (!item) return '';
    const tid = trashId || (scope === 'trash' ? item.id : undefined);
    return filesApi.getThumbnailUrl({
      scope: scope === 'trash' ? 'private' : scope,
      path: item.path,
      trashId: tid,
      size
    });
  }

  function resetState() {
    clearTimeout(retryTimer);
    retryTimer = null;
    isLoaded = false;
    hasError = false;
    retryCount = 0;
    if (isMedia) {
      imageUrl = getBaseUrl();
    } else {
      imageUrl = '';
    }
  }

  function handleLoad() {
    clearTimeout(retryTimer);
    retryTimer = null;
    isLoaded = true;
    hasError = false;
  }

  async function handleError() {
    if (!isMedia || hasError) return;

    if (retryCount < MAX_RETRIES) {
      const delay = RETRY_DELAYS[retryCount] || 2000;
      retryCount++;

      clearTimeout(retryTimer);
      retryTimer = setTimeout(async () => {
        try {
          const baseUrl = getBaseUrl();
          if (!baseUrl) return;

          const res = await fetch(baseUrl, { method: 'GET' });
          if (res.status === 200) {
            // Thumbnail is ready! Force reload image
            imageUrl = `${baseUrl}${baseUrl.includes('?') ? '&' : '?'}_t=${Date.now()}`;
          } else if (res.status === 202) {
            // Server still generating in background queue, continue polling
            handleError();
          } else {
            hasError = true;
          }
        } catch (err) {
          handleError();
        }
      }, delay);
    } else {
      hasError = true;
    }
  }

  function getMaterialIcon(itm) {
    if (!itm) return 'insert_drive_file';
    if (itm.is_dir) return 'folder';
    const filename = itm.name || itm.path || '';
    const ext = filename.includes('.') ? filename.split('.').pop().toLowerCase() : '';

    switch (ext) {
      case 'pdf': return 'picture_as_pdf';
      case 'doc':
      case 'docx': return 'description';
      case 'xls':
      case 'xlsx': return 'table_chart';
      case 'ppt':
      case 'pptx': return 'slideshow';
      case 'zip':
      case 'tar':
      case 'gz':
      case '7z':
      case 'rar':
      case 'bz2':
      case 'xz': return 'folder_zip';
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'flac':
      case 'm4a':
      case 'aac': return 'audiotrack';
      case 'mp4':
      case 'mkv':
      case 'avi':
      case 'mov':
      case 'webm':
      case 'flv': return 'movie';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'gif':
      case 'bmp':
      case 'heic':
      case 'avif':
      case 'heif': return 'image';
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
      case 'sh': return 'article';
      default:
        if (itm.type === 'photo') return 'image';
        if (itm.type === 'video') return 'movie';
        if (itm.type === 'audio') return 'audiotrack';
        if (itm.type === 'archive') return 'folder_zip';
        return 'insert_drive_file';
    }
  }

  onDestroy(() => {
    clearTimeout(retryTimer);
  });
</script>

<div class="smart-thumbnail-root {viewMode}">
  {#if isMedia && !hasError}
    <div class="thumbnail-wrapper">
      {#if item.blurhash}
        <BlurHashCanvas blurhash={item.blurhash} />
      {:else}
        <div class="placeholder-fallback" class:hidden={isLoaded}>
          <span class="material-symbols-outlined placeholder-icon">
            {item.type === 'video' || isVideoExt(item.name) ? 'movie' : 'image'}
          </span>
          <div class="shimmer-wave"></div>
        </div>
      {/if}

      {#if imageUrl}
        <img
          src={imageUrl}
          alt={item.name || ''}
          loading="lazy"
          decoding="async"
          class="thumbnail-img"
          class:loaded={isLoaded}
          on:load={handleLoad}
          on:error={handleError}
        />
      {/if}
    </div>
  {:else}
    <span
      class="material-symbols-outlined fallback-icon {item && item.is_dir ? 'icon-folder' : ''}"
      style={item && item.is_dir ? "font-variation-settings: 'FILL' 1;" : ''}
    >
      {getMaterialIcon(item)}
    </span>
  {/if}
</div>

<style>
  .smart-thumbnail-root {
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    position: relative;
    overflow: hidden;
  }

  .thumbnail-wrapper {
    position: relative;
    width: 100%;
    height: 100%;
    overflow: hidden;
    border-radius: inherit;
    background-color: var(--bg-surface, rgba(255, 255, 255, 0.04));
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .placeholder-fallback {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, rgba(255, 255, 255, 0.03) 0%, rgba(255, 255, 255, 0.07) 100%);
    overflow: hidden;
    pointer-events: none;
    transition: opacity 0.3s ease-out;
  }

  .placeholder-fallback.hidden {
    opacity: 0;
  }

  .placeholder-icon {
    font-size: 28px;
    color: var(--text-sub, rgba(255, 255, 255, 0.3));
    opacity: 0.35;
  }

  :global(.grid-item-thumbnail) .placeholder-icon {
    font-size: 40px;
  }

  .shimmer-wave {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: linear-gradient(
      90deg,
      transparent 0%,
      rgba(255, 255, 255, 0.05) 50%,
      transparent 100%
    );
    background-size: 200% 100%;
    animation: shimmer 1.8s infinite;
  }

  @keyframes shimmer {
    0% { background-position: -200% 0; }
    100% { background-position: 200% 0; }
  }

  .thumbnail-img {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    object-fit: cover;
    opacity: 0;
    transition: opacity 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    z-index: 1;
  }

  .thumbnail-img.loaded {
    opacity: 1;
  }

  .fallback-icon {
    color: var(--text-sub);
    user-select: none;
  }

  .smart-thumbnail-root.grid .fallback-icon {
    font-size: 52px;
  }

  .smart-thumbnail-root.list .fallback-icon {
    font-size: 24px;
  }

  .fallback-icon.icon-folder {
    color: var(--accent-color);
  }
</style>
