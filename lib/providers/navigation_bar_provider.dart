import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

final navigatiionBarProvider = Provider<NavigationBarControls>((ref) {
  var navigationBarControls = NavigationBarControls();

  return navigationBarControls;
});

class NavigationBarControls {
  int _newNotesCount = 0;

  int get newNotesCount => _newNotesCount;
  set newNotesCount(int value) => {
        _newNotesCount = value,
        _newNotesCountController.add(_newNotesCount),
      };

  final StreamController<void> _onTabHome = StreamController<void>.broadcast();
  final StreamController<int> _newNotesCountController =
      StreamController<int>.broadcast();

  Stream<void> get onTabHome => _onTabHome.stream;
  Stream<int> get newNotesCountStream => _newNotesCountController.stream;

  void resetNewNotesCount() {
    _newNotesCount = 0;
  }

  void tabHome() {
    _onTabHome.add(null);
  }
}
