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
  import { onMount } from 'svelte';
  import { get } from 'svelte/store';
  import HeaderBar from './components/HeaderBar.svelte';
  import Sidebar from './components/Sidebar.svelte';
  import BreadcrumbBar from './components/BreadcrumbBar.svelte';
  import FileGrid from './components/FileGrid.svelte';
  import FileList from './components/FileList.svelte';
  import AuthModal from './components/AuthModal.svelte';
  import FolderPickerModal from './components/FolderPickerModal.svelte';
  import UploadConflictModal from './components/UploadConflictModal.svelte';
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
  import { t, i18n } from './stores/i18n.js';

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
  let confirmDeleteModal = null; // { paths, itemName, count }

  // Share Link Modal State
  let shareModal = null; // { file, url }
  let renameModal = null; // { file, newName }
  let uploadConflictModal = null; // { conflicts, nonConflicts }

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

  // Automatically refresh directories silently while transfers are active
  let prevActiveCount = 0;
  let autoClearTransfersTimeout;
  let activeRefreshInterval;

  activeCount.subscribe((count) => {
    if (count > 0) {
      clearTimeout(autoClearTransfersTimeout);
      if (!activeRefreshInterval) {
        activeRefreshInterval = setInterval(() => {
          if (currentRoute === 'files') {
            filesStore.loadDirectory(true);
          }
        }, 1500);
      }
    } else {
      if (activeRefreshInterval) {
        clearInterval(activeRefreshInterval);
        activeRefreshInterval = null;
      }
      if (prevActiveCount > 0) {
        if (currentRoute === 'files') {
          filesStore.loadDirectory(true);
        }

        const q = get(transfersStore.queue) || [];
        const hasPaused = q.some((t) => t.status === 'paused');
        const hasCancelled = q.some((t) => t.status === 'cancelled');
        const allCompleted = q.length > 0 && q.every((t) => t.status === 'completed');

        if (hasPaused) {
          showToast(i18n.format('toasts.transfers_paused'), 'info');
        } else {
          if (hasCancelled && !allCompleted) {
            showToast(i18n.format('toasts.transfers_cancelled'), 'warning');
          } else if (allCompleted) {
            showToast(i18n.format('toasts.transfers_done'), 'success');
          }

          // Auto-clear finished/cancelled items and close drawer/island after 4 seconds
          clearTimeout(autoClearTransfersTimeout);
          autoClearTransfersTimeout = setTimeout(() => {
            transfersStore.clearCompleted();
            transfersStore.isDrawerOpen.set(false);
          }, 4000);
        }
      }
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

  function processUploadQueue(payload) {
    let filesToUpload = [];
    if (Array.isArray(payload)) {
      filesToUpload = payload.map((item) => {
        if (typeof File !== 'undefined' && item instanceof File) {
          return { file: item, path: item.name };
        }
        return { file: item.file || item, path: item.path || (item.file ? item.file.name : item.name) };
      });
    } else if (payload && payload.files && Array.isArray(payload.files)) {
      filesToUpload = payload.files.map((file) => ({
        file,
        path: file.name
      }));
    } else if (payload && (payload.file || payload.name)) {
      filesToUpload = [{ file: payload.file || payload, path: payload.path || payload.name }];
    }

    if (filesToUpload.length === 0) return;

    // Create lookup map of existing items in the current directory
    const existingMap = new Map();
    for (const item of ($entries || [])) {
      if (item.name) {
        existingMap.set(item.name, item);
      }
      if (item.path) {
        existingMap.set(item.path, item);
      }
    }

    const conflicts = [];
    const nonConflicts = [];

    for (const uploadItem of filesToUpload) {
      const topSegment = uploadItem.path ? uploadItem.path.split('/')[0] : (uploadItem.file ? uploadItem.file.name : '');
      const directMatch = existingMap.get(uploadItem.path) || (uploadItem.file && existingMap.get(uploadItem.file.name)) || existingMap.get(topSegment);

      if (directMatch) {
        conflicts.push({
          file: uploadItem.file,
          path: uploadItem.path,
          name: (uploadItem.file && uploadItem.file.name) || topSegment,
          size: uploadItem.file ? uploadItem.file.size : 0,
          existing: directMatch
        });
      } else {
        nonConflicts.push(uploadItem);
      }
    }

    if (conflicts.length > 0) {
      uploadConflictModal = { conflicts, nonConflicts };
    } else {
      transfersStore.enqueueBatch(filesToUpload, $scope, $currentPath);
    }
  }

  function handleGlobalFileSelection(e) {
    if (!e.target || !e.target.files || e.target.files.length === 0) return;
    const fileList = Array.from(e.target.files);
    const filesToUpload = fileList.map((file) => ({
      file,
      path: file.name
    }));
    processUploadQueue(filesToUpload);
    e.target.value = '';
  }

  function handleUploadFiles(event) {
    const files = event.detail; // Array of { file, path } or { files: [...] }
    if (!files) return;
    processUploadQueue(files);
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
            showToast(i18n.format('toasts.download_started', { name: item.name }), 'success');
          } catch (err) {
            showToast(err.message || i18n.format('toasts.download_failed'), 'error');
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
        requestDelete([item.path], item.name);
      } else if ($selectedPaths.size > 0) {
        requestDelete(Array.from($selectedPaths));
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
      showToast(i18n.format('toasts.folder_created_named', { name }), 'success');
      filesStore.loadDirectory();
    } catch (err) {
      showToast(err.message || i18n.format('toasts.folder_create_failed'), 'error');
    }
  }

  async function handleDownloadZip(item) {
    try {
      showToast(i18n.format('toasts.zip_preparing', { name: item ? item.name : i18n.format('common.folder') }), 'info');
      await filesApi.downloadZip({
        scope: $scope,
        path: item ? item.path : '',
        filename: item ? `${item.name}.zip` : 'folder.zip'
      });
      showToast(i18n.format('toasts.zip_downloaded'), 'success');
    } catch (err) {
      showToast(err.message || i18n.format('toasts.zip_download_failed'), 'error');
    }
  }

  async function handleToggleServerShared(item) {
    try {
      const nextState = !item.is_shared;
      await filesApi.toggleServerShared({ path: item.path, isShared: nextState });
      showToast(nextState ? i18n.format('toasts.shared_named', { name: item.name }) : i18n.format('toasts.unshared_named', { name: item.name }), 'success');
      filesStore.loadDirectory();
    } catch (err) {
      showToast(err.message || i18n.format('toasts.share_status_failed'), 'error');
    }
  }

  async function handleShareItem(item) {
    try {
      const res = await shareApi.createShare({ scope: $scope, path: item.path });
      const host = window.location.origin;
      const shareUrl = `${host}/s/${res.token}`;
      shareModal = { file: item, url: shareUrl };
    } catch (err) {
      showToast(err.message || i18n.format('toasts.share_link_failed'), 'error');
    }
  }

  function copyShareUrl() {
    if (!shareModal) return;
    navigator.clipboard.writeText(shareModal.url);
    showToast(i18n.format('toasts.copied_link'), 'success');
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
      showToast(i18n.format('toasts.renamed_named', { oldName: file.name, newName: trimmed }), 'success');
      filesStore.loadDirectory();
    } catch (err) {
      showToast(err.message || i18n.format('toasts.rename_failed'), 'error');
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
        showToast(i18n.format('toasts.items_moved_to', { count: targetPaths.length, dest: destFolder || i18n.format('common.root') }), 'success');
      } else {
        // Move single context menu item
        const singleItem = folderPickerTargetItems[0];
        if (singleItem) {
          await filesApi.moveFile({ scope: $scope, srcPath: singleItem.path, destFolder });
          showToast(i18n.format('toasts.item_moved_to', { name: singleItem.name, dest: destFolder || i18n.format('common.root') }), 'success');
          filesStore.loadDirectory();
        }
      }
    } catch (err) {
      showToast(err.message || i18n.format('toasts.move_failed'), 'error');
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
      showToast(i18n.format('toasts.already_in_target'), 'info');
      return;
    }

    const currentParent = $currentPath;
    const isMovingUp = destFolder === (currentParent.includes('/') ? currentParent.substring(0, currentParent.lastIndexOf('/')) : '');
    let targetName = i18n.format('common.root');
    if (isMovingUp && currentParent !== '') {
      targetName = i18n.format('files.parent_folder');
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
      showToast(i18n.format('toasts.items_moved_to_named', { count: successCount, dest: targetName }), 'success');
    } else if (successCount > 0) {
      showToast(i18n.format('toasts.items_moved_to_named', { count: successCount, dest: targetName }), 'info');
    } else {
      showToast(lastError ? `${i18n.format('toasts.move_failed')}: ${lastError}` : i18n.format('toasts.move_failed'), 'error');
    }
    await filesStore.loadDirectory();
  }

  function requestDelete(paths, itemName = null) {
    if (!paths || paths.length === 0) return;
    confirmDeleteModal = {
      paths,
      itemName: itemName || (paths.length === 1 ? paths[0].split('/').pop() : null),
      count: paths.length
    };
  }

  async function executeConfirmedDelete() {
    if (!confirmDeleteModal) return;
    const { paths, itemName, count } = confirmDeleteModal;
    confirmDeleteModal = null;

    try {
      const res = await filesApi.deleteFiles({ scope: $scope, paths });
      filesStore.clearSelection();
      await filesStore.loadDirectory();
      refreshStats();

      if (count === 1 && itemName) {
        if (res && res.failed > 0) {
          showToast(i18n.format('toasts.item_delete_failed'), 'error');
        } else {
          showToast(i18n.format('toasts.item_moved_to_trash', { name: itemName }), 'success');
        }
      } else {
        const deleted = res?.deleted ?? (count - (res?.failed ?? 0));
        const failed = res?.failed ?? 0;
        if (failed === 0) {
          showToast(i18n.format('toasts.batch_deleted_summary', { count: deleted, deleted }), 'success');
        } else if (deleted > 0) {
          showToast(i18n.format('toasts.batch_deleted_partial', { deleted, failed }), 'warning');
        } else {
          showToast(i18n.format('toasts.batch_deleted_all_failed', { count: failed, failed }), 'error');
        }
      }
    } catch (err) {
      showToast(err.message || i18n.format('toasts.item_delete_failed'), 'error');
    }
  }

  async function handleBatchDownload() {
    const selectedPathsArray = Array.from($selectedPaths);
    const selectedEntries = $entries.filter((item) => selectedPathsArray.includes(item.path));
    if (selectedEntries.length === 0) return;

    filesStore.clearSelection();

    const filesToDownload = selectedEntries.filter((item) => !item.is_dir);
    const foldersToDownload = selectedEntries.filter((item) => item.is_dir);

    if (filesToDownload.length > 0) {
      showToast(i18n.format('toasts.batch_download_started', { count: filesToDownload.length }), 'success');
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
    showToast(i18n.format('toasts.batch_sharing', { count: selectedEntries.length }), 'info');
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
      showToast(i18n.format('toasts.batch_shared', { count: successCount }), 'success');
      filesStore.loadDirectory();
      refreshStats();
    }
  }

  async function handleBatchUnshare() {
    const selectedPathsArray = Array.from($selectedPaths);
    const selectedEntries = $entries.filter((item) => selectedPathsArray.includes(item.path) && item.is_owner !== false);
    if (selectedEntries.length === 0) {
      showToast(i18n.format('toasts.unshare_only_owned'), 'info');
      return;
    }

    filesStore.clearSelection();
    showToast(i18n.format('toasts.batch_unsharing', { count: selectedEntries.length }), 'info');
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
      showToast(i18n.format('toasts.batch_unshared', { count: successCount }), 'success');
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
      {#if $scope !== 'shared'}
        <button
          class="floating-action-btn"
          title={$t('modals.create_folder.title')}
          on:click={openNewFolderModal}
        >
          <span class="material-symbols-outlined" style="margin-right: 8px;">create_new_folder</span>
          <span>{$t('files.create_new_folder')}</span>
        </button>
      {/if}

      <main class="main-content">
        {#if $error}
          <div class="error-banner text-sub">{$error}</div>
        {/if}

        {#if $isLoading}
          <div class="loading-state text-sub">{$t('common.loading')}</div>
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
        on:deleteSelected={() => requestDelete(Array.from($selectedPaths))}
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
      items={$entries.filter((e) => !e.is_dir)}
      scope={$scope}
      on:close={() => (activePreviewFile = null)}
      on:changeItem={(e) => (activePreviewFile = e.detail)}
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
        showToast(i18n.format('modals.auth.login_success'), 'success');
      }}
      on:authenticated={(e) => {
        authStore.setSession(e.detail);
        isAuthOpen = false;
        filesStore.loadDirectory();
        showToast(i18n.format('modals.auth.login_success'), 'success');
      }}
    />
  {/if}

  <!-- Share Link Dialog Modal -->
  {#if shareModal}
    <div class="modal-backdrop" on:click|self={() => (shareModal = null)}>
      <div class="dialog-card">
        <h3 class="text-title">{$t('modals.share.title')}</h3>
        <p class="text-sub">{$t('modals.share.subtitle')}: {shareModal.file.name}</p>
        <input type="text" class="form-input text-code" readonly value={shareModal.url} />
        <div class="dialog-actions">
          <button class="btn btn-secondary" on:click={() => (shareModal = null)}>{$t('common.close')}</button>
          <button class="btn btn-primary" on:click={copyShareUrl}>📋 {$t('modals.share.copy_link')}</button>
        </div>
      </div>
    </div>
  {/if}

  <!-- Rename Modal -->
  {#if renameModal}
    <div class="modal-backdrop" on:click|self={() => (renameModal = null)}>
      <div class="dialog-card">
        <h3 class="text-title">{$t('modals.rename.title')}</h3>
        <input
          type="text"
          class="form-input text-body"
          bind:value={renameModal.newName}
          on:keydown={(e) => e.key === 'Enter' && handleRenameSubmit()}
        />
        <div class="dialog-actions">
          <button class="btn btn-secondary" on:click={() => (renameModal = null)}>{$t('common.cancel')}</button>
          <button class="btn btn-primary" on:click={handleRenameSubmit}>{$t('modals.rename.rename_btn')}</button>
        </div>
      </div>
    </div>
  {/if}

  <!-- New Folder Modal -->
  {#if newFolderModal}
    <div class="modal-backdrop" on:click|self={() => (newFolderModal = false)}>
      <div class="dialog-card">
        <h3 class="text-title">{$t('modals.create_folder.title')}</h3>
        <input
          type="text"
          class="form-input text-body"
          placeholder={$t('modals.create_folder.placeholder')}
          bind:value={newFolderName}
          on:keydown={(e) => e.key === 'Enter' && handleCreateFolderSubmit()}
        />
        <div class="dialog-actions">
          <button class="btn btn-secondary" on:click={() => (newFolderModal = false)}>{$t('common.cancel')}</button>
          <button class="btn btn-primary" on:click={handleCreateFolderSubmit}>{$t('modals.create_folder.create_btn')}</button>
        </div>
      </div>
    </div>
  {/if}

  <!-- Confirm Drag-to-Move Modal -->
  {#if confirmMoveModal}
    <div class="modal-backdrop" on:click|self={() => (confirmMoveModal = null)}>
      <div class="dialog-card">
        <h3 class="text-title" style="margin: 0; color: var(--text-main); font-weight: 700;">{$t('modals.move.title')}</h3>
        <p class="text-sub" style="margin: 0; line-height: 1.5;">
          {confirmMoveModal.validPaths.length === 1 ? `"${confirmMoveModal.validPaths[0].split('/').pop()}"` : $t('common.items', { count: confirmMoveModal.validPaths.length })} -> <strong>"{confirmMoveModal.targetName}"</strong>
        </p>
        <div class="dialog-actions" style="margin-top: 8px;">
          <button class="btn btn-secondary" on:click={() => (confirmMoveModal = null)}>{$t('common.cancel')}</button>
          <button class="btn btn-primary" on:click={executeConfirmedMove}>{$t('common.move')}</button>
        </div>
      </div>
    </div>
  {/if}

  <!-- Confirm Delete Modal (Single & Batch) -->
  {#if confirmDeleteModal}
    <div class="modal-backdrop" on:click|self={() => (confirmDeleteModal = null)}>
      <div class="dialog-card">
        <h3 class="text-title" style="margin: 0; color: var(--text-main); font-weight: 700;">{$t('modals.delete.title')}</h3>
        <p class="text-sub" style="margin: 8px 0 0 0; color: var(--text-sub); font-size: 14px; line-height: 1.5;">
          {confirmDeleteModal.count === 1
            ? $t('modals.delete.single_msg', { name: confirmDeleteModal.itemName })
            : $t('modals.delete.batch_msg', { count: confirmDeleteModal.count })}
        </p>
        <div class="dialog-actions" style="display: flex; justify-content: flex-end; gap: var(--spacing-sm); margin-top: 16px;">
          <button class="btn btn-secondary" on:click={() => (confirmDeleteModal = null)}>{$t('common.cancel')}</button>
          <button class="btn btn-primary danger-btn" on:click={executeConfirmedDelete}>{$t('modals.delete.delete_btn')}</button>
        </div>
      </div>
    </div>
  {/if}

  <!-- Upload Conflict Modal -->
  {#if uploadConflictModal}
    <UploadConflictModal
      conflicts={uploadConflictModal.conflicts}
      nonConflicts={uploadConflictModal.nonConflicts}
      on:resolve={(e) => {
        const { confirmed } = e.detail;
        if (confirmed && confirmed.length > 0) {
          transfersStore.enqueueBatch(confirmed, $scope, $currentPath);
        }
        uploadConflictModal = null;
      }}
      on:close={() => (uploadConflictModal = null)}
    />
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
