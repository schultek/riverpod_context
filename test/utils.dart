import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_context/riverpod_context.dart';

Widget providerApp(WidgetBuilder builder) {
  return ProviderScope(
    child: InheritedConsumer(
      child: MaterialApp(home: Builder(builder: builder)),
    ),
  );
}
