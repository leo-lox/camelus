import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../atoms/long_button.dart';
import '../../../components/responsive_center.dart';

class OnboardingLoginSelectPage extends ConsumerStatefulWidget {
  final Function onPressedSeedPhraseLogin;
  final Function onPressedAmberLogin;
  final Function onPressedBunkerLogin;
  final Function? onPressedBack;

  const OnboardingLoginSelectPage({
    super.key,
    required this.onPressedSeedPhraseLogin,
    required this.onPressedAmberLogin,
    required this.onPressedBunkerLogin,
    this.onPressedBack,
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
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 600,
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.onPressedBack != null)
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        PhosphorIcons.arrowLeft(),
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: () => widget.onPressedBack!(),
                    ),
                  ],
                ),
              if (widget.onPressedBack == null) const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "login",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 40,
                        fontFamily: "Poppins",
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),
              if (Platform.isAndroid)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: longButton(
                      name: "amber login",
                      inverted: false,
                      onPressed: () => widget.onPressedAmberLogin(),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: longButton(
                    name: "seed phrase login",
                    inverted: false,
                    onPressed: () => widget.onPressedSeedPhraseLogin(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: longButton(
                    name: "bunker login",
                    inverted: false,
                    onPressed: () => widget.onPressedBunkerLogin(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
