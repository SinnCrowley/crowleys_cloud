import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/shared/utils/url_utils.dart';
import 'package:http/http.dart' as http;

/// Authentication mode enumeration (login or registration).
enum AuthMode { register, login }

/// Result payload containing access and refresh tokens returned from authentication endpoints.
class AuthResult {
  const AuthResult({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

/// Gateway interface for executing raw HTTP network calls to backend authentication services.
abstract class AuthGateway {
  Future<AuthResult> register({
    required String baseUrl,
    required String username,
    required String password,
  });

  Future<AuthResult> login({
    required String baseUrl,
    required String username,
    required String password,
  });

  Future<AuthResult> refresh({
    required String baseUrl,
    required String refreshToken,
  });
}

/// Concrete HTTP gateway performing login, registration, and refresh requests.
class HttpAuthGateway implements AuthGateway {
  HttpAuthGateway({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<AuthResult> login({
    required String baseUrl,
    required String username,
    required String password,
  }) {
    return _postAuth(_endpoint(baseUrl, '/api/login'), {
      'username': username,
      'password': password,
    });
  }

  @override
  Future<AuthResult> register({
    required String baseUrl,
    required String username,
    required String password,
  }) {
    return _postAuth(_endpoint(baseUrl, '/api/register'), {
      'username': username,
      'password': password,
    });
  }

  @override
  Future<AuthResult> refresh({
    required String baseUrl,
    required String refreshToken,
  }) {
    return _postAuth(_endpoint(baseUrl, '/api/refresh'), {
      'refresh_token': refreshToken,
    });
  }

  Future<AuthResult> _postAuth(Uri uri, Map<String, Object?> payload) async {
    final response = await _client.post(
      uri,
      headers: const {'content-type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _extractError(response.body) ??
            'Authentication failed (${response.statusCode}) at ${uri.toString()}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, Object?>;
    final accessToken = json['access_token'] as String?;
    final refreshToken = json['refresh_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw const AuthException('Missing access token in response');
    }
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const AuthException('Missing refresh token in response');
    }
    return AuthResult(accessToken: accessToken, refreshToken: refreshToken);
  }

  Uri _endpoint(String baseUrl, String path) =>
      UrlUtils.buildEndpoint(baseUrl, path);

  String? _extractError(String body) {
    try {
      final json = jsonDecode(body) as Map<String, Object?>;
      return json['error'] as String?;
    } catch (_) {
      return null;
    }
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException($message)';
}

enum SessionCheckStatus {
  authorized,
  noSession,
  unauthorized,
  unreachable,
  serverError,
}

class SessionCheckResult {
  const SessionCheckResult(this.status, {this.message});

  final SessionCheckStatus status;
  final String? message;
}

/// Primary authentication service coordinating login/registration, token lifecycle management,
/// session validation, credential persistence, and token lifetime policy synchronization with [SecretStore].
class AuthService {
  AuthService({
    required this.secretStore,
    AuthGateway? gateway,
    http.Client? client,
  }) : gateway = gateway ?? HttpAuthGateway(),
       _client = client ?? http.Client();

  final SecretStore secretStore;
  final AuthGateway gateway;
  final http.Client _client;

  Future<void> authenticate({
    required String serverId,
    required String baseUrl,
    required String username,
    required String password,
    required AuthMode mode,
    String? email,
  }) async {
    final result = switch (mode) {
      AuthMode.register => await gateway.register(
        baseUrl: baseUrl,
        username: username,
        password: password,
      ),
      AuthMode.login => await gateway.login(
        baseUrl: baseUrl,
        username: username,
        password: password,
      ),
    };
    await secretStore.saveTokens(
      serverId: serverId,
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
    await secretStore.saveCredentials(
      serverId: serverId,
      username: username,
      password: password,
    );
    try {
      await fetchAndSaveSyncToken(serverId: serverId, baseUrl: baseUrl);
    } catch (_) {}
  }

  Future<String?> readLastUsername(String serverId) {
    return secretStore.readLastUsername(serverId);
  }

  Future<bool> hasSavedCredentials(String serverId) async {
    final username = await secretStore.readLastUsername(serverId);
    final password = await secretStore.readSavedPassword(serverId);
    return username != null &&
        username.isNotEmpty &&
        password != null &&
        password.isNotEmpty;
  }

  Future<void> authenticateWithSavedCredentials({
    required String serverId,
    required String baseUrl,
  }) async {
    final username = await secretStore.readLastUsername(serverId);
    final password = await secretStore.readSavedPassword(serverId);
    if (username == null ||
        username.isEmpty ||
        password == null ||
        password.isEmpty) {
      throw const AuthException('No saved credentials available');
    }

    await authenticate(
      serverId: serverId,
      baseUrl: baseUrl,
      username: username,
      password: password,
      mode: AuthMode.login,
    );
  }

  Future<bool> hasSession(String serverId) async {
    final token = await secretStore.readToken(serverId);
    return token != null && token.isNotEmpty;
  }

  Future<String?> readAccessToken(String serverId) {
    return secretStore.readToken(serverId);
  }

  Future<SessionCheckResult> checkSession({
    required String serverId,
    required String baseUrl,
  }) async {
    final token = await readAccessToken(serverId);
    if (token == null || token.isEmpty) {
      return const SessionCheckResult(SessionCheckStatus.noSession);
    }

    final uri = _endpoint(
      baseUrl,
      '/api/dir',
    ).replace(queryParameters: {'scope': 'private', 'path': ''});
    try {
      final response = await _client
          .get(uri, headers: {'authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 5));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final hasSyncToken = await secretStore.readSyncToken(serverId) != null;
        if (!hasSyncToken) {
          try {
            await fetchAndSaveSyncToken(serverId: serverId, baseUrl: baseUrl);
          } catch (_) {}
        }
        return const SessionCheckResult(SessionCheckStatus.authorized);
      }
      if (response.statusCode == 401) {
        return const SessionCheckResult(SessionCheckStatus.unauthorized);
      }
      return SessionCheckResult(
        SessionCheckStatus.serverError,
        message: 'Server responded with HTTP ${response.statusCode}.',
      );
    } on SocketException {
      return const SessionCheckResult(
        SessionCheckStatus.unreachable,
        message: 'Server is unreachable.',
      );
    } on http.ClientException {
      return const SessionCheckResult(
        SessionCheckStatus.unreachable,
        message: 'Unable to reach the server.',
      );
    } on TimeoutException {
      return const SessionCheckResult(
        SessionCheckStatus.unreachable,
        message: 'Connection timed out.',
      );
    } catch (_) {
      return const SessionCheckResult(
        SessionCheckStatus.unreachable,
        message: 'Connection check failed.',
      );
    }
  }

  Future<void> refreshSession({
    required String serverId,
    required String baseUrl,
  }) async {
    final refreshToken = await secretStore.readRefreshToken(serverId);
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const AuthException('No refresh token available');
    }

    final result = await gateway.refresh(
      baseUrl: baseUrl,
      refreshToken: refreshToken,
    );
    await secretStore.saveTokens(
      serverId: serverId,
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
  }

  Future<void> requestPasswordReset({
    required String baseUrl,
    required String username,
  }) async {
    final uri = _endpoint(baseUrl, '/api/auth/reset-password/request');
    final response = await _client.post(
      uri,
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({'username': username}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _extractError(response.body) ??
            'Password reset request failed (${response.statusCode})',
      );
    }
  }

  Future<void> verifyPasswordReset({
    required String baseUrl,
    required String username,
    required String code,
    required String newPassword,
  }) async {
    final uri = _endpoint(baseUrl, '/api/auth/reset-password/verify');
    final response = await _client.post(
      uri,
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'code': code,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _extractError(response.body) ??
            'Password reset verification failed (${response.statusCode})',
      );
    }
  }

  Future<void> persistCurrentSessionForConfiguredLifetime(
    String serverId,
  ) async {
    final accessToken = await secretStore.readToken(serverId);
    final refreshToken = await secretStore.readRefreshToken(serverId);
    if (accessToken == null || accessToken.isEmpty) return;
    if (refreshToken == null || refreshToken.isEmpty) {
      await secretStore.saveToken(serverId: serverId, token: accessToken);
      return;
    }
    await secretStore.saveTokens(
      serverId: serverId,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<void> changePassword({
    required String serverId,
    required String baseUrl,
    required String newPassword,
  }) async {
    final token = await readAccessToken(serverId);
    if (token == null || token.isEmpty) {
      throw const AuthException('No active session available');
    }
    final username = await readLastUsername(serverId);
    if (username == null || username.isEmpty) {
      throw const AuthException('No saved username available');
    }

    await _sendAuthorizedJson(
      method: 'POST',
      uri: _endpoint(baseUrl, '/api/account/password'),
      token: token,
      payload: {'new_password': newPassword},
      fallbackMessage: 'Password change failed',
    );

    await authenticate(
      serverId: serverId,
      baseUrl: baseUrl,
      username: username,
      password: newPassword,
      mode: AuthMode.login,
    );
  }

  Future<void> deleteAccount({
    required String serverId,
    required String baseUrl,
  }) async {
    final token = await readAccessToken(serverId);
    if (token == null || token.isEmpty) {
      throw const AuthException('No active session available');
    }

    await _sendAuthorizedJson(
      method: 'DELETE',
      uri: _endpoint(baseUrl, '/api/account'),
      token: token,
      fallbackMessage: 'Account deletion failed',
    );
    await logout(serverId);
  }

  Future<void> logout(String serverId) async {
    await secretStore.clearToken(serverId);
    await secretStore.clearSyncToken(serverId);
    await secretStore.clearCredentials(serverId);
  }

  Future<String?> readSyncToken(String serverId) {
    return secretStore.readSyncToken(serverId);
  }

  Future<String?> fetchAndSaveSyncToken({
    required String serverId,
    required String baseUrl,
  }) async {
    final token = await readAccessToken(serverId);
    if (token == null || token.isEmpty) return null;

    final uri = _endpoint(baseUrl, '/api/account/sync-token');
    final response = await _client.get(
      uri,
      headers: {'authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) return null;

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final syncToken = json['sync_token'] as String?;
    if (syncToken != null && syncToken.isNotEmpty) {
      await secretStore.saveSyncToken(serverId: serverId, syncToken: syncToken);
      return syncToken;
    }
    return null;
  }

  Future<void> _sendAuthorizedJson({
    required String method,
    required Uri uri,
    required String token,
    Map<String, Object?>? payload,
    required String fallbackMessage,
  }) async {
    final request = http.Request(method, uri)
      ..headers['authorization'] = 'Bearer $token'
      ..headers['content-type'] = 'application/json';
    if (payload != null) {
      request.body = jsonEncode(payload);
    }

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    throw AuthException(
      _extractError(response.body) ??
          '$fallbackMessage (${response.statusCode}) at ${uri.toString()}',
    );
  }

  String? _extractError(String body) {
    try {
      final json = jsonDecode(body) as Map<String, Object?>;
      return json['error'] as String?;
    } catch (_) {
      return null;
    }
  }

  Uri _endpoint(String baseUrl, String path) =>
      UrlUtils.buildEndpoint(baseUrl, path);
}
