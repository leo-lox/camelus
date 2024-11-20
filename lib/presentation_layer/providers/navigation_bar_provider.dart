import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to manage navigation bar controls.
/// It instantiates the `NavigationBarControls` and makes it accessible via Riverpod.
final navigationBarProvider = Provider<NavigationBarControls>((ref) {
  final navigationBarControls = NavigationBarControls();
  // Return the instance for provider access
  return navigationBarControls;
});

/// Class to manage the behavior and state of the navigation bar.
class NavigationBarControls {
  // Tracks the number of new notes.
  int _newNotesCount = 0;

  /// Getter for the current count of new notes.
  int get newNotesCount => _newNotesCount;

  /// Setter for the count of new notes.
  /// Updates the internal value and emits the updated count via the stream.
  set newNotesCount(int value) => {
        _newNotesCount = value, // Update the count
        _newNotesCountController.add(_newNotesCount), // Notify listeners
      };

  // StreamController to handle "Home" tab events. It broadcasts events to multiple listeners.
  final StreamController<void> _onTabHome = StreamController<void>.broadcast();

  // StreamController to broadcast changes to the count of new notes.
  final StreamController<int> _newNotesCountController =
      StreamController<int>.broadcast();

  // StreamController to handle "Search" tab events. It also broadcasts events.
  final StreamController<void> _onTabSearch =
      StreamController<void>.broadcast();

  /// Stream to listen to "Home" tab events.
  Stream<void> get onTabHome => _onTabHome.stream;

  /// Stream to listen to updates of the new notes count.
  Stream<int> get newNotesCountStream => _newNotesCountController.stream;

  /// Stream to listen to "Search" tab events.
  Stream<void> get onTabSearch => _onTabSearch.stream;

  /// Resets the count of new notes to 0 and notifies listeners of the change.
  void resetNewNotesCount() {
    _newNotesCount = 0; // Reset the count
    _newNotesCountController.add(_newNotesCount); // Notify listeners
  }

  /// Emits an event to indicate the "Home" tab has been selected.
  void tabHome() {
    _onTabHome.add(null);
  }

  /// Emits an event to indicate the "Search" tab has been selected.
  void tabSearch() {
    _onTabSearch.add(null);
  }
}
