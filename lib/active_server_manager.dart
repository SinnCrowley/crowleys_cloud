import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:crowleys_cloud/server_store.dart';
import 'package:flutter/foundation.dart';

class ActiveServerManager extends ChangeNotifier {
  ActiveServerManager({required this.store, required this.authService});

  final ServerStore store;
  final AuthService authService;

  List<ServerProfile> servers = [];
  ServerProfile? activeServer;
  bool isReady = false;
  bool requiresSetup = true;
  bool requiresAuth = false;

  Future<void> initialize() async {
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
    requiresAuth = !(await authService.hasSession(activeServer!.id));
    isReady = true;
    notifyListeners();
  }

  Future<void> addServer(ServerProfile profile) async {
    servers = [...servers, profile];
    activeServer = profile;
    requiresSetup = false;
    requiresAuth = false;
    await _persist();
    notifyListeners();
  }

  Future<void> switchActive(String serverId) async {
    final next = servers.where((s) => s.id == serverId).firstOrNull;
    if (next == null) return;

    activeServer = next.copyWith(lastUsedAt: DateTime.now().toUtc());
    servers = servers
        .map((s) => s.id == next.id ? activeServer! : s)
        .toList(growable: false);
    requiresAuth = !(await authService.hasSession(next.id));
    await _persist();
    notifyListeners();
  }

  Future<void> removeServer(String serverId) async {
    servers = servers.where((s) => s.id != serverId).toList(growable: false);
    await authService.logout(serverId);

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
      requiresAuth = !(await authService.hasSession(activeServer!.id));
    }
    await _persist();
    notifyListeners();
  }

  Future<void> markAuthed(String serverId) async {
    if (activeServer?.id == serverId) {
      requiresAuth = false;
      notifyListeners();
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
}

extension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
