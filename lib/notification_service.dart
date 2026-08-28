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

import 'dart:ui';

import 'package:crowleys_cloud/l10n/generated/app_localizations.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations_en.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

AppLocalizations _resolveNotificationL10n() {
  try {
    final locale = PlatformDispatcher.instance.locale;
    return lookupAppLocalizations(locale);
  } catch (_) {
    return AppLocalizationsEn();
  }
}

class SyncNotificationService {
  SyncNotificationService._();
  static final SyncNotificationService instance = SyncNotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(settings: initSettings);

    final l10n = _resolveNotificationL10n();
    final channelName = l10n.syncChannelName;
    final channelDescription = l10n.syncChannelDescription;

    final channel = AndroidNotificationChannel(
      'sync_channel',
      channelName,
      description: channelDescription,
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  Future<void> showProgressNotification({
    required int id,
    required String title,
    required String body,
    int? progress,
    int? maxProgress,
  }) async {
    await initialize();

    final l10n = _resolveNotificationL10n();
    final channelName = l10n.syncChannelName;
    final channelDescription = l10n.syncChannelDescription;

    final androidDetails = AndroidNotificationDetails(
      'sync_channel',
      channelName,
      channelDescription: channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      showProgress: progress != null,
      maxProgress: maxProgress ?? 100,
      progress: progress ?? 0,
      indeterminate: progress == null,
      ongoing: true,
      playSound: false,
      enableVibration: false,
    );

    final details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> showCompleteNotification({
    required int id,
    required String title,
    required String body,
    bool isError = false,
  }) async {
    await initialize();

    if (!isError) {
      await _notificationsPlugin.cancel(id: id);
      return;
    }

    final l10n = _resolveNotificationL10n();
    final channelName = l10n.syncChannelName;
    final channelDescription = l10n.syncChannelDescription;

    final androidDetails = AndroidNotificationDetails(
      'sync_channel',
      channelName,
      channelDescription: channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ongoing: false,
      playSound: true,
    );

    final details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}
