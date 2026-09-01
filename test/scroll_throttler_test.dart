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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crowleys_cloud/shared/utils/scroll_throttler.dart';

void main() {
  group('ScrollThrottler', () {
    testWidgets('initial state isFastScrolling is false', (tester) async {
      bool? isFast;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollThrottler(
              child: Builder(
                builder: (context) {
                  isFast = ScrollThrottler.isFastScrolling(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      expect(isFast, isFalse);
    });

    testWidgets('returns false when no ancestor ScrollThrottler exists', (
      tester,
    ) async {
      bool? isFast;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                isFast = ScrollThrottler.isFastScrolling(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(isFast, isFalse);
      expect(
        ScrollThrottler.notifierOf(tester.element(find.byType(SizedBox))),
        isNull,
      );
    });

    testWidgets('detects fast fling and resets on scroll end', (tester) async {
      final controller = ScrollController();
      late ValueNotifier<bool> fastNotifier;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollThrottler(
              velocityThreshold: 300.0,
              idleTimeout: const Duration(milliseconds: 50),
              child: Builder(
                builder: (context) {
                  fastNotifier = ScrollThrottler.notifierOf(context)!;
                  return ListView.builder(
                    controller: controller,
                    itemCount: 100,
                    itemBuilder: (ctx, i) =>
                        SizedBox(height: 100, child: Text('Item $i')),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(fastNotifier.value, isFalse);

      // Fast drag fling
      await tester.fling(find.byType(ListView), const Offset(0, -500), 3000);
      await tester.pump();
      expect(fastNotifier.value, isTrue);

      // Wait for ballistic settle
      await tester.pumpAndSettle();
      expect(fastNotifier.value, isFalse);
    });

    testWidgets(
      'resets after idle timeout if fling stops without explicit end notification',
      (tester) async {
        final controller = ScrollController();
        late ValueNotifier<bool> fastNotifier;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ScrollThrottler(
                velocityThreshold: 200.0,
                idleTimeout: const Duration(milliseconds: 60),
                child: Builder(
                  builder: (context) {
                    fastNotifier = ScrollThrottler.notifierOf(context)!;
                    return ListView.builder(
                      controller: controller,
                      itemCount: 100,
                      itemBuilder: (ctx, i) =>
                          SizedBox(height: 100, child: Text('Item $i')),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // Trigger fling
        await tester.fling(find.byType(ListView), const Offset(0, -300), 2000);
        await tester.pump();
        expect(fastNotifier.value, isTrue);

        // Advance clock past idle timeout
        await tester.pump(const Duration(milliseconds: 100));
        expect(fastNotifier.value, isFalse);
      },
    );

    testWidgets('allows notification bubbling to parent NotificationListener', (
      tester,
    ) async {
      var parentReceived = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationListener<ScrollNotification>(
              onNotification: (notif) {
                parentReceived = true;
                return false;
              },
              child: ScrollThrottler(
                child: ListView.builder(
                  itemCount: 50,
                  itemBuilder: (ctx, i) =>
                      SizedBox(height: 50, child: Text('Item $i')),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.drag(find.byType(ListView), const Offset(0, -100));
      await tester.pump();

      expect(parentReceived, isTrue);
    });
  });
}
