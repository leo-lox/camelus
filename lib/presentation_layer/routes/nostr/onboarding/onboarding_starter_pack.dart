import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/onboard_conf.dart';
import '../../../../config/palette.dart';
import '../../../../domain_layer/entities/onboarding_user_info.dart';
import '../../../atoms/long_button.dart';
import '../../../atoms/my_profile_picture.dart';
import '../../../atoms/overlapting_avatars.dart';
import '../../../providers/metadata_state_provider.dart';
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

    for (var element in CAMELUS_RECOMMEDED_STARTER_PACKS) {
      followSetsList.add(
        ref.watch(nostrListsFollowStateProvider(element)),
      );
      recommenderMetadataList.add(
        ref.watch(metadataStateProvider(element)),
      );
    }

    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        backgroundColor: Palette.background,
        leading: Container(),
        leadingWidth: 0,
        title: Text("Starter Packs"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: followSetsList.length,
              itemBuilder: (context, followSetsIndex) {
                final followSets = followSetsList[followSetsIndex];

                if (followSets.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                return Column(
                  children: followSets.publicNostrFollowSets.map((nostrSet) {
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
                          Expanded(
                            child: Column(
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
                  }).toList(),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            width: 400,
            height: 40,
            child: longButton(
              name: true ? "next" : "skip",
              onPressed: (() {
                widget.submitCallback([]);
              }),
              inverted: false,
            ),
          ),
          const SizedBox(
            height: 15,
          ),
        ],
      ),
    );
  }
}
