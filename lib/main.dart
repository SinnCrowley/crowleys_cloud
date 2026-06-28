import 'dart:async';
import 'dart:io';

import 'package:crowleys_cloud/active_server_manager.dart';
import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/app_settings_service.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WorkmanagerSyncBackgroundScheduler().initialize();
  await CacheService.instance.init();
  await ThumbnailService.instance.init();
  runApp(const CrowleysCloudApp());
}

class CrowleysCloudApp extends StatelessWidget {
  const CrowleysCloudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crowley\'s Cloud',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: appBackground,
        primaryColor: appAccent,
        colorScheme: const ColorScheme.dark(
          primary: appAccent,
          secondary: appAccent,
          surface: appSurface,
        ),
      ),
      home: const MainScreen(),
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
          child: const Icon(Icons.shield_outlined, color: appAccent, size: 18),
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
          onSubmit: (mode) async {
            return widget.onPasswordAuth(
              username: _usernameController.text.trim(),
              password: _passwordController.text,
              mode: mode,
            );
          },
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
  late final VoidCallback _searchTextListener;
  late final VoidCallback _serverManagerListener;
  late final VoidCallback _transferListener;
  late final ActiveServerManager _serverManager;
  late final BiometricAuthService _biometricAuthService;
  late final AppSettingsService _appSettingsService;
  late final SyncBackgroundScheduler _syncScheduler;
  final TransferManager _transferManager = TransferManager();
  bool _authPromptInFlight = false;

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
      setState(() {});
    };
    _serverManager.addListener(_serverManagerListener);
    _transferListener = () {
      if (!mounted) return;
      setState(() {});
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
    _localController?.disposeController();
    _localController?.dispose();
    _serverController?.disposeController();
    _serverController?.dispose();
    _serverManager.dispose();
    super.dispose();
  }

  Future<void> _initializeServers() async {
    await _serverManager.initialize();
    await _syncScheduler.scheduleForServers(_serverManager.servers);
    try {
      final prefs = await SharedPreferences.getInstance();
      _isGridView = prefs.getBool('is_grid_view') ?? true;
    } catch (_) {}
    if (!mounted) return;
    setState(() {});
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
      MaterialPageRoute(builder: (_) => const ServerSetupScreen()),
    );
    if (setupResult == null) return;

    try {
      await _serverManager.authService.authenticate(
        serverId: setupResult.profile.id,
        baseUrl: setupResult.profile.baseUrl,
        username: setupResult.username,
        password: setupResult.password,
        mode: setupResult.authMode,
      );
      await _serverManager.addServer(setupResult.profile);
      await _serverManager.markAuthed(setupResult.profile.id);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication failed: ${e.message}')),
      );
      return;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication failed. Please try again.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _switchServer(String serverId) async {
    if (_serverManager.activeServer?.id == serverId) return;
    await _serverManager.switchActive(serverId);
    _searchController.clear();
    _localController?.disposeController();
    _localController?.dispose();
    _localController = null;
    _selectedLocalCategory = null;
    _selectedServerCategory = null;
    _serverController?.disposeController();
    _serverController?.dispose();
    _serverController = null;
    if (!mounted) return;
    setState(() {});
  }

  Future<bool> _confirmServerSwitch(String serverName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appSurface,
        title: const Text(
          'Switch server?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Switch active server to "$serverName"?',
          style: const TextStyle(color: Colors.white70),
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
    if (_authPromptInFlight) return;
    final active = _serverManager.activeServer;
    if (active == null || !_serverManager.requiresAuth) return;

    _authPromptInFlight = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_serverManager.requiresAuth) {
        _authPromptInFlight = false;
        return;
      }

      await _authenticateActiveServer();
      _authPromptInFlight = false;
      if (mounted) setState(() {});
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

    if (!mounted) return;
    if (canUseBiometrics) {
      final authed = await _authenticateWithBiometrics(
        active,
        reportFailure: false,
      );
      if (authed) {
        if (!mounted) return;
        setState(() {});
        return;
      }
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return _ActiveServerAuthDialog(
          active: active,
          initialUsername: lastUsername ?? '',
          canUseBiometrics: canUseBiometrics,
          onPasswordAuth:
              ({required username, required password, required mode}) {
                return _authenticateWithPassword(
                  activeId: active.id,
                  baseUrl: active.baseUrl,
                  username: username,
                  password: password,
                  mode: mode,
                );
              },
          onBiometricAuth: _authenticateWithBiometrics,
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;
    setState(() {});
  }

  Future<bool> _authenticateWithPassword({
    required String activeId,
    required String baseUrl,
    required String username,
    required String password,
    required AuthMode mode,
  }) async {
    if (username.isEmpty || password.isEmpty) return false;

    try {
      await _serverManager.authService.authenticate(
        serverId: activeId,
        baseUrl: baseUrl,
        username: username,
        password: password,
        mode: mode,
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
    final unlocked = await _biometricAuthService.unlockSavedCredentials();
    if (!unlocked) return false;

    try {
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
        title: const Text(
          'Choose server',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: otherServers.length,
            itemBuilder: (context, index) {
              final server = otherServers[index];
              return ListTile(
                leading: const Icon(Icons.dns, color: Colors.white70),
                title: Text(
                  server.displayName,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  server.baseUrl,
                  style: const TextStyle(color: Colors.white54),
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
      _localController?.disposeController();
      _localController?.dispose();
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
    if (_selectedModeIndex == 0) {
      if (_localController != null && _localController!.isSelectionMode) {
        _localController!.clearSelection();
      } else if (_localController?.canNavigateBack ?? false) {
        await _clearSearchAndResetFilterForCurrentMode();
        await _localController!.navigateBack();
      } else {
        await _clearSearchAndResetFilterForCurrentMode();
        _localController?.disposeController();
        _localController?.dispose();
        setState(() {
          _selectedLocalCategory = null;
          _localController = null;
        });
      }
      return;
    }
    if (_serverController?.canNavigateBack ?? false) {
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
    _serverController?.disposeController();
    _serverController?.dispose();
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
                const Text(
                  'No servers configured yet.',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Add your first server to continue.',
                  style: TextStyle(color: Colors.white70),
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
      _scheduleActiveServerAuthPrompt();
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Authenticate: ${_serverManager.activeServer!.displayName}',
          ),
          backgroundColor: appSurface,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Authentication required',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Opening sign in...',
                  style: TextStyle(color: Colors.white70),
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
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _serverManager.connectionErrorMessage!,
                  style: const TextStyle(color: Colors.white70),
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
      canPop: _selectedModeIndex == 1
          ? !(_serverController?.canNavigateBack ?? false) &&
                _selectedServerCategory == null
          : _selectedLocalCategory == null,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            backgroundColor: appSurface,
            surfaceTintColor: appSurface,
            elevation: 0,
            leading:
                (_selectedModeIndex == 0 && _selectedLocalCategory != null) ||
                    (_selectedModeIndex == 1 &&
                        ((_serverController?.canNavigateBack ?? false) ||
                            _selectedServerCategory != null))
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _handleBack,
                  )
                : IconButton(
                    iconSize: 28,
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => _scaffoldKey.currentState!.openDrawer(),
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
                  const Icon(Icons.search, color: Colors.white54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () async {
                        _searchController.clear();
                        await _resetSearchFilterForCurrentMode();
                      },
                      child: const Icon(
                        Icons.close,
                        color: Colors.white54,
                        size: 20,
                      ),
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
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  const Divider(color: Colors.white24),
                  ..._serverManager.servers.map((server) {
                    final isActive =
                        _serverManager.activeServer?.id == server.id;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: isActive ? appBackground : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          leading: Icon(
                            Icons.dns,
                            color: isActive ? Colors.white : Colors.white70,
                          ),
                          title: Text(
                            server.displayName,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                          subtitle: Text(
                            server.baseUrl,
                            style: TextStyle(
                              color: isActive ? Colors.white70 : Colors.white54,
                            ),
                          ),
                          selected: isActive,
                          onTap: isActive
                              ? null
                              : () async {
                                  final shouldSwitch =
                                      await _confirmServerSwitch(
                                        server.displayName,
                                      );
                                  if (!shouldSwitch || !context.mounted) return;
                                  await _switchServer(server.id);
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                },
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.white70,
                            ),
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
                    leading: const Icon(Icons.add, color: Colors.white70),
                    title: const Text(
                      'Add server',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await _openAddServerFlow();
                    },
                  ),
                  const Divider(color: Colors.white24),
                  ListTile(
                    leading: const Icon(Icons.folder, color: Colors.white70),
                    title: const Text(
                      'Local',
                      style: TextStyle(color: Colors.white),
                    ),
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
                    leading: const Icon(Icons.cloud, color: Colors.white70),
                    title: const Text(
                      'Server',
                      style: TextStyle(color: Colors.white),
                    ),
                    selected: _selectedModeIndex == 1,
                    onTap: () {
                      setState(() {
                        _selectedModeIndex = 1;
                      });
                      unawaited(_clearSearchAndResetFilterForCurrentMode());
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(color: Colors.white24),
                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.white70),
                    title: const Text(
                      'Settings',
                      style: TextStyle(color: Colors.white),
                    ),
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
                Icon(category.icon, color: Colors.white70, size: 40),
                const SizedBox(height: 12),
                Text(
                  category.name,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
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
                Icon(category.icon, color: Colors.white70, size: 40),
                const SizedBox(height: 12),
                Text(
                  category.name,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
