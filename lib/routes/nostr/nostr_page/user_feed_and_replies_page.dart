import 'dart:async';
import 'dart:developer';

import 'package:camelus/db/database.dart';
import 'package:camelus/db/entities/db_note_view.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/providers/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UserFeedAndRepliesView extends ConsumerStatefulWidget {
  final String pubkey;

  const UserFeedAndRepliesView({Key? key, required this.pubkey})
      : super(key: key);

  @override
  UserFeedAndRepliesViewState createState() => UserFeedAndRepliesViewState();
}

class UserFeedAndRepliesViewState
    extends ConsumerState<UserFeedAndRepliesView> {
  late AppDatabase db;
  late List<String> _followingPubkeys;
  final List<StreamSubscription> _subscriptions = [];

  final StreamController<List<NostrNote>> _streamController =
      StreamController<List<NostrNote>>.broadcast();

  _streamFeed() async {
    log("streaming feed ");

    final stopwatch = Stopwatch()..start();

    var getresult =
        await db.noteDao.findPubkeyNotesByKind(_followingPubkeys, 1);
    log("streaming getResult: ${getresult.length} notes; executed in ${stopwatch.elapsed}");

    _streamController.add(getresult.map((e) => e.toNostrNote()).toList());

    Stream<List<DbNoteView>> stream =
        db.noteDao.findPubkeyNotesStreamByKind(_followingPubkeys, 1);

    _subscriptions.add(stream.listen((event) {
      stream.listen((event) {
        log("streaming: ${event.length} notes");
        _streamController.add(event.map((e) => e.toNostrNote()).toList());
      });
    }));
  }

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

  void _initSequence() async {
    await _initDb();
    await _getFollowingPubkeys();
    //_streamFeed();
  }

  @override
  void initState() {
    super.initState();
    _initSequence();
  }

  @override
  void dispose() {
    _disposeSubscriptions();
    super.dispose();
  }

  void _disposeSubscriptions() {
    for (var s in _subscriptions) {
      s.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NostrNote>>(
      stream: _streamController.stream,
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
        } else {
          return Center(
              //button
              child: ElevatedButton(
            onPressed: () {
              _streamFeed();
            },
            child: Text("Refresh",
                style: TextStyle(fontSize: 20, color: Colors.white)),
          ));
        }
      },
    );
  }
}
