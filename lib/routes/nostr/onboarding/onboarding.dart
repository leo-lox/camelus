import 'package:camelus/models/onboarding_user_info.dart';
import 'package:camelus/routes/nostr/onboarding/onboarding_login.dart';
import 'package:camelus/routes/nostr/onboarding/onboarding_name.dart';
import 'package:camelus/routes/nostr/onboarding/onboarding_page01.dart';
import 'package:camelus/routes/nostr/onboarding/onboarding_picture.dart';
import 'package:camelus/routes/nostr/onboarding/onboarding_summary.dart';
import 'package:flutter/material.dart';
import 'package:camelus/helpers/bip340.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NostrOnboarding extends ConsumerStatefulWidget {
  const NostrOnboarding({super.key});

  @override
  ConsumerState<NostrOnboarding> createState() => _NostrOnboardingState();
}

class _NostrOnboardingState extends ConsumerState<NostrOnboarding>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final PageController _horizontalPageController = PageController(
    initialPage: 1,
    keepPage: true,
  );
  bool horizontalScrollLock = false;

  OnboardingUserInfo signUpInfo = OnboardingUserInfo(
    keyPair: Bip340().generatePrivateKey(),
  );

  void _setupTabLiseners() {
    // listen to changes of tabs
    _tabController.addListener(() {
      if (_tabController.index >= 1) {
        setState(() {
          horizontalScrollLock = true;
        });
      } else {
        setState(() {
          horizontalScrollLock = false;
        });
      }
    });
    _horizontalPageController.addListener(() {
      if (horizontalScrollLock) {
        _horizontalPageController.jumpToPage(1);
      }
    });
  }

  _navigateToLogin() {
    _horizontalPageController.animateToPage(0,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      initialIndex: 0,
      vsync: this,
    );

    _setupTabLiseners();
  }


  _nextTab() {
    _tabController.animateTo(
      _tabController.index + 1,
      curve: Curves.easeInOut,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: PageView(
        controller: _horizontalPageController,
        scrollDirection: Axis.vertical,
        children: [
          const OnboardingLoginPage(),
          TabBarView(
            controller: _tabController,
            children: [
              OnboardingPage01(
                loginCallback: _navigateToLogin,
                registerCallback: () {
                  _tabController.animateTo(
                    1,
                    curve: Curves.easeInOut,
                    duration: const Duration(milliseconds: 500),
                  );
                },
              ),
              OnboardingName(
                userInfo: signUpInfo,
                submitCallback: (_) {
                  _nextTab();
                },
              ),
              OnboardingPicture(
                pictureCallback: () {},
                signUpInfo: signUpInfo,
              ),
              const OnboardingSummary(),
            ],
          ),
        ],
      ),
    );
  }
}
