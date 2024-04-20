import 'package:camelus/presentation_layer/atoms/long_button.dart';
import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class OnboardingPage01 extends ConsumerStatefulWidget {
  Function loginCallback;
  Function registerCallback;

  OnboardingPage01({
    super.key,
    required this.loginCallback,
    required this.registerCallback,
  });
  @override
  ConsumerState<OnboardingPage01> createState() => _OnboardingPage01State();
}

class _OnboardingPage01State extends ConsumerState<OnboardingPage01> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(
              flex: 10,
            ),
            Text(
              "welcome to",
              style: TextStyle(
                color: Palette.extraLightGray,
                fontSize: MediaQuery.of(context).size.width / 22,
              ),
            ),
            Text(
              "camelus",
              style: TextStyle(
                color: Palette.white,
                fontSize: MediaQuery.of(context).size.width / 7,
                fontFamily: 'Poppins',
              ),
            ),
            const Spacer(
              flex: 10,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              width: 400,
              height: 40,
              child: longButton(
                name: "join the conversation",
                onPressed: (() {
                  widget.registerCallback();
                }),
                inverted: true,
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              width: 400,
              height: 40,
              child: longButton(
                name: "login",
                onPressed: (() {
                  widget.loginCallback();
                }),
                inverted: false,
              ),
            ),
            const Spacer(
              flex: 2,
            ),
          ],
        ),
      ),
    );
  }
}
