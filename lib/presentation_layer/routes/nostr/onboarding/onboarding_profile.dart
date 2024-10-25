import 'package:camelus/presentation_layer/components/edit_profile.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../domain_layer/entities/onboarding_user_info.dart';
import '../../../atoms/long_button.dart';

class OnboardingProfile extends ConsumerStatefulWidget {
  final OnboardingUserInfo signUpInfo;
  final Function profileCallback;

  const OnboardingProfile({
    super.key,
    required this.signUpInfo,
    required this.profileCallback,
  });

  @override
  ConsumerState<OnboardingProfile> createState() => _OnboardingProfileState();
}

class _OnboardingProfileState extends ConsumerState<OnboardingProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            children: [
              EditProfile(
                initialName: widget.signUpInfo.name ?? '',
                onNameChanged: (value) {
                  widget.signUpInfo.name = value;
                },
                initialPicture: widget.signUpInfo.picture?.bytes,
                pictureCallback: () {},
                initialBanner: widget.signUpInfo.banner?.bytes,
                bannerCallback: () {},
                initalAbout: widget.signUpInfo.about ?? '',
                onAboutChanged: (value) {
                  widget.signUpInfo.about = value;
                },
                initialNip05: widget.signUpInfo.nip05 ?? '',
                onNip05Changed: (value) {
                  widget.signUpInfo.nip05 = value;
                },
                initialWebsite: widget.signUpInfo.website ?? '',
                onWebsiteChanged: (value) {
                  widget.signUpInfo.website = value;
                },
                initalLud06: widget.signUpInfo.lud06,
                onLud06Changed: (value) {
                  widget.signUpInfo.lud06 = value;
                },
                initialLud16: widget.signUpInfo.lud16,
                onLud16Changed: (value) {
                  widget.signUpInfo.lud16 = value;
                },
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
                    widget.profileCallback();
                  }),
                  inverted: true,
                ),
              ),
              const SizedBox(
                height: 15,
              ),
            ],
          ),
        ));
  }
}
