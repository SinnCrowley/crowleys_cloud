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
import 'dart:async';
import 'dart:ui';
import 'dart:convert';

import 'package:crowleys_cloud/app_settings_service.dart';
import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_en.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:crowleys_cloud/server_store.dart';
import 'package:crowleys_cloud/storage/app_database.dart';
import 'package:crowleys_cloud/sync_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'package:crowleys_cloud/notification_service.dart';

AppLocalizations _resolveAppLocalizations() {
  try {
    final locale = PlatformDispatcher.instance.locale;
    return lookupAppLocalizations(locale);
  } catch (_) {
    return AppLocalizationsEn();
  }
}

const syncBackgroundTaskName = 'crowleys_cloud_background_sync';
const syncBackgroundUniquePrefix = 'crowleys_cloud_sync_';
const syncBackgroundTag = 'crowleys_cloud_sync';

/// Interface for background sync job scheduling.
abstract class SyncBackgroundScheduler {
  /// Initializes the background work manager subsystem.
  Future<void> initialize();

  /// Schedules periodic background sync tasks for the given server profiles based on user settings.
  Future<void> scheduleForServers(
    List<ServerProfile> servers, {
    bool forceReRegister = false,
  });

  /// Triggers a immediate one-off background sync execution for debugging.
  Future<void> debugTriggerOneOffSync(String serverId);

  /// Cancels background sync tasks for a specific server profile.
  Future<void> cancelForServer(String serverId);

  /// Cancels all scheduled background sync tasks.
  Future<void> cancelAll();
}

/// [Workmanager] implementation for background task scheduling with configuration hashing.
class WorkmanagerSyncBackgroundScheduler implements SyncBackgroundScheduler {
  WorkmanagerSyncBackgroundScheduler({
    Workmanager? workmanager,
    bool? isAndroid,
    bool? isIos,
  }) : _workmanager = workmanager ?? Workmanager(),
       _isAndroid = isAndroid,
       _isIos = isIos;

  final Workmanager _workmanager;
  final bool? _isAndroid;
  final bool? _isIos;
  bool _initialized = false;
  bool _isAvailable = false;

  bool get isAvailable => _isAvailable;

