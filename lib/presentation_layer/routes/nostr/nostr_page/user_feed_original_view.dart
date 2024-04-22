import 'dart:async';
import 'dart:developer';
import 'package:camelus/presentation_layer/atoms/new_posts_available.dart';
import 'package:camelus/presentation_layer/atoms/refresh_indicator_no_need.dart';
import 'package:camelus/presentation_layer/components/note_card/note_card_container.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/data_layer/models/nostr_note.dart';
import 'package:camelus/presentation_layer/providers/database_provider.dart';
import 'package:camelus/presentation_layer/providers/following_provider.dart';
import 'package:camelus/presentation_layer/providers/navigation_bar_provider.dart';
import 'package:camelus/presentation_layer/providers/ndk_provider.dart';
import 'package:camelus/presentation_layer/providers/relay_provider.dart';
import 'package:camelus/scroll_controller/retainable_scroll_controller.dart';
import 'package:camelus/services/nostr/feeds/user_feed.dart';
import 'package:dart_ndk/nips/nip01/bip340_event_verifier.dart';
import 'package:dart_ndk/nips/nip01/filter.dart';
import 'package:dart_ndk/relay_jit_manager/relay_jit_manager.dart';
import 'package:dart_ndk/relay_jit_manager/request_jit.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';

class UserFeedOriginalView extends ConsumerStatefulWidget {
  final String pubkey;

  const UserFeedOriginalView({super.key, required this.pubkey});

  @override
  ConsumerState<UserFeedOriginalView> createState() =>
      _UserFeedOriginalViewState();
}

class _UserFeedOriginalViewState extends ConsumerState<UserFeedOriginalView> {
  late Isar db;
  late RelayJitManager ndk;
  final List<StreamSubscription> _subscriptions = [];
  late List<String> _followingPubkeys;
  late UserFeed _userFeed;
  final Completer<void> _servicesReady = Completer<void>();

  late final RetainableScrollController _scrollControllerFeed =
      RetainableScrollController();
  bool _newPostsAvailable = false;

  final String userFeedFreshId = "fresh";
  final String userFeedTimelineFetchId = "timeline";

  NostrNote? _lastNoteInFeed;

  void _setupScrollListener() {
    _scrollControllerFeed.addListener(() {
      if (_scrollControllerFeed.position.pixels ==
          _scrollControllerFeed.position.maxScrollExtent) {
        log("reached end of scroll");

        var latest = _userFeed.feed.last.created_at; //- 86400 * 7; // -1 week

        _userFeedLoadMore(latest);
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
      _userFeed.newNotesStream.listen((event) {
        log("new notes stream event");
        setState(() {
          _newPostsAvailable = true;
        });
        // notify navigation bar
        ref.read(navigationBarProvider).newNotesCount = event.length;
      }),
    );
  }

  void _setupNavBarHomeListener() {
    var provider = ref.read(navigationBarProvider);
    _subscriptions.add(provider.onTabHome.listen((event) {
      _handleHomeBarTab();
    }));
  }

  void _handleHomeBarTab() {
    if (_newPostsAvailable) {
      _integrateNewNotes();
    }
    ref.watch(navigationBarProvider).resetNewNotesCount();
    // scroll to top
    _scrollControllerFeed.animateTo(
      _scrollControllerFeed.position.minScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  void _integrateNewNotes() {
    _userFeed.integrateNewNotes();
    _scrollControllerFeed.animateTo(
      _scrollControllerFeed.position.minScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    setState(() {
      _newPostsAvailable = false;
    });
    ref.watch(navigationBarProvider).resetNewNotesCount();
  }

  void _initUserFeed() {
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    int latestTweet = now - 86400; // -1 day

    _userFeed.requestRelayUserFeed(
      users: _followingPubkeys,
      requestId: userFeedFreshId,
      limit: 15,
      since: latestTweet,
    );
  }

  void _userFeedLoadMore(int? until) async {
    log("load more called");

    if (_followingPubkeys.isEmpty) {
      log("!!! no following users found !!!");
      return;
    }

    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    // schould not be needed
    int defaultUntil = now - 86400 * 1; // -1 day

    _userFeed.requestRelayUserFeed(
      users: _followingPubkeys,
      requestId: userFeedTimelineFetchId,
      limit: 5,
      until: until ?? defaultUntil,
    );
  }

  void _userFeedCheckForNewData(NostrNote currentBuilNote) {
    var latestSessionNote = _userFeed.oldestNoteInSession;
    if (latestSessionNote == null) {
      return;
    }
    if (latestSessionNote.id == currentBuilNote.id) {
      _userFeedLoadMore(currentBuilNote.created_at);
    }
  }

  Future<void> _getFollowingPubkeys() async {
    var followingP = ref.read(followingProvider);
    await followingP.servicesReady;

    _followingPubkeys = followingP.ownContacts.map((e) => e.value).toList();
    _followingPubkeys = [..._followingPubkeys, widget.pubkey]; // add own pubkey
    return;
  }

  Future<void> _initDb() async {
    db = await ref.read(databaseProvider.future);
    return;
  }

  Future<void> _initNdk() async {
    ndk = ref.read(ndkProvider);
    return;
  }

  Future<void> _initSequence() async {
    await _initDb();
    await _getFollowingPubkeys();
    await _initNdk();

    var relayCoordinator = ref.watch(relayServiceProvider);

    var verifier = Bip340EventVerifier();
    NostrRequestJit _feedRequest = NostrRequestJit.subscription("ndk_feed",
        eventVerifier: verifier,
        filters: [
          Filter(authors: _followingPubkeys, kinds: [1])
        ]);

    ndk.handleRequest(_feedRequest);

    _feedRequest.responseStream.listen((event) {
      //log("NDK: feed response event $event");
    });

    _userFeed = UserFeed(db, _followingPubkeys, relayCoordinator);
    await _userFeed.feedRdy;

    _servicesReady.complete();

    // reset home bar new notes count
    ref.watch(navigationBarProvider).resetNewNotesCount();

    _initUserFeed();
    _setupScrollListener();
    _setupNewNotesListener();
    _setupNavBarHomeListener();

    return;
  }

  @override
  void initState() {
    super.initState();
    _initSequence();
  }

  @override
  void dispose() {
    _userFeed.cleanup();
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
                  stream: _userFeed.feedStream,
                  initialData: _userFeed.feed,
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

                      _lastNoteInFeed = notes.last;

                      return CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        controller: _scrollControllerFeed,
                        slivers: [
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                var note = notes[index];
                                _userFeedCheckForNewData(note);
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
