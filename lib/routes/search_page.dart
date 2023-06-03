import 'dart:developer';

import 'package:camelus/config/palette.dart';
import 'package:camelus/models/nostr_note.dart';
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
        NostrNote("myId", "myPubkey", 0, 1, "mytest", "invalidSig", []),
      );
    } catch (e) {
      log("note likely already exists");
    }

    var b = await db.noteDao.findAllNotes();
    log(b.map((e) => e.id).toString());
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
