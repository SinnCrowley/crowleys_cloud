// Copyright (C) 2026 Sinn Crowley
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'dart:io';

import 'package:crowleys_cloud/l10n/generated/app_localizations.dart';
import 'package:crowleys_cloud/l10n/localization_fallback.dart';

import 'package:crowleys_cloud/active_server_manager.dart';
import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/app_settings_service.dart';
import 'package:crowleys_cloud/app_update_service.dart';
import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/biometric_auth_service.dart';
import 'package:crowleys_cloud/cache_service.dart';
import 'package:crowleys_cloud/file_browser.dart';
import 'package:crowleys_cloud/file_browser_controller.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:crowleys_cloud/server_setup_screen.dart';
import 'package:crowleys_cloud/sync_scheduler.dart';
import 'package:crowleys_cloud/sync_service.dart';
import 'package:crowleys_cloud/shared/utils/byte_formatter.dart';
import 'package:crowleys_cloud/theme_customizer_dialog.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

const _syncCategoryOptions = [
  _SyncCategoryOption('photos', 'Photos', Icons.photo_outlined),
  _SyncCategoryOption('videos', 'Videos', Icons.videocam_outlined),
  _SyncCategoryOption('audio', 'Audio', Icons.audiotrack_outlined),
  _SyncCategoryOption('documents', 'Documents', Icons.description_outlined),
  _SyncCategoryOption('other', 'Other files', Icons.insert_drive_file_outlined),
];

class _SyncCategoryOption {
  const _SyncCategoryOption(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;
}

class SettingsScreen extends StatefulWidget {
  SettingsScreen({
    super.key,
    required this.serverManager,
    AppSettingsService? settingsService,
    BiometricAuthService? biometricAuthService,
    CacheService? cacheService,
    this.syncService,
    this.syncStateStore = const FileSyncStateStore(),
    this.syncScheduler,
    this.localFolderPicker,
    this.onLocaleChanged,
  }) : settingsService = settingsService ?? AppSettingsService(),
       biometricAuthService = biometricAuthService ?? BiometricAuthService(),
       cacheService = cacheService ?? CacheService.instance;

  final ActiveServerManager serverManager;
  final AppSettingsService settingsService;
  final BiometricAuthService biometricAuthService;
  final CacheService cacheService;
  final SyncService? syncService;
  final SyncStateStore syncStateStore;
  final SyncBackgroundScheduler? syncScheduler;
  final Future<String?> Function(BuildContext context)? localFolderPicker;
  final Future<void> Function(Locale? locale)? onLocaleChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  bool _showHiddenFiles = false;
  bool _biometricLoginEnabled = false;
  bool _canUseBiometrics = false;
  TokenLifetimeOption _tokenLifetime = TokenLifetimeOption.everyOpen;
  int _cacheMaxBytes = CacheService.defaultThumbnailMaxBytes;
  int _cacheSizeBytes = 0;
  String? _downloadPath;
  String? _selectedSyncServerId;
  SyncRunResult? _lastSyncResult;
  bool _isSyncing = false;
  double? _syncProgressPercent;
  String _defaultTargetDir = '/backup/device';
  bool _isCheckingUpdate = false;
  String? _localeCode;

  SyncService get _syncService {
    return widget.syncService ??
        SyncService(
          scanner: DeviceSyncFileScanner(),
          apiClient: HttpSyncApiClient(
            authService: widget.serverManager.authService,
          ),
          stateStore: widget.syncStateStore,
        );
  }

  ServerProfile? get _selectedSyncServer {
    final selectedId = _selectedSyncServerId;
    if (selectedId != null) {
      final selected = widget.serverManager.servers
          .where((server) => server.id == selectedId)
          .firstOrNull;
      if (selected != null) return selected;
    }
    return widget.serverManager.activeServer ??
        widget.serverManager.servers.firstOrNull;
  }

  Map<String, Object?> get _syncPrefs {
    return _selectedSyncServer?.syncPrefs ?? const {};
  }

  bool _syncBool(String key, bool fallback) {
    final value = _syncPrefs[key];
    return value is bool ? value : fallback;
  }

  String _syncString(String key, String fallback) {
    final value = _syncPrefs[key];
    if (value is String && value.trim().isNotEmpty) return value;
    return fallback;
  }

  String _defaultTargetDirectory() {
    return _defaultTargetDir;
  }

  String _displayLocalFolderPath(String path, [AppLocalizations? l10n]) {
    const androidPrimaryStoragePrefix = '/storage/emulated/0';
    final trimmed = path.trim();
    final storageLabel = (l10n ?? platformAppLocalizations()).storageRoot;
    if (trimmed == androidPrimaryStoragePrefix) return storageLabel;
    if (trimmed.startsWith('$androidPrimaryStoragePrefix/')) {
      final relative = trimmed.substring(androidPrimaryStoragePrefix.length);
      return relative.isEmpty ? storageLabel : relative;
    }
    return trimmed;
  }

