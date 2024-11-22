import 'package:camelus/presentation_layer/atoms/my_profile_picture.dart';
import 'package:camelus/presentation_layer/providers/metadata_state_provider.dart';
import 'package:camelus/presentation_layer/providers/nostr_list_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/onboard_conf.dart';
import '../../../../config/palette.dart';
import '../../../../domain_layer/entities/onboarding_user_info.dart';
import '../../../../domain_layer/entities/user_metadata.dart';
import '../../../atoms/overlapting_avatars.dart';
import '../../../providers/nostr_lists_follow_state_provider.dart';

class OnboardingStarterPack extends ConsumerStatefulWidget {
  final Function(List<String>) submitCallback;

  final OnboardingUserInfo userInfo;

  const OnboardingStarterPack({
    super.key,
    required this.submitCallback,
    required this.userInfo,
  });
  @override
  ConsumerState<OnboardingStarterPack> createState() =>
      _OnboardingStarterPackState();
}

class _OnboardingStarterPackState extends ConsumerState<OnboardingStarterPack> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final List<NostrListsFollowState> followSetsList = [];
    final List<MetadataState> recommenderMetadataList = [];

    CAMELUS_RECOMMEDED_STARTER_PACKS.forEach((element) {
      followSetsList.add(
        ref.watch(nostrListsFollowStateProvider(element)),
      );
      recommenderMetadataList.add(
        ref.watch(metadataStateProvider(element)),
      );
    });

    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        backgroundColor: Palette.background,
        leading: Container(),
        leadingWidth: 0,
        title: Text("Starter Packs"),
      ),
      body: ListView.builder(
        itemCount: followSetsList.length,
        itemBuilder: (context, followSetsIndex) {
          final followSets = followSetsList[followSetsIndex];

          return followSets.isLoading
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  //physics: ,
                  itemCount: followSets.publicNostrFollowSets.length,
                  itemBuilder: (context, index) {
                    final nostrSet = followSets.publicNostrFollowSets[index];
                    if (nostrSet.elements.isEmpty) return Container();
                    return ListTile(
                      title: Row(
                        children: [
                          if (nostrSet.image != null)
                            Image.network(nostrSet.image!,
                                width: 50, height: 50),
                          if (nostrSet.image == null)
                            Image.asset("assets/images/list_placeholder.png",
                                width: 50, height: 50),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nostrSet.title ?? nostrSet.name),
                              Text(
                                "by ${recommenderMetadataList[followSetsIndex].userMetadata?.name ?? "Unknown"}",
                                style: TextStyle(
                                  color: Palette.gray,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: SizedBox(
                        width: 150,
                        child: OverlappingAvatars(
                          avatars: nostrSet.elements
                              .take(5)
                              .map((e) => UserImage(
                                    imageUrl: ref
                                        .watch(metadataStateProvider(e.value))
                                        .userMetadata
                                        ?.picture,
                                    pubkey: e.value,
                                  ))
                              .toList(),
                        ),
                      ),
                      onTap: () {},
                    );
                  },
                );
        },
      ),
    );
  }
}


//PersonCard