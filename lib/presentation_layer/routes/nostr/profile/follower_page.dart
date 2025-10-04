import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/palette.dart';
import '../../../../domain_layer/entities/contact_list.dart';
import '../../../../domain_layer/entities/user_metadata.dart';
import '../../../components/person_card.dart';
import '../../../providers/following_contact_state_provider.dart';
import '../../../providers/metadata_state_provider.dart';
import '../../../providers/ndk_provider.dart';
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
    final selfPubkey = ref.watch(ndkProvider).accounts.getPublicKey();
    final myContactListNotifier =
        ref.watch(contactListStateProvider(selfPubkey!).notifier);

    List<String> newContacts = [...currentOwnContacts.contacts];

    if (followChange) {
      newContacts.add(pubkey);
      await myContactListNotifier.followUser(pubkey);
    } else {
      newContacts.removeWhere((element) => element == pubkey);
      await myContactListNotifier.unfollowUser(pubkey);
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
    final myContactList = ref.watch(contactListSelfStateProvider);
    return Scaffold(
      backgroundColor: Paletter.getBackground(context),
      appBar: AppBar(
        backgroundColor: Paletter.getBackground(context),
        title: Text(widget.title),
        foregroundColor: Paletter.getWhite(context),
      ),
      body: ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: widget.contactList.contacts.length,
          itemBuilder: (context, index) {
            final displayPubkey = widget.contactList.contacts[index];

            final displayMetadata =
                ref.watch(metadataStateProvider(displayPubkey)).userMetadata;
            return personCard(
              displayPubkey,
              displayMetadata,
              myContactList.contactList,
              context,
            );
          }),
    );
  }

  PersonCard personCard(String displayPubkey, UserMetadata? metadata,
      ContactList ownContactList, BuildContext context) {
    return PersonCard(
      pubkey: displayPubkey,
      name: metadata?.name ?? "",
      pictureUrl: metadata?.picture ?? "",
      about: metadata?.about ?? "",
      nip05: metadata?.nip05,
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
