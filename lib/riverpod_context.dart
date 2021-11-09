library riverpod_context;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/inherited_consumer.dart';

export 'src/inherited_consumer.dart' show InheritedConsumer;

extension RiverpodContext on BuildContext {
  /// Reads a provider without listening to it
  T read<T>(ProviderBase<T> provider) {
    return ProviderScope.containerOf(this, listen: false).read(provider);
  }

  /// Refreshes a provider
  T refresh<T>(ProviderBase<T> provider) {
    return ProviderScope.containerOf(this, listen: false).refresh(provider);
  }

  /// Watches a provider and rebuilds the current context on change
  T watch<T>(ProviderListenable<T> provider) {
    return InheritedConsumer.watch<T>(this, provider);
  }

  /// Primes the current context for dependency monitoring
  void prime() {
    InheritedConsumer.prime(this);
  }

// Todo add context.listen
}
