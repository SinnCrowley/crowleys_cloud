import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:crowleys_cloud/cache_service.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  AppSettingsService({SharedPreferences? prefs}) : _prefs = prefs;

  static const showHiddenFilesKey = 'settings.showHiddenFiles';
  static const biometricLoginEnabledKey = 'settings.biometricLoginEnabled';
  static const _legacyRequireBiometricOnLaunchKey =
      'settings.requireBiometricOnLaunch';
  static const downloadDirectoryPathKey = 'settings.downloadDirectoryPath';
  static const tokenLifetimeKey = 'settings.tokenLifetime';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _store async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<bool> showHiddenFiles() async {
    return (await _store).getBool(showHiddenFilesKey) ?? false;
  }

  Future<void> setShowHiddenFiles(bool value) async {
    await (await _store).setBool(showHiddenFilesKey, value);
  }

  Future<bool> biometricLoginEnabled() async {
    final prefs = await _store;
    return prefs.getBool(biometricLoginEnabledKey) ??
        prefs.getBool(_legacyRequireBiometricOnLaunchKey) ??
        false;
  }

  Future<void> setBiometricLoginEnabled(bool value) async {
    final prefs = await _store;
    await prefs.setBool(biometricLoginEnabledKey, value);
    await prefs.remove(_legacyRequireBiometricOnLaunchKey);
  }

  Future<String?> downloadDirectoryPath() async {
    final path = (await _store).getString(downloadDirectoryPathKey);
    if (path == null || path.trim().isEmpty) return null;
    return path;
  }

  Future<void> setDownloadDirectoryPath(String? path) async {
    final trimmed = path?.trim() ?? '';
    final prefs = await _store;
    if (trimmed.isEmpty) {
      await prefs.remove(downloadDirectoryPathKey);
      return;
    }
    await prefs.setString(downloadDirectoryPathKey, trimmed);
  }

  Future<TokenLifetimeOption> tokenLifetime() async {
    final id = (await _store).getString(tokenLifetimeKey);
    return TokenLifetimeOption.byId(id);
  }

  Future<void> setTokenLifetime(TokenLifetimeOption value) async {
    await (await _store).setString(tokenLifetimeKey, value.id);
  }

  Future<int> cacheMaxBytes() async {
    return (await _store).getInt(CacheService.thumbnailMaxBytesKey) ??
        CacheService.defaultThumbnailMaxBytes;
  }

  Future<void> setCacheMaxBytes(int value) async {
    await (await _store).setInt(CacheService.thumbnailMaxBytesKey, value);
  }

  Future<String> defaultBackupTargetDirectory() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return '/backup/${_sanitizeDeviceName(Platform.localHostname)}';
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      String name = 'device';
      if (Platform.isAndroid) {
        String? customName;
        try {
          const platform = MethodChannel(
            'com.sinncrowley.crowleys_cloud/device_info',
          );
          customName = await platform.invokeMethod<String>('getDeviceName');
        } catch (_) {}
        if (customName != null && customName.trim().isNotEmpty) {
          name = customName;
        } else {
          final androidInfo = await deviceInfo.androidInfo;
          name = androidInfo.model;
        }
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        name = iosInfo.name;
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        name = macInfo.computerName;
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        name = windowsInfo.computerName;
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        name = linuxInfo.name;
      } else {
        name = Platform.localHostname;
      }
      final sanitized = _sanitizeDeviceName(name);
      return '/backup/$sanitized';
    } catch (_) {
      return '/backup/${_sanitizeDeviceName(Platform.localHostname)}';
    }
  }

  String _sanitizeDeviceName(String value) {
    final normalized = value.trim().toLowerCase();
    final safe = normalized
        .replaceAll(RegExp(r'[^a-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return safe.isEmpty ? 'device' : safe;
  }
}

class TokenLifetimeOption {
  const TokenLifetimeOption(this.id, this.label, this.duration);

  final String id;
  final String label;
  final Duration? duration;

  bool get expiresOnAppClose => duration == Duration.zero;
  bool get neverExpiresOnDevice => duration == null;

  static const everyOpen = TokenLifetimeOption(
    'everyOpen',
    'Every app open',
    Duration.zero,
  );
  static const oneHour = TokenLifetimeOption(
    'oneHour',
    'After 1 hour',
    Duration(hours: 1),
  );
  static const oneDay = TokenLifetimeOption(
    'oneDay',
    'After 1 day',
    Duration(days: 1),
  );
  static const oneWeek = TokenLifetimeOption(
    'oneWeek',
    'After 1 week',
    Duration(days: 7),
  );
  static const oneMonth = TokenLifetimeOption(
    'oneMonth',
    'After 1 month',
    Duration(days: 30),
  );
  static const threeMonths = TokenLifetimeOption(
    'threeMonths',
    'After 3 months',
    Duration(days: 90),
  );
  static const never = TokenLifetimeOption(
    'never',
    'Never on this device',
    null,
  );

  static const values = [
    everyOpen,
    oneHour,
    oneDay,
    oneWeek,
    oneMonth,
    threeMonths,
    never,
  ];

  static TokenLifetimeOption byId(String? id) {
    return values.firstWhere(
      (option) => option.id == id,
      orElse: () => everyOpen,
    );
  }
}

class CacheLimitOption {
  const CacheLimitOption(this.label, this.bytes);

  static const unlimitedBytes = -1;

  final String label;
  final int bytes;

  static const values = [
    CacheLimitOption('500 MB', 500 * 1024 * 1024),
    CacheLimitOption('1 GB', 1024 * 1024 * 1024),
    CacheLimitOption('5 GB', 5 * 1024 * 1024 * 1024),
    CacheLimitOption('Unlimited', unlimitedBytes),
  ];
}
