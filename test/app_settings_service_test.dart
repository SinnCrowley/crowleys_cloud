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
