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

import 'dart:io';

import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/cache_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  AppSettingsService({SharedPreferences? prefs}) : _prefs = prefs;

  static const showHiddenFilesKey = 'settings.showHiddenFiles';
  static const biometricLoginEnabledKey = 'settings.biometricLoginEnabled';
  static const _legacyRequireBiometricOnLaunchKey =
      'settings.requireBiometricOnLaunch';
  static const downloadDirectoryPathKey = 'settings.downloadDirectoryPath';
  static const tokenLifetimeKey = 'settings.tokenLifetime';
  static const localeKey = 'settings.locale';
  static const deviceNameKey = 'settings.deviceName';
  static const _cachedDefaultBackupTargetDirKey =
      'cached_default_backup_target_dir';

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
        true;
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

  Future<String?> localeCode() async {
    final code = (await _store).getString(localeKey);
    return code == null || code.isEmpty ? null : code;
  }

  Future<void> setLocaleCode(String? code) async {
    final prefs = await _store;
    if (code == null || code.isEmpty) {
      await prefs.remove(localeKey);
      return;
    }
    await prefs.setString(localeKey, code);
  }

  Future<String?> deviceName() async {
    final name = (await _store).getString(deviceNameKey);
    return name == null || name.trim().isEmpty ? null : name.trim();
  }

  Future<void> setDeviceName(String? name) async {
    final trimmed = name?.trim() ?? '';
    final prefs = await _store;
    if (trimmed.isEmpty) {
      await prefs.remove(deviceNameKey);
    } else {
      await prefs.setString(deviceNameKey, trimmed);
    }
    await prefs.remove(_cachedDefaultBackupTargetDirKey);
  }

  Future<String> getSystemDeviceName({
    DeviceInfoPlugin? deviceInfoPlugin,
  }) async {
    final customName = await deviceName();
    if (customName != null && customName.isNotEmpty) {
      return customName;
    }

    try {
      final deviceInfo = deviceInfoPlugin ?? DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        final name = androidInfo.name.trim();
        if (name.isNotEmpty &&
            name.toLowerCase() != 'localhost' &&
            name.toLowerCase() != 'null') {
          return name;
        }
        final model = androidInfo.model.trim();
        if (model.isNotEmpty &&
            model.toLowerCase() != 'localhost' &&
            model.toLowerCase() != 'null') {
          return model;
        }
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        final name = iosInfo.name.trim();
        if (name.isNotEmpty &&
            name.toLowerCase() != 'localhost' &&
            name.toLowerCase() != 'null') {
          return name;
        }
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        final compName = macInfo.computerName.trim();
        if (compName.isNotEmpty &&
            compName.toLowerCase() != 'localhost' &&
            compName.toLowerCase() != 'null') {
          return compName;
        }
      } else if (Platform.isWindows) {
        final winInfo = await deviceInfo.windowsInfo;
        final compName = winInfo.computerName.trim();
        if (compName.isNotEmpty &&
            compName.toLowerCase() != 'localhost' &&
            compName.toLowerCase() != 'null') {
          return compName;
        }
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        final pretty = linuxInfo.prettyName.trim();
        if (pretty.isNotEmpty &&
            pretty.toLowerCase() != 'localhost' &&
            pretty.toLowerCase() != 'null') {
          return pretty;
        }
        final name = linuxInfo.name.trim();
        if (name.isNotEmpty &&
            name.toLowerCase() != 'localhost' &&
            name.toLowerCase() != 'null') {
          return name;
        }
      }
    } catch (_) {}

    try {
      final host = Platform.localHostname.trim();
      if (host.isNotEmpty &&
          host.toLowerCase() != 'localhost' &&
          host.toLowerCase() != 'localhost.localdomain') {
        return host;
      }
    } catch (_) {}

    return 'device';
  }

  Future<int> cacheMaxBytes() async {
    return (await _store).getInt(CacheService.thumbnailMaxBytesKey) ??
        CacheService.defaultThumbnailMaxBytes;
  }

  Future<void> setCacheMaxBytes(int value) async {
    await (await _store).setInt(CacheService.thumbnailMaxBytesKey, value);
  }

  Future<String> defaultBackupTargetDirectory({
    DeviceInfoPlugin? deviceInfoPlugin,
  }) async {
    final store = await _store;
    final cached = store.getString(_cachedDefaultBackupTargetDirKey);
    if (cached != null &&
        cached.isNotEmpty &&
        cached != '/backup/localhost' &&
        cached != 'backup/localhost') {
      return cached;
    }

    if (Platform.environment.containsKey('FLUTTER_TEST') &&
        deviceInfoPlugin == null) {
      final customName = await deviceName();
      if (customName != null && customName.isNotEmpty) {
        return '/backup/${_sanitizeDeviceName(customName)}';
      }
      final sanitized = _sanitizeDeviceName(Platform.localHostname);
      final safeName = (sanitized.isEmpty || sanitized == 'localhost')
          ? 'device'
          : sanitized;
      return '/backup/$safeName';
    }

    try {
      final rawName = await getSystemDeviceName(
        deviceInfoPlugin: deviceInfoPlugin,
      );
      final sanitized = _sanitizeDeviceName(rawName);
      final safeName = (sanitized.isEmpty || sanitized == 'localhost')
          ? 'device'
          : sanitized;
      final result = '/backup/$safeName';
      await store.setString(_cachedDefaultBackupTargetDirKey, result);
      return result;
    } catch (_) {
      return '/backup/device';
    }
  }

  String _sanitizeDeviceName(String value) {
    final normalized = value.trim().toLowerCase();
    final safe = normalized
        .replaceAll(RegExp(r'[^a-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return (safe.isEmpty || safe == 'localhost') ? 'device' : safe;
  }

  Future<AppThemeData> loadTheme() async {
    final store = await _store;
    final modeStr = store.getString('settings.themeMode') ?? 'dark';
    final mode = AppThemeMode.values.firstWhere(
      (m) => m.name == modeStr,
      orElse: () => AppThemeMode.dark,
    );

    final font = store.getString('settings.themeFontFamily') ?? 'System';
    final scale = store.getDouble('settings.themeFontSizeScale') ?? 1.0;
    final customAccentInt = store.getInt('settings.themeCustomAccent');
    final customAccent = customAccentInt != null
        ? Color(customAccentInt)
        : null;

    if (mode == AppThemeMode.light) {
      return AppThemeData.light.copyWith(
        accent: customAccent ?? AppThemeData.light.accent,
        fontFamily: font,
        fontSizeScale: scale,
      );
    }

    if (mode == AppThemeMode.dark) {
      return AppThemeData.dark.copyWith(
        accent: customAccent ?? AppThemeData.dark.accent,
        fontFamily: font,
        fontSizeScale: scale,
      );
    }

    // Custom Mode
    final bg = store.getInt('settings.themeCustomBackground') ?? 0xFF1E1E1E;
    final surface = store.getInt('settings.themeCustomSurface') ?? 0xFF2C2C2C;
    final accent = store.getInt('settings.themeCustomAccent') ?? 0xFFFA5252;
    final text = store.getInt('settings.themeCustomText') ?? 0xFFFFFFFF;
    final subtext = store.getInt('settings.themeCustomSubtext') ?? 0xFFA0A0A0;
    final border = store.getInt('settings.themeCustomBorder') ?? 0xFF3D3D3D;

    return AppThemeData(
      mode: AppThemeMode.custom,
      background: Color(bg),
      surface: Color(surface),
      accent: Color(accent),
      text: Color(text),
      subtext: Color(subtext),
      border: Color(border),
      fontFamily: font,
      fontSizeScale: scale,
    );
  }

  Future<void> saveTheme(AppThemeData theme) async {
    final store = await _store;
    await store.setString('settings.themeMode', theme.mode.name);
    await store.setInt('settings.themeCustomAccent', theme.accent.toARGB32());
    await store.setString('settings.themeFontFamily', theme.fontFamily);
    await store.setDouble('settings.themeFontSizeScale', theme.fontSizeScale);

    if (theme.mode == AppThemeMode.custom) {
      await store.setInt(
        'settings.themeCustomBackground',
        theme.background.toARGB32(),
      );
      await store.setInt(
        'settings.themeCustomSurface',
        theme.surface.toARGB32(),
      );
      await store.setInt('settings.themeCustomText', theme.text.toARGB32());
      await store.setInt(
        'settings.themeCustomSubtext',
        theme.subtext.toARGB32(),
      );
      await store.setInt('settings.themeCustomBorder', theme.border.toARGB32());
    }
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
      orElse: () => oneMonth,
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
