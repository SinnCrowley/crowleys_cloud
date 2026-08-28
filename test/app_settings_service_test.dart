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
import 'package:crowleys_cloud/cache_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('returns defaults when no settings are stored', () async {
    final settings = AppSettingsService();

    expect(await settings.showHiddenFiles(), false);
    expect(await settings.biometricLoginEnabled(), true);
    expect(await settings.downloadDirectoryPath(), null);
    expect(await settings.tokenLifetime(), TokenLifetimeOption.oneMonth);
    expect(
      await settings.cacheMaxBytes(),
      CacheService.defaultThumbnailMaxBytes,
    );
    expect(
      await settings.defaultBackupTargetDirectory(),
      startsWith('/backup/'),
    );
  });

  test('persists behavior and storage settings', () async {
    final settings = AppSettingsService();

    await settings.setShowHiddenFiles(true);
    await settings.setBiometricLoginEnabled(true);
    await settings.setDownloadDirectoryPath('/tmp/downloads');
    await settings.setTokenLifetime(TokenLifetimeOption.oneWeek);
    await settings.setCacheMaxBytes(CacheLimitOption.values.first.bytes);

    expect(await settings.showHiddenFiles(), true);
    expect(await settings.biometricLoginEnabled(), true);
    expect(await settings.downloadDirectoryPath(), '/tmp/downloads');
    expect(await settings.tokenLifetime(), TokenLifetimeOption.oneWeek);
    expect(await settings.cacheMaxBytes(), CacheLimitOption.values.first.bytes);

    await settings.setDownloadDirectoryPath('');
    expect(await settings.downloadDirectoryPath(), null);
  });

  test(
    'persists an explicit language and can return to system language',
    () async {
      final settings = AppSettingsService();

      expect(await settings.localeCode(), isNull);
      await settings.setLocaleCode('cs');
      expect(await settings.localeCode(), 'cs');

      await settings.setLocaleCode(null);
      expect(await settings.localeCode(), isNull);
    },
  );

  test(
    'migrates legacy biometric app-lock setting to biometric login',
    () async {
      SharedPreferences.setMockInitialValues({
        'settings.requireBiometricOnLaunch': true,
      });

      final settings = AppSettingsService();

      expect(await settings.biometricLoginEnabled(), true);

      await settings.setBiometricLoginEnabled(false);

      expect(await settings.biometricLoginEnabled(), false);
    },
  );
}
