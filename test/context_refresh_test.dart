import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_context/riverpod_context.dart';

import 'utils.dart';

final counter = StateProvider((ref) => 0);
final counterB = StateProvider((ref) => 10);

void main() {
  testWidgets(
    'context.refresh refreshes provider state',
    (WidgetTester tester) async {
      await tester.pumpWidget(providerApp((context) {
        return TextButton(
          child: Text('${context.watch(counter)}'),
          onPressed: () {
            context.read(counter.state).state++;
          },
          onLongPress: () {
            context.refresh(counter);
          },
        );
      }));

      expect(find.text('0'), findsOneWidget);

      // increase counter
      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      // refresh counter
      await tester.longPress(find.byType(TextButton));
      await tester.pump();

      expect(find.text('0'), findsOneWidget);
    },
  );

  testWidgets(
    'context.refresh refreshes overridden provider state',
    (WidgetTester tester) async {
      await tester.pumpWidget(providerApp((context) {
        return Column(children: [
          Builder(builder: (context) {
            return TextButton(
              key: const ValueKey('a'),
              child: Text('a ${context.watch(counter)}'),
              onPressed: () {
                context.read(counter.state).state++;
              },
              onLongPress: () {
                context.refresh(counter);
              },
            );
          }),
          ProviderScope(
            overrides: [counter.overrideWithProvider(counterB)],
            child: Builder(builder: (context) {
              return TextButton(
                key: const ValueKey('b'),
                child: Text('b ${context.watch(counter)}'),
                onPressed: () {
                  context.read(counter.state).state++;
                },
                onLongPress: () {
                  context.refresh(counter);
                },
              );
            }),
          ),
        ]);
      }));

      expect(find.text('a 0'), findsOneWidget);
      expect(find.text('b 10'), findsOneWidget);

      // increase counters
      await tester.tap(find.byKey(const ValueKey('a')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('b')));
      await tester.pump();

      expect(find.text('a 1'), findsOneWidget);
      expect(find.text('b 11'), findsOneWidget);

      // refresh counter a
      await tester.longPress(find.byKey(const ValueKey('a')));
      await tester.pump();

      expect(find.text('a 0'), findsOneWidget);
      expect(find.text('b 11'), findsOneWidget);

      // increase counter a, refresh counter b
      await tester.tap(find.byKey(const ValueKey('a')));
      await tester.pump();
      await tester.longPress(find.byKey(const ValueKey('b')));
      await tester.pump();

      expect(find.text('a 1'), findsOneWidget);
      expect(find.text('b 10'), findsOneWidget);
    },
  );
}
