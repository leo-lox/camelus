import 'dart:async';
import 'dart:developer';

import 'package:hooks_riverpod/hooks_riverpod.dart';

final navigatiionBarProvider = Provider<NavigationBarControls>((ref) {
  var navigationBarControls = NavigationBarControls();

  return navigationBarControls;
});

class NavigationBarControls {
  int _newNotesCount = 0;

  int get newNotesCount => _newNotesCount;
  set newNotesCount(int value) => _newNotesCount = value;

  final StreamController<void> _onTabHome = StreamController<void>.broadcast();

  Stream<void> get onTabHome => _onTabHome.stream;

  void resetNewNotesCount() {
    _newNotesCount = 0;
  }

  void tabHome() {
    _onTabHome.add(null);
  }
}
