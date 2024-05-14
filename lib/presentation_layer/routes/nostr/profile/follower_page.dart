import 'package:camelus/domain_layer/entities/user_metadata.dart';
import 'package:camelus/presentation_layer/components/person_card.dart';
import 'package:camelus/domain_layer/entities/nostr_tag.dart';
import 'package:camelus/presentation_layer/providers/following_provider.dart';
import 'package:camelus/presentation_layer/providers/metadata_provider.dart';
import 'package:flutter/material.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/presentation_layer/routes/nostr/profile/profile_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FollowerPage extends ConsumerStatefulWidget {
  final String title;
  final List<NostrTag> contacts;

  const FollowerPage({
    super.key,
    required this.title,
    required this.contacts,
  });

  @override
  ConsumerState<FollowerPage> createState() => _FollowerPageState();
}

class _FollowerPageState extends ConsumerState<FollowerPage> {
  /// follow Change - true to add, false to remove
  void _changeFollowing(bool followChange, String pubkey,
      List<NostrTag> currentOwnContacts) async {
    List<NostrTag> newContacts = [...currentOwnContacts];

    if (followChange) {
      newContacts.add(NostrTag(type: 'p', value: pubkey));
    } else {
      newContacts.removeWhere((element) => element.value == pubkey);
    }

    ref.read(followingProvider).setFollowing(newContacts);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var metadata = ref.watch(metadataProvider);
    var followingService = ref.watch(followingProvider);
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        backgroundColor: Palette.background,
        title: Text(widget.title),
        foregroundColor: Palette.white,
      ),
      body: StreamBuilder<List<NostrTag>>(
          stream: followingService.getFollowingSelf(),
          builder: (context, ownFollowingSnapshot) {
            return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: widget.contacts.length,
                itemBuilder: (context, index) {
                  var displayPubkey = widget.contacts[index].value;
                  return StreamBuilder<UserMetadata?>(
                      stream: metadata.getMetadataByPubkey(displayPubkey),
                      builder: (BuildContext context, metadataSnapshot) {
                        if (metadataSnapshot.hasData) {
                          return personCard(displayPubkey, metadataSnapshot,
                              ownFollowingSnapshot, context);
                        } else if (metadataSnapshot.hasError) {
                          return Text('Error: ${metadataSnapshot.error}');
                        } else {
                          return personCard(displayPubkey, metadataSnapshot,
                              ownFollowingSnapshot, context);
                        }
                      });
                });
          }),
    );
  }

  PersonCard personCard(
      String displayPubkey,
      AsyncSnapshot<UserMetadata?> metadataSnapshot,
      AsyncSnapshot<List<NostrTag>> ownFollowingSnapshot,
      BuildContext context) {
    return PersonCard(
      pubkey: displayPubkey,
      name: metadataSnapshot.data?.name ?? "",
      pictureUrl: metadataSnapshot.data?.picture ?? "",
      about: metadataSnapshot.data?.about ?? "",
      nip05: metadataSnapshot.data?.nip05 ?? "",
      isFollowing: ownFollowingSnapshot.data!
          .any((element) => element.value == displayPubkey),
      onTap: () {
        // navigate to profile page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(
              pubkey: displayPubkey,
            ),
          ),
        );
      },
      onFollowTab: (followState) {
        _changeFollowing(
          followState,
          displayPubkey,
          ownFollowingSnapshot.data!,
        );
      },
    );
  }
}
