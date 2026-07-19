import 'package:crowleys_cloud/app_theme.dart';
import 'package:crowleys_cloud/theme_customizer_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ColorPickerDialog renders without layout assertion errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
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

  testWidgets('Font size scaling works without TextStyle assertions', (tester) async {
    AppTheme.set(AppThemeData.dark.copyWith(fontSizeScale: 1.25));

    await tester.pumpWidget(
      ValueListenableBuilder<AppThemeData>(
        valueListenable: AppTheme.notifier,
        builder: (context, appTheme, _) {
          return MaterialApp(
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(appTheme.fontSizeScale),
                ),
                child: child!,
              );
            },
            home: const Scaffold(
              body: Center(
                child: Text('Scaled Text Test'),
              ),
            ),
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
