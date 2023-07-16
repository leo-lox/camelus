import 'dart:async';
import 'dart:developer';

import 'package:camelus/atoms/new_posts_available.dart';
import 'package:camelus/atoms/refresh_indicator_no_need.dart';
import 'package:camelus/components/note_card/note_card_container.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/db/database.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/providers/database_provider.dart';
import 'package:camelus/providers/relay_provider.dart';
import 'package:camelus/scroll_controller/retainable_scroll_controller.dart';
import 'package:camelus/services/nostr/feeds/hashtag_feed.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HashtagFeedView extends ConsumerStatefulWidget {
  final String hashtag;

  const HashtagFeedView({Key? key, required this.hashtag}) : super(key: key);

  @override
  ConsumerState<HashtagFeedView> createState() => _HashtagFeedViewState();
}

class _HashtagFeedViewState extends ConsumerState<HashtagFeedView> {
  late AppDatabase db;
  final List<StreamSubscription> _subscriptions = [];
  late HashtagFeed _hashtagFeed;
  final String hashtagFeedFreshId = "fresh";
  final String hashtagFeedTimelineFetchId = "timeline";

  late final RetainableScrollController _scrollControllerFeed =
      RetainableScrollController();
  bool _newPostsAvailable = false;

  final Completer<void> _servicesReady = Completer<void>();

  void _setupScrollListener() {
    _scrollControllerFeed.addListener(() {
      if (_scrollControllerFeed.position.pixels ==
          _scrollControllerFeed.position.maxScrollExtent) {
        log("reached end of scroll");

        var latest =
            _hashtagFeed.feed.last.created_at; //- 86400 * 7; // -1 week

        _hashtagFeedLoadMore(latest);
      }

      if (_scrollControllerFeed.position.pixels < 100) {
        // disable after sroll
        // if (_newPostsAvailable) {
        //   setState(() {
        //     _newPostsAvailable = false;
        //   });
        // }
      }
    });
  }

  void _setupNewNotesListener() {
    _subscriptions.add(
      _hashtagFeed.newNotesStream.listen((event) {
        log("new notes stream event");
        setState(() {
          _newPostsAvailable = true;
        });
      }),
    );
  }

  void _integrateNewNotes() {
    _hashtagFeed.integrateNewNotes();
    _scrollControllerFeed.animateTo(
      _scrollControllerFeed.position.minScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    setState(() {
      _newPostsAvailable = false;
    });
  }

  void _initHashtagFeed() {
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    int latestTweet = now - 86400; // -1 day

    _hashtagFeed.requestRelayHashtagFeed(
      hashtags: [widget.hashtag],
      requestId: hashtagFeedFreshId,
      limit: 5,
      //since: latestTweet,
    );
  }

  void _hashtagFeedLoadMore(int? until) async {
    log("load more called");

    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    // schould not be needed
    int defaultUntil = now - 86400 * 7; // -1 week

    _hashtagFeed.requestRelayHashtagFeed(
      hashtags: [widget.hashtag],
      requestId: hashtagFeedTimelineFetchId,
      limit: 5,
      until: until ?? defaultUntil,
    );
  }

  void _hashtagFeedCheckForNewData(NostrNote currentBuilNote) {
    var latestSessionNote = _hashtagFeed.oldestNoteInSession;
    if (latestSessionNote == null) {
      return;
    }
    var difference = currentBuilNote.created_at - latestSessionNote.created_at;
    log("${latestSessionNote.created_at} -- ${currentBuilNote.created_at} -- $difference");
    if (latestSessionNote.id == currentBuilNote.id) {
      log("### load more please #################################");
      _hashtagFeedLoadMore(currentBuilNote.created_at);
    }
  }

  Future<void> _initDb() async {
    db = await ref.read(databaseProvider.future);
    return;
  }

  Future<void> _initSequence() async {
    await _initDb();

    var relayCoordinator = ref.watch(relayServiceProvider);

    _hashtagFeed = HashtagFeed(db, relayCoordinator, widget.hashtag);
    await _hashtagFeed.feedRdy;

    _servicesReady.complete();

    _initHashtagFeed();
    _setupScrollListener();
    _setupNewNotesListener();

    return;
  }

  @override
  void initState() {
    super.initState();
    _initSequence();
  }

  @override
  void dispose() {
    super.dispose();
    _hashtagFeed.cleanup();
    _disposeSubscriptions();
  }

  void _disposeSubscriptions() {
    for (var s in _subscriptions) {
      s.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _servicesReady.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
            color: Palette.white,
          ));
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error'));
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return Stack(
            children: [
              RefreshIndicatorNoNeed(
                onRefresh: () {
                  return Future.delayed(const Duration(milliseconds: 0));
                },
                child: StreamBuilder<List<NostrNote>>(
                  stream: _hashtagFeed.feedStream,
                  initialData: _hashtagFeed.feed,
                  builder: (BuildContext context,
                      AsyncSnapshot<List<NostrNote>> snapshot) {
                    if (snapshot.hasData) {
                      var notes = snapshot.data!;

                      if (notes.isEmpty) {
                        return const Center(
                          child: Text("no notes found",
                              style: TextStyle(
                                  fontSize: 20, color: Palette.white)),
                        );
                      }

                      return CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        controller: _scrollControllerFeed,
                        slivers: [
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                var note = notes[index];
                                _hashtagFeedCheckForNewData(note);
                                return NoteCardContainer(notes: [note]);
                              },
                              childCount: notes.length,
                            ),
                          ),
                        ],
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                          //button
                          child: ElevatedButton(
                        onPressed: () {},
                        child: Text(snapshot.error.toString(),
                            style: const TextStyle(
                                fontSize: 20, color: Colors.white)),
                      ));
                    }
                    return const Text("waiting for stream trigger ",
                        style: TextStyle(fontSize: 20));
                  },
                ),
              ),
              if (_newPostsAvailable)
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: newPostsAvailable(
                      name: "new posts",
                      onPressed: () {
                        _integrateNewNotes();
                      }),
                ),
            ],
          );
        }
        return const Center(child: Text('Error'));
      },
    );
  }
}
