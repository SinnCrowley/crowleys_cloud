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
