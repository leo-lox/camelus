import 'package:camelus/presentation_layer/atoms/my_profile_picture.dart';
import 'package:camelus/presentation_layer/providers/metadata_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/palette.dart';
import '../../../../domain_layer/entities/onboarding_user_info.dart';

class OnboardingStarterPack extends ConsumerStatefulWidget {
  final Function(List<String>) submitCallback;

  final OnboardingUserInfo userInfo;

  // default schould be set to camelus recommendations,
  // changes on invite deeplink
  final String invitedByPubkeyStarterPack;
  final String? starterPackName;

  const OnboardingStarterPack({
    super.key,
    required this.submitCallback,
    required this.userInfo,
    required this.invitedByPubkeyStarterPack,
    this.starterPackName,
  });
  @override
  ConsumerState<OnboardingStarterPack> createState() =>
      _OnboardingStarterPackState();
}

class _OnboardingStarterPackState extends ConsumerState<OnboardingStarterPack> {
  @override
  Widget build(BuildContext context) {
    final metadataP = ref
        .watch(metadataStateProvider(widget.invitedByPubkeyStarterPack))
        .userMetadata;
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        backgroundColor: Palette.background,
        leading: UserImage(
          imageUrl: metadataP?.picture,
          pubkey: widget.invitedByPubkeyStarterPack,
        ),
        title: Text("${metadataP?.name} Starter Packs"),
      ),
      body: Text("Hello World"),
    );
  }
}


//PersonCard