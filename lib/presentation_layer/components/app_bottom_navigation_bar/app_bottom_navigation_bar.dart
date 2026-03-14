import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../providers/app_bar_provider/app_bottom_bar_provider.dart';
import '../../providers/messaging/dm_conversations_provider.dart';

class AppBottomNavigationBar extends ConsumerWidget {
  const AppBottomNavigationBar({super.key});

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

        switch (index) {
          case 0:
            {
              context.go('/home');
              break;
            }

          case 1:
            {
              context.go('/search');
              break;
            }
          case 2:
            {
              context.go('/notifications');
              break;
            }
          case 3:
            {
              context.go('/messages');
              break;
            }
        }
      },
      destinations: <NavigationDestination>[
        _buildHomeItem(context, navigationState, ref),
        _buildSearchItem(context, navigationState),
        _buildNotificationsItem(context, navigationState),
        _buildMessagesItem(context, navigationState, ref),
      ],
    );
  }

  NavigationDestination _buildHomeItem(
    BuildContext context,
    NavigationState state,
    WidgetRef ref,
  ) {
    final isSelected = state.selectedTab == NavigationTab.home;

    return NavigationDestination(
      icon: Builder(
        builder: (context) {
          final child = Icon(
            PhosphorIcons.house(),
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
            size: 23,
          );

          if (state.newNotesCountHome > 0) {
            return Badge(child: child);
          }

          return child;
        },
      ),
      tooltip: isSelected
          ? AppLocalizations.of(context)!.scrollToTop
          : AppLocalizations.of(context)!.home,
      label: AppLocalizations.of(context)!.home,
    );
  }

  NavigationDestination _buildSearchItem(
    BuildContext context,
    NavigationState state,
  ) {
    final isSelected = state.selectedTab == NavigationTab.search;

    return NavigationDestination(
      icon: Builder(
        builder: (context) {
          return Icon(
            PhosphorIcons.magnifyingGlass(),
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
            size: 23,
          );
        },
      ),
      label: AppLocalizations.of(context)!.search,
      tooltip: AppLocalizations.of(context)!.search,
    );
  }

  NavigationDestination _buildNotificationsItem(
    BuildContext context,
    NavigationState state,
  ) {
    final isSelected = state.selectedTab == NavigationTab.notifications;

    return NavigationDestination(
      icon: Builder(
        builder: (context) {
          final child = Icon(
            PhosphorIcons.bell(),
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
            size: 23,
          );

          if (state.newNotesCountNotifications > 0) {
            return Badge(child: child);
          }

          return child;
        },
      ),
      label: AppLocalizations.of(context)!.notifications,
      tooltip: AppLocalizations.of(context)!.notifications,
    );
  }

  NavigationDestination _buildMessagesItem(
    BuildContext context,
    NavigationState state,
    WidgetRef ref,
  ) {
    final isSelected = state.selectedTab == NavigationTab.chat;
    final unreadCount = ref.watch(dmUnreadCountProvider);

    return NavigationDestination(
      icon: Builder(
        builder: (context) {
          final child = Icon(
            PhosphorIcons.chatCircle(),
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
            size: 23,
          );

          final count = unreadCount.value ?? 0;
          if (count > 0) {
            return Badge(
              label: Text(count > 99 ? '99+' : count.toString()),
              child: child,
            );
          }

          return child;
        },
      ),
      label: 'Messages',
      tooltip: 'Messages',
    );
  }
}
