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
