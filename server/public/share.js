// Copyright (C) 2026 Sinn Crowley
// SPDX-License-Identifier: AGPL-3.0-or-later

(function() {
  'use strict';

  const token = window.location.pathname.split('/')[2];
  let shareData = null;
  let currentRelPath = '';
  let currentLayout = localStorage.getItem('viewLayout') || 'grid'; // grid | list
  let filteredFiles = [];
  let mediaList = [];
  let currentLightboxIdx = -1;

  // Internationalization (i18n) dictionaries
  const dictionaries = {
    en: {
      share_title: "Shared Link",
      search_placeholder: "Filter files...",
      toggle_view: "Toggle Grid / List View",
      toggle_theme: "Toggle Light / Dark Mode",
      download: "Download",
      download_all_zip: "Download All (.zip)",
      download_file: "Download ({size})",
      fullscreen: "Fullscreen",
      loading_resource: "Loading shared resource...",
      loading_files: "Loading files...",
      loading_content: "Loading content...",
      loading_preview: "Loading preview content...",
      error_text_preview: "Error loading text preview.",
      error_load_resource: "Failed to load shared resource",
      error_network: "Network error connecting to server",
      preview: "Preview",
      text_preview: "Text Preview",
      close: "Close (Esc)",
      prev: "Previous (←)",
      next: "Next (→)",
      copied: "Copied to clipboard!",
      empty_title: "This directory is empty",
      empty_sub: "No files found matching your criteria",
      type: "Type",
      name: "Name",
      size: "Size",
      modified: "Modified",
      action: "Action",
      folder: "Folder",
      document: "DOCUMENT"
    },
    ru: {
      share_title: "Общая ссылка",
      search_placeholder: "Фильтр файлов...",
      toggle_view: "Сетка / Список",
      toggle_theme: "Переключить тему",
      download: "Скачать",
      download_all_zip: "Скачать всё (.zip)",
      download_file: "Скачать ({size})",
      fullscreen: "Во весь экран",
      loading_resource: "Загрузка ресурса...",
      loading_files: "Загрузка файлов...",
      loading_content: "Загрузка содержимого...",
      loading_preview: "Загрузка предпросмотра...",
      error_text_preview: "Ошибка загрузки предпросмотра.",
      error_load_resource: "Не удалось загрузить ресурс",
      error_network: "Ошибка сети при подключении к серверу",
      preview: "Просмотр",
      text_preview: "Текстовый просмотр",
      close: "Закрыть (Esc)",
      prev: "Предыдущий (←)",
      next: "Следующий (→)",
      copied: "Скопировано в буфер обмена!",
      empty_title: "В этой папке пусто",
      empty_sub: "Файлы по вашему запросу не найдены",
      type: "Тип",
      name: "Имя",
      size: "Размер",
      modified: "Изменен",
      action: "Действие",
      folder: "Папка",
      document: "ДОКУМЕНТ"
    }
  };

  function detectSystemLanguage() {
    try {
      if (typeof navigator !== 'undefined') {
        const candidates = (navigator.languages && navigator.languages.length > 0)
          ? navigator.languages
          : [navigator.language || navigator.userLanguage || ''];
        for (const raw of candidates) {
          if (!raw || typeof raw !== 'string') continue;
          const tag = raw.toLowerCase().trim();
          if (tag.startsWith('ru') || tag.startsWith('be') || tag.startsWith('kk') || tag.startsWith('uk')) {
            return 'ru';
          }
          if (tag.startsWith('en')) {
            return 'en';
          }
        }
      }
    } catch (_) {}
    return 'en';
  }

  function getActiveLanguage() {
    try {
      const saved = localStorage.getItem('cc_language') || localStorage.getItem('cc_share_lang') || 'system';
      if (saved === 'ru' || saved === 'en') return saved;
      const detected = detectSystemLanguage();
      return (detected === 'ru' || detected === 'en') ? detected : 'en';
    } catch (_) {
      return 'en';
    }
  }

  const currentLocale = getActiveLanguage();

  function t(key, params = null) {
    try {
      const dict = dictionaries[currentLocale] || dictionaries.en;
      let text = dict[key] || (dictionaries.en && dictionaries.en[key]) || key;
      if (params && typeof params === 'object') {
        Object.keys(params).forEach(k => {
          text = text.replace(new RegExp('\\{' + k + '\\}', 'g'), params[k]);
        });
      }
      return text;
    } catch (_) {
      return key;
    }
  }

  function updateStaticTexts() {
    document.title = `Crowley's Cloud - ${t('share_title')}`;
    const searchInput = document.getElementById('searchInput');
    if (searchInput) {
      searchInput.placeholder = t('search_placeholder');
      searchInput.setAttribute('aria-label', t('search_placeholder'));
    }
    const layoutBtn = document.getElementById('layoutToggleBtn');
    if (layoutBtn) layoutBtn.title = t('toggle_view');
    const themeBtn = document.getElementById('themeToggleBtn');
    if (themeBtn) themeBtn.title = t('toggle_theme');
    const lbDownloadBtn = document.getElementById('lightboxDownloadBtn');
    if (lbDownloadBtn) lbDownloadBtn.title = t('download');
    const lbCloseBtn = document.getElementById('lightboxCloseBtn');
    if (lbCloseBtn) lbCloseBtn.title = t('close');
    const lbPrevBtn = document.getElementById('lightboxPrevBtn');
    if (lbPrevBtn) lbPrevBtn.title = t('prev');
    const lbNextBtn = document.getElementById('lightboxNextBtn');
    if (lbNextBtn) lbNextBtn.title = t('next');
    const tmTitle = document.getElementById('textModalTitle');
    if (tmTitle) tmTitle.textContent = t('text_preview');
    const tmDownloadBtn = document.getElementById('textModalDownloadBtn');
    if (tmDownloadBtn) tmDownloadBtn.title = t('download');
    const tmCloseBtn = document.getElementById('textModalCloseBtn');
    if (tmCloseBtn) tmCloseBtn.title = t('close');
  }

  function getMaterialIcon(file) {
    if (!file) return 'insert_drive_file';
    if (file.isDir) return 'folder';
    const name = (file.name || '').toLowerCase();
    const ext = name.includes('.') ? name.split('.').pop() : '';
    const type = (file.type || '').toLowerCase();

    switch (ext) {
      case 'pdf': return 'picture_as_pdf';
      case 'doc': case 'docx': return 'description';
      case 'xls': case 'xlsx': return 'table_chart';
      case 'ppt': case 'pptx': return 'slideshow';
      case 'zip': case 'tar': case 'gz': case '7z': case 'rar': case 'bz2': case 'xz': return 'folder_zip';
      case 'mp3': case 'wav': case 'ogg': case 'flac': case 'm4a': case 'aac': return 'audiotrack';
      case 'mp4': case 'mkv': case 'avi': case 'mov': case 'webm': case 'flv': return 'movie';
      case 'jpg': case 'jpeg': case 'png': case 'webp': case 'gif': case 'bmp': case 'heic': case 'avif': case 'heif': case 'svg': case 'svgz': return 'image';
      case 'txt': case 'md': case 'json': case 'yaml': case 'yml': case 'xml': case 'log': case 'csv': case 'js': case 'ts': case 'html': case 'css': case 'dart': case 'cpp': case 'c': case 'h': case 'hpp': case 'py': case 'sh': return 'article';
      default:
        if (type === 'photo' || type === 'image') return 'image';
        if (type === 'video') return 'movie';
        if (type === 'audio') return 'audiotrack';
        if (type === 'archive') return 'folder_zip';
        return 'insert_drive_file';
    }
  }

  function getFileTypeCategory(file) {
    if (!file) return 'other';
    if (file.isDir) return 'directory';
    const icon = getMaterialIcon(file);
    if (icon === 'image') return 'image';
    if (icon === 'movie') return 'video';
    if (icon === 'audiotrack') return 'audio';
    if (icon === 'article') return 'text';
    if (icon === 'picture_as_pdf' || icon === 'description' || icon === 'table_chart' || icon === 'slideshow') return 'document';
    return 'other';
  }

  // Theme Management
  function initTheme() {
    const savedTheme = localStorage.getItem('cc_web_theme') || 'dark';
    document.documentElement.setAttribute('data-theme', savedTheme);
    updateThemeIcon();
  }

  function toggleTheme() {
    const current = document.documentElement.getAttribute('data-theme');
    const next = current === 'dark' ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', next);
    localStorage.setItem('cc_web_theme', next);
    updateThemeIcon();
  }

  function updateThemeIcon() {
    const current = document.documentElement.getAttribute('data-theme');
    const iconEl = document.getElementById('themeIcon');
    if (iconEl) {
      iconEl.textContent = current === 'dark' ? 'light_mode' : 'dark_mode';
    }
  }

  function showToast(msg) {
    const tEl = document.getElementById('toast');
    if (!tEl) return;
    tEl.textContent = msg || t('copied');
    tEl.classList.add('show');
    setTimeout(() => tEl.classList.remove('show'), 2500);
  }

  // Data Fetching
  async function loadShareInfo(relPath = '') {
    currentRelPath = relPath;
    const appMain = document.getElementById('appMain');
    appMain.innerHTML = `
      <div class="spinner-container">
        <div class="spinner"></div>
        <p class="text-sub">${t('loading_files')}</p>
      </div>
    `;

    try {
      const url = `/api/public/share/${encodeURIComponent(token)}/info?p=${encodeURIComponent(relPath)}`;
      const resp = await fetch(url);
      if (!resp.ok) {
        const err = await resp.json();
        showError(err.error || t('error_load_resource'));
        return;
      }
      shareData = await resp.json();
      renderView();
    } catch (e) {
      showError(t('error_network'));
    }
  }

  function showError(msg) {
    document.getElementById('appMain').innerHTML = `
      <div class="empty-state">
        <span class="material-symbols-outlined empty-icon" style="color:var(--color-danger); opacity:1;">error_outline</span>
        <h3 class="empty-title">${escapeHtml(msg)}</h3>
      </div>
    `;
  }

  function toggleLayout() {
    currentLayout = currentLayout === 'grid' ? 'list' : 'grid';
    localStorage.setItem('viewLayout', currentLayout);
    updateLayoutIcon();
    renderView();
  }

  function updateLayoutIcon() {
    const iconEl = document.getElementById('layoutIcon');
    if (iconEl) {
      iconEl.textContent = currentLayout === 'grid' ? 'list' : 'grid_view';
    }
  }

  function onFilterChange(query) {
    const q = (query || '').toLowerCase().trim();
    const clearBtn = document.getElementById('clearSearchBtn');
    if (clearBtn) clearBtn.style.display = q ? 'block' : 'none';

    const files = shareData ? (shareData.files || []) : [];
    if (!q) {
      filteredFiles = files;
    } else {
      filteredFiles = files.filter(f => f.name.toLowerCase().includes(q));
    }
    renderFileContainer();
  }

  function clearSearch() {
    const input = document.getElementById('searchInput');
    if (input) {
      input.value = '';
      onFilterChange('');
    }
  }

  function renderView() {
    const appMain = document.getElementById('appMain');
    const mainDownloadBtn = document.getElementById('mainDownloadBtn');
    const downloadBtnText = document.getElementById('downloadBtnText');

    updateLayoutIcon();

    if (!shareData) return;

    if (!shareData.isFolder && currentRelPath === '') {
      mainDownloadBtn.href = `/s/${encodeURIComponent(token)}/raw?download=1`;
      downloadBtnText.textContent = t('download');

      renderSingleFileView(shareData.files[0] || {
        name: shareData.rootName,
        relPath: '',
        size: shareData.size || 0,
        mimeType: shareData.mimeType || '',
        type: shareData.type || 'other'
      });
      return;
    }

    mainDownloadBtn.href = `/s/${encodeURIComponent(token)}/zip?p=${encodeURIComponent(currentRelPath)}`;
    downloadBtnText.textContent = t('download_all_zip');

    filteredFiles = shareData.files || [];
    mediaList = filteredFiles.filter(f => {
      const cat = getFileTypeCategory(f);
      return cat === 'image' || cat === 'video';
    });

    let html = `
      <div class="breadcrumb-bar">
        <button class="crumb-btn ${currentRelPath === '' ? 'active' : ''}" data-crumb-path="">
          <span class="material-symbols-outlined" style="font-size:18px;">folder_open</span>
          <span>${escapeHtml(shareData.rootName)}</span>
        </button>
        ${renderBreadcrumbsHTML(currentRelPath)}
      </div>
      <div id="fileContainer"></div>
    `;

    appMain.innerHTML = html;
    renderFileContainer();
  }

  function renderBreadcrumbsHTML(relPath) {
    if (!relPath) return '';
    const parts = relPath.split('/');
    let accumulated = '';
    let res = '';
    parts.forEach((part, idx) => {
      accumulated += (accumulated ? '/' : '') + part;
      const isLast = idx === parts.length - 1;
      const curAcc = accumulated;
      res += `
        <span class="crumb-separator">/</span>
        <button class="crumb-btn ${isLast ? 'active' : ''}" ${isLast ? '' : `data-crumb-path="${escapeHtml(curAcc)}"`}>
          <span>${escapeHtml(part)}</span>
        </button>
      `;
    });
    return res;
  }

  function renderFileContainer() {
    const container = document.getElementById('fileContainer');
    if (!container) return;

    if (filteredFiles.length === 0) {
      container.innerHTML = `
        <div class="empty-state">
          <span class="material-symbols-outlined empty-icon">folder_open</span>
          <h3 class="empty-title">${t('empty_title')}</h3>
          <p class="empty-sub">${t('empty_sub')}</p>
        </div>
      `;
      return;
    }

    if (currentLayout === 'grid') {
      let gridHtml = '<div class="grid-container">';
      filteredFiles.forEach(file => {
        gridHtml += renderGridCard(file);
      });
      gridHtml += '</div>';
      container.innerHTML = gridHtml;
    } else {
      let listHtml = `
        <div class="list-container">
          <div class="list-header">
            <span>${t('type')}</span>
            <span>${t('name')}</span>
            <span style="text-align:right;">${t('size')}</span>
            <span style="text-align:right;">${t('modified')}</span>
            <span style="text-align:right;">${t('action')}</span>
          </div>
      `;
      filteredFiles.forEach(file => {
        listHtml += renderListRow(file);
      });
      listHtml += '</div>';
      container.innerHTML = listHtml;
    }
  }

  function renderGridCard(file) {
    const rawUrl = `/s/${encodeURIComponent(token)}/raw?p=${encodeURIComponent(file.relPath)}`;
    const downloadUrl = `/s/${encodeURIComponent(token)}/raw?download=1&p=${encodeURIComponent(file.relPath)}`;
    const category = getFileTypeCategory(file);

    let thumbnailContent = '';
    if (file.isDir) {
      thumbnailContent = `<span class="material-symbols-outlined grid-item-icon icon-folder">folder</span>`;
    } else if (category === 'image') {
      thumbnailContent = `<img src="${rawUrl}" loading="lazy" alt="${escapeHtml(file.name)}">`;
    } else {
      thumbnailContent = `<span class="material-symbols-outlined grid-item-icon">${getMaterialIcon(file)}</span>`;
    }

    return `
      <div class="grid-item" data-relpath="${escapeHtml(file.relPath)}" data-is-dir="${file.isDir ? '1' : '0'}">
        <div class="grid-item-thumbnail">
          ${thumbnailContent}
        </div>
        <div class="grid-item-info">
          <div class="grid-item-name" title="${escapeHtml(file.name)}">${escapeHtml(file.name)}</div>
          <div class="grid-item-meta-row">
            <span class="grid-item-meta">${file.isDir ? t('folder') : formatSize(file.size)}</span>
            ${!file.isDir ? `
              <a href="${downloadUrl}" class="grid-item-action-btn" title="${t('download')}">
                <span class="material-symbols-outlined" style="font-size: 16px;">download</span>
              </a>
            ` : ''}
          </div>
        </div>
      </div>
    `;
  }

  function renderListRow(file) {
    const downloadUrl = `/s/${encodeURIComponent(token)}/raw?download=1&p=${encodeURIComponent(file.relPath)}`;
    const iconName = getMaterialIcon(file);

    return `
      <div class="list-row" data-relpath="${escapeHtml(file.relPath)}" data-is-dir="${file.isDir ? '1' : '0'}">
        <div class="list-icon">
          <span class="material-symbols-outlined file-type-icon">${iconName}</span>
        </div>
        <div class="list-name" title="${escapeHtml(file.name)}">${escapeHtml(file.name)}</div>
        <div class="list-size">${file.isDir ? '--' : formatSize(file.size)}</div>
        <div class="list-date">${formatDate(file.modifiedAt)}</div>
        <div class="list-action">
          ${!file.isDir ? `
            <a href="${downloadUrl}" class="grid-item-action-btn" title="${t('download')}">
              <span class="material-symbols-outlined" style="font-size: 18px;">download</span>
            </a>
          ` : ''}
        </div>
      </div>
    `;
  }

  function renderSingleFileView(file) {
    const appMain = document.getElementById('appMain');
    const rawUrl = `/s/${encodeURIComponent(token)}/raw`;
    const downloadUrl = `/s/${encodeURIComponent(token)}/raw?download=1`;
    const category = getFileTypeCategory(file);

    let mediaStageHtml = '';
    let isMedia = false;

    if (category === 'image') {
      isMedia = true;
      mediaList = [file];
      mediaStageHtml = `
        <div class="preview-stage" data-action="open-lightbox" title="${t('fullscreen')}">
          <img src="${rawUrl}" alt="${escapeHtml(file.name)}">
        </div>`;
    } else if (category === 'video') {
      isMedia = true;
      mediaList = [file];
      mediaStageHtml = `
        <div class="preview-stage">
          <video src="${rawUrl}" controls autoplay></video>
        </div>`;
    } else if (category === 'audio') {
      mediaStageHtml = `
        <div class="audio-stage">
          <span class="material-symbols-outlined" style="font-size:64px; color:var(--accent-color);">audiotrack</span>
          <audio src="${rawUrl}" controls></audio>
        </div>`;
    } else if (category === 'text') {
      fetchTextPreview(rawUrl);
      mediaStageHtml = `<div class="code-container" id="codePreview">${t('loading_preview')}</div>`;
    } else {
      const ext = file.name.includes('.') ? file.name.split('.').pop().toUpperCase() : 'FILE';
      mediaStageHtml = `
        <div class="generic-file-box">
          <span class="material-symbols-outlined generic-icon">${getMaterialIcon(file)}</span>
          <div class="file-badge">${escapeHtml(ext)} ${t('document')}</div>
        </div>`;
    }

    appMain.innerHTML = `
      <div class="file-showcase">
        <h2 class="showcase-title">${escapeHtml(file.name)}</h2>
        ${mediaStageHtml}
        <div class="showcase-actions">
          <a href="${downloadUrl}" class="btn btn-primary">
            <span class="material-symbols-outlined" style="font-size: 18px;">download</span>
            ${t('download_file', { size: formatSize(file.size) })}
          </a>
          ${isMedia ? `
            <button class="btn btn-secondary" data-action="open-lightbox">
              <span class="material-symbols-outlined" style="font-size: 18px;">fullscreen</span>
              ${t('fullscreen')}
            </button>
          ` : ''}
        </div>
      </div>
    `;
  }

  async function fetchTextPreview(url) {
    try {
      const resp = await fetch(url);
      const text = await resp.text();
      const el = document.getElementById('codePreview');
      if (el) el.textContent = text;
    } catch (e) {
      const el = document.getElementById('codePreview');
      if (el) el.textContent = t('error_text_preview');
    }
  }

  async function openTextModal(file) {
    const modal = document.getElementById('textModal');
    const title = document.getElementById('textModalTitle');
    const content = document.getElementById('textModalContent');
    const downloadBtn = document.getElementById('textModalDownloadBtn');

    title.textContent = file.name;
    downloadBtn.href = `/s/${encodeURIComponent(token)}/raw?download=1${file.relPath ? '&p=' + encodeURIComponent(file.relPath) : ''}`;
    content.textContent = t('loading_content');
    modal.classList.add('active');

    const rawUrl = `/s/${encodeURIComponent(token)}/raw${file.relPath ? '?p=' + encodeURIComponent(file.relPath) : ''}`;
    try {
      const resp = await fetch(rawUrl);
      const text = await resp.text();
      content.textContent = text;
    } catch (e) {
      content.textContent = t('error_text_preview');
    }
  }

  function closeTextModal() {
    const modal = document.getElementById('textModal');
    if (modal) modal.classList.remove('active');
  }

  function onFileClick(relPath) {
    const file = (filteredFiles || []).find(f => f.relPath === relPath);
    if (file) {
      const category = getFileTypeCategory(file);
      if (category === 'text') {
        openTextModal(file);
        return;
      }
    }

    const idx = mediaList.findIndex(m => m.relPath === relPath);
    if (idx !== -1) {
      openLightbox(idx);
    } else {
      window.location.href = `/s/${encodeURIComponent(token)}/raw?download=1&p=${encodeURIComponent(relPath)}`;
    }
  }

  function openLightbox(idx) {
    if (!mediaList || mediaList.length === 0) return;
    if (idx < 0 || idx >= mediaList.length) return;
    currentLightboxIdx = idx;
    const file = mediaList[idx];
    const modal = document.getElementById('lightboxModal');
    const title = document.getElementById('lightboxTitle');
    const content = document.getElementById('lightboxContent');
    const downloadBtn = document.getElementById('lightboxDownloadBtn');
    const prevBtn = document.getElementById('lightboxPrevBtn');
    const nextBtn = document.getElementById('lightboxNextBtn');

    title.textContent = mediaList.length > 1 ? `${file.name} (${idx + 1}/${mediaList.length})` : file.name;
    downloadBtn.href = `/s/${encodeURIComponent(token)}/raw?download=1${file.relPath ? '&p=' + encodeURIComponent(file.relPath) : ''}`;

    prevBtn.style.display = mediaList.length > 1 ? 'flex' : 'none';
    nextBtn.style.display = mediaList.length > 1 ? 'flex' : 'none';

    const rawUrl = `/s/${encodeURIComponent(token)}/raw${file.relPath ? '?p=' + encodeURIComponent(file.relPath) : ''}`;
    const category = getFileTypeCategory(file);
    if (category === 'image') {
      content.innerHTML = `<img src="${rawUrl}" alt="${escapeHtml(file.name)}">`;
    } else if (category === 'video') {
      content.innerHTML = `<video src="${rawUrl}" controls autoplay></video>`;
    }

    modal.classList.add('active');
  }

  function closeLightbox() {
    const modal = document.getElementById('lightboxModal');
    const content = document.getElementById('lightboxContent');
    if (modal) modal.classList.remove('active');
    if (content) content.innerHTML = '';
    currentLightboxIdx = -1;
  }

  function lightboxPrev() {
    if (currentLightboxIdx > 0) openLightbox(currentLightboxIdx - 1);
  }

  function lightboxNext() {
    if (currentLightboxIdx < mediaList.length - 1) openLightbox(currentLightboxIdx + 1);
  }

  function formatSize(bytes) {
    if (!bytes || bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  }

  function formatDate(ts) {
    if (!ts) return '--';
    const d = new Date(ts * 1000);
    return isNaN(d.getTime()) ? '--' : d.toLocaleDateString(currentLocale === 'ru' ? 'ru-RU' : 'en-US', { year: 'numeric', month: 'short', day: 'numeric' });
  }

  function escapeHtml(str) {
    if (!str) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function escapeJs(str) {
    if (!str) return '';
    return JSON.stringify(String(str)).slice(1, -1);
  }

  // Set up event listeners
  function initEvents() {
    const searchInput = document.getElementById('searchInput');
    if (searchInput) {
      searchInput.addEventListener('input', (e) => onFilterChange(e.target.value));
    }

    const clearBtn = document.getElementById('clearSearchBtn');
    if (clearBtn) {
      clearBtn.addEventListener('click', clearSearch);
    }

    const layoutBtn = document.getElementById('layoutToggleBtn');
    if (layoutBtn) {
      layoutBtn.addEventListener('click', toggleLayout);
    }

    const themeBtn = document.getElementById('themeToggleBtn');
    if (themeBtn) {
      themeBtn.addEventListener('click', toggleTheme);
    }

    const tmCloseBtn = document.getElementById('textModalCloseBtn');
    if (tmCloseBtn) {
      tmCloseBtn.addEventListener('click', closeTextModal);
    }

    const lbCloseBtn = document.getElementById('lightboxCloseBtn');
    if (lbCloseBtn) {
      lbCloseBtn.addEventListener('click', closeLightbox);
    }

    const lbPrevBtn = document.getElementById('lightboxPrevBtn');
    if (lbPrevBtn) {
      lbPrevBtn.addEventListener('click', lightboxPrev);
    }

    const lbNextBtn = document.getElementById('lightboxNextBtn');
    if (lbNextBtn) {
      lbNextBtn.addEventListener('click', lightboxNext);
    }

    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        if (currentLightboxIdx !== -1) closeLightbox();
        closeTextModal();
      }
      if (currentLightboxIdx !== -1) {
        if (e.key === 'ArrowLeft') lightboxPrev();
        if (e.key === 'ArrowRight') lightboxNext();
      }
    });

    // Delegated click handler for breadcrumbs, cards, rows, and buttons
    document.addEventListener('click', (e) => {
      const crumbBtn = e.target.closest('button[data-crumb-path]');
      if (crumbBtn) {
        const path = crumbBtn.getAttribute('data-crumb-path');
        if (path !== null) {
          loadShareInfo(path);
          return;
        }
      }

      const actionBtn = e.target.closest('.grid-item-action-btn');
      if (actionBtn) {
        // Direct click on download action inside item card/row
        return;
      }

      const lightboxTrigger = e.target.closest('[data-action="open-lightbox"]');
      if (lightboxTrigger) {
        openLightbox(0);
        return;
      }

      const itemEl = e.target.closest('.grid-item, .list-row');
      if (itemEl && itemEl.hasAttribute('data-relpath')) {
        const isDir = itemEl.getAttribute('data-is-dir') === '1';
        const relPath = itemEl.getAttribute('data-relpath') || '';
        if (isDir) {
          loadShareInfo(relPath);
        } else {
          onFileClick(relPath);
        }
      }
    });
  }

  // Initialize
  initTheme();
  updateStaticTexts();
  initEvents();
  loadShareInfo();
})();
