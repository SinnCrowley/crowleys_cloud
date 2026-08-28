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
  import { createEventDispatcher, onDestroy } from 'svelte';
  import { authStore } from '../stores/auth.js';
  import { t } from '../stores/i18n.js';
  import CustomSelect from './CustomSelect.svelte';

  export let searchQuery = '';
  export let layoutMode = 'grid';
  export let sortBy = 'name';
  export let sortOrder = 'asc';
  export let currentTheme = 'dark';
  export let isAuthenticated = false;
  export let currentRoute = 'dashboard';

  const dispatch = createEventDispatcher();
  const { user } = authStore;

  let searchTimeout = null;

  function handleSearchInput(e) {
    const val = e.target.value;
    if (searchTimeout) clearTimeout(searchTimeout);
    searchTimeout = setTimeout(() => {
      dispatch('search', val);
    }, 800);
  }

  function handleSearchKeydown(e) {
    if (e.key === 'Enter') {
      if (searchTimeout) clearTimeout(searchTimeout);
      dispatch('search', e.target.value);
    }
  }

  function clearSearch() {
    if (searchTimeout) clearTimeout(searchTimeout);
    dispatch('search', '');
  }

  onDestroy(() => {
    if (searchTimeout) clearTimeout(searchTimeout);
  });

  $: sortOptions = [
    { value: 'name', label: $t('nav.sort_name') },
    { value: 'date', label: $t('nav.sort_date') },
    { value: 'size', label: $t('nav.sort_size') },
    { value: 'type', label: $t('nav.sort_type') }
  ];

  function handleSortChange(e) {
    dispatch('changeSort', e.detail);
  }

  function toggleSidebarMobile() {
    const sidebar = document.querySelector('.sidebar-nav');
    const backdrop = document.querySelector('.sidebar-mobile-backdrop');
    if (sidebar) {
      sidebar.classList.toggle('open');
    }
    if (backdrop) {
      backdrop.classList.toggle('open');
    }
  }
</script>

