import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_context/riverpod_context.dart';

import 'utils.dart';

final counter = StateProvider((ref) => 0);
final counterB = StateProvider.autoDispose((ref) => 0);

void main() {
  testWidgets(
    'context.listen listens to provider state',
    (WidgetTester tester) async {
      int? wasCalledWith;

      await tester.pumpWidget(providerApp((context) {
        context.listen<int>(counter, (prev, next) {
          wasCalledWith = next;
        });

        return TextButton(
          child: const Text('tap'),
          onPressed: () {
            context.read(counter.state).state++;
          },
        );
      }));

      expect(wasCalledWith, isNull);

      // increase counter
      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(wasCalledWith, equals(1));
    },
  );

  testWidgets(
    'context.listen re-listens on rebuild',
    (WidgetTester tester) async {
      List<int> wasCalledWith = [];

      await tester.pumpWidget(providerApp((context) {
        context.listen<int>(counter, (prev, next) {
          wasCalledWith.add(next);
        }, fireImmediately: true);

        return TextButton(
          child: Text('${context.watch(counter)}'),
          onPressed: () {
            context.read(counter.state).state++;
          },
        );
      }));

      expect(wasCalledWith, equals([0]));

      // increase counter
      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(wasCalledWith, equals([0, 1]));
    },
  );

  testWidgets(
    'context.listen un-listens on dispose',
    (WidgetTester tester) async {
      List<int> wasCalledWith = [];

      await tester.pumpWidget(providerApp((context) {
        if (context.watch(counter.select((cnt) => cnt < 2))) {
          return Builder(
            builder: (context) {
              context.listen<int>(counter, (prev, next) {
                wasCalledWith.add(next);
              }, fireImmediately: true);

              return TextButton(
                child: Text('a ${context.watch(counter)}'),
                onPressed: () {
                  context.read(counter.state).state++;
                },
              );
            },
          );
        } else {
          return TextButton(
            child: Text('b ${context.watch(counter)}'),
            onPressed: () {
              context.read(counter.state).state++;
            },
          );
        }
      }));

      expect(wasCalledWith, equals([0]));
      expect(find.text('a 0'), findsOneWidget);

      // increase counter
      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(wasCalledWith, equals([0, 1]));
      expect(find.text('a 1'), findsOneWidget);

      // increase counter
      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(wasCalledWith, equals([0, 1, 2]));
      expect(find.text('b 2'), findsOneWidget);

      // increase counter
      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(wasCalledWith, equals([0, 1, 2]));
      expect(find.text('b 3'), findsOneWidget);
    },
  );

  testWidgets(
    'context.unlisten closes an active listener',
    (WidgetTester tester) async {
      List<int> wasCalledWith = [];

      late Element element;
      var shouldListen = true;

      await tester.pumpWidget(providerApp((context) {
        if (shouldListen) {
          context.listen(counterB, (_, int value) {
            wasCalledWith.add(value);
          }, fireImmediately: true);
        } else {
          context.unlisten(counterB);
        }
        element = context as Element;
        return const Text('test');
      }));

      expect(wasCalledWith, equals([0]));
      expect(element.read(counterB), equals(0));

      // increase counter
      element.read(counterB.state).state = 1;

      expect(wasCalledWith, equals([0, 1]));

      // remove listener
      shouldListen = false;
      element.markNeedsBuild();
      await tester.pump();

      expect(wasCalledWith, equals([0, 1]));

      // was disposed
      await tester.pump();
      expect(element.read(counterB), equals(0));
    },
  );
}
