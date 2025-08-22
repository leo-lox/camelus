import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/wallet/sheet_send_receive.dart';
import 'wallet_dashboard.dart';

import 'wallet_qr_scan.dart';

// Navigation state class
class WalletNavigationState {
  final int selectedIndex;
  final int dashboardIndex;
  final PageController mainPageController;
  final PageController dashboardPageController;
  final StreamController<int> pageChangeController;

  const WalletNavigationState({
    required this.selectedIndex,
    required this.dashboardIndex,
    required this.mainPageController,
    required this.dashboardPageController,
    required this.pageChangeController,
  });

  WalletNavigationState copyWith({
    int? selectedIndex,
    int? dashboardIndex,
    PageController? mainPageController,
    PageController? dashboardPageController,
    StreamController<int>? pageChangeController,
  }) {
    return WalletNavigationState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      dashboardIndex: dashboardIndex ?? this.dashboardIndex,
      mainPageController: mainPageController ?? this.mainPageController,
      dashboardPageController:
          dashboardPageController ?? this.dashboardPageController,
      pageChangeController: pageChangeController ?? this.pageChangeController,
    );
  }
}

// StateNotifier for managing navigation
class WalletNavigationNotifier extends StateNotifier<WalletNavigationState> {
  WalletNavigationNotifier()
      : super(WalletNavigationState(
          selectedIndex: 0,
          dashboardIndex:
              1, // Start at dashboard (index 1 in vertical PageView)
          mainPageController: PageController(initialPage: 0),
          dashboardPageController: PageController(initialPage: 1),
          pageChangeController: StreamController<int>.broadcast(),
        ));

  // Route mappings
  final Map<String, int> _routeToIndex = {
    '/wallet/qr-scan': 0,
    '/wallet/dashboard': 0,
    '/wallet/receive': 1,
    '/wallet/mints': 2,
  };

  final Map<int, String> _indexToRoute = {
    0: '/wallet/dashboard',
    1: '/wallet/receive',
    2: '/wallet/mints',
  };

  // Change main page (horizontal navigation)
  void changeMainPage(int index,
      {bool animate = true, bool updateRoute = true}) {
    if (index == state.selectedIndex) return;

    state = state.copyWith(selectedIndex: index);
    state.pageChangeController.add(index);

    if (animate) {
      state.mainPageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      state.mainPageController.jumpToPage(index);
    }
  }

  // Change dashboard page (vertical navigation)
  void changeDashboardPage(int index, {bool animate = true}) {
    if (index == state.dashboardIndex) return;

    state = state.copyWith(dashboardIndex: index);

    if (animate) {
      state.dashboardPageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      state.dashboardPageController.jumpToPage(index);
    }
  }

  // Navigate by route name
  void navigateToRoute(String route, BuildContext context) {
    final index = _routeToIndex[route];
    if (index != null) {
      if (route == '/wallet/qr-scan') {
        // Special case: navigate to QR scan (dashboard index 0)
        changeMainPage(0, updateRoute: false);
        changeDashboardPage(0);
      } else {
        changeMainPage(index);
        if (index == 0) {
          // Ensure we're on dashboard when navigating to main dashboard
          changeDashboardPage(1);
        }
      }
      Navigator.pushReplacementNamed(context, route);
    }
  }

  // Handle page swipe from PageView
  void onMainPageSwipe(int index) {
    state = state.copyWith(selectedIndex: index);
    state.pageChangeController.add(index);
  }

  // Handle dashboard page swipe
  void onDashboardPageSwipe(int index) {
    state = state.copyWith(dashboardIndex: index);
  }

  // Get current route
  String get currentRoute {
    if (state.selectedIndex == 0 && state.dashboardIndex == 0) {
      return '/wallet/qr-scan';
    }
    return _indexToRoute[state.selectedIndex] ?? '/wallet/dashboard';
  }

  @override
  void dispose() {
    state.mainPageController.dispose();
    state.dashboardPageController.dispose();
    state.pageChangeController.close();
    super.dispose();
  }
}

// Provider
final walletNavigationProvider =
    StateNotifierProvider<WalletNavigationNotifier, WalletNavigationState>(
        (ref) {
  return WalletNavigationNotifier();
});

// Convenience providers for easy access
final selectedIndexProvider = Provider<int>((ref) {
  return ref.watch(walletNavigationProvider).selectedIndex;
});

final dashboardIndexProvider = Provider<int>((ref) {
  return ref.watch(walletNavigationProvider).dashboardIndex;
});

final mainPageControllerProvider = Provider<PageController>((ref) {
  return ref.watch(walletNavigationProvider).mainPageController;
});

final dashboardPageControllerProvider = Provider<PageController>((ref) {
  return ref.watch(walletNavigationProvider).dashboardPageController;
});

final pageChangeStreamProvider = Provider<Stream<int>>((ref) {
  return ref
      .watch(walletNavigationProvider)
      .pageChangeController
      .stream
      .asBroadcastStream();
});

class WalletNavigation extends ConsumerStatefulWidget {
  const WalletNavigation({super.key, required this.title});

  final String title;

  @override
  ConsumerState<WalletNavigation> createState() => _WalletNavigationState();
}

class _WalletNavigationState extends ConsumerState<WalletNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;

  void _onItemLongPress(BuildContext myContext) {
    final navigationState = ref.read(walletNavigationProvider);
    final currentIndex = navigationState.selectedIndex;

    showModalBottomSheet(
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      context: myContext,
      builder: (context) => WalletSheetSendReceive(
        isHideBottomNavBar: (isHideBottomNavBar) {
          isHideBottomNavBar
              ? animationController.forward()
              : animationController.reverse();
        },
        pageChangeStream: ref.read(pageChangeStreamProvider),
      ),
    ).then((_) {
      // Restore previous state
      ref.read(walletNavigationProvider.notifier).changeMainPage(currentIndex);
    });
  }

  void _onItemTapped(int index, BuildContext myContext) {
    ref.read(walletNavigationProvider.notifier).changeMainPage(index);
  }

  void _onMainPageSwipe(int index) {
    ref.read(walletNavigationProvider.notifier).onMainPageSwipe(index);
  }

  void _onDashboardPageSwipe(int index) {
    ref.read(walletNavigationProvider.notifier).onDashboardPageSwipe(index);
  }

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    animationController.forward();

    // current route from navigator
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentRoute = ModalRoute.of(context)?.settings.name;
      if (currentRoute != null) {
        ref
            .read(walletNavigationProvider.notifier)
            .navigateToRoute(currentRoute, context);
      }
    });
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigationState = ref.watch(walletNavigationProvider);
    final selectedIndex = ref.watch(selectedIndexProvider);
    final mainPageController = ref.watch(mainPageControllerProvider);
    final dashboardPageController = ref.watch(dashboardPageControllerProvider);

    return PageView(
      scrollDirection: Axis.horizontal,
      controller: mainPageController,
      onPageChanged: _onMainPageSwipe,
      physics: const BouncingScrollPhysics(),
      children: [
        PageView(
          scrollDirection: Axis.vertical,
          controller: dashboardPageController,
          onPageChanged: _onDashboardPageSwipe,
          children: [
            WalletQrScan(),
            WalletDashboard(),
          ],
        ),
      ],
    );
  }
}
