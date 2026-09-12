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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crowleys_cloud/server_profile.dart';
import 'package:crowleys_cloud/storage/app_database.dart';
import 'package:crowleys_cloud/sync_scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

/// Recorded call for periodic task registration.
class _RecordedPeriodicTask {
  _RecordedPeriodicTask({
    required this.uniqueName,
    required this.taskName,
    this.frequency,
    this.initialDelay,
    this.constraints,
    this.inputData,
    this.existingWorkPolicy,
    this.tag,
  });

  final String uniqueName;
  final String taskName;
  final Duration? frequency;
  final Duration? initialDelay;
  final Constraints? constraints;
  final Map<String, dynamic>? inputData;
  final ExistingPeriodicWorkPolicy? existingWorkPolicy;
  final String? tag;
}

/// Recorded call for one-off task registration.
class _RecordedOneOffTask {
  _RecordedOneOffTask({
    required this.uniqueName,
    required this.taskName,
    this.inputData,
    this.initialDelay,
    this.constraints,
    this.tag,
    this.existingWorkPolicy,
  });

  final String uniqueName;
  final String taskName;
  final Map<String, dynamic>? inputData;
  final Duration? initialDelay;
  final Constraints? constraints;
  final String? tag;
  final ExistingWorkPolicy? existingWorkPolicy;
}

/// Full mock implementation of [Workmanager] for unit testing.
class _MockWorkmanager implements Workmanager {
  int initializeCalls = 0;
  Function? lastCallbackDispatcher;
  bool shouldThrowOnInitialize = false;
  Exception? initializeException;

  final List<_RecordedPeriodicTask> registeredPeriodicTasks = [];
  bool shouldThrowOnRegisterPeriodic = false;
  Exception? registerPeriodicException;

  final List<_RecordedOneOffTask> registeredOneOffTasks = [];
  bool shouldThrowOnRegisterOneOff = false;
  Exception? registerOneOffException;

  final List<String> cancelledUniqueNames = [];
  bool shouldThrowOnCancelUniqueName = false;

  final List<String> cancelledTags = [];
  int cancelAllCalls = 0;

  @override
  Future<void> initialize(
    Function callbackDispatcher, {
    bool isInDebugMode = false,
  }) async {
    initializeCalls++;
    lastCallbackDispatcher = callbackDispatcher;
    if (shouldThrowOnInitialize) {
      if (initializeException != null) {
        throw initializeException!;
      }
      throw PlatformException(
        code: 'WM_INIT_FAILED',
        message: 'Workmanager initialization failed on host platform',
      );
    }
  }

  @override
  Future<void> registerPeriodicTask(
    String uniqueName,
    String taskName, {
    Duration? frequency,
    Duration? flexInterval,
    Map<String, dynamic>? inputData,
    Duration? initialDelay,
    Constraints? constraints,
    ExistingPeriodicWorkPolicy? existingWorkPolicy,
    BackoffPolicy? backoffPolicy,
    Duration? backoffPolicyDelay,
    String? tag,
    ForegroundServiceConfig? foregroundServiceConfig,
  }) async {
    if (shouldThrowOnRegisterPeriodic) {
      if (registerPeriodicException != null) {
        throw registerPeriodicException!;
      }
      throw PlatformException(
        code: 'WM_REGISTER_FAILED',
        message: 'Registration rejected by platform',
      );
    }
    registeredPeriodicTasks.add(
      _RecordedPeriodicTask(
        uniqueName: uniqueName,
        taskName: taskName,
        frequency: frequency,
        initialDelay: initialDelay,
        constraints: constraints,
        inputData: inputData,
        existingWorkPolicy: existingWorkPolicy,
        tag: tag,
      ),
    );
  }

  @override
  Future<void> registerOneOffTask(
    String uniqueName,
    String taskName, {
    Map<String, dynamic>? inputData,
    Duration? initialDelay,
    Constraints? constraints,
    ExistingWorkPolicy? existingWorkPolicy,
    BackoffPolicy? backoffPolicy,
    Duration? backoffPolicyDelay,
    String? tag,
    OutOfQuotaPolicy? outOfQuotaPolicy,
    ForegroundServiceConfig? foregroundServiceConfig,
    bool expedited = false,
  }) async {
    if (shouldThrowOnRegisterOneOff) {
      if (registerOneOffException != null) {
        throw registerOneOffException!;
      }
      throw PlatformException(
        code: 'WM_REGISTER_ONEOFF_FAILED',
        message: 'One-off registration rejected by platform',
      );
    }
    registeredOneOffTasks.add(
      _RecordedOneOffTask(
        uniqueName: uniqueName,
        taskName: taskName,
        inputData: inputData,
        initialDelay: initialDelay,
        constraints: constraints,
        tag: tag,
        existingWorkPolicy: existingWorkPolicy,
      ),
    );
  }

