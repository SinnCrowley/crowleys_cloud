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

import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/cache_service.dart';
import 'package:crowleys_cloud/l10n/generated/app_localizations.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:crowleys_cloud/server_store.dart';
import 'package:crowleys_cloud/shared/utils/iterable_extensions.dart';
import 'package:flutter/widgets.dart';

class ActiveServerManager extends ChangeNotifier {
  ActiveServerManager({
    required this.store,
    required this.authService,
    CacheService? cacheService,
  }) : _cacheService = cacheService ?? CacheService.instance;

  final ServerStore store;
  final AuthService authService;
  final CacheService _cacheService;

  List<ServerProfile> servers = [];
  ServerProfile? activeServer;
  bool isReady = false;
  bool requiresSetup = true;
  bool requiresAuth = false;
  String? connectionErrorMessage;

  AppLocalizations _getL10n([AppLocalizations? l10n]) {
    if (l10n != null) return l10n;
    try {
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      if (AppLocalizations.supportedLocales.any(
        (loc) => loc.languageCode == locale.languageCode,
      )) {
        return lookupAppLocalizations(Locale(locale.languageCode));
      }
    } catch (_) {}
    return lookupAppLocalizations(const Locale('en'));
  }

  Future<void> initialize([AppLocalizations? l10n]) async {
    final snapshot = await store.load();
    servers = snapshot.servers;
    if (servers.isEmpty) {
      requiresSetup = true;
      requiresAuth = false;
      activeServer = null;
      isReady = true;
      notifyListeners();
      return;
    }

    requiresSetup = false;
    activeServer = _pickActive(servers, snapshot.activeServerId);
    await _refreshAuthAndConnectionState(activeServer!, l10n);
    isReady = true;
    notifyListeners();
  }

  Future<void> addServer(ServerProfile profile) async {
    servers = [...servers, profile];
    activeServer = profile;
    requiresSetup = false;
    requiresAuth = false;
    connectionErrorMessage = null;
    await _persist();
    notifyListeners();
  }

  Future<void> switchActive(String serverId, [AppLocalizations? l10n]) async {
    final next = servers.where((s) => s.id == serverId).firstOrNull;
    if (next == null) return;

    activeServer = next.copyWith(lastUsedAt: DateTime.now().toUtc());
    servers = servers
        .map((s) => s.id == next.id ? activeServer! : s)
        .toList(growable: false);
    await _refreshAuthAndConnectionState(activeServer!, l10n);
    await _persist();
    notifyListeners();
  }

  Future<void> removeServer(String serverId, [AppLocalizations? l10n]) async {
    servers = servers.where((s) => s.id != serverId).toList(growable: false);
    await authService.logout(serverId);
    await _cacheService.deleteServer(serverId);

    if (servers.isEmpty) {
      activeServer = null;
      requiresSetup = true;
      requiresAuth = false;
      await _persist(activeId: null);
      notifyListeners();
      return;
    }

    if (activeServer?.id == serverId) {
      activeServer = _pickMostRecent(servers);
      await _refreshAuthAndConnectionState(activeServer!, l10n);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> markAuthed(String serverId, [AppLocalizations? l10n]) async {
    if (activeServer?.id == serverId) {
      await _refreshAuthAndConnectionState(activeServer!, l10n);
      notifyListeners();
    }
  }

  Future<void> updateActiveServerSyncPrefs(Map<String, Object?> prefs) async {
    final active = activeServer;
    if (active == null) return;
    await updateServerSyncPrefs(active.id, prefs);
  }

  Future<void> updateServerSyncPrefs(
    String serverId,
    Map<String, Object?> prefs,
  ) async {
    final current = servers
        .where((server) => server.id == serverId)
        .firstOrNull;
    if (current == null) return;
    final updated = current.copyWith(
      syncPrefs: {...current.syncPrefs, ...prefs},
    );
    if (activeServer?.id == serverId) {
      activeServer = updated;
    }
    servers = servers
        .map((server) => server.id == updated.id ? updated : server)
        .toList(growable: false);
    await _persist();
    notifyListeners();
  }

  void reportConnectionError({
    required String serverId,
    String? message,
    AppLocalizations? l10n,
  }) {
    if (activeServer?.id != serverId) return;
    requiresAuth = false;
    connectionErrorMessage =
        message ?? _getL10n(l10n).unableToConnectToServer;
    notifyListeners();
  }

  Future<void> _refreshAuthAndConnectionState(
    ServerProfile profile, [
    AppLocalizations? l10n,
  ]) async {
    connectionErrorMessage = null;
    final hasSession = await authService.hasSession(profile.id);
    requiresAuth = !hasSession;
    if (!hasSession) return;

    final check = await authService.checkSession(
      serverId: profile.id,
      baseUrl: profile.connectionUrl,
    );
    switch (check.status) {
      case SessionCheckStatus.authorized:
        requiresAuth = false;
        break;
      case SessionCheckStatus.noSession:
      case SessionCheckStatus.unauthorized:
        requiresAuth = true;
        break;
      case SessionCheckStatus.unreachable:
      case SessionCheckStatus.serverError:
        requiresAuth = false;
        connectionErrorMessage =
            check.message ?? _getL10n(l10n).unableToConnectToServer;
        break;
    }
  }

  ServerProfile _pickActive(List<ServerProfile> all, String? activeServerId) {
    final byId = all.where((s) => s.id == activeServerId).firstOrNull;
    if (byId != null) return byId;
    return _pickMostRecent(all);
  }

  ServerProfile _pickMostRecent(List<ServerProfile> all) {
    final sorted = [...all]
      ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    return sorted.first;
  }

  Future<void> _persist({String? activeId}) async {
    await store.save(
      servers: servers,
      activeServerId: activeId ?? activeServer?.id,
    );
  }

  void refresh() {
    notifyListeners();
  }
}
