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
