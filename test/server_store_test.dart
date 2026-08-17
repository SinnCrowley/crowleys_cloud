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

import 'package:crowleys_cloud/server_profile.dart';
import 'package:crowleys_cloud/server_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('save/load roundtrip with active server id', () async {
    final tempDir = await Directory.systemTemp.createTemp('server_store_test');
    addTearDown(() => tempDir.delete(recursive: true));
    final file = File('${tempDir.path}/servers.json');

    final store = ServerStore(fileProvider: () async => file);
    final server = ServerProfile(
      id: 's1',
      displayName: 'Home NAS',
      baseUrl: 'https://home.local',
      authMode: 'register',
      lastUsedAt: DateTime.utc(2026, 5, 14),
      syncPrefs: const {'syncOnWifiOnly': true},
    );

    await store.save(servers: [server], activeServerId: 's1');

    final loaded = await store.load();
    expect(loaded.activeServerId, 's1');
    expect(loaded.servers.length, 1);
    expect(loaded.servers.first.displayName, 'Home NAS');
    expect(loaded.servers.first.syncPrefs['syncOnWifiOnly'], true);
  });
}
