<script>
  import { transfersStore } from '../stores/transfers.js';

  const { queue, isDrawerOpen } = transfersStore;

  function formatSize(bytes) {
    if (!bytes || isNaN(bytes)) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.min(Math.floor(Math.log(bytes) / Math.log(k)), sizes.length - 1);
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  }

  function formatSpeed(bytesPerSec) {
    if (!bytesPerSec || bytesPerSec <= 0) return '0 KB/s';
    if (bytesPerSec < 1024 * 1024) {
      return (bytesPerSec / 1024).toFixed(1) + ' KB/s';
    }
    return (bytesPerSec / (1024 * 1024)).toFixed(1) + ' MB/s';
  }

  function getStatusBadgeClass(status) {
    switch (status) {
      case 'running': return 'badge-running';
      case 'completed': return 'badge-completed';
      case 'failed': return 'badge-failed';
      case 'paused': return 'badge-paused';
      case 'cancelled': return 'badge-cancelled';
      default: return 'badge-queued';
    }
  }

  $: hasRunningOrQueued = $queue.some((t) => t.status === 'running' || t.status === 'queued');
  $: hasActiveTransfers = $queue.some((t) => t.status === 'running' || t.status === 'queued' || t.status === 'paused');
  $: hasCompletedOrFailed = $queue.some((t) => t.status === 'completed' || t.status === 'failed' || t.status === 'cancelled');
</script>

