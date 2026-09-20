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
import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/server_browser_controller.dart';
import 'package:crowleys_cloud/server_file_browser.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:crowleys_cloud/shared/widgets/remote_thumbnail_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<ServerBrowserController> createController() async {
    final store = InMemorySecretStore();
    await store.saveTokens(
      serverId: 'srv',
      accessToken: 'token',
      refreshToken: 'refresh',
    );

    final client = MockClient((request) async {
      if (request.url.path == '/api/dir') {
        return http.Response(
          jsonEncode({
            'entries': [
              {
                'name': 'Documents',
                'size': 0,
                'modified_at': 1000,
                'type': 'dir',
                'mime_type': 'inode/directory',
                'is_dir': true,
                'path': '/Documents',
              },
              {
                'name': 'song.mp3',
                'size': 1024,
                'modified_at': 2000,
                'type': 'audio',
                'mime_type': 'audio/mpeg',
                'is_dir': false,
                'path': '/song.mp3',
              },
              {
                'name': 'report.pdf',
                'size': 2048,
                'modified_at': 3000,
                'type': 'document',
                'mime_type': 'application/pdf',
                'is_dir': false,
                'path': '/report.pdf',
              },
              {
                'name': 'photo.jpg',
                'size': 4096,
                'modified_at': 4000,
                'type': 'photo',
                'mime_type': 'image/jpeg',
                'is_dir': false,
                'path': '/photo.jpg',
              },
            ],
          }),
          200,
        );
      }
      return http.Response('Not found', 404);
    });

    return ServerBrowserController(
      profile: ServerProfile(
        id: 'srv',
        displayName: 'Test Server',
        baseUrl: 'http://localhost:8080',
        authMode: 'login',
        lastUsedAt: DateTime.now().toUtc(),
        syncPrefs: const {},
      ),
      serverId: 'srv',
      authService: AuthService(secretStore: store),
      client: client,
    );
  }

  testWidgets('renders server files in GridView matching local browser layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = await createController();
    await tester.pumpWidget(
      wrapWithLocalization(
        Scaffold(
          body: ServerFileBrowser(controller: controller, isGridView: true),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Folder: immediately renders folder icon synchronously without network thumbnail widget
    expect(find.byIcon(Icons.folder), findsWidgets);

    // Audio: immediately renders audio_file icon
    expect(find.byIcon(Icons.audio_file), findsOneWidget);

    // Document: immediately renders pdf icon
    expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);

    // Media (photo): renders RemoteThumbnailWidget
    expect(find.byType(RemoteThumbnailWidget), findsOneWidget);

    // File names are rendered centered
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('song.mp3'), findsOneWidget);
    expect(find.text('report.pdf'), findsOneWidget);
    expect(find.text('photo.jpg'), findsOneWidget);

    controller.disposeController();
    controller.dispose();
  });

  testWidgets('renders server files in ListView matching local browser layout', (
    tester,
  ) async {
    final controller = await createController();
    await tester.pumpWidget(
      wrapWithLocalization(
        Scaffold(
          body: ServerFileBrowser(controller: controller, isGridView: false),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 4 ListTiles rendered
    expect(find.byType(ListTile), findsNWidgets(4));

    // Icons present
    expect(find.byIcon(Icons.folder), findsWidgets);
    expect(find.byIcon(Icons.audio_file), findsOneWidget);
    expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    expect(find.byType(RemoteThumbnailWidget), findsOneWidget);

    // Context menu icon present for each file
    expect(find.byIcon(Icons.more_vert), findsNWidgets(4));

    controller.disposeController();
    controller.dispose();
  });
}