  @override
  Future<void> cancelByUniqueName(String uniqueName) async {
    if (shouldThrowOnCancelUniqueName) {
      throw PlatformException(
        code: 'WM_CANCEL_FAILED',
        message: 'Cancel by unique name failed',
      );
    }
    cancelledUniqueNames.add(uniqueName);
  }

  @override
  Future<void> cancelByTag(String tag) async {
    cancelledTags.add(tag);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
  }

  @override
  void executeTask(
    BackgroundTaskHandler backgroundTaskHandler, {
    BackgroundTaskStoppedHandler? onTaskStopped,
  }) {}

  @override
  Future<String> printScheduledTasks() async => '';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ServerProfile _buildTestServer({
  required String id,
  String displayName = 'Test Server',
  String baseUrl = 'http://127.0.0.1:8080',
  bool syncEnabled = true,
  int syncFrequency = 15,
  bool backupWifiOnly = true,
  bool backupChargingOnly = false,
  List<String>? syncCategories,
  List<String>? syncFolders,
}) {
  return ServerProfile(
    id: id,
    displayName: displayName,
    baseUrl: baseUrl,
    authMode: 'token',
    lastUsedAt: DateTime.utc(2026, 1, 1),
    syncPrefs: {
      'syncEnabled': syncEnabled,
      'syncFrequency': syncFrequency,
      'backupWifiOnly': backupWifiOnly,
      'backupChargingOnly': backupChargingOnly,
      'syncCategories': ?syncCategories,
      'syncFolders': ?syncFolders,
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppDatabase.ensurePlatformInitialized();

  late Directory tempDir;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    tempDir = Directory.systemTemp.createTempSync('sync_scheduler_test_');

    // Mock path_provider
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (MethodCall methodCall) async {
          if (methodCall.method == 'getApplicationDocumentsDirectory') {
            return tempDir.path;
          }
          return null;
        });

    // Mock local_notifications
    const notifChannel = MethodChannel(
      'dexterous.com/flutter/local_notifications',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notifChannel, (MethodCall methodCall) async {
          return true;
        });

    // Mock workmanager channel
    const wmChannel = MethodChannel('be.tramckas.workmanager');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(wmChannel, (MethodCall methodCall) async {
          return true;
        });
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('Group 1: Subsystem Initialization & Graceful Degradation', () {
    test(
      '1.1 Android initialize() invokes Workmanager.initialize with syncCallbackDispatcher',
      () async {
        final mockWm = _MockWorkmanager();
        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: true,
          isIos: false,
        );

        await scheduler.initialize();

        expect(mockWm.initializeCalls, 1);
        expect(mockWm.lastCallbackDispatcher, equals(syncCallbackDispatcher));
        expect(scheduler.isAvailable, isTrue);
      },
    );

    test(
      '1.2 iOS initialize() invokes Workmanager.initialize with syncCallbackDispatcher',
      () async {
        final mockWm = _MockWorkmanager();
        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: false,
          isIos: true,
        );

        await scheduler.initialize();

        expect(mockWm.initializeCalls, 1);
        expect(mockWm.lastCallbackDispatcher, equals(syncCallbackDispatcher));
        expect(scheduler.isAvailable, isTrue);
      },
    );

    test(
      '1.3 initialize() is idempotent and avoids redundant Workmanager.initialize invocations',
      () async {
        final mockWm = _MockWorkmanager();
        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: false,
          isIos: true,
        );

        await scheduler.initialize();
        await scheduler.initialize();
        await scheduler.initialize();

        expect(mockWm.initializeCalls, 1);
        expect(scheduler.isAvailable, isTrue);
      },
    );

    test(
      '1.4 initialize() gracefully degrades on PlatformException without rethrowing',
      () async {
        final mockWm = _MockWorkmanager()
          ..shouldThrowOnInitialize = true
          ..initializeException = PlatformException(
            code: 'SIMULATOR_UNSUPPORTED',
            message: 'BGTaskScheduler is not supported in iOS Simulator',
          );
        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: false,
          isIos: true,
        );

        await expectLater(scheduler.initialize(), completes);
        expect(scheduler.isAvailable, isFalse);
      },
    );

