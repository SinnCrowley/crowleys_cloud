import 'dart:convert';
import 'dart:io';

import 'package:crowleys_cloud/server_profile.dart';
import 'package:path_provider/path_provider.dart';

class ServerStoreSnapshot {
  const ServerStoreSnapshot({
    required this.servers,
    required this.activeServerId,
  });

  final List<ServerProfile> servers;
  final String? activeServerId;
}

class ServerStore {
  ServerStore({this.fileProvider});

  final Future<File> Function()? fileProvider;

  Future<ServerStoreSnapshot> load() async {
    final file = await _resolveFile();
    if (!await file.exists()) {
      return const ServerStoreSnapshot(servers: [], activeServerId: null);
    }

    final raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return const ServerStoreSnapshot(servers: [], activeServerId: null);
    }

    final data = jsonDecode(raw) as Map<String, Object?>;
    final servers = ((data['servers'] as List?) ?? const [])
        .map(
          (entry) =>
              ServerProfile.fromJson(Map<String, Object?>.from(entry as Map)),
        )
        .toList();

    final activeServerId = data['activeServerId'] as String?;
    return ServerStoreSnapshot(
      servers: servers,
      activeServerId: activeServerId,
    );
  }

  Future<void> save({
    required List<ServerProfile> servers,
    required String? activeServerId,
  }) async {
    final file = await _resolveFile();
    await file.parent.create(recursive: true);
    final payload = {
      'activeServerId': activeServerId,
      'servers': servers.map((s) => s.toJson()).toList(),
    };
    await file.writeAsString(jsonEncode(payload));
  }

  Future<File> _resolveFile() async {
    if (fileProvider != null) {
      return fileProvider!();
    }
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/servers.json');
  }
}
