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

  export let currentRoute = 'dashboard';
  export let filterType = 'all';
  export let scope = 'private';

  const dispatch = createEventDispatcher();

  function closeMobileSidebar() {
    if (typeof document !== 'undefined') {
      const sidebar = document.querySelector('.sidebar-nav');
      if (sidebar) sidebar.classList.remove('open');
      const backdrop = document.querySelector('.sidebar-mobile-backdrop');
      if (backdrop) backdrop.classList.remove('open');
    }
  }

  function selectRoute(route, newFilterType = 'all', newScope = 'private') {
    closeMobileSidebar();
    dispatch('navigate', { route, filterType: newFilterType, scope: newScope });
  }

  function handleUploadTrigger() {
    closeMobileSidebar();
    dispatch('uploadTrigger');
  }
</script>

<aside class="sidebar-nav">
  <div class="sidebar-brand">
    <div class="sidebar-brand-logo">
      <img src="/logo.png" alt="Crowley's Cloud Logo" />
    </div>
  </div>

  <div class="sidebar-add-btn-container">
    <button class="sidebar-add-btn" on:click={handleUploadTrigger}>
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
      <span>Shared</span>
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
