import 'dart:async';
import 'dart:io';

import 'package:crowleys_cloud/active_server_manager.dart';
import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/file_browser.dart';
import 'package:crowleys_cloud/file_browser_controller.dart';
import 'package:crowleys_cloud/file_item.dart';
import 'package:crowleys_cloud/server_browser_controller.dart';
import 'package:crowleys_cloud/server_file_browser.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/server_setup_screen.dart';
import 'package:crowleys_cloud/server_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import 'thumbnail_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  late final ActiveServerManager _serverManager;

  FileCategory? _selectedLocalCategory;
  FileCategory? _selectedServerCategory;
  FileBrowserController? _localController;
  ServerBrowserController? _serverController;

  @override
  void initState() {
    super.initState();
    _serverManager = ActiveServerManager(
      store: ServerStore(),
      authService: AuthService(
        secretStore: FlutterSecureSecretStore(
          storage: const FlutterSecureStorage(),
        ),
      ),
    );
    _searchTextListener = () => setState(() {});
    _searchController.addListener(_searchTextListener);
    unawaited(_initializeServers());
  }

  @override
  void dispose() {
    _searchController.removeListener(_searchTextListener);
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
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _retryStartupValidation() async {
    await _initializeServers();
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

  Future<void> _authenticateActiveServer() async {
    final active = _serverManager.activeServer;
    if (active == null) return;

    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    var mode = AuthMode.register;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text('Authenticate ${active.displayName}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<AuthMode>(
                    segments: const [
                      ButtonSegment(
                        value: AuthMode.register,
                        label: Text('Register'),
                      ),
                      ButtonSegment(
                        value: AuthMode.login,
                        label: Text('Login'),
                      ),
                    ],
                    selected: {mode},
                    onSelectionChanged: (selection) {
                      setLocalState(() {
                        mode = selection.first;
                      });
                    },
                  ),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Authenticate'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;
    final username = usernameController.text.trim();
    final password = passwordController.text;
    if (username.isEmpty || password.isEmpty) return;

    try {
      await _serverManager.authService.authenticate(
        serverId: active.id,
        baseUrl: active.baseUrl,
        username: username,
        password: password,
        mode: mode,
      );
      await _serverManager.markAuthed(active.id);
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
      final controller = FileBrowserController(category: category);
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
          final result = await _uploadDirectoryToServer(
            client: client,
            base: base,
            activeServerId: activeServer.id,
            activeServerBaseUrl: activeServer.baseUrl,
            initialToken: token,
            rootDirectory: Directory(localPath),
            rootRemotePrefix: item.name,
          );
          token = result.token;
          if (result.ok) {
            uploaded.add(item.name);
          } else {
            failed.add(item.name);
            failDetails.add('${item.name}: ${result.error}');
          }
          continue;
        }

        final result = await _uploadFileToServer(
          client: client,
          base: base,
          activeServerId: activeServer.id,
          activeServerBaseUrl: activeServer.baseUrl,
          initialToken: token,
          localFile: File(localPath),
          remotePath: p.basename(localPath),
        );
        token = result.token;
        if (result.ok) {
          uploaded.add(item.name);
        } else {
          failed.add(item.name);
          failDetails.add('${item.name}: ${result.error}');
        }
      }
    } finally {
      client.close();
    }
    if (!mounted) return;
    final msg =
        'Uploaded ${uploaded.length} item(s)'
        '${failed.isNotEmpty ? ', failed ${failed.length}' : ''}.'
        '${failDetails.isNotEmpty ? '\n${failDetails.first}' : ''}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<({bool ok, String? token, String error})> _uploadFileToServer({
    required http.Client client,
    required String base,
    required String activeServerId,
    required String activeServerBaseUrl,
    required String? initialToken,
    required File localFile,
    required String remotePath,
  }) async {
    if (!await localFile.exists()) {
      return (ok: false, token: initialToken, error: 'local file not found');
    }

    final bytes = await localFile.readAsBytes();
    final uri = Uri.parse(base).resolve('/api/files').replace(
      queryParameters: {'scope': 'private', 'path': remotePath},
    );
    var token = initialToken;
    if (token == null || token.isEmpty) {
      return (ok: false, token: token, error: 'no session token');
    }

    var response = await client.post(
      uri,
      headers: {
        'authorization': 'Bearer $token',
        'content-type': 'application/octet-stream',
      },
      body: bytes,
    );

    if (response.statusCode == 401) {
      try {
        await _serverManager.authService.refreshSession(
          serverId: activeServerId,
          baseUrl: activeServerBaseUrl,
        );
        token = await _serverManager.authService.readAccessToken(activeServerId);
      } catch (_) {}
      if (token != null && token.isNotEmpty) {
        response = await client.post(
          uri,
          headers: {
            'authorization': 'Bearer $token',
            'content-type': 'application/octet-stream',
          },
          body: bytes,
        );
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (ok: true, token: token, error: '');
    }
    final body = response.body.trim();
    return (
      ok: false,
      token: token,
      error: 'HTTP ${response.statusCode}${body.isEmpty ? '' : ' $body'}',
    );
  }

  Future<({bool ok, String? token, String error})> _uploadDirectoryToServer({
    required http.Client client,
    required String base,
    required String activeServerId,
    required String activeServerBaseUrl,
    required String? initialToken,
    required Directory rootDirectory,
    required String rootRemotePrefix,
  }) async {
    if (!await rootDirectory.exists()) {
      return (ok: false, token: initialToken, error: 'local directory not found');
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

    await for (final entity in rootDirectory.list(recursive: true, followLinks: false)) {
      if (entity is Directory) {
        final relDir = p.relative(entity.path, from: rootDirectory.path);
        final remoteDirPath = p.join(rootRemotePrefix, relDir);
        final createDirResult = await _createServerFolder(
          client: client,
          base: base,
          activeServerId: activeServerId,
          activeServerBaseUrl: activeServerBaseUrl,
          initialToken: token,
          remotePath: remoteDirPath,
        );
        token = createDirResult.token;
        if (!createDirResult.ok) {
          return (ok: false, token: token, error: createDirResult.error);
        }
        continue;
      }
      if (entity is! File) continue;
      final rel = p.relative(entity.path, from: rootDirectory.path);
      final remotePath = p.join(rootRemotePrefix, rel);
      final fileResult = await _uploadFileToServer(
        client: client,
        base: base,
        activeServerId: activeServerId,
        activeServerBaseUrl: activeServerBaseUrl,
        initialToken: token,
        localFile: entity,
        remotePath: remotePath,
      );
      token = fileResult.token;
      if (!fileResult.ok) {
        return (ok: false, token: token, error: fileResult.error);
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

    final uri = Uri.parse(base).resolve('/api/folders').replace(
      queryParameters: {'scope': 'private', 'path': remotePath},
    );
    var response = await client.post(
      uri,
      headers: {'authorization': 'Bearer $token'},
      body: const [],
    );
    if (response.statusCode == 401) {
      try {
        await _serverManager.authService.refreshSession(
          serverId: activeServerId,
          baseUrl: activeServerBaseUrl,
        );
        token = await _serverManager.authService.readAccessToken(activeServerId);
      } catch (_) {}
      if (token != null && token.isNotEmpty) {
        response = await client.post(
          uri,
          headers: {'authorization': 'Bearer $token'},
          body: const [],
        );
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (ok: true, token: token, error: '');
    }
    final body = response.body.trim();
    return (
      ok: false,
      token: token,
      error: 'folder create HTTP ${response.statusCode}${body.isEmpty ? '' : ' $body'}',
    );
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
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Authenticate: ${_serverManager.activeServer!.displayName}',
          ),
          backgroundColor: appSurface,
        ),
        body: Center(
          child: FilledButton(
            onPressed: _authenticateActiveServer,
            child: const Text('Authenticate server'),
          ),
        ),
      );
    }

    if (_serverManager.connectionErrorMessage != null) {
      final active = _serverManager.activeServer;
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
                onPressed: () => setState(() => _isGridView = !_isGridView),
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
                    subtitle: Text(
                      'Active: ${_serverManager.activeServer?.displayName ?? '-'}',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const Divider(color: Colors.white24),
                  ..._serverManager.servers.map(
                    (server) => ListTile(
                      leading: const Icon(Icons.dns, color: Colors.white70),
                      title: Text(
                        server.displayName,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        server.baseUrl,
                        style: const TextStyle(color: Colors.white54),
                      ),
                      selected: _serverManager.activeServer?.id == server.id,
                      onTap: () async {
                        await _switchServer(server.id);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white70),
                        onPressed: () async {
                          await _serverManager.removeServer(server.id);
                          if (!context.mounted) return;
                          setState(() {});
                        },
                      ),
                    ),
                  ),
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
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedModeIndex,
            onTap: (value) async {
              setState(() {
                _selectedModeIndex = value;
              });
              await _clearSearchAndResetFilterForCurrentMode();
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Local'),
              BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'Server'),
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
