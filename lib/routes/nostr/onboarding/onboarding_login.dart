import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class OnboardingLoginPage extends ConsumerStatefulWidget {
  const OnboardingLoginPage({Key? key}) : super(key: key);
  @override
  ConsumerState<OnboardingLoginPage> createState() =>
      _OnboardingLoginPageState();
}

class _OnboardingLoginPageState extends ConsumerState<OnboardingLoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      body: Text("login"),
    );
  }
}
