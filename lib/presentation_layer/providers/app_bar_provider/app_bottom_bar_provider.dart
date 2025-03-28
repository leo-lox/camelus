import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

enum NavigationTab { home, search, notifications, chat }

class NavigationState {
  final NavigationTab selectedTab;
  final int newNotesCount;

  NavigationState({
    required this.selectedTab,
    this.newNotesCount = 0,
  });

  NavigationState copyWith({
    NavigationTab? selectedTab,
    int? newNotesCount,
  }) {
    return NavigationState(
      selectedTab: selectedTab ?? this.selectedTab,
      newNotesCount: newNotesCount ?? this.newNotesCount,
    );
  }
}

class NavigationEvents {
  // Stream controllers for specific tab events
  final _homeTabController = StreamController<void>.broadcast();
  final _searchTabController = StreamController<void>.broadcast();
  final _notificationsTabController = StreamController<void>.broadcast();
  final _chatTabController = StreamController<void>.broadcast();

  // Expose streams for listeners
  Stream<void> get onHomeTabSelected => _homeTabController.stream;
  Stream<void> get onSearchTabSelected => _searchTabController.stream;
  Stream<void> get onNotificationsTabSelected =>
      _notificationsTabController.stream;
  Stream<void> get onChatTabSelected => _chatTabController.stream;

  // Methods to trigger events
  void triggerHomeTabEvent() {
    _homeTabController.add(null);
  }

  void triggerSearchTabEvent() {
    _searchTabController.add(null);
  }

  void triggerNotificationsTabEvent() {
    _notificationsTabController.add(null);
  }

  void triggerChatTabEvent() {
    _chatTabController.add(null);
  }

  void dispose() {
    _homeTabController.close();
    _searchTabController.close();
    _notificationsTabController.close();
    _chatTabController.close();
  }
}

class NavigationNotifier extends StateNotifier<NavigationState> {
  final NavigationEvents events = NavigationEvents();

  NavigationNotifier()
      : super(NavigationState(selectedTab: NavigationTab.home));

  void selectTab(NavigationTab tab) {
    final previousTab = state.selectedTab;
    state = state.copyWith(selectedTab: tab);

    // Only trigger events if this is a new selection (not a re-selection)
    if (previousTab != tab) {
      _triggerTabEvent(tab);
    } else {
      // If it's the same tab (re-selection), still trigger the event
      _triggerTabEvent(tab);
    }
  }

  void _triggerTabEvent(NavigationTab tab) {
    switch (tab) {
      case NavigationTab.home:
        events.triggerHomeTabEvent();
        break;
      case NavigationTab.search:
        events.triggerSearchTabEvent();
        break;
      case NavigationTab.notifications:
        events.triggerNotificationsTabEvent();
        break;
      case NavigationTab.chat:
        events.triggerChatTabEvent();
        break;
    }
  }

  void updateNewNotesCount(int count) {
    state = state.copyWith(newNotesCount: count);
  }

  void resetNewNotesCount() {
    state = state.copyWith(newNotesCount: 0);
  }

  @override
  void dispose() {
    events.dispose();
    super.dispose();
  }
}

final appBottomNavigationBarProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
  return NavigationNotifier();
});

final appBottomNavigationBarEventsProvider = Provider<NavigationEvents>((ref) {
  final notifier = ref.watch(appBottomNavigationBarProvider.notifier);
  return notifier.events;
});
