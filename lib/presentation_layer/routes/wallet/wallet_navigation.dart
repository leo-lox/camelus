import 'dart:async';

import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';

import '../../components/app_bottom_navigation_bar/app_bottom_navigation_bar.dart';
import '../../components/wallet/sheet_send_receive.dart';
import 'wallet_dashboard.dart';
import 'wallet_mints.dart';
import 'wallet_qr_scan.dart';
import 'wallet_receive.dart';

class WalletNavigation extends StatefulWidget {
  const WalletNavigation({super.key, required this.title});

  final String title;

  @override
  State<WalletNavigation> createState() => _WalletNavigationState();
}

class _WalletNavigationState extends State<WalletNavigation>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController animationController;

  late final PageController dashboardPageViewController;

  late final PageController mainPageViewController;

  final StreamController<int> _pageChangeController =
      StreamController<int>.broadcast();

  void _onItemLongPress(myContext) {
    final previusIndex = _selectedIndex;
    showModalBottomSheet(
      backgroundColor: Colors.black,
      //anchorPoint: Offset(50, 20),
      //useRootNavigator: false,
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
        pageChangeStream: _pageChangeController.stream.asBroadcastStream(),
      ),
    ).then(
      (_) {
        setState(() {
          _selectedIndex = previusIndex;
        });
      },
    );
  }

  void _onItemTapped(
    int index,
    myContext,
  ) {
    changePage(index);
  }

  void _onPageSwipe(int index) {
    changePage(index - 1);
  }

  void changePage(int index) {
    _pageChangeController.add(index);
    switch (index) {
      case 0:
        {
          //Navigator.pushNamed(context, '/home');
          setState(() {
            _selectedIndex = index;
          });
          _pageChangeController.add(index);

          break;
        }

      case 1:
        {
          //Navigator.pushNamed(context, '/receive');
          setState(() {
            _selectedIndex = index;
          });
          _pageChangeController.add(index);

          break;
        }
      case 2:
        {
          setState(() {
            _selectedIndex = index;
          });
          _pageChangeController.add(index);
          break;
        }
      case 3:
        {
          setState(() {
            _selectedIndex = index;
          });
          _pageChangeController.add(index);
          break;
        }
    }
  }

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));

    dashboardPageViewController = PageController();

    mainPageViewController = PageController();

    animationController.forward();
  }

  @override
  void dispose() {
    animationController.dispose();
    dashboardPageViewController.dispose();
    mainPageViewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Palette.background,
        appBar: null,
        body: PageView(
          scrollDirection: Axis.horizontal,
          controller: mainPageViewController,
          onPageChanged: _onPageSwipe,
          physics: const BouncingScrollPhysics(),
          children: [
            PageView(
                scrollDirection: Axis.vertical,
                controller: dashboardPageViewController,
                children: [
                  WalletQrScan(),
                  WalletDashboard(),
                ]),
            WalletReceive(),
            WalletMints(),
          ],
        ),
        bottomNavigationBar: AppBottomNavigationBar(
          pageController: mainPageViewController, // todo: replace with actual
        ));
  }
}
