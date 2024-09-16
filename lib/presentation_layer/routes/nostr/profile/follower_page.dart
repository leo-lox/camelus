import 'package:camelus/domain_layer/entities/contact_list.dart';
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
  final List<String> contacts;

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
  void _changeFollowing(
      bool followChange, String pubkey, ContactList currentOwnContacts) async {
    List<String> newContacts = [...currentOwnContacts.contacts];

    if (followChange) {
      newContacts.add(pubkey);
    } else {
      newContacts.removeWhere((element) => element == pubkey);
    }

    ref.read(followingProvider).setContacts(newContacts);
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
      body: StreamBuilder<ContactList>(
          stream: followingService.getContactsStreamSelf(),
          builder: (context, ownFollowingSnapshot) {
            if (ownFollowingSnapshot.hasError) {
              return Text('Error: ${ownFollowingSnapshot.error}');
            }
            if (!ownFollowingSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: widget.contacts.length,
                itemBuilder: (context, index) {
                  var displayPubkey = widget.contacts[index];
                  return StreamBuilder<UserMetadata?>(
                      stream: metadata.getMetadataByPubkey(displayPubkey),
                      builder: (BuildContext context, metadataSnapshot) {
                        if (metadataSnapshot.hasData) {
                          return personCard(displayPubkey, metadataSnapshot,
                              ownFollowingSnapshot.data!, context);
                        } else if (metadataSnapshot.hasError) {
                          return Text('Error: ${metadataSnapshot.error}');
                        } else {
                          return personCard(displayPubkey, metadataSnapshot,
                              ownFollowingSnapshot.data!, context);
                        }
                      });
                });
          }),
    );
  }

  PersonCard personCard(
      String displayPubkey,
      AsyncSnapshot<UserMetadata?> metadataSnapshot,
      ContactList ownContactList,
      BuildContext context) {
    return PersonCard(
      pubkey: displayPubkey,
      name: metadataSnapshot.data?.name ?? "",
      pictureUrl: metadataSnapshot.data?.picture ?? "",
      about: metadataSnapshot.data?.about ?? "",
      nip05: metadataSnapshot.data?.nip05 ?? "",
      isFollowing:
          ownContactList.contacts.any((element) => element == displayPubkey),
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
          ownContactList,
        );
      },
    );
  }
}