{#if $isDrawerOpen && $queue.length > 0}
  <div class="transfer-drawer">
    <div class="drawer-header">
      <div class="drawer-title text-title">
        Transfers Queue ({$queue.length})
      </div>
      <div class="drawer-controls">
        {#if hasActiveTransfers}
          <button
            class="btn-action text-caption"
            on:click={() => transfersStore.togglePauseAll()}
            title={hasRunningOrQueued ? "Pause all transfers" : "Resume all transfers"}
          >
            <span class="material-symbols-outlined" style="font-size: 16px;">
              {hasRunningOrQueued ? 'pause' : 'play_arrow'}
            </span>
            <span>{hasRunningOrQueued ? 'Pause' : 'Resume'}</span>
          </button>

          <button
            class="btn-action btn-danger text-caption"
            on:click={() => transfersStore.cancelAll()}
            title="Cancel all active transfers"
          >
            <span class="material-symbols-outlined" style="font-size: 16px;">close</span>
            <span>Cancel</span>
          </button>
        {/if}

        {#if hasCompletedOrFailed}
          <button
            class="btn-action text-caption"
            on:click={() => transfersStore.clearCompleted()}
            title="Clear finished transfers"
          >
            <span class="material-symbols-outlined" style="font-size: 16px;">delete_sweep</span>
            <span>Clear Completed</span>
          </button>
        {/if}

        <button
          class="btn-icon close-btn"
          on:click={() => transfersStore.toggleDrawer()}
          title="Minimize drawer"
        >
          <span class="material-symbols-outlined" style="font-size: 18px;">close</span>
        </button>
      </div>
    </div>

    <div class="drawer-list">
      {#each $queue as item (item.id)}
        <div class="transfer-item">
          <div class="item-main-row">
            <span class="type-badge">
              <span class="material-symbols-outlined" style="font-size: 20px; color: var(--text-sub);">
                {item.type === 'upload' ? 'upload' : 'download'}
              </span>
            </span>
            <div class="item-details">
              <span class="item-name text-body" title={item.path}>{item.name}</span>
              <span class="item-sub text-caption">
                {formatSize(item.transferred)} / {formatSize(item.size)}
                {#if item.status === 'running'}
                  · {formatSpeed(item.speed)}
                {/if}
              </span>
            </div>
            <span class="status-badge {getStatusBadgeClass(item.status)} text-caption">
              {item.status}
            </span>

            <div class="item-actions">
              {#if item.status === 'running'}
                <button
                  class="btn-icon mini-action"
                  title="Pause transfer"
                  on:click={() => transfersStore.pauseTransfer(item.id)}
                >
                  <span class="material-symbols-outlined" style="font-size: 16px;">pause</span>
                </button>
              {:else if item.status === 'paused'}
                <button
                  class="btn-icon mini-action"
                  title="Resume transfer"
                  on:click={() => transfersStore.resumeTransfer(item.id)}
                >
                  <span class="material-symbols-outlined" style="font-size: 16px;">play_arrow</span>
                </button>
              {/if}

              {#if item.status === 'running' || item.status === 'queued' || item.status === 'paused'}
                <button
                  class="btn-icon mini-action"
                  title="Cancel transfer"
                  on:click={() => transfersStore.cancelTransfer(item.id)}
                >
                  <span class="material-symbols-outlined" style="font-size: 16px;">close</span>
                </button>
              {/if}
            </div>
          </div>

          <div class="item-progress-bar">
            <div
              class="progress-fill {getStatusBadgeClass(item.status)}"
              style="width: {item.progress}%;"
            />
          </div>

          {#if item.error}
            <div class="item-error text-caption">{item.error}</div>
          {/if}
        </div>
      {/each}
    </div>
  </div>
{/if}

<style>
  .transfer-drawer {
    position: fixed;
    bottom: 76px;
    left: 50%;
    transform: translateX(-50%);
    width: 850px;
    max-width: calc(100vw - 32px);
    max-height: 720px;
    z-index: 900;
    background-color: var(--bg-surface);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-xl);
    box-shadow: var(--shadow-card);
    display: flex;
    flex-direction: column;
    overflow: hidden;
  }

  .drawer-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: var(--spacing-md) var(--spacing-lg);
    border-bottom: 1px solid var(--border-color);
    background-color: var(--bg-surface);
  }

  .drawer-title {
    margin: 0;
    color: var(--text-main);
    font-weight: 700;
    font-size: 14px;
  }

  .drawer-controls {
    display: flex;
    align-items: center;
    gap: var(--spacing-sm);
  }

  .btn-action {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    padding: 4px 10px;
    background-color: var(--bg-input);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    color: var(--text-main);
    cursor: pointer;
    font-weight: 600;
    font-size: 12px;
    transition: all 0.15s ease;
  }

  .btn-action:hover {
    background-color: var(--bg-surface-hover);
    color: var(--accent-color);
  }

  .btn-action.btn-danger {
    color: var(--color-danger);
  }

  .btn-action.btn-danger:hover {
    background-color: rgba(255, 82, 82, 0.12);
  }

  .btn-text {
    background: none;
    border: none;
    color: var(--accent-color);
    cursor: pointer;
    font-weight: 700;
  }

  .close-btn {
    width: 28px;
    height: 28px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: var(--radius-full);
  }

  .close-btn:hover {
    background-color: var(--bg-surface-hover);
    color: var(--accent-color);
  }

  .drawer-list {
    flex: 1;
    overflow-y: auto;
    padding: var(--spacing-sm) var(--spacing-md);
    display: flex;
    flex-direction: column;
    gap: var(--spacing-sm);
  }

  .transfer-item {
    background-color: var(--bg-input);
    border-radius: var(--radius-md);
    border: 1px solid var(--border-color);
    padding: var(--spacing-sm) var(--spacing-md);
    display: flex;
    flex-direction: column;
    gap: var(--spacing-xs);
  }

  .item-main-row {
    display: flex;
    align-items: center;
    gap: var(--spacing-sm);
  }

  .type-badge {
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }

  .item-details {
    flex: 1;
    display: flex;
    flex-direction: column;
    overflow: hidden;
  }

  .item-name {
    color: var(--text-main);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    font-weight: 600;
    font-size: 13px;
  }

  .item-sub {
    color: var(--text-sub);
    font-size: 11px;
    margin-top: 2px;
  }

  .status-badge {
    padding: 2px 6px;
    border-radius: var(--radius-sm);
    text-transform: capitalize;
    font-weight: 600;
    font-size: 10px;
  }

  .badge-queued {
    background-color: rgba(134, 142, 150, 0.15);
    color: var(--text-sub);
  }

  .badge-running {
    background-color: rgba(51, 154, 240, 0.15);
    color: #339af0;
  }

  .badge-completed {
    background-color: rgba(81, 207, 102, 0.15);
    color: #51cf66;
  }

  .badge-failed {
    background-color: rgba(255, 82, 82, 0.15);
    color: var(--color-danger);
  }

  .badge-paused {
    background-color: rgba(252, 196, 25, 0.15);
    color: #fcc419;
  }

  .badge-cancelled {
    background-color: rgba(134, 142, 150, 0.15);
    color: var(--text-sub);
  }

  .item-actions {
    display: flex;
    align-items: center;
    gap: var(--spacing-xs);
  }

  .mini-action {
    width: 26px;
    height: 26px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: var(--radius-full);
    color: var(--text-sub);
  }

  .mini-action:hover {
    background-color: var(--bg-surface-hover);
    color: var(--accent-color);
  }

  .item-progress-bar {
    width: 100%;
    height: 6px;
    background-color: var(--border-color);
    border-radius: var(--radius-full);
    overflow: hidden;
    margin-top: 4px;
  }

  .progress-fill {
    height: 100%;
    transition: width 0.2s ease;
  }

  .progress-fill.badge-running {
    background-color: #339af0;
  }

  .progress-fill.badge-completed {
    background-color: #51cf66;
  }

  .progress-fill.badge-failed {
    background-color: var(--color-danger);
  }

  .progress-fill.badge-paused {
    background-color: #fcc419;
  }

  .progress-fill.badge-queued {
    background-color: var(--text-sub);
  }

  .item-error {
    color: var(--color-danger);
    font-size: 11px;
    font-weight: 500;
    margin-top: 2px;
  }
</style>