  bool get _effectiveIsAndroid => _isAndroid ?? Platform.isAndroid;
  bool get _effectiveIsIos => _isIos ?? Platform.isIOS;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    if (!_effectiveIsAndroid && !_effectiveIsIos) {
      _initialized = true;
      _isAvailable = false;
      return;
    }
    try {
      await _workmanager.initialize(syncCallbackDispatcher);
      _initialized = true;
      _isAvailable = true;
    } on PlatformException catch (e) {
      _initialized = true;
      _isAvailable = false;
      debugPrint(
        '[SyncScheduler] Workmanager initialize PlatformException: ${e.message}',
      );
    } catch (e) {
      _initialized = true;
      _isAvailable = false;
      debugPrint('[SyncScheduler] Workmanager initialize failed: $e');
    }
  }

  @override
  Future<void> debugTriggerOneOffSync(String serverId) async {
    if (!_effectiveIsAndroid && !_effectiveIsIos) return;
    try {
      await initialize();
      final secretStore = FlutterSecureSecretStore(
        storage: const FlutterSecureStorage(),
      );
      final syncToken = await secretStore.readSyncToken(serverId);
      await _workmanager.registerOneOffTask(
        '$syncBackgroundUniquePrefix${serverId}_debug_oneoff',
        syncBackgroundTaskName,
        inputData: {'serverId': serverId, 'syncToken': syncToken},
        constraints: Constraints(networkType: NetworkType.connected),
        tag: syncBackgroundTag,
      );
    } catch (e) {
      debugPrint('[SyncScheduler] debugTriggerOneOffSync failed: $e');
    }
  }

  @override
  Future<void> scheduleForServers(
    List<ServerProfile> servers, {
    bool forceReRegister = false,
  }) async {
    if (!_effectiveIsAndroid && !_effectiveIsIos) return;
    try {
      await initialize();
      if (!_isAvailable) return;
      if (_effectiveIsAndroid) {
        await _scheduleForServersAndroid(
          servers,
          forceReRegister: forceReRegister,
        );
      } else if (_effectiveIsIos) {
        await _scheduleForServersIos(servers, forceReRegister: forceReRegister);
      }
    } catch (e) {
      debugPrint('[SyncScheduler] scheduleForServers error: $e');
    }
  }

  Future<void> _scheduleForServersAndroid(
    List<ServerProfile> servers, {
    bool forceReRegister = false,
  }) async {
    final secretStore = FlutterSecureSecretStore(
      storage: const FlutterSecureStorage(),
    );
    final prefs = await SharedPreferences.getInstance();
    for (final server in servers) {
      final uniqueName = '$syncBackgroundUniquePrefix${server.id}';
      final prefKey = 'sync_sched_config_${server.id}';
      if (_syncEnabled(server)) {
        final frequencyMinutes =
            server.syncPrefs['syncFrequency'] as int? ?? 15;
        final syncToken = await secretStore.readSyncToken(server.id);
        final wifiOnly = _wifiOnly(server);
        final chargingOnly = _chargingOnly(server);

        final configMap = {
          'frequency': frequencyMinutes,
          'syncToken': syncToken,
          'wifiOnly': wifiOnly,
          'chargingOnly': chargingOnly,
          'syncCategories': server.syncPrefs['syncCategories'],
          'syncFolders': server.syncPrefs['syncFolders'],
        };
        final configJson = jsonEncode(configMap);
        final existingConfig = prefs.getString(prefKey);

        if (!forceReRegister && existingConfig == configJson) {
          // Task configuration hasn't changed. Skip re-registering to avoid resetting WorkManager timer.
          continue;
        }

        try {
          await _workmanager.registerPeriodicTask(
            uniqueName,
            syncBackgroundTaskName,
            frequency: Duration(minutes: frequencyMinutes),
            inputData: {'serverId': server.id, 'syncToken': syncToken},
            constraints: Constraints(
              networkType: wifiOnly
                  ? NetworkType.unmetered
                  : NetworkType.connected,
              requiresCharging: chargingOnly,
            ),
            existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
            tag: syncBackgroundTag,
          );

          await prefs.setString(prefKey, configJson);
        } catch (e) {
          debugPrint('[SyncScheduler] Android registerPeriodicTask error: $e');
        }
      } else {
        try {
          await _workmanager.cancelByUniqueName(uniqueName);
          await prefs.remove(prefKey);
        } catch (e) {
          debugPrint('[SyncScheduler] Android cancelByUniqueName error: $e');
        }
      }
    }
  }

  Future<void> _scheduleForServersIos(
    List<ServerProfile> servers, {
    bool forceReRegister = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    const prefKey = 'sync_sched_config_ios_aggregate';
    final enabledServers = servers.where(_syncEnabled).toList();

    if (enabledServers.isEmpty) {
      try {
        await _workmanager.cancelByUniqueName(syncBackgroundTaskName);
      } catch (e) {
        debugPrint('[SyncScheduler] iOS cancelByUniqueName error: $e');
      }
      await prefs.remove(prefKey);
      return;
    }

    final minFrequencyMinutes = enabledServers
        .map((s) => s.syncPrefs['syncFrequency'] as int? ?? 15)
        .reduce((a, b) => a < b ? a : b)
        .clamp(15, 10080);
    final allWifiOnly = enabledServers.every(_wifiOnly);
    final allChargingOnly = enabledServers.every(_chargingOnly);
    final enabledIds = enabledServers.map((s) => s.id).toList()..sort();

    final configMap = {
      'frequency': minFrequencyMinutes,
      'wifiOnly': allWifiOnly,
      'chargingOnly': allChargingOnly,
      'serverIds': enabledIds,
    };
    final configJson = jsonEncode(configMap);
    final existingConfig = prefs.getString(prefKey);

    if (!forceReRegister && existingConfig == configJson) {
      return;
    }

    try {
      await _workmanager.registerPeriodicTask(
        syncBackgroundTaskName,
        syncBackgroundTaskName,
        frequency: Duration(minutes: minFrequencyMinutes),
        initialDelay: Duration(minutes: minFrequencyMinutes),
        constraints: Constraints(
          networkType: allWifiOnly
              ? NetworkType.unmetered
              : NetworkType.connected,
          requiresCharging: allChargingOnly,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
      await prefs.setString(prefKey, configJson);
    } on PlatformException catch (e) {
      debugPrint(
        '[SyncScheduler] iOS registerPeriodicTask PlatformException: ${e.message}',
      );
    } catch (e) {
      debugPrint('[SyncScheduler] iOS registerPeriodicTask failed: $e');
    }
  }

  @override
  Future<void> cancelForServer(String serverId) async {
    if (!_effectiveIsAndroid && !_effectiveIsIos) return;
    try {
      if (_effectiveIsAndroid) {
        await _workmanager.cancelByUniqueName(
          '$syncBackgroundUniquePrefix$serverId',
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('sync_sched_config_$serverId');
      } else if (_effectiveIsIos) {
        final store = ServerStore();
        final snapshot = await store.load();
        final remaining = snapshot.servers
            .where((s) => s.id != serverId && _syncEnabled(s))
            .toList();
        await _scheduleForServersIos(remaining, forceReRegister: true);
      }
    } catch (e) {
      debugPrint('[SyncScheduler] cancelForServer failed: $e');
    }
  }

  @override
  Future<void> cancelAll() async {
    if (!_effectiveIsAndroid && !_effectiveIsIos) return;
    try {
      if (_effectiveIsAndroid) {
        await _workmanager.cancelAll();
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs
            .getKeys()
            .where((k) => k.startsWith('sync_sched_config_'))
            .toList();
        for (final key in keys) {
          await prefs.remove(key);
        }
      } else if (_effectiveIsIos) {
        await _workmanager.cancelByUniqueName(syncBackgroundTaskName);
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('sync_sched_config_ios_aggregate');
      }
    } catch (e) {
      debugPrint('[SyncScheduler] cancelAll failed: $e');
    }
  }

  bool _syncEnabled(ServerProfile server) {
    if (server.syncPrefs['syncEnabled'] != true) return false;
    final categories = server.syncPrefs['syncCategories'];
    final folders = server.syncPrefs['syncFolders'];
    final hasCategories =
        categories is List &&
        categories.any((e) => e.toString().trim().isNotEmpty);
    final hasFolders =
        folders is List && folders.any((e) => e.toString().trim().isNotEmpty);
    return hasCategories || hasFolders;
  }

  bool _wifiOnly(ServerProfile server) {
    final value = server.syncPrefs['backupWifiOnly'];
    return value is bool ? value : true;
  }

  bool _chargingOnly(ServerProfile server) {
    return server.syncPrefs['backupChargingOnly'] == true;
  }
}

/// VM entry-point function for WorkManager background execution.
@pragma('vm:entry-point')
void syncCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      DartPluginRegistrant.ensureInitialized();
      AppDatabase.ensurePlatformInitialized();
      final isSyncTask =
          taskName == syncBackgroundTaskName ||
          taskName == Workmanager.iOSBackgroundTask ||
          taskName == 'dev.fluttercommunity.workmanager.BackgroundFetch' ||
          taskName ==
              'dev.fluttercommunity.workmanager.BackgroundProcessingTask';
      if (!isSyncTask) return true;
      final serverId = inputData?['serverId'] as String?;
      final syncToken = inputData?['syncToken'] as String?;
      return await runBackgroundSync(serverId: serverId, syncToken: syncToken);
    } catch (e, stack) {
      debugPrint('[SyncDispatcher] Uncaught background error: $e\n$stack');
      return false;
    }
  });
}

