import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecretStore {
  Future<void> saveToken({required String serverId, required String token});

  Future<void> saveTokens({
    required String serverId,
    required String accessToken,
    required String refreshToken,
  });

  Future<String?> readToken(String serverId);

  Future<String?> readRefreshToken(String serverId);

  Future<void> clearToken(String serverId);
}

class FlutterSecureSecretStore implements SecretStore {
  FlutterSecureSecretStore({required this.storage});

  final FlutterSecureStorage storage;

  @override
  Future<void> clearToken(String serverId) async {
    await storage.delete(key: _tokenKey(serverId));
    await storage.delete(key: _refreshTokenKey(serverId));
  }

  @override
  Future<String?> readToken(String serverId) async {
    return storage.read(key: _tokenKey(serverId));
  }

  @override
  Future<String?> readRefreshToken(String serverId) async {
    return storage.read(key: _refreshTokenKey(serverId));
  }

  @override
  Future<void> saveToken({
    required String serverId,
    required String token,
  }) async {
    await storage.write(key: _tokenKey(serverId), value: token);
  }

  @override
  Future<void> saveTokens({
    required String serverId,
    required String accessToken,
    required String refreshToken,
  }) async {
    await storage.write(key: _tokenKey(serverId), value: accessToken);
    await storage.write(key: _refreshTokenKey(serverId), value: refreshToken);
  }

  String _tokenKey(String serverId) => 'server_token_$serverId';
  String _refreshTokenKey(String serverId) => 'server_refresh_token_$serverId';
}

class InMemorySecretStore implements SecretStore {
  final Map<String, String> _tokens = {};
  final Map<String, String> _refreshTokens = {};

  @override
  Future<void> clearToken(String serverId) async {
    _tokens.remove(serverId);
    _refreshTokens.remove(serverId);
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
}
