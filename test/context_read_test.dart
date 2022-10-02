import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_context/riverpod_context.dart';

import 'utils.dart';

final counter = StateProvider((ref) => 0);

void main() {
  testWidgets(
    'context.read returns provider state',
    (WidgetTester tester) async {
      await tester.pumpWidget(providerApp((context) {
        return Text('${context.read(counter)}');
      }));

      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsNothing);
    },
  );

  testWidgets(
    'context.read returns overridden provider state',
    (WidgetTester tester) async {
      await tester.pumpWidget(providerApp((context) {
        return Column(children: [
          Text('a ${context.read(counter)}'),
          ProviderScope(
            overrides: [counter.overrideWithProvider(StateProvider((_) => 1))],
            child: Builder(builder: (context) {
              return Text('b ${context.read(counter)}');
            }),
          ),
        ]);
      }));

      expect(find.text('a 0'), findsOneWidget);
      expect(find.text('b 1'), findsOneWidget);
    },
  );
}
