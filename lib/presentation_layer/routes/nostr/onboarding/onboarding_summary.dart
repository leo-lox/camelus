import 'package:camelus/presentation_layer/components/edit_profile.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class OnboardingSummary extends ConsumerStatefulWidget {
  const OnboardingSummary({super.key});

  @override
  ConsumerState<OnboardingSummary> createState() => _OnboardingSummaryState();
}

class _OnboardingSummaryState extends ConsumerState<OnboardingSummary> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: EditProfile(),
    );
  }
}
