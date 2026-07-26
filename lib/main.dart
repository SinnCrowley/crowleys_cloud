import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:crowleys_cloud/active_server_manager.dart';
import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/app_settings_service.dart';
import 'package:crowleys_cloud/app_update_service.dart';
import 'package:crowleys_cloud/auth_card.dart';
import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/biometric_auth_service.dart';
import 'package:crowleys_cloud/cache_service.dart';
import 'package:crowleys_cloud/file_browser.dart';
import 'package:crowleys_cloud/file_browser_controller.dart';
import 'package:crowleys_cloud/file_item.dart';
import 'package:crowleys_cloud/server_browser_controller.dart';
import 'package:crowleys_cloud/server_file_browser.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:crowleys_cloud/server_setup_screen.dart';
import 'package:crowleys_cloud/settings_screen.dart';
import 'package:crowleys_cloud/server_store.dart';
import 'package:crowleys_cloud/sync_scheduler.dart';
import 'package:crowleys_cloud/transfer_manager.dart';
import 'package:crowleys_cloud/transfer_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'thumbnail_service.dart';
import 'package:crowleys_cloud/trash_browser_controller.dart';
import 'package:crowleys_cloud/trash_browser_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WorkmanagerSyncBackgroundScheduler().initialize();
  await CacheService.instance.init();
  await ThumbnailService.instance.init();
  final theme = await AppSettingsService().loadTheme();
  AppTheme.set(theme);
  runApp(const CrowleysCloudApp());
}

class CrowleysCloudApp extends StatelessWidget {
  const CrowleysCloudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeData>(
      valueListenable: AppTheme.notifier,
      builder: (context, appTheme, _) {
        final isDark =
            appTheme.mode != AppThemeMode.light &&
            (appTheme.mode == AppThemeMode.dark ||
                appTheme.background.computeLuminance() < 0.5);

        final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();
        final fontFamily = appTheme.fontFamily == 'System'
            ? null
            : appTheme.fontFamily;

        return MaterialApp(
          title: 'Crowley\'s Cloud',
          debugShowCheckedModeBanner: false,
          theme: baseTheme.copyWith(
            scaffoldBackgroundColor: appTheme.background,
            primaryColor: appTheme.accent,
            colorScheme:
                (isDark ? const ColorScheme.dark() : const ColorScheme.light())
                    .copyWith(
                      primary: appTheme.accent,
                      secondary: appTheme.accent,
                      surface: appTheme.surface,
                    ),
            textTheme: baseTheme.textTheme.apply(
              fontFamily: fontFamily,
              bodyColor: appTheme.text,
              displayColor: appTheme.text,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: appTheme.surface,
              foregroundColor: appTheme.text,
            ),
          ),
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(appTheme.fontSizeScale),
              ),
              child: child!,
            );
          },
          home: const MainScreen(),
        );
      },
    );
  }
}

class _AuthServerBadge extends StatelessWidget {
  const _AuthServerBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.storage_rounded, color: Colors.white70, size: 34),
        const SizedBox(width: 8),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: appAccent.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: appAccent),
          ),
          child: Icon(Icons.shield_outlined, color: appAccent, size: 18),
        ),
      ],
    );
  }
}

class _ActiveServerAuthDialog extends StatefulWidget {
  const _ActiveServerAuthDialog({
    required this.active,
    required this.initialUsername,
    required this.canUseBiometrics,
    required this.onPasswordAuth,
    required this.onBiometricAuth,
  });

  final ServerProfile active;
  final String initialUsername;
  final bool canUseBiometrics;
  final Future<bool> Function({
    required String username,
    required String password,
    required AuthMode mode,
    String? email,
  })
  onPasswordAuth;
  final Future<bool> Function(ServerProfile active) onBiometricAuth;

  @override
  State<_ActiveServerAuthDialog> createState() =>
      _ActiveServerAuthDialogState();
}

class _ActiveServerAuthDialogState extends State<_ActiveServerAuthDialog> {
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername);
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: appSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: SingleChildScrollView(
        child: AuthCard(
          title: 'Sign In',
          subtitle: widget.active.displayName,
          initialMode: AuthMode.login,
          usernameController: _usernameController,
          passwordController: _passwordController,
          biometricAvailable: widget.canUseBiometrics,
          leading: const _AuthServerBadge(),
          onSubmit: (mode, {email}) async {
            return widget.onPasswordAuth(
              username: _usernameController.text.trim(),
              password: _passwordController.text,
              mode: mode,
              email: email,
            );
          },
          getBaseUrl: () => widget.active.baseUrl,
          onBiometricLogin: () async {
            return widget.onBiometricAuth(widget.active);
          },
        ),
      ),
    );
  }
}

class _UploadPlan {
  _UploadPlan({
    required this.file,
    required this.remotePath,
    required this.totalBytes,
  });

  final File file;
  final String remotePath;
  final int totalBytes;
  TransferItem? transferItem;
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _allCategories = <FileCategory>[
    FileCategory('All files', Icons.folder),
    FileCategory('Photos', Icons.photo),
    FileCategory('Videos', Icons.videocam),
    FileCategory('Audio', Icons.audiotrack),
    FileCategory('Documents', Icons.description),
    FileCategory('Other', Icons.insert_drive_file),
  ];
  static const _serverCategories = <FileCategory>[
    FileCategory('All files', Icons.folder),
    FileCategory('Photos', Icons.photo),
    FileCategory('Videos', Icons.videocam),
    FileCategory('Audio', Icons.audiotrack),
    FileCategory('Documents', Icons.description),
    FileCategory('Other', Icons.insert_drive_file),
    FileCategory('Shared', Icons.folder_shared),
  ];

