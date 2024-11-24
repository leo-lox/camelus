import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../config/onboard_conf.dart';
import '../../../../config/palette.dart';
import '../../../../domain_layer/entities/nostr_list.dart';
import '../../../../domain_layer/entities/onboarding_user_info.dart';
import '../../../atoms/long_button.dart';
import '../../../atoms/my_profile_picture.dart';
import '../../../atoms/overlapting_avatars.dart';
import '../../../providers/metadata_state_provider.dart';
import '../../../providers/nostr_lists_follow_state_provider.dart';

class OnboardingStarterPack extends ConsumerStatefulWidget {
  final Function(List<String>) submitCallback;

  final OnboardingUserInfo userInfo;
  final String? invitedByPubkey;

  const OnboardingStarterPack({
    super.key,
    required this.submitCallback,
    required this.userInfo,
    this.invitedByPubkey,
  });
  @override
  ConsumerState<OnboardingStarterPack> createState() =>
      _OnboardingStarterPackState();
}

class _OnboardingStarterPackState extends ConsumerState<OnboardingStarterPack> {
  late List<String> selectedPubkeys;

  final List<String> recommendedStarterPacks = CAMELUS_RECOMMEDED_STARTER_PACKS;

  @override
  void initState() {
    super.initState();
    selectedPubkeys = widget.userInfo.followPubkeys;

    if (widget.invitedByPubkey != null && widget.invitedByPubkey!.isNotEmpty) {
      // check if its already in the list
      if (recommendedStarterPacks.contains(widget.invitedByPubkey!)) {
        return;
      }

      // add to beginning of list
      recommendedStarterPacks.insert(0, widget.invitedByPubkey!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<NostrListsFollowState> followSetsList = [];
    final List<MetadataState> recommenderMetadataList = [];

    for (var element in recommendedStarterPacks) {
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
        title: widget.invitedByPubkey == null
            ? Text("Starter Packs")
            : Text("Additional Starter Packs"),
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
                                Text.rich(
                                  overflow: TextOverflow.ellipsis,
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: nostrSet.title ?? nostrSet.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const TextSpan(text: " "),
                                      TextSpan(
                                        text: "(${nostrSet.elements.length}) ",
                                        style: const TextStyle(
                                          color: Palette.gray,
                                          fontSize: 12,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            "by ${recommenderMetadataList[followSetsIndex].userMetadata?.name ?? "Unknown"}",
                                        style: TextStyle(
                                          color: Palette.gray,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  nostrSet.description ?? "",
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 0,
                      ),
                      trailing: SizedBox(
                        width: 135,
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OnboardingOpenStarterPack(
                              followSet: nostrSet,
                              selectedPubkeys: selectedPubkeys,
                            ),
                          ),
                        );
                      },
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
              name: selectedPubkeys.isNotEmpty
                  ? "continue with ${selectedPubkeys.length} accounts"
                  : "select a starter pack",
              onPressed: (() {
                widget.submitCallback(selectedPubkeys);
              }),
              disabled: selectedPubkeys.isEmpty,
              inverted: true,
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

class OnboardingOpenStarterPack extends ConsumerStatefulWidget {
  final NostrSet followSet;
  final List<String> selectedPubkeys;

  const OnboardingOpenStarterPack({
    super.key,
    required this.followSet,
    required this.selectedPubkeys,
  });
  @override
  ConsumerState<OnboardingOpenStarterPack> createState() =>
      _OnboardingOpenStarterPackState();
}

class _OnboardingOpenStarterPackState
    extends ConsumerState<OnboardingOpenStarterPack> {
  late final List<String> selectedPubkeys;

  // check if nothing of the followSet is selected
  bool get nothingOfOwnSelected => widget.followSet.elements
      .every((element) => !selectedPubkeys.contains(element.value));

  Iterable<NostrListElement> get ownSelected => widget.followSet.elements
      .where((element) => selectedPubkeys.contains(element.value));
  int get ownSelectedCount => ownSelected.length;

  bool get allSelected => widget.followSet.elements
      .every((element) => selectedPubkeys.contains(element.value));

  @override
  void initState() {
    super.initState();
    selectedPubkeys = widget.selectedPubkeys;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        backgroundColor: Palette.background,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: 20,
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: widget.followSet.title ?? widget.followSet.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: " "),
                  TextSpan(
                    text:
                        "by ${ref.watch(metadataStateProvider(widget.followSet.pubKey)).userMetadata?.name ?? "Unknown"}",
                    style: TextStyle(
                      color: Palette.gray,
                      fontSize: 12,
                    ),
                  ),
                ]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            Spacer(flex: 1),
            if (allSelected)
              longButton(
                  name: "unselect all",
                  onPressed: () {
                    // unselect only own
                    setState(() {
                      selectedPubkeys.removeWhere((element) {
                        return widget.followSet.elements
                            .map((e) => e.value)
                            .contains(element);
                      });
                    });
                  })
          ],
        ),
        foregroundColor: Palette.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: widget.followSet.elements.length,
              itemBuilder: (context, index) {
                final displayPubkey = widget.followSet.elements[index].value;
                final displayMetadata = ref
                    .watch(metadataStateProvider(displayPubkey))
                    .userMetadata;
                return ListTile(
                  onTap: () {
                    // Toggle selection
                    setState(() {
                      if (selectedPubkeys.contains(displayPubkey)) {
                        selectedPubkeys.remove(displayPubkey);
                      } else {
                        selectedPubkeys.add(displayPubkey);
                      }
                    });
                  },
                  title: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserImage(
                        imageUrl: displayMetadata?.picture,
                        pubkey: displayPubkey,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayMetadata?.name ?? "",
                              style: const TextStyle(
                                color: Palette.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayMetadata?.about ?? "",
                              style: const TextStyle(
                                color: Palette.gray,
                                fontSize: 12,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    selectedPubkeys.contains(displayPubkey)
                        ? PhosphorIcons.checkCircle()
                        : PhosphorIcons.circle(),
                    color: Palette.white,
                  ),
                );
              },
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            width: 400,
            height: 40,
            child: longButton(
              name: nothingOfOwnSelected
                  ? "follow all"
                  : "follow ${ownSelectedCount} accounts",
              onPressed: (() {
                setState(() {
                  if (nothingOfOwnSelected) {
                    selectedPubkeys
                        .addAll(widget.followSet.elements.map((e) => e.value));
                  }

                  Navigator.pop(context, selectedPubkeys);
                });
              }),
              disabled: false,
              inverted: true,
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
