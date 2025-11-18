import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../config/onboard_conf.dart';
import '../../../../config/palette.dart';
import '../../../../domain_layer/entities/nostr_list.dart';
import '../../../../domain_layer/entities/onboarding_user_info.dart';
import '../../../atoms/long_button.dart';
import '../../../atoms/my_profile_picture.dart';
import '../../../atoms/spinner_center.dart';
import '../../../components/starter_packs/starter_pack_card.dart';
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
      if (!recommendedStarterPacks.contains(widget.invitedByPubkey!)) {
        recommendedStarterPacks.insert(0, widget.invitedByPubkey!);
      }
    }
  }

  // flattened list of starter pack items
  List<_StarterPackItem> _buildFlattenedItems() {
    final List<NostrListsFollowState> followSetsList = [];

    // build the follow sets list
    for (final element in recommendedStarterPacks) {
      followSetsList.add(ref.watch(nostrListsFollowStateProvider(element)));
    }

    List<_StarterPackItem> items = [];

    for (int i = 0; i < followSetsList.length; i++) {
      final followSets = followSetsList[i];

      if (followSets.isLoading) {
        items.add(_StarterPackItem.loading());
      } else {
        for (var nostrSet in followSets.publicNostrFollowSets) {
          if (nostrSet.elements.isNotEmpty) {
            items.add(_StarterPackItem.starterPack(nostrSet));
          }
        }
      }
    }

    return items;
  }

  Widget _buildItemWidget(_StarterPackItem item) {
    if (item.isLoading) {
      return const Center(child: SpinnerCenter());
    }

    return StarterPackCard(
      pack: item.nostrSet!,
      onTab: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OnboardingOpenStarterPack(
              followSet: item.nostrSet!,
              selectedPubkeys: selectedPubkeys,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final flattenedItems = _buildFlattenedItems();

    return Scaffold(
      appBar: AppBar(
        leading: Container(),
        leadingWidth: 0,
        title: widget.invitedByPubkey == null
            ? Text(AppLocalizations.of(context)!.starterPacks)
            : Text(AppLocalizations.of(context)!.additionalStarterPacks),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: flattenedItems.length,
              itemBuilder: (context, index) =>
                  _buildItemWidget(flattenedItems[index]),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            width: 400,
            height: 40,
            child: longButton(
              name: selectedPubkeys.isNotEmpty
                  ? AppLocalizations.of(
                      context,
                    )!.continueWithAccounts(selectedPubkeys.length)
                  : AppLocalizations.of(context)!.selectStarterPack,
              onPressed: (() {
                widget.submitCallback(selectedPubkeys);
              }),
              disabled: selectedPubkeys.isEmpty,
              inverted: true,
            ),
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }
}

// helper class to represent flattened items
class _StarterPackItem {
  final bool isLoading;
  final NostrStarterPack? nostrSet;

  _StarterPackItem._({required this.isLoading, this.nostrSet});

  factory _StarterPackItem.loading() => _StarterPackItem._(isLoading: true);

  factory _StarterPackItem.starterPack(NostrStarterPack nostrSet) =>
      _StarterPackItem._(isLoading: false, nostrSet: nostrSet);
}

class OnboardingOpenStarterPack extends ConsumerStatefulWidget {
  final NostrStarterPack followSet;
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

  // Check if nothing of the followSet is selected
  bool get nothingOfOwnSelected => widget.followSet.elements.every(
    (element) => !selectedPubkeys.contains(element.value),
  );

  Iterable<NostrListElement> get ownSelected => widget.followSet.elements.where(
    (element) => selectedPubkeys.contains(element.value),
  );

  int get ownSelectedCount => ownSelected.length;

  bool get allSelected => widget.followSet.elements.every(
    (element) => selectedPubkeys.contains(element.value),
  );

  @override
  void initState() {
    super.initState();
    selectedPubkeys = widget.selectedPubkeys;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: 20,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: widget.followSet.title ?? widget.followSet.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: " "),
                    TextSpan(
                      text: AppLocalizations.of(context)!.by(
                        ref
                                .watch(
                                  metadataStateProvider(
                                    widget.followSet.pubKey,
                                  ),
                                )
                                .userMetadata
                                ?.name ??
                            "Unknown",
                      ),
                      style: TextStyle(
                        color: Paletter.getGray(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            const Spacer(flex: 1),
            if (allSelected)
              longButton(
                name: AppLocalizations.of(context)!.unselectAll,
                onPressed: () {
                  setState(() {
                    selectedPubkeys.removeWhere((element) {
                      return widget.followSet.elements
                          .map((e) => e.value)
                          .contains(element);
                    });
                  });
                },
              ),
          ],
        ),
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
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayMetadata?.about ?? "",
                              style: TextStyle(
                                color: Paletter.getGray(context),
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
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            width: 400,
            height: 40,
            child: longButton(
              name: nothingOfOwnSelected
                  ? AppLocalizations.of(context)!.followAll
                  : AppLocalizations.of(
                      context,
                    )!.followAccounts(ownSelectedCount),
              onPressed: (() {
                setState(() {
                  if (nothingOfOwnSelected) {
                    selectedPubkeys.addAll(
                      widget.followSet.elements.map((e) => e.value),
                    );
                  }
                  Navigator.pop(context, selectedPubkeys);
                });
              }),
              disabled: false,
              inverted: true,
            ),
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }
}
