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
    context.dependOnInheritedElement(elem, aspect: target);
    return elem._read(context, target) as T;
  }

  /// Priming a context is necessary when context.watch is called conditionally
  /// and the condition does not come from another context.watch
  static void prime(BuildContext context) {
    _ensureDebugDoingBuild(context, 'prime');
    _getElementOrThrow(context)._prime(context);
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
  /// We use the [aspect] parameter for the provider we want to watch.
  @override
  void updateDependencies(Element dependent, Object? aspect) {
    var listenable = aspect as ProviderListenable;

    if (!watchers.containsKey(dependent)) {
      watchers[dependent] = DependencyWatcher(dependent, this);
    }

    watchers[dependent]!.watch(listenable);
  }

  void _prime(BuildContext dependent) {
    watchers[dependent]?.prime();
  }

  /// This is used to return the current value when calling [context.watch].
  /// We need this since [dependOnInheritedElement] returns void.
  dynamic _read(Object dependent, ProviderListenable target) {
    return watchers[dependent]?.subscriptions[target]?.read();
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
    for (var interceptor in watchers.values) {
      for (var subscription in interceptor.subscriptions.values) {
        subscription.close();
      }
    }
    super.unmount();
  }
}