  List<String> _syncStringList(String key) {
    final value = _syncPrefs[key];
    if (value is List) {
      return value
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  List<String> _syncCategories() {
    final raw = _syncPrefs['syncCategories'];
    if (raw is List) {
      return raw
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  @override
  void initState() {
    super.initState();
    widget.serverManager.addListener(_onServerChanged);
    _load();
  }

  @override
  void dispose() {
    widget.serverManager.removeListener(_onServerChanged);
    super.dispose();
  }

  void _onServerChanged() {
    if (!mounted) return;
    final selectedId = _selectedSyncServerId;
    if (selectedId != null &&
        !widget.serverManager.servers.any(
          (server) => server.id == selectedId,
        )) {
      _selectedSyncServerId =
          widget.serverManager.activeServer?.id ??
          widget.serverManager.servers.firstOrNull?.id;
    }
    setState(() {});
    _loadLastSyncResult();
  }

  Future<void> _load() async {
    final results = await Future.wait<Object?>([
      widget.settingsService.showHiddenFiles(),
      widget.settingsService.biometricLoginEnabled(),
      widget.biometricAuthService.canAuthenticate(),
      widget.settingsService.tokenLifetime(),
      widget.settingsService.cacheMaxBytes(),
      widget.cacheService.cacheSizeBytes(),
      widget.settingsService.downloadDirectoryPath(),
      widget.settingsService.defaultBackupTargetDirectory(),
      widget.settingsService.localeCode(),
    ]);
    if (!mounted) return;
    setState(() {
      _showHiddenFiles = results[0]! as bool;
      _biometricLoginEnabled = results[1]! as bool;
      _canUseBiometrics = results[2]! as bool;
      _tokenLifetime = results[3]! as TokenLifetimeOption;
      _cacheMaxBytes = results[4]! as int;
      _cacheSizeBytes = results[5]! as int;
      _downloadPath = results[6] as String?;
      _defaultTargetDir = results[7]! as String;
      _localeCode = results[8] as String?;
      _selectedSyncServerId =
          widget.serverManager.activeServer?.id ??
          widget.serverManager.servers.firstOrNull?.id;
      _isLoading = false;
    });
    await _loadLastSyncResult();
  }

  Future<void> _loadLastSyncResult() async {
    final serverId = _selectedSyncServer?.id;
    final result = serverId == null
        ? null
        : await widget.syncStateStore.readLastResult(serverId);
    if (!mounted) return;
    setState(() => _lastSyncResult = result);
  }

  Future<void> _setShowHiddenFiles(bool value) async {
    await widget.settingsService.setShowHiddenFiles(value);
    if (!mounted) return;
    setState(() => _showHiddenFiles = value);
  }

  Future<void> _setBiometricLoginEnabled(bool value) async {
    if (value && !_canUseBiometrics) return;
    await widget.settingsService.setBiometricLoginEnabled(value);
    if (!mounted) return;
    setState(() => _biometricLoginEnabled = value);
  }

  Future<void> _setLocaleCode(String? code) async {
    await widget.settingsService.setLocaleCode(code);
    await widget.onLocaleChanged?.call(
      code == null
          ? null
          : code == 'pt-BR'
          ? const Locale('pt', 'BR')
          : code == 'zh-Hans'
          ? const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans')
          : Locale(code),
    );
    if (mounted) setState(() => _localeCode = code);
  }

  Future<void> _setTokenLifetime(TokenLifetimeOption? value) async {
    if (value == null) return;
    await widget.settingsService.setTokenLifetime(value);
    for (final server in widget.serverManager.servers) {
      await widget.serverManager.authService
          .persistCurrentSessionForConfiguredLifetime(server.id);
    }
    if (!mounted) return;
    setState(() => _tokenLifetime = value);
  }

  Future<void> _changeActiveServerPassword() async {
    final server = widget.serverManager.activeServer;
    if (server == null) return;

    final password = await showDialog<String?>(
      context: context,
      builder: (context) => const _PasswordChangeDialog(),
    );
    if (password == null) return;

    try {
      await widget.serverManager.authService.changePassword(
        serverId: server.id,
        baseUrl: server.connectionUrl,
        newPassword: password,
      );
      await widget.serverManager.markAuthed(server.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.passwordUpdated)),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.passwordChangeFailed(e.message),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.passwordChangeFailedGeneric,
          ),
        ),
      );
    }
  }

