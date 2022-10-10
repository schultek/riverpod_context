import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dependency_watcher.dart';

class InheritedConsumer extends InheritedWidget {
  const InheritedConsumer({
    required Widget child,
    Key? key,
  }) : super(key: key, child: child);

  @override
  InheritedElement createElement() => InheritedConsumerElement(this);

  /// This will get the inherited element and call the
  /// [dependOnInheritedElement] method. The element will decide when to
  /// rebuild the provided context
  static T watch<T>(BuildContext context, ProviderListenable<T> target) {
    _ensureDebugDoingBuild(context, 'watch');

    var elem = _getElementOrThrow(context);
    context.dependOnInheritedElement(elem);
    return elem._watch(context, target);
  }

  /// Priming a context is necessary when context.watch is called conditionally
  /// and the condition does not come from another context.watch
  static void prime(BuildContext context) {
    _ensureDebugDoingBuild(context, 'prime');
    _getElementOrThrow(context)._prime(context);
  }

  /// This will listen to the provider and manage the provider subscription
  static void listen<T>(
    BuildContext context,
    ProviderListenable<T> target,
    void Function(T? previous, T value) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool fireImmediately = false,
  }) {
    var elem = _getElementOrThrow(context);
    context.dependOnInheritedElement(elem);
    elem._listen(context, target, listener,
        onError: onError, fireImmediately: fireImmediately);
  }

  static void unlisten(BuildContext context, ProviderListenable target) {
    var elem = _getElementOrThrow(context);
    elem._unlisten(context, target);
  }

  static void _ensureDebugDoingBuild(BuildContext context, String method) {
    assert(() {
      if (!context.debugDoingBuild) {
        throw StateError(
            'context.$method can only be used within the build method of a widget');
      }
      return true;
    }());
  }

  static InheritedConsumerElement _getElementOrThrow(BuildContext context) {
    var elem =
        context.getElementForInheritedWidgetOfExactType<InheritedConsumer>();
    if (elem == null) {
      throw StateError("No InheritedConsumer found!");
    }
    return elem as InheritedConsumerElement;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true; // This widget should never rebuild, so returning true is fine
  }
}

/// The custom [InheritedElement] implementation. This is somewhat similar to
/// the [ConsumerStatefulElement] implementation.
class InheritedConsumerElement extends InheritedElement {
  InheritedConsumerElement(InheritedConsumer widget) : super(widget);

  final watchers = <Element, DependencyWatcher>{};

  /// This gets invoked after calling [dependOnInheritedElement] during build.
  @override
  void updateDependencies(Element dependent, Object? aspect) {
    watchers[dependent] ??= DependencyWatcher(dependent, this);
    setDependencies(dependent, {});
  }

  /// This is called after [dependOnInheritedElement] to watch a provider.
  T _watch<T>(Object dependent, ProviderListenable<T> target) {
    return watchers[dependent]!.watch(target);
  }

  /// This is called after [dependOnInheritedElement] to listen to a provider.
  void _listen<T>(
    Object dependent,
    ProviderListenable<T> target,
    void Function(T? previous, T value) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool fireImmediately = false,
  }) {
    watchers[dependent]!.listen(target, listener,
        onError: onError, fireImmediately: fireImmediately);
  }

  /// This will unsubscribe a previous listened-to provider
  void _unlisten(Object dependent, ProviderListenable target) {
    watchers[dependent]?.unlisten(target);
  }

  void _prime(BuildContext dependent) {
    watchers[dependent]?.prime();
  }

  @override
  Set<ProviderListenable>? getDependencies(Element dependent) {
    return super.getDependencies(dependent) as Set<ProviderListenable>?;
  }

  @override
  void setDependencies(
      Element dependent, covariant Set<ProviderListenable> value) {
    super.setDependencies(dependent, value);
  }

  @override
  void unmount() {
    // cleanup all dependencies
    for (var watcher in watchers.values) {
      watcher.clear();
    }
    watchers.clear();
    super.unmount();
  }
}
