<script>
  import { onMount } from 'svelte';
  import { get } from 'svelte/store';
  import HeaderBar from './components/HeaderBar.svelte';
  import Sidebar from './components/Sidebar.svelte';
  import BreadcrumbBar from './components/BreadcrumbBar.svelte';
  import FileGrid from './components/FileGrid.svelte';
  import FileList from './components/FileList.svelte';
  import AuthModal from './components/AuthModal.svelte';
  import FolderPickerModal from './components/FolderPickerModal.svelte';
  import ContextMenu from './components/ContextMenu.svelte';
  import SelectionActionBar from './components/SelectionActionBar.svelte';
  import MediaPreviewModal from './components/MediaPreviewModal.svelte';
  import TransferBottomBar from './components/TransferBottomBar.svelte';
  import TransferProgressDrawer from './components/TransferProgressDrawer.svelte';
  import TrashBrowser from './routes/TrashBrowser.svelte';
  import Dashboard from './routes/Dashboard.svelte';
  import Settings from './routes/Settings.svelte';

  import { filesStore } from './stores/files.js';
  import { transfersStore, activeCount } from './stores/transfers.js';
  import { authStore } from './stores/auth.js';
  import { themeState } from './stores/theme.js';
  import { filesApi } from './api/files.js';
  import { refreshStats } from './stores/stats.js';
  import { shareApi } from './api/share.js';

  // Destructure stores for template binding
  const { scope, currentPath, entries, searchQuery, sortOption, filterType, selectedPaths, isLoading, error } = filesStore;
  const { isAuthenticated, user } = authStore;
  const { theme: appTheme, fontScale, accent } = themeState;
  const { queue: transfersQueue } = transfersStore;

  // URL Routing Helpers
  function encodeSubpath(path) {
    if (!path) return '';
    return path.split('/').map(encodeURIComponent).join('/');
  }

  function decodeSubpath(sub) {
    if (!sub) return '';
    return sub.split('/').map(decodeURIComponent).join('/');
  }

  function getUrlForState(route, scopeVal, filterVal, pathVal) {
    const r = (route === 'trash' || route === 'settings' || (route === 'dashboard' && filterVal === 'all' && scopeVal === 'private' && !pathVal))
      ? route
      : 'files';

    if (r === 'dashboard') return '/dashboard';
    if (r === 'trash') return '/trash';
    if (r === 'settings') return '/settings';

    if (r === 'files') {
      if (scopeVal === 'shared') {
        return pathVal ? `/shared/browse/${encodeSubpath(pathVal)}` : '/shared';
      }
      if (pathVal) {
        return `/files/browse/${encodeSubpath(pathVal)}`;
      }
      if (filterVal === 'photo') return '/photos';
      if (filterVal === 'video') return '/videos';
      if (filterVal === 'audio') return '/audio';
      if (filterVal === 'document') return '/documents';
      if (filterVal === 'other') return '/other';
      return '/files';
    }
    return '/dashboard';
  }

  function parseUrlToState(pathname) {
    const cleanPath = pathname.replace(/\/+$/, '') || '/';

    if (cleanPath === '/' || cleanPath === '/dashboard') {
      return { route: 'dashboard', scope: 'private', filterType: 'all', currentPath: '' };
    }
    if (cleanPath === '/trash') {
      return { route: 'trash', scope: 'private', filterType: 'all', currentPath: '' };
    }
    if (cleanPath === '/settings') {
      return { route: 'settings', scope: 'private', filterType: 'all', currentPath: '' };
    }
    if (cleanPath === '/shared' || cleanPath === '/shared/browse') {
      return { route: 'files', scope: 'shared', filterType: 'all', currentPath: '' };
    }
    if (cleanPath.startsWith('/shared/browse/')) {
      const rawSub = cleanPath.substring('/shared/browse/'.length);
      return { route: 'files', scope: 'shared', filterType: 'all', currentPath: decodeSubpath(rawSub) };
    }
    if (cleanPath === '/files' || cleanPath === '/files/all' || cleanPath === '/files/browse') {
      return { route: 'files', scope: 'private', filterType: 'all', currentPath: '' };
    }
    if (cleanPath === '/photos' || cleanPath === '/files/photos') {
      return { route: 'files', scope: 'private', filterType: 'photo', currentPath: '' };
    }
    if (cleanPath === '/videos' || cleanPath === '/files/videos') {
      return { route: 'files', scope: 'private', filterType: 'video', currentPath: '' };
    }
    if (cleanPath === '/audio' || cleanPath === '/files/audio') {
      return { route: 'files', scope: 'private', filterType: 'audio', currentPath: '' };
    }
    if (cleanPath === '/documents' || cleanPath === '/files/documents') {
      return { route: 'files', scope: 'private', filterType: 'document', currentPath: '' };
    }
    if (cleanPath === '/other' || cleanPath === '/files/other') {
      return { route: 'files', scope: 'private', filterType: 'other', currentPath: '' };
    }
    if (cleanPath.startsWith('/files/browse/')) {
      const rawSub = cleanPath.substring('/files/browse/'.length);
      return { route: 'files', scope: 'private', filterType: 'all', currentPath: decodeSubpath(rawSub) };
    }
    if (cleanPath.startsWith('/s/')) {
      if (typeof window !== 'undefined') {
        window.location.reload();
      }
      return { route: 'dashboard', scope: 'private', filterType: 'all', currentPath: '' };
    }

    return { route: 'dashboard', scope: 'private', filterType: 'all', currentPath: '' };
  }

  // Parse initial route synchronously on script load to prevent render flicker / state reset on page refresh
  const initialUrlState = typeof window !== 'undefined'
    ? parseUrlToState(window.location.pathname)
    : { route: 'dashboard', scope: 'private', filterType: 'all', currentPath: '' };

  // App-level state
  let layoutMode = typeof localStorage !== 'undefined' ? localStorage.getItem('cc_layout_mode') || 'grid' : 'grid';
  let currentRoute = initialUrlState.route;
  let isAuthOpen = false;
  $: if (!$isAuthenticated) {
    isAuthOpen = true;
  } else {
    refreshStats();
  }

  function closeMobileSidebar() {
    if (typeof document !== 'undefined') {
      const sidebar = document.querySelector('.sidebar-nav');
      if (sidebar) sidebar.classList.remove('open');
      const backdrop = document.querySelector('.sidebar-mobile-backdrop');
      if (backdrop) backdrop.classList.remove('open');
    }
  }

  // Global File Input for Sidebar trigger
  let globalFileInput;

  // Context Menu State
  let contextMenu = null; // { x, y, item }

  // Modal States
  let activePreviewFile = null; // file item object or null
  let isFolderPickerOpen = false;
  let folderPickerTargetItems = []; // Array of items to move
  let confirmMoveModal = null; // { validPaths, destFolder, targetName }

  // Share Link Modal State
  let shareModal = null; // { file, url }
  let renameModal = null; // { file, newName }

  // New folder dialog state
  let newFolderModal = false;
  let newFolderName = '';

  // Custom Toast System
  let toastMessage = '';
  let toastType = 'success'; // 'success' | 'error' | 'info'
  let toastTimeout;

  function showToast(message, type = 'success') {
    toastMessage = message;
    toastType = type;
    clearTimeout(toastTimeout);
    toastTimeout = setTimeout(() => {
      toastMessage = '';
    }, 4000);
  }

  function handleToastEvent(e) {
    const { message, type } = e.detail || {};
    if (message) {
      showToast(message, type);
    }
  }

  if (typeof window !== 'undefined') {
    filesStore.scope.set(initialUrlState.scope);
    filesStore.filterType.set(initialUrlState.filterType);
    filesStore.currentPath.set(initialUrlState.currentPath);
  }

  function applyStateFromPath(pathname, pushToHistory = false) {
    closeMobileSidebar();
    const newState = parseUrlToState(pathname);
    currentRoute = newState.route;

    filesStore.selectedPaths.set(new Set());
    filesStore.scope.set(newState.scope);
    filesStore.filterType.set(newState.filterType);
    filesStore.currentPath.set(newState.currentPath);

    if (typeof localStorage !== 'undefined') {
      localStorage.setItem('cc_current_route', newState.route);
      localStorage.setItem('cc_current_scope', newState.scope);
      localStorage.setItem('cc_current_filter', newState.filterType);
      localStorage.setItem('cc_current_path', newState.currentPath);
    }

    if (newState.route === 'files') {
      filesStore.loadDirectory();
    }

    if (typeof window !== 'undefined') {
      const targetUrl = getUrlForState(newState.route, newState.scope, newState.filterType, newState.currentPath);
      const stateObj = {
        url: targetUrl,
        route: newState.route,
        scope: newState.scope,
        filterType: newState.filterType,
        currentPath: newState.currentPath
      };

      if (pushToHistory) {
        if (window.location.pathname !== targetUrl) {
          window.history.pushState(stateObj, '', targetUrl);
        } else {
          window.history.replaceState(stateObj, '', targetUrl);
        }
      } else {
        window.history.replaceState(stateObj, '', targetUrl);
      }
    }
  }

  onMount(() => {
    applyStateFromPath(window.location.pathname, false);

    const handlePopState = (e) => {
      const targetPath = (e && e.state && e.state.url)
        ? e.state.url
        : window.location.pathname;
      applyStateFromPath(targetPath, false);
    };

    window.addEventListener('popstate', handlePopState);

    if (get(authStore.isAuthenticated)) {
      refreshStats();
    }

    return () => {
      window.removeEventListener('popstate', handlePopState);
    };
  });

  // Automatically refresh directories when uploads/downloads complete
  let prevActiveCount = 0;
  let autoClearTransfersTimeout;
  activeCount.subscribe((count) => {
    if (prevActiveCount > 0 && count === 0) {
      if (currentRoute === 'files') {
        filesStore.loadDirectory();
      }
      showToast('All active file transfers completed successfully.', 'success');
      
      // Auto-clear completed items and close drawer after 4 seconds
      clearTimeout(autoClearTransfersTimeout);
      autoClearTransfersTimeout = setTimeout(() => {
        transfersStore.clearCompleted();
        transfersStore.isDrawerOpen.set(false);
      }, 4000);
    } else if (count > 0) {
      clearTimeout(autoClearTransfersTimeout);
    }
    prevActiveCount = count;
  });

  // Reactive sync of body class for theme
  $: if (typeof document !== 'undefined' && $appTheme) {
    document.body.className = `theme-${$appTheme}`;
  }

  function toggleTheme() {
    themeState.toggleTheme();
  }

  function handleToggleLayout() {
    layoutMode = layoutMode === 'grid' ? 'list' : 'grid';
    if (typeof localStorage !== 'undefined') {
      localStorage.setItem('cc_layout_mode', layoutMode);
    }
  }

  function handleSidebarNavigate(event) {
    const { route, filterType: newFilter, scope: newScope } = event.detail;
    const targetUrl = getUrlForState(route, newScope || 'private', newFilter || 'all', '');
    applyStateFromPath(targetUrl, true);
  }

  function handleNavigate(path) {
    const targetUrl = $scope === 'shared'
      ? (path ? `/shared/browse/${encodeSubpath(path)}` : '/shared')
      : (path ? `/files/browse/${encodeSubpath(path)}` : '/files');
    applyStateFromPath(targetUrl, true);
  }

  function handleSelect(item) {
    filesStore.toggleSelection(item.path, true);
  }

  function handleOpenItem(item) {
    if (item.is_dir) {
      handleNavigate(item.path);
    } else {
      activePreviewFile = item;
    }
  }

  function handleGlobalFileSelection(e) {
    if (!e.target || !e.target.files || e.target.files.length === 0) return;
    const fileList = Array.from(e.target.files);
    const filesToUpload = fileList.map((file) => ({
      file,
      path: file.name
    }));
    transfersStore.enqueueBatch(filesToUpload, $scope, $currentPath);
    e.target.value = '';
  }

  function handleUploadFiles(event) {
    const files = event.detail; // Array of { file, path }
    if (!files || files.length === 0) return;
    transfersStore.enqueueBatch(files, $scope, $currentPath);
  }

  function handleContextMenu(event) {
    const { x, y, item } = event.detail;
    contextMenu = { x, y, item };
  }

  async function handleContextMenuAction(event) {
    const { type, item } = event.detail;
    contextMenu = null;

    if (type === 'preview') {
      if (item) handleOpenItem(item);
    } else if (type === 'download') {
      if (item) {
        if (item.is_dir) {
          handleDownloadZip(item);
        } else {
          try {
            await filesApi.downloadFile({ scope: $scope, path: item.path, filename: item.name });
            showToast(`Started downloading ${item.name}`, 'success');
          } catch (err) {
            showToast(err.message || 'Failed to download file', 'error');
          }
        }
      }
    } else if (type === 'downloadZip') {
      if (item) handleDownloadZip(item);
    } else if (type === 'toggleServerShared') {
      if (item) handleToggleServerShared(item);
    } else if (type === 'share') {
      if (item) handleShareItem(item);
    } else if (type === 'rename') {
      if (item) {
        renameModal = { file: item, newName: item.name };
      }
    } else if (type === 'move') {
      if (item) {
        folderPickerTargetItems = [item];
        isFolderPickerOpen = true;
      }
    } else if (type === 'delete') {
      if (item) {
        try {
          await filesApi.deleteFile({ scope: $scope, path: item.path });
          showToast(`Moved ${item.name} to trash.`, 'success');
          filesStore.loadDirectory();
          refreshStats();
        } catch (err) {
          showToast(err.message || 'Failed to delete item', 'error');
        }
      }
    } else if (type === 'refresh') {
      filesStore.loadDirectory();
      refreshStats();
    } else if (type === 'newFolder') {
      openNewFolderModal();
    }
  }

  function openNewFolderModal() {
    newFolderName = '';
    newFolderModal = true;
  }

  async function handleCreateFolderSubmit() {
    const name = newFolderName.trim();
    newFolderModal = false;
    if (!name) return;
    const targetPath = $currentPath ? `${$currentPath}/${name}` : name;
    try {
      await filesApi.createFolder({ scope: $scope, path: targetPath });
      showToast(`Created folder "${name}"`, 'success');
      filesStore.loadDirectory();
    } catch (err) {
      showToast(err.message || 'Failed to create folder', 'error');
    }
  }

  async function handleDownloadZip(item) {
    try {
      showToast(`Preparing ZIP archive for ${item ? item.name : 'folder'}...`, 'info');
      await filesApi.downloadZip({
        scope: $scope,
        path: item ? item.path : '',
        filename: item ? `${item.name}.zip` : 'folder.zip'
      });
      showToast('ZIP archive downloaded successfully', 'success');
    } catch (err) {
      showToast(err.message || 'Failed to download ZIP archive', 'error');
    }
  }

  async function handleToggleServerShared(item) {
    try {
      const nextState = !item.is_shared;
      await filesApi.toggleServerShared({ path: item.path, isShared: nextState });
      showToast(nextState ? `Shared "${item.name}" in server` : `Unshared "${item.name}" in server`, 'success');
      filesStore.loadDirectory();
    } catch (err) {
      showToast(err.message || 'Failed to update server share status', 'error');
    }
  }

  async function handleShareItem(item) {
    try {
      const res = await shareApi.createShare({ scope: $scope, path: item.path });
      const host = window.location.origin;
      const shareUrl = `${host}/s/${res.token}`;
      shareModal = { file: item, url: shareUrl };
    } catch (err) {
      showToast(err.message || 'Failed to generate share link', 'error');
    }
  }

  function copyShareUrl() {
    if (!shareModal) return;
    navigator.clipboard.writeText(shareModal.url);
    showToast('Public link copied to clipboard!', 'success');
    shareModal = null;
  }

  async function handleRenameSubmit() {
    if (!renameModal) return;
    const { file, newName } = renameModal;
    const trimmed = newName.trim();
    renameModal = null;
    if (!trimmed || trimmed === file.name) return;

    try {
      await filesApi.renameFile({ scope: $scope, path: file.path, newName: trimmed });
      showToast(`Renamed ${file.name} to ${trimmed}.`, 'success');
      filesStore.loadDirectory();
    } catch (err) {
      showToast(err.message || 'Failed to rename item', 'error');
    }
  }

  function handleOpenMoveSelected() {
    const selectedPathsArray = Array.from($selectedPaths);
    folderPickerTargetItems = $entries.filter((item) => selectedPathsArray.includes(item.path));
    isFolderPickerOpen = true;
  }

  async function handleMoveConfirm(event) {
    const destFolder = event.detail; // path string
    isFolderPickerOpen = false;
    
    // Determine if we are moving the single context-menu item or batch selected items
    const selectedPathsArray = Array.from($selectedPaths);
    const targetPaths = folderPickerTargetItems.map(item => item.path);
    const isMovingBatch = targetPaths.every(path => selectedPathsArray.includes(path)) && selectedPathsArray.length > 0;

    try {
      if (isMovingBatch) {
        await filesStore.moveSelected(destFolder);
        showToast(`Moved ${targetPaths.length} items to "${destFolder || 'Root'}"`, 'success');
      } else {
        // Move single context menu item
        const singleItem = folderPickerTargetItems[0];
        if (singleItem) {
          await filesApi.moveFile({ scope: $scope, srcPath: singleItem.path, destFolder });
          showToast(`Moved "${singleItem.name}" to "${destFolder || 'Root'}"`, 'success');
          filesStore.loadDirectory();
        }
      }
    } catch (err) {
      showToast(err.message || 'Failed to move items', 'error');
    }
  }

  function handleMoveItems(event) {
    const { paths, destFolder } = event.detail || {};
    if (!paths || paths.length === 0) return;

    // Filter out invalid moves (item into its current folder or folder into itself/subfolder)
    const validPaths = paths.filter((srcPath) => {
      const currentParent = srcPath.includes('/') ? srcPath.substring(0, srcPath.lastIndexOf('/')) : '';
      if (currentParent === destFolder) return false;
      if (srcPath === destFolder || destFolder.startsWith(srcPath + '/')) return false;
      return true;
    });

    if (validPaths.length === 0) {
      showToast('Items are already in the target folder.', 'info');
      return;
    }

    const currentParent = $currentPath;
    const isMovingUp = destFolder === (currentParent.includes('/') ? currentParent.substring(0, currentParent.lastIndexOf('/')) : '');
    let targetName = 'Root';
    if (isMovingUp && currentParent !== '') {
      targetName = 'Parent Folder';
    } else if (destFolder) {
      targetName = destFolder.split('/').pop();
    }

    confirmMoveModal = { validPaths, destFolder, targetName };
  }

  async function executeConfirmedMove() {
    if (!confirmMoveModal) return;
    const { validPaths, destFolder, targetName } = confirmMoveModal;
    confirmMoveModal = null;

    let successCount = 0;
    let failCount = 0;
    let lastError = '';
    for (const srcPath of validPaths) {
      try {
        await filesApi.moveFile({ scope: $scope, srcPath, destFolder });
        successCount++;
      } catch (err) {
        console.error(`Failed to move ${srcPath}:`, err);
        lastError = err.message || '';
        failCount++;
      }
    }

    filesStore.clearSelection();
    if (failCount === 0) {
      showToast(`Moved ${successCount} item${successCount > 1 ? 's' : ''} to "${targetName}"`, 'success');
    } else if (successCount > 0) {
      showToast(`Moved ${successCount} items, ${failCount} failed: ${lastError}`, 'info');
    } else {
      showToast(lastError ? `Failed to move items: ${lastError}` : 'Failed to move items.', 'error');
    }
    await filesStore.loadDirectory();
  }

  async function handleBatchDownload() {
    const selectedPathsArray = Array.from($selectedPaths);
    const selectedEntries = $entries.filter((item) => selectedPathsArray.includes(item.path));
    if (selectedEntries.length === 0) return;

    filesStore.clearSelection();

    const filesToDownload = selectedEntries.filter((item) => !item.is_dir);
    const foldersToDownload = selectedEntries.filter((item) => item.is_dir);

    if (filesToDownload.length > 0) {
      showToast(`Starting batch download of ${filesToDownload.length} files...`, 'success');
      for (const item of filesToDownload) {
        try {
          await filesApi.downloadFile({ scope: $scope, path: item.path, filename: item.name });
        } catch (err) {
          console.error(`Failed to download ${item.name}:`, err);
        }
      }
    }

    for (const folder of foldersToDownload) {
      await handleDownloadZip(folder);
    }
  }

  async function handleBatchShare() {
    const selectedPathsArray = Array.from($selectedPaths);
    const selectedEntries = $entries.filter((item) => selectedPathsArray.includes(item.path));
    if (selectedEntries.length === 0) return;

    filesStore.clearSelection();
    showToast(`Sharing ${selectedEntries.length} items in server...`, 'info');
    let successCount = 0;
    for (const item of selectedEntries) {
      try {
        await filesApi.toggleServerShared({ path: item.path, isShared: true });
        successCount++;
      } catch (err) {
        console.error(`Failed to share ${item.name}:`, err);
      }
    }
    if (successCount > 0) {
      showToast(`Shared ${successCount} items in server.`, 'success');
      filesStore.loadDirectory();
      refreshStats();
    }
  }

  async function handleBatchUnshare() {
    const selectedPathsArray = Array.from($selectedPaths);
    const selectedEntries = $entries.filter((item) => selectedPathsArray.includes(item.path) && item.is_owner !== false);
    if (selectedEntries.length === 0) {
      showToast('You can only unshare items that you own.', 'info');
      return;
    }

    filesStore.clearSelection();
    showToast(`Unsharing ${selectedEntries.length} items...`, 'info');
    let successCount = 0;
    for (const item of selectedEntries) {
      try {
        await filesApi.toggleServerShared({ path: item.path, isShared: false });
        successCount++;
      } catch (err) {
        console.error(`Failed to unshare ${item.name}:`, err);
      }
    }
    if (successCount > 0) {
      showToast(`Unshared ${successCount} items from server.`, 'success');
      filesStore.loadDirectory();
      refreshStats();
    }
  }

  function triggerGlobalUpload() {
    if (globalFileInput) {
      globalFileInput.click();
    }
  }