  int _selectedModeIndex = 0;
  bool _isGridView = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late final VoidCallback _searchTextListener;
  late final VoidCallback _serverManagerListener;
  late final VoidCallback _transferListener;
  late final ActiveServerManager _serverManager;
  late final BiometricAuthService _biometricAuthService;
  late final AppSettingsService _appSettingsService;
  late final SyncBackgroundScheduler _syncScheduler;
  final TransferManager _transferManager = TransferManager();
  bool _authPromptInFlight = false;
  bool _authPromptDismissed = false;
  bool _canUseBiometrics = false;
  int _trashRetentionDays = 7;
  double _dragStartX = 0.0;
  bool _isValidDrag = false;
  bool _isDrawerOpen = false;

  FileCategory? _selectedLocalCategory;
  FileCategory? _selectedServerCategory;
  FileBrowserController? _localController;
  ServerBrowserController? _serverController;

  @override
  void initState() {
    super.initState();
    _appSettingsService = AppSettingsService();
    _syncScheduler = WorkmanagerSyncBackgroundScheduler();
    _serverManager = ActiveServerManager(
      store: ServerStore(),
      authService: AuthService(
        secretStore: FlutterSecureSecretStore(
          storage: const FlutterSecureStorage(),
          settingsService: _appSettingsService,
        ),
      ),
    );
    _biometricAuthService = BiometricAuthService();
    _searchTextListener = () => setState(() {});
    _searchController.addListener(_searchTextListener);
    _serverManagerListener = () {
      if (!mounted) return;
      unawaited(_loadTrashRetention());
      setState(() {});
    };
    _serverManager.addListener(_serverManagerListener);
    _transferListener = () {
      if (!mounted) return;
      if (!_transferManager.hasActiveTransfers && _transferManager.hasItems) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _transferManager.clearFinished();
          }
        });
      }
    };
    _transferManager.addListener(_transferListener);
    unawaited(_initializeServers());
  }

  @override
  void dispose() {
    _searchController.removeListener(_searchTextListener);
    _serverManager.removeListener(_serverManagerListener);
    _transferManager.removeListener(_transferListener);
    _transferManager.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _disposeLocalController();
    _disposeServerController();
    _serverManager.dispose();
    super.dispose();
  }

  void _disposeLocalController() {
    if (_localController != null) {
      _localController!.disposeController();
      _localController!.dispose();
      _localController = null;
    }
  }

  void _disposeServerController() {
    if (_serverController != null) {
      _serverController!.disposeController();
      _serverController!.dispose();
      _serverController = null;
    }
  }

  Future<void> _requestAllPermissionsAtStartup() async {
    try {
      await Permission.notification.request();
      await [Permission.photos, Permission.videos, Permission.audio].request();

      var storageStatus = await Permission.manageExternalStorage.status;
      if (!storageStatus.isGranted) {
        storageStatus = await Permission.manageExternalStorage.request();
        if (!storageStatus.isGranted) {
          await openAppSettings();
        }
      }
    } catch (_) {}
  }

  Future<void> _initializeServers() async {
    await _requestAllPermissionsAtStartup();
    await _serverManager.initialize();
    await _syncScheduler.scheduleForServers(
      _serverManager.servers,
      forceReRegister: true,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      _isGridView = prefs.getBool('is_grid_view') ?? true;
    } catch (_) {}
    await _loadTrashRetention();
    if (!mounted) return;
    setState(() {});
    unawaited(_checkForAutoUpdates());
  }

  Future<void> _checkForAutoUpdates() async {
    try {
      final info = await AppUpdateService().checkForUpdates();
      if (mounted && info != null && info.hasUpdate) {
        await AppUpdateDialog.show(context, info);
      }
    } catch (_) {}
  }

  Future<void> _loadTrashRetention() async {
    final activeServer = _serverManager.activeServer;
    if (activeServer == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final days = prefs.getInt('trash.retention_days.${activeServer.id}') ?? 7;
      if (mounted) {
        setState(() {
          _trashRetentionDays = days;
        });
      }
    } catch (_) {}
  }

  Future<void> _retryStartupValidation() async {
    await _initializeServers();
  }

  Future<void> _openTransfersPage() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TransferPage(manager: _transferManager),
      ),
    );
  }

  Future<void> _openSettingsPage() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          serverManager: _serverManager,
          settingsService: _appSettingsService,
          biometricAuthService: _biometricAuthService,
          syncScheduler: _syncScheduler,
        ),
      ),
    );
    await _localController?.reload();
    await _serverController?.reload();
    if (mounted) setState(() {});
  }

  void _reportActiveServerConnectionError([String? message]) {
    final active = _serverManager.activeServer;
    if (active == null) return;
    _serverManager.reportConnectionError(serverId: active.id, message: message);
  }

  Future<void> _openAddServerFlow() async {
    final setupResult = await Navigator.of(context).push<ServerSetupResult>(
      MaterialPageRoute(
        builder: (_) =>
            ServerSetupScreen(authService: _serverManager.authService),
      ),
    );
    if (setupResult == null) return;

    try {
      await _serverManager.addServer(setupResult.profile);
      await _serverManager.markAuthed(setupResult.profile.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save server: $e')));
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _switchServer(String serverId) async {
    if (_serverManager.activeServer?.id == serverId) return;
    await _serverManager.switchActive(serverId);
    await _loadTrashRetention();
    _searchController.clear();
    _disposeLocalController();
    _selectedLocalCategory = null;
    _selectedServerCategory = null;
    _disposeServerController();
    if (!mounted) return;
    setState(() {
      _authPromptDismissed = false;
    });
  }

  Future<bool> _confirmServerSwitch(String serverName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appSurface,
        title: Text('Switch server?', style: TextStyle(color: appText)),
        content: Text(
          'Switch active server to "$serverName"?',
          style: TextStyle(color: appSubtext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Switch'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  void _scheduleActiveServerAuthPrompt() {
    if (_authPromptInFlight || _authPromptDismissed) return;
    final active = _serverManager.activeServer;
    if (active == null || !_serverManager.requiresAuth) return;

    _authPromptInFlight = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted || !_serverManager.requiresAuth) {
          return;
        }
        await _authenticateActiveServer();
      } catch (e, stack) {
        debugPrint('Error during authentication: $e\n$stack');
      } finally {
        _authPromptInFlight = false;
        if (mounted) setState(() {});
      }
    });
  }

  Future<void> _authenticateActiveServer() async {
    final active = _serverManager.activeServer;
    if (active == null) return;

    final lastUsername = await _serverManager.authService.readLastUsername(
      active.id,
    );
    final hasSavedCredentials = await _serverManager.authService
        .hasSavedCredentials(active.id);
    final biometricLoginEnabled = await _appSettingsService
        .biometricLoginEnabled();
    final canUseBiometrics =
        biometricLoginEnabled &&
        hasSavedCredentials &&
        await _biometricAuthService.canAuthenticate();

    if (mounted) {
      setState(() {
        _canUseBiometrics = canUseBiometrics;
      });
    }

    if (!mounted) return;
    if (canUseBiometrics && !_authPromptDismissed) {
      final authed = await _authenticateWithBiometrics(
        active,
        reportFailure: false,
      );
      if (authed) {
        if (!mounted) return;
        setState(() {
          _authPromptDismissed = false;
        });
        return;
      } else {
        // Biometrics was cancelled or failed. Set _authPromptDismissed = true
        // so we show the buttons page instead of automatically opening password dialog.
        if (!mounted) return;
        setState(() {
          _authPromptDismissed = true;
        });
        return;
      }
    }

    if (!mounted) return;
    await _showPasswordDialog(active, lastUsername, canUseBiometrics);
  }

  Future<void> _showPasswordDialog(
    ServerProfile active,
    String? lastUsername,
    bool canUseBiometrics,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _ActiveServerAuthDialog(
          active: active,
          initialUsername: lastUsername ?? '',
          canUseBiometrics: canUseBiometrics,
          onPasswordAuth:
              ({required username, required password, required mode, email}) {
                return _authenticateWithPassword(
                  activeId: active.id,
                  baseUrl: active.baseUrl,
                  username: username,
                  password: password,
                  mode: mode,
                  email: email,
                );
              },
          onBiometricAuth: _authenticateWithBiometrics,
        );
      },
    );

    if (!mounted) return;
    if (confirmed != true) {
      setState(() {
        _authPromptDismissed = true;
      });
      return;
    }

    setState(() {
      _authPromptDismissed = false;
    });
  }

  Future<bool> _authenticateWithPassword({
    required String activeId,
    required String baseUrl,
    required String username,
    required String password,
    required AuthMode mode,
    String? email,
  }) async {
    if (username.isEmpty || password.isEmpty) return false;

    try {
      await _serverManager.authService.authenticate(
        serverId: activeId,
        baseUrl: baseUrl,
        username: username,
        password: password,
        mode: mode,
        email: email,
      );
      await _serverManager.markAuthed(activeId);
    } on AuthException catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication failed: ${e.message}')),
      );
      return false;
    } catch (_) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication failed. Please try again.'),
        ),
      );
      return false;
    }
    return true;
  }

  Future<bool> _authenticateWithBiometrics(
    ServerProfile active, {
    bool reportFailure = true,
  }) async {
    try {
      final unlocked = await _biometricAuthService
          .unlockSavedCredentials()
          .timeout(const Duration(seconds: 10), onTimeout: () => false);
      if (!unlocked) return false;

      await _serverManager.authService.authenticateWithSavedCredentials(
        serverId: active.id,
        baseUrl: active.baseUrl,
      );
      await _serverManager.markAuthed(active.id);
    } on AuthException catch (e) {
      if (!mounted) return false;
      if (reportFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Biometric login failed: ${e.message}')),
        );
      }
      return false;
    } catch (_) {
      if (!mounted) return false;
      if (reportFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric login failed.')),
        );
      }
      return false;
    }
    return true;
  }

  Future<void> _chooseOtherServerFromExisting() async {
    final activeId = _serverManager.activeServer?.id;
    final otherServers = _serverManager.servers
        .where((server) => server.id != activeId)
        .toList(growable: false);
    if (otherServers.isEmpty) return;

    final selectedServerId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appSurface,
        title: Text('Choose server', style: TextStyle(color: appText)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: otherServers.length,
            itemBuilder: (context, index) {
              final server = otherServers[index];
              return ListTile(
                leading: Icon(Icons.dns, color: appSubtext),
                title: Text(
                  server.displayName,
                  style: TextStyle(color: appText),
                ),
                subtitle: Text(
                  server.baseUrl,
                  style: TextStyle(color: appSubtext),
                ),
                onTap: () => Navigator.of(context).pop(server.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedServerId == null) return;
    await _switchServer(selectedServerId);
  }

  void _onSearchChanged(String query) {
    if (_selectedModeIndex == 0) {
      _localController?.setSearchQueryDebounced(query);
    } else {
      _serverController?.setSearchQueryDebounced(query);
    }
  }

  Future<void> _resetSearchFilterForCurrentMode() async {
    if (_selectedModeIndex == 0) {
      await _localController?.setSearchQuery('');
    } else {
      _serverController?.setSearchQueryDebounced('', delay: Duration.zero);
    }
  }

  Future<void> _clearSearchAndResetFilterForCurrentMode() async {
    _searchController.clear();
    await _resetSearchFilterForCurrentMode();
  }

  Future<void> _onLocalCategorySelected(FileCategory category) async {
    final permissionGranted = await _requestPermission(category);
    if (permissionGranted) {
      await _clearSearchAndResetFilterForCurrentMode();
      _disposeLocalController();
      final controller = FileBrowserController(
        category: category,
        settingsService: _appSettingsService,
      );
      setState(() {
        _selectedLocalCategory = category;
        _localController = controller;
      });
    }
  }

  Future<void> _handleBack() async {
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
      return;
    }
    if (_selectedModeIndex == 0) {
      if (_localController != null && _localController!.isSelectionMode) {
        _localController!.clearSelection();
      } else if (_localController?.canNavigateBack ?? false) {
        await _clearSearchAndResetFilterForCurrentMode();
        await _localController!.navigateBack();
      } else {
        await _clearSearchAndResetFilterForCurrentMode();
        _disposeLocalController();
        setState(() {
          _selectedLocalCategory = null;
        });
      }
      return;
    }
    if (_serverController != null && _serverController!.isSelectionMode) {
      _serverController!.clearSelection();
    } else if (_serverController?.canNavigateBack ?? false) {
      await _clearSearchAndResetFilterForCurrentMode();
      await _serverController!.navigateBack();
    } else if (_selectedServerCategory != null) {
      await _clearSearchAndResetFilterForCurrentMode();
      setState(() {
        _selectedServerCategory = null;
      });
    }
  }

  Future<void> _uploadLocalItems(List<FileItem> items) async {
    final activeServer = _serverManager.activeServer;
    if (activeServer == null) return;
    var token = await _serverManager.authService.readAccessToken(
      activeServer.id,
    );
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No server session token. Re-authenticate server.'),
          ),
        );
      }
      return;
    }

    final base = activeServer.baseUrl.contains('://')
        ? activeServer.baseUrl
        : 'http://${activeServer.baseUrl}';
    final uploaded = <String>[];
    final failed = <String>[];
    final failDetails = <String>[];
    final client = http.Client();
    try {
      for (final item in items) {
        final localPath = await item.path;
        if (localPath.isEmpty) {
          failed.add(item.name);
          failDetails.add('${item.name}: local path is empty');
          continue;
        }

        if (item.isDirectory) {
          final directoryResult = await _uploadDirectoryWithProgress(
            client: client,
            base: base,
            activeServerId: activeServer.id,
            activeServerBaseUrl: activeServer.baseUrl,
            initialToken: token,
            rootDirectory: Directory(localPath),
            rootRemotePrefix: item.name,
          );
          token = directoryResult.token;
          if (directoryResult.ok) uploaded.add(item.name);
          if (!directoryResult.ok) {
            if (_isDisconnectedOperationError(directoryResult.error)) {
              _reportActiveServerConnectionError('Server is unreachable.');
              return;
            }
            failed.add(item.name);
            failDetails.add('${item.name}: ${directoryResult.error}');
          }
          continue;
        }

        final file = File(localPath);
        final transferItem = _transferManager.addItem(
          name: item.name,
          direction: TransferDirection.upload,
          totalBytes: await file.length(),
        );
        try {
          final result = await _uploadFileToServer(
            client: client,
            base: base,
            activeServerId: activeServer.id,
            activeServerBaseUrl: activeServer.baseUrl,
            initialToken: token,
            localFile: file,
            remotePath: p.basename(localPath),
            transferItem: transferItem,
          );
          token = result.token;
          if (result.ok) {
            uploaded.add(item.name);
          } else {
            if (_isDisconnectedOperationError(result.error)) {
              _reportActiveServerConnectionError('Server is unreachable.');
              return;
            }
            failed.add(item.name);
            failDetails.add('${item.name}: ${result.error}');
          }
        } on TransferItemCanceledException {
          continue;
        }
      }
    } on TransferCanceledException {
      return;
    } on SocketException {
      _reportActiveServerConnectionError('Server is unreachable.');
      return;
    } on HttpException {
      _reportActiveServerConnectionError('Server is unreachable.');
      return;
    } on http.ClientException {
      _reportActiveServerConnectionError('Server is unreachable.');
      return;
    } finally {
      client.close();
    }
    if (!mounted) return;
    final msg =
        'Uploaded ${uploaded.length} item(s)'
        '${failed.isNotEmpty ? ', failed ${failed.length}' : ''}.'
        '${failDetails.isNotEmpty ? '\n${failDetails.first}' : ''}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    if (uploaded.isNotEmpty) {
      await _serverController?.invalidateCurrentDirectory(reloadAfter: true);
    }
  }

  Future<({bool ok, String? token, String error})> _uploadFileToServer({
    required http.Client client,
    required String base,
    required String activeServerId,
    required String activeServerBaseUrl,
    required String? initialToken,
    required File localFile,
    required String remotePath,
    required TransferItem transferItem,
  }) async {
    if (!await localFile.exists()) {
      return (ok: false, token: initialToken, error: 'local file not found');
    }

    final uri = Uri.parse(base)
        .resolve('/api/files')
        .replace(queryParameters: {'scope': 'private', 'path': remotePath});
    var token = initialToken;
    if (token == null || token.isEmpty) {
      return (ok: false, token: token, error: 'no session token');
    }

    http.StreamedResponse response;
    try {
      _transferManager.throwIfItemCanceled(transferItem);
      _transferManager.startItem(transferItem);
      response = await _sendUploadRequest(
        client: client,
        uri,
        token: token,
        localFile: localFile,
        transferItem: transferItem,
      );
      _transferManager.throwIfItemCanceled(transferItem);
    } on TransferCanceledException {
      rethrow;
    } on TransferItemCanceledException {
      rethrow;
    } on SocketException {
      _transferManager.failItem(transferItem, 'server disconnected');
      return (ok: false, token: token, error: 'server disconnected');
    } on HttpException {
      _transferManager.failItem(transferItem, 'server disconnected');
      return (ok: false, token: token, error: 'server disconnected');
    } on http.ClientException {
      if (_transferManager.isCanceled) throw TransferCanceledException();
      _transferManager.failItem(transferItem, 'server disconnected');
      return (ok: false, token: token, error: 'server disconnected');
    }

    if (response.statusCode == 401) {
      try {
        await _serverManager.authService.refreshSession(
          serverId: activeServerId,
          baseUrl: activeServerBaseUrl,
        );
        token = await _serverManager.authService.readAccessToken(
          activeServerId,
        );
      } catch (_) {}
      if (token != null && token.isNotEmpty) {
        try {
          _transferManager.updateItem(transferItem, 0);
          _transferManager.throwIfItemCanceled(transferItem);
          response = await _sendUploadRequest(
            client: client,
            uri,
            token: token,
            localFile: localFile,
            transferItem: transferItem,
          );
          _transferManager.throwIfItemCanceled(transferItem);
        } on TransferCanceledException {
          rethrow;
        } on TransferItemCanceledException {
          rethrow;
        } on SocketException {
          _transferManager.failItem(transferItem, 'server disconnected');
          return (ok: false, token: token, error: 'server disconnected');
        } on HttpException {
          _transferManager.failItem(transferItem, 'server disconnected');
          return (ok: false, token: token, error: 'server disconnected');
        } on http.ClientException {
          if (_transferManager.isCanceled) throw TransferCanceledException();
          _transferManager.failItem(transferItem, 'server disconnected');
          return (ok: false, token: token, error: 'server disconnected');
        }
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      _transferManager.completeItem(transferItem);
      return (ok: true, token: token, error: '');
    }
    if (_isConnectionUnavailableStatus(response.statusCode)) {
      _transferManager.failItem(transferItem, 'server disconnected');
      return (ok: false, token: token, error: 'server disconnected');
    }
    final body = await response.stream.bytesToString();
    _transferManager.failItem(transferItem, 'HTTP ${response.statusCode}');
    return (
      ok: false,
      token: token,
      error: 'HTTP ${response.statusCode}${body.isEmpty ? '' : ' $body'}',
    );
  }

  Future<http.StreamedResponse> _sendUploadRequest(
    Uri uri, {
    required http.Client client,
    required String token,
    required File localFile,
    required TransferItem transferItem,
  }) async {
    final request = http.StreamedRequest('POST', uri)
      ..headers['authorization'] = 'Bearer $token'
      ..headers['content-type'] = 'application/octet-stream'
      ..contentLength = await localFile.length();
    unawaited(() async {
      var sent = 0;
      try {
        await for (final chunk in localFile.openRead()) {
          _transferManager.throwIfCanceled();
          _transferManager.throwIfItemCanceled(transferItem);
          await _transferManager.waitIfPaused();
          _transferManager.throwIfItemCanceled(transferItem);
          sent += chunk.length;
          request.sink.add(chunk);
          _transferManager.updateItem(transferItem, sent);
        }
        await request.sink.close();
      } on TransferItemCanceledException catch (e) {
        request.sink.addError(e);
        await request.sink.close();
      } catch (e) {
        request.sink.addError(e);
        await request.sink.close();
      }
    }());
    return client.send(request);
  }

  Future<({bool ok, String? token, String error})>
  _uploadDirectoryWithProgress({
    required http.Client client,
    required String base,
    required String activeServerId,
    required String activeServerBaseUrl,
    required String? initialToken,
    required Directory rootDirectory,
    required String rootRemotePrefix,
  }) async {
    if (!await rootDirectory.exists()) {
      return (
        ok: false,
        token: initialToken,
        error: 'local directory not found',
      );
    }
    final directories = <String>[];
    final uploadPlans = <_UploadPlan>[];
    try {
      await for (final entity in rootDirectory.list(
        recursive: true,
        followLinks: false,
      )) {
        final rel = p.relative(entity.path, from: rootDirectory.path);
        if (entity is Directory) {
          directories.add(rel);
          continue;
        }
        if (entity is! File) continue;
        uploadPlans.add(
          _UploadPlan(
            file: entity,
            remotePath: p.join(rootRemotePrefix, rel),
            totalBytes: await entity.length(),
          ),
        );
      }
    } on FileSystemException catch (e) {
      return (
        ok: false,
        token: initialToken,
        error: e.message.isEmpty ? 'failed to scan directory' : e.message,
      );
    }

    var token = initialToken;
    final rootCreate = await _createServerFolder(
      client: client,
      base: base,
      activeServerId: activeServerId,
      activeServerBaseUrl: activeServerBaseUrl,
      initialToken: token,
      remotePath: rootRemotePrefix,
    );
    token = rootCreate.token;
    if (!rootCreate.ok) {
      return (ok: false, token: token, error: rootCreate.error);
    }

    for (final relDir in directories) {
      final createDirResult = await _createServerFolder(
        client: client,
        base: base,
        activeServerId: activeServerId,
        activeServerBaseUrl: activeServerBaseUrl,
        initialToken: token,
        remotePath: p.join(rootRemotePrefix, relDir),
      );
      token = createDirResult.token;
      if (!createDirResult.ok) {
        return (ok: false, token: token, error: createDirResult.error);
      }
    }

    final transferItems = _transferManager.addItems(
      uploadPlans
          .map(
            (plan) => TransferItemDraft(
              name: plan.remotePath,
              direction: TransferDirection.upload,
              totalBytes: plan.totalBytes,
            ),
          )
          .toList(growable: false),
    );
    for (var i = 0; i < uploadPlans.length; i++) {
      uploadPlans[i].transferItem = transferItems[i];
    }

    for (final plan in uploadPlans) {
      try {
        final fileResult = await _uploadFileToServer(
          client: client,
          base: base,
          activeServerId: activeServerId,
          activeServerBaseUrl: activeServerBaseUrl,
          initialToken: token,
          localFile: plan.file,
          remotePath: plan.remotePath,
          transferItem: plan.transferItem!,
        );
        token = fileResult.token;
        if (!fileResult.ok) {
          return (ok: false, token: token, error: fileResult.error);
        }
      } on TransferItemCanceledException {
        continue;
      }
    }
    return (ok: true, token: token, error: '');
  }

  Future<({bool ok, String? token, String error})> _createServerFolder({
    required http.Client client,
    required String base,
    required String activeServerId,
    required String activeServerBaseUrl,
    required String? initialToken,
    required String remotePath,
  }) async {
    var token = initialToken;
    if (token == null || token.isEmpty) {
      return (ok: false, token: token, error: 'no session token');
    }

    final uri = Uri.parse(base)
        .resolve('/api/folders')
        .replace(queryParameters: {'scope': 'private', 'path': remotePath});
    http.Response response;
    try {
      response = await client.post(
        uri,
        headers: {'authorization': 'Bearer $token'},
        body: const [],
      );
    } on SocketException {
      return (ok: false, token: token, error: 'server disconnected');
    } on HttpException {
      return (ok: false, token: token, error: 'server disconnected');
    } on http.ClientException {
      return (ok: false, token: token, error: 'server disconnected');
    }
    if (response.statusCode == 401) {
      try {
        await _serverManager.authService.refreshSession(
          serverId: activeServerId,
          baseUrl: activeServerBaseUrl,
        );
        token = await _serverManager.authService.readAccessToken(
          activeServerId,
        );
      } catch (_) {}
      if (token != null && token.isNotEmpty) {
        try {
          response = await client.post(
            uri,
            headers: {'authorization': 'Bearer $token'},
            body: const [],
          );
        } on SocketException {
          return (ok: false, token: token, error: 'server disconnected');
        } on HttpException {
          return (ok: false, token: token, error: 'server disconnected');
        } on http.ClientException {
          return (ok: false, token: token, error: 'server disconnected');
        }
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (ok: true, token: token, error: '');
    }
    if (_isConnectionUnavailableStatus(response.statusCode)) {
      return (ok: false, token: token, error: 'server disconnected');
    }
    final body = response.body.trim();
    return (
      ok: false,
      token: token,
      error:
          'folder create HTTP ${response.statusCode}${body.isEmpty ? '' : ' $body'}',
    );
  }

  bool _isDisconnectedOperationError(String error) {
    return error.toLowerCase().contains('server disconnected');
  }

  bool _isConnectionUnavailableStatus(int statusCode) {
    return statusCode == 500 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;
  }

  Future<bool> _requestPermission(FileCategory category) async {
    Permission permission;
    bool isManageExternalStorage = false;

    switch (category.name) {
      case 'Photos':
        permission = Permission.photos;
        break;
      case 'Videos':
        permission = Permission.videos;
        break;
      case 'Audio':
        permission = Permission.audio;
        break;
      default:
        permission = Permission.manageExternalStorage;
        isManageExternalStorage = true;
        break;
    }

    var status = await permission.status;
    if (!status.isGranted) {
      status = await permission.request();
      if (isManageExternalStorage && !status.isGranted) {
        await openAppSettings();
        status = await permission.status;
      }
    }
    return status.isGranted;
  }

  void _ensureServerController() {
    final active = _serverManager.activeServer;
    if (active == null) return;
    if (_serverController != null && _serverController!.serverId == active.id) {
      return;
    }
    _disposeServerController();
    _serverController = ServerBrowserController(
      profile: active,
      serverId: active.id,
      authService: _serverManager.authService,
      onConnectionLost: _reportActiveServerConnectionError,
      transferManager: _transferManager,
      settingsService: _appSettingsService,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_serverManager.isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_serverManager.requiresSetup) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Crowley\'s Cloud setup'),
          backgroundColor: appSurface,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No servers configured yet.',
                  style: TextStyle(color: appText, fontSize: 18),
                ),
                const SizedBox(height: 12),
                Text(
                  'Add your first server to continue.',
                  style: TextStyle(color: appSubtext),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _openAddServerFlow,
                  child: const Text('Add server'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_serverManager.requiresAuth) {
      debugPrint(
        'MainScreen build requiresAuth: _authPromptDismissed=$_authPromptDismissed, _authPromptInFlight=$_authPromptInFlight',
      );
      _scheduleActiveServerAuthPrompt();
      final active = _serverManager.activeServer!;
      return Scaffold(
        appBar: AppBar(
          title: Text('Authenticate: ${active.displayName}'),
          backgroundColor: appSurface,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _authPromptDismissed
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _canUseBiometrics
                            ? Icons.fingerprint
                            : Icons.lock_outline,
                        size: 64,
                        color: appAccent,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Authentication required',
                        style: TextStyle(
                          color: appText,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to access files on ${active.displayName}',
                        style: TextStyle(color: appSubtext),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: FilledButton.icon(
                          onPressed: () async {
                            final lastUsername = await _serverManager
                                .authService
                                .readLastUsername(active.id);
                            if (!mounted) return;
                            setState(() {
                              _authPromptInFlight = true;
                            });
                            try {
                              await _showPasswordDialog(
                                active,
                                lastUsername,
                                _canUseBiometrics,
                              );
                            } finally {
                              _authPromptInFlight = false;
                              if (mounted) setState(() {});
                            }
                          },
                          icon: const Icon(Icons.login),
                          label: const Text('Sign In with Password'),
                          style: FilledButton.styleFrom(
                            backgroundColor: appAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (_canUseBiometrics) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 260),
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final authed = await _authenticateWithBiometrics(
                                active,
                              );
                              if (authed && mounted) {
                                setState(() {
                                  _authPromptDismissed = false;
                                });
                              }
                            },
                            icon: const Icon(Icons.fingerprint),
                            label: const Text('Use Biometrics'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: appText,
                              side: BorderSide(color: appBorder),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (_serverManager.servers.length > 1) ...[
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: _chooseOtherServerFromExisting,
                          icon: Icon(Icons.swap_horiz, color: appAccent),
                          label: Text(
                            'Switch Server',
                            style: TextStyle(
                              color: appAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Authentication required',
                        style: TextStyle(color: appText, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Opening sign in...',
                        style: TextStyle(color: appSubtext),
                      ),
                    ],
                  ),
          ),
        ),
      );
    }

    if (_serverManager.connectionErrorMessage != null) {
      final active = _serverManager.activeServer;
      final hasOtherServers = _serverManager.servers.any(
        (server) => server.id != active?.id,
      );
      return Scaffold(
        appBar: AppBar(
          title: const Text('Server connection failed'),
          backgroundColor: appSurface,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  active == null
                      ? 'Unable to connect to the active server.'
                      : 'Unable to connect to ${active.displayName}.',
                  style: TextStyle(color: appText, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _serverManager.connectionErrorMessage!,
                  style: TextStyle(color: appSubtext),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _retryStartupValidation,
                    child: const Text('Retry'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: hasOtherServers
                        ? _chooseOtherServerFromExisting
                        : null,
                    child: const Text('Choose other server'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _openAddServerFlow,
                    child: const Text('Add server'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    _ensureServerController();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
          return;
        }
        if (_isDrawerOpen ||
            (_scaffoldKey.currentState?.isDrawerOpen ?? false)) {
          _scaffoldKey.currentState?.closeDrawer();
          return;
        }

        final bool serverSelMode = _serverController?.isSelectionMode ?? false;
        final bool localSelMode = _localController?.isSelectionMode ?? false;
        final bool serverCanGoBack =
            (_serverController?.canNavigateBack ?? false) ||
            _selectedServerCategory != null;
        final bool localCanGoBack = _selectedLocalCategory != null;

        final bool hasBackAction = _selectedModeIndex == 1
            ? (serverSelMode || serverCanGoBack)
            : (localSelMode || localCanGoBack);

        if (hasBackAction) {
          await _handleBack();
        } else {
          await SystemNavigator.pop();
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (details) {
          final startX = details.globalPosition.dx;
          _dragStartX = startX;
          _isValidDrag = startX >= 25.0 && startX <= 100.0;
        },
        onHorizontalDragUpdate: (details) {
          if (_isValidDrag) {
            final deltaX = details.globalPosition.dx - _dragStartX;
            if (deltaX > 45.0) {
              _isValidDrag = false;
              _scaffoldKey.currentState?.openDrawer();
            }
          }
        },
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          child: Scaffold(
            key: _scaffoldKey,
            onDrawerChanged: (isOpen) {
              setState(() {
                _isDrawerOpen = isOpen;
              });
            },
            appBar: AppBar(
              backgroundColor: appSurface,
              surfaceTintColor: appSurface,
              elevation: 0,
              leadingWidth: 96,
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    iconSize: 28,
                    icon: Icon(Icons.menu, color: appText),
                    onPressed: () => _scaffoldKey.currentState!.openDrawer(),
                  ),
                  if ((_selectedModeIndex == 0 &&
                          _selectedLocalCategory != null) ||
                      (_selectedModeIndex == 1 &&
                          ((_serverController?.canNavigateBack ?? false) ||
                              _selectedServerCategory != null)))
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: appText),
                      onPressed: _handleBack,
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
              title: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: appBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.search, color: appSubtext),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: TextStyle(color: appSubtext),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: TextStyle(color: appText),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () async {
                          _searchController.clear();
                          await _resetSearchFilterForCurrentMode();
                        },
                        child: Icon(Icons.close, color: appSubtext, size: 20),
                      ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                  onPressed: () async {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('is_grid_view', _isGridView);
                    } catch (_) {}
                  },
                ),
              ],
            ),
            drawer: Drawer(
              backgroundColor: appSurface,
              child: SafeArea(
                child: ListView(
                  children: [
                    ListTile(
                      title: Text(
                        'Crowley\'s Cloud',
                        style: TextStyle(color: appText, fontSize: 18),
                      ),
                    ),
                    Divider(color: appBorder),
                    ..._serverManager.servers.map((server) {
                      final isActive =
                          _serverManager.activeServer?.id == server.id;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        child: Material(
                          color: isActive ? appBackground : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            leading: Icon(
                              Icons.dns,
                              color: isActive ? appText : appSubtext,
                            ),
                            title: Text(
                              server.displayName,
                              style: TextStyle(
                                color: appText,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                            subtitle: Text(
                              server.baseUrl,
                              style: TextStyle(color: appSubtext),
                            ),
                            selected: isActive,
                            onTap: isActive
                                ? null
                                : () async {
                                    final shouldSwitch =
                                        await _confirmServerSwitch(
                                          server.displayName,
                                        );
                                    if (!shouldSwitch || !context.mounted) {
                                      return;
                                    }
                                    await _switchServer(server.id);
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                  },
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: appSubtext),
                              onPressed: () async {
                                await _serverManager.removeServer(server.id);
                                if (!context.mounted) return;
                                setState(() {});
                              },
                            ),
                          ),
                        ),
                      );
                    }),
                    ListTile(
                      leading: Icon(Icons.add, color: appSubtext),
                      title: Text(
                        'Add server',
                        style: TextStyle(color: appText),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        await _openAddServerFlow();
                      },
                    ),
                    Divider(color: appBorder),
                    ListTile(
                      leading: Icon(Icons.folder, color: appSubtext),
                      title: Text('Local', style: TextStyle(color: appText)),
                      selected: _selectedModeIndex == 0,
                      onTap: () {
                        setState(() {
                          _selectedModeIndex = 0;
                        });
                        unawaited(_clearSearchAndResetFilterForCurrentMode());
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.cloud, color: appSubtext),
                      title: Text('Server', style: TextStyle(color: appText)),
                      selected: _selectedModeIndex == 1,
                      onTap: () {
                        setState(() {
                          _selectedModeIndex = 1;
                        });
                        unawaited(_clearSearchAndResetFilterForCurrentMode());
                        Navigator.pop(context);
                      },
                    ),
                    if (_serverManager.activeServer != null &&
                        _trashRetentionDays > 0)
                      ListTile(
                        leading: Icon(Icons.delete_outline, color: appSubtext),
                        title: Text('Trash', style: TextStyle(color: appText)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TrashBrowserScreen(
                                controller: TrashBrowserController(
                                  serverId: _serverManager.activeServer!.id,
                                  baseUrl: _serverManager.activeServer!.baseUrl,
                                  authService: _serverManager.authService,
                                ),
                                isGridView: _isGridView,
                                onToggleGridView: (val) async {
                                  setState(() {
                                    _isGridView = val;
                                  });
                                  try {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setBool('is_grid_view', val);
                                  } catch (_) {}
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    Divider(color: appBorder),
                    ListTile(
                      leading: Icon(Icons.settings, color: appSubtext),
                      title: Text('Settings', style: TextStyle(color: appText)),
                      onTap: () async {
                        Navigator.pop(context);
                        await _openSettingsPage();
                      },
                    ),
                  ],
                ),
              ),
            ),
            body: _selectedModeIndex == 0
                ? (_selectedLocalCategory == null
                      ? _buildLocalCategoryGrid()
                      : FileBrowser(
                          category: _selectedLocalCategory!,
                          isGridView: _isGridView,
                          controller: _localController,
                          onUploadItems: _uploadLocalItems,
                        ))
                : _buildServerModeBody(),
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TransferBottomBar(
                  manager: _transferManager,
                  onOpen: _openTransfersPage,
                ),
                BottomNavigationBar(
                  currentIndex: _selectedModeIndex,
                  onTap: (value) async {
                    setState(() {
                      _selectedModeIndex = value;
                    });
                    await _clearSearchAndResetFilterForCurrentMode();
                  },
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.folder),
                      label: 'Local',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.cloud),
                      label: 'Server',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServerModeBody() {
    if (_serverController == null) return const SizedBox.shrink();
    if (_selectedServerCategory == null) {
      return _buildServerCategoryGrid();
    }
    return ServerFileBrowser(
      controller: _serverController!,
      isGridView: _isGridView,
    );
  }

  Widget _buildServerCategoryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _serverCategories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final category = _serverCategories[index];
        return InkWell(
          onTap: () async {
            final isShared = category.name == 'Shared';
            final type = switch (category.name) {
              'Photos' => 'photo',
              'Videos' => 'video',
              'Audio' => 'audio',
              'Documents' => 'document',
              'Other' => 'other',
              _ => 'all',
            };
            _searchController.clear();
            _serverController?.setSearchQueryDebounced(
              '',
              delay: Duration.zero,
            );
            await _serverController?.setScope(isShared ? 'shared' : 'private');
            _serverController?.setCategory(type);
            setState(() {
              _selectedServerCategory = category;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: appSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category.icon, color: appSubtext, size: 40),
                const SizedBox(height: 12),
                Text(
                  category.name,
                  style: TextStyle(color: appText, fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocalCategoryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allCategories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final category = _allCategories[index];
        return InkWell(
          onTap: () => _onLocalCategorySelected(category),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: appSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category.icon, color: appSubtext, size: 40),
                const SizedBox(height: 12),
                Text(
                  category.name,
                  style: TextStyle(color: appText, fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