<header class="header-bar">
  <!-- Mobile Menu Toggle & App Name -->
  <div class="mobile-toggle-section">
    <button class="btn-icon mobile-menu-btn" on:click={toggleSidebarMobile} title={$t('nav.toggle_menu')}>
      <span class="material-symbols-outlined">menu</span>
    </button>
    <img src="/logo_horizontal.png" alt="Crowley's Cloud Logo" class="mobile-brand-logo" />
  </div>

  <!-- Search Input Area -->
  <div class="search-section">
    <div class="search-wrapper">
      <span class="material-symbols-outlined search-icon">search</span>
      <input
        type="text"
        class="search-pill text-body"
        placeholder={$t('nav.search_placeholder')}
        value={searchQuery}
        on:input={handleSearchInput}
        on:keydown={handleSearchKeydown}
      />
      {#if searchQuery}
        <button
          type="button"
          class="btn-icon clear-search-btn"
          on:click={clearSearch}
          title={$t('nav.clear_search')}
        >
          <span class="material-symbols-outlined">close</span>
        </button>
      {/if}
    </div>
  </div>

  <!-- Actions & Utility Bar -->
  <div class="actions-section">
    <!-- View Mode Selector -->
    {#if currentRoute === 'files' || currentRoute === 'trash'}
      <button
        class="btn-icon header-action-btn"
        title={$t('nav.toggle_view')}
        on:click={() => dispatch('toggleLayout')}
      >
        <span class="material-symbols-outlined">
          {layoutMode === 'grid' ? 'list' : 'grid_view'}
        </span>
      </button>

      <!-- Sort Column Selector -->
      <div class="sort-select-container">
        <span class="sort-label text-caption">{$t('nav.sort_by')}</span>
        <CustomSelect
          bind:value={sortBy}
          options={sortOptions}
          on:change={handleSortChange}
        />
      </div>

      <!-- Sort Order Toggle -->
      <button
        class="btn-icon header-action-btn"
        title={$t('nav.toggle_sort_direction')}
        on:click={() => dispatch('toggleSortOrder')}
      >
        <span class="material-symbols-outlined">
          {sortOrder === 'asc' ? 'arrow_upward' : 'arrow_downward'}
        </span>
      </button>
    {/if}

    <div class="header-divider"></div>

    <!-- Theme Mode Toggle -->
    <button
      class="btn-icon header-action-btn"
      title={$t('nav.toggle_theme')}
      on:click={() => dispatch('toggleTheme')}
    >
      <span class="material-symbols-outlined">
        {currentTheme === 'dark' ? 'light_mode' : 'dark_mode'}
      </span>
    </button>

    <!-- Authentication Username Button (No Avatar) -->
    {#if isAuthenticated}
      <button class="username-btn text-body" on:click={() => dispatch('openAuth')} title={$t('modals.auth.logged_in_as', { username: $user?.username || $t('nav.user') })}>
        <span class="material-symbols-outlined username-icon">person</span>
        <span class="username-text">{$user?.username || $t('nav.user')}</span>
      </button>
    {:else}
      <button class="btn btn-primary" on:click={() => dispatch('openAuth')}>
        <span class="material-symbols-outlined" style="font-size: 18px;">login</span>
        {$t('nav.sign_in')}
      </button>
    {/if}
  </div>
</header>

<style>
  .header-bar {
    height: 64px;
    background-color: var(--bg-surface);
    border-bottom: 1px solid var(--border-color);
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 24px;
    gap: var(--spacing-md);
    flex-shrink: 0;
  }

  .mobile-toggle-section {
    display: none;
    align-items: center;
    gap: var(--spacing-sm);
  }

  .mobile-menu-btn {
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .mobile-brand-logo {
    height: 40px;
    max-height: 42px;
    width: auto;
    object-fit: contain;
  }

  .search-section {
    flex: 1;
    max-width: 480px;
  }

  .search-wrapper {
    position: relative;
    width: 100%;
  }

  .search-icon {
    position: absolute;
    left: 12px;
    top: 50%;
    transform: translateY(-50%);
    color: var(--text-sub);
    pointer-events: none;
    font-size: 20px;
  }

  .search-pill {
    width: 100%;
    height: 40px;
    border-radius: var(--radius-full);
    background-color: var(--bg-input);
    border: 1px solid var(--border-color);
    padding: 0 36px 0 44px;
    color: var(--text-main);
    outline: none;
    font-size: 13px;
    font-weight: 500;
    transition: border-color 0.15s ease, box-shadow 0.15s ease;
  }

  .search-pill:focus {
    border-color: var(--accent-color);
    box-shadow: 0 0 0 2px rgba(250, 82, 82, 0.15);
  }

  .clear-search-btn {
    position: absolute;
    right: 10px;
    top: 50%;
    transform: translateY(-50%);
    color: var(--text-sub);
    width: 24px;
    height: 24px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    background: none;
    border: none;
    cursor: pointer;
    padding: 0;
  }

  .clear-search-btn:hover {
    color: var(--text-main);
    background-color: var(--bg-surface-hover);
  }

  .clear-search-btn .material-symbols-outlined {
    font-size: 16px;
  }

  .actions-section {
    display: flex;
    align-items: center;
    gap: var(--spacing-sm);
  }

  .header-action-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--text-sub);
    width: 36px;
    height: 36px;
  }

  .header-action-btn:hover {
    color: var(--text-main);
    background-color: var(--bg-surface-hover);
  }

  .select-wrapper {
    position: relative;
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .sort-label {
    color: var(--text-sub);
    font-size: 12px;
    font-weight: 600;
    white-space: nowrap;
    flex-shrink: 0;
    user-select: none;
  }

  .sort-select-container {
    display: flex;
    align-items: center;
    gap: 8px;
    flex-shrink: 0;
  }

  .sort-select-container :global(.custom-select-wrapper) {
    width: 140px;
    max-width: 140px;
    flex-shrink: 0;
  }

  .sort-select-container :global(.custom-select-trigger) {
    height: 36px;
    padding: 0 12px;
  }

  .header-divider {
    width: 1px;
    height: 20px;
    background-color: var(--border-color);
    margin: 0 4px;
    flex-shrink: 0;
  }

  .username-btn {
    display: flex;
    align-items: center;
    gap: 8px;
    background-color: var(--bg-input);
    color: var(--text-main);
    border: 1px solid var(--border-color);
    padding: 6px 14px;
    border-radius: var(--radius-full);
    cursor: pointer;
    font-weight: 600;
    font-size: 13px;
    transition: background-color 0.15s ease, border-color 0.15s ease;
  }

  .username-btn:hover {
    background-color: var(--bg-surface-hover);
    border-color: var(--accent-color);
  }

  .username-icon {
    font-size: 18px;
    color: var(--text-sub);
  }

  .username-btn:hover .username-icon {
    color: var(--accent-color);
  }

  .username-text {
    max-width: 120px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  @media (max-width: 768px) {
    .mobile-toggle-section {
      display: flex;
    }

    .header-bar {
      padding: 0 16px;
    }
  }

  @media (max-width: 480px) {
    .search-section {
      display: none;
    }
    .header-bar {
      padding: 0 10px;
      gap: 6px;
    }
    .actions-section {
      gap: 4px;
    }
    .username-text {
      max-width: 70px;
    }
  }
</style>
