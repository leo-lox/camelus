import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../config/palette.dart';
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

    return BottomNavigationBar(
      backgroundColor: Palette.background,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      type: BottomNavigationBarType.fixed,
      currentIndex: navigationState.selectedTab.index,
      onTap: (int index) {
        final tab = NavigationTab.values[index];
        notifier.selectTab(tab);

        // Jump to the corresponding page
        pageController.jumpToPage(index);
      },
      items: <BottomNavigationBarItem>[
        _buildHomeItem(navigationState, ref),
        _buildSearchItem(navigationState),
        _buildNotificationsItem(navigationState),
        _buildChatItem(navigationState),
      ],
    );
  }

  BottomNavigationBarItem _buildHomeItem(NavigationState state, WidgetRef ref) {
    final isSelected = state.selectedTab == NavigationTab.home;

    return BottomNavigationBarItem(
      icon: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: <Widget>[
              Icon(
                PhosphorIcons.house(),
                color: isSelected ? Palette.primary : Palette.darkGray,
                size: 23,
              ),
              if (state.newNotesCountHome > 0) IndicatorDot(),
            ],
          ),
        ],
      ),
      tooltip: isSelected ? "scroll to top" : "home",
      label: "home",
    );
  }

  BottomNavigationBarItem _buildSearchItem(NavigationState state) {
    final isSelected = state.selectedTab == NavigationTab.search;

    return BottomNavigationBarItem(
      icon: Icon(
        PhosphorIcons.magnifyingGlass(),
        color: isSelected ? Palette.primary : Palette.darkGray,
        size: 23,
      ),
      label: "search",
      tooltip: "search",
    );
  }

  BottomNavigationBarItem _buildNotificationsItem(NavigationState state) {
    final isSelected = state.selectedTab == NavigationTab.notifications;

    return BottomNavigationBarItem(
      icon: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: <Widget>[
              Icon(
                PhosphorIcons.bell(),
                color: isSelected ? Palette.primary : Palette.darkGray,
                size: 23,
              ),
              if (state.newNotesCountNotifications > 0) IndicatorDot(),
            ],
          ),
        ],
      ),
      label: "notifications",
      tooltip: "notifications",
    );
  }

  BottomNavigationBarItem _buildChatItem(NavigationState state) {
    final isSelected = state.selectedTab == NavigationTab.chat;

    return BottomNavigationBarItem(
      icon: Icon(
        PhosphorIcons.chats(),
        color: isSelected ? Palette.primary : Palette.darkGray,
        size: 23,
      ),
      label: "",
    );
  }
}

class IndicatorDot extends StatelessWidget {
  const IndicatorDot({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Palette.lightGray,
          borderRadius: BorderRadius.circular(50),
        ),
        constraints: const BoxConstraints(
          minWidth: 12,
          minHeight: 12,
        ),
      ),
    );
  }
}
