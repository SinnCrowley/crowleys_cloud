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
  import { createEventDispatcher, onMount, onDestroy } from 'svelte';
  import { filesApi } from '../api/files.js';
  import { apiGet } from '../api/client.js';
  import { t } from '../stores/i18n.js';

  export let file = null;
  export let items = [];
  export let scope = 'private';
  export let isTrash = false;

  const dispatch = createEventDispatcher();

  let textContent = '';
  let isLoadingText = false;
  let textError = '';
  let copied = false;

  let pdfObjectUrl = '';
  let isLoadingPdf = false;
  let pdfError = '';

  $: activeFileType = getFileType(file);
  $: downloadUrl = file ? filesApi.getDownloadUrl({ scope, path: file.path, trashId: isTrash ? file.id : undefined }) : '';
  $: galleryIndex = items.findIndex((i) => isTrash ? (i.id === file?.id) : (i.path === file?.path));
  $: textLines = textContent ? textContent.split('\n') : [];

  function getFileType(item) {
    if (!item) return 'unsupported';
    if (item.type === 'photo' || isImageExtension(item.name)) return 'image';
    if (item.type === 'video' || isVideoExtension(item.name)) return 'video';
    if (item.type === 'audio' || isAudioExtension(item.name)) return 'audio';
    if (isPdfExtension(item.name)) return 'pdf';
    if (isTextExtension(item.name)) return 'text';
    return 'unsupported';
  }

  function isPdfExtension(filename) {
    return /\.pdf$/i.test(filename || '');
  }

  function isImageExtension(filename) {
    return /\.(jpg|jpeg|png|gif|webp|svg|bmp|ico)$/i.test(filename || '');
  }

  function isVideoExtension(filename) {
    return /\.(mp4|webm|ogg|mov|mkv|avi)$/i.test(filename || '');
  }

  function isAudioExtension(filename) {
    return /\.(mp3|wav|ogg|flac|aac|m4a)$/i.test(filename || '');
  }

  function isTextExtension(filename) {
    return /\.(txt|json|js|jsx|ts|tsx|py|cpp|c|h|hpp|css|html|xml|md|sh|yaml|yml|ini|log|env|dart|svelte)$/i.test(
      filename || ''
    );
  }

  async function loadTextContent() {
    if (!file || activeFileType !== 'text') return;
    isLoadingText = true;
    textError = '';
    textContent = '';

    try {
      const url = filesApi.getDownloadUrl({ scope, path: file.path, trashId: isTrash ? file.id : undefined });
      const blob = await apiGet(url);
      if (blob && blob instanceof Blob) {
        textContent = await blob.text();
      } else if (typeof blob === 'string') {
        textContent = blob;
      } else {
        textContent = JSON.stringify(blob, null, 2);
      }
    } catch (err) {
      textError = err.message || 'Failed to load text content';
    } finally {
      isLoadingText = false;
    }
  }

  async function loadPdfContent() {
    if (!file || activeFileType !== 'pdf') return;
    isLoadingPdf = true;
    pdfError = '';
    if (pdfObjectUrl) {
      URL.revokeObjectURL(pdfObjectUrl);
      pdfObjectUrl = '';
    }

    try {
      const url = filesApi.getDownloadUrl({ scope, path: file.path, trashId: isTrash ? file.id : undefined });
      const blob = await apiGet(url);
      if (blob && blob instanceof Blob) {
        const pdfBlob = new Blob([blob], { type: 'application/pdf' });
        pdfObjectUrl = URL.createObjectURL(pdfBlob);
      } else {
        throw new Error('Failed to load PDF data');
      }
    } catch (err) {
      pdfError = err.message || 'Failed to load PDF preview';
    } finally {
      isLoadingPdf = false;
    }
  }

  $: if (file && activeFileType === 'text') {
    loadTextContent();
  }

  $: if (file && activeFileType === 'pdf') {
    loadPdfContent();
  }

  onMount(() => {
    window.addEventListener('keydown', handleKeyDown);
  });

  onDestroy(() => {
    window.removeEventListener('keydown', handleKeyDown);
    if (pdfObjectUrl) {
      URL.revokeObjectURL(pdfObjectUrl);
    }
  });

  function handleKeyDown(e) {
    if (e.key === 'Escape') {
      dispatch('close');
    } else if (e.key === 'ArrowLeft') {
      handlePrev();
    } else if (e.key === 'ArrowRight') {
      handleNext();
    }
  }

  function handlePrev() {
    if (items.length <= 1) return;
    const prevIdx = galleryIndex > 0 ? galleryIndex - 1 : items.length - 1;
    dispatch('changeItem', items[prevIdx]);
  }

  function handleNext() {
    if (items.length <= 1) return;
    const nextIdx = galleryIndex < items.length - 1 ? galleryIndex + 1 : 0;
    dispatch('changeItem', items[nextIdx]);
  }

  function handleDownload() {
    if (file) {
      filesApi.downloadFile({ scope, path: file.path, trashId: isTrash ? file.id : undefined, filename: file.name });
    }
  }

  async function copyText() {
    try {
      await navigator.clipboard.writeText(textContent);
      copied = true;
      setTimeout(() => (copied = false), 2000);
    } catch (err) {
      console.error('Failed to copy text:', err);
    }
  }

  function formatSize(bytes) {
    if (!bytes || isNaN(bytes)) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.min(Math.floor(Math.log(bytes) / Math.log(k)), sizes.length - 1);
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  }
</script>

