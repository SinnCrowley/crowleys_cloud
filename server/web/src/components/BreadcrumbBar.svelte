<script>
  import { createEventDispatcher } from 'svelte';

  export let path = '';

  const dispatch = createEventDispatcher();

  $: segments = path ? path.split('/').filter(Boolean) : [];

  function navigateToSegment(index) {
    const targetPath = segments.slice(0, index + 1).join('/');
    dispatch('navigate', targetPath);
  }
</script>

<nav class="breadcrumb-bar">
  <button
    class="breadcrumb-item home-btn"
    on:click={() => dispatch('navigate', '')}
    title="Home Root"
    style="display: inline-flex; align-items: center;"
  >
    <span class="material-symbols-outlined" style="font-size: 18px; margin-right: 6px;">folder</span>
    Root
  </button>

  {#each segments as segment, i}
    <span class="separator">›</span>
    <button
      class="breadcrumb-item {i === segments.length - 1 ? 'active' : ''}"
      on:click={() => navigateToSegment(i)}
    >
      {segment}
    </button>
  {/each}
</nav>

<style>
  .breadcrumb-bar {
    height: 44px;
    background-color: var(--bg-background);
    border-bottom: 1px solid var(--border-color);
    display: flex;
    align-items: center;
    padding: 0 var(--spacing-lg);
    gap: var(--spacing-xs);
    overflow-x: auto;
    white-space: nowrap;
  }

  .breadcrumb-item {
    background: none;
    border: none;
    color: var(--text-sub);
    font-family: var(--font-sans);
    font-size: calc(13px * var(--font-scale));
    font-weight: 500;
    padding: 4px 8px;
    border-radius: var(--radius-sm);
    cursor: pointer;
    transition: color 0.15s ease, background-color 0.15s ease;
  }

  .breadcrumb-item:hover {
    color: var(--text-main);
    background-color: var(--bg-surface-hover);
  }

  .breadcrumb-item.active {
    color: var(--accent-color);
    font-weight: 700;
  }

  .separator {
    color: var(--text-sub);
    font-size: 14px;
  }
</style>