  Future<void> _deleteActiveServerAccount() async {
    final server = widget.serverManager.activeServer;
    if (server == null) return;

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appSurface,
        title: Text(l10n.deleteAccountTitle),
        content: Text(l10n.deleteAccountBody(server.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteAccountButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.serverManager.authService.deleteAccount(
        serverId: server.id,
        baseUrl: server.connectionUrl,
      );
      await widget.serverManager.removeServer(server.id);
      if (!mounted) return;
      setState(() {
        _selectedSyncServerId =
            widget.serverManager.activeServer?.id ??
            widget.serverManager.servers.firstOrNull?.id;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.accountDeleted)));
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountDeletionFailed(e.message))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountDeletionFailedGeneric)),
      );
    }
  }

  Future<void> _setCacheLimit(int? value) async {
    if (value == null) return;
    await widget.cacheService.setThumbnailMaxBytes(value);
    if (!mounted) return;
    setState(() => _cacheMaxBytes = value);
    await _refreshCacheSize();
  }

  Future<void> _refreshCacheSize() async {
    final size = await widget.cacheService.cacheSizeBytes();
    if (!mounted) return;
    setState(() => _cacheSizeBytes = size);
  }

  Future<void> _clearCache() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appSurface,
        title: Text(l10n.clearCacheTitle),
        content: Text(l10n.clearCacheBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.clear),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.cacheService.clearAll();
    await _refreshCacheSize();
  }

  Future<void> _editDownloadPath() async {
    final l10n = AppLocalizations.of(context)!;
    final path = await showDialog<String?>(
      context: context,
      builder: (context) => _TextInputDialog(
        title: l10n.downloadPathDialogTitle,
        initialValue: _downloadPath ?? '',
        hintText: l10n.downloadPathHint,
        secondaryActionLabel: l10n.useDefault,
        secondaryActionValue: '',
      ),
    );
    if (path == null) return;
    await widget.settingsService.setDownloadDirectoryPath(path);
    if (!mounted) return;
    setState(() => _downloadPath = path.trim().isEmpty ? null : path.trim());
  }

  Future<void> _editTargetDirectory() async {
    final l10n = AppLocalizations.of(context)!;
    final current = _syncString(
      'backupTargetDirectory',
      _defaultTargetDirectory(),
    );
    final initial =
        (current == '/backup/localhost' || current == 'backup/localhost')
            ? _defaultTargetDirectory()
            : current;
    final path = await showDialog<String?>(
      context: context,
      builder: (context) => _TextInputDialog(
        title: l10n.serverTargetDirDialogTitle,
        initialValue: initial,
        hintText: l10n.serverTargetDirectoryHint,
      ),
    );
    if (path == null) return;
    await _updateSyncPrefs({'backupTargetDirectory': path.trim()});
  }

  Future<void> _addSyncFolder() async {
    final path = await _pickLocalFolder();
    if (path == null || path.trim().isEmpty) return;
    final folders = {..._syncStringList('syncFolders'), path.trim()}.toList()
      ..sort();
    await _updateSyncPrefs({'syncFolders': folders});
  }

  Future<void> _openAddServerFlow() async {
    final setupResult = await Navigator.of(context).push<ServerSetupResult>(
      MaterialPageRoute(
        builder: (_) =>
            ServerSetupScreen(authService: widget.serverManager.authService),
      ),
    );
    if (setupResult == null) return;

    try {
      await widget.serverManager.addServer(setupResult.profile);
      await widget.serverManager.markAuthed(setupResult.profile.id);
      await widget.syncScheduler?.scheduleForServers(
        widget.serverManager.servers,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.failedToSaveServer(e.toString()),
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _selectedSyncServerId = setupResult.profile.id);
  }

  Future<void> _removeServer(ServerProfile server) async {
    await widget.serverManager.removeServer(server.id);
    await widget.syncScheduler?.scheduleForServers(
      widget.serverManager.servers,
    );
    if (!mounted) return;
    setState(() {
      if (_selectedSyncServerId == server.id) {
        _selectedSyncServerId =
            widget.serverManager.activeServer?.id ??
            widget.serverManager.servers.firstOrNull?.id;
      }
    });
  }

  Future<String?> _pickLocalFolder() async {
    final picker = widget.localFolderPicker;
    if (picker != null) return picker(context);

    if (!Platform.environment.containsKey('FLUTTER_TEST') &&
        Platform.isAndroid) {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          await openAppSettings();
          status = await Permission.manageExternalStorage.status;
        }
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.manageStoragePermissionRequired,
                ),
              ),
            );
          }
          return null;
        }
      }
    }

    Directory? startDir;
    final storageDirs = await getExternalStorageDirectories();
    if (storageDirs != null && storageDirs.isNotEmpty) {
      final root = extractRootPath(storageDirs.first.path);
      if (root != null) startDir = Directory(root);
    }
    if (startDir == null || !mounted) return null;

    final l10n = AppLocalizations.of(context)!;
    final controller = FileBrowserController(
      category: FileCategory(l10n.allFiles, Icons.folder_outlined),
      loadOnInit: false,
      settingsService: widget.settingsService,
    );
    try {
      return await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => LocalFolderPickerScreen(
            controller: controller,
            initialPath: startDir!.path,
          ),
        ),
      );
    } finally {
      controller.disposeController();
      controller.dispose();
    }
  }

  Future<void> _removeSyncFolder(String folder) async {
    final folders = _syncStringList(
      'syncFolders',
    ).where((item) => item != folder).toList(growable: false);
    await _updateSyncPrefs({'syncFolders': folders});
  }

  Future<void> _editSyncCategories() async {
    final current = _syncCategories().toSet();
    final selected = await showDialog<Set<String>?>(
      context: context,
      builder: (context) => _SyncCategoriesDialog(initialSelected: current),
    );
    if (selected == null) return;
    final ordered = _syncCategoryOptions
        .map((option) => option.id)
        .where(selected.contains)
        .toList(growable: false);
    await _updateSyncPrefs({'syncCategories': ordered});

    final server = _selectedSyncServer;
    if (server != null) {
      await _requestPermissionsForServerSync(server);
    }
  }

  String _syncFrequencyLabel(AppLocalizations l10n, int minutes) {
    if (minutes == 15) return l10n.syncFreqEvery15Min;
    if (minutes == 30) return l10n.syncFreqEvery30Min;
    if (minutes == 60) return l10n.syncFreqEvery1Hour;
    if (minutes % 60 == 0) {
      final hours = minutes ~/ 60;
      if (hours == 1) return l10n.syncFreqEvery1Hour;
      if (hours == 24) return l10n.syncFreqDaily;
      return l10n.syncFreqEveryNHours(hours);
    }
    return l10n.syncFreqEveryNMin(minutes);
  }

  Future<void> _showSyncFrequencyPicker() async {
    final current = _syncPrefs['syncFrequency'] as int? ?? 15;
    final options = [15, 30, 60, 120, 240, 480, 720, 1440];
    final l10n = AppLocalizations.of(context)!;

    final selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: appSurface,
        title: Text(
          l10n.chooseSyncFrequencyTitle,
          style: TextStyle(color: appText),
        ),
        children: options.map((minutes) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, minutes),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _syncFrequencyLabel(l10n, minutes),
                  style: TextStyle(color: appText),
                ),
                if (minutes == current)
                  Icon(Icons.check, color: appAccent, size: 20),
              ],
            ),
          );
        }).toList(),
      ),
    );
    if (selected != null) {
      await _updateSyncPrefs({'syncFrequency': selected});
    }
  }

  Future<void> _updateSyncPrefs(Map<String, Object?> updates) async {
    final serverId = _selectedSyncServer?.id;
    if (serverId == null) return;
    await widget.serverManager.updateServerSyncPrefs(serverId, updates);
    await widget.syncScheduler?.scheduleForServers(
      widget.serverManager.servers,
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<bool> _requestPermissionsForServerSync(ServerProfile server) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
    if (!Platform.isAndroid) return true;

    final categories = _syncStringList('syncCategories');
    final folders = _syncStringList('syncFolders');
    if (categories.isEmpty && folders.isEmpty) {
      return true;
    }

    final needed = <Permission>{
      Permission.notification,
      Permission.ignoreBatteryOptimizations,
    };
    if (folders.isNotEmpty) {
      needed.add(Permission.manageExternalStorage);
    }

    for (final cat in categories) {
      if (cat == 'photos') {
        needed.add(Permission.photos);
      } else if (cat == 'videos') {
        needed.add(Permission.videos);
      } else if (cat == 'audio') {
        needed.add(Permission.audio);
      } else {
        needed.add(Permission.manageExternalStorage);
      }
    }

    var allGranted = true;
    for (final perm in needed) {
      var status = await perm.status;
      if (!status.isGranted) {
        status = await perm.request();
        if (perm == Permission.manageExternalStorage && !status.isGranted) {
          await openAppSettings();
          status = await perm.status;
        }
        if (!status.isGranted) {
          allGranted = false;
        }
      }
    }
    return allGranted;
  }

  Future<void> _syncSelectedServerNow() async {
    final server = _selectedSyncServer;
    if (server == null || _isSyncing) return;
    final l10n = AppLocalizations.of(context)!;

    final hasPermission = await _requestPermissionsForServerSync(server);
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.storagePermissionsRequired)));
      return;
    }

    setState(() {
      _isSyncing = true;
      _syncProgressPercent = null;
    });
    final result = await _syncService.syncServer(
      server,
      l10n: l10n,
      onProgress: (message, progress) {
        if (!mounted) return;
        setState(() {
          _syncProgressPercent = progress;
        });
      },
    );
    if (!mounted) return;
    setState(() {
      _lastSyncResult = result;
      _isSyncing = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_syncResultMessage(l10n, result))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        backgroundColor: appSurface,
        surfaceTintColor: appSurface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _themeSection(l10n),
                const SizedBox(height: 14),
                _backupSection(l10n),
                const SizedBox(height: 14),
                _cacheSection(l10n),
                const SizedBox(height: 14),
                _securitySection(l10n),
                const SizedBox(height: 14),
                _aboutSection(l10n),
              ],
            ),
    );
  }

  Widget _backupSection(AppLocalizations l10n) {
    final selectedServer = _selectedSyncServer;
    final hasSelectedServer = selectedServer != null;
    final syncEnabled = _syncBool('syncEnabled', false);
    final wifiOnly = _syncBool('backupWifiOnly', true);
    final chargingOnly = _syncBool('backupChargingOnly', false);
    final rawTarget = _syncString(
      'backupTargetDirectory',
      _defaultTargetDirectory(),
    );
    final target =
        (rawTarget == '/backup/localhost' || rawTarget == 'backup/localhost')
            ? _defaultTargetDirectory()
            : rawTarget;
    final syncCategories = _syncCategories();
    final syncFolders = _syncStringList('syncFolders');

    return _SettingsSection(
      title: l10n.sectionBackupSync,
      children: [
        if (widget.serverManager.servers.isEmpty)
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: Text(l10n.noServersConfiguredSync),
            subtitle: Text(l10n.addServerBeforeSync),
            trailing: IconButton(
              tooltip: l10n.addServer,
              icon: const Icon(Icons.add),
              onPressed: _openAddServerFlow,
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: Text(
              l10n.selectServerToConfigureSync,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          ...widget.serverManager.servers.map((server) {
            final isSelected = selectedServer?.id == server.id;
            final isActive = widget.serverManager.activeServer?.id == server.id;
            return ListTile(
              selected: isSelected,
              leading: Icon(
                Icons.dns_outlined,
                color: isSelected ? appAccent : appSubtext,
              ),
              title: Text(server.displayName, style: TextStyle(color: appText)),
              subtitle: Text(
                isActive
                    ? '${server.baseUrl} ${l10n.activeServerSuffix}'
                    : server.baseUrl,
                style: TextStyle(color: appSubtext),
              ),
              onTap: () {
                setState(() => _selectedSyncServerId = server.id);
                _loadLastSyncResult();
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) Icon(Icons.check, color: appAccent),
                  IconButton(
                    tooltip: l10n.removeServer,
                    icon: Icon(Icons.delete_outline, color: appSubtext),
                    onPressed: () => _removeServer(server),
                  ),
                ],
              ),
            );
          }),
          ListTile(
            leading: Icon(Icons.add, color: appSubtext),
            title: Text(l10n.addServer, style: TextStyle(color: appText)),
            onTap: _openAddServerFlow,
          ),
        ],
        SwitchListTile(
          secondary: Icon(Icons.sync, color: appAccent),
          title: Text(
            l10n.folderAndCategorySync,
            style: TextStyle(color: appText),
          ),
          subtitle: Text(
            hasSelectedServer
                ? l10n.keepCategoriesSynced
                : l10n.addServerBeforeSyncEnable,
            style: TextStyle(color: appSubtext),
          ),
          value: hasSelectedServer && syncEnabled,
          onChanged: hasSelectedServer
              ? (value) async {
                  await _updateSyncPrefs({'syncEnabled': value});
                }
              : null,
        ),
        if (hasSelectedServer && syncEnabled) ...[
          ListTile(
            leading: Icon(Icons.wifi, color: appAccent),
            title: Text(l10n.onlyOnWifi, style: TextStyle(color: appText)),
            trailing: Switch(
              value: wifiOnly,
              onChanged: (value) => _updateSyncPrefs({'backupWifiOnly': value}),
            ),
          ),
          ListTile(
            leading: Icon(Icons.battery_charging_full, color: appAccent),
            title: Text(
              l10n.onlyWhileCharging,
              style: TextStyle(color: appText),
            ),
            trailing: Switch(
              value: chargingOnly,
              onChanged: (value) =>
                  _updateSyncPrefs({'backupChargingOnly': value}),
            ),
          ),
          ListTile(
            enabled: hasSelectedServer,
            leading: Icon(Icons.folder_outlined, color: appAccent),
            title: Text(
              l10n.serverTargetDirectory,
              style: TextStyle(color: appText),
            ),
            subtitle: Text(target, style: TextStyle(color: appSubtext)),
            trailing: Icon(Icons.chevron_right, color: appSubtext),
            onTap: hasSelectedServer ? _editTargetDirectory : null,
          ),
          ListTile(
            enabled: hasSelectedServer,
            leading: Icon(Icons.av_timer, color: appAccent),
            title: Text(
              l10n.synchronizationFrequency,
              style: TextStyle(color: appText),
            ),
            subtitle: Text(
              _syncFrequencyLabel(
                l10n,
                _syncPrefs['syncFrequency'] as int? ?? 15,
              ),
              style: TextStyle(color: appSubtext),
            ),
            trailing: Icon(Icons.arrow_drop_down, color: appSubtext),
            onTap: hasSelectedServer ? _showSyncFrequencyPicker : null,
          ),
          ListTile(
            enabled: hasSelectedServer && !_isSyncing,
            leading: _isSyncing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.sync_outlined, color: appAccent),
            title: Text(l10n.syncNow, style: TextStyle(color: appText)),
            subtitle: _isSyncing
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        l10n.syncing,
                        style: TextStyle(color: appSubtext, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _syncProgressPercent,
                          minHeight: 4,
                          backgroundColor: appBorder.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(appAccent),
                        ),
                      ),
                    ],
                  )
                : Text(
                    _syncStatusLabel(l10n, _lastSyncResult),
                    style: TextStyle(color: appSubtext),
                  ),
            trailing: _isSyncing
                ? null
                : Icon(Icons.chevron_right, color: appSubtext),
            onTap: hasSelectedServer && !_isSyncing
                ? _syncSelectedServerNow
                : null,
          ),
          ListTile(
            leading: Icon(Icons.category_outlined, color: appAccent),
            title: Text(
              l10n.categoriesToSynchronize,
              style: TextStyle(color: appText),
            ),
            subtitle: Text(
              syncCategories.isEmpty
                  ? l10n.noCategoriesSelected
                  : l10n.nCategoriesSelected(syncCategories.length),
              style: TextStyle(color: appSubtext),
            ),
            trailing: Icon(Icons.chevron_right, color: appSubtext),
            onTap: _editSyncCategories,
          ),
          ListTile(
            leading: Icon(Icons.folder_copy_outlined, color: appAccent),
            title: Text(
              l10n.foldersToSynchronize,
              style: TextStyle(color: appText),
            ),
            subtitle: Text(
              syncFolders.isEmpty
                  ? l10n.noCustomFolders
                  : syncFolders.length == 1
                  ? _displayLocalFolderPath(syncFolders.single, l10n)
                  : l10n.nFolders(syncFolders.length),
              style: TextStyle(color: appSubtext),
            ),
            onTap: hasSelectedServer ? _addSyncFolder : null,
            trailing: IconButton(
              tooltip: l10n.addFolder,
              icon: Icon(Icons.add, color: appSubtext),
              onPressed: hasSelectedServer ? _addSyncFolder : null,
            ),
          ),
          ...syncFolders.map((folder) {
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 56, right: 16),
              title: Text(_displayLocalFolderPath(folder, l10n)),
              trailing: IconButton(
                tooltip: l10n.removeFolder,
                icon: const Icon(Icons.close),
                onPressed: hasSelectedServer
                    ? () => _removeSyncFolder(folder)
                    : null,
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _cacheSection(AppLocalizations l10n) {
    return _SettingsSection(
      title: l10n.sectionStorageCache,
      children: [
        ListTile(
          leading: Icon(Icons.storage_outlined, color: appAccent),
          title: Text(l10n.cacheSize, style: TextStyle(color: appText)),
          subtitle: Text(
            _formatBytes(_cacheSizeBytes),
            style: TextStyle(color: appSubtext),
          ),
          trailing: IconButton(
            tooltip: l10n.refreshTooltip,
            onPressed: _refreshCacheSize,
            icon: Icon(Icons.refresh, color: appSubtext),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: DropdownButtonFormField<int>(
            initialValue:
                CacheLimitOption.values.any(
                  (option) => option.bytes == _cacheMaxBytes,
                )
                ? _cacheMaxBytes
                : null,
            hint: Text(_formatBytes(_cacheMaxBytes)),
            decoration: InputDecoration(labelText: l10n.cacheLimit),
            items: CacheLimitOption.values
                .map(
                  (option) => DropdownMenuItem<int>(
                    value: option.bytes,
                    child: Text(
                      option.bytes == CacheLimitOption.unlimitedBytes
                          ? l10n.cacheLimitUnlimited
                          : option.label,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: _setCacheLimit,
          ),
        ),
        ListTile(
          leading: Icon(Icons.download_outlined, color: appAccent),
          title: Text(l10n.downloadPath, style: TextStyle(color: appText)),
          subtitle: Text(
            _downloadPath ?? l10n.defaultDownloadFolder,
            style: TextStyle(color: appSubtext),
          ),
          trailing: Icon(Icons.chevron_right, color: appSubtext),
          onTap: _editDownloadPath,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: OutlinedButton.icon(
            onPressed: _clearCache,
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.clearCache),
          ),
        ),
      ],
    );
  }

  Widget _securitySection(AppLocalizations l10n) {
    final activeServer = widget.serverManager.activeServer;
    final hasActiveServer = activeServer != null;

    return _SettingsSection(
      title: l10n.sectionSecurityBehavior,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: DropdownButtonFormField<TokenLifetimeOption>(
            initialValue: _tokenLifetime,
            decoration: InputDecoration(
              labelText: l10n.requireLogin,
              prefixIcon: const Icon(Icons.key_outlined),
            ),
            items: TokenLifetimeOption.values
                .map(
                  (option) => DropdownMenuItem<TokenLifetimeOption>(
                    value: option,
                    child: Text(switch (option.id) {
                      'everyOpen' => l10n.tokenLifetimeEveryOpen,
                      'oneHour' => l10n.tokenLifetimeOneHour,
                      'oneDay' => l10n.tokenLifetimeOneDay,
                      'oneWeek' => l10n.tokenLifetimeOneWeek,
                      'oneMonth' => l10n.tokenLifetimeOneMonth,
                      'threeMonths' => l10n.tokenLifetimeThreeMonths,
                      'never' => l10n.tokenLifetimeNever,
                      _ => option.label,
                    }),
                  ),
                )
                .toList(growable: false),
            onChanged: _setTokenLifetime,
          ),
        ),
        SwitchListTile(
          secondary: Icon(Icons.fingerprint, color: appAccent),
          title: Text(l10n.biometricLogin, style: TextStyle(color: appText)),
          subtitle: Text(
            _canUseBiometrics
                ? l10n.biometricLoginSubtitle
                : l10n.biometricsNotAvailable,
            style: TextStyle(color: appSubtext),
          ),
          value: _canUseBiometrics && _biometricLoginEnabled,
          onChanged: _canUseBiometrics ? _setBiometricLoginEnabled : null,
        ),
        SwitchListTile(
          secondary: Icon(Icons.visibility_outlined, color: appAccent),
          title: Text(l10n.showHiddenFiles, style: TextStyle(color: appText)),
          subtitle: Text(
            l10n.showHiddenFilesSubtitle,
            style: TextStyle(color: appSubtext),
          ),
          value: _showHiddenFiles,
          onChanged: _setShowHiddenFiles,
        ),
        ListTile(
          enabled: hasActiveServer,
          leading: Icon(Icons.lock_reset_outlined, color: appAccent),
          title: Text(l10n.changePassword, style: TextStyle(color: appText)),
          subtitle: Text(
            hasActiveServer
                ? l10n.changePasswordSubtitle(activeServer.displayName)
                : l10n.addServerBeforeChangePassword,
            style: TextStyle(color: appSubtext),
          ),
          trailing: Icon(Icons.chevron_right, color: appSubtext),
          onTap: hasActiveServer ? _changeActiveServerPassword : null,
        ),
        ListTile(
          enabled: hasActiveServer,
          leading: Icon(
            Icons.person_remove_outlined,
            color: hasActiveServer ? Colors.redAccent : appSubtext,
          ),
          title: Text(l10n.deleteUserAccount, style: TextStyle(color: appText)),
          subtitle: Text(
            l10n.deleteUserAccountSubtitle,
            style: TextStyle(color: appSubtext),
          ),
          trailing: Icon(Icons.chevron_right, color: appSubtext),
          onTap: hasActiveServer ? _deleteActiveServerAccount : null,
        ),
      ],
    );
  }

  Future<void> _checkForUpdatesManually() async {
    if (_isCheckingUpdate) return;
    setState(() => _isCheckingUpdate = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final service = AppUpdateService();
      final info = await service.checkForUpdates(l10n: l10n);
      if (!mounted) return;
      if (info != null && info.hasUpdate) {
        await AppUpdateDialog.show(context, info);
      } else if (info != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.appIsUpToDate(info.currentVersion))),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.updateCheckFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingUpdate = false);
      }
    }
  }

  Widget _aboutSection(AppLocalizations l10n) {
    return _SettingsSection(
      title: l10n.sectionAboutUpdates,
      children: [
        ListTile(
          leading: _isCheckingUpdate
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.system_update_outlined, color: appAccent),
          title: Text(l10n.checkForUpdates, style: TextStyle(color: appText)),
          subtitle: Text(
            _isCheckingUpdate
                ? l10n.checkingForUpdates
                : l10n.versionLabel(appVersion),
            style: TextStyle(color: appSubtext),
          ),
          trailing: _isCheckingUpdate
              ? null
              : Icon(Icons.chevron_right, color: appSubtext),
          onTap: _isCheckingUpdate ? null : _checkForUpdatesManually,
        ),
      ],
    );
  }

  String _formatBytes(int bytes) => ByteFormatter.format(bytes);

  String _syncStatusLabel(AppLocalizations l10n, SyncRunResult? result) {
    if (result == null) return l10n.noSyncHasRunYet;
    final localFinished = result.finishedAt.toLocal();
    final minute = localFinished.minute.toString().padLeft(2, '0');
    final hour = localFinished.hour.toString().padLeft(2, '0');
    final day = localFinished.day.toString().padLeft(2, '0');
    final month = localFinished.month.toString().padLeft(2, '0');
    return l10n.lastRunAt('$day.$month.${localFinished.year} $hour:$minute');
  }

  Widget _themeSection(AppLocalizations l10n) {
    final currentTheme = AppTheme.current;

    return _SettingsSection(
      title: l10n.sectionAppearance,
      children: [
        ListTile(
          leading: Icon(Icons.language_outlined, color: appAccent),
          title: Text(l10n.language, style: TextStyle(color: appText)),
          trailing: DropdownButton<String?>(
            value: _localeCode,
            dropdownColor: currentTheme.surface,
            underline: const SizedBox.shrink(),
            onChanged: _setLocaleCode,
            items: const [
              DropdownMenuItem(value: null, child: Text('System default')),
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'cs', child: Text('Čeština')),
              DropdownMenuItem(value: 'ru', child: Text('Русский')),
              DropdownMenuItem(value: 'uk', child: Text('Українська')),
              DropdownMenuItem(value: 'pl', child: Text('Polski')),
              DropdownMenuItem(value: 'de', child: Text('Deutsch')),
              DropdownMenuItem(value: 'es', child: Text('Español')),
              DropdownMenuItem(value: 'fr', child: Text('Français')),
              DropdownMenuItem(value: 'ar', child: Text('العربية')),
              DropdownMenuItem(value: 'bn', child: Text('বাংলা')),
              DropdownMenuItem(value: 'fa', child: Text('فارسی')),
              DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
              DropdownMenuItem(value: 'id', child: Text('Bahasa Indonesia')),
              DropdownMenuItem(value: 'it', child: Text('Italiano')),
              DropdownMenuItem(value: 'pt', child: Text('Português')),
              DropdownMenuItem(
                value: 'pt-BR',
                child: Text('Português (Brasil)'),
              ),
              DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
              DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
              DropdownMenuItem(value: 'ja', child: Text('日本語')),
              DropdownMenuItem(value: 'ko', child: Text('한국어')),
              DropdownMenuItem(value: 'zh', child: Text('中文')),
              DropdownMenuItem(value: 'zh-Hans', child: Text('简体中文')),
            ],
          ),
        ),
        ListTile(
          leading: Icon(
            currentTheme.mode == AppThemeMode.light
                ? Icons.light_mode_outlined
                : currentTheme.mode == AppThemeMode.dark
                ? Icons.dark_mode_outlined
                : Icons.palette_outlined,
            color: appAccent,
          ),
          title: Text(l10n.themeModeTitle, style: TextStyle(color: appText)),
          subtitle: Text(
            currentTheme.mode == AppThemeMode.light
                ? l10n.themeLightFull
                : currentTheme.mode == AppThemeMode.dark
                ? l10n.themeDarkFull
                : l10n.themeCustomFull,
            style: TextStyle(color: appSubtext),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SegmentedButton<AppThemeMode>(
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: appAccent.withValues(alpha: 0.25),
              selectedForegroundColor: appAccent,
              foregroundColor: appSubtext,
              side: BorderSide(color: appBorder),
            ),
            segments: [
              ButtonSegment(
                value: AppThemeMode.dark,
                label: Text(l10n.themeDark),
                icon: const Icon(Icons.dark_mode_outlined, size: 16),
              ),
              ButtonSegment(
                value: AppThemeMode.light,
                label: Text(l10n.themeLight),
                icon: const Icon(Icons.light_mode_outlined, size: 16),
              ),
              ButtonSegment(
                value: AppThemeMode.custom,
                label: Text(l10n.themeCustom),
                icon: const Icon(Icons.palette_outlined, size: 16),
              ),
            ],
            selected: {currentTheme.mode},
            onSelectionChanged: (selected) async {
              final newMode = selected.first;
              AppThemeData newTheme;
              if (newMode == AppThemeMode.dark) {
                newTheme = AppThemeData.dark.copyWith(
                  accent: currentTheme.accent,
                  fontFamily: currentTheme.fontFamily,
                  fontSizeScale: currentTheme.fontSizeScale,
                );
              } else if (newMode == AppThemeMode.light) {
                newTheme = AppThemeData.light.copyWith(
                  accent: currentTheme.accent,
                  fontFamily: currentTheme.fontFamily,
                  fontSizeScale: currentTheme.fontSizeScale,
                );
              } else {
                newTheme = currentTheme.copyWith(mode: AppThemeMode.custom);
              }
              AppTheme.set(newTheme);
              await widget.settingsService.saveTheme(newTheme);
              if (mounted) setState(() {});
            },
          ),
        ),
        const SizedBox(height: 8),

        // Accent Color Picker
        ListTile(
          leading: Icon(Icons.color_lens_outlined, color: appAccent),
          title: Text(l10n.accentColor, style: TextStyle(color: appText)),
          subtitle: Text(
            l10n.primaryAccentColor,
            style: TextStyle(color: appSubtext),
          ),
          trailing: GestureDetector(
            onTap: () async {
              final picked = await ColorPickerDialog.show(
                context,
                initialColor: currentTheme.accent,
                title: l10n.selectAccentColor,
              );
              if (picked != null) {
                final newTheme = currentTheme.copyWith(accent: picked);
                AppTheme.set(newTheme);
                await widget.settingsService.saveTheme(newTheme);
                if (mounted) setState(() {});
              }
            },
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: currentTheme.accent,
                shape: BoxShape.circle,
                border: Border.all(color: appBorder, width: 2),
              ),
            ),
          ),
        ),

        // Custom Theme Colors (visible when Mode is Custom)
        if (currentTheme.mode == AppThemeMode.custom) ...[
          _buildColorTile(
            l10n: l10n,
            title: l10n.backgroundColor,
            color: currentTheme.background,
            onColorPicked: (newColor) async {
              final newTheme = currentTheme.copyWith(background: newColor);
              AppTheme.set(newTheme);
              await widget.settingsService.saveTheme(newTheme);
              if (mounted) setState(() {});
            },
          ),
          _buildColorTile(
            l10n: l10n,
            title: l10n.surfaceColor,
            color: currentTheme.surface,
            onColorPicked: (newColor) async {
              final newTheme = currentTheme.copyWith(surface: newColor);
              AppTheme.set(newTheme);
              await widget.settingsService.saveTheme(newTheme);
              if (mounted) setState(() {});
            },
          ),
          _buildColorTile(
            l10n: l10n,
            title: l10n.textColor,
            color: currentTheme.text,
            onColorPicked: (newColor) async {
              final newTheme = currentTheme.copyWith(text: newColor);
              AppTheme.set(newTheme);
              await widget.settingsService.saveTheme(newTheme);
              if (mounted) setState(() {});
            },
          ),
          _buildColorTile(
            l10n: l10n,
            title: l10n.subtextColor,
            color: currentTheme.subtext,
            onColorPicked: (newColor) async {
              final newTheme = currentTheme.copyWith(subtext: newColor);
              AppTheme.set(newTheme);
              await widget.settingsService.saveTheme(newTheme);
              if (mounted) setState(() {});
            },
          ),
          _buildColorTile(
            l10n: l10n,
            title: l10n.borderColor,
            color: currentTheme.border,
            onColorPicked: (newColor) async {
              final newTheme = currentTheme.copyWith(border: newColor);
              AppTheme.set(newTheme);
              await widget.settingsService.saveTheme(newTheme);
              if (mounted) setState(() {});
            },
          ),
        ],

        // Font Size Scale Slider
        ListTile(
          leading: Icon(Icons.format_size_outlined, color: appAccent),
          title: Text(l10n.fontSizeScale, style: TextStyle(color: appText)),
          subtitle: Text(
            '${(currentTheme.fontSizeScale * 100).round()}%',
            style: TextStyle(color: appSubtext),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Slider(
            value: currentTheme.fontSizeScale,
            min: 0.85,
            max: 1.30,
            divisions: 9,
            activeColor: appAccent,
            inactiveColor: appBorder,
            label: '${(currentTheme.fontSizeScale * 100).round()}%',
            onChanged: (val) async {
              final newTheme = currentTheme.copyWith(fontSizeScale: val);
              AppTheme.set(newTheme);
              await widget.settingsService.saveTheme(newTheme);
              if (mounted) setState(() {});
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildColorTile({
    required AppLocalizations l10n,
    required String title,
    required Color color,
    required ValueChanged<Color> onColorPicked,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      title: Text(title, style: TextStyle(color: appText, fontSize: 14)),
      trailing: GestureDetector(
        onTap: () async {
          final picked = await ColorPickerDialog.show(
            context,
            initialColor: color,
            title: l10n.selectColor(title),
          );
          if (picked != null) {
            onColorPicked(picked);
          }
        },
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: appBorder, width: 2),
          ),
        ),
      ),
    );
  }

  String _syncResultMessage(AppLocalizations l10n, SyncRunResult result) {
    return switch (result.status) {
      SyncRunStatus.success => l10n.syncResultSuccess(
        result.uploadedFiles,
        result.skippedFiles,
      ),
      SyncRunStatus.noFiles => l10n.syncResultNoFiles,
      SyncRunStatus.partialFailure => l10n.syncResultPartial(
        result.uploadedFiles,
        result.failedFiles,
      ),
      SyncRunStatus.authRequired => l10n.syncResultAuthRequired,
      SyncRunStatus.serverUnreachable =>
        result.message ?? l10n.syncResultUnreachable,
      SyncRunStatus.failed => result.message ?? l10n.syncResultFailed,
    };
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: appSurface,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text(
              title,
              style: TextStyle(
                color: appText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    this.initialValue = '',
    this.hintText,
    this.secondaryActionLabel,
    this.secondaryActionValue,
  });

  final String title;
  final String initialValue;
  final String? hintText;
  final String? secondaryActionLabel;
  final String? secondaryActionValue;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: appSurface,
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: widget.hintText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.cancel),
        ),
        if (widget.secondaryActionLabel != null)
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(widget.secondaryActionValue),
            child: Text(widget.secondaryActionLabel!),
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _PasswordChangeDialog extends StatefulWidget {
  const _PasswordChangeDialog();

  @override
  State<_PasswordChangeDialog> createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<_PasswordChangeDialog> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _errorText;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final password = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;
    if (password.isEmpty) {
      setState(() => _errorText = l10n.enterNewPassword);
      return;
    }
    if (password != confirm) {
      setState(() => _errorText = l10n.passwordsDoNotMatch);
      return;
    }
    Navigator.of(context).pop(password);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: appSurface,
      title: Text(l10n.changePasswordDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _newPasswordController,
            autofocus: true,
            obscureText: !_showNewPassword,
            decoration: InputDecoration(
              labelText: l10n.newPasswordFieldLabel,
              suffixIcon: IconButton(
                tooltip: _showNewPassword
                    ? l10n.hidePassword
                    : l10n.showPassword,
                icon: Icon(
                  _showNewPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () =>
                    setState(() => _showNewPassword = !_showNewPassword),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPasswordController,
            obscureText: !_showConfirmPassword,
            decoration: InputDecoration(
              labelText: l10n.confirmPasswordLabel,
              errorText: _errorText,
              suffixIcon: IconButton(
                tooltip: _showConfirmPassword
                    ? l10n.hidePassword
                    : l10n.showPassword,
                icon: Icon(
                  _showConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(
                  () => _showConfirmPassword = !_showConfirmPassword,
                ),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}

class _SyncCategoriesDialog extends StatefulWidget {
  const _SyncCategoriesDialog({required this.initialSelected});

  final Set<String> initialSelected;

  @override
  State<_SyncCategoriesDialog> createState() => _SyncCategoriesDialogState();
}

class _SyncCategoriesDialogState extends State<_SyncCategoriesDialog> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initialSelected};
  }

  void _setSelected(String id, bool enabled) {
    setState(() {
      if (enabled) {
        _selected.add(id);
      } else {
        _selected.remove(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sections = <({String title, List<_SyncCategoryOption> items})>[
      (
        title: l10n.syncCategorySectionMedia,
        items: [_syncCategoryOptions[0], _syncCategoryOptions[1]],
      ),
      (
        title: l10n.syncCategorySectionAudioDocs,
        items: [_syncCategoryOptions[2], _syncCategoryOptions[3]],
      ),
      (title: l10n.syncCategorySectionOther, items: [_syncCategoryOptions[4]]),
    ];

    return AlertDialog(
      backgroundColor: appSurface,
      title: Text(
        l10n.categoriesToSyncDialogTitle,
        style: TextStyle(color: appText),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.categoriesToSyncBody,
                  style: TextStyle(color: appSubtext),
                ),
              ),
              ...sections.expand(
                (section) => [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        section.title,
                        style: TextStyle(
                          color: appText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  ...section.items.map(
                    (option) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      activeColor: appAccent,
                      secondary: Icon(option.icon, color: appAccent),
                      title: Text(switch (option.id) {
                        'photos' => l10n.categoryPhotos,
                        'videos' => l10n.categoryVideos,
                        'audio' => l10n.categoryAudio,
                        'documents' => l10n.categoryDocuments,
                        _ => l10n.categoryOtherFiles,
                      }, style: TextStyle(color: appText)),
                      value: _selected.contains(option.id),
                      onChanged: (value) =>
                          _setSelected(option.id, value ?? false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(_selected.clear),
          child: Text(l10n.clearAll, style: TextStyle(color: appSubtext)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.cancel, style: TextStyle(color: appSubtext)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: appAccent),
          onPressed: () => Navigator.of(context).pop({..._selected}),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

extension IterableExtension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
