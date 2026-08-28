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

  export let selectedCount = 0;
  export let shiftUp = false;
  export let currentScope = 'private';

  const dispatch = createEventDispatcher();
</script>

{#if selectedCount > 0}
  <div class="selection-action-bar" class:shifted={shiftUp}>
    <div class="selection-info text-body">
      <span class="count-badge">{selectedCount}</span>
      <span>{$t('common.selected')}</span>
    </div>

    <div class="action-buttons">
      <button
        class="btn btn-secondary action-btn text-body"
        on:click={() => dispatch('downloadSelected')}
        title={$t('context_menu.download_selected')}
        style="display: inline-flex; align-items: center; gap: 8px;"
      >
        <span class="material-symbols-outlined" style="font-size: 20px;">download</span>
        {$t('common.download')}
      </button>

      {#if currentScope !== 'shared'}
        <button
          class="btn btn-secondary action-btn text-body"
          on:click={() => dispatch('shareSelected')}
          title={$t('context_menu.share_link')}
          style="display: inline-flex; align-items: center; gap: 8px;"
        >
          <span class="material-symbols-outlined" style="font-size: 20px;">folder_shared</span>
          {$t('common.share')}
        </button>

        <button
          class="btn btn-secondary action-btn text-body"
          on:click={() => dispatch('moveSelected')}
          title={$t('context_menu.move_selected')}
          style="display: inline-flex; align-items: center; gap: 8px;"
        >
          <span class="material-symbols-outlined" style="font-size: 20px;">drive_file_move</span>
          {$t('common.move')}
        </button>

        <button
          class="btn btn-secondary action-btn text-body danger-btn"
          on:click={() => dispatch('deleteSelected')}
          title={$t('context_menu.delete_selected')}
          style="display: inline-flex; align-items: center; gap: 8px;"
        >
          <span class="material-symbols-outlined" style="font-size: 20px;">delete</span>
          {$t('common.delete')}
        </button>
      {:else}
        <button
          class="btn btn-secondary action-btn text-body danger-btn"
          on:click={() => dispatch('unshareSelected')}
          title={$t('context_menu.unshare_in_server')}
          style="display: inline-flex; align-items: center; gap: 8px;"
        >
          <span class="material-symbols-outlined" style="font-size: 20px;">folder_off</span>
          {$t('common.unshare')}
        </button>
      {/if}

      <button
        class="btn-icon close-btn"
        on:click={() => dispatch('clear')}
        title={$t('common.deselect_all')}
        style="display: flex; align-items: center; justify-content: center;"
      >
        <span class="material-symbols-outlined" style="font-size: 20px;">close</span>
      </button>
    </div>
  </div>
{/if}

<style>
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
    transition: bottom 0.25s cubic-bezier(0.4, 0, 0.2, 1);
    animation: slideUp 0.2s ease-out;
  }

  .selection-action-bar.shifted {
    bottom: 88px; /* Shift up to not overlap with TransferBottomBar */
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
</style>
