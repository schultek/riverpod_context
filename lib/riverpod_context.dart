library riverpod_context;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/inherited_consumer.dart';

export 'src/inherited_consumer.dart' show InheritedConsumer;

extension RiverpodContext on BuildContext {
  /// Reads a provider without listening to it
  T read<T>(ProviderListenable<T> provider) {
    return ProviderScope.containerOf(this, listen: false).read(provider);
  }

  /// Refreshes a provider
  T refresh<T>(Refreshable<T> provider) {
    return ProviderScope.containerOf(this, listen: false).refresh(provider);
  }

  /// Invalidates a provider
  void invalidate(ProviderOrFamily provider) {
    ProviderScope.containerOf(this, listen: false).invalidate(provider);
  }

  /// Watches a provider and rebuilds the current context on change
  T watch<T>(ProviderListenable<T> provider) {
    return InheritedConsumer.watch<T>(this, provider);
  }

  /// Primes the current context for dependency monitoring
  void prime() {
    InheritedConsumer.prime(this);
  }

  /// Listens to a provider and automatically manages the subscription
  void listen<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T value) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool fireImmediately = false,
  }) {
    InheritedConsumer.listen<T>(this, provider, listener,
        onError: onError, fireImmediately: fireImmediately);
  }

  void unlisten(ProviderListenable provider) {
    InheritedConsumer.unlisten(this, provider);
  }

  /// Listens to a provider and returns the subscription.
  ProviderSubscription<T> subscribe<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T value) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool fireImmediately = false,
  }) {
    return ProviderScope.containerOf(this, listen: false).listen(
        provider, listener,
        fireImmediately: fireImmediately, onError: onError);
  }
}
