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

  export let x = 0;
  export let y = 0;
  export let item = null;
  export let selectedCount = 0;
  export let currentScope = 'private';

  const dispatch = createEventDispatcher();

  let menuElem;
  let clampedX = x;
  let clampedY = y;

  function updatePosition() {
    if (!menuElem) return;
    const rect = menuElem.getBoundingClientRect();
    const windowWidth = window.innerWidth;
    const windowHeight = window.innerHeight;

    if (x + rect.width > windowWidth - 8) {
      clampedX = Math.max(8, windowWidth - rect.width - 8);
    } else {
      clampedX = Math.max(8, x);
    }

    if (y + rect.height > windowHeight - 8) {
      clampedY = Math.max(8, windowHeight - rect.height - 8);
    } else {
      clampedY = Math.max(8, y);
    }
  }

  onMount(() => {
    updatePosition();
    window.addEventListener('click', handleWindowClick);
    window.addEventListener('keydown', handleKeyDown);
  });

  onDestroy(() => {
    window.removeEventListener('click', handleWindowClick);
    window.removeEventListener('keydown', handleKeyDown);
  });

  function handleWindowClick(e) {
    if (menuElem && !menuElem.contains(e.target)) {
      dispatch('close');
    }
  }

  // Close context menu on scrolls to avoid menu floating away from item
  onMount(() => {
    window.addEventListener('scroll', handleScroll, true);
  });
  onDestroy(() => {
    window.removeEventListener('scroll', handleScroll, true);
  });
  function handleScroll() {
    dispatch('close');
  }

  function handleKeyDown(e) {
    if (e.key === 'Escape') {
      dispatch('close');
    }
  }

  function handleAction(type) {
    dispatch('action', { type, item });
    dispatch('close');
  }
</script>

<div
  bind:this={menuElem}
  class="context-menu"
  style="top: {clampedY}px; left: {clampedX}px;"
>
  {#if item}
    <div class="menu-header text-caption">{item.name}</div>
    <div class="menu-divider" />

    {#if !item.is_dir}
      <button class="menu-item text-body" on:click={() => handleAction('preview')}>
        <span class="material-symbols-outlined item-icon">visibility</span> Preview / Open
      </button>
      <button class="menu-item text-body" on:click={() => handleAction('download')}>
        <span class="material-symbols-outlined item-icon">download</span> Download
      </button>
    {:else}
      <button class="menu-item text-body" on:click={() => handleAction('preview')}>
        <span class="material-symbols-outlined item-icon">folder_open</span> Open Folder
      </button>
      <button class="menu-item text-body" on:click={() => handleAction('downloadZip')}>
        <span class="material-symbols-outlined item-icon">folder_zip</span> Download ZIP
      </button>
    {/if}

    {#if currentScope !== 'shared'}
      <button class="menu-item text-body" on:click={() => handleAction('share')}>
        <span class="material-symbols-outlined item-icon">share</span> Share Link
      </button>
      <button class="menu-item text-body" on:click={() => handleAction('toggleServerShared')}>
        <span class="material-symbols-outlined item-icon">
          {item.is_shared ? 'folder_off' : 'folder_shared'}
        </span>
        {item.is_shared ? 'Unshare in Server' : 'Share in Server'}
      </button>

      <button class="menu-item text-body" on:click={() => handleAction('rename')}>
        <span class="material-symbols-outlined item-icon">edit</span> Rename
      </button>
      <button class="menu-item text-body" on:click={() => handleAction('move')}>
        <span class="material-symbols-outlined item-icon">drive_file_move</span> Move To...
      </button>
      <div class="menu-divider" />
      <button class="menu-item text-body danger" on:click={() => handleAction('delete')}>
        <span class="material-symbols-outlined item-icon">delete</span> Move to Trash
      </button>
    {:else}
      {#if item.is_owner !== false}
        <div class="menu-divider" />
        <button class="menu-item text-body danger" on:click={() => handleAction('toggleServerShared')}>
          <span class="material-symbols-outlined item-icon">folder_off</span> Unshare in Server
        </button>
      {/if}
    {/if}
  {:else if selectedCount > 0}
    <div class="menu-header text-caption">{selectedCount} items selected</div>
    <div class="menu-divider" />
    <button class="menu-item text-body" on:click={() => handleAction('download')}>
      <span class="material-symbols-outlined item-icon">download</span> Download Selected
    </button>
    {#if currentScope !== 'shared'}
      <button class="menu-item text-body" on:click={() => handleAction('move')}>
        <span class="material-symbols-outlined item-icon">drive_file_move</span> Move Selected...
      </button>
      <div class="menu-divider" />
      <button class="menu-item text-body danger" on:click={() => handleAction('delete')}>
        <span class="material-symbols-outlined item-icon">delete</span> Delete Selected to Trash
      </button>
    {/if}
  {:else}
    <button class="menu-item text-body" on:click={() => handleAction('refresh')}>
      <span class="material-symbols-outlined item-icon">refresh</span> Refresh Directory
    </button>
    <button class="menu-item text-body" on:click={() => handleAction('newFolder')}>
      <span class="material-symbols-outlined item-icon">create_new_folder</span> New Folder
    </button>
  {/if}
</div>

<style>
  .context-menu {
    position: fixed;
    z-index: 1100;
    min-width: 190px;
    max-width: 280px;
    background-color: var(--bg-surface);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    box-shadow: var(--shadow-dropdown);
    padding: var(--spacing-xs) 0;
    user-select: none;
  }

  .menu-header {
    padding: var(--spacing-xs) var(--spacing-md);
    color: var(--text-sub);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    font-weight: 700;
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .menu-divider {
    height: 1px;
    background-color: var(--border-color);
    margin: var(--spacing-xs) 0;
  }

  .menu-item {
    display: flex;
    align-items: center;
    gap: 12px;
    width: 100%;
    padding: 10px 16px;
    background: transparent;
    border: none;
    outline: none;
    color: var(--text-main);
    font-family: inherit;
    font-size: 13px;
    font-weight: 600;
    text-align: left;
    cursor: pointer;
    transition: background-color 0.15s ease, color 0.15s ease;
  }

  .menu-item:hover {
    background-color: var(--bg-surface-hover);
    color: var(--accent-color);
  }

  .menu-item.danger {
    color: var(--color-danger);
  }

  .menu-item.danger:hover {
    background-color: rgba(255, 82, 82, 0.1);
  }

  .item-icon {
    font-size: 18px;
    color: var(--text-sub);
    flex-shrink: 0;
  }

  .menu-item:hover .item-icon {
    color: var(--accent-color);
  }

  .menu-item.danger:hover .item-icon {
    color: var(--color-danger);
  }
</style>
