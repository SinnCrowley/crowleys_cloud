<!-- Copyright (C) 2026 Sinn Crowley; SPDX-License-Identifier: AGPL-3.0-or-later -->
<script>
  import { createEventDispatcher, onMount } from 'svelte';
  import { apiGet, apiPost, apiDelete, apiFetch } from '../api/client.js';
  import { authStore } from '../stores/auth.js';
  import { t } from '../stores/i18n.js';

  const dispatch = createEventDispatcher();
  const { user } = authStore;
  let section = 'users';
  let users = [];
  let applications = [];
  let resetCodes = [];
  let config = null;
  let maintenance = { phase: 'idle', maintenance: false, running: false };
  let edits = {};
  let busy = false;
  let error = '';
  let selectedUserId = null;
  let recovery = null;
  let signingSecret = '';
  let encryptionKey = '';
  let mounted = false;
  let nowSeconds = Math.floor(Date.now() / 1000);
  let copiedCode = null;

  let quotaUnit = 1024 * 1024 * 1024;
  let quotaDisplayValue = 10;
  let lastSelectedUserId = null;

  $: defaultQuotaBytes = Number(config?.fields?.find(f => f.name === 'default_quota_bytes')?.value ?? 0);
  $: maxQuotaValue = ($user?.role !== 'superuser' && defaultQuotaBytes > 0)
    ? Math.floor(defaultQuotaBytes / quotaUnit)
    : Math.floor(Number.MAX_SAFE_INTEGER / quotaUnit);

  $: unitOptions = [
    { multiplier: 1, label: $t('admin.units.bytes') },
    { multiplier: 1024, label: $t('admin.units.kilobytes') },
    { multiplier: 1024 * 1024, label: $t('admin.units.megabytes') },
    { multiplier: 1024 * 1024 * 1024, label: $t('admin.units.gigabytes') },
  ];

  function initQuotaInputs(person) {
    if (!person) return;
    const bytes = Number(person.quota_bytes);
    if (bytes && bytes > 0) {
      if (bytes % (1024 * 1024 * 1024) === 0) {
        quotaUnit = 1024 * 1024 * 1024;
        quotaDisplayValue = bytes / (1024 * 1024 * 1024);
      } else if (bytes % (1024 * 1024) === 0) {
        quotaUnit = 1024 * 1024;
        quotaDisplayValue = bytes / (1024 * 1024);
      } else if (bytes % 1024 === 0) {
        quotaUnit = 1024;
        quotaDisplayValue = bytes / 1024;
      } else {
        quotaUnit = 1;
        quotaDisplayValue = bytes;
      }
    } else {
      quotaUnit = 1024 * 1024 * 1024;
      quotaDisplayValue = 10;
      if ($user?.role !== 'superuser' && defaultQuotaBytes > 0 && quotaDisplayValue * quotaUnit > defaultQuotaBytes) {
        quotaDisplayValue = Math.max(1, Math.floor(defaultQuotaBytes / quotaUnit));
      }
      if (person.quotaMode === 'limited') {
        person.quota_bytes = quotaDisplayValue * quotaUnit;
      }
    }
  }

  function syncQuotaBytes() {
    if (selectedUser && selectedUser.quotaMode === 'limited') {
      let val = Number(quotaDisplayValue);
      if (isNaN(val) || val <= 0) val = 1;
      if ($user?.role !== 'superuser' && defaultQuotaBytes > 0 && maxQuotaValue > 0 && val > maxQuotaValue) {
        val = maxQuotaValue;
        quotaDisplayValue = val;
      }
      selectedUser.quota_bytes = Math.round(val * quotaUnit);
    }
  }

  function incrementQuota() {
    const current = Number(quotaDisplayValue) || 0;
    if (current < maxQuotaValue) {
      quotaDisplayValue = current + 1;
      syncQuotaBytes();
    }
  }

  function decrementQuota() {
    const current = Number(quotaDisplayValue) || 0;
    if (current > 1) {
      quotaDisplayValue = current - 1;
      syncQuotaBytes();
    }
  }

  function fail(reason) {
    const code = reason?.data?.code;
    const translated = code ? $t(`admin.errors.${code}`) : '';
    error = translated && translated !== `admin.errors.${code}` ? translated : reason.message || $t('common.error');
  }
  async function refresh() {
    const [people, pending, settings, state, codes] = await Promise.all([
      apiGet('/api/admin/users'), apiGet('/api/admin/applications'),
      apiGet('/api/admin/config'), apiGet('/api/admin/maintenance'),
      apiGet('/api/admin/reset-codes')
    ]);
    if (!mounted) return;
    users = people.map(person => ({ ...person, quotaMode: person.quota_bytes === null ? 'inherit' : person.quota_bytes === 0 ? 'unlimited' : 'limited' }));
    applications = pending;
    config = settings;
    maintenance = state;
    resetCodes = codes || [];
  }
  async function perform(work, reload = true, notify = true) {
    if (busy) return;
    busy = true; error = '';
    try {
      await work();
      if (reload) await refresh();
      const account = await apiGet('/api/account');
      authStore.user.set(account);
      if (notify) {
        dispatch('toast', { message: $t('admin.saved'), type: 'success' });
      }
    } catch (reason) { fail(reason); }
    finally { busy = false; }
  }
  $: selectedUser = users.find(person => person.id === selectedUserId) || null;
  $: if (selectedUser && selectedUser.id !== lastSelectedUserId) {
    lastSelectedUserId = selectedUser.id;
    initQuotaInputs(selectedUser);
  } else if (!selectedUser) {
    lastSelectedUserId = null;
  }
  $: if (selectedUser && selectedUser.quotaMode === 'limited' && (!selectedUser.quota_bytes || selectedUser.quota_bytes <= 0)) {
    selectedUser.quota_bytes = Math.round((Number(quotaDisplayValue) || 1) * quotaUnit);
  }
  function isSelf(person) { return person.id === $user?.id; }
  function formatBytes(bytes) {
    const value = Number(bytes || 0);
    if (value < 1024) return `${value} B`;
    const units = ['KB', 'MB', 'GB', 'TB'];
    const unit = Math.min(units.length - 1, Math.floor(Math.log(value) / Math.log(1024)) - 1);
    return `${(value / 1024 ** (unit + 1)).toFixed(value < 10 * 1024 ** (unit + 1) ? 1 : 0)} ${units[unit]}`;
  }
  function quotaSummary(person) {
    const limit = Number(person.effective_quota_bytes || 0);
    return limit > 0 ? `${formatBytes(person.used_bytes)} / ${formatBytes(limit)}` : `${formatBytes(person.used_bytes)} / ∞`;
  }
  function fieldLabel(field) { return $t(`admin.fields.${field.name}.label`); }
  function fieldHelp(field) { return $t(`admin.fields.${field.name}.help`); }
  function saveUser(person) {
    if (isSelf(person) && person.status === 'blocked') {
      error = $t('admin.errors.cannot_block_self');
      return;
    }
    if (person.role === 'superuser' && person.status === 'blocked') {
      error = $t('admin.errors.cannot_block_superuser');
      return;
    }
    if ($user?.role !== 'superuser' && person.role === 'superuser') {
      error = $t('admin.errors.cannot_modify_superuser');
      return;
    }
    if (person.quotaMode === 'limited') {
      syncQuotaBytes();
    }
    const quota = person.quotaMode === 'inherit' ? null : person.quotaMode === 'unlimited' ? 0 : Number(person.quota_bytes);
    if (quota !== null && (!Number.isSafeInteger(quota) || quota < 0 || (person.quotaMode === 'limited' && quota === 0))) {
      error = $t('admin.errors.invalid_quota'); return;
    }
    if ($user?.role !== 'superuser' && defaultQuotaBytes > 0) {
      if (person.quotaMode === 'unlimited' || (quota !== null && quota > defaultQuotaBytes)) {
        error = $t('admin.errors.quota_exceeded_default'); return;
      }
    }
    perform(() => apiFetch(`/api/admin/users/${person.id}`, { method: 'PATCH', body: JSON.stringify({ role: person.role, status: person.status, quota_bytes: quota }) }));
  }
  async function resetPassword(person) {
    if (!window.confirm($t('admin.confirm_reset', { name: person.username }))) return;
    await perform(async () => {
      const result = await apiPost(`/api/admin/users/${person.id}/reset-password`, {});
      recovery = { username: person.username, code: result.code };
    });
  }
  function deleteUser(person) {
    if (!window.confirm($t('admin.confirm_delete', { name: person.username }))) return;
    perform(() => apiDelete(`/api/admin/users/${person.id}`));
  }
  function saveConfig() {
    const changes = {};
    for (const field of config.fields) {
      if (!(field.name in edits)) continue;
      const value = edits[field.name];
      changes[field.name] = field.type === 'integer' ? Number(value) : value;
      if (field.type === 'integer' && (!Number.isSafeInteger(changes[field.name]) || changes[field.name] < 0)) {
        error = $t('admin.errors.invalid_config_value'); return;
      }
    }
    if (!Object.keys(changes).length) return;
    perform(async () => {
      config = await apiFetch('/api/admin/config', { method: 'PATCH', body: JSON.stringify({ revision: config.revision, changes }) });
      edits = {};
    });
  }
  async function rotate(kind) {
    if (!window.confirm($t(kind === 'signing' ? 'admin.confirm_signing' : 'admin.confirm_encryption'))) return;
    if (kind === 'signing') {
      busy = true; error = '';
      try {
        await apiPost('/api/admin/signing-secret', { revision: config.revision, secret: signingSecret });
        signingSecret = ''; authStore.clearSession();
      } catch (reason) { fail(reason); }
      finally { busy = false; }
    } else {
      await perform(async () => {
        maintenance = await apiPost('/api/admin/encryption-key', { revision: config.revision, secret: encryptionKey });
        encryptionKey = ''; section = 'maintenance';
      });
    }
  }
  function formatExpiresIn(expiresAt) {
    const diff = Math.max(0, expiresAt - nowSeconds);
    const minutes = Math.floor(diff / 60);
    const seconds = diff % 60;
    return `${minutes}m ${seconds.toString().padStart(2, '0')}s`;
  }
  async function copyCode(code) {
    try {
      await navigator.clipboard.writeText(code);
      copiedCode = code;
      setTimeout(() => {
        if (copiedCode === code) copiedCode = null;
      }, 2000);
    } catch {
      // ignore
    }
  }
  async function deleteResetCode(item) {
    if (!window.confirm($t('admin.confirm_delete_reset_code', { name: item.username }))) return;
    await perform(() => apiDelete(`/api/admin/reset-codes/${item.id}`));
  }
  onMount(() => {
    mounted = true;
    perform(refresh, false, false);
    const ticker = setInterval(() => {
      nowSeconds = Math.floor(Date.now() / 1000);
      if (resetCodes.some(c => c.expires_at <= nowSeconds)) {
        resetCodes = resetCodes.filter(c => c.expires_at > nowSeconds);
      }
    }, 1000);
    const timer = setInterval(async () => {
      if (busy || !mounted) return;
      try {
        const state = await apiGet('/api/admin/maintenance');
        if (!mounted) return;
        const finished = maintenance.maintenance && !state.maintenance;
        maintenance = state;
        if (finished) await refresh();
      } catch (reason) { if (mounted) fail(reason); }
    }, 3000);
    return () => {
      mounted = false;
      clearInterval(ticker);
      clearInterval(timer);
    };
  });
