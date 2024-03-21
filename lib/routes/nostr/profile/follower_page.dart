import 'package:camelus/atoms/person_card.dart';
import 'package:camelus/db/entities/db_user_metadata.dart';
import 'package:camelus/db/queries/db_note_queries.dart';
import 'package:camelus/models/nostr_request_event.dart';
import 'package:camelus/models/nostr_tag.dart';
import 'package:camelus/providers/database_provider.dart';
import 'package:camelus/providers/following_provider.dart';
import 'package:camelus/providers/key_pair_provider.dart';
import 'package:camelus/providers/metadata_provider.dart';
import 'package:camelus/providers/relay_provider.dart';
import 'package:flutter/material.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/routes/nostr/profile/profile_page.dart';
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
    var mykeys = await ref.watch(keyPairProvider.future);
    var db = await ref.watch(databaseProvider.future);

    var myLastNote = (await DbNoteQueries.kindPubkeyFuture(db,
            pubkey: mykeys.keyPair!.publicKey, kind: 3))
        .first;

    List<NostrTag> newContacts = [...currentOwnContacts];

    if (followChange) {
      newContacts.add(NostrTag(type: 'p', value: pubkey));
    } else {
      newContacts.removeWhere((element) => element.value == pubkey);
    }

    _writeContacts(
      publicKey: mykeys.keyPair!.publicKey,
      privateKey: mykeys.keyPair!.privateKey,
      content: myLastNote.content ?? "",
      updatedContacts: newContacts,
    );
  }

  Future _writeContacts({
    required String publicKey,
    required String privateKey,
    required String content,
    required List<NostrTag> updatedContacts,
  }) async {
    var relays = ref.watch(relayServiceProvider);
    NostrRequestEventBody body = NostrRequestEventBody(
      pubkey: publicKey,
      privateKey: privateKey,
      content: content,
      kind: 3,
      tags: updatedContacts,
    );
    NostrRequestEvent myEvent = NostrRequestEvent(body: body);

    await relays.write(request: myEvent);

    return;
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
          stream: followingService.ownPubkeyContactsStreamDb,
          initialData: followingService.ownContacts,
          builder: (context, ownFollowingSnapshot) {
            return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: widget.contacts.length,
                itemBuilder: (context, index) {
                  var displayPubkey = widget.contacts[index].value;
                  return StreamBuilder<DbUserMetadata?>(
                      stream: metadata.getMetadataByPubkeyStream(displayPubkey),
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
      AsyncSnapshot<DbUserMetadata?> metadataSnapshot,
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
