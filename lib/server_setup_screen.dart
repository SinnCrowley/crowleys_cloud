import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/auth_card.dart';
import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:crowleys_cloud/shared/utils/url_utils.dart';
import 'package:flutter/material.dart';

class ServerSetupResult {
  const ServerSetupResult({
    required this.profile,
    required this.username,
    required this.password,
    required this.authMode,
    this.email,
  });

  final ServerProfile profile;
  final String username;
  final String password;
  final AuthMode authMode;
  final String? email;
}

class ServerSetupScreen extends StatefulWidget {
  const ServerSetupScreen({
    super.key,
    required this.authService,
    this.initialUrl = '',
    this.initialName = '',
  });

  final AuthService authService;
  final String initialUrl;
  final String initialName;

  @override
  State<ServerSetupScreen> createState() => _ServerSetupScreenState();
}

class _ServerSetupScreenState extends State<ServerSetupScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  AuthMode _mode = AuthMode.login;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _urlController = TextEditingController(text: widget.initialUrl);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Map<String, String> _parseUrlInput(String input) => UrlUtils.parseUrlInput(input);

  Future<void> _submit(AuthMode mode, {String? email}) async {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || url.isEmpty || username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All fields are required.')));
      return;
    }

    final parsed = _parseUrlInput(url);
    final parsedBaseUrl = parsed['baseUrl']!;
    final parsedPort = parsed['port']!;

    final profile = ServerProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      displayName: name,
      baseUrl: parsedBaseUrl,
      port: parsedPort.isNotEmpty ? parsedPort : null,
      authMode: mode.name,
      lastUsedAt: DateTime.now().toUtc(),
      syncPrefs: const {'syncOnWifiOnly': true, 'thumbnailPreload': true},
    );

    try {
      await widget.authService.authenticate(
        serverId: profile.id,
        baseUrl: profile.connectionUrl,
        username: username,
        password: password,
        mode: mode,
        email: email,
      );

      if (!mounted) return;
      Navigator.of(context).pop(
        ServerSetupResult(
          profile: profile,
          username: username,
          password: password,
          authMode: mode,
          email: email,
        ),
      );
    } on AuthException catch (e) {
      _usernameController.clear();
      _passwordController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication failed: ${e.message}')),
      );
    } catch (_) {
      _usernameController.clear();
      _passwordController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication failed. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        title: const Text('Add server'),
        backgroundColor: appSurface,
      ),
      body: Container(
        color: appBackground,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: AuthCard(
                title: 'Connect Server',
                subtitle: 'Add your home file server and sign in.',
                initialMode: _mode,
                usernameController: _usernameController,
                passwordController: _passwordController,
                submitLabel: 'Save Server',
                onSubmit: (mode, {email}) async {
                  _mode = mode;
                  await _submit(mode, email: email);
                  return false;
                },
                getBaseUrl: () => _urlController.text.trim(),
                leading: const _ServerBadge(),
                extraFields: [
                  AuthInputField(
                    controller: _nameController,
                    label: 'Server name',
                    hintText: 'Home NAS',
                    icon: Icons.dns_outlined,
                  ),
                  AuthInputField(
                    controller: _urlController,
                    label: 'Base URL',
                    hintText: 'https://cloud.example.com',
                    icon: Icons.link_outlined,
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServerBadge extends StatelessWidget {
  const _ServerBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFF292929),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF444444)),
      ),
      child: Icon(Icons.storage_rounded, color: appAccent, size: 32),
    );
  }
}
