import 'package:camelus/presentation_layer/components/edit_profile.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class OnboardingProfile extends ConsumerStatefulWidget {
  const OnboardingProfile({super.key});

  @override
  ConsumerState<OnboardingProfile> createState() => _OnboardingProfileState();
}

class _OnboardingProfileState extends ConsumerState<OnboardingProfile> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: EditProfile(),
    );
  }
}