    test(
      '1.5 initialize() gracefully degrades on generic Exception without rethrowing',
      () async {
        final mockWm = _MockWorkmanager()
          ..shouldThrowOnInitialize = true
          ..initializeException = Exception('Workmanager fatal native error');
        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: true,
          isIos: false,
        );

        await expectLater(scheduler.initialize(), completes);
        expect(scheduler.isAvailable, isFalse);
      },
    );

    test(
      '1.6 Desktop platform completely bypasses Workmanager.initialize and marks isAvailable = false',
      () async {
        final mockWm = _MockWorkmanager();
        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: false,
          isIos: false,
        );

        await scheduler.initialize();

        expect(mockWm.initializeCalls, 0);
        expect(scheduler.isAvailable, isFalse);
      },
    );

    test(
      '1.7 Default WorkmanagerSyncBackgroundScheduler() without overrides resolves safely on host',
      () async {
        final scheduler = WorkmanagerSyncBackgroundScheduler();
        await expectLater(scheduler.initialize(), completes);
        // On host Linux test runner, Platform.isAndroid and Platform.isIOS are false
        expect(scheduler.isAvailable, isFalse);
      },
    );

    test(
      '1.8 scheduleForServers exits immediately without registering when isAvailable is false',
      () async {
        final mockWm = _MockWorkmanager()..shouldThrowOnInitialize = true;
        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: false,
          isIos: true,
        );

        final server = _buildTestServer(
          id: 'srv_1',
          syncCategories: ['photos'],
        );

        await scheduler.scheduleForServers([server]);

        expect(scheduler.isAvailable, isFalse);
        expect(mockWm.registeredPeriodicTasks, isEmpty);
      },
    );
  });

  group('Group 2: iOS Periodic Scheduling (scheduleForServers)', () {
    test(
      '2.1 Registers single static periodic task with uniqueName matching Info.plist and no tag',
      () async {
        final mockWm = _MockWorkmanager();
        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: false,
          isIos: true,
        );

        final server = _buildTestServer(
          id: 'srv_ios',
          syncFrequency: 30,
          syncCategories: ['photos'],
        );

        await scheduler.scheduleForServers([server]);

        expect(mockWm.registeredPeriodicTasks.length, 1);
        final task = mockWm.registeredPeriodicTasks.single;
        expect(task.uniqueName, 'crowleys_cloud_background_sync');
        expect(task.taskName, 'crowleys_cloud_background_sync');
        expect(task.tag, isNull);
        expect(task.frequency, const Duration(minutes: 30));
        expect(task.initialDelay, const Duration(minutes: 30));
        expect(task.existingWorkPolicy, ExistingPeriodicWorkPolicy.update);
      },
    );

    test('2.2 Aggregates minimum frequency across enabled servers', () async {
      final mockWm = _MockWorkmanager();
      final scheduler = WorkmanagerSyncBackgroundScheduler(
        workmanager: mockWm,
        isAndroid: false,
        isIos: true,
      );

      final server1 = _buildTestServer(
        id: 'srv_1',
        syncFrequency: 60,
        syncCategories: ['photos'],
      );
      final server2 = _buildTestServer(
        id: 'srv_2',
        syncFrequency: 25,
        syncFolders: ['/documents'],
      );
      final server3 = _buildTestServer(
        id: 'srv_3',
        syncFrequency: 120,
        syncCategories: ['audio'],
      );

      await scheduler.scheduleForServers([server1, server2, server3]);

      expect(mockWm.registeredPeriodicTasks.length, 1);
      final task = mockWm.registeredPeriodicTasks.single;
      expect(task.frequency, const Duration(minutes: 25));
      expect(task.initialDelay, const Duration(minutes: 25));
    });

    test(
      '2.3 Frequency clamping: clamps < 15 to 15, and > 10080 to 10080 minutes',
      () async {
        final mockWm = _MockWorkmanager();
        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: false,
          isIos: true,
        );

        // Sub-15 minutes clamped up to 15
        final serverLow = _buildTestServer(
          id: 'srv_low',
          syncFrequency: 5,
          syncCategories: ['photos'],
        );
        await scheduler.scheduleForServers([serverLow], forceReRegister: true);
        expect(
          mockWm.registeredPeriodicTasks.last.frequency,
          const Duration(minutes: 15),
        );

        // Above 10080 minutes (7 days) clamped down to 10080
        final serverHigh = _buildTestServer(
          id: 'srv_high',
          syncFrequency: 25000,
          syncCategories: ['photos'],
        );
        await scheduler.scheduleForServers([serverHigh], forceReRegister: true);
        expect(
          mockWm.registeredPeriodicTasks.last.frequency,
          const Duration(minutes: 10080),
        );
      },
    );

    test(
      '2.4 Network constraints: unmetered only if ALL servers require Wi-Fi',
      () async {
        final mockWm = _MockWorkmanager();
        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: false,
          isIos: true,
        );

        final srvWifi1 = _buildTestServer(
          id: 's1',
          backupWifiOnly: true,
          syncCategories: ['photos'],
        );
        final srvWifi2 = _buildTestServer(
          id: 's2',
          backupWifiOnly: true,
          syncCategories: ['documents'],
        );

        // Both require Wi-Fi -> unmetered
        await scheduler.scheduleForServers([
          srvWifi1,
          srvWifi2,
        ], forceReRegister: true);
        var constraints = mockWm.registeredPeriodicTasks.last.constraints;
        expect(constraints?.networkType, NetworkType.unmetered);

        // One allows cellular -> connected
        final srvCellular = _buildTestServer(
          id: 's3',
          backupWifiOnly: false,
          syncCategories: ['audio'],
        );
        await scheduler.scheduleForServers([
          srvWifi1,
          srvCellular,
        ], forceReRegister: true);
        constraints = mockWm.registeredPeriodicTasks.last.constraints;
        expect(constraints?.networkType, NetworkType.connected);
      },
    );

    test(
      '2.5 Charging constraints: requiresCharging is true only if ALL servers require charging',
      () async {
        final mockWm = _MockWorkmanager();
        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: false,
          isIos: true,
        );

        final srvCharge1 = _buildTestServer(
          id: 's1',
          backupChargingOnly: true,
          syncCategories: ['photos'],
        );
        final srvCharge2 = _buildTestServer(
          id: 's2',
          backupChargingOnly: true,
          syncCategories: ['documents'],
        );

        // Both require charging -> requiresCharging true
        await scheduler.scheduleForServers([
          srvCharge1,
          srvCharge2,
        ], forceReRegister: true);
        var constraints = mockWm.registeredPeriodicTasks.last.constraints;
        expect(constraints?.requiresCharging, isTrue);

        // One does not require charging -> requiresCharging false
        final srvNoCharge = _buildTestServer(
          id: 's3',
          backupChargingOnly: false,
          syncCategories: ['audio'],
        );
        await scheduler.scheduleForServers([
          srvCharge1,
          srvNoCharge,
        ], forceReRegister: true);
        constraints = mockWm.registeredPeriodicTasks.last.constraints;
        expect(constraints?.requiresCharging, isFalse);
      },
    );

    test(
      '2.6 Idempotency: unchanged aggregate config skips re-registration; forceReRegister forces it',
      () async {
        final mockWm = _MockWorkmanager();
        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: false,
          isIos: true,
        );

        final server = _buildTestServer(
          id: 'srv_1',
          syncFrequency: 45,
          syncCategories: ['photos'],
        );

        // Initial registration
        await scheduler.scheduleForServers([server]);
        expect(mockWm.registeredPeriodicTasks.length, 1);

        // Repeated registration with identical configuration is skipped
        await scheduler.scheduleForServers([server]);
        expect(mockWm.registeredPeriodicTasks.length, 1);

        // forceReRegister: true forces re-registration
        await scheduler.scheduleForServers([server], forceReRegister: true);
        expect(mockWm.registeredPeriodicTasks.length, 2);

        // Modified frequency triggers re-registration
        final serverModified = _buildTestServer(
          id: 'srv_1',
          syncFrequency: 60,
          syncCategories: ['photos'],
        );
        await scheduler.scheduleForServers([serverModified]);
        expect(mockWm.registeredPeriodicTasks.length, 3);
      },
    );

    test(
      '2.7 Cancels crowleys_cloud_background_sync when 0 servers enabled or target paths empty',
      () async {
        final mockWm = _MockWorkmanager();
        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: false,
          isIos: true,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'sync_sched_config_ios_aggregate',
          '{"existing":"config"}',
        );

        // Scenario A: empty server list
        await scheduler.scheduleForServers([]);
        expect(
          mockWm.cancelledUniqueNames,
          contains('crowleys_cloud_background_sync'),
        );
        expect(prefs.containsKey('sync_sched_config_ios_aggregate'), isFalse);

        // Scenario B: server with syncEnabled: false
        mockWm.cancelledUniqueNames.clear();
        final disabledServer = _buildTestServer(
          id: 'srv_dis',
          syncEnabled: false,
          syncCategories: ['photos'],
        );
        await scheduler.scheduleForServers([disabledServer]);
        expect(
          mockWm.cancelledUniqueNames,
          contains('crowleys_cloud_background_sync'),
        );

        // Scenario C: server with syncEnabled: true but empty categories and folders
        mockWm.cancelledUniqueNames.clear();
        final emptyTargetsServer = _buildTestServer(
          id: 'srv_empty',
          syncEnabled: true,
          syncCategories: [],
          syncFolders: [],
        );
        await scheduler.scheduleForServers([emptyTargetsServer]);
        expect(
          mockWm.cancelledUniqueNames,
          contains('crowleys_cloud_background_sync'),
        );
      },
    );

    test(
      '2.8 Catches PlatformException and generic Exception on registerPeriodicTask gracefully',
      () async {
        final mockWm = _MockWorkmanager()
          ..shouldThrowOnRegisterPeriodic = true
          ..registerPeriodicException = PlatformException(
            code: 'IOS_TASK_LIMIT',
            message: 'Too many BGTasks registered',
          );

        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: false,
          isIos: true,
        );

        final server = _buildTestServer(
          id: 'srv_1',
          syncCategories: ['photos'],
        );

        // Must not throw uncaught error
        await expectLater(scheduler.scheduleForServers([server]), completes);
      },
    );
  });

  group('Group 3: Android Periodic Scheduling (scheduleForServers)', () {
    test(
      '3.1 Registers dynamic per-server periodic tasks with crowleys_cloud_sync_<id>',
      () async {
        final mockWm = _MockWorkmanager();
        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: true,
          isIos: false,
        );

        FlutterSecureStorage.setMockInitialValues({
          'server_sync_token_alpha': 'token_alpha_123',
          'server_sync_token_beta': 'token_beta_456',
        });

        final serverA = _buildTestServer(
          id: 'alpha',
          syncFrequency: 20,
          syncCategories: ['photos'],
          backupWifiOnly: true,
          backupChargingOnly: false,
        );

        final serverB = _buildTestServer(
          id: 'beta',
          syncFrequency: 45,
          syncFolders: ['/sync/docs'],
          backupWifiOnly: false,
          backupChargingOnly: true,
        );

        await scheduler.scheduleForServers([serverA, serverB]);

        expect(mockWm.registeredPeriodicTasks.length, 2);

        final taskA = mockWm.registeredPeriodicTasks.firstWhere(
          (t) => t.uniqueName == 'crowleys_cloud_sync_alpha',
        );
        expect(taskA.taskName, 'crowleys_cloud_background_sync');
        expect(taskA.tag, 'crowleys_cloud_sync');
        expect(taskA.frequency, const Duration(minutes: 20));
        expect(taskA.constraints?.networkType, NetworkType.unmetered);
        expect(taskA.constraints?.requiresCharging, isFalse);
        expect(taskA.inputData, {
          'serverId': 'alpha',
          'syncToken': 'token_alpha_123',
        });

        final taskB = mockWm.registeredPeriodicTasks.firstWhere(
          (t) => t.uniqueName == 'crowleys_cloud_sync_beta',
        );
        expect(taskB.taskName, 'crowleys_cloud_background_sync');
        expect(taskB.tag, 'crowleys_cloud_sync');
        expect(taskB.frequency, const Duration(minutes: 45));
        expect(taskB.constraints?.networkType, NetworkType.connected);
        expect(taskB.constraints?.requiresCharging, isTrue);
        expect(taskB.inputData, {
          'serverId': 'beta',
          'syncToken': 'token_beta_456',
        });
      },
    );

    test(
      '3.2 Android task idempotency skips unchanged tasks and forceReRegister updates them',
      () async {
        final mockWm = _MockWorkmanager();
        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: true,
          isIos: false,
        );

        final server = _buildTestServer(
          id: 'alpha',
          syncCategories: ['photos'],
        );

        // First call registers
        await scheduler.scheduleForServers([server]);
        expect(mockWm.registeredPeriodicTasks.length, 1);

        // Second identical call is skipped
        await scheduler.scheduleForServers([server]);
        expect(mockWm.registeredPeriodicTasks.length, 1);

        // forceReRegister: true re-registers
        await scheduler.scheduleForServers([server], forceReRegister: true);
        expect(mockWm.registeredPeriodicTasks.length, 2);
      },
    );

    test(
      '3.3 Cancels Android task and removes pref when a server is disabled',
      () async {
        final mockWm = _MockWorkmanager();
        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: true,
          isIos: false,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sync_sched_config_alpha', '{"existing":"cfg"}');

        final disabledServer = _buildTestServer(
          id: 'alpha',
          syncEnabled: false,
          syncCategories: ['photos'],
        );

        await scheduler.scheduleForServers([disabledServer]);

        expect(
          mockWm.cancelledUniqueNames,
          contains('crowleys_cloud_sync_alpha'),
        );
        expect(prefs.containsKey('sync_sched_config_alpha'), isFalse);
      },
    );

    test(
      '3.4 Catches exceptions during Android registration and cancellation safely',
      () async {
        final mockWm = _MockWorkmanager()
          ..shouldThrowOnRegisterPeriodic = true
          ..shouldThrowOnCancelUniqueName = true;

        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: true,
          isIos: false,
        );

        final server = _buildTestServer(
          id: 'alpha',
          syncCategories: ['photos'],
        );
        final disabledServer = _buildTestServer(
          id: 'beta',
          syncEnabled: false,
          syncCategories: ['photos'],
        );

        await expectLater(
          scheduler.scheduleForServers([server, disabledServer]),
          completes,
        );
      },
    );
  });

  group('Group 4: Per-Server Cancellation (cancelForServer)', () {
    test(
      '4.1 Android cancelForServer cancels specific dynamic uniqueName and removes pref',
      () async {
        final mockWm = _MockWorkmanager();
        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: true,
          isIos: false,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sync_sched_config_srv_target', '{"data":1}');
        await prefs.setString('sync_sched_config_srv_other', '{"data":2}');

        await scheduler.cancelForServer('srv_target');

        expect(
          mockWm.cancelledUniqueNames,
          contains('crowleys_cloud_sync_srv_target'),
        );
        expect(
          mockWm.cancelledUniqueNames,
          isNot(contains('crowleys_cloud_sync_srv_other')),
        );
        expect(prefs.containsKey('sync_sched_config_srv_target'), isFalse);
        expect(prefs.containsKey('sync_sched_config_srv_other'), isTrue);
      },
    );

    test(
      '4.2 iOS cancelForServer recalculates aggregate schedule for remaining enabled servers in ServerStore',
      () async {
        final mockWm = _MockWorkmanager();
        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: false,
          isIos: true,
        );

        // Seed servers.json with two enabled servers
        final serversFile = File('${tempDir.path}/servers.json');
        final payload = {
          'activeServerId': 'srv_1',
          'servers': [
            {
              'id': 'srv_1',
              'displayName': 'Server 1',
              'baseUrl': 'http://srv1.local',
              'authMode': 'token',
              'lastUsedAt': '2026-01-01T00:00:00.000Z',
              'syncPrefs': {
                'syncEnabled': true,
                'syncFrequency': 20,
                'backupWifiOnly': true,
                'syncCategories': ['photos'],
              },
            },
            {
              'id': 'srv_2',
              'displayName': 'Server 2',
              'baseUrl': 'http://srv2.local',
              'authMode': 'token',
              'lastUsedAt': '2026-01-01T00:00:00.000Z',
              'syncPrefs': {
                'syncEnabled': true,
                'syncFrequency': 45,
                'backupWifiOnly': false,
                'syncFolders': ['/docs'],
              },
            },
          ],
        };
        await serversFile.writeAsString(jsonEncode(payload));

        // Cancel srv_1 -> should reschedule for srv_2 with frequency 45 and connected network
        await scheduler.cancelForServer('srv_1');

        expect(mockWm.registeredPeriodicTasks.length, 1);
        final task = mockWm.registeredPeriodicTasks.single;
        expect(task.uniqueName, 'crowleys_cloud_background_sync');
        expect(task.frequency, const Duration(minutes: 45));
        expect(task.constraints?.networkType, NetworkType.connected);
      },
    );

    test(
      '4.3 iOS cancelForServer cancels aggregate task when no remaining enabled servers exist',
      () async {
        final mockWm = _MockWorkmanager();
        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: false,
          isIos: true,
        );

        // Seed servers.json with only srv_1
        final serversFile = File('${tempDir.path}/servers.json');
        final payload = {
          'activeServerId': 'srv_1',
          'servers': [
            {
              'id': 'srv_1',
              'displayName': 'Server 1',
              'baseUrl': 'http://srv1.local',
              'authMode': 'token',
              'lastUsedAt': '2026-01-01T00:00:00.000Z',
              'syncPrefs': {
                'syncEnabled': true,
                'syncCategories': ['photos'],
              },
            },
          ],
        };
        await serversFile.writeAsString(jsonEncode(payload));

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sync_sched_config_ios_aggregate', '{"agg":"1"}');

        await scheduler.cancelForServer('srv_1');

        expect(
          mockWm.cancelledUniqueNames,
          contains('crowleys_cloud_background_sync'),
        );
        expect(prefs.containsKey('sync_sched_config_ios_aggregate'), isFalse);
      },
    );

    test(
      '4.4 Desktop cancelForServer is safe no-op without invoking Workmanager',
      () async {
        final mockWm = _MockWorkmanager();
        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: false,
          isIos: false,
        );

        await scheduler.cancelForServer('srv_1');

        expect(mockWm.cancelledUniqueNames, isEmpty);
        expect(mockWm.registeredPeriodicTasks, isEmpty);
      },
    );
  });

  group('Group 5: Global Cancellation (cancelAll)', () {
    test(
      '5.1 Android cancelAll calls Workmanager.cancelAll and clears all sync_sched_config_* keys',
      () async {
        final mockWm = _MockWorkmanager();
        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: true,
          isIos: false,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sync_sched_config_alpha', '{"a":1}');
        await prefs.setString('sync_sched_config_beta', '{"b":2}');
        await prefs.setString('other_unrelated_key', 'stay');

        await scheduler.cancelAll();

        expect(mockWm.cancelAllCalls, 1);
        expect(prefs.containsKey('sync_sched_config_alpha'), isFalse);
        expect(prefs.containsKey('sync_sched_config_beta'), isFalse);
        expect(prefs.containsKey('other_unrelated_key'), isTrue);
      },
    );

    test(
      '5.2 iOS cancelAll cancels static task crowleys_cloud_background_sync and removes aggregate pref',
      () async {
        final mockWm = _MockWorkmanager();
        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: false,
          isIos: true,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sync_sched_config_ios_aggregate', '{"agg":1}');

        await scheduler.cancelAll();

        expect(
          mockWm.cancelledUniqueNames,
          contains('crowleys_cloud_background_sync'),
        );
        expect(mockWm.cancelAllCalls, 0); // Must NOT call cancelAll()
        expect(mockWm.cancelledTags, isEmpty); // Must NEVER call cancelByTag()
        expect(prefs.containsKey('sync_sched_config_ios_aggregate'), isFalse);
      },
    );

    test('5.3 Desktop cancelAll is safe no-op', () async {
      final mockWm = _MockWorkmanager();
      final scheduler = WorkmanagerSyncBackgroundScheduler(
        workmanager: mockWm,
        isAndroid: false,
        isIos: false,
      );

      await scheduler.cancelAll();

      expect(mockWm.cancelAllCalls, 0);
      expect(mockWm.cancelledUniqueNames, isEmpty);
    });
  });

  group('Group 6: One-Off Debug Sync (debugTriggerOneOffSync)', () {
    test(
      '6.1 Android debugTriggerOneOffSync registers one-off task with token and connected network',
      () async {
        final mockWm = _MockWorkmanager();
        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: true,
          isIos: false,
        );

        FlutterSecureStorage.setMockInitialValues({
          'server_sync_token_debug_srv': 'token_xyz_789',
        });

        await scheduler.debugTriggerOneOffSync('debug_srv');

        expect(mockWm.registeredOneOffTasks.length, 1);
        final task = mockWm.registeredOneOffTasks.single;
        expect(task.uniqueName, 'crowleys_cloud_sync_debug_srv_debug_oneoff');
        expect(task.taskName, 'crowleys_cloud_background_sync');
        expect(task.tag, 'crowleys_cloud_sync');
        expect(task.constraints?.networkType, NetworkType.connected);
        expect(task.inputData, {
          'serverId': 'debug_srv',
          'syncToken': 'token_xyz_789',
        });
      },
    );

    test(
      '6.2 iOS debugTriggerOneOffSync registers one-off task with token and connected network',
      () async {
        final mockWm = _MockWorkmanager();
        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: false,
          isIos: true,
        );

        FlutterSecureStorage.setMockInitialValues({
          'server_sync_token_ios_dbg': 'token_ios_999',
        });

        await scheduler.debugTriggerOneOffSync('ios_dbg');

        expect(mockWm.registeredOneOffTasks.length, 1);
        final task = mockWm.registeredOneOffTasks.single;
        expect(task.uniqueName, 'crowleys_cloud_sync_ios_dbg_debug_oneoff');
        expect(task.taskName, 'crowleys_cloud_background_sync');
        expect(task.constraints?.networkType, NetworkType.connected);
        expect(task.inputData, {
          'serverId': 'ios_dbg',
          'syncToken': 'token_ios_999',
        });
      },
    );

    test(
      '6.3 Desktop debugTriggerOneOffSync safely exits without registering',
      () async {
        final mockWm = _MockWorkmanager();
        final scheduler = WorkmanagerSyncBackgroundScheduler(
          workmanager: mockWm,
          isAndroid: false,
          isIos: false,
        );

        await scheduler.debugTriggerOneOffSync('desk_srv');

        expect(mockWm.registeredOneOffTasks, isEmpty);
      },
    );

    test('6.4 Catches error gracefully if registerOneOffTask throws', () async {
      final mockWm = _MockWorkmanager()..shouldThrowOnRegisterOneOff = true;
      final scheduler = WorkmanagerSyncBackgroundScheduler(
        workmanager: mockWm,
        isAndroid: true,
        isIos: false,
      );

      await expectLater(
        scheduler.debugTriggerOneOffSync('srv_fail'),
        completes,
      );
    });
  });

  group('Group 7: VM Callback Dispatcher & Background Task Recognition', () {
    setUpAll(() {
      syncCallbackDispatcher();
    });

    Future<bool?> triggerExecuteTask(
      String taskName, {
      Map<String, dynamic>? inputData,
    }) async {
      const codec = WorkmanagerFlutterApi.pigeonChannelCodec;
      final encoded = codec.encodeMessage([taskName, inputData]);
      final completer = Completer<ByteData?>();
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            'dev.flutter.pigeon.workmanager_platform_interface.WorkmanagerFlutterApi.executeTask',
            encoded,
            (ByteData? data) {
              completer.complete(data);
            },
          );
      final responseBytes = await completer.future;
      if (responseBytes == null) return null;
      final result = codec.decodeMessage(responseBytes) as List<Object?>?;
      if (result == null || result.isEmpty) return null;
      return result[0] as bool?;
    }

    test(
      '7.1 Unrecognized task name returns true immediately without triggering sync',
      () async {
        final result = await triggerExecuteTask('unrecognized_task_xyz');
        expect(result, isTrue);
      },
    );

    test(
      '7.2 Task name recognition: crowleys_cloud_background_sync is recognized',
      () async {
        // With no servers in ServerStore, runBackgroundSync returns true
        final result = await triggerExecuteTask(
          'crowleys_cloud_background_sync',
          inputData: {'serverId': null},
        );
        expect(result, isTrue);
      },
    );

    test(
      '7.3 Task name recognition: Workmanager.iOSBackgroundTask (iOSPerformFetch) is recognized',
      () async {
        final result = await triggerExecuteTask(
          Workmanager.iOSBackgroundTask,
          inputData: {'serverId': null},
        );
        expect(result, isTrue);
      },
    );

    test(
      '7.4 Task name recognition: dev.fluttercommunity.workmanager.BackgroundFetch is recognized',
      () async {
        final result = await triggerExecuteTask(
          'dev.fluttercommunity.workmanager.BackgroundFetch',
          inputData: {'serverId': null},
        );
        expect(result, isTrue);
      },
    );

    test(
      '7.5 Task name recognition: dev.fluttercommunity.workmanager.BackgroundProcessingTask is recognized',
      () async {
        final result = await triggerExecuteTask(
          'dev.fluttercommunity.workmanager.BackgroundProcessingTask',
          inputData: {'serverId': null},
        );
        expect(result, isTrue);
      },
    );

    test(
      '7.6 Catches uncaught background exception in isolate and returns false',
      () async {
        // Create a corrupted servers.json file in documents directory to force jsonDecode FormatException
        final corruptFile = File('${tempDir.path}/servers.json');
        await corruptFile.writeAsString('INVALID_JSON_CORRUPT_CONTENT{{{{');

        final result = await triggerExecuteTask(
          'crowleys_cloud_background_sync',
          inputData: {'serverId': null},
        );

        // The dispatcher's catch (e, stack) should catch the FormatException and return false
        expect(result, isFalse);
      },
    );
  });
}
