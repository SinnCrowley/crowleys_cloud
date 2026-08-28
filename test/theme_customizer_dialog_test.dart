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

import 'package:crowleys_cloud/app_theme.dart';
import 'package:crowleys_cloud/theme_customizer_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';

void main() {
  testWidgets('ColorPickerDialog renders without layout assertion errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapWithLocalization(
        Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                ColorPickerDialog.show(
                  context,
                  initialColor: Colors.blue,
                  title: 'Select Accent Color',
                );
              },
              child: const Text('Open Color Picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Color Picker'));
    await tester.pumpAndSettle();

    expect(find.text('Select Accent Color'), findsOneWidget);
    expect(find.text('Presets'), findsOneWidget);
    expect(find.text('Custom Palette'), findsOneWidget);
    expect(find.text('HEX RGB Code'), findsOneWidget);
  });

  testWidgets('Font size scaling works without TextStyle assertions', (
    tester,
  ) async {
    AppTheme.set(AppThemeData.dark.copyWith(fontSizeScale: 1.25));

    await tester.pumpWidget(
      ValueListenableBuilder<AppThemeData>(
        valueListenable: AppTheme.notifier,
        builder: (context, appTheme, _) {
          return wrapWithLocalization(
            const Scaffold(body: Center(child: Text('Scaled Text Test'))),
          );
        },
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Scaled Text Test'), findsOneWidget);

    // Change scale back to default
    AppTheme.set(AppThemeData.dark);
    await tester.pumpAndSettle();
  });
}
