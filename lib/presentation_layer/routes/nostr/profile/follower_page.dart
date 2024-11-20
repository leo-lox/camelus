import 'package:camelus/domain_layer/entities/contact_list.dart';
import 'package:camelus/domain_layer/entities/user_metadata.dart';
import 'package:camelus/presentation_layer/components/person_card.dart';
import 'package:camelus/presentation_layer/providers/following_provider.dart';
import 'package:camelus/presentation_layer/providers/metadata_provider.dart';
import 'package:flutter/material.dart';
import 'package:camelus/config/palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_page_2.dart';

class FollowerPage extends ConsumerStatefulWidget {
  final String title;

  final ContactList contactList;

  const FollowerPage({
    super.key,
    required this.contactList,
    required this.title,
  });

  @override
  ConsumerState<FollowerPage> createState() => _FollowerPageState();
}

class _FollowerPageState extends ConsumerState<FollowerPage> {
  /// follow Change - true to add, false to remove
  Future<void> _changeFollowing(
    bool followChange,
    String pubkey,
    ContactList currentOwnContacts,
  ) async {
    final followService = ref.read(followingProvider);
    List<String> newContacts = [...currentOwnContacts.contacts];

    if (followChange) {
      newContacts.add(pubkey);
      await followService.followUser(pubkey);
    } else {
      newContacts.removeWhere((element) => element == pubkey);
      await followService.unfollowUser(pubkey);
    }
    setState(() {
      currentOwnContacts.contacts = newContacts;
    });
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

          /// get self contacts to display follow state
          stream: followingService.getContactsStreamSelf(),
          builder: (context, contactsSnapshot) {
            if (contactsSnapshot.hasError) {
              return Text('Error: ${contactsSnapshot.error}');
            }
            if (!contactsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: widget.contactList.contacts.length,
                itemBuilder: (context, index) {
                  var displayPubkey = widget.contactList.contacts[index];
                  return StreamBuilder<UserMetadata?>(
                      stream: metadata.getMetadataByPubkey(displayPubkey),
                      builder: (BuildContext context, metadataSnapshot) {
                        if (metadataSnapshot.hasData) {
                          return personCard(
                            displayPubkey,
                            metadataSnapshot,
                            contactsSnapshot.data!,
                            context,
                          );
                        } else if (metadataSnapshot.hasError) {
                          return Text('Error: ${metadataSnapshot.error}');
                        } else {
                          return personCard(
                            displayPubkey,
                            metadataSnapshot,
                            contactsSnapshot.data!,
                            context,
                          );
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
            builder: (context) => ProfilePage2(
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
