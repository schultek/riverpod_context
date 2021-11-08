import 'package:flutter/widgets.dart';

import 'dependency_watcher.dart';

class BuildWatcher {
  static late BuildWatcher instance = BuildWatcher._();

  Set<DependencyWatcher> interceptors = {};

  BuildWatcher._() {
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      WidgetsBinding.instance!.addPersistentFrameCallback((_) => onFrame());
    });
  }

  void onFrame() {
    for (var interceptor in [...interceptors]) {
      // if the dependencies are null, this element was removed from the tree
      if (interceptor.needsDependencyCheck ||
          interceptor.parent.getDependencies(interceptor.dependent) == null) {
        interceptor.checkDependencies();
      }
    }
  }
}
