import 'dart:developer';

import 'package:camelus/config/palette.dart';
import 'package:camelus/db/entities/db_note_view.dart';
import 'package:camelus/db/entities/db_note_view_base.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/models/nostr_tag.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:camelus/providers/database_provider.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  @override
  void initState() {
    super.initState();

    test();
  }

  test() async {
    //await ref.watch(databaseProvider.future)

    var db = await ref.read(databaseProvider.future);

    try {
      await db.noteDao.insertNostrNote(
        NostrNote(
            id: "myId",
            pubkey: "myPubkey",
            created_at: 0,
            kind: 1,
            content: "mytest",
            sig: "invalidSig",
            tags: []),
      );
    } catch (e) {
      log("note likely already exists");
    }

    try {
      await db.noteDao.insertNostrNote(
        NostrNote(
            id: "myId10",
            pubkey: "myPubkey10",
            created_at: 0,
            kind: 1,
            content: "mytest2",
            sig: "invalidSig",
            tags: [
              NostrTag(
                  type: "p",
                  value: "myTag1Pubkey",
                  recommended_relay: "myTag1Relay"),
              NostrTag(type: "e", value: "myTag2EvnetId"),
            ]),
      );
    } catch (e) {
      log("note2 likely already exists");
    }

    List<DbNoteView> a = await db.noteDao.findAllNotes();

    List<NostrNote> b = a.map((e) => e.toNostrNote()).toList();

    var c = await db.noteDao.findPubkeyNotes(['myPubkey', 'myPubkey10']);
    log("findAll: ${b}");
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Palette.background,
      body: Center(
        child: Text('work in progress', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
