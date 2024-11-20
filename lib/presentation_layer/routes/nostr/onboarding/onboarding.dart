import 'package:camelus/presentation_layer/providers/onboarding_provider.dart';
import 'package:camelus/presentation_layer/routes/nostr/onboarding/onboarding_done.dart';
import 'package:camelus/presentation_layer/routes/nostr/onboarding/onboarding_follow_graph/onboarding_follow_graph.dart';
import 'package:camelus/presentation_layer/routes/nostr/onboarding/onboarding_login.dart';
import 'package:camelus/presentation_layer/routes/nostr/onboarding/onboarding_login_amber.dart';
import 'package:camelus/presentation_layer/routes/nostr/onboarding/onboarding_name.dart';
import 'package:camelus/presentation_layer/routes/nostr/onboarding/onboarding_page01.dart';
import 'package:camelus/presentation_layer/routes/nostr/onboarding/onboarding_picture.dart';
import 'package:camelus/presentation_layer/routes/nostr/onboarding/onboarding_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding_login_select.dart';

class NostrOnboarding extends ConsumerStatefulWidget {
  const NostrOnboarding({super.key});

  @override
  ConsumerState<NostrOnboarding> createState() => _NostrOnboardingState();
}

class _NostrOnboardingState extends ConsumerState<NostrOnboarding>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _loginTabController;

  final PageController _horizontalPageController = PageController(
    initialPage: 1,
    keepPage: true,
  );
  bool horizontalScrollLock = false;
  bool pageLock = false;

  bool pageLockLogin = false;

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

      if (_tabController.index == 4 || _tabController.index == 5) {
        setState(() {
          pageLock = true;
        });
      } else {
        setState(() {
          pageLock = false;
        });
      }
      if (_tabController.index != 1) {
        FocusScope.of(context).unfocus();
      }
    });

    _loginTabController.addListener(() {
      if (_loginTabController.index == 1) {
        setState(() {
          horizontalScrollLock = true;
        });
      } else {
        setState(() {
          horizontalScrollLock = false;
        });
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
      length: 6,
      initialIndex: 0,
      vsync: this,
    );

    _loginTabController = TabController(
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
    final signUpInfo = ref.watch(onboardingProvider).signUpInfo;

    return SafeArea(
      child: PageView(
        controller: _horizontalPageController,
        scrollDirection: Axis.vertical,
        physics: horizontalScrollLock
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        children: [
          TabBarView(
            controller: _loginTabController,
            physics:
                pageLockLogin ? const NeverScrollableScrollPhysics() : null,
            children: [
              OnboardingLoginSelectPage(
                onPressedAmberLogin: () {
                  _loginTabController.animateTo(
                    2,
                    curve: Curves.easeInOut,
                    duration: const Duration(milliseconds: 500),
                  );
                },
                onPressedSeedPhraseLogin: () {
                  _loginTabController.animateTo(
                    1,
                    curve: Curves.easeInOut,
                    duration: const Duration(milliseconds: 500),
                  );
                },
              ),
              OnboardingLoginPage(),
              OnboardingLoginAmberPage(),
            ],
          ),
          TabBarView(
            controller: _tabController,
            physics: pageLock ? const NeverScrollableScrollPhysics() : null,
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
                pictureCallback: () {
                  _nextTab();
                },
                signUpInfo: signUpInfo,
              ),
              OnboardingProfile(
                profileCallback: () {
                  _nextTab();
                },
                signUpInfo: signUpInfo,
              ),
              OnboardingFollowGraph(
                submitCallback: (followPubkeys) {
                  signUpInfo.followPubkeys = followPubkeys;
                  _nextTab();
                },
                userInfo: signUpInfo,
              ),
              OnboardingDone(submitCallback: () {}, userInfo: signUpInfo)
            ],
          ),
        ],
      ),
    );
  }
}
