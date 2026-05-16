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