</script>

<section class="administration" aria-busy={busy}>
  <header class="admin-header">
    <h1>{$t('admin.title')}</h1>
    <button class="btn btn-secondary" disabled={busy} on:click={() => perform(refresh, false, false)}>
      <span class="material-symbols-outlined">refresh</span>
      {$t('common.refresh')}
    </button>
  </header>

  <nav class="admin-nav" aria-label={$t('admin.title')}>
    {#each ['users', 'applications', 'reset_codes', 'configuration', 'maintenance'] as tab}
      <button class="nav-tab" class:active={section === tab} aria-current={section === tab ? 'page' : undefined} on:click={() => section = tab}>
        {$t(`admin.${tab}`)}
        {tab === 'applications' && applications.length ? ` (${applications.length})` : ''}
        {tab === 'reset_codes' && resetCodes.length ? ` (${resetCodes.length})` : ''}
      </button>
    {/each}
  </nav>

  {#if error}<p class="error-banner" role="alert">{error}</p>{/if}
  {#if maintenance.maintenance}<p class="warning-banner" role="status">{$t('account_status.serverMaintenance')}</p>{/if}
  {#if recovery}
    <aside class="recovery-banner" role="status">
      <strong>{recovery.username}</strong>
      <p>{$t('admin.recovery_hint')}</p>
      <code>{recovery.code}</code>
      <button class="btn btn-secondary" on:click={() => recovery = null}>{$t('common.close')}</button>
    </aside>
  {/if}

  {#if section === 'users'}
    <div class="table-card">
      <table>
        <thead>
          <tr>
            <th>{$t('common.name')}</th>
            <th>{$t('admin.role')}</th>
            <th>{$t('admin.status')}</th>
            <th>{$t('admin.quota')}</th>
            <th style="width: 100px;"></th>
          </tr>
        </thead>
        <tbody>
          {#each users as person (person.id)}
            <tr>
              <td><strong>{person.username}</strong></td>
              <td>{$t(`admin.${person.role === 'superuser' ? 'superuser' : person.role === 'admin' ? 'administrator' : 'user'}`)}</td>
              <td><span class="status" class:blocked={person.status === 'blocked'}>{$t(`admin.${person.status}`)}</span></td>
              <td>{quotaSummary(person)}</td>
              <td style="text-align: right;">
                <button class="btn btn-secondary" type="button" on:click={() => selectedUserId = person.id}>{$t('common.update')}</button>
              </td>
            </tr>
          {/each}
        </tbody>
      </table>
    </div>

    {#if selectedUser}
      <!-- svelte-ignore a11y-click-events-have-key-events -->
      <!-- svelte-ignore a11y-no-static-element-interactions -->
      <div class="modal-backdrop" on:click|self={() => selectedUserId = null}>
        <form class="dialog-card user-details" on:submit|preventDefault={() => saveUser(selectedUser)}>
          <div class="dialog-heading">
            <div>
              <h2>{selectedUser.username}</h2>
              <p class="text-sub">{$t('admin.used')}: {formatBytes(selectedUser.used_bytes)} · {$t('admin.reserved')}: {formatBytes(selectedUser.reserved_bytes)}</p>
            </div>
            <button class="btn-icon" type="button" on:click={() => selectedUserId = null} title={$t('common.close')}>
              <span class="material-symbols-outlined">close</span>
            </button>
          </div>

          {#if selectedUser.status === 'deleting'}
            <p class="warning-banner">{$t('admin.deleting')}</p>
            <button class="btn btn-primary" type="button" disabled={busy || maintenance.maintenance} on:click={() => deleteUser(selectedUser)}>{$t('admin.retry')}</button>
          {:else}
            <div class="form-group">
              <span class="form-label">{$t('admin.role')}</span>
              <div class="select-wrapper">
                <select class="custom-select" bind:value={selectedUser.role} disabled={selectedUser.role === 'superuser' || ($user?.role !== 'superuser' && selectedUser.role === 'admin')}>
                  {#if selectedUser.role === 'superuser'}
                    <option value="superuser">{$t('admin.superuser')}</option>
                  {:else}
                    <option value="user">{$t('admin.user')}</option>
                    <option value="admin">{$t('admin.administrator')}</option>
                  {/if}
                </select>
                <span class="material-symbols-outlined select-arrow">expand_more</span>
              </div>
              {#if $user?.role !== 'superuser' && selectedUser.role === 'superuser'}
                <small class="field-hint">{$t('admin.errors.cannot_modify_superuser')}</small>
              {:else if $user?.role !== 'superuser' && selectedUser.role === 'admin'}
                <small class="field-hint">{$t('admin.errors.cannot_demote_admin')}</small>
              {/if}
            </div>

            <div class="form-group">
              <span class="form-label">{$t('admin.status')}</span>
              <div class="select-wrapper">
                <select class="custom-select" bind:value={selectedUser.status} disabled={selectedUser.role === 'superuser'}>
                  <option value="active">{$t('admin.active')}</option>
                  <option value="blocked" disabled={isSelf(selectedUser) || selectedUser.role === 'superuser'}>{$t('admin.blocked')}</option>
                </select>
                <span class="material-symbols-outlined select-arrow">expand_more</span>
              </div>
              {#if isSelf(selectedUser)}<small class="field-hint">{$t('admin.errors.cannot_block_self')}</small>
              {:else if selectedUser.role === 'superuser'}<small class="field-hint">{$t('admin.errors.cannot_block_superuser')}</small>{/if}
            </div>

            <div class="form-group">
              <span class="form-label">{$t('admin.quota')}</span>
              <div class="select-wrapper">
                <select class="custom-select" bind:value={selectedUser.quotaMode} disabled={$user?.role !== 'superuser' && selectedUser.role === 'superuser'}>
                  <option value="inherit">{$t('admin.inherit')}</option>
                  {#if $user?.role === 'superuser' || defaultQuotaBytes <= 0}
                    <option value="unlimited">{$t('admin.unlimited')}</option>
                  {/if}
                  <option value="limited">{$t('admin.limited')}</option>
                </select>
                <span class="material-symbols-outlined select-arrow">expand_more</span>
              </div>
              <small class="field-hint">{quotaSummary(selectedUser)}</small>
            </div>

            {#if selectedUser.quotaMode === 'limited'}
              <div class="form-group">
                <span class="form-label">{$t('admin.bytes')}</span>
                <div class="quota-input-group">
                  <div class="custom-number-stepper">
                    <input
                      class="form-input stepper-input"
                      type="number"
                      min="1"
                      step="1"
                      max={maxQuotaValue}
                      bind:value={quotaDisplayValue}
                      on:input={syncQuotaBytes}
                      disabled={$user?.role !== 'superuser' && selectedUser.role === 'superuser'}
                      required
                    />
                    <div class="stepper-buttons">
                      <button
                        type="button"
                        class="stepper-btn"
                        tabindex="-1"
                        aria-label={$t('admin.increase')}
                        disabled={$user?.role !== 'superuser' && selectedUser.role === 'superuser'}
                        on:click={incrementQuota}
                      >
                        <span class="material-symbols-outlined">keyboard_arrow_up</span>
                      </button>
                      <button
                        type="button"
                        class="stepper-btn"
                        tabindex="-1"
                        aria-label={$t('admin.decrease')}
                        disabled={$user?.role !== 'superuser' && selectedUser.role === 'superuser'}
                        on:click={decrementQuota}
                      >
                        <span class="material-symbols-outlined">keyboard_arrow_down</span>
                      </button>
                    </div>
                  </div>

                  <div class="select-wrapper quota-unit-select">
                    <select
                      class="custom-select"
                      bind:value={quotaUnit}
                      disabled={$user?.role !== 'superuser' && selectedUser.role === 'superuser'}
                      on:change={syncQuotaBytes}
                    >
                      {#each unitOptions as opt}
                        <option value={opt.multiplier}>{opt.label}</option>
                      {/each}
                    </select>
                    <span class="material-symbols-outlined select-arrow">expand_more</span>
                  </div>
                </div>
                {#if selectedUser.quota_bytes}
                  <small class="field-hint">≈ {formatBytes(selectedUser.quota_bytes)} ({Number(selectedUser.quota_bytes).toLocaleString()} {$t('admin.bytes_label')})</small>
                {/if}
              </div>
            {/if}

            <div class="dialog-actions">
              <button class="btn btn-primary" disabled={busy || ($user?.role !== 'superuser' && selectedUser.role === 'superuser')}>{$t('common.save')}</button>
              <button class="btn btn-secondary" type="button" disabled={busy || selectedUser.role === 'superuser' || ($user?.role !== 'superuser' && selectedUser.role === 'admin')} on:click={() => resetPassword(selectedUser)}>{$t('admin.reset_password')}</button>
              <button class="btn btn-secondary" type="button" disabled={busy || ($user?.role !== 'superuser' && selectedUser.role === 'superuser')} on:click={() => perform(() => apiPost(`/api/admin/users/${selectedUser.id}/revoke-sessions`, {}))}>{$t('admin.revoke_sessions')}</button>
              <button class="btn btn-danger" type="button" disabled={busy || maintenance.maintenance || isSelf(selectedUser) || selectedUser.role === 'superuser' || ($user?.role !== 'superuser' && selectedUser.role === 'admin')} on:click={() => deleteUser(selectedUser)}>{$t('common.delete')}</button>
            </div>
          {/if}
        </form>
      </div>
    {/if}
  {:else if section === 'applications'}
    {#if !applications.length}
      <div class="empty-placeholder">
        <span class="material-symbols-outlined empty-icon">how_to_reg</span>
        <p class="empty-sub">{$t('admin.no_applications')}</p>
      </div>
    {/if}
    {#each applications as person (person.id)}
      <article class="applicant-card">
        <div class="applicant-info">
          <strong>{person.username}</strong>
          <span class="text-sub">{new Date(person.created_at * 1000).toLocaleString()}</span>
        </div>
        <div class="applicant-actions">
          <button class="btn btn-primary" disabled={busy} on:click={() => perform(() => apiPost(`/api/admin/users/${person.id}/approve`, {}))}>{$t('admin.approve')}</button>
          <button class="btn btn-secondary" disabled={busy} on:click={() => perform(() => apiPost(`/api/admin/users/${person.id}/reject`, {}))}>{$t('admin.reject')}</button>
        </div>
      </article>
    {/each}
  {:else if section === 'reset_codes'}
    {#if !resetCodes.length}
      <div class="empty-placeholder">
        <span class="material-symbols-outlined empty-icon">lock_reset</span>
        <p class="empty-sub">{$t('admin.no_reset_codes')}</p>
      </div>
    {:else}
      <div class="table-card">
        <table>
          <thead>
            <tr>
              <th>{$t('common.name')}</th>
              <th>{$t('admin.role')}</th>
              <th>{$t('admin.reset_code')}</th>
              <th>{$t('admin.created_at')}</th>
              <th>{$t('admin.expires_in')}</th>
              <th style="width: 100px;"></th>
            </tr>
          </thead>
          <tbody>
            {#each resetCodes as item (item.id)}
              <tr>
                <td><strong>{item.username}</strong></td>
                <td>{$t(`admin.${item.role === 'superuser' ? 'superuser' : item.role === 'admin' ? 'administrator' : 'user'}`)}</td>
                <td>
                  <button class="btn-copy-code" type="button" on:click={() => copyCode(item.code)} title={$t('common.copy')}>
                    <code class="code-badge">{item.code}</code>
                    <span class="material-symbols-outlined icon-sm">{copiedCode === item.code ? 'check' : 'content_copy'}</span>
                  </button>
                </td>
                <td>{new Date(item.created_at * 1000).toLocaleTimeString()}</td>
                <td>
                  <span class="expires-badge" class:expires-soon={item.expires_at - nowSeconds < 120}>
                    {formatExpiresIn(item.expires_at)}
                  </span>
                </td>
                <td style="text-align: right;">
                  <button class="btn btn-danger" type="button" disabled={busy || ($user?.role !== 'superuser' && (item.role === 'admin' || item.role === 'superuser'))} on:click={() => deleteResetCode(item)}>{$t('common.delete')}</button>
                </td>
              </tr>
            {/each}
          </tbody>
        </table>
      </div>
    {/if}
  {:else if section === 'configuration' && config}
    <div class="settings-card config-card">
      {#if $user?.role !== 'superuser'}
        <p class="warning-banner" role="status">{$t('admin.superuser_required')}</p>
      {/if}
      <div class="config-banner">
        <span class="material-symbols-outlined banner-icon">info</span>
        <p>{$t('admin.config_hint')}</p>
      </div>
      <form on:submit|preventDefault={saveConfig}>
        <div class="settings-list">
          {#each config.fields.filter(field => !field.secret) as field}
            <label class="setting">
              <span class="setting-info">
                <strong class="setting-title">{fieldLabel(field)}</strong>
                <small class="setting-desc">{fieldHelp(field)}</small>
                <span class="setting-badges">
                  <span class="badge {field.apply === 'live' ? 'badge-live' : 'badge-restart'}">{$t(`admin.apply.${field.apply}`)}</span>
                  <span class="badge badge-source">{$t(`admin.source.${field.source}`)}</span>
                </span>
              </span>
              <div class="setting-control">
                {#if field.type === 'boolean'}
                  <label class="custom-checkbox">
                    <input type="checkbox" checked={edits[field.name] ?? field.value} disabled={!field.editable || busy || maintenance.maintenance || $user?.role !== 'superuser'} on:change={event => edits = {...edits, [field.name]: event.target.checked}} />
                    <span class="checkbox-indicator"></span>
                  </label>
                {:else if field.name === 'registration_mode' || field.name === 'log_level'}
                  <div class="select-wrapper">
                    <select class="custom-select" value={edits[field.name] ?? field.value} disabled={busy || maintenance.maintenance || $user?.role !== 'superuser'} on:change={event => edits = {...edits, [field.name]: event.target.value}}>
                      {#each field.name === 'registration_mode' ? ['approval', 'open', 'closed'] : ['TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR'] as option}
                        <option value={option}>{field.name === 'registration_mode' ? $t(`admin.registration.${option}`) : option}</option>
                      {/each}
                    </select>
                    <span class="material-symbols-outlined select-arrow">expand_more</span>
                  </div>
                {:else}
                  <input class="form-input" type={field.type === 'integer' ? 'number' : 'text'} value={edits[field.name] ?? field.value} disabled={!field.editable || busy || maintenance.maintenance || $user?.role !== 'superuser'} on:input={event => edits = {...edits, [field.name]: event.target.value}} />
                {/if}
                {#if field.pending}<small class="setting-pending">{$t('admin.pending')}: {String(field.effective)}</small>{/if}
              </div>
            </label>
          {/each}
        </div>
        <div class="config-actions">
          <button class="btn btn-primary" disabled={busy || maintenance.maintenance || !Object.keys(edits).length || $user?.role !== 'superuser'}>{$t('common.save')}</button>
        </div>
      </form>
    </div>
  {:else if section === 'maintenance'}
    <div class="settings-card maintenance-status-card">
      {#if $user?.role !== 'superuser'}
        <p class="warning-banner" role="status">{$t('admin.superuser_required')}</p>
      {/if}
      <div class="maintenance-header">
        <div>
          <h2>{$t('admin.rotation')}</h2>
          <p class="text-sub">{$t(`admin.phase.${maintenance.phase}`)}</p>
        </div>
      </div>
      {#if maintenance.files_total > 0}
        <div class="progress-bar-wrapper">
          <progress max={maintenance.files_total} value={maintenance.files_done} class="custom-progress"></progress>
          <p class="text-sub">{maintenance.files_done} / {maintenance.files_total} · {maintenance.bytes_done.toLocaleString()} / {maintenance.bytes_total.toLocaleString()} B</p>
        </div>
      {/if}
      {#if maintenance.error_code}
        <p class="error-banner" role="alert">{$t('admin.rotation_failed')} ({maintenance.error_code})</p>
      {/if}
      {#if maintenance.maintenance && !maintenance.running}
        <button class="btn btn-primary" disabled={busy || $user?.role !== 'superuser'} on:click={() => perform(() => apiPost('/api/admin/encryption-key/resume', {}))}>{$t('admin.retry')}</button>
      {/if}
    </div>

    {#if config}
      <div class="maintenance-grid">
        {#each config.fields.filter(field => field.secret) as field}
          <form class="settings-card maintenance-card" on:submit|preventDefault={() => rotate(field.name === 'jwt_secret' ? 'signing' : 'encryption')}>
            <div class="maintenance-card-header">
              <h2>{field.name}</h2>
              <span class="badge badge-source">{$t(`admin.source.${field.source}`)}</span>
            </div>
            {#if !field.editable}
              <p class="warning-banner">{$t('admin.environment_hint')}</p>
            {:else}
              <div class="form-group">
                <span class="form-label">{$t('admin.new_secret')}</span>
                {#if field.name === 'jwt_secret'}
                  <input class="form-input" type="password" autocomplete="new-password" minlength="32" maxlength="4096" bind:value={signingSecret} disabled={$user?.role !== 'superuser'} required />
                {:else}
                  <input class="form-input" type="password" autocomplete="new-password" minlength="32" maxlength="4096" bind:value={encryptionKey} disabled={$user?.role !== 'superuser'} required />
                {/if}
              </div>
              <div class="maintenance-actions">
                <button class="btn btn-primary" disabled={busy || maintenance.maintenance || $user?.role !== 'superuser'}>{$t('admin.rotate')}</button>
              </div>
            {/if}
          </form>
        {/each}
      </div>
    {/if}
  {/if}
</section>

<style>
  .administration { padding: var(--spacing-xl); max-width: 1180px; margin: 0 auto; color: var(--text-main); }
  .admin-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: var(--spacing-lg); }
  .admin-header h1 { margin: 0; font-size: calc(24px * var(--font-scale)); font-weight: 700; }
  
  .admin-nav { display: flex; gap: var(--spacing-xs); margin-bottom: var(--spacing-xl); border-bottom: 1px solid var(--border-color); }
  .nav-tab { border: 0; border-bottom: 2px solid transparent; background: transparent; color: var(--text-sub); padding: var(--spacing-sm) var(--spacing-md); font-family: inherit; font-size: calc(14px * var(--font-scale)); font-weight: 600; cursor: pointer; transition: color 0.15s ease, border-color 0.15s ease; }
  .nav-tab:hover { color: var(--text-main); }
  .nav-tab.active { color: var(--accent-color); border-bottom-color: var(--accent-color); }

  .table-card { background: var(--bg-surface); border: 1px solid var(--border-color); border-radius: var(--radius-xl); box-shadow: var(--shadow-card); overflow: auto; margin-bottom: var(--spacing-lg); }
  table { width: 100%; border-collapse: collapse; min-width: 680px; }
  th, td { padding: var(--spacing-md) var(--spacing-lg); text-align: left; border-bottom: 1px solid var(--border-color); }
  th { color: var(--text-sub); font-size: calc(12px * var(--font-scale)); font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; }
  tbody tr:last-child td { border-bottom: none; }
  tbody tr:hover { background: var(--bg-surface-hover); }

  .status { display: inline-flex; border-radius: var(--radius-full); background: color-mix(in srgb, var(--color-success) 18%, transparent); color: var(--color-success); padding: 3px 10px; font-size: calc(12px * var(--font-scale)); font-weight: 600; }
  .status.blocked { background: color-mix(in srgb, var(--color-danger) 18%, transparent); color: var(--color-danger); }

  .code-badge { font-family: var(--font-mono); font-size: calc(15px * var(--font-scale)); font-weight: 700; letter-spacing: 0.15em; background: var(--bg-input); color: var(--text-main); padding: 4px 10px; border-radius: var(--radius-sm); border: 1px solid var(--border-color); }
  .btn-copy-code { display: inline-flex; align-items: center; gap: var(--spacing-xs); background: transparent; border: none; padding: 2px 6px; cursor: pointer; border-radius: var(--radius-sm); transition: background-color 0.15s ease; }
  .btn-copy-code:hover { background-color: var(--bg-surface-hover); }
  .icon-sm { font-size: 18px; color: var(--text-sub); }
  .expires-badge { display: inline-flex; border-radius: var(--radius-full); background: color-mix(in srgb, var(--accent-color) 15%, transparent); color: var(--accent-color); padding: 3px 10px; font-size: calc(12px * var(--font-scale)); font-weight: 600; font-family: var(--font-mono); }
  .expires-badge.expires-soon { background: color-mix(in srgb, var(--color-danger) 18%, transparent); color: var(--color-danger); }

  .modal-backdrop { position: fixed; inset: 0; z-index: 1000; display: grid; place-items: center; padding: var(--spacing-lg); background: color-mix(in srgb, #000 65%, transparent); backdrop-filter: blur(4px); }
  .user-details { width: min(100%, 480px); max-height: calc(100vh - 32px); overflow: auto; margin: 0; background: var(--bg-surface); border: 1px solid var(--border-color); border-radius: var(--radius-xl); box-shadow: var(--shadow-card); padding: var(--spacing-xl); display: flex; flex-direction: column; gap: var(--spacing-md); }
  .dialog-heading { display: flex; justify-content: space-between; align-items: flex-start; flex-wrap: nowrap; margin-bottom: var(--spacing-xs); }
  .dialog-heading h2 { margin: 0 0 4px 0; font-size: calc(20px * var(--font-scale)); font-weight: 700; overflow-wrap: anywhere; }
  .user-details .form-group { margin: 0; display: flex; flex-direction: column; gap: var(--spacing-xs); }
  .user-details .select-wrapper { width: 100%; max-width: 100%; position: relative; }
  .user-details .select-wrapper .custom-select { width: 100%; height: 42px; padding: 0 36px 0 16px; font-size: calc(14px * var(--font-scale)); text-align: left; }
  .quota-input-group { display: flex; gap: var(--spacing-sm); align-items: center; width: 100%; }
  .custom-number-stepper { position: relative; flex: 1; min-width: 0; display: flex; align-items: center; }
  .stepper-input { width: 100%; height: 42px; padding: 0 32px 0 16px; appearance: textfield; -moz-appearance: textfield; }
  .stepper-input::-webkit-inner-spin-button, .stepper-input::-webkit-outer-spin-button { -webkit-appearance: none; margin: 0; }
  .stepper-buttons { position: absolute; right: 4px; top: 3px; bottom: 3px; width: 24px; display: flex; flex-direction: column; justify-content: center; z-index: 2; }
  .stepper-btn { flex: 1; display: flex; align-items: center; justify-content: center; background: transparent; border: none; padding: 0; margin: 0; color: var(--text-sub); cursor: pointer; border-radius: var(--radius-sm); transition: background-color 0.15s ease, color 0.15s ease; }
  .stepper-btn:hover { background-color: var(--bg-surface-hover); color: var(--text-main); }
  .stepper-btn:active { color: var(--accent-color); }
  .stepper-btn .material-symbols-outlined { font-size: 18px; line-height: 1; user-select: none; }
  .user-details .quota-unit-select { flex: 1.2; min-width: 140px; width: auto; }
  .field-hint { display: block; font-size: calc(12px * var(--font-scale)); color: var(--text-sub); margin-top: 2px; }
  .dialog-actions { display: flex; flex-wrap: wrap; gap: var(--spacing-sm); justify-content: flex-end; margin-top: var(--spacing-sm); }

  .config-card { background: var(--bg-surface); border: 1px solid var(--border-color); border-radius: var(--radius-xl); box-shadow: var(--shadow-card); padding: var(--spacing-xl); }
  .config-banner { display: flex; align-items: flex-start; gap: var(--spacing-md); padding: var(--spacing-md); background: color-mix(in srgb, var(--accent-color) 8%, var(--bg-surface)); border: 1px solid color-mix(in srgb, var(--accent-color) 20%, transparent); border-radius: var(--radius-md); margin-bottom: var(--spacing-lg); color: var(--text-main); font-size: calc(13px * var(--font-scale)); line-height: 1.4; }
  .config-banner .banner-icon { color: var(--accent-color); font-size: 20px; flex-shrink: 0; }
  .config-banner p { margin: 0; }
  .settings-list { display: flex; flex-direction: column; }
  .setting { display: grid; grid-template-columns: minmax(0, 1fr) minmax(200px, 320px); align-items: center; gap: var(--spacing-xl); padding: var(--spacing-lg) 0; border-bottom: 1px solid var(--border-color); cursor: default; }
  .setting:last-child { border-bottom: none; }
  .setting-info { display: flex; flex-direction: column; gap: var(--spacing-xs); }
  .setting-title { font-size: calc(14px * var(--font-scale)); color: var(--text-main); font-weight: 600; }
  .setting-desc { color: var(--text-sub); font-size: calc(12px * var(--font-scale)); line-height: 1.35; }
  .setting-badges { display: flex; gap: var(--spacing-xs); margin-top: var(--spacing-xs); }
  .badge { font-size: calc(11px * var(--font-scale)); padding: 2px 8px; border-radius: var(--radius-full); font-weight: 600; display: inline-flex; }
  .badge-live { background: color-mix(in srgb, var(--color-success) 15%, transparent); color: var(--color-success); }
  .badge-restart { background: color-mix(in srgb, var(--color-warning) 15%, transparent); color: var(--color-warning); }
  .badge-source { background: var(--bg-surface-hover); color: var(--text-sub); border: 1px solid var(--border-color); }
  .setting-control { display: flex; flex-direction: column; gap: var(--spacing-xs); align-items: flex-end; width: 100%; }
  .setting-control .form-input, .setting-control .select-wrapper { width: 100%; max-width: 320px; }
  .setting-control .select-wrapper .custom-select { width: 100%; height: 42px; padding: 0 36px 0 16px; font-size: calc(14px * var(--font-scale)); }
  .setting-pending { color: var(--color-warning); font-size: calc(12px * var(--font-scale)); }
  .config-actions { margin-top: var(--spacing-lg); display: flex; justify-content: flex-end; }

  .maintenance-status-card { background: var(--bg-surface); border: 1px solid var(--border-color); border-radius: var(--radius-xl); box-shadow: var(--shadow-card); padding: var(--spacing-xl); margin-bottom: var(--spacing-lg); }
  .maintenance-header { display: flex; justify-content: space-between; align-items: center; }
  .maintenance-header h2 { margin: 0 0 4px 0; font-size: calc(18px * var(--font-scale)); font-weight: 700; }
  .maintenance-header p { margin: 0; }
  .progress-bar-wrapper { display: flex; flex-direction: column; gap: var(--spacing-xs); margin: var(--spacing-md) 0; }
  progress.custom-progress { width: 100%; height: 8px; border-radius: var(--radius-full); overflow: hidden; appearance: none; -webkit-appearance: none; background: var(--bg-input); }
  progress.custom-progress::-webkit-progress-bar { background: var(--bg-input); border-radius: var(--radius-full); }
  progress.custom-progress::-webkit-progress-value { background: var(--accent-color); border-radius: var(--radius-full); }
  progress.custom-progress::-moz-progress-bar { background: var(--accent-color); border-radius: var(--radius-full); }

  .maintenance-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: var(--spacing-lg); }
  .maintenance-card { background: var(--bg-surface); border: 1px solid var(--border-color); border-radius: var(--radius-xl); box-shadow: var(--shadow-card); padding: var(--spacing-xl); display: flex; flex-direction: column; gap: var(--spacing-md); }
  .maintenance-card-header { display: flex; justify-content: space-between; align-items: center; }
  .maintenance-card-header h2 { margin: 0; font-size: calc(16px * var(--font-scale)); font-weight: 700; }
  .maintenance-card .form-group { margin: 0; display: flex; flex-direction: column; gap: var(--spacing-xs); }
  .maintenance-actions { display: flex; justify-content: flex-end; margin-top: var(--spacing-xs); }

  .applicant-card { display: flex; justify-content: space-between; align-items: center; background: var(--bg-surface); border: 1px solid var(--border-color); border-radius: var(--radius-lg); padding: var(--spacing-md) var(--spacing-lg); margin-bottom: var(--spacing-sm); }
  .applicant-info { display: flex; flex-direction: column; gap: 2px; }
  .applicant-actions { display: flex; gap: var(--spacing-sm); }

  .empty-placeholder { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 48px var(--spacing-lg); text-align: center; }
  .empty-icon { font-size: 48px; color: var(--text-sub); opacity: 0.6; margin-bottom: var(--spacing-sm); }
  .empty-sub { color: var(--text-sub); font-size: calc(14px * var(--font-scale)); margin: 0; }

  .error-banner { background: color-mix(in srgb, var(--color-danger) 14%, transparent); border: 1px solid color-mix(in srgb, var(--color-danger) 30%, transparent); color: var(--color-danger); padding: var(--spacing-md); border-radius: var(--radius-md); margin-bottom: var(--spacing-md); font-size: calc(13px * var(--font-scale)); }
  .warning-banner { background: color-mix(in srgb, var(--color-warning) 14%, transparent); border: 1px solid color-mix(in srgb, var(--color-warning) 30%, transparent); padding: var(--spacing-md); border-radius: var(--radius-md); margin-bottom: var(--spacing-md); font-size: calc(13px * var(--font-scale)); }
  .recovery-banner { background: color-mix(in srgb, var(--color-warning) 14%, transparent); border: 1px solid color-mix(in srgb, var(--color-warning) 30%, transparent); padding: var(--spacing-md); border-radius: var(--radius-md); margin-bottom: var(--spacing-md); }
  .recovery-banner code { display: block; font-size: 2rem; letter-spacing: .2em; margin: var(--spacing-sm) 0 var(--spacing-md) 0; font-family: var(--font-mono); }

  @media (max-width: 768px) {
    .administration { padding: var(--spacing-md); }
    .setting { grid-template-columns: 1fr; gap: var(--spacing-sm); }
    .setting-control { align-items: stretch; }
    .setting-control .form-input, .setting-control .select-wrapper { max-width: 100%; }
    .user-details { padding: var(--spacing-lg); }
  }
  @media (max-width: 480px) {
    .quota-input-group { flex-direction: column; align-items: stretch; }
  }
</style>
