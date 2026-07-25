import 'dart:io';

import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/cache_service.dart';
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

    final store = await _store;
    final cached = store.getString('cached_default_backup_target_dir');
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    try {
      final name = Platform.localHostname;
      final result = '/backup/${_sanitizeDeviceName(name)}';
      await store.setString('cached_default_backup_target_dir', result);
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
    return safe.isEmpty ? 'device' : safe;
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
