<script>
  import { createEventDispatcher } from 'svelte';

  export let selectedCount = 0;
  export let shiftUp = false;
  export let currentScope = 'private';

  const dispatch = createEventDispatcher();
</script>

{#if selectedCount > 0}
  <div class="selection-action-bar" class:shifted={shiftUp}>
    <div class="selection-info text-body">
      <span class="count-badge">{selectedCount}</span> selected
    </div>

    <div class="action-buttons">
      <button
        class="btn btn-secondary action-btn text-body"
        on:click={() => dispatch('downloadSelected')}
        title="Download selected items"
        style="display: inline-flex; align-items: center; gap: 8px;"
      >
        <span class="material-symbols-outlined" style="font-size: 20px;">download</span>
        Download
      </button>

      {#if currentScope !== 'shared'}
        <button
          class="btn btn-secondary action-btn text-body"
          on:click={() => dispatch('shareSelected')}
          title="Share selected items in server"
          style="display: inline-flex; align-items: center; gap: 8px;"
        >
          <span class="material-symbols-outlined" style="font-size: 20px;">folder_shared</span>
          Share
        </button>

        <button
          class="btn btn-secondary action-btn text-body"
          on:click={() => dispatch('moveSelected')}
          title="Move selected items"
          style="display: inline-flex; align-items: center; gap: 8px;"
        >
          <span class="material-symbols-outlined" style="font-size: 20px;">drive_file_move</span>
          Move
        </button>

        <button
          class="btn btn-secondary action-btn text-body danger-btn"
          on:click={() => dispatch('deleteSelected')}
          title="Delete selected items to trash"
          style="display: inline-flex; align-items: center; gap: 8px;"
        >
          <span class="material-symbols-outlined" style="font-size: 20px;">delete</span>
          Delete
        </button>
      {:else}
        <button
          class="btn btn-secondary action-btn text-body danger-btn"
          on:click={() => dispatch('unshareSelected')}
          title="Unshare selected items in server"
          style="display: inline-flex; align-items: center; gap: 8px;"
        >
          <span class="material-symbols-outlined" style="font-size: 20px;">folder_off</span>
          Unshare
        </button>
      {/if}

      <button
        class="btn-icon close-btn"
        on:click={() => dispatch('clear')}
        title="Deselect all"
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
