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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/l10n/localization_fallback.dart';
import 'package:crowleys_cloud/shared/utils/scram_utils.dart';
import 'package:crowleys_cloud/shared/utils/url_utils.dart';
import 'package:http/http.dart' as http;

/// Authentication mode enumeration (login or registration).
enum AuthMode { register, login }

/// Result payload containing access and refresh tokens returned from authentication endpoints.
class AuthResult {
  const AuthResult({required this.accessToken, required this.refreshToken})
    : pending = false;
  const AuthResult.pending()
    : accessToken = '',
      refreshToken = '',
      pending = true;

  final bool pending;

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

  Future<bool> ping(
    String baseUrl, {
    Duration timeout = const Duration(seconds: 4),
  }) async => true;
}

/// Concrete HTTP gateway performing login, registration, and refresh requests.
class HttpAuthGateway implements AuthGateway {
  HttpAuthGateway({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<bool> ping(
    String baseUrl, {
    Duration timeout = const Duration(seconds: 4),
  }) async {
    try {
      final uri = _endpoint(baseUrl, '/api/ping');
      final resp = await _client.get(uri).timeout(timeout);
      return resp.statusCode >= 200 && resp.statusCode < 500;
    } catch (_) {
      try {
        final uri = _endpoint(baseUrl, '/api/auth/challenge');
        final resp = await _client.get(uri).timeout(timeout);
        return resp.statusCode >= 200 && resp.statusCode < 500;
      } catch (_) {
        return false;
      }
    }
  }

  @override
  Future<AuthResult> login({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    final l10n = platformAppLocalizations();
    final clientNonce = ScramUtils.generateRandomHex(16);
    final challengeUri = _endpoint(
      baseUrl,
      '/api/auth/challenge',
    ).replace(queryParameters: {'username': username, 'nonce': clientNonce});

    http.Response? challengeResp;
    try {
      challengeResp = await _client.get(challengeUri);
    } on SocketException {
      throw AuthException(l10n.serverIsUnreachable);
    } on http.ClientException catch (e) {
      throw AuthException(
        e.message.isNotEmpty ? e.message : l10n.serverIsUnreachable,
      );
    } on TimeoutException {
      throw AuthException(l10n.serverIsUnreachable);
    } on HandshakeException catch (e) {
      throw AuthException(
        e.message.isNotEmpty ? e.message : l10n.serverIsUnreachable,
      );
    } catch (_) {}

    if (challengeResp != null && challengeResp.statusCode == 200) {
      try {
        final chal = jsonDecode(challengeResp.body) as Map<String, Object?>;
        final authMode = chal['auth_mode'] as String?;
        if (authMode == 'scram-argon2id') {
          final saltHex = chal['salt'] as String;
          final memCostKb = (chal['m'] as num).toInt();
          final timeCost = (chal['t'] as num).toInt();
          final lanes = (chal['p'] as num).toInt();
          final serverNonce = chal['nonce'] as String;
          final challengeToken = chal['challenge_token'] as String;

          final authMessage = ScramUtils.scramArgon2idAuthMessage(
            username,
            serverNonce,
            saltHex,
            memCostKb,
            timeCost,
            lanes,
          );
          final proof = await ScramUtils.computeArgon2idProof(
            password: password,
            saltHex: saltHex,
            memCostKb: memCostKb,
            timeCost: timeCost,
            lanes: lanes,
            authMessage: authMessage,
          );

          return await _postAuth(
            _endpoint(baseUrl, '/api/login'),
            {
              'username': username,
              'nonce': serverNonce,
              'client_proof': proof.clientProofHex,
              'challenge_token': challengeToken,
            },
            expectedServerSignature: proof.expectedServerSignatureHex,
          );
        } else if (authMode == 'scram') {
          final saltHex = chal['salt'] as String;
          final iterations = (chal['iterations'] as num).toInt();
          final serverNonce = chal['nonce'] as String;
          final challengeToken = chal['challenge_token'] as String;

          final authMessage = ScramUtils.scramAuthMessage(
            username,
            serverNonce,
            saltHex,
            iterations,
          );
          final proof = ScramUtils.computeProof(
            password: password,
            saltHex: saltHex,
            iterations: iterations,
            authMessage: authMessage,
          );

          return await _postAuth(
            _endpoint(baseUrl, '/api/login'),
            {
              'username': username,
              'nonce': serverNonce,
              'client_proof': proof.clientProofHex,
              'challenge_token': challengeToken,
            },
            expectedServerSignature: proof.expectedServerSignatureHex,
          );
        }
      } catch (e) {
        if (e is AuthException) rethrow;
      }
    }

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
  }) async {
    final scramKeys = await ScramUtils.generateArgon2idRegistrationKeys(
      password,
    );
    try {
      return await _postAuth(_endpoint(baseUrl, '/api/register'), {
        'username': username,
        'kdf': 'argon2id',
        'salt': scramKeys.saltHex,
        'm': scramKeys.memCostKb,
        't': scramKeys.timeCost,
        'p': scramKeys.lanes,
        'stored_key': scramKeys.storedKeyHex,
        'server_key': scramKeys.serverKeyHex,
      });
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('password are required')) {
        return _postAuth(_endpoint(baseUrl, '/api/register'), {
          'username': username,
          'password': password,
        });
      }
      rethrow;
    }
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

  Future<AuthResult> _postAuth(
    Uri uri,
    Map<String, Object?> payload, {
    String? expectedServerSignature,
  }) async {
    final l10n = platformAppLocalizations();
    final http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: const {'content-type': 'application/json'},
        body: jsonEncode(payload),
      );
    } on SocketException {
      throw AuthException(l10n.serverIsUnreachable);
    } on http.ClientException catch (e) {
      throw AuthException(
        e.message.isNotEmpty ? e.message : l10n.serverIsUnreachable,
      );
    } on TimeoutException {
      throw AuthException(l10n.serverIsUnreachable);
    } on HandshakeException catch (e) {
      throw AuthException(
        e.message.isNotEmpty ? e.message : l10n.serverIsUnreachable,
      );
    }

    if (response.statusCode == 202 && uri.path.endsWith('/api/register')) {
      try {
        final body = jsonDecode(response.body) as Map<String, Object?>;
        if (body['status'] == 'pending') return const AuthResult.pending();
      } catch (_) {}
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        accountErrorMessage(response.body) ??
            _extractError(response.body) ??
            l10n.authFailedGeneric,
      );
    }

