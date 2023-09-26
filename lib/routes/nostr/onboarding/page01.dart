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
    return Container(
      child: Text("Page 01"),
    );
  }
}
