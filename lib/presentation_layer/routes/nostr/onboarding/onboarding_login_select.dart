import 'package:flutter/material.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../config/palette.dart';
import '../../../atoms/long_button.dart';

class OnboardingLoginSelectPage extends ConsumerStatefulWidget {
  final Function onPressedSeedPhraseLogin;
  final Function onPressedAmberLogin;

  const OnboardingLoginSelectPage({
    super.key,
    required this.onPressedSeedPhraseLogin,
    required this.onPressedAmberLogin,
  });
  @override
  ConsumerState<OnboardingLoginSelectPage> createState() =>
      _OnboardingLoginSelectPageState();
}

class _OnboardingLoginSelectPageState
    extends ConsumerState<OnboardingLoginSelectPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      backgroundColor: Palette.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        // input for the user to enter their private key, should be visible on a dark background.
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                width: MediaQuery.of(context).size.width,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "login",
                      style: TextStyle(
                        color: Palette.white,
                        fontSize: 40,
                        fontFamily: "Poppins",
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(
                flex: 1,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 40,
                child: longButton(
                  name: "amber login",
                  inverted: false,
                  onPressed: () => widget.onPressedAmberLogin(),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 40,
                child: longButton(
                  name: "seed phrase login",
                  inverted: false,
                  onPressed: () => widget.onPressedSeedPhraseLogin(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
