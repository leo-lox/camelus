import 'package:camelus/presentation_layer/atoms/long_button.dart';
import 'package:camelus/presentation_layer/components/starter_packs/open_starter_pack.dart';
import 'package:camelus/presentation_layer/components/starter_packs/starter_pack_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain_layer/entities/nostr_list.dart';
import '../../../domain_layer/entities/starter_pack_identifier.dart';
import '../../../helpers/helpers.dart';
import '../../atoms/spinner_center.dart';
import '../../providers/ndk_provider.dart';
import '../../providers/nostr_lists_follow_state_provider.dart';

class StarterPacksList extends ConsumerWidget {
  final String pubkey;

  const StarterPacksList({
    super.key,
    required this.pubkey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followSetsList = ref.watch(nostrListsFollowStateProvider(pubkey));
    final ndk = ref.watch(ndkProvider);
    final myPubkey = ndk.accounts.getPublicKey();

    final bool isOwnProfile = myPubkey == pubkey;

    if (followSetsList.isLoading) {
      return Center(child: SpinnerCenter());
    }

    if (followSetsList.publicNostrFollowSets.isEmpty) {
      if (isOwnProfile) {
        return Center(
          child: longButton(
              name: "create starter pack",
              inverted: true,
              onPressed: () {
                Navigator.pushNamed(context, '/edit-starter-pack',
                    arguments: StarterPackIdentifier(
                      name: "i-${Helpers().getRandomString(10)}", //create new
                      pubkey: pubkey,
                    ));
              }),
        );
      }

      return Center(
        child: Text("No starter packs found"),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 50),
      child: ListView.builder(
          itemCount: isOwnProfile
              ? followSetsList.publicNostrFollowSets.length + 1
              : followSetsList.publicNostrFollowSets.length,
          itemBuilder: (
            context,
            followSetsIndex,
          ) {
            if (followSetsIndex ==
                    followSetsList.publicNostrFollowSets.length &&
                isOwnProfile) {
              return Container(
                padding: EdgeInsets.only(top: 18, bottom: 50),
                child: Center(
                  child: longButton(
                      name: "create another",
                      inverted: true,
                      onPressed: () {
                        Navigator.pushNamed(context, '/edit-starter-pack',
                            arguments: StarterPackIdentifier(
                              name:
                                  "i-${Helpers().getRandomString(10)}", //create new
                              pubkey: pubkey,
                            ));
                      }),
                ),
              );
            }
            final NostrStarterPack starterPacks =
                followSetsList.publicNostrFollowSets[followSetsIndex];
            if (starterPacks.elements.isEmpty) return Container();

            return Container(
              padding: EdgeInsets.fromLTRB(8, 2, 8, 2),
              child: StarterPackCard(
                pack: starterPacks,
                onTab: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OpenStarterPack(
                        followSet: starterPacks,
                      ),
                    ),
                  );
                },
              ),
            );
          }),
    );
  }
}
