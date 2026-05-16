import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:flutter/material.dart';

class ServerSetupResult {
  const ServerSetupResult({
    required this.profile,
    required this.username,
    required this.password,
    required this.authMode,
  });

  final ServerProfile profile;
  final String username;
  final String password;
  final AuthMode authMode;
}

class ServerSetupScreen extends StatefulWidget {
  const ServerSetupScreen({
    super.key,
    this.initialUrl = '',
    this.initialName = '',
  });

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
  AuthMode _mode = AuthMode.register;

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

  void _submit() {
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

    final profile = ServerProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      displayName: name,
      baseUrl: url,
      authMode: _mode.name,
      lastUsedAt: DateTime.now().toUtc(),
      syncPrefs: const {'syncOnWifiOnly': true, 'thumbnailPreload': true},
    );

    Navigator.of(context).pop(
      ServerSetupResult(
        profile: profile,
        username: username,
        password: password,
        authMode: _mode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add server')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Server name'),
            ),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'Base URL'),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            SegmentedButton<AuthMode>(
              segments: const [
                ButtonSegment(
                  value: AuthMode.register,
                  label: Text('Register'),
                ),
                ButtonSegment(value: AuthMode.login, label: Text('Login')),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) {
                setState(() {
                  _mode = selection.first;
                });
              },
            ),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Save server'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
