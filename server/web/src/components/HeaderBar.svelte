<script>
  import { createEventDispatcher, onDestroy } from 'svelte';
  import { authStore } from '../stores/auth.js';
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

  const sortOptions = [
    { value: 'name', label: 'Name' },
    { value: 'date', label: 'Date' },
    { value: 'size', label: 'Size' },
    { value: 'type', label: 'Type' }
  ];

  function handleSortChange(e) {
    dispatch('changeSort', e.detail);
  }

  function toggleSidebarMobile() {
    const sidebar = document.querySelector('.sidebar-nav');
    if (sidebar) {
      sidebar.classList.toggle('open');
    }
  }
</script>

<header class="header-bar">
  <!-- Mobile Menu Toggle & App Name -->
  <div class="mobile-toggle-section">
    <button class="btn-icon mobile-menu-btn" on:click={toggleSidebarMobile} title="Toggle menu">
      <span class="material-symbols-outlined">menu</span>
    </button>
    <span class="mobile-brand-title text-title">Crowley's Cloud</span>
  </div>

  <!-- Search Input Area -->
  <div class="search-section">
    <div class="search-wrapper">
      <span class="material-symbols-outlined search-icon">search</span>
      <input
        type="text"
        class="search-pill text-body"
        placeholder="Search files, folders, extensions..."
        value={searchQuery}
        on:input={handleSearchInput}
        on:keydown={handleSearchKeydown}
      />
      {#if searchQuery}
        <button
          type="button"
          class="btn-icon clear-search-btn"
          on:click={clearSearch}
          title="Clear search"
        >
          <span class="material-symbols-outlined">close</span>
        </button>
      {/if}
    </div>
  </div>

  <!-- Actions & Utility Bar -->
  <div class="actions-section">
    <!-- View Mode Selector -->
    {#if currentRoute === 'files'}
      <button
        class="btn-icon header-action-btn"
        title="Toggle Grid / List View"
        on:click={() => dispatch('toggleLayout')}
      >
        <span class="material-symbols-outlined">
          {layoutMode === 'grid' ? 'list' : 'grid_view'}
        </span>
      </button>

      <!-- Sort Column Selector -->
      <div class="sort-select-container">
        <span class="sort-label text-caption">Sort by:</span>
        <CustomSelect
          bind:value={sortBy}
          options={sortOptions}
          on:change={handleSortChange}
        />
      </div>

      <!-- Sort Order Toggle -->
      <button
        class="btn-icon header-action-btn"
        title="Toggle Sort Direction"
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
      title="Toggle Light / Dark Mode"
      on:click={() => dispatch('toggleTheme')}
    >
      <span class="material-symbols-outlined">
        {currentTheme === 'dark' ? 'light_mode' : 'dark_mode'}
      </span>
    </button>

    <!-- Authentication Username Button (No Avatar) -->
    {#if isAuthenticated}
      <button class="username-btn text-body" on:click={() => dispatch('openAuth')} title="Logged in as {$user?.username || 'User'}">
        <span class="material-symbols-outlined username-icon">person</span>
        <span class="username-text">{$user?.username || 'User'}</span>
      </button>
    {:else}
      <button class="btn btn-primary" on:click={() => dispatch('openAuth')}>
        <span class="material-symbols-outlined" style="font-size: 18px;">login</span>
        Sign In
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

  .mobile-brand-title {
    font-weight: 700;
    color: var(--accent-color);
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
  }

  .sort-select-container {
    display: flex;
    align-items: center;
    gap: 6px;
  }

  .sort-select-container :global(.custom-select-wrapper) {
    max-width: 140px;
  }

  .sort-select-container :global(.custom-select-trigger) {
    height: 36px;
  }

  .header-divider {
    width: 1px;
    height: 20px;
    background-color: var(--border-color);
    margin: 0 4px;
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
  }
</style>
