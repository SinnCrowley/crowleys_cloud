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

import 'package:crowleys_cloud/app_settings_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure credential and token storage interface for multi-server profile sessions.
abstract class SecretStore {
  /// Saves an access token for the given [serverId].
  Future<void> saveToken({required String serverId, required String token});

  /// Saves both access and refresh tokens for the given [serverId].
  Future<void> saveTokens({
    required String serverId,
    required String accessToken,
    required String refreshToken,
  });

  /// Persists user credentials securely for background re-authentication.
  Future<void> saveCredentials({
    required String serverId,
    required String username,
    required String password,
  });

  /// Reads the active access token for [serverId] if valid under current lifetime settings.
  Future<String?> readToken(String serverId);

  /// Reads the active refresh token for [serverId] if valid.
  Future<String?> readRefreshToken(String serverId);

  /// Reads the last saved username for [serverId].
  Future<String?> readLastUsername(String serverId);

  /// Reads saved user password for [serverId].
  Future<String?> readSavedPassword(String serverId);

  /// Persists a background sync token for fast API authentication.
  Future<void> saveSyncToken({
    required String serverId,
    required String syncToken,
  });

  /// Reads the saved sync token for [serverId].
  Future<String?> readSyncToken(String serverId);

  /// Clears the saved sync token for [serverId].
  Future<void> clearSyncToken(String serverId);

  /// Clears stored access, refresh, and expiration timestamps for [serverId].
  Future<void> clearToken(String serverId);

  /// Clears stored login credentials for [serverId].
  Future<void> clearCredentials(String serverId);
}

/// Default secure storage instance configured with [KeychainAccessibility.first_unlock]
/// to allow background services (like iOS background sync) to read tokens when the phone is locked,
/// and [AndroidOptions.resetOnError] to recover from corrupted KeyStore entries.
const defaultSecureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(resetOnError: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
);

/// Secure storage implementation leveraging [FlutterSecureStorage] with
/// lifetime calculation, epoch token expiration tracking, and volatile in-memory fallback.
class FlutterSecureSecretStore implements SecretStore {
  FlutterSecureSecretStore({
    FlutterSecureStorage? storage,
    AppSettingsService? settingsService,
  }) : storage = storage ?? defaultSecureStorage,
       _settingsService = settingsService ?? AppSettingsService();

  final FlutterSecureStorage storage;
  final AppSettingsService _settingsService;
  final Map<String, String> _sessionTokens = {};
  final Map<String, String> _sessionRefreshTokens = {};
  final Map<String, String> _sessionUsernames = {};
  final Map<String, String> _sessionPasswords = {};
  final Map<String, String> _sessionSyncTokens = {};

  Future<void> _safeWrite(String key, String value) async {
    try {
      await storage.write(key: key, value: value);
    } catch (_) {
      try {
        await storage.delete(key: key);
        await storage.write(key: key, value: value);
      } catch (_) {
        // Fall back gracefully to in-memory session if secure storage fails on device
      }
    }
  }

  Future<void> _safeDelete(String key) async {
    try {
      await storage.delete(key: key);
    } catch (_) {}
  }

  @override
  Future<void> clearToken(String serverId) async {
    _sessionTokens.remove(serverId);
    _sessionRefreshTokens.remove(serverId);
    await _safeDelete(_tokenKey(serverId));
    await _safeDelete(_refreshTokenKey(serverId));
    await _safeDelete(_tokenExpiresAtKey(serverId));
  }

  @override
  Future<void> clearCredentials(String serverId) async {
    _sessionUsernames.remove(serverId);
    _sessionPasswords.remove(serverId);
    await _safeDelete(_usernameKey(serverId));
    await _safeDelete(_passwordKey(serverId));
  }