</script>

<div class="app-container">
  <!-- Hidden Global Upload Selector -->
  <input
    type="file"
    multiple
    bind:this={globalFileInput}
    on:change={handleGlobalFileSelection}
    style="display: none;"
  />

  <Sidebar
    {currentRoute}
    filterType={$filterType}
    scope={$scope}
    on:navigate={handleSidebarNavigate}
    on:uploadTrigger={triggerGlobalUpload}
  />

  <!-- Mobile Sidebar Backdrop Overlay -->
  <!-- svelte-ignore a11y-click-events-have-key-events -->
  <!-- svelte-ignore a11y-no-static-element-interactions -->
  <div class="sidebar-mobile-backdrop" on:click={closeMobileSidebar}></div>

  <div class="main-canvas">
    <HeaderBar
      searchQuery={$searchQuery}
      layoutMode={layoutMode}
      sortBy={$sortOption.field}
      sortOrder={$sortOption.order}
      currentTheme={$appTheme}
      isAuthenticated={$isAuthenticated}
      {currentRoute}
      on:toggleTheme={toggleTheme}
      on:toggleLayout={handleToggleLayout}
      on:toggleRoute={(e) => applyStateFromPath(getUrlForState(e.detail, 'private', 'all', ''), true)}
      on:openAuth={() => (isAuthOpen = true)}
      on:search={(e) => {
        const val = e.detail;
        searchQuery.set(val);
        if (val && currentRoute !== 'files' && currentRoute !== 'trash') {
          applyStateFromPath('/files', true);
        } else if (currentRoute === 'files') {
          filesStore.loadDirectory();
        }
      }}
      on:changeSort={(e) => {
        sortOption.update((s) => ({ ...s, field: e.detail }));
        filesStore.loadDirectory();
      }}
      on:toggleSortOrder={() => {
        sortOption.update((s) => ({ ...s, order: s.order === 'asc' ? 'desc' : 'asc' }));
        filesStore.loadDirectory();
      }}
    />

    {#if currentRoute === 'dashboard'}
      <main class="main-content">
        <Dashboard
          on:navigate={handleSidebarNavigate}
          on:uploadFiles={handleUploadFiles}
        />
      </main>
    {:else if currentRoute === 'files'}
      {#if $filterType === 'all'}
        <BreadcrumbBar
          path={$currentPath}
          on:navigate={(e) => handleNavigate(e.detail)}
        />
      {/if}

      <!-- Extended FAB for Folder Creation in bottom-right corner -->
      <button
        class="floating-action-btn"
        title="Create New Folder"
        on:click={openNewFolderModal}
      >
        <span class="material-symbols-outlined" style="margin-right: 8px;">create_new_folder</span>
        <span>New Folder</span>
      </button>

      <main class="main-content">
        {#if $error}
          <div class="error-banner text-sub">{$error}</div>
        {/if}

        {#if $isLoading}
          <div class="loading-state text-sub">Loading files...</div>
        {:else if layoutMode === 'grid'}
          <FileGrid
            items={$entries}
            selectedItems={$selectedPaths}
            scope={$scope}
            filterType={$filterType}
            currentPath={$currentPath}
            searchQuery={$searchQuery}
            on:select={(e) => handleSelect(e.detail)}
            on:open={(e) => handleOpenItem(e.detail)}
            on:uploadFiles={handleUploadFiles}
            on:contextmenu={handleContextMenu}
            on:moveItems={handleMoveItems}
          />
        {:else}
          <FileList
            items={$entries}
            selectedItems={$selectedPaths}
            filterType={$filterType}
            scope={$scope}
            currentPath={$currentPath}
            searchQuery={$searchQuery}
            on:select={(e) => handleSelect(e.detail)}
            on:open={(e) => handleOpenItem(e.detail)}
            on:uploadFiles={handleUploadFiles}
            on:contextmenu={handleContextMenu}
            on:selectAll={() => filesStore.selectAll()}
            on:clearSelection={() => filesStore.clearSelection()}
            on:moveItems={handleMoveItems}
          />
        {/if}
      </main>

      <SelectionActionBar
        selectedCount={$selectedPaths.size}
        selectedPaths={$selectedPaths}
        currentScope={$scope}
        shiftUp={$transfersQueue.length > 0}
        on:clear={() => filesStore.clearSelection()}
        on:downloadSelected={handleBatchDownload}
        on:shareSelected={handleBatchShare}
        on:moveSelected={handleOpenMoveSelected}
        on:deleteSelected={() => filesStore.deleteSelected()}
        on:unshareSelected={handleBatchUnshare}
      />
    {:else if currentRoute === 'trash'}
      <main class="main-content">
        <TrashBrowser
          scope={$scope}
          searchQuery={$searchQuery}
          layoutMode={layoutMode}
          sortBy={$sortOption.field}
          sortOrder={$sortOption.order}
          on:back={() => applyStateFromPath('/files', true)}
          on:toast={handleToastEvent}
        />
      </main>
    {:else if currentRoute === 'settings'}
      <main class="main-content">
        <Settings on:toast={handleToastEvent} />
      </main>
    {/if}
  </div>

  <!-- Transfer Bottom Bar & Progress Drawer -->
  <TransferBottomBar />
  <TransferProgressDrawer />

  <!-- Context Menu Floating Overlay -->
  {#if contextMenu}
    <ContextMenu
      x={contextMenu.x}
      y={contextMenu.y}
      item={contextMenu.item}
      selectedCount={$selectedPaths.size}
      currentScope={$scope}
      on:close={() => (contextMenu = null)}
      on:action={handleContextMenuAction}
    />
  {/if}

  <!-- Folder Picker for Moving Items -->
  {#if isFolderPickerOpen}
    <FolderPickerModal
      items={$entries}
      scope={$scope}
      targetItems={folderPickerTargetItems}
      on:close={() => (isFolderPickerOpen = false)}
      on:confirm={handleMoveConfirm}
    />
  {/if}

  <!-- Media Preview Modal -->
  {#if activePreviewFile}
    <MediaPreviewModal
      file={activePreviewFile}
      scope={$scope}
      on:close={() => (activePreviewFile = null)}
    />
  {/if}

  <!-- Auth Dialog Modal -->
  {#if isAuthOpen}
    <AuthModal
      on:close={() => (isAuthOpen = false)}
      on:success={(e) => {
        authStore.setSession(e.detail);
        isAuthOpen = false;
        filesStore.loadDirectory();
        showToast('Logged in successfully!', 'success');
      }}
      on:authenticated={(e) => {
        authStore.setSession(e.detail);
        isAuthOpen = false;
        filesStore.loadDirectory();
        showToast('Logged in successfully!', 'success');
      }}
    />
  {/if}

  <!-- Share Link Dialog Modal -->
  {#if shareModal}
    <div class="modal-backdrop" on:click|self={() => (shareModal = null)}>
      <div class="dialog-card">
        <h3 class="text-title">Share Link Created</h3>
        <p class="text-sub">Public download link for {shareModal.file.name}:</p>
        <input type="text" class="form-input text-code" readonly value={shareModal.url} />
        <div class="dialog-actions">
          <button class="btn btn-secondary" on:click={() => (shareModal = null)}>Close</button>
          <button class="btn btn-primary" on:click={copyShareUrl}>📋 Copy Link</button>
        </div>
      </div>
    </div>
  {/if}

  <!-- Rename Modal -->
  {#if renameModal}
    <div class="modal-backdrop" on:click|self={() => (renameModal = null)}>
      <div class="dialog-card">
        <h3 class="text-title">Rename Item</h3>
        <input
          type="text"
          class="form-input text-body"
          bind:value={renameModal.newName}
          on:keydown={(e) => e.key === 'Enter' && handleRenameSubmit()}
        />
        <div class="dialog-actions">
          <button class="btn btn-secondary" on:click={() => (renameModal = null)}>Cancel</button>
          <button class="btn btn-primary" on:click={handleRenameSubmit}>Rename</button>
        </div>
      </div>
    </div>
  {/if}

  <!-- New Folder Modal -->
  {#if newFolderModal}
    <div class="modal-backdrop" on:click|self={() => (newFolderModal = false)}>
      <div class="dialog-card">
        <h3 class="text-title">Create Folder</h3>
        <input
          type="text"
          class="form-input text-body"
          placeholder="New folder name"
          bind:value={newFolderName}
          on:keydown={(e) => e.key === 'Enter' && handleCreateFolderSubmit()}
        />
        <div class="dialog-actions">
          <button class="btn btn-secondary" on:click={() => (newFolderModal = false)}>Cancel</button>
          <button class="btn btn-primary" on:click={handleCreateFolderSubmit}>Create</button>
        </div>
      </div>
    </div>
  {/if}

  <!-- Confirm Drag-to-Move Modal -->
  {#if confirmMoveModal}
    <div class="modal-backdrop" on:click|self={() => (confirmMoveModal = null)}>
      <div class="dialog-card">
        <h3 class="text-title" style="margin: 0; color: var(--text-main); font-weight: 700;">Move Items</h3>
        <p class="text-sub" style="margin: 0; line-height: 1.5;">
          Are you sure you want to move {confirmMoveModal.validPaths.length === 1 ? `"${confirmMoveModal.validPaths[0].split('/').pop()}"` : `${confirmMoveModal.validPaths.length} items`} to <strong>"{confirmMoveModal.targetName}"</strong>?
        </p>
        <div class="dialog-actions" style="margin-top: 8px;">
          <button class="btn btn-secondary" on:click={() => (confirmMoveModal = null)}>Cancel</button>
          <button class="btn btn-primary" on:click={executeConfirmedMove}>Move</button>
        </div>
      </div>
    </div>
  {/if}

  <!-- Global Application Toast notification banner -->
  {#if toastMessage}
    <div class="toast-notification {toastType} text-body">
      <span class="material-symbols-outlined toast-icon">
        {toastType === 'success' ? 'check_circle' : toastType === 'error' ? 'error' : 'info'}
      </span>
      <span>{toastMessage}</span>
    </div>
  {/if}
</div>

<style>
  .app-container {
    display: flex;
    min-height: 100vh;
    width: 100vw;
    overflow: hidden;
    background-color: var(--bg-background);
  }

  .main-canvas {
    flex: 1;
    display: flex;
    flex-direction: column;
    height: 100vh;
    overflow: hidden;
    position: relative;
  }

  .main-content {
    flex: 1;
    overflow-y: auto;
    display: flex;
    flex-direction: column;
    position: relative;
  }

  .error-banner {
    padding: var(--spacing-sm) var(--spacing-lg);
    background-color: rgba(255, 82, 82, 0.15);
    color: var(--color-danger);
  }

  .loading-state {
    text-align: center;
    padding: 64px;
  }

  .dialog-card {
    width: 100%;
    max-width: 440px;
    background-color: var(--bg-surface);
    border-radius: var(--radius-xl);
    border: 1px solid var(--border-color);
    box-shadow: var(--shadow-card);
    padding: var(--spacing-xl);
    display: flex;
    flex-direction: column;
    gap: var(--spacing-md);
  }

  .dialog-actions {
    display: flex;
    justify-content: flex-end;
    gap: var(--spacing-sm);
  }

  .floating-action-btn {
    position: fixed;
    bottom: 24px;
    right: 24px;
    height: 56px;
    border-radius: var(--radius-full);
    background-color: var(--accent-color);
    color: #FFFFFF;
    border: none;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    z-index: 45;
    padding: 0 24px;
    font-weight: 700;
    font-size: 14px;
    transition: transform 0.15s ease, background-color 0.15s ease;
  }

  .floating-action-btn:hover {
    transform: scale(1.05);
    background-color: var(--accent-hover);
  }

  .floating-action-btn .material-symbols-outlined {
    font-size: 20px;
  }

  /* Global Toast Notifications */
  .toast-notification {
    position: fixed;
    top: 24px;
    left: 50%;
    transform: translateX(-50%);
    z-index: 1500;
    display: flex;
    align-items: center;
    gap: var(--spacing-sm);
    background-color: var(--bg-surface);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-full);
    padding: 10px 24px;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
    backdrop-filter: blur(8px);
    font-weight: 600;
    color: var(--text-main);
    animation: toastSlideDown 0.25s ease-out;
  }

  .toast-icon {
    font-size: 20px;
  }

  .toast-notification.success .toast-icon {
    color: var(--color-success);
  }

  .toast-notification.error .toast-icon {
    color: var(--color-danger);
  }

  .toast-notification.info .toast-icon {
    color: #339af0;
  }

  @keyframes toastSlideDown {
    from {
      transform: translate(-50%, -24px);
      opacity: 0;
    }
    to {
      transform: translate(-50%, 0);
      opacity: 1;
    }
  }
</style>
