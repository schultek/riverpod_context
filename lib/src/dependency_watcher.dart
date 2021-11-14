import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'build_watcher.dart';
import 'inherited_consumer.dart';

class DependencyWatcher {
  final Element dependent;
  final InheritedConsumerElement parent;

  DependencyWatcher(this.dependent, this.parent) {
    BuildWatcher.instance.watchers.add(this);
    parent.setDependencies(dependent, {});
  }

  Map<ProviderListenable, ProviderSubscription> subscriptions = {};
  Map<ProviderListenable, ProviderSubscription> listeners = {};

  /// [InheritedElement] has it's own private [_dependents] but we use both
  /// to identify changes in dependencies after widget rebuilds
  /// (see [checkDependencies])
  Set<ProviderListenable>? nextDependents;

  /// To signal [BuildWatcher] to call [checkDependencies] after next frame
  bool needsDependencyCheck = false;

  T watch<T>(ProviderListenable<T> listenable) {
    if (!subscriptions.containsKey(listenable)) {
      // create a new [ProviderSubscription] and add it to the dependencies

      void listener(_, v) {
        if (subscriptions[listenable] == null) return;

        needsDependencyCheck = true;

        // remove all dependencies, these will be re-assigned
        // during the build phase
        parent.setDependencies(dependent, {});

        // trigger a rebuild for this dependent
        dependent.markNeedsBuild();
      }

      var container = ProviderScope.containerOf(dependent);
      var subscription = container.listen(listenable, listener);

      subscriptions[listenable] = subscription;
    }

    // add the provider to the next dependencies
    (nextDependents ??= {}).add(listenable);

    needsDependencyCheck = true;

    return subscriptions[listenable]!.read();
  }

  void listen<T>(
    ProviderListenable<T> listenable,
    void Function(T? previous, T value) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool fireImmediately = false,
  }) {
    // close any existing listeners for the same provider
    if (listeners.containsKey(listenable)) {
      listeners[listenable]!.close();
      fireImmediately = false;
    }

    var container = ProviderScope.containerOf(dependent);
    var subscription = container.listen(listenable, listener,
        fireImmediately: fireImmediately, onError: onError);

    listeners[listenable] = subscription;
  }

  void unlisten(ProviderListenable listenable) {
    listeners.remove(listenable)?.close();
  }

  void prime() {
    needsDependencyCheck = true;
  }

  /// After building, we have to check all dependencies if they are still
  /// valid and close unused subscriptions
  /// A dependent is automatically removed only from the private dependents
  /// when a widget is deactivated.
  void checkDependencies() {
    // get the next dependencies
    var dependencies = nextDependents ?? {};
    nextDependents = null;

    // update the current dependencies
    parent.setDependencies(dependent, dependencies);

    subscriptions.removeWhere((key, value) {
      // if it was removed during the last build phase, we close
      // the subscription. This is important for auto dispose
      if (!dependencies.contains(key)) {
        value.close();
        return true;
      }
      return false;
    });

    needsDependencyCheck = false;
  }

  void clear() {
    for (var subscription in subscriptions.values) {
      subscription.close();
    }
    subscriptions.clear();
    for (var listener in listeners.values) {
      listener.close();
    }
    listeners.clear();
    BuildWatcher.instance.watchers.remove(this);
  }

  void dispose() {
    clear();
    parent.watchers.remove(dependent);
  }
}
