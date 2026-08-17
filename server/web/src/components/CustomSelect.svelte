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
  import { createEventDispatcher, onMount } from 'svelte';
  export let value = '';
  export let options = []; // Array of { value, label }

  const dispatch = createEventDispatcher();
  let isOpen = false;
  let selectEl;

  function toggleOpen() {
    isOpen = !isOpen;
  }

  function selectOption(optVal) {
    value = optVal;
    isOpen = false;
    dispatch('change', value);
  }

  function handleOutsideClick(e) {
    if (selectEl && !selectEl.contains(e.target)) {
      isOpen = false;
    }
  }

  onMount(() => {
    if (typeof window !== 'undefined') {
      window.addEventListener('click', handleOutsideClick);
      return () => {
        window.removeEventListener('click', handleOutsideClick);
      };
    }
  });

  $: currentLabel = options.find(o => o.value === value)?.label || value;
</script>

<div class="custom-select-wrapper" bind:this={selectEl}>
  <button class="custom-select-trigger text-body" on:click={toggleOpen}>
    <span>{currentLabel}</span>
    <span class="material-symbols-outlined select-arrow" class:rotated={isOpen}>expand_more</span>
  </button>

  {#if isOpen}
    <div class="custom-select-dropdown">
      {#each options as opt}
        <button
          class="custom-select-option text-body"
          class:selected={opt.value === value}
          on:click={() => selectOption(opt.value)}
        >
          <span>{opt.label}</span>
          {#if opt.value === value}
            <span class="material-symbols-outlined check-icon">check</span>
          {/if}
        </button>
      {/each}
    </div>
  {/if}
</div>

<style>
  .custom-select-wrapper {
    position: relative;
    width: 100%;
    max-width: 240px;
    user-select: none;
  }

  .custom-select-trigger {
    width: 100%;
    height: 40px;
    background-color: var(--bg-input);
    color: var(--text-main);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    padding: 0 16px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    transition: border-color 0.15s ease, background-color 0.15s ease;
  }

  .custom-select-trigger:hover {
    background-color: var(--bg-surface-hover);
    border-color: var(--accent-color);
  }

  .select-arrow {
    font-size: 18px;
    color: var(--text-sub);
    transition: transform 0.2s ease, color 0.15s ease;
  }

  .select-arrow.rotated {
    transform: rotate(180deg);
  }

  .custom-select-trigger:hover .select-arrow {
    color: var(--accent-color);
  }

  .custom-select-dropdown {
    position: absolute;
    top: calc(100% + 6px);
    left: 0;
    min-width: 100%;
    width: max-content;
    background-color: var(--bg-surface);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-lg);
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.25);
    z-index: 1000;
    overflow: hidden;
    padding: 4px;
    display: flex;
    flex-direction: column;
    gap: 2px;
    animation: fadeIn 0.15s ease-out;
  }

  @keyframes fadeIn {
    from {
      opacity: 0;
      transform: translateY(-8px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  .custom-select-option {
    width: 100%;
    padding: 8px 12px;
    background: transparent;
    border: none;
    border-radius: var(--radius-md);
    color: var(--text-main);
    font-size: 13px;
    font-weight: 500;
    text-align: left;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: space-between;
    transition: background-color 0.15s ease, color 0.15s ease;
  }

  .custom-select-option:hover {
    background-color: var(--bg-surface-hover);
    color: var(--accent-color);
  }

  .custom-select-option.selected {
    background-color: rgba(250, 82, 82, 0.08);
    color: var(--accent-color);
    font-weight: 700;
  }

  .check-icon {
    font-size: 16px;
    color: var(--accent-color);
  }
</style>
