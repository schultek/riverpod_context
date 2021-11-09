import 'package:flutter/widgets.dart';

import 'dependency_watcher.dart';

class BuildWatcher {
  static late BuildWatcher instance = BuildWatcher._();

  Set<DependencyWatcher> watchers = {};

  BuildWatcher._() {
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      WidgetsBinding.instance!.addPersistentFrameCallback((_) => onFrame());
    });
  }

  void onFrame() {
    for (var watcher in [...watchers]) {
      // if the dependencies are null, this element was removed from the tree
      if (watcher.needsDependencyCheck ||
          watcher.parent.getDependencies(watcher.dependent) == null) {
        watcher.checkDependencies();
      }
    }
  }
}
