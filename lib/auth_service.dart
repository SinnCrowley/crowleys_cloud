import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crowleys_cloud/secret_store.dart';
import 'package:http/http.dart' as http;

enum AuthMode { register, login }

class AuthResult {
  const AuthResult({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

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

  Uri _endpoint(String baseUrl, String path) {
    final raw = baseUrl.trim();
    final withScheme = raw.contains('://') ? raw : 'http://$raw';
    final base = Uri.parse(withScheme);
    final basePath = base.path.isEmpty
        ? '/'
        : (base.path.endsWith('/') ? base.path : '${base.path}/');
    final normalizedBase = base.replace(path: basePath);
    final relativePath = path.startsWith('/') ? path.substring(1) : path;
    return normalizedBase.resolve(relativePath);
  }

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

    final uri = _endpoint(baseUrl, '/api/dir').replace(
      queryParameters: {'scope': 'private', 'path': ''},
    );
    try {
      final response = await _client
          .get(uri, headers: {'authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 5));
      if (response.statusCode >= 200 && response.statusCode < 300) {
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

  Future<void> logout(String serverId) {
    return secretStore.clearToken(serverId);
  }

  Uri _endpoint(String baseUrl, String path) {
    final raw = baseUrl.trim();
    final withScheme = raw.contains('://') ? raw : 'http://$raw';
    final base = Uri.parse(withScheme);
    final basePath = base.path.isEmpty
        ? '/'
        : (base.path.endsWith('/') ? base.path : '${base.path}/');
    final normalizedBase = base.replace(path: basePath);
    final relativePath = path.startsWith('/') ? path.substring(1) : path;
    return normalizedBase.resolve(relativePath);
  }
}
