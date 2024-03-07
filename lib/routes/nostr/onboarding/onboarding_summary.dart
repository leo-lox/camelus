import 'package:camelus/components/edit_profile.dart';
import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class OnboardingSummary extends ConsumerStatefulWidget {
  const OnboardingSummary({Key? key}) : super(key: key);

@override
  ConsumerState<OnboardingSummary> createState() => _OnboardingSummaryState();
}

class _OnboardingSummaryState extends ConsumerState<OnboardingSummary> {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      body: EditProfile(),
    );
  
 

  }
}