    final Map<String, Object?> json;
    try {
      json = jsonDecode(response.body) as Map<String, Object?>;
    } on FormatException {
      throw AuthException(l10n.connectionFailed('Invalid JSON'));
    }

    if (expectedServerSignature != null) {
      final serverSig = json['server_signature'] as String?;
      if (serverSig != null && serverSig != expectedServerSignature) {
        throw AuthException(l10n.authFailedGeneric);
      }
    }

    final accessToken = json['access_token'] as String?;
    final refreshToken = json['refresh_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw AuthException(l10n.authErrorMissingAccessToken);
    }
    if (refreshToken == null || refreshToken.isEmpty) {
      throw AuthException(l10n.authErrorMissingRefreshToken);
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

String? accountErrorMessage(String body) {
  try {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final l10n = platformAppLocalizations();
    final code = (data['code'] as String?)?.toLowerCase();
    final error = (data['error'] as String?)?.toLowerCase();
    final key = code ?? error;
    if (key == null) return null;

    final isRu = l10n.localeName.startsWith('ru');

    switch (key) {
      case 'registration_pending':
        return l10n.registrationPending;
      case 'registration_closed':
        return l10n.registrationClosed;
      case 'account_blocked':
        return l10n.accountBlocked;
      case 'password_reset_required':
        return l10n.passwordResetRequired;
      case 'maintenance':
        return l10n.serverMaintenance;
      case 'quota_exceeded':
        return l10n.storageQuotaExceeded;
      case 'invalid_credentials':
      case 'invalid credentials':
        return isRu
            ? 'Неверное имя пользователя или пароль.'
            : 'Invalid username or password.';
      case 'user_already_exists':
        return isRu
            ? 'Пользователь с таким именем уже существует.'
            : 'A user with this username already exists.';
      case 'rate_limited':
      case 'rate_limit_exceeded':
      case 'rate limit exceeded':
        return isRu
            ? 'Слишком много запросов. Пожалуйста, подождите.'
            : 'Too many requests. Please try again later.';
      case 'username_required':
      case 'username is required':
        return l10n.usernameIsRequired;
      case 'invalid challenge parameters':
      case 'invalid challenge token':
      case 'challenge token expired':
      case 'nonce already consumed':
        return isRu
            ? 'Сессия авторизации устарела. Попробуйте снова.'
            : 'Authentication session expired. Please try again.';
      default:
        return data['error'] as String?;
    }
  } catch (_) {
    return null;
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException($message)';
}

class ServerUnreachableException extends AuthException {
  const ServerUnreachableException([String? message])
    : super(message ?? 'Server is unreachable.');
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

  Future<bool> authenticate({
    required String serverId,
    required String baseUrl,
    required String username,
    required String password,
    required AuthMode mode,
    String? email,
  }) async {
    final isOnline = await gateway.ping(baseUrl);
    if (!isOnline) {
      final l10n = platformAppLocalizations();
      throw ServerUnreachableException(l10n.serverIsUnreachable);
    }

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
    if (result.pending) return false;
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
    return true;
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
      throw AuthException(
        platformAppLocalizations().authErrorNoSavedCredentials,
      );
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
    final l10n = platformAppLocalizations();
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
        message: l10n.connectionFailed('HTTP ${response.statusCode}'),
      );
    } on SocketException {
      return SessionCheckResult(
        SessionCheckStatus.unreachable,
        message: l10n.serverIsUnreachable,
      );
    } on http.ClientException {
      return SessionCheckResult(
        SessionCheckStatus.unreachable,
        message: l10n.serverIsUnreachable,
      );
    } on TimeoutException {
      return SessionCheckResult(
        SessionCheckStatus.unreachable,
        message: l10n.serverIsUnreachable,
      );
    } catch (_) {
      return SessionCheckResult(
        SessionCheckStatus.unreachable,
        message: l10n.serverIsUnreachable,
      );
    }
  }

  Future<void> refreshSession({
    required String serverId,
    required String baseUrl,
  }) async {
    final refreshToken = await secretStore.readRefreshToken(serverId);
    if (refreshToken == null || refreshToken.isEmpty) {
      throw AuthException(platformAppLocalizations().authErrorNoRefreshToken);
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
    final scramKeys = await ScramUtils.generateArgon2idRegistrationKeys(
      newPassword,
    );
    final uri = _endpoint(baseUrl, '/api/auth/reset-password/verify');
    final response = await _client.post(
      uri,
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'code': code,
        'kdf': 'argon2id',
        'salt': scramKeys.saltHex,
        'm': scramKeys.memCostKb,
        't': scramKeys.timeCost,
        'p': scramKeys.lanes,
        'stored_key': scramKeys.storedKeyHex,
        'server_key': scramKeys.serverKeyHex,
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
    String? currentPassword,
    required String newPassword,
  }) async {
    final token = await readAccessToken(serverId);
    if (token == null || token.isEmpty) {
      throw AuthException(platformAppLocalizations().authErrorNoActiveSession);
    }
    final username = await readLastUsername(serverId);
    if (username == null || username.isEmpty) {
      throw AuthException(platformAppLocalizations().authErrorNoSavedUsername);
    }

    final curPw =
        currentPassword ?? await secretStore.readSavedPassword(serverId);
    if (curPw == null || curPw.isEmpty) {
      throw AuthException(platformAppLocalizations().passwordCannotBeEmpty);
    }

    final clientNonce = ScramUtils.generateRandomHex(16);
    dynamic challenge;
    try {
      final res = await _client.get(
        _endpoint(
          baseUrl,
          '/api/account/reauth/challenge',
        ).replace(queryParameters: {'nonce': clientNonce}),
        headers: {'authorization': 'Bearer $token'},
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        challenge = jsonDecode(res.body);
      }
    } catch (_) {}

    if (challenge == null) {
      try {
        final res = await _client.get(
          _endpoint(baseUrl, '/api/auth/challenge').replace(
            queryParameters: {'username': username, 'nonce': clientNonce},
          ),
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          challenge = jsonDecode(res.body);
        }
      } catch (_) {}
    }

    final scramKeys = await ScramUtils.generateArgon2idRegistrationKeys(
      newPassword,
    );

    final payload = <String, dynamic>{
      'kdf': 'argon2id',
      'salt': scramKeys.saltHex,
      'm': scramKeys.memCostKb,
      't': scramKeys.timeCost,
      'p': scramKeys.lanes,
      'stored_key': scramKeys.storedKeyHex,
      'server_key': scramKeys.serverKeyHex,
    };

    if (challenge != null && challenge['auth_mode'] == 'scram-argon2id') {
      final salt = challenge['salt'] as String;
      final m = challenge['m'] as int;
      final t = challenge['t'] as int;
      final p = challenge['p'] as int;
      final nonce = challenge['nonce'] as String;
      final challengeToken = challenge['challenge_token'] as String;

      final authMessage = ScramUtils.scramArgon2idAuthMessage(
        username,
        nonce,
        salt,
        m,
        t,
        p,
      );
      final proof = await ScramUtils.computeArgon2idProof(
        password: curPw,
        saltHex: salt,
        memCostKb: m,
        timeCost: t,
        lanes: p,
        authMessage: authMessage,
      );

      payload['current_nonce'] = nonce;
      payload['current_client_proof'] = proof.clientProofHex;
      payload['current_challenge_token'] = challengeToken;
    } else {
      payload['current_password'] = curPw;
    }

    await _sendAuthorizedJson(
      method: 'POST',
      uri: _endpoint(baseUrl, '/api/account/password'),
      token: token,
      payload: payload,
      fallbackMessage: platformAppLocalizations().passwordChangeFailedGeneric,
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
      throw AuthException(platformAppLocalizations().authErrorNoActiveSession);
    }

    await _sendAuthorizedJson(
      method: 'DELETE',
      uri: _endpoint(baseUrl, '/api/account'),
      token: token,
      fallbackMessage: platformAppLocalizations().accountDeletionFailedGeneric,
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
