import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:camelus/atoms/long_button.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/db/entities/db_note.dart';
import 'package:camelus/db/entities/db_user_metadata.dart';
import 'package:camelus/db/queries/db_note_queries.dart';
import 'package:camelus/helpers/nip04_encryption.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/models/nostr_request_event.dart';
import 'package:camelus/models/nostr_tag.dart';
import 'package:camelus/providers/database_provider.dart';
import 'package:camelus/providers/key_pair_provider.dart';
import 'package:camelus/providers/metadata_provider.dart';
import 'package:camelus/providers/relay_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';

class BlockPage extends ConsumerStatefulWidget {
  String userPubkey;
  String? postId;

  BlockPage({Key? key, required this.userPubkey, this.postId})
      : super(key: key);

  @override
  ConsumerState<BlockPage> createState() => _BlockPageState();
}

class _BlockPageState extends ConsumerState<BlockPage> {
  bool isUserBlocked = false;
  bool requestLoading = false;

  List<NostrTag> tags = [];
  List<NostrTag> contentObj = [];

  Completer initDone = Completer();

  late final Isar db;
  late final KeyPairWrapper keyService;

  @override
  void initState() {
    super.initState();
    _initBlockState();
  }

  // gets the current state and who is blocked
  Future _initBlockState() async {
    db = await ref.read(databaseProvider.future);
    keyService = await ref.read(keyPairProvider.future);
    final existingListDb = await DbNoteQueries.kindPubkeyFuture(
      db,
      pubkey: keyService.keyPair!.publicKey,
      kind: 10000,
    );

    if (existingListDb.isNotEmpty) {
      final existingList = existingListDb.first.toNostrNote();
      tags = existingList.tags;
      // decrypt content
      final nip04 = Nip04Encryption();
      try {
        final oldContentObj = nip04.decrypt(keyService.keyPair!.privateKey,
            keyService.keyPair!.publicKey, existingList.content);

        final List<List<String>> contentJson = json
            .decode(oldContentObj)
            .map<List<String>>((e) => List<String>.from(e))
            .toList();

        List<NostrTag> convertedList = [];
        // convert to NostrTag
        for (var element in contentJson) {
          convertedList.add(NostrTag.fromJson(element));
        }

        contentObj = convertedList;
      } catch (e) {
        log("error decrypting encrypted blocklist: $e");
      }
    }

    // change state if user is blocked
    if (contentObj.any((element) => element.value == widget.userPubkey)) {
      setState(() {
        isUserBlocked = true;
      });
    }
    initDone.complete();

    return;
  }

  /// write the new state to nostr
  writeNewBlockState() async {
    await initDone.future;

    final String newContent =
        json.encode(contentObj.map((e) => e.toList()).toList());

    final nip04 = Nip04Encryption();

    final encryptedContent = nip04.encrypt(keyService.keyPair!.privateKey,
        keyService.keyPair!.publicKey, newContent);

    final NostrRequestEventBody newNoteBody = NostrRequestEventBody(
      pubkey: keyService.keyPair!.publicKey,
      kind: 10000,
      tags: tags,
      content: encryptedContent,
      privateKey: keyService.keyPair!.privateKey,
    );

    var myRequest = NostrRequestEvent(body: newNoteBody);
    var relays = ref.watch(relayServiceProvider);
    List<String> results = await relays.write(request: myRequest);
    return results;
  }

  void _blockUser(
    String pubkey,
  ) async {
    setState(() {
      requestLoading = true;
    });
    // add blocked user to tags
    contentObj.add(NostrTag(type: "p", value: pubkey));
    await writeNewBlockState();
    setState(() {
      requestLoading = false;
    });

    // delete post if it exists
    await db.writeTxn(() async {
      final q = DbNoteQueries.kindPubkeyQuery(db, pubkey: pubkey, kind: 1);
      await q.deleteAll();
    });
  }

  void _unblockUser(
    String pubkey,
  ) async {
    setState(() {
      requestLoading = true;
    });
    // remove blocked user from content
    contentObj.removeWhere((element) => element.value == pubkey);
    await writeNewBlockState();
    setState(() {
      requestLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var metadata = ref.watch(metadataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('block/report'),
        backgroundColor: Palette.background,
      ),
      backgroundColor: Palette.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // block user
            Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('user',
                          style: TextStyle(
                              color: Palette.lightGray, fontSize: 20)),
                      const SizedBox(width: 10),
                      FutureBuilder<DbUserMetadata?>(
                        future:
                            metadata.getMetadataByPubkey(widget.userPubkey!),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              snapshot.data?.name ?? widget.userPubkey!,
                              style: const TextStyle(
                                  color: Palette.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold),
                            );
                          }
                          return Container();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder(
                      future: initDone.future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return SizedBox(
                            height: 40,
                            width: MediaQuery.of(context).size.width * 0.75,
                            child: longButton(
                                name: "loading",
                                loading: true,
                                onPressed: () {}),
                          );
                        }

                        return SizedBox(
                          height: 40,
                          width: MediaQuery.of(context).size.width * 0.75,
                          child: longButton(
                              name: isUserBlocked ? "unblock" : "block",
                              loading: requestLoading,
                              onPressed: () {
                                if (isUserBlocked) {
                                  _unblockUser(widget.userPubkey);
                                } else {
                                  _blockUser(widget.userPubkey);
                                }
                                setState(() {
                                  isUserBlocked = !isUserBlocked;
                                });
                              }),
                        );
                      }),
                  const SizedBox(height: 10),
                  // SizedBox(
                  //   height: 40,
                  //   width: MediaQuery.of(context).size.width * 0.75,
                  //   child: longButton(name: "report", onPressed: () => {}),
                  // ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
