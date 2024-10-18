import 'package:camelus/presentation_layer/atoms/long_button.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/domain_layer/entities/onboarding_user_info.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class OnboardingFollowGraph extends ConsumerStatefulWidget {
  final Function submitCallback;

  OnboardingUserInfo userInfo;

  OnboardingFollowGraph({
    super.key,
    required this.submitCallback,
    required this.userInfo,
  });
  @override
  ConsumerState<OnboardingFollowGraph> createState() =>
      _OnboardingFollowGraphState();
}

class _OnboardingFollowGraphState extends ConsumerState<OnboardingFollowGraph> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(
              flex: 20,
            ),
            const SizedBox(
              height: 10,
            ),
            const Spacer(
              flex: 1,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              width: 400,
              height: 40,
              child: longButton(
                name: "next",
                onPressed: (() {
                  widget.submitCallback();
                }),
                inverted: true,
              ),
            ),
            const SizedBox(
              height: 15,
            ),
          ],
        ),
      ),
    );
  }
}
