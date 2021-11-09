import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_context/riverpod_context.dart';

import 'utils.dart';

final counter = StateProvider((ref) => 0);
final autoDisposeCounter = StateProvider.autoDispose((ref) => 0);

void main() {
  testWidgets(
    'context.watch returns provider state and rebuilds on change',
    (WidgetTester tester) async {
      await tester.pumpWidget(providerApp((context) {
        return TextButton(
          child: Text('${context.watch(counter)}'),
          onPressed: () {
            context.read(counter.state).state++;
          },
        );
      }));

      expect(find.text('0'), findsOneWidget);

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
    },
  );

  testWidgets(
    'context.watch returns overridden provider state',
    (WidgetTester tester) async {
      await tester.pumpWidget(providerApp((context) {
        return Column(children: [
          TextButton(
            key: const ValueKey('a'),
            child: Text('a ${context.watch(counter)}'),
            onPressed: () {
              context.read(counter.state).state++;
            },
          ),
          ProviderScope(
            overrides: [counter.overrideWithValue(StateController(10))],
            child: Builder(builder: (context) {
              return TextButton(
                key: const ValueKey('b'),
                child: Text('b ${context.watch(counter)}'),
                onPressed: () {
                  context.read(counter.state).state++;
                },
              );
            }),
          ),
        ]);
      }));

      expect(find.text('a 0'), findsOneWidget);
      expect(find.text('b 10'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('a')));
      await tester.pump();

      expect(find.text('a 1'), findsOneWidget);
      expect(find.text('b 10'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('b')));
      await tester.pump();

      expect(find.text('a 1'), findsOneWidget);
      expect(find.text('b 11'), findsOneWidget);
    },
  );

  testWidgets(
    'provider is autodisposed when no longer watched',
    (WidgetTester tester) async {
      await tester.pumpWidget(providerApp((context) {
        var showCounter = true;
        return StatefulBuilder(
          builder: (context, setState) {
            context.prime();
            return TextButton(
              child: showCounter
                  ? Text('${context.watch(autoDisposeCounter)}')
                  : const Text('hidden'),
              onPressed: () {
                context.read(autoDisposeCounter.state).state++;
              },
              onLongPress: () {
                setState(() {
                  showCounter = !showCounter;
                });
              },
            );
          },
        );
      }));

      expect(find.text('0'), findsOneWidget);
      expect(find.text('hidden'), findsNothing);

      // increase counter
      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('hidden'), findsNothing);

      // hide counter
      await tester.longPress(find.byType(TextButton));
      await tester.pump();

      expect(find.text('1'), findsNothing);
      expect(find.text('hidden'), findsOneWidget);

      // show counter
      await tester.longPress(find.byType(TextButton));
      await tester.pump();

      expect(find.text('0'), findsOneWidget);
      expect(find.text('hidden'), findsNothing);
    },
  );
}
