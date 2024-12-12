import 'package:camelus/presentation_layer/components/starter_packs/open_starter_pack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/palette.dart';
import '../../../domain_layer/entities/nostr_list.dart';
import '../../atoms/my_profile_picture.dart';
import '../../atoms/overlapting_avatars.dart';
import '../../providers/metadata_state_provider.dart';
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

    if (followSetsList.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (followSetsList.publicNostrFollowSets.isEmpty) {
      return Center(
        child: Text("No starter packs found"),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 50),
      child: ListView.builder(
          itemCount: followSetsList.publicNostrFollowSets.length,
          itemBuilder: (
            context,
            followSetsIndex,
          ) {
            final NostrSet nostrSet =
                followSetsList.publicNostrFollowSets[followSetsIndex];

            if (nostrSet.elements.isEmpty) return Container();

            return ListTile(
              title: Row(
                children: [
                  if (nostrSet.image != null)
                    Image.network(nostrSet.image!, width: 50, height: 50),
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
                    builder: (context) => OpenStarterPack(
                      followSet: nostrSet,
                    ),
                  ),
                );
              },
            );
          }),
    );
  }
}
