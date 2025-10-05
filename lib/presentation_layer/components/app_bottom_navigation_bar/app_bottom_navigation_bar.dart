import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../providers/app_bar_provider/app_bottom_bar_provider.dart';

class AppBottomNavigationBar extends ConsumerWidget {
  final PageController pageController;

  const AppBottomNavigationBar({
    super.key,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(appBottomNavigationBarProvider);
    final notifier = ref.read(appBottomNavigationBarProvider.notifier);

    return NavigationBar(
      height: kBottomNavigationBarHeight,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      selectedIndex: navigationState.selectedTab.index,
      indicatorColor: Colors.transparent,
      onDestinationSelected: (int index) {
        final tab = NavigationTab.values[index];
        notifier.selectTab(tab);

        // Jump to the corresponding page
        pageController.jumpToPage(index);
      },
      destinations: <NavigationDestination>[
        _buildHomeItem(navigationState, ref),
        _buildSearchItem(navigationState),
        _buildNotificationsItem(navigationState),
        //_buildChatItem(navigationState),
      ],
    );
  }

  NavigationDestination _buildHomeItem(NavigationState state, WidgetRef ref) {
    final isSelected = state.selectedTab == NavigationTab.home;

    return NavigationDestination(
      icon: Builder(builder: (context) {
        final child = Icon(
          PhosphorIcons.house(),
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
          size: 23,
        );

        if (state.newNotesCountHome > 0) {
          return Badge(
            child: child,
          );
        }

        return child;
      }),
      tooltip: isSelected ? "scroll to top" : "home",
      label: "home",
    );
  }

  NavigationDestination _buildSearchItem(NavigationState state) {
    final isSelected = state.selectedTab == NavigationTab.search;

    return NavigationDestination(
      icon: Builder(builder: (context) {
        return Icon(
          PhosphorIcons.magnifyingGlass(),
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
          size: 23,
        );
      }),
      label: "search",
      tooltip: "search",
    );
  }

  NavigationDestination _buildNotificationsItem(NavigationState state) {
    final isSelected = state.selectedTab == NavigationTab.notifications;

    return NavigationDestination(
      icon: Builder(builder: (context) {
        final child = Icon(
          PhosphorIcons.bell(),
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
          size: 23,
        );

        if (state.newNotesCountNotifications > 0) {
          return Badge(
            child: child,
          );
        }

        return child;
      }),
      label: "notifications",
      tooltip: "notifications",
    );
  }
}
