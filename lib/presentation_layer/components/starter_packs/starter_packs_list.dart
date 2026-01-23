import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain_layer/entities/nostr_list.dart';
import '../../../domain_layer/entities/starter_pack_identifier.dart';
import '../../../helpers/helpers.dart';
import '../../atoms/long_button.dart';
import '../../atoms/spinner_center.dart';
import '../../providers/ndk_provider.dart';
import '../../providers/nostr_lists_follow_state_provider.dart';
import 'starter_pack_card.dart';

class StarterPacksList extends ConsumerWidget {
  final String pubkey;

  const StarterPacksList({super.key, required this.pubkey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    NostrListsFollowState followSetsList = ref.watch(
      nostrListsFollowStateProvider(pubkey),
    );
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
            name: AppLocalizations.of(context)!.createStarterPack,
            inverted: true,
            onPressed: () {
              context.push(
                '/edit-starter-pack',
                extra: StarterPackIdentifier(
                  name: "i-${Helpers().getRandomString(10)}", //create new
                  pubkey: pubkey,
                ),
              );
            },
          ),
        );
      }

      return Center(
        child: Text(AppLocalizations.of(context)!.noStarterPacksFound),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 50),
      child: ListView.builder(
        itemCount: isOwnProfile
            ? followSetsList.publicNostrFollowSets.length + 1
            : followSetsList.publicNostrFollowSets.length,
        itemBuilder: (context, followSetsIndex) {
          if (followSetsIndex == followSetsList.publicNostrFollowSets.length &&
              isOwnProfile) {
            return Container(
              padding: EdgeInsets.only(top: 18, bottom: 50),
              child: Center(
                child: longButton(
                  name: AppLocalizations.of(context)!.createAnother,
                  inverted: true,
                  onPressed: () {
                    context.push(
                      '/edit-starter-pack',
                      extra: StarterPackIdentifier(
                        name: "i-${Helpers().getRandomString(10)}", //create new
                        pubkey: pubkey,
                      ),
                    );
                  },
                ),
              ),
            );
          }
          final NostrStarterPack starterPacks =
              followSetsList.publicNostrFollowSets[followSetsIndex];
          if (starterPacks.elements.isEmpty) return Container();

          return Container(
            padding: EdgeInsets.fromLTRB(8, 2, 8, 2),
            child: StarterPackCard(
              key: ValueKey('starterPackCard-${starterPacks.name}-$pubkey'),
              pack: starterPacks,
              onTab: () {
                context.push(
                  '/open-starter-pack',
                  extra: StarterPackIdentifier(
                    name: starterPacks.name,
                    pubkey: pubkey,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
