import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:flutter/material.dart';

class AuthCard extends StatefulWidget {
  const AuthCard({
    super.key,
    required this.title,
    required this.usernameController,
    required this.passwordController,
    required this.onSubmit,
    this.subtitle,
    this.initialMode = AuthMode.login,
    this.leading,
    this.extraFields = const [],
    this.biometricAvailable = false,
    this.onBiometricLogin,
    this.submitLabel,
    this.getBaseUrl,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> extraFields;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final AuthMode initialMode;
  final bool biometricAvailable;
  final Future<bool> Function(AuthMode mode, {String? email}) onSubmit;
  final Future<bool> Function()? onBiometricLogin;
  final String? submitLabel;
  final String? Function()? getBaseUrl;

  @override
  State<AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard> {
  late AuthMode _mode;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _isBiometricSubmitting = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || _isBiometricSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final completed = await widget.onSubmit(_mode);
      if (completed && mounted) {
        Navigator.maybePop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitBiometric() async {
    final callback = widget.onBiometricLogin;
    if (callback == null || _isSubmitting || _isBiometricSubmitting) return;
    setState(() => _isBiometricSubmitting = true);
    try {
      final completed = await callback();
      if (completed && mounted) {
        Navigator.maybePop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isBiometricSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitLabel =
        widget.submitLabel ?? (_mode == AuthMode.login ? 'Log In' : 'Register');

    return Container(
      constraints: const BoxConstraints(maxWidth: 430),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: appSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF444444)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.leading != null) ...[
            Center(child: widget.leading!),
            const SizedBox(height: 12),
          ],
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, height: 1.35),
            ),
          ],
          if (widget.extraFields.isNotEmpty) ...[
            const SizedBox(height: 22),
            ...widget.extraFields,
          ],
          const SizedBox(height: 20),
          _AuthModeTabs(
            mode: _mode,
            onChanged: (mode) => setState(() => _mode = mode),
          ),
          const SizedBox(height: 18),
          _AuthTextField(
            controller: widget.usernameController,
            label: 'Username',
            hintText: 'Enter your username',
            icon: Icons.person_outline,
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 14),
          _AuthTextField(
            controller: widget.passwordController,
            label: 'Password',
            hintText: 'Enter your password',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white54,
              ),
            ),
          ),
          if (_mode == AuthMode.login) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showForgotPasswordDialog(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(color: appAccent, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: appAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    submitLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
          if (widget.biometricAvailable &&
              widget.onBiometricLogin != null &&
              _mode == AuthMode.login) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isBiometricSubmitting ? null : _submitBiometric,
              icon: _isBiometricSubmitting
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.fingerprint),
              label: const Text('Use Biometrics'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            _mode == AuthMode.login
                ? 'Do not have an account? Switch to Register.'
                : 'Already have an account? Switch to Log In.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final baseUrl = widget.getBaseUrl?.call();
    if (baseUrl == null || baseUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a server URL first.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _ForgotPasswordDialog(
          baseUrl: baseUrl,
        );
      },
    );
  }
}

class _AuthModeTabs extends StatelessWidget {
  const _AuthModeTabs({required this.mode, required this.onChanged});

  final AuthMode mode;
  final ValueChanged<AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFF292929),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF444444)),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Log In',
            selected: mode == AuthMode.login,
            onTap: () => onChanged(AuthMode.login),
          ),
          _TabButton(
            label: 'Register',
            selected: mode == AuthMode.register,
            onTap: () => onChanged(AuthMode.register),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(
              bottom: BorderSide(
                color: selected ? appAccent : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white38,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.textInputAction,
    this.keyboardType,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.white54),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF292929),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white30),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF444444)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: appAccent),
        ),
      ),
    );
  }
}


class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.baseUrl});

  final String baseUrl;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  int _step = 1; // 1: request code, 2: verify code & change password
  bool _isLoading = false;
  String _error = '';
  String _success = '';

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _error = 'Username is required.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final authService = AuthService(secretStore: _DummySecretStore());
      await authService.requestPasswordReset(
        baseUrl: widget.baseUrl,
        username: username,
      );
      setState(() {
        _step = 2;
        _isLoading = false;
      });
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to request reset. Verify the server URL.';
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    final username = _usernameController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text;

    if (code.isEmpty || password.isEmpty) {
      setState(() => _error = 'Code and new password are required.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final authService = AuthService(secretStore: _DummySecretStore());
      await authService.verifyPasswordReset(
        baseUrl: widget.baseUrl,
        username: username,
        code: code,
        newPassword: password,
      );
      setState(() {
        _success = 'Password reset successfully!';
        _isLoading = false;
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to reset password. Please check the code.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: appSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFF444444)),
      ),
      title: Text(
        _step == 1 ? 'Reset Password' : 'Enter Reset Code',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      content: _success.isNotEmpty
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
                const SizedBox(height: 16),
                Text(
                  _success,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error.isNotEmpty) ...[
                    Text(
                      _error,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (_step == 1) ...[
                    const Text(
                      'Enter your username. The 6-digit verification code will be printed to the server logs/console.',
                      style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.35),
                    ),
                    const SizedBox(height: 16),
                    _AuthTextField(
                      controller: _usernameController,
                      label: 'Username',
                      hintText: 'Enter your username',
                      icon: Icons.person_outline,
                    ),
                  ] else ...[
                    Text(
                      'Verification code has been printed to the server console. Enter the 6-digit code and your new password.',
                      style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.35),
                    ),
                    const SizedBox(height: 16),
                    _AuthTextField(
                      controller: _codeController,
                      label: 'Reset Code',
                      hintText: 'Enter 6-digit code',
                      icon: Icons.vpn_key_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    _AuthTextField(
                      controller: _passwordController,
                      label: 'New Password',
                      hintText: 'Enter new password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                    ),
                  ],
                ],
              ),
            ),
      actions: _success.isNotEmpty
          ? []
          : [
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              FilledButton(
                onPressed: _isLoading ? null : (_step == 1 ? _sendCode : _resetPassword),
                style: FilledButton.styleFrom(
                  backgroundColor: appAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_step == 1 ? 'Send Code' : 'Reset Password'),
              ),
            ],
    );
  }
}

class _DummySecretStore implements SecretStore {
  @override
  Future<void> clearCredentials(String serverId) async {}
  @override
  Future<void> clearToken(String serverId) async {}
  @override
  Future<String?> readLastUsername(String serverId) async => null;
  @override
  Future<String?> readRefreshToken(String serverId) async => null;
  @override
  Future<String?> readSavedPassword(String serverId) async => null;
  @override
  Future<String?> readToken(String serverId) async => null;
  @override
  Future<void> saveCredentials({required String serverId, required String username, required String password}) async {}
  @override
  Future<void> saveTokens({required String serverId, required String accessToken, required String refreshToken}) async {}
  @override
  Future<void> saveToken({required String serverId, required String token}) async {}
}

class AuthInputField extends StatelessWidget {
  const AuthInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _AuthTextField(
        controller: controller,
        label: label,
        hintText: hintText,
        icon: icon,
        keyboardType: keyboardType,
      ),
    );
  }
}
