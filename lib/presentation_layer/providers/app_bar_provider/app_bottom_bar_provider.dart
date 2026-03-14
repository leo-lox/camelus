import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

enum NavigationTab {
  home,
  search,

  notifications,
  chat,
  wallet,
}

class NavigationState {
  final NavigationTab selectedTab;
  final int newNotesCountHome;
  final int newNotesCountNotifications;

  NavigationState({
    required this.selectedTab,
    this.newNotesCountHome = 0,
    this.newNotesCountNotifications = 0,
  });

  NavigationState copyWith({
    NavigationTab? selectedTab,
    int? newNotesCountHome,
    int? newNotesCountNotifications,
  }) {
    return NavigationState(
      selectedTab: selectedTab ?? this.selectedTab,
      newNotesCountHome: newNotesCountHome ?? this.newNotesCountHome,
      newNotesCountNotifications:
          newNotesCountNotifications ?? this.newNotesCountNotifications,
    );
  }
}

class NavigationEvents {
  // Stream controllers for specific tab events
  final _homeTabController = StreamController<void>.broadcast();
  final _searchTabController = StreamController<void>.broadcast();
  final _notificationsTabController = StreamController<void>.broadcast();
  final _chatTabController = StreamController<void>.broadcast();
  final _walletTabController = StreamController<void>.broadcast();

  // Expose streams for listeners
  Stream<void> get onHomeTabSelected => _homeTabController.stream;
  Stream<void> get onSearchTabSelected => _searchTabController.stream;
  Stream<void> get onNotificationsTabSelected =>
      _notificationsTabController.stream;
  Stream<void> get onChatTabSelected => _chatTabController.stream;
  Stream<void> get onWalletTabSelected => _walletTabController.stream;

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

  void triggerWalletTabEvent() {
    _walletTabController.add(null);
  }

  void dispose() {
    _homeTabController.close();
    _searchTabController.close();
    _notificationsTabController.close();
    _chatTabController.close();
    _walletTabController.close();
  }
}

class NavigationNotifier extends Notifier<NavigationState> {
  final NavigationEvents events = NavigationEvents();

  @override
  NavigationState build() {
    // Register dispose callback
    ref.onDispose(() {
      events.dispose();
    });

    return NavigationState(selectedTab: NavigationTab.home);
  }

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
      case NavigationTab.wallet:
        events.triggerWalletTabEvent();
        break;
    }
  }

  void updateNewNotesCountHome(int count) {
    state = state.copyWith(newNotesCountHome: count);
  }

  void resetNewNotesCountHome() {
    state = state.copyWith(newNotesCountHome: 0);
  }

  void updateNewNotesCountNotifications(int count) {
    state = state.copyWith(newNotesCountNotifications: count);
  }

  void resetNewNotesCountNotifications() {
    state = state.copyWith(newNotesCountNotifications: 0);
  }
}

final appBottomNavigationBarProvider =
    NotifierProvider<NavigationNotifier, NavigationState>(
      NavigationNotifier.new,
    );

final appBottomNavigationBarEventsProvider = Provider<NavigationEvents>((ref) {
  final notifier = ref.watch(appBottomNavigationBarProvider.notifier);
  return notifier.events;
});
