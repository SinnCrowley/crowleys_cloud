import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../auth_service.dart';

/// Centralized HTTP client wrapper that handles Bearer token authorization,
/// automatic 401 interception, session refresh via [AuthService], network failure notifications, and retry logic.
class AuthenticatedHttpClient {
  AuthenticatedHttpClient({
    required this.authService,
    required this.serverId,
    required this.baseUrl,
    http.Client? client,
    this.onConnectionLost,
  }) : client = client ?? http.Client();

  final AuthService authService;
  final String serverId;
  final String baseUrl;
  final http.Client client;
  final ValueChanged<String>? onConnectionLost;

  /// Executes an HTTP GET request with Bearer authorization and 401 token refresh retry.
  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) {
    return _sendWithRetry(
      (token) => _safeRequest(
        () => client.get(uri, headers: _buildHeaders(token, headers)),
      ),
      headers: headers,
    );
  }

  /// Executes a streamed HTTP GET request with Bearer authorization and 401 token refresh retry.
  Future<http.StreamedResponse> streamedGet(
    Uri uri, {
    Map<String, String>? headers,
  }) {
    return _sendStreamedWithRetry(
      (token) => _safeStreamedRequest(() {
        final request = http.Request('GET', uri)
          ..headers.addAll(_buildHeaders(token, headers));
        return client.send(request);
      }),
      headers: headers,
    );
  }

  /// Executes an HTTP POST request sending JSON with Bearer authorization and 401 token refresh retry.
  Future<http.Response> postJson(
    Uri uri,
    Map<String, Object?> payload, {
    Map<String, String>? headers,
  }) {
    final mergedHeaders = {
      'content-type': 'application/json',
      ...?headers,
    };
    return _sendWithRetry(
      (token) => _safeRequest(
        () => client.post(
          uri,
          headers: _buildHeaders(token, mergedHeaders),
          body: jsonEncode(payload),
        ),
      ),
      headers: mergedHeaders,
    );
  }

  /// Executes an HTTP POST request sending raw bytes with Bearer authorization and 401 token refresh retry.
  Future<http.Response> postBytes(
    Uri uri,
    List<int> body, {
    Map<String, String>? headers,
  }) {
    final mergedHeaders = {
      'content-type': 'application/octet-stream',
      ...?headers,
    };
    return _sendWithRetry(
      (token) => _safeRequest(
        () => client.post(
          uri,
          headers: _buildHeaders(token, mergedHeaders),
          body: body,
        ),
      ),
      headers: mergedHeaders,
    );
  }

  /// Executes an HTTP DELETE request with Bearer authorization and 401 token refresh retry.
  Future<http.Response> delete(Uri uri, {Map<String, String>? headers}) {
    return _sendWithRetry(
      (token) => _safeRequest(
        () => client.delete(uri, headers: _buildHeaders(token, headers)),
      ),
      headers: headers,
    );
  }

  /// Executes an HTTP DELETE request sending JSON payload with Bearer authorization and 401 token refresh retry.
  Future<http.Response> deleteJson(
    Uri uri,
    Map<String, Object?> payload, {
    Map<String, String>? headers,
  }) {
    final mergedHeaders = {
      'content-type': 'application/json',
      ...?headers,
    };
    return _sendWithRetry(
      (token) => _safeRequest(
        () => client.delete(
          uri,
          headers: _buildHeaders(token, mergedHeaders),
          body: jsonEncode(payload),
        ),
      ),
      headers: mergedHeaders,
    );
  }

  /// Dispatches an arbitrary request function using the current valid token with 401 retry.
  Future<http.Response> sendAuthorized({
    required Future<http.Response> Function(String token) send,
    String? explicitToken,
  }) async {
    if (explicitToken != null && explicitToken.isNotEmpty) {
      final response = await send(explicitToken);
      if (response.statusCode != 401) return response;
    }
    return _sendWithRetry(send);
  }

  Map<String, String> _buildHeaders(
    String token,
    Map<String, String>? baseHeaders,
  ) {
    final map = <String, String>{};
    if (baseHeaders != null) {
      map.addAll(baseHeaders);
    }
    if (token.isNotEmpty) {
      map['authorization'] = 'Bearer $token';
    }
    return map;
  }

  Future<http.Response> _sendWithRetry(
    Future<http.Response> Function(String token) send, {
    Map<String, String>? headers,
  }) async {
    String? explicitToken;
    if (headers != null) {
      final authHeader = headers.entries
          .firstWhere(
            (e) => e.key.toLowerCase() == 'authorization',
            orElse: () => const MapEntry('', ''),
          )
          .value;
      if (authHeader.startsWith('Bearer ')) {
        explicitToken = authHeader.substring(7).trim();
      }
    }

    var token = (explicitToken != null && explicitToken.isNotEmpty)
        ? explicitToken
        : await authService.readAccessToken(serverId);

    if (token == null || token.isEmpty) return http.Response('', 401);

    var response = await send(token);
    if (response.statusCode != 401) return response;

    try {
      await authService.refreshSession(serverId: serverId, baseUrl: baseUrl);
      token = await authService.readAccessToken(serverId);
      if (token == null || token.isEmpty) return response;
      response = await send(token);
    } catch (_) {}
    return response;
  }

  Future<http.StreamedResponse> _sendStreamedWithRetry(
    Future<http.StreamedResponse> Function(String token) send, {
    Map<String, String>? headers,
  }) async {
    String? explicitToken;
    if (headers != null) {
      final authHeader = headers.entries
          .firstWhere(
            (e) => e.key.toLowerCase() == 'authorization',
            orElse: () => const MapEntry('', ''),
          )
          .value;
      if (authHeader.startsWith('Bearer ')) {
        explicitToken = authHeader.substring(7).trim();
      }
    }

    var token = (explicitToken != null && explicitToken.isNotEmpty)
        ? explicitToken
        : await authService.readAccessToken(serverId);

    if (token == null || token.isEmpty) {
      return http.StreamedResponse(const Stream.empty(), 401);
    }

    var response = await send(token);
    if (response.statusCode != 401) return response;

    try {
      await authService.refreshSession(serverId: serverId, baseUrl: baseUrl);
      token = await authService.readAccessToken(serverId);
      if (token == null || token.isEmpty) return response;
      response = await send(token);
    } catch (_) {}
    return response;
  }

  bool _isConnectionUnavailableStatus(int statusCode) {
    return statusCode == 500 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;
  }

  void _notifyConnectionLost(String message) {
    try {
      onConnectionLost?.call(message);
    } catch (_) {}
  }

  Future<http.Response> _safeRequest(
    Future<http.Response> Function() action,
  ) async {
    try {
      final response = await action();
      if (_isConnectionUnavailableStatus(response.statusCode)) {
        _notifyConnectionLost('Server is unreachable.');
      }
      return response;
    } on SocketException {
      _notifyConnectionLost('Server is unreachable.');
      return http.Response('', 503);
    } on http.ClientException {
      _notifyConnectionLost('Server is unreachable.');
      return http.Response('', 503);
    } on TimeoutException {
      _notifyConnectionLost('Server is unreachable.');
      return http.Response('', 504);
    } on HandshakeException {
      _notifyConnectionLost('Server is unreachable.');
      return http.Response('', 525);
    } catch (_) {
      _notifyConnectionLost('Server is unreachable.');
      return http.Response('', 500);
    }
  }

  Future<http.StreamedResponse> _safeStreamedRequest(
    Future<http.StreamedResponse> Function() action,
  ) async {
    try {
      final response = await action();
      if (_isConnectionUnavailableStatus(response.statusCode)) {
        _notifyConnectionLost('Server is unreachable.');
      }
      return response;
    } on SocketException {
      _notifyConnectionLost('Server is unreachable.');
      return http.StreamedResponse(const Stream.empty(), 503);
    } on http.ClientException {
      _notifyConnectionLost('Server is unreachable.');
      return http.StreamedResponse(const Stream.empty(), 503);
    } on TimeoutException {
      _notifyConnectionLost('Server is unreachable.');
      return http.StreamedResponse(const Stream.empty(), 504);
    } on HandshakeException {
      _notifyConnectionLost('Server is unreachable.');
      return http.StreamedResponse(const Stream.empty(), 525);
    } catch (_) {
      _notifyConnectionLost('Server is unreachable.');
      return http.StreamedResponse(const Stream.empty(), 500);
    }
  }
}
