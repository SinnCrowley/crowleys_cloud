import 'dart:io';
import 'dart:convert';

import 'package:crowleys_cloud/active_server_manager.dart';
import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/app_settings_service.dart';
import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/biometric_auth_service.dart';
import 'package:crowleys_cloud/cache_service.dart';
import 'package:crowleys_cloud/file_browser.dart';
import 'package:crowleys_cloud/file_browser_controller.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:crowleys_cloud/server_setup_screen.dart';
import 'package:crowleys_cloud/sync_scheduler.dart';
import 'package:crowleys_cloud/sync_service.dart';
import 'package:crowleys_cloud/theme_customizer_dialog.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  int _trashRetentionDays = 7;
  bool _trashLoading = false;

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

  String _displayLocalFolderPath(String path) {
    const androidPrimaryStoragePrefix = '/storage/emulated/0';
    final trimmed = path.trim();
    if (trimmed == androidPrimaryStoragePrefix) return 'Storage';
    if (trimmed.startsWith('$androidPrimaryStoragePrefix/')) {
      final relative = trimmed.substring(androidPrimaryStoragePrefix.length);
      return relative.isEmpty ? 'Storage' : relative;
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
      _selectedSyncServerId =
          widget.serverManager.activeServer?.id ??
          widget.serverManager.servers.firstOrNull?.id;
      _isLoading = false;
    });
    await _loadTrashRetention();
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

  Uri _apiUri(String baseUrl, String endpointPath) {
    final raw = baseUrl.trim();
    final withScheme = raw.contains('://') ? raw : 'http://$raw';
    final base = Uri.parse(withScheme);

    var basePath = base.path;
    if (basePath.isEmpty) basePath = '/';
    if (basePath.endsWith('/')) {
      basePath = basePath.substring(0, basePath.length - 1);
    }

    final endpoint = endpointPath.startsWith('/')
        ? endpointPath
        : '/$endpointPath';
    final hasApiSuffix = basePath == '/api' || basePath.endsWith('/api');
    final apiPath = hasApiSuffix
        ? '$basePath$endpoint'
        : '$basePath/api$endpoint';
    return base.replace(path: apiPath, query: null, fragment: null);
  }

  Future<void> _loadTrashRetention() async {
    final activeServer = widget.serverManager.activeServer;
    if (activeServer == null) return;
    try {
      final token = await widget.serverManager.authService.readAccessToken(
        activeServer.id,
      );
      if (token == null || token.isEmpty) return;
      final uri = _apiUri(
        activeServer.connectionUrl,
        '/account/settings/trash',
      );
      final response = await http.get(
        uri,
        headers: {'authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body) as Map<String, Object?>;
        final days = (payload['trash_retention_days'] as num?)?.toInt() ?? 7;
        setState(() {
          _trashRetentionDays = days;
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('trash.retention_days.${activeServer.id}', days);
      }
    } catch (_) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getInt('trash.retention_days.${activeServer.id}');
        if (cached != null) {
          setState(() {
            _trashRetentionDays = cached;
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _setTrashRetention(int days) async {
    final activeServer = widget.serverManager.activeServer;
    if (activeServer == null) return;
    setState(() {
      _trashRetentionDays = days;
      _trashLoading = true;
    });
    try {
      final token = await widget.serverManager.authService.readAccessToken(
        activeServer.id,
      );
      if (token == null || token.isEmpty) return;
      final uri = _apiUri(
        activeServer.connectionUrl,
        '/account/settings/trash',
      );
      final response = await http.post(
        uri,
        headers: {
          'authorization': 'Bearer $token',
          'content-type': 'application/json',
        },
        body: jsonEncode({'trash_retention_days': days}),
      );
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('trash.retention_days.${activeServer.id}', days);
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _trashLoading = false);
      }
      widget.serverManager.refresh();
    }
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password updated.')));
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password change failed: ${e.message}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password change failed.')));
    }
  }

  Future<void> _deleteActiveServerAccount() async {
    final server = widget.serverManager.activeServer;
    if (server == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appSurface,
        title: const Text('Delete account?'),
        content: Text(
          'This permanently deletes your account on ${server.displayName} and removes all files stored in your private cloud folder. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete account'),
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
      ).showSnackBar(const SnackBar(content: Text('Account deleted.')));
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account deletion failed: ${e.message}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Account deletion failed.')));
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appSurface,
        title: const Text('Clear cache?'),
        content: const Text(
          'This removes local thumbnails and cached server listings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.cacheService.clearAll();
    await _refreshCacheSize();
  }

  Future<void> _editDownloadPath() async {
    final path = await showDialog<String?>(
      context: context,
      builder: (context) => _TextInputDialog(
        title: 'Download path',
        initialValue: _downloadPath ?? '',
        hintText: '/storage/emulated/0/CrowleysCloud',
        secondaryActionLabel: 'Use default',
        secondaryActionValue: '',
      ),
    );
    if (path == null) return;
    await widget.settingsService.setDownloadDirectoryPath(path);
    if (!mounted) return;
    setState(() => _downloadPath = path.trim().isEmpty ? null : path.trim());
  }

  Future<void> _editTargetDirectory() async {
    final current = _syncString(
      'backupTargetDirectory',
      _defaultTargetDirectory(),
    );
    final path = await showDialog<String?>(
      context: context,
      builder: (context) => _TextInputDialog(
        title: 'Server target directory',
        initialValue: current,
        hintText: '/backup/mobile_phone',
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
        builder: (_) => ServerSetupScreen(authService: widget.serverManager.authService),
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
        SnackBar(content: Text('Failed to save server: $e')),
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
              const SnackBar(
                content: Text(
                  'Manage Storage permission is required to browse and select folders.',
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

    final controller = FileBrowserController(
      category: const FileCategory('All files', Icons.folder_outlined),
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

  String _syncFrequencyLabel(int minutes) {
    if (minutes == 15) return 'Every 15 minutes';
    if (minutes == 30) return 'Every 30 minutes';
    if (minutes == 60) return 'Every hour';
    if (minutes % 60 == 0) {
      final hours = minutes ~/ 60;
      if (hours == 1) return 'Every hour';
      if (hours == 24) return 'Daily';
      return 'Every $hours hours';
    }
    return 'Every $minutes minutes';
  }

  Future<void> _showSyncFrequencyPicker() async {
    final current = _syncPrefs['syncFrequency'] as int? ?? 15;
    final options = [15, 30, 60, 120, 240, 480, 720, 1440];

    final selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: appSurface,
        title: Text('Choose Sync Frequency', style: TextStyle(color: appText)),
        children: options.map((minutes) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, minutes),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_syncFrequencyLabel(minutes), style: TextStyle(color: appText)),
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

    final hasPermission = await _requestPermissionsForServerSync(server);
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Storage permissions are required to perform synchronization.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
      _syncProgressPercent = null;
    });
    final result = await _syncService.syncServer(
      server,
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
    ).showSnackBar(SnackBar(content: Text(_syncResultMessage(result))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: appSurface,
        surfaceTintColor: appSurface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _themeSection(),
                const SizedBox(height: 14),
                _backupSection(),
                const SizedBox(height: 14),
                _cacheSection(),
                const SizedBox(height: 14),
                _securitySection(),
              ],
            ),
    );
  }

  Widget _backupSection() {
    final selectedServer = _selectedSyncServer;
    final hasSelectedServer = selectedServer != null;
    final syncEnabled = _syncBool('syncEnabled', false);
    final wifiOnly = _syncBool('backupWifiOnly', true);
    final chargingOnly = _syncBool('backupChargingOnly', false);
    final target = _syncString(
      'backupTargetDirectory',
      _defaultTargetDirectory(),
    );
    final syncCategories = _syncCategories();
    final syncFolders = _syncStringList('syncFolders');

    return _SettingsSection(
      title: 'Backup & Sync',
      children: [
        if (widget.serverManager.servers.isEmpty)
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('No servers configured'),
            subtitle: const Text('Add a server before configuring sync.'),
            trailing: IconButton(
              tooltip: 'Add server',
              icon: const Icon(Icons.add),
              onPressed: _openAddServerFlow,
            ),
          )
        else ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: Text(
              'Select a server to configure its sync settings.',
              style: TextStyle(color: Colors.white70),
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
                isActive ? '${server.baseUrl} · active' : server.baseUrl,
                style: TextStyle(color: appSubtext),
              ),
              onTap: () {
                setState(() => _selectedSyncServerId = server.id);
                _loadLastSyncResult();
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    Icon(Icons.check, color: appAccent),
                  IconButton(
                    tooltip: 'Remove server',
                    icon: Icon(Icons.delete_outline, color: appSubtext),
                    onPressed: () => _removeServer(server),
                  ),
                ],
              ),
            );
          }),
          ListTile(
            leading: Icon(Icons.add, color: appSubtext),
            title: Text('Add server', style: TextStyle(color: appText)),
            onTap: _openAddServerFlow,
          ),
        ],
        SwitchListTile(
          secondary: Icon(Icons.sync, color: appAccent),
          title: Text('Folder and category sync', style: TextStyle(color: appText)),
          subtitle: Text(
            hasSelectedServer
                ? 'Keep selected local categories or folders synced with this server.'
                : 'Add a server before enabling synchronization.',
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
            title: Text('Only on Wi-Fi', style: TextStyle(color: appText)),
            trailing: Switch(
              value: wifiOnly,
              onChanged: (value) => _updateSyncPrefs({'backupWifiOnly': value}),
            ),
          ),
          ListTile(
            leading: Icon(Icons.battery_charging_full, color: appAccent),
            title: Text('Only while charging', style: TextStyle(color: appText)),
            trailing: Switch(
              value: chargingOnly,
              onChanged: (value) =>
                  _updateSyncPrefs({'backupChargingOnly': value}),
            ),
          ),
          ListTile(
            enabled: hasSelectedServer,
            leading: Icon(Icons.folder_outlined, color: appAccent),
            title: Text('Server target directory', style: TextStyle(color: appText)),
            subtitle: Text(target, style: TextStyle(color: appSubtext)),
            trailing: Icon(Icons.chevron_right, color: appSubtext),
            onTap: hasSelectedServer ? _editTargetDirectory : null,
          ),
          ListTile(
            enabled: hasSelectedServer,
            leading: Icon(Icons.av_timer, color: appAccent),
            title: Text('Synchronization frequency', style: TextStyle(color: appText)),
            subtitle: Text(
              _syncFrequencyLabel(_syncPrefs['syncFrequency'] as int? ?? 15),
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
            title: Text('Sync now', style: TextStyle(color: appText)),
            subtitle: _isSyncing
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Syncing...',
                        style: TextStyle(color: appSubtext, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _syncProgressPercent,
                          minHeight: 4,
                          backgroundColor: appBorder.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            appAccent,
                          ),
                        ),
                      ),
                    ],
                  )
                : Text(_syncStatusLabel(_lastSyncResult), style: TextStyle(color: appSubtext)),
            trailing: _isSyncing ? null : Icon(Icons.chevron_right, color: appSubtext),
            onTap: hasSelectedServer && !_isSyncing
                ? _syncSelectedServerNow
                : null,
          ),
          ListTile(
            enabled: hasSelectedServer && !_isSyncing,
            leading: Icon(Icons.bug_report_outlined, color: appAccent),
            title: Text('Trigger Background Sync (Debug)', style: TextStyle(color: appText)),
            subtitle: Text(
              'Forces a WorkManager one-off background task run.',
              style: TextStyle(color: appSubtext),
            ),
            onTap: hasSelectedServer
                ? () async {
                    final scheduler = widget.syncScheduler;
                    if (scheduler != null) {
                      await scheduler.debugTriggerOneOffSync(selectedServer.id);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'One-off background sync task scheduled! Check logs.',
                          ),
                        ),
                      );
                    }
                  }
                : null,
          ),
          ListTile(
            leading: Icon(Icons.category_outlined, color: appAccent),
            title: Text('Categories to synchronize', style: TextStyle(color: appText)),
            subtitle: Text(
              syncCategories.isEmpty
                  ? 'No categories selected.'
                  : '${syncCategories.length} selected',
              style: TextStyle(color: appSubtext),
            ),
            trailing: Icon(Icons.chevron_right, color: appSubtext),
            onTap: _editSyncCategories,
          ),
          ListTile(
            leading: Icon(Icons.folder_copy_outlined, color: appAccent),
            title: Text('Folders to synchronize', style: TextStyle(color: appText)),
            subtitle: Text(
              syncFolders.isEmpty
                  ? 'No custom folders configured.'
                  : syncFolders.length == 1
                  ? _displayLocalFolderPath(syncFolders.single)
                  : '${syncFolders.length} folder(s)',
              style: TextStyle(color: appSubtext),
            ),
            onTap: hasSelectedServer ? _addSyncFolder : null,
            trailing: IconButton(
              tooltip: 'Add folder',
              icon: Icon(Icons.add, color: appSubtext),
              onPressed: hasSelectedServer ? _addSyncFolder : null,
            ),
          ),
          ...syncFolders.map((folder) {
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 56, right: 16),
              title: Text(_displayLocalFolderPath(folder)),
              trailing: IconButton(
                tooltip: 'Remove folder',
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

  Widget _cacheSection() {
    return _SettingsSection(
      title: 'Storage & Cache',
      children: [
        ListTile(
          leading: Icon(Icons.storage_outlined, color: appAccent),
          title: Text('Cache size', style: TextStyle(color: appText)),
          subtitle: Text(_formatBytes(_cacheSizeBytes), style: TextStyle(color: appSubtext)),
          trailing: IconButton(
            tooltip: 'Refresh',
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
            decoration: const InputDecoration(labelText: 'Cache limit'),
            items: CacheLimitOption.values
                .map(
                  (option) => DropdownMenuItem<int>(
                    value: option.bytes,
                    child: Text(option.label),
                  ),
                )
                .toList(growable: false),
            onChanged: _setCacheLimit,
          ),
        ),
        ListTile(
          leading: Icon(Icons.download_outlined, color: appAccent),
          title: Text('Download path', style: TextStyle(color: appText)),
          subtitle: Text(_downloadPath ?? 'Default CrowleysCloud folder', style: TextStyle(color: appSubtext)),
          trailing: Icon(Icons.chevron_right, color: appSubtext),
          onTap: _editDownloadPath,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: OutlinedButton.icon(
            onPressed: _clearCache,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Clear cache'),
          ),
        ),
      ],
    );
  }

  Widget _securitySection() {
    final activeServer = widget.serverManager.activeServer;
    final hasActiveServer = activeServer != null;

    return _SettingsSection(
      title: 'Security & Behavior',
      children: [
        if (hasActiveServer)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: DropdownButtonFormField<int>(
              key: ValueKey(_trashRetentionDays),
              initialValue: _trashRetentionDays,
              decoration: const InputDecoration(
                labelText: 'Trash retention period',
                prefixIcon: Icon(Icons.delete_outline),
              ),
              items: TrashRetentionOption.values
                  .map(
                    (option) => DropdownMenuItem<int>(
                      value: option.days,
                      child: Text(option.label),
                    ),
                  )
                  .toList(),
              onChanged: _trashLoading
                  ? null
                  : (val) {
                      if (val != null) _setTrashRetention(val);
                    },
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: DropdownButtonFormField<TokenLifetimeOption>(
            initialValue: _tokenLifetime,
            decoration: const InputDecoration(
              labelText: 'Require login',
              prefixIcon: Icon(Icons.key_outlined),
            ),
            items: TokenLifetimeOption.values
                .map(
                  (option) => DropdownMenuItem<TokenLifetimeOption>(
                    value: option,
                    child: Text(option.label),
                  ),
                )
                .toList(growable: false),
            onChanged: _setTokenLifetime,
          ),
        ),
        SwitchListTile(
          secondary: Icon(Icons.fingerprint, color: appAccent),
          title: Text('Biometric login', style: TextStyle(color: appText)),
          subtitle: Text(
            _canUseBiometrics
                ? 'Allow saved-credential login with biometrics.'
                : 'Biometrics are not available on this device.',
            style: TextStyle(color: appSubtext),
          ),
          value: _canUseBiometrics && _biometricLoginEnabled,
          onChanged: _canUseBiometrics ? _setBiometricLoginEnabled : null,
        ),
        SwitchListTile(
          secondary: Icon(Icons.visibility_outlined, color: appAccent),
          title: Text('Show hidden files', style: TextStyle(color: appText)),
          subtitle: Text('Display dot-files and dot-folders.', style: TextStyle(color: appSubtext)),
          value: _showHiddenFiles,
          onChanged: _setShowHiddenFiles,
        ),
        ListTile(
          enabled: hasActiveServer,
          leading: Icon(Icons.lock_reset_outlined, color: appAccent),
          title: Text('Change password', style: TextStyle(color: appText)),
          subtitle: Text(
            hasActiveServer
                ? 'Update password for ${activeServer.displayName}.'
                : 'Add a server before changing password.',
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
          title: Text('Delete user account', style: TextStyle(color: appText)),
          subtitle: Text('Deletes the user and all private cloud files.', style: TextStyle(color: appSubtext)),
          trailing: Icon(Icons.chevron_right, color: appSubtext),
          onTap: hasActiveServer ? _deleteActiveServerAccount : null,
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(1)} GB';
  }

  String _syncStatusLabel(SyncRunResult? result) {
    if (result == null) return 'No sync has run yet.';
    final localFinished = result.finishedAt.toLocal();
    final minute = localFinished.minute.toString().padLeft(2, '0');
    final hour = localFinished.hour.toString().padLeft(2, '0');
    final day = localFinished.day.toString().padLeft(2, '0');
    final month = localFinished.month.toString().padLeft(2, '0');
    return 'Last run $day.$month.${localFinished.year} $hour:$minute';
  }

  Widget _themeSection() {
    final currentTheme = AppTheme.current;

    return _SettingsSection(
      title: 'Appearance & Customization',
      children: [
        ListTile(
          leading: Icon(
            currentTheme.mode == AppThemeMode.light
                ? Icons.light_mode_outlined
                : currentTheme.mode == AppThemeMode.dark
                    ? Icons.dark_mode_outlined
                    : Icons.palette_outlined,
            color: appAccent,
          ),
          title: Text('Theme Mode', style: TextStyle(color: appText)),
          subtitle: Text(
            currentTheme.mode == AppThemeMode.light
                ? 'Light Theme'
                : currentTheme.mode == AppThemeMode.dark
                    ? 'Dark Theme'
                    : 'Custom Theme',
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
            segments: const [
              ButtonSegment(
                value: AppThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_outlined, size: 16),
              ),
              ButtonSegment(
                value: AppThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_outlined, size: 16),
              ),
              ButtonSegment(
                value: AppThemeMode.custom,
                label: Text('Custom'),
                icon: Icon(Icons.palette_outlined, size: 16),
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
          title: Text('Accent Color', style: TextStyle(color: appText)),
          subtitle: Text('Primary accent color', style: TextStyle(color: appSubtext)),
          trailing: GestureDetector(
            onTap: () async {
              final picked = await ColorPickerDialog.show(
                context,
                initialColor: currentTheme.accent,
                title: 'Select Accent Color',
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
            title: 'Background Color',
            color: currentTheme.background,
            onColorPicked: (newColor) async {
              final newTheme = currentTheme.copyWith(background: newColor);
              AppTheme.set(newTheme);
              await widget.settingsService.saveTheme(newTheme);
              if (mounted) setState(() {});
            },
          ),
          _buildColorTile(
            title: 'Surface Color',
            color: currentTheme.surface,
            onColorPicked: (newColor) async {
              final newTheme = currentTheme.copyWith(surface: newColor);
              AppTheme.set(newTheme);
              await widget.settingsService.saveTheme(newTheme);
              if (mounted) setState(() {});
            },
          ),
          _buildColorTile(
            title: 'Text Color',
            color: currentTheme.text,
            onColorPicked: (newColor) async {
              final newTheme = currentTheme.copyWith(text: newColor);
              AppTheme.set(newTheme);
              await widget.settingsService.saveTheme(newTheme);
              if (mounted) setState(() {});
            },
          ),
          _buildColorTile(
            title: 'Subtext Color',
            color: currentTheme.subtext,
            onColorPicked: (newColor) async {
              final newTheme = currentTheme.copyWith(subtext: newColor);
              AppTheme.set(newTheme);
              await widget.settingsService.saveTheme(newTheme);
              if (mounted) setState(() {});
            },
          ),
          _buildColorTile(
            title: 'Border Color',
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
          title: Text('Font Size Scale', style: TextStyle(color: appText)),
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
            title: 'Select $title',
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

  String _syncResultMessage(SyncRunResult result) {
    return switch (result.status) {
      SyncRunStatus.success =>
        'Synced ${result.uploadedFiles}, skipped ${result.skippedFiles}.',
      SyncRunStatus.noFiles => 'No files selected for sync.',
      SyncRunStatus.partialFailure =>
        'Synced ${result.uploadedFiles}, failed ${result.failedFiles}.',
      SyncRunStatus.authRequired => 'Sign in before syncing.',
      SyncRunStatus.serverUnreachable =>
        result.message ?? 'Server unreachable. Connection lost.',
      SyncRunStatus.failed => result.message ?? 'Sync failed.',
    };
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: appSurface,
        borderRadius: BorderRadius.circular(8),
      ),
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
          child: const Text('Cancel'),
        ),
        if (widget.secondaryActionLabel != null)
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(widget.secondaryActionValue),
            child: Text(widget.secondaryActionLabel!),
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Save'),
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
    final password = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;
    if (password.isEmpty) {
      setState(() => _errorText = 'Enter a new password.');
      return;
    }
    if (password != confirm) {
      setState(() => _errorText = 'Passwords do not match.');
      return;
    }
    Navigator.of(context).pop(password);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: appSurface,
      title: const Text('Change password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _newPasswordController,
            autofocus: true,
            obscureText: !_showNewPassword,
            decoration: InputDecoration(
              labelText: 'New password',
              suffixIcon: IconButton(
                tooltip: _showNewPassword ? 'Hide password' : 'Show password',
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
              labelText: 'Confirm password',
              errorText: _errorText,
              suffixIcon: IconButton(
                tooltip: _showConfirmPassword
                    ? 'Hide password'
                    : 'Show password',
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
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
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
    final sections = <({String title, List<_SyncCategoryOption> items})>[
      (
        title: 'Media',
        items: [_syncCategoryOptions[0], _syncCategoryOptions[1]],
      ),
      (
        title: 'Audio and documents',
        items: [_syncCategoryOptions[2], _syncCategoryOptions[3]],
      ),
      (title: 'Other', items: [_syncCategoryOptions[4]]),
    ];

    return AlertDialog(
      backgroundColor: appSurface,
      title: Text(
        'Categories to synchronize',
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
                  'Choose one or more categories. Leaving everything unchecked is valid.',
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
                      title: Text(option.label, style: TextStyle(color: appText)),
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
          child: Text('Clear all', style: TextStyle(color: appSubtext)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text('Cancel', style: TextStyle(color: appSubtext)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: appAccent),
          onPressed: () => Navigator.of(context).pop({..._selected}),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

extension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class TrashRetentionOption {
  const TrashRetentionOption(this.days, this.label);
  final int days;
  final String label;

  static const values = [
    TrashRetentionOption(0, 'Disabled'),
    TrashRetentionOption(1, '1 day'),
    TrashRetentionOption(3, '3 days'),
    TrashRetentionOption(7, '1 week'),
    TrashRetentionOption(30, '1 month'),
    TrashRetentionOption(90, '3 months'),
  ];
}
