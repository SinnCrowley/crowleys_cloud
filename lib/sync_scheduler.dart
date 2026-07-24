import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'dart:convert';

import 'package:crowleys_cloud/app_settings_service.dart';
import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:crowleys_cloud/server_store.dart';
import 'package:crowleys_cloud/sync_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'package:crowleys_cloud/notification_service.dart';

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
}

/// [Workmanager] implementation for Android background task scheduling with configuration hashing.
class WorkmanagerSyncBackgroundScheduler implements SyncBackgroundScheduler {
  WorkmanagerSyncBackgroundScheduler({Workmanager? workmanager})
    : _workmanager = workmanager ?? Workmanager();

  final Workmanager _workmanager;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized || !Platform.isAndroid) return;
    await _workmanager.initialize(syncCallbackDispatcher);
    _initialized = true;
  }

  @override
  Future<void> debugTriggerOneOffSync(String serverId) async {
    if (!Platform.isAndroid) return;
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
  }

  @override
  Future<void> scheduleForServers(
    List<ServerProfile> servers, {
    bool forceReRegister = false,
  }) async {
    if (!Platform.isAndroid) return;
    await initialize();
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
      } else {
        await _workmanager.cancelByUniqueName(uniqueName);
        await prefs.remove(prefKey);
      }
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

/// VM entry-point function for WorkManager background execution on Android.
@pragma('vm:entry-point')
void syncCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    if (taskName != syncBackgroundTaskName) return true;
    final serverId = inputData?['serverId'] as String?;
    final syncToken = inputData?['syncToken'] as String?;
    return runBackgroundSync(serverId: serverId, syncToken: syncToken);
  });
}

/// Executes background sync for active servers and updates system notifications.
Future<bool> runBackgroundSync({String? serverId, String? syncToken}) async {
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
    stateStore: const FileSyncStateStore(),
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
  });

  if (serverId != null && servers.isEmpty) {
    await Workmanager().cancelByUniqueName(
      '$syncBackgroundUniquePrefix$serverId',
    );
    return true;
  }
  for (final server in servers) {
    final notificationId = server.id.hashCode;
    final serverName = server.displayName;

    final result = await syncService.syncServer(
      server,
      onProgress: (message, progress) {
        int? intProgress;
        if (progress != null) {
          intProgress = (progress * 100).round();
        }
        unawaited(
          SyncNotificationService.instance.showProgressNotification(
            id: notificationId,
            title: 'Syncing with $serverName',
            body: message,
            progress: intProgress,
          ),
        );
      },
    );

    if (result.status == SyncRunStatus.serverUnreachable ||
        result.status == SyncRunStatus.authRequired) {
      final isUnreachable = result.status == SyncRunStatus.serverUnreachable;
      await SyncNotificationService.instance.showCompleteNotification(
        id: notificationId,
        title: 'Sync with $serverName paused',
        body: isUnreachable
            ? 'Server is unreachable. Background sync paused until app is opened.'
            : 'Authentication required. Open app to log in.',
        isError: true,
      );
      await Workmanager().cancelByUniqueName(
        '$syncBackgroundUniquePrefix${server.id}',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('sync_sched_config_${server.id}');
      return false;
    } else if (result.status == SyncRunStatus.failed ||
        result.status == SyncRunStatus.partialFailure) {
      await SyncNotificationService.instance.showCompleteNotification(
        id: notificationId,
        title: 'Sync with $serverName failed',
        body: result.message ?? 'An error occurred during synchronization.',
        isError: true,
      );
      if (result.status == SyncRunStatus.failed) return false;
    } else {
      await SyncNotificationService.instance.showCompleteNotification(
        id: notificationId,
        title: 'Sync with $serverName complete',
        body: 'Sync complete.',
        isError: false,
      );
    }
  }
  return true;
}
