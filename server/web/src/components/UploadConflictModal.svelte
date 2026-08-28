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

  export let conflicts = [];
  export let nonConflicts = [];

  const dispatch = createEventDispatcher();

  let currentIndex = 0;
  let applyToAll = false;
  let confirmedUploads = [...nonConflicts];
  let skippedUploads = [];

  $: currentConflict = conflicts[currentIndex] || null;
  $: totalConflicts = conflicts.length;
  $: isMultiConflict = totalConflicts > 1;

  function formatSize(bytes) {
    if (bytes === 0) return '0 B';
    if (!bytes || isNaN(bytes) || bytes < 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    const i = Math.min(Math.floor(Math.log(bytes) / Math.log(k)), sizes.length - 1);
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  }

  function formatDate(timestamp) {
    if (!timestamp) return $t('common.not_available');
    const date = new Date(typeof timestamp === 'number' && timestamp < 1e12 ? timestamp * 1000 : timestamp);
    return date.toLocaleDateString(undefined, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  }

  function finish() {
    dispatch('resolve', {
      confirmed: confirmedUploads,
      skipped: skippedUploads
    });
  }

  function handleOverwrite() {
    if (!currentConflict) return;

    if (applyToAll) {
      for (let i = currentIndex; i < conflicts.length; i++) {
        confirmedUploads.push({
          file: conflicts[i].file,
          path: conflicts[i].path
        });
      }
      finish();
      return;
    }

    confirmedUploads.push({
      file: currentConflict.file,
      path: currentConflict.path
    });

    if (currentIndex + 1 < conflicts.length) {
      currentIndex++;
    } else {
      finish();
    }
  }

  function handleSkip() {
    if (!currentConflict) return;

    if (applyToAll) {
      for (let i = currentIndex; i < conflicts.length; i++) {
        skippedUploads.push(conflicts[i]);
      }
      finish();
      return;
    }

    skippedUploads.push(currentConflict);

    if (currentIndex + 1 < conflicts.length) {
      currentIndex++;
    } else {
      finish();
    }
  }

  function handleOverwriteAll() {
    for (let i = currentIndex; i < conflicts.length; i++) {
      confirmedUploads.push({
        file: conflicts[i].file,
        path: conflicts[i].path
      });
    }
    finish();
  }

  function handleSkipAll() {
    for (let i = currentIndex; i < conflicts.length; i++) {
      skippedUploads.push(conflicts[i]);
    }
    finish();
  }

  function handleClose() {
    dispatch('close');
  }
</script>

<!-- svelte-ignore a11y-click-events-have-key-events -->
<!-- svelte-ignore a11y-no-static-element-interactions -->
<div class="modal-backdrop" on:click|self={handleClose}>
  <div class="conflict-modal-card">
    <div class="conflict-header">
      <div class="conflict-title-area">
        <span class="material-symbols-outlined conflict-icon">warning</span>
        <div>
          <h3 class="text-title" style="margin: 0;">{$t('modals.conflict.upload_title')}</h3>
          {#if isMultiConflict}
            <span class="conflict-counter text-caption">{$t('modals.conflict.upload_subtitle', { count: totalConflicts })}</span>
          {/if}
        </div>
      </div>
      <button class="btn-icon" on:click={handleClose} title={$t('common.cancel')}>
        <span class="material-symbols-outlined" style="font-size: 20px;">close</span>
      </button>
    </div>

    {#if currentConflict}
      <p class="conflict-description text-body">
        <strong class="file-highlight">{currentConflict.name}</strong>
      </p>

      <div class="file-comparison-grid">
        <!-- Existing File -->
        <div class="comparison-card existing">
          <div class="comparison-header">
            <span class="material-symbols-outlined comp-icon">history</span>
            <span class="text-caption font-bold">{$t('modals.conflict.existing_file', { size: formatSize(currentConflict.existing.size) })}</span>
          </div>
          <div class="comparison-details">
            <div class="detail-row">
              <span class="text-caption text-sub">{$t('common.size')}:</span>
              <span class="text-caption font-medium">{formatSize(currentConflict.existing.size)}</span>
            </div>
            {#if currentConflict.existing.modified_at || currentConflict.existing.created_at}
              <div class="detail-row">
                <span class="text-caption text-sub">{$t('common.date')}:</span>
                <span class="text-caption font-medium">{formatDate(currentConflict.existing.modified_at || currentConflict.existing.created_at)}</span>
              </div>
            {/if}
          </div>
        </div>

        <!-- Arrow -->
        <div class="comparison-arrow">
          <span class="material-symbols-outlined">arrow_forward</span>
        </div>

        <!-- New File -->
        <div class="comparison-card incoming">
          <div class="comparison-header">
            <span class="material-symbols-outlined comp-icon">upload_file</span>
            <span class="text-caption font-bold">{$t('modals.conflict.new_file', { size: formatSize(currentConflict.size) })}</span>
          </div>
          <div class="comparison-details">
            <div class="detail-row">
              <span class="text-caption text-sub">{$t('common.size')}:</span>
              <span class="text-caption font-medium">{formatSize(currentConflict.size)}</span>
            </div>
            {#if currentConflict.file && currentConflict.file.lastModified}
              <div class="detail-row">
                <span class="text-caption text-sub">{$t('common.date')}:</span>
                <span class="text-caption font-medium">{formatDate(currentConflict.file.lastModified)}</span>
              </div>
            {/if}
          </div>
        </div>
      </div>

      {#if isMultiConflict}
        <label class="apply-all-checkbox text-body">
          <input type="checkbox" bind:checked={applyToAll} />
          <span>{$t('modals.conflict.overwrite_all')} ({totalConflicts - currentIndex})</span>
        </label>
      {/if}
    {/if}

    <div class="conflict-actions">
      {#if isMultiConflict}
        <div class="batch-quick-actions">
          <button class="btn btn-secondary btn-sm" on:click={handleSkipAll}>{$t('modals.conflict.skip_all')}</button>
          <button class="btn btn-secondary btn-sm" on:click={handleOverwriteAll}>{$t('modals.conflict.overwrite_all')}</button>
        </div>
      {/if}
      <div class="primary-choice-actions">
        <button class="btn btn-secondary" on:click={handleSkip}>
          {$t('modals.conflict.skip')}
        </button>
        <button class="btn btn-primary" on:click={handleOverwrite}>
          {$t('modals.conflict.overwrite')}
        </button>
      </div>
    </div>
  </div>
</div>

<style>
  .conflict-modal-card {
    width: 100%;
    max-width: 520px;
    background-color: var(--bg-surface);
    border-radius: var(--radius-xl);
    border: 1px solid var(--border-color);
    box-shadow: var(--shadow-card);
    padding: var(--spacing-xl);
    display: flex;
    flex-direction: column;
    gap: var(--spacing-md);
    animation: modalIn 0.15s ease-out;
  }

  @keyframes modalIn {
    from {
      opacity: 0;
      transform: scale(0.96);
    }
    to {
      opacity: 1;
      transform: scale(1);
    }
  }

  .conflict-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .conflict-title-area {
    display: flex;
    align-items: center;
    gap: var(--spacing-sm);
  }

  .conflict-icon {
    color: #F59E0B;
    font-size: 28px;
  }

  .conflict-counter {
    color: var(--text-muted);
    font-size: 12px;
  }

  .conflict-description {
    color: var(--text-secondary);
    line-height: 1.5;
    margin: 0;
  }

  .file-highlight {
    color: var(--text-primary);
    word-break: break-all;
  }

  .file-comparison-grid {
    display: flex;
    align-items: center;
    gap: var(--spacing-sm);
    margin: 4px 0;
  }

  .comparison-card {
    flex: 1;
    background-color: var(--bg-surface-variant, rgba(255, 255, 255, 0.04));
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    padding: var(--spacing-md);
    display: flex;
    flex-direction: column;
    gap: 6px;
  }

  .comparison-card.incoming {
    border-color: rgba(99, 102, 241, 0.3);
    background-color: rgba(99, 102, 241, 0.05);
  }

  .comparison-header {
    display: flex;
    align-items: center;
    gap: 6px;
    color: var(--text-primary);
  }

  .comp-icon {
    font-size: 18px;
    color: var(--accent-color);
  }

  .comparison-details {
    display: flex;
    flex-direction: column;
    gap: 4px;
  }

  .detail-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .comparison-arrow {
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--text-muted);
  }

  .apply-all-checkbox {
    display: flex;
    align-items: center;
    gap: 8px;
    cursor: pointer;
    user-select: none;
    color: var(--text-secondary);
    font-size: 13px;
    padding: 4px 0;
  }

  .apply-all-checkbox input[type="checkbox"] {
    accent-color: var(--accent-color);
    width: 16px;
    height: 16px;
    cursor: pointer;
  }

  .conflict-actions {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: var(--spacing-sm);
    margin-top: 8px;
    flex-wrap: wrap;
  }

  .batch-quick-actions {
    display: flex;
    gap: 6px;
  }

  .primary-choice-actions {
    display: flex;
    gap: var(--spacing-sm);
    margin-left: auto;
  }

  .btn-sm {
    padding: 6px 12px;
    font-size: 12px;
  }

  .font-bold {
    font-weight: 600;
  }

  .font-medium {
    font-weight: 500;
    color: var(--text-primary);
  }
</style>