  @override
  Future<String?> readToken(String serverId) async {
    try {
      final sessionToken = _sessionTokens[serverId];
      if (sessionToken != null && sessionToken.isNotEmpty) return sessionToken;
      if (!await _canUseStoredTokens(serverId)) return null;
      final token = await storage.read(key: _tokenKey(serverId));
      if (token != null && token.isNotEmpty) {
        _sessionTokens[serverId] = token;
      }
      return token;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> readRefreshToken(String serverId) async {
    try {
      final sessionToken = _sessionRefreshTokens[serverId];
      if (sessionToken != null && sessionToken.isNotEmpty) return sessionToken;
      if (!await _canUseStoredTokens(serverId)) return null;
      final token = await storage.read(key: _refreshTokenKey(serverId));
      if (token != null && token.isNotEmpty) {
        _sessionRefreshTokens[serverId] = token;
      }
      return token;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> readLastUsername(String serverId) async {
    final sessionUsername = _sessionUsernames[serverId];
    if (sessionUsername != null && sessionUsername.isNotEmpty) {
      return sessionUsername;
    }
    try {
      final username = await storage.read(key: _usernameKey(serverId));
      if (username != null && username.isNotEmpty) {
        _sessionUsernames[serverId] = username;
      }
      return username;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> readSavedPassword(String serverId) async {
    final sessionPassword = _sessionPasswords[serverId];
    if (sessionPassword != null && sessionPassword.isNotEmpty) {
      return sessionPassword;
    }
    try {
      final password = await storage.read(key: _passwordKey(serverId));
      if (password != null && password.isNotEmpty) {
        _sessionPasswords[serverId] = password;
      }
      return password;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveToken({
    required String serverId,
    required String token,
  }) async {
    _sessionTokens[serverId] = token;
    await _persistTokensForLifetime(serverId, accessToken: token);
  }

  @override
  Future<void> saveTokens({
    required String serverId,
    required String accessToken,
    required String refreshToken,
  }) async {
    _sessionTokens[serverId] = accessToken;
    _sessionRefreshTokens[serverId] = refreshToken;
    await _persistTokensForLifetime(
      serverId,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<void> saveCredentials({
    required String serverId,
    required String username,
    required String password,
  }) async {
    _sessionUsernames[serverId] = username;
    _sessionPasswords[serverId] = password;
    await _safeWrite(_usernameKey(serverId), username);
    await _safeWrite(_passwordKey(serverId), password);
  }

  @override
  Future<void> saveSyncToken({
    required String serverId,
    required String syncToken,
  }) async {
    _sessionSyncTokens[serverId] = syncToken;
    await _safeWrite(_syncTokenKey(serverId), syncToken);
  }

  @override
  Future<String?> readSyncToken(String serverId) async {
    final sessionSyncToken = _sessionSyncTokens[serverId];
    if (sessionSyncToken != null && sessionSyncToken.isNotEmpty) {
      return sessionSyncToken;
    }
    try {
      final token = await storage.read(key: _syncTokenKey(serverId));
      if (token != null && token.isNotEmpty) {
        _sessionSyncTokens[serverId] = token;
      }
      return token;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearSyncToken(String serverId) async {
    _sessionSyncTokens.remove(serverId);
    await _safeDelete(_syncTokenKey(serverId));
  }

  String _tokenKey(String serverId) => 'server_token_$serverId';
  String _refreshTokenKey(String serverId) => 'server_refresh_token_$serverId';
  String _tokenExpiresAtKey(String serverId) =>
      'server_token_expires_at_$serverId';
  String _usernameKey(String serverId) => 'server_last_username_$serverId';
  String _passwordKey(String serverId) => 'server_saved_password_$serverId';
  String _syncTokenKey(String serverId) => 'server_sync_token_$serverId';

  Future<bool> _canUseStoredTokens(String serverId) async {
    try {
      final lifetime = await _settingsService.tokenLifetime();
      if (lifetime.expiresOnAppClose) return false;

      final expiresAtRaw = await storage.read(
        key: _tokenExpiresAtKey(serverId),
      );
      if (expiresAtRaw == null || expiresAtRaw.isEmpty) return false;
      final expiresAtMs = int.tryParse(expiresAtRaw);
      if (expiresAtMs == null) return false;
      if (expiresAtMs < 0) return true;

      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        expiresAtMs,
        isUtc: true,
      );
      if (DateTime.now().toUtc().isBefore(expiresAt)) return true;

      await clearToken(serverId);
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _persistTokensForLifetime(
    String serverId, {
    required String accessToken,
    String? refreshToken,
  }) async {
    try {
      final lifetime = await _settingsService.tokenLifetime();
      if (lifetime.expiresOnAppClose) {
        await _safeDelete(_tokenKey(serverId));
        await _safeDelete(_refreshTokenKey(serverId));
        await _safeDelete(_tokenExpiresAtKey(serverId));
        return;
      }

      final expiresAt = lifetime.neverExpiresOnDevice
          ? -1
          : (lifetime.duration != null
                ? DateTime.now()
                      .toUtc()
                      .add(lifetime.duration!)
                      .millisecondsSinceEpoch
                : -1);
      await _safeWrite(_tokenKey(serverId), accessToken);
      if (refreshToken != null) {
        await _safeWrite(_refreshTokenKey(serverId), refreshToken);
      }
      await _safeWrite(_tokenExpiresAtKey(serverId), expiresAt.toString());
    } catch (_) {
      // Kept in _sessionTokens / _sessionRefreshTokens in memory
    }
  }
}

/// In-memory implementation of [SecretStore] for unit testing.
class InMemorySecretStore implements SecretStore {
  final Map<String, String> _tokens = {};
  final Map<String, String> _refreshTokens = {};
  final Map<String, String> _syncTokens = {};
  final Map<String, String> _usernames = {};
  final Map<String, String> _passwords = {};

  @override
  Future<void> saveSyncToken({
    required String serverId,
    required String syncToken,
  }) async {
    _syncTokens[serverId] = syncToken;
  }

  @override
  Future<String?> readSyncToken(String serverId) async {
    return _syncTokens[serverId];
  }

  @override
  Future<void> clearSyncToken(String serverId) async {
    _syncTokens.remove(serverId);
  }

  @override
  Future<void> clearToken(String serverId) async {
    _tokens.remove(serverId);
    _refreshTokens.remove(serverId);
  }

  @override
  Future<void> clearCredentials(String serverId) async {
    _usernames.remove(serverId);
    _passwords.remove(serverId);
  }

  @override
  Future<String?> readToken(String serverId) async {
    return _tokens[serverId];
  }

  @override
  Future<String?> readRefreshToken(String serverId) async {
    return _refreshTokens[serverId];
  }

  @override
  Future<String?> readLastUsername(String serverId) async {
    return _usernames[serverId];
  }

  @override
  Future<String?> readSavedPassword(String serverId) async {
    return _passwords[serverId];
  }

  @override
  Future<void> saveToken({
    required String serverId,
    required String token,
  }) async {
    _tokens[serverId] = token;
  }

  @override
  Future<void> saveTokens({
    required String serverId,
    required String accessToken,
    required String refreshToken,
  }) async {
    _tokens[serverId] = accessToken;
    _refreshTokens[serverId] = refreshToken;
  }

  @override
  Future<void> saveCredentials({
    required String serverId,
    required String username,
    required String password,
  }) async {
    _usernames[serverId] = username;
    _passwords[serverId] = password;
  }
}

/// Decorator for [SecretStore] that allows overriding sync tokens (e.g. during background jobs).
class OverrideSyncTokenSecretStore implements SecretStore {
  OverrideSyncTokenSecretStore({
    required this.delegate,
    this.overrideSyncToken,
  });

  final SecretStore delegate;
  final String? overrideSyncToken;

  @override
  Future<void> saveToken({required String serverId, required String token}) =>
      delegate.saveToken(serverId: serverId, token: token);

  @override
  Future<void> saveTokens({
    required String serverId,
    required String accessToken,
    required String refreshToken,
  }) => delegate.saveTokens(
    serverId: serverId,
    accessToken: accessToken,
    refreshToken: refreshToken,
  );

  @override
  Future<void> saveCredentials({
    required String serverId,
    required String username,
    required String password,
  }) => delegate.saveCredentials(
    serverId: serverId,
    username: username,
    password: password,
  );

  @override
  Future<String?> readToken(String serverId) => delegate.readToken(serverId);

  @override
  Future<String?> readRefreshToken(String serverId) =>
      delegate.readRefreshToken(serverId);

  @override
  Future<String?> readLastUsername(String serverId) =>
      delegate.readLastUsername(serverId);

  @override
  Future<String?> readSavedPassword(String serverId) =>
      delegate.readSavedPassword(serverId);

  @override
  Future<void> saveSyncToken({
    required String serverId,
    required String syncToken,
  }) => delegate.saveSyncToken(serverId: serverId, syncToken: syncToken);

  @override
  Future<String?> readSyncToken(String serverId) async {
    if (overrideSyncToken != null && overrideSyncToken!.isNotEmpty) {
      return overrideSyncToken;
    }
    return delegate.readSyncToken(serverId);
  }

  @override
  Future<void> clearSyncToken(String serverId) =>
      delegate.clearSyncToken(serverId);

  @override
  Future<void> clearToken(String serverId) => delegate.clearToken(serverId);

  @override
  Future<void> clearCredentials(String serverId) =>
      delegate.clearCredentials(serverId);
}
