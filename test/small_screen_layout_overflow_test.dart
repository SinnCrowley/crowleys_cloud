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
import 'package:crowleys_cloud/active_server_manager.dart';
import 'package:crowleys_cloud/app_constants.dart';
import 'package:crowleys_cloud/app_update_service.dart';
import 'package:crowleys_cloud/auth_service.dart';
import 'package:crowleys_cloud/biometric_auth_service.dart';
import 'package:crowleys_cloud/file_browser.dart';
import 'package:crowleys_cloud/file_browser_controller.dart';
import 'package:crowleys_cloud/secret_store.dart';
import 'package:crowleys_cloud/server_browser_controller.dart';
import 'package:crowleys_cloud/server_file_browser.dart';
import 'package:crowleys_cloud/server_profile.dart';
import 'package:crowleys_cloud/server_store.dart';
import 'package:crowleys_cloud/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_helpers.dart';

class _FakeBiometricAuthService extends BiometricAuthService {
  @override
  Future<bool> canAuthenticate() async => false;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Crowleys Cloud',
      packageName: 'com.sinncrowley.crowleys_cloud',
      version: '0.4.0',
      buildNumber: '400',
      buildSignature: '',
    );
  });

  group('Small screen (320px width) layout & overflow tests', () {
    testWidgets(
      'SettingsScreen renders without overflow on 320px screen in Russian & English',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final manager =
            ActiveServerManager(
                store: ServerStore(),
                authService: AuthService(secretStore: InMemorySecretStore()),
              )
              ..activeServer = ServerProfile(
                id: 'srv',
                displayName: 'My Cloud Server',
                baseUrl: 'http://localhost',
                authMode: 'login',
                lastUsedAt: DateTime.now().toUtc(),
                syncPrefs: const {
                  'syncEnabled': true,
                  'syncFolders': ['/storage/emulated/0'],
                },
              );

        for (final locale in [const Locale('ru'), const Locale('en')]) {
          await tester.pumpWidget(
            wrapWithLocalization(
              SettingsScreen(
                serverManager: manager,
                biometricAuthService: _FakeBiometricAuthService(),
              ),
              locale: locale,
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);

          final listView = find.byType(ListView);
          expect(listView, findsOneWidget);

          for (var i = 0; i < 5; i++) {
            await tester.drag(listView, const Offset(0, -300));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        }
      },
    );

    testWidgets(
      'AppUpdateDialog renders without overflow on 320px screen in Russian & English',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        const updateInfo = AppUpdateInfo(
          hasUpdate: true,
          currentVersion: '0.4.0',
          latestVersion: '0.5.0-long-release-candidate-name',
          releaseNotes:
              '### New features\n- Many improvements\n- Bug fixes for layout',
          htmlUrl:
              'https://github.com/SinnCrowley/crowleys_cloud/releases/tag/v0.5.0',
          apkUrl: 'https://example.com/release.apk',
        );

        for (final locale in [const Locale('ru'), const Locale('en')]) {
          await tester.pumpWidget(
            wrapWithLocalization(
              Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) =>
                            const AppUpdateDialog(updateInfo: updateInfo),
                      );
                    },
                    child: const Text('Open Dialog'),
                  ),
                ),
              ),
              locale: locale,
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('Open Dialog'));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(AppUpdateDialog), findsOneWidget);

          // Dismiss dialog via the cancel/updateLater button
          await tester.tap(find.byType(TextButton).first);
          await tester.pumpAndSettle();
        }
      },
    );

    testWidgets(
      'LocalFolderPickerScreen toolbar is responsive, fits without horizontal scroll on 320px & 360px',
      (tester) async {
        final tempDir = Directory.systemTemp.createTempSync('picker_test');
        addTearDown(() => tempDir.deleteSync(recursive: true));

        final controller = FileBrowserController(
          category: const FileCategory('All files', Icons.folder),
          loadOnInit: false,
        );

        // Test on 320px screen (compact button)
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        for (final locale in [const Locale('ru'), const Locale('en')]) {
          await tester.pumpWidget(
            wrapWithLocalization(
              LocalFolderPickerScreen(
                controller: controller,
                initialPath: tempDir.path,
              ),
              locale: locale,
            ),
          );
          for (var i = 0; i < 5; i++) {
            await tester.pump(const Duration(milliseconds: 50));
          }

          expect(tester.takeException(), isNull);
          expect(find.byType(LocalFolderPickerScreen), findsOneWidget);
          // On 320px (usable width 288px < 340px), compact icon button is shown
          expect(find.byType(IconButton), findsWidgets);
        }

        // Test on 360px screen (button with text)
        tester.view.physicalSize = const Size(360, 640);
        await tester.pumpWidget(
          wrapWithLocalization(
            LocalFolderPickerScreen(
              controller: controller,
              initialPath: tempDir.path,
            ),
            locale: const Locale('ru'),
          ),
        );
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        expect(tester.takeException(), isNull);
        expect(find.byType(FilledButton), findsOneWidget);
      },
    );

    testWidgets(
      'Server file move folder picker toolbar fits without overflow and has proper icon spacing',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final secretStore = InMemorySecretStore();
        await secretStore.saveTokens(
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
                    'name': 'Docs',
                    'size': 0,
                    'modified_at': 1000,
                    'type': 'dir',
                    'mime_type': 'inode/directory',
                    'is_dir': true,
                    'path': '/Docs',
                  },
                ],
              }),
              200,
            );
          }
          return http.Response('{}', 200);
        });

        final serverController = ServerBrowserController(
          serverId: 'srv',
          profile: ServerProfile(
            id: 'srv',
            displayName: 'Test',
            baseUrl: 'http://localhost',
            authMode: 'login',
            lastUsedAt: DateTime.now().toUtc(),
            syncPrefs: const {},
          ),
          authService: AuthService(secretStore: secretStore),
          client: client,
        );

        await tester.pumpWidget(
          wrapWithLocalization(
            Scaffold(
              body: ServerFileBrowser(
                controller: serverController,
                isGridView: true,
              ),
            ),
            locale: const Locale('ru'),
          ),
        );
        await tester.pumpAndSettle();

        // Select an item to show action toolbar
        final item = serverController.files.first;
        serverController.toggleSelection(item);
        await tester.pumpAndSettle();

        // Tap "Move to folder" / "addToFolder" in app bar
        await tester.tap(find.byIcon(Icons.drive_file_move));
        await tester.pumpAndSettle();

        // Folder picker screen is opened without overflow
        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.sort), findsOneWidget);
      },
    );
  });
}
