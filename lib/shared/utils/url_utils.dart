/// Centralized URL parsing, scheme injection, trailing slash normalization,
/// and API endpoint resolution utilities for client-server communication.
abstract final class UrlUtils {
  /// Resolves [path] against [baseUrl], ensuring a valid scheme (defaults to 'http://').
  /// Preserves base query parameters and normalizes multi-leading/trailing slashes.
  static Uri buildEndpoint(String baseUrl, String path) {
    final raw = baseUrl.trim();
    if (raw.isEmpty) return Uri.parse(path);

    final withScheme = raw.contains('://') ? raw : 'http://$raw';
    final baseUri = Uri.parse(withScheme);

    var basePath = baseUri.path.replaceAll(RegExp(r'/+'), '/');
    if (basePath.isEmpty) {
      basePath = '/';
    } else if (!basePath.endsWith('/')) {
      basePath = '$basePath/';
    }

    var cleanPath = path.trim().replaceAll(RegExp(r'/+'), '/');
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    final combinedPath = '$basePath$cleanPath';
    final targetUri = Uri.parse(combinedPath);

    Map<String, String>? mergedQuery;
    if (baseUri.hasQuery || targetUri.hasQuery) {
      mergedQuery = {...baseUri.queryParameters, ...targetUri.queryParameters};
    }

    String? fragment;
    if (targetUri.hasFragment && targetUri.fragment.isNotEmpty) {
      fragment = targetUri.fragment;
    } else if (baseUri.hasFragment && baseUri.fragment.isNotEmpty) {
      fragment = baseUri.fragment;
    }

    return baseUri.replace(
      path: targetUri.path,
      queryParameters: (mergedQuery != null && mergedQuery.isNotEmpty)
          ? mergedQuery
          : null,
      fragment: fragment,
    );
  }

  /// Builds a Uri targeting an API endpoint path under `/api`.
  /// Automatically injects `/api` into the base path if not already present,
  /// avoiding duplicate `/api` segments on versioned paths like `/api/v1`.
  static Uri buildApiEndpoint(
    String baseUrl,
    String endpointPath, [
    Map<String, String>? queryParameters,
  ]) {
    final raw = baseUrl.trim();
    final withScheme = raw.contains('://') ? raw : 'http://$raw';
    final base = Uri.parse(withScheme);

    var basePath = base.path.replaceAll(RegExp(r'/+'), '/');
    if (basePath.isEmpty) basePath = '/';
    if (basePath.endsWith('/') && basePath.length > 1) {
      basePath = basePath.substring(0, basePath.length - 1);
    }

    final cleanEndpoint = endpointPath.startsWith('/')
        ? endpointPath
        : '/$endpointPath';

    final hasApiSegment =
        basePath == '/api' ||
        basePath.startsWith('/api/') ||
        basePath.contains('/api/') ||
        basePath.endsWith('/api');

    final apiPath = hasApiSegment
        ? '$basePath$cleanEndpoint'
        : (basePath == '/'
              ? '/api$cleanEndpoint'
              : '$basePath/api$cleanEndpoint');

    Map<String, String>? mergedQuery;
    if (base.hasQuery ||
        (queryParameters != null && queryParameters.isNotEmpty)) {
      mergedQuery = {...base.queryParameters, ...?queryParameters};
    }

    String? fragment;
    if (base.hasFragment && base.fragment.isNotEmpty) {
      fragment = base.fragment;
    }

    return base.replace(
      path: apiPath.replaceAll(RegExp(r'/+'), '/'),
      queryParameters: (mergedQuery != null && mergedQuery.isNotEmpty)
          ? mergedQuery
          : null,
      fragment: fragment,
    );
  }

  /// Parses user-entered connection strings into scheme-qualified base URL and port,
  /// handling userinfo credentials (user:pass@host), IPv6 ([::1]), and whitespace properly.
  static Map<String, String> parseUrlInput(String input) {
    var raw = input.trim();
    if (raw.isEmpty) {
      return {'baseUrl': '', 'port': ''};
    }

    raw = raw.replaceAll(RegExp(r'\s+'), '');

    String scheme = 'http';
    if (raw.startsWith('https://')) {
      scheme = 'https';
      raw = raw.substring(8);
    } else if (raw.startsWith('http://')) {
      scheme = 'http';
      raw = raw.substring(7);
    }

    final parsedUri = Uri.tryParse('$scheme://$raw');
    if (parsedUri != null && parsedUri.hasAuthority) {
      final userInfo = parsedUri.userInfo.isNotEmpty
          ? '${parsedUri.userInfo}@'
          : '';
      final host = parsedUri.host;
      final port = parsedUri.hasPort ? parsedUri.port.toString() : '';

      final hostPart = host.contains(':') && !host.startsWith('[')
          ? '[$host]'
          : host;
      return {'baseUrl': '$scheme://$userInfo$hostPart', 'port': port};
    }

    return {'baseUrl': '$scheme://$raw', 'port': ''};
  }

  /// Normalizes a base URL to ensure proper scheme and trimmed trailing slashes.
  static String normalizeBaseUrl(String baseUrl) {
    var raw = baseUrl.trim();
    if (raw.isEmpty) return '';
    raw = raw.replaceAll(RegExp(r'\s+'), '');
    final withScheme = raw.contains('://') ? raw : 'http://$raw';
    final uri = Uri.tryParse(withScheme) ?? Uri.parse(withScheme);
    var path = uri.path.replaceAll(RegExp(r'/+'), '/');
    while (path.endsWith('/') && path.length > 1) {
      path = path.substring(0, path.length - 1);
    }
    String? fragment;
    if (uri.hasFragment && uri.fragment.isNotEmpty) {
      fragment = uri.fragment;
    }
    return uri
        .replace(path: path == '/' ? '' : path, fragment: fragment)
        .toString();
  }
}
