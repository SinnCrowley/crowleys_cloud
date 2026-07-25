import 'package:flutter_test/flutter_test.dart';
import 'package:crowleys_cloud/shared/utils/url_utils.dart';

void main() {
  group('UrlUtils', () {
    test(
      'buildEndpoint injects http scheme when missing and resolves relative path',
      () {
        final uri = UrlUtils.buildEndpoint('localhost:8080', 'dir');
        expect(uri.toString(), 'http://localhost:8080/dir');
      },
    );

    test(
      'buildEndpoint preserves existing https scheme and normalizes trailing slash',
      () {
        final uri = UrlUtils.buildEndpoint(
          'https://example.com/sub/',
          '/files/download',
        );
        expect(uri.toString(), 'https://example.com/sub/files/download');
      },
    );

    test('buildApiEndpoint adds /api prefix when missing', () {
      final uri = UrlUtils.buildApiEndpoint('http://localhost:8080', '/dir', {
        'scope': 'private',
      });
      expect(uri.toString(), 'http://localhost:8080/api/dir?scope=private');
    });

    test(
      'buildApiEndpoint does not duplicate /api prefix when already present',
      () {
        final uri = UrlUtils.buildApiEndpoint(
          'http://localhost:8080/api',
          '/dir',
        );
        expect(uri.toString(), 'http://localhost:8080/api/dir');
      },
    );

    test('parseUrlInput parses scheme, host, and port correctly', () {
      final result = UrlUtils.parseUrlInput('https://192.168.1.100:8080/path/');
      expect(result['baseUrl'], 'https://192.168.1.100');
      expect(result['port'], '8080');
    });

    test('parseUrlInput handles input without scheme or port', () {
      final result = UrlUtils.parseUrlInput('my-server.local');
      expect(result['baseUrl'], 'http://my-server.local');
      expect(result['port'], '');
    });

    test('normalizeBaseUrl removes trailing slashes', () {
      final normalized = UrlUtils.normalizeBaseUrl(
        'http://example.com:3000///',
      );
      expect(normalized, 'http://example.com:3000');
    });
  });
}