/// Executes background sync for active servers and updates system notifications.
Future<bool> runBackgroundSync({
  String? serverId,
  String? syncToken,
  AppLocalizations? l10n,
  SyncStateStore? stateStore,
}) async {
  AppDatabase.ensurePlatformInitialized();
  final resolvedL10n = l10n ?? _resolveAppLocalizations();
  final store = ServerStore();
  final snapshot = await store.load();
  final settingsService = AppSettingsService();
  final baseSecretStore = FlutterSecureSecretStore(
    storage: const FlutterSecureStorage(),
    settingsService: settingsService,
  );
  final secretStore = OverrideSyncTokenSecretStore(
    delegate: baseSecretStore,
    overrideSyncToken: syncToken,
  );
  final authService = AuthService(secretStore: secretStore);
  final syncService = SyncService(
    scanner: DeviceSyncFileScanner(),
    apiClient: HttpSyncApiClient(authService: authService),
    stateStore: stateStore ?? const SqliteSyncStateStore(),
  );

  final servers = snapshot.servers.where((server) {
    if (server.syncPrefs['syncEnabled'] != true) return false;
    final categories = server.syncPrefs['syncCategories'];
    final folders = server.syncPrefs['syncFolders'];
    final hasCategories =
        categories is List &&
        categories.any((e) => e.toString().trim().isNotEmpty);
    final hasFolders =
        folders is List && folders.any((e) => e.toString().trim().isNotEmpty);
    if (!hasCategories && !hasFolders) return false;
    return serverId == null || server.id == serverId;
  }).toList();

  if (servers.isEmpty) {
    try {
      if (Platform.isAndroid && serverId != null) {
        await Workmanager().cancelByUniqueName(
          '$syncBackgroundUniquePrefix$serverId',
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('sync_sched_config_$serverId');
      } else if (Platform.isIOS) {
        await Workmanager().cancelByUniqueName(syncBackgroundTaskName);
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('sync_sched_config_ios_aggregate');
      }
    } catch (_) {}
    return true;
  }

  // iOS allocates ~30s for BGAppRefreshTask. Pass a safe 24-second deadline.
  final DateTime? deadline = Platform.isIOS
      ? DateTime.now().add(const Duration(seconds: 24))
      : null;

  var anySuccess = false;
  var anyFailure = false;

  for (final server in servers) {
    if (deadline != null && DateTime.now().isAfter(deadline)) break;

    final notificationId = server.id.hashCode;
    final serverName = server.displayName;

    final result = await syncService.syncServer(
      server,
      l10n: resolvedL10n,
      deadline: deadline,
      onProgress: (message, progress) {
        int? intProgress;
        if (progress != null) {
          intProgress = (progress * 100).round();
        }
        unawaited(
          SyncNotificationService.instance.showProgressNotification(
            id: notificationId,
            title: resolvedL10n.syncNotificationSyncingWith(serverName),
            body: message,
            progress: intProgress,
          ),
        );
      },
    );

    if (result.status == SyncRunStatus.serverUnreachable ||
        result.status == SyncRunStatus.authRequired) {
      anyFailure = true;
      final isUnreachable = result.status == SyncRunStatus.serverUnreachable;
      await SyncNotificationService.instance.showCompleteNotification(
        id: notificationId,
        title: resolvedL10n.syncNotificationPausedTitle(serverName),
        body: isUnreachable
            ? resolvedL10n.syncNotificationUnreachableBody
            : resolvedL10n.syncNotificationAuthRequiredBody,
        isError: true,
      );
      try {
        if (Platform.isAndroid) {
          await Workmanager().cancelByUniqueName(
            '$syncBackgroundUniquePrefix${server.id}',
          );
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('sync_sched_config_${server.id}');
          return false;
        } else if (Platform.isIOS) {
          final otherServers = servers.where((s) => s.id != server.id).toList();
          if (otherServers.isEmpty) {
            await Workmanager().cancelByUniqueName(syncBackgroundTaskName);
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('sync_sched_config_ios_aggregate');
            return false;
          }
        }
      } catch (_) {}
    } else if (result.status == SyncRunStatus.failed ||
        result.status == SyncRunStatus.partialFailure) {
      anyFailure = true;
      await SyncNotificationService.instance.showCompleteNotification(
        id: notificationId,
        title: resolvedL10n.syncNotificationFailedTitle(serverName),
        body: result.message ?? resolvedL10n.syncNotificationGenericErrorBody,
        isError: true,
      );
      if (Platform.isAndroid && result.status == SyncRunStatus.failed) {
        return false;
      }
    } else {
      anySuccess = true;
      await SyncNotificationService.instance.showCompleteNotification(
        id: notificationId,
        title: resolvedL10n.syncNotificationCompleteTitle(serverName),
        body: resolvedL10n.syncNotificationCompleteBody,
        isError: false,
      );
    }
  }

  if (Platform.isIOS) {
    return anySuccess || !anyFailure;
  }
  return true;
}
