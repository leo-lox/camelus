import 'dart:async';
import 'dart:developer';

import 'package:camelus/db/database.dart';
import 'package:camelus/db/entities/db_note_view.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/providers/database_provider.dart';
import 'package:camelus/services/nostr/feeds/user_and_replies_feed.dart';
import 'package:camelus/services/nostr/relays/relays.dart';
import 'package:camelus/services/nostr/relays/relays_injector.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UserFeedAndRepliesView extends ConsumerStatefulWidget {
  final String pubkey;
  final Relays _relays;

  UserFeedAndRepliesView({Key? key, required this.pubkey})
      : _relays = RelaysInjector().relays,
        super(key: key);

  @override
  UserFeedAndRepliesViewState createState() => UserFeedAndRepliesViewState();
}

class UserFeedAndRepliesViewState
    extends ConsumerState<UserFeedAndRepliesView> {
  late AppDatabase db;
  late List<String> _followingPubkeys;
  late UserFeedAndRepliesFeed _userFeedAndRepliesFeed;

  final Completer<void> _servicesReady = Completer<void>();

  Future<void> _getFollowingPubkeys() async {
    var kind3 = (await db.noteDao.findPubkeyNotesByKind([widget.pubkey], 3))[0]
        .toNostrNote();
    List<String> followingList =
        kind3.getTagPubkeys.map((e) => e.value).toList();

    _followingPubkeys = followingList;
    return;
  }

  Future<void> _initDb() async {
    db = await ref.read(databaseProvider.future);
    return;
  }

  Future<void> _initSequence() async {
    await _initDb();
    await _getFollowingPubkeys();
    _userFeedAndRepliesFeed =
        UserFeedAndRepliesFeed(db, _followingPubkeys, widget._relays);
    _servicesReady.complete();
    return;
  }

  @override
  void initState() {
    super.initState();
    _initSequence();
  }

  @override
  void dispose() {
    _userFeedAndRepliesFeed.cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _servicesReady.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error'));
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return StreamBuilder<List<NostrNote>>(
            stream: _userFeedAndRepliesFeed.feedStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                var notes = snapshot.data!;
                return ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    var note = notes[index];
                    return ListTile(
                      title: Text(note.content),
                      subtitle: Text(note.created_at.toString()),
                    );
                  },
                );
              }
              if (snapshot.hasError) {
                return Center(
                    //button
                    child: ElevatedButton(
                  onPressed: () {},
                  child: Text(snapshot.error.toString(),
                      style: TextStyle(fontSize: 20, color: Colors.white)),
                ));
              }
              return const Text("waiting for stream trigger ",
                  style: TextStyle(fontSize: 20));
            },
          );
        }
        return const Center(child: Text('Error'));
      },
    );
  }
}
