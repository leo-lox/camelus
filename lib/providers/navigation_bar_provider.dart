import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

final navigationBarProvider = Provider<NavigationBarControls>((ref) {
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

  // home
  final StreamController<void> _onTabHome = StreamController<void>.broadcast();
  final StreamController<int> _newNotesCountController =
      StreamController<int>.broadcast();

  // search
  final StreamController<void> _onTabSearch =
      StreamController<void>.broadcast();

  Stream<void> get onTabHome => _onTabHome.stream;
  Stream<int> get newNotesCountStream => _newNotesCountController.stream;

  Stream<void> get onTabSearch => _onTabSearch.stream;

  void resetNewNotesCount() {
    _newNotesCount = 0;
    _newNotesCountController.add(_newNotesCount);
  }

  void tabHome() {
    _onTabHome.add(null);
  }

  void tabSearch() {
    _onTabSearch.add(null);
  }
}
