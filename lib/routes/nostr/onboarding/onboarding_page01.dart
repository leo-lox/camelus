import 'dart:developer';

import 'package:camelus/atoms/long_button.dart';
import 'package:camelus/config/palette.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class OnboardingPage01 extends ConsumerStatefulWidget {
  const OnboardingPage01({Key? key}) : super(key: key);
  @override
  ConsumerState<OnboardingPage01> createState() => _OnboardingPage01State();
}

class _OnboardingPage01State extends ConsumerState<OnboardingPage01> {
  @override
  Widget build(BuildContext context) {
    return Center(
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
            width: 400,
            height: 40,
            child: longButton(
              name: "join the conversation",
              onPressed: (() {}),
              inverted: true,
            ),
          ),
          const SizedBox(
            height: 30,
          ),
          Container(
            width: 400,
            height: 40,
            child: longButton(
              name: "login",
              onPressed: (() {
                log("login");
              }),
              inverted: false,
            ),
          ),
          const Spacer(
            flex: 2,
          ),
        ],
      ),
    );
  }
}
