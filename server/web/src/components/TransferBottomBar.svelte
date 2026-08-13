<script>
  import { transfersStore, activeCount, totalSpeed } from '../stores/transfers.js';

  const { queue, isDrawerOpen } = transfersStore;

  $: totalItemsCount = $queue.length;
  $: activeItemsCount = $activeCount;
  $: pausedItemsCount = $queue.filter((t) => t.status === 'paused').length;
  $: cancelledItemsCount = $queue.filter((t) => t.status === 'cancelled').length;
  $: completedItemsCount = $queue.filter((t) => t.status === 'completed').length;
  $: speedBytes = $totalSpeed;

  $: overallProgress = calculateOverallProgress($queue);

  function calculateOverallProgress(items) {
    if (items.length === 0) return 0;
    const totalBytes = items.reduce((sum, i) => sum + (i.size || 0), 0);
    const transferredBytes = items.reduce((sum, i) => sum + (i.transferred || 0), 0);
    if (totalBytes === 0) return 0;
    return Math.round((transferredBytes / totalBytes) * 100);
  }

  function formatSpeed(bytesPerSec) {
    if (!bytesPerSec || bytesPerSec <= 0) return '0 KB/s';
    if (bytesPerSec < 1024 * 1024) {
      return (bytesPerSec / 1024).toFixed(1) + ' KB/s';
    }
    return (bytesPerSec / (1024 * 1024)).toFixed(1) + ' MB/s';
  }
  $: hasRunningOrQueued = $queue.some((t) => t.status === 'running' || t.status === 'queued');
  $: hasActiveTransfers = $queue.some((t) => t.status === 'running' || t.status === 'queued' || t.status === 'paused');
</script>

{#if totalItemsCount > 0}
  <div class="transfer-bottom-bar text-body">
    <div class="transfer-summary" on:click={() => transfersStore.toggleDrawer()}>
      {#if activeItemsCount > 0}
        <span class="active-badge">{activeItemsCount} active</span>
        <span class="speed-indicator">{formatSpeed(speedBytes)}</span>
        <div class="mini-progress-bar">
          <div class="mini-progress-fill" style="width: {overallProgress}%;" />
        </div>
        <span class="progress-percent">{overallProgress}%</span>
      {:else if pausedItemsCount > 0}
        <span class="active-badge badge-paused">{pausedItemsCount} paused</span>
        <div class="mini-progress-bar">
          <div class="mini-progress-fill paused-fill" style="width: {overallProgress}%;" />
        </div>
        <span class="idle-text text-sub">Transfers paused ({overallProgress}%)</span>
      {:else if cancelledItemsCount > 0 && completedItemsCount < totalItemsCount}
        <span class="active-badge badge-cancelled">{cancelledItemsCount} cancelled</span>
        <span class="idle-text text-sub">Transfers cancelled</span>
      {:else}
        <span class="active-badge badge-completed">Completed</span>
        <span class="idle-text text-sub">Transfers finished</span>
      {/if}
    </div>

    <div class="bar-actions">
      {#if hasActiveTransfers}
        <button
          class="btn-icon mini-action"
          title={hasRunningOrQueued ? "Pause transfers" : "Resume transfers"}
          on:click={() => transfersStore.togglePauseAll()}
        >
          <span class="material-symbols-outlined" style="font-size: 18px;">
            {hasRunningOrQueued ? 'pause' : 'play_arrow'}
          </span>
        </button>

        <button
          class="btn-icon mini-action action-danger"
          title="Cancel transfers"
          on:click={() => transfersStore.cancelAll()}
        >
          <span class="material-symbols-outlined" style="font-size: 18px;">close</span>
        </button>
      {/if}

      <button
        class="btn-icon mini-action"
        title={$isDrawerOpen ? 'Close drawer' : 'Expand drawer'}
        on:click={() => transfersStore.toggleDrawer()}
      >
        <span class="material-symbols-outlined" style="font-size: 18px;">
          {$isDrawerOpen ? 'expand_more' : 'expand_less'}
        </span>
      </button>
    </div>
  </div>
{/if}

<style>
  .transfer-bottom-bar {
    position: fixed;
    bottom: 16px;
    left: 50%;
    transform: translateX(-50%);
    z-index: 900;
    display: flex;
    align-items: center;
    gap: var(--spacing-md);
    background-color: var(--bg-surface);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-full);
    padding: 6px 16px;
    box-shadow: var(--shadow-card);
    backdrop-filter: blur(8px);
    user-select: none;
    min-width: 280px;
    justify-content: space-between;
  }

  .transfer-summary {
    display: flex;
    align-items: center;
    gap: var(--spacing-sm);
    cursor: pointer;
    flex: 1;
  }

  .active-badge {
    background-color: var(--accent-color);
    color: #ffffff;
    border-radius: var(--radius-full);
    padding: 2px 8px;
    font-size: calc(12px * var(--font-scale));
    font-weight: 700;
  }

  .active-badge.badge-paused {
    background-color: #fcc419;
    color: #000000;
  }

  .active-badge.badge-cancelled {
    background-color: #868e96;
    color: #ffffff;
  }

  .active-badge.badge-completed {
    background-color: #51cf66;
    color: #ffffff;
  }

  .mini-progress-fill.paused-fill {
    background-color: #fcc419;
  }

  .speed-indicator {
    font-family: var(--font-mono);
    font-size: calc(12px * var(--font-scale));
    color: var(--text-main);
    font-weight: 600;
  }

  .mini-progress-bar {
    width: 60px;
    height: 6px;
    background-color: var(--bg-input);
    border-radius: var(--radius-full);
    overflow: hidden;
    flex-shrink: 0;
  }

  .mini-progress-fill {
    height: 100%;
    background-color: var(--accent-color);
    transition: width 0.2s ease;
  }

  .progress-percent {
    font-size: calc(12px * var(--font-scale));
    color: var(--text-sub);
    min-width: 32px;
  }

  .idle-text {
    font-size: calc(13px * var(--font-scale));
    color: var(--text-sub);
    font-weight: 600;
  }

  .bar-actions {
    display: flex;
    align-items: center;
    gap: var(--spacing-xs);
  }

  .mini-action {
    width: 28px;
    height: 28px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--text-sub);
    border-radius: var(--radius-full);
  }

  .mini-action:hover {
    background-color: var(--bg-surface-hover);
    color: var(--accent-color);
  }

  .mini-action.action-danger:hover {
    background-color: rgba(255, 82, 82, 0.15);
    color: var(--color-danger);
  }
</style>
