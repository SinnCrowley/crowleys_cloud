<script>
  import { createEventDispatcher } from 'svelte';

  export let currentRoute = 'dashboard';
  export let filterType = 'all';
  export let scope = 'private';

  const dispatch = createEventDispatcher();

  function selectRoute(route, newFilterType = 'all', newScope = 'private') {
    dispatch('navigate', { route, filterType: newFilterType, scope: newScope });
  }
</script>

<aside class="sidebar-nav">
  <div class="sidebar-brand">
    <div class="sidebar-brand-logo" style="background: transparent; padding: 0;">
      <img src="/logo.png" alt="Crowley's Cloud Logo" style="width: 100%; height: 100%; object-fit: contain;" />
    </div>
    <div class="sidebar-brand-info">
      <span class="sidebar-brand-title">Crowley's Cloud</span>
      <span class="sidebar-brand-subtitle">Web Client v1.0</span>
    </div>
  </div>

  <div class="sidebar-add-btn-container">
    <button class="sidebar-add-btn" on:click={() => dispatch('uploadTrigger')}>
      <span class="material-symbols-outlined">upload</span>
      Upload File
    </button>
  </div>

  <nav class="sidebar-menu">
    <button
      class="sidebar-item {currentRoute === 'dashboard' ? 'active' : ''}"
      on:click={() => selectRoute('dashboard')}
    >
      <span class="material-symbols-outlined">dashboard</span>
      <span>Dashboard</span>
    </button>

    <div class="sidebar-divider"></div>

    <button
      class="sidebar-item {currentRoute === 'files' && scope === 'private' && filterType === 'all' ? 'active' : ''}"
      on:click={() => selectRoute('files', 'all', 'private')}
    >
      <span class="material-symbols-outlined">folder</span>
      <span>All Files</span>
    </button>

    <button
      class="sidebar-item {currentRoute === 'files' && scope === 'private' && filterType === 'photo' ? 'active' : ''}"
      on:click={() => selectRoute('files', 'photo', 'private')}
    >
      <span class="material-symbols-outlined">photo</span>
      <span>Photos</span>
    </button>

    <button
      class="sidebar-item {currentRoute === 'files' && scope === 'private' && filterType === 'video' ? 'active' : ''}"
      on:click={() => selectRoute('files', 'video', 'private')}
    >
      <span class="material-symbols-outlined">videocam</span>
      <span>Videos</span>
    </button>

    <button
      class="sidebar-item {currentRoute === 'files' && scope === 'private' && filterType === 'audio' ? 'active' : ''}"
      on:click={() => selectRoute('files', 'audio', 'private')}
    >
      <span class="material-symbols-outlined">audiotrack</span>
      <span>Audio</span>
    </button>

    <button
      class="sidebar-item {currentRoute === 'files' && scope === 'private' && filterType === 'document' ? 'active' : ''}"
      on:click={() => selectRoute('files', 'document', 'private')}
    >
      <span class="material-symbols-outlined">description</span>
      <span>Documents</span>
    </button>

    <button
      class="sidebar-item {currentRoute === 'files' && scope === 'private' && filterType === 'other' ? 'active' : ''}"
      on:click={() => selectRoute('files', 'other', 'private')}
    >
      <span class="material-symbols-outlined">insert_drive_file</span>
      <span>Other</span>
    </button>

    <div class="sidebar-divider"></div>

    <button
      class="sidebar-item {currentRoute === 'files' && scope === 'shared' ? 'active' : ''}"
      on:click={() => selectRoute('files', 'all', 'shared')}
    >
      <span class="material-symbols-outlined">group</span>
      <span>Shared with me</span>
    </button>
  </nav>

  <div class="sidebar-footer">
    <button
      class="sidebar-item {currentRoute === 'trash' ? 'active' : ''}"
      on:click={() => selectRoute('trash')}
    >
      <span class="material-symbols-outlined">delete</span>
      <span>Trash</span>
    </button>

    <button
      class="sidebar-item {currentRoute === 'settings' ? 'active' : ''}"
      on:click={() => selectRoute('settings')}
    >
      <span class="material-symbols-outlined">settings</span>
      <span>Settings</span>
    </button>
  </div>
</aside>
