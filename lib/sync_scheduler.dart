import 'dart:io';

import 'package:crowleys_cloud/app_settings_service.dart';
import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:crowleys_cloud/server_store.dart';
import 'package:crowleys_cloud/sync_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:workmanager/workmanager.dart';

const syncBackgroundTaskName = 'crowleys_cloud_background_sync';
const syncBackgroundUniquePrefix = 'crowleys_cloud_sync_';
const syncBackgroundTag = 'crowleys_cloud_sync';

abstract class SyncBackgroundScheduler {
  Future<void> initialize();

  Future<void> scheduleForServers(List<ServerProfile> servers);
}

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
  Future<void> scheduleForServers(List<ServerProfile> servers) async {
    if (!Platform.isAndroid) return;
    await initialize();
    await _workmanager.cancelByTag(syncBackgroundTag);
    for (final server in servers.where(_syncEnabled)) {
      await _workmanager.registerPeriodicTask(
        '$syncBackgroundUniquePrefix${server.id}',
        syncBackgroundTaskName,
        frequency: const Duration(minutes: 15),
        inputData: {'serverId': server.id},
        constraints: Constraints(
          networkType: _wifiOnly(server)
              ? NetworkType.unmetered
              : NetworkType.connected,
          requiresCharging: _chargingOnly(server),
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        tag: syncBackgroundTag,
      );
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

@pragma('vm:entry-point')
void syncCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (taskName != syncBackgroundTaskName) return true;
    final serverId = inputData?['serverId'] as String?;
    return runBackgroundSync(serverId: serverId);
  });
}

Future<bool> runBackgroundSync({String? serverId}) async {
  final store = ServerStore();
  final snapshot = await store.load();
  final settingsService = AppSettingsService();
  final authService = AuthService(
    secretStore: FlutterSecureSecretStore(
      storage: const FlutterSecureStorage(),
      settingsService: settingsService,
    ),
  );
  final syncService = SyncService(
    scanner: DeviceSyncFileScanner(),
    apiClient: HttpSyncApiClient(authService: authService),
    stateStore: FileSyncStateStore(),
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
  for (final server in servers) {
    final result = await syncService.syncServer(server);
    if (result.status == SyncRunStatus.failed) return false;
  }
  return true;
}