{#if file}
  <!-- svelte-ignore a11y-click-events-have-key-events -->
  <!-- svelte-ignore a11y-no-static-element-interactions -->
  <div class="modal-backdrop preview-backdrop" on:click|self={() => dispatch('close')}>
    <div class="preview-container">
      <!-- Top Header Bar -->
      <div class="preview-header">
        <div class="header-file-info">
          <span class="file-title text-title" title={file.name}>{file.name}</span>
          <span class="file-size text-caption">{formatSize(file.size)}</span>
        </div>

        <div class="header-controls">
          {#if activeFileType === 'text'}
            <button class="btn btn-secondary text-body" on:click={copyText}>
              <span class="material-symbols-outlined" style="font-size: 18px; color: {copied ? 'var(--color-success)' : 'inherit'};">{copied ? 'check' : 'content_copy'}</span>
              {copied ? $t('common.copied') : $t('modals.preview.copy_text')}
            </button>
          {/if}

          {#if isTrash}
            <button class="btn btn-secondary text-body" on:click={() => dispatch('restore', file)}>
              <span class="material-symbols-outlined" style="font-size: 18px; color: var(--color-success);">restore</span>
              {$t('common.restore')}
            </button>
            <button class="btn btn-secondary text-body danger-btn" on:click={() => dispatch('delete', file)}>
              <span class="material-symbols-outlined" style="font-size: 18px; color: var(--color-danger);">delete_forever</span>
              {$t('trash.delete_forever')}
            </button>
          {:else}
            <button class="btn btn-secondary text-body" on:click={handleDownload}>
              <span class="material-symbols-outlined" style="font-size: 18px;">download</span>
              {$t('common.download')}
            </button>
          {/if}

          <button class="btn-icon close-btn" on:click={() => dispatch('close')} title={$t('modals.preview.close')}>
            <span class="material-symbols-outlined" style="font-size: 20px;">close</span>
          </button>
        </div>
      </div>

      <!-- Main Stage Content -->
      <div class="preview-stage">
        {#if items.length > 1}
          <button class="nav-arrow left-arrow" on:click={handlePrev} title={$t('modals.preview.prev_file')}>
            <span class="material-symbols-outlined" style="font-size: 32px;">chevron_left</span>
          </button>
        {/if}

        <div class="stage-content">
          {#if activeFileType === 'image'}
            <img src={downloadUrl} alt={file.name} class="preview-image" />
          {:else if activeFileType === 'video'}
            <!-- svelte-ignore a11y-media-has-caption -->
            <video src={downloadUrl} controls autoplay class="preview-video">
              Your browser does not support html5 video playback.
            </video>
          {:else if activeFileType === 'audio'}
            <div class="audio-card">
              <span class="material-symbols-outlined audio-icon">audiotrack</span>
              <h4 class="audio-name text-title">{file.name}</h4>
              <audio src={downloadUrl} controls autoplay class="preview-audio">
                Your browser does not support html5 audio playback.
              </audio>
            </div>
          {:else if activeFileType === 'pdf'}
            {#if isLoadingPdf}
              <div class="loading-text text-sub">{$t('modals.preview.loading_pdf')}</div>
            {:else if pdfError}
              <div class="error-text text-sub">{pdfError}</div>
            {:else if pdfObjectUrl}
              <!-- svelte-ignore a11y-missing-attribute -->
              <iframe src={pdfObjectUrl} title={file.name} class="preview-pdf"></iframe>
            {/if}
          {:else if activeFileType === 'text'}
            <div class="text-viewer-card">
              {#if isLoadingText}
                <div class="loading-text text-sub">{$t('modals.preview.loading_text')}</div>
              {:else if textError}
                <div class="error-text text-sub">{textError}</div>
              {:else}
                <div class="code-container">
                  <div class="line-numbers">
                    {#each textLines as _, i}
                      <span>{i + 1}</span>
                    {/each}
                  </div>
                  <pre class="code-body text-code"><code>{textContent}</code></pre>
                </div>
              {/if}
            </div>
          {:else}
            <div class="unsupported-card">
              <span class="material-symbols-outlined unsupported-icon">description</span>
              <h3 class="text-title">{$t('modals.preview.preview_not_available')}</h3>
              <p class="text-sub">
                {$t('modals.preview.preview_not_available_sub')}
              </p>
              <button class="btn btn-primary" on:click={handleDownload}>
                <span class="material-symbols-outlined" style="font-size: 18px;">download</span>
                {$t('modals.preview.download_file', { size: formatSize(file.size) })}
              </button>
            </div>
          {/if}
        </div>

        {#if items.length > 1}
          <button class="nav-arrow right-arrow" on:click={handleNext} title={$t('modals.preview.next_file')}>
            <span class="material-symbols-outlined" style="font-size: 32px;">chevron_right</span>
          </button>
        {/if}
      </div>
    </div>
  </div>
{/if}

<style>
  .preview-backdrop {
    background-color: rgba(0, 0, 0, 0.85);
    backdrop-filter: blur(8px);
    z-index: 1200;
  }

  .preview-container {
    width: 92vw;
    height: 92vh;
    display: flex;
    flex-direction: column;
    background-color: var(--bg-surface);
    border-radius: var(--radius-xl);
    border: 1px solid var(--border-color);
    box-shadow: var(--shadow-card);
    overflow: hidden;
  }

  .preview-header {
    height: 64px;
    padding: 0 var(--spacing-lg);
    display: flex;
    align-items: center;
    justify-content: space-between;
    border-bottom: 1px solid var(--border-color);
    background-color: var(--bg-surface);
  }

  .header-file-info {
    display: flex;
    align-items: baseline;
    gap: var(--spacing-md);
    overflow: hidden;
  }

  .file-title {
    color: var(--text-main);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .header-controls {
    display: flex;
    align-items: center;
    gap: var(--spacing-md);
  }

  .close-btn {
    font-size: 18px;
  }

  .preview-stage {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: space-between;
    position: relative;
    overflow: hidden;
    background-color: var(--bg-background);
  }

  .stage-content {
    flex: 1;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: var(--spacing-md);
    overflow: hidden;
  }

  .preview-image {
    max-width: 100%;
    max-height: 100%;
    object-fit: contain;
    border-radius: var(--radius-md);
    box-shadow: var(--shadow-card);
  }

  .preview-video {
    max-width: 100%;
    max-height: 100%;
    border-radius: var(--radius-md);
    outline: none;
  }

  .preview-pdf {
    width: 100%;
    height: 100%;
    border: none;
    border-radius: var(--radius-lg);
    background-color: #ffffff;
  }

  .audio-card {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: var(--spacing-lg);
    background-color: var(--bg-surface);
    padding: 48px;
    border-radius: var(--radius-xl);
    border: 1px solid var(--border-color);
    box-shadow: var(--shadow-card);
    min-width: 320px;
    text-align: center;
  }

  .audio-icon {
    font-size: 64px;
    color: var(--accent-color);
  }

  .preview-audio {
    width: 100%;
    min-width: 280px;
  }

  .text-viewer-card {
    width: 100%;
    height: 100%;
    background-color: var(--bg-surface);
    border-radius: var(--radius-lg);
    border: 1px solid var(--border-color);
    overflow: hidden;
    display: flex;
    flex-direction: column;
  }

  .code-container {
    display: flex;
    flex: 1;
    overflow: auto;
    font-family: var(--font-mono);
    position: relative;
    width: 100%;
    height: 100%;
  }

  .line-numbers {
    position: sticky;
    left: 0;
    z-index: 2;
    padding: var(--spacing-md) var(--spacing-sm);
    background-color: var(--bg-input);
    border-right: 1px solid var(--border-color);
    color: var(--text-sub);
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    user-select: none;
    font-size: calc(13px * var(--font-scale));
    line-height: 1.5;
    flex-shrink: 0;
    min-width: 44px;
    height: fit-content;
    min-height: 100%;
  }

  .code-body {
    margin: 0;
    padding: var(--spacing-md);
    flex: 1;
    overflow: visible;
    color: var(--text-main);
    line-height: 1.5;
    font-size: calc(13px * var(--font-scale));
    min-width: max-content;
    height: fit-content;
    min-height: 100%;
  }

  .unsupported-card {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: var(--spacing-md);
    text-align: center;
    background-color: var(--bg-surface);
    padding: 48px;
    border-radius: var(--radius-xl);
    border: 1px solid var(--border-color);
  }

  .unsupported-icon {
    font-size: 64px;
    opacity: 0.8;
    color: var(--text-sub);
  }

  .nav-arrow {
    background: rgba(0, 0, 0, 0.4);
    color: #ffffff;
    border: none;
    font-size: 36px;
    width: 48px;
    height: 80px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    z-index: 10;
    transition: background-color 0.15s ease;
  }

  .nav-arrow:hover {
    background: rgba(0, 0, 0, 0.7);
  }

  .left-arrow {
    border-radius: 0 var(--radius-lg) var(--radius-lg) 0;
  }

  .right-arrow {
    border-radius: var(--radius-lg) 0 0 var(--radius-lg);
  }

  .loading-text,
  .error-text {
    padding: 32px;
    text-align: center;
  }
</style>
