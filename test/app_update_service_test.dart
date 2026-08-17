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

import 'dart:convert';
import 'package:crowleys_cloud/app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AppUpdateService.isVersionNewer', () {
    test('correctly compares version numbers', () {
      expect(AppUpdateService.isVersionNewer('1.1.0', '1.0.0'), isTrue);
      expect(AppUpdateService.isVersionNewer('v1.1.0', '1.0.0'), isTrue);
      expect(AppUpdateService.isVersionNewer('2.0.0', '1.9.9'), isTrue);
      expect(AppUpdateService.isVersionNewer('1.0.1', '1.0.0'), isTrue);
      expect(AppUpdateService.isVersionNewer('1.0.0', '1.0.0'), isFalse);
      expect(AppUpdateService.isVersionNewer('0.9.9', '1.0.0'), isFalse);
      expect(AppUpdateService.isVersionNewer('v1.0.0-beta', '1.0.0'), isFalse);
    });
  });

  group('AppUpdateService.checkForUpdates', () {
    test('returns update info when a newer release is found', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/releases/latest')) {
          return http.Response(
            jsonEncode({
              'tag_name': 'v1.1.0',
              'html_url':
                  'https://github.com/SinnCrowley/crowleys_cloud/releases/tag/v1.1.0',
              'body': '## What\'s Changed\n- Added in-app update checking',
              'assets': [
                {
                  'name': 'crowleys-cloud-1.1.0.apk',
                  'browser_download_url':
                      'https://github.com/SinnCrowley/crowleys_cloud/releases/download/v1.1.0/crowleys-cloud-1.1.0.apk',
                },
              ],
            }),
            200,
          );
        }
        return http.Response('Not found', 440);
      });

      final service = AppUpdateService(currentVersion: '1.0.0');
      final result = await service.checkForUpdates(client: mockClient);

      expect(result, isNotNull);
      expect(result!.hasUpdate, isTrue);
      expect(result.currentVersion, equals('1.0.0'));
      expect(result.latestVersion, equals('1.1.0'));
      expect(result.releaseNotes, contains('Added in-app update checking'));
      expect(
        result.apkUrl,
        equals(
          'https://github.com/SinnCrowley/crowleys_cloud/releases/download/v1.1.0/crowleys-cloud-1.1.0.apk',
        ),
      );
    });

    test('returns hasUpdate false when on latest version', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'tag_name': 'v1.0.0',
            'html_url':
                'https://github.com/SinnCrowley/crowleys_cloud/releases/tag/v1.0.0',
            'body': 'Initial release',
            'assets': [],
          }),
          200,
        );
      });

      final service = AppUpdateService(currentVersion: '1.0.0');
      final result = await service.checkForUpdates(client: mockClient);

      expect(result, isNotNull);
      expect(result!.hasUpdate, isFalse);
      expect(result.latestVersion, equals('1.0.0'));
    });

    test(
      'returns hasUpdate false when no releases published yet (404)',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'message': 'Not Found',
              'documentation_url':
                  'https://docs.github.com/rest/releases/releases#get-the-latest-release',
            }),
            404,
          );
        });

        final service = AppUpdateService(currentVersion: '1.0.0');
        final result = await service.checkForUpdates(client: mockClient);

        expect(result, isNotNull);
        expect(result!.hasUpdate, isFalse);
        expect(result.currentVersion, equals('1.0.0'));
        expect(result.latestVersion, equals('1.0.0'));
      },
    );
  });
}
