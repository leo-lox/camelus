import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/onboarding_provider.dart';
import 'onboarding_done.dart';
import 'onboarding_invited_by.dart';
import 'onboarding_login.dart';
import 'onboarding_login_amber.dart';
import 'onboarding_login_select.dart';
import 'onboarding_name.dart';
import 'onboarding_page01.dart';
import 'onboarding_picture.dart';
import 'onboarding_profile.dart';
import 'onboarding_starter_pack.dart';

class NostrOnboarding extends ConsumerStatefulWidget {
  const NostrOnboarding({
    super.key,
  });

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
        //todo: check implications
        // setState(() {
        //   pageLock = true;
        // });
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
              if (signUpInfo.invitedByPubkey == null)
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
              if (signUpInfo.invitedByPubkey != null)
                OnboardingInvitedBy(
                  nextCallback: () {
                    _nextTab();
                  },
                  userInfo: signUpInfo,
                  invitedByPubkey: signUpInfo.invitedByPubkey!,
                  inviteListName: signUpInfo.inviteListName!,
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
              OnboardingStarterPack(
                invitedByPubkey: signUpInfo.invitedByPubkey,
                submitCallback: (followPubkeys) {
                  signUpInfo.followPubkeys = followPubkeys;
                  _nextTab();
                },
                userInfo: signUpInfo,
              ),
              // OnboardingFollowGraph(
              //   submitCallback: (followPubkeys) {
              //     signUpInfo.followPubkeys = followPubkeys;
              //     _nextTab();
              //   },
              //   userInfo: signUpInfo,
              // ),
              OnboardingDone(submitCallback: () {}, userInfo: signUpInfo)
            ],
          ),
        ],
      ),
    );
  }
}
