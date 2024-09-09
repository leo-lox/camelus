import 'dart:async';
import 'dart:developer';
import 'package:camelus/presentation_layer/atoms/new_posts_available.dart';
import 'package:camelus/presentation_layer/atoms/refresh_indicator_no_need.dart';
import 'package:camelus/presentation_layer/components/note_card/note_card_container.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/presentation_layer/providers/get_notes_provider.dart';
import 'package:camelus/presentation_layer/providers/navigation_bar_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import '../../../components/note_card/sceleton_note.dart';
import '../../../providers/main_feed_provider.dart';

class UserFeedOriginalView extends ConsumerStatefulWidget {
  final String pubkey;

  final ScrollController scrollControllerFeed;

  // attaches from outside, used for scroll animation
  const UserFeedOriginalView(
      {super.key, required this.pubkey, required this.scrollControllerFeed});

  @override
  ConsumerState<UserFeedOriginalView> createState() =>
      _UserFeedOriginalViewState();
}

class _UserFeedOriginalViewState extends ConsumerState<UserFeedOriginalView> {
  final List<StreamSubscription> _subscriptions = [];

  final Completer<void> _servicesReady = Completer<void>();

  bool _newPostsAvailable = false;

  // new #########
  final List<NostrNote> timelineEvents = [];
  late final Stream<List<NostrNote>> _eventStreamBuffer;
  NostrNote get latestNote => timelineEvents.last;

  _scrollListener() {
    if (widget.scrollControllerFeed.position.pixels ==
        widget.scrollControllerFeed.position.maxScrollExtent) {
      final mainFeedProvider = ref.read(getMainFeedProvider);
      // mainFeedProvider.loadMore(
      //   oltherThen: latestNote.created_at,
      //   pubkey: widget.pubkey,
      // );
    }

    if (widget.scrollControllerFeed.position.pixels < 100) {
      // disable after sroll
      // if (_newPostsAvailable) {
      //   setState(() {
      //     _newPostsAvailable = false;
      //   });
      // }
    }
  }

  _loadMore() {
    if (timelineEvents.length < 2) return;
    log("_loadMore()");
    final mainFeedProvider = ref.read(getMainFeedProvider);
    mainFeedProvider.loadMore(
      oltherThen: latestNote.created_at,
      pubkey: widget.pubkey,
    );
  }

  void _setupScrollListener() {
    widget.scrollControllerFeed.addListener(_scrollListener);
  }

  void _setupMainFeedListener() {
    /// buffers an integrates notes into feed
    final mainFeedProvider = ref.read(getMainFeedProvider);
    _eventStreamBuffer = mainFeedProvider.stream
        .bufferTime(const Duration(
          milliseconds: 500,
        ))
        .where((events) => events.isNotEmpty);

    _eventStreamBuffer.listen((events) {
      if (mounted) {
        setState(() {
          timelineEvents.addAll(events);
          timelineEvents.sort((a, b) => b.created_at.compareTo(a.created_at));
        });
      }
    });

    mainFeedProvider.fetchFeedEvents(
      npub: widget.pubkey,
      requestId: "my-test",
      limit: 20,
    );
  }

  void _setupNewNotesListener() {
    final mainFeedProvider = ref.read(getMainFeedProvider);

    mainFeedProvider.newNotesStream
        .bufferTime(const Duration(
          seconds: 5,
        ))
        .where((events) => events.isNotEmpty)
        .listen((events) {
      log("new notes stream event");
      if (mounted) {
        setState(() {
          _newPostsAvailable = true;
        });
      }

      // notify navigation bar
      ref.read(navigationBarProvider).newNotesCount = events.length;
    });
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
      return;
    }
    ref.watch(navigationBarProvider).resetNewNotesCount();
    // scroll to top
    widget.scrollControllerFeed.animateTo(
      widget.scrollControllerFeed.position.minScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  void _integrateNewNotes() {
    widget.scrollControllerFeed.animateTo(
      widget.scrollControllerFeed.position.minScrollExtent,
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
    final notesProvider = ref.read(getNotesProvider);

    // todo: first fetch
  }

  Future<void> _initSequence() async {
    _servicesReady.complete();
    if (!mounted) return;

    _initUserFeed();
    _setupScrollListener();
    _setupMainFeedListener();
    _setupNewNotesListener();

    _setupNavBarHomeListener();

    // todo: bug on first launch
    //ref.watch(navigationBarProvider).resetNewNotesCount();
  }

  @override
  void initState() {
    super.initState();
    _initSequence();
  }

  @override
  void dispose() {
    _disposeSubscriptions();
    widget.scrollControllerFeed.removeListener(_scrollListener);
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
                child: ListView.builder(
                  controller: PrimaryScrollController.of(context),
                  itemCount: timelineEvents.length + 1,
                  itemBuilder: (context, index) {
                    if (index == timelineEvents.length) {
                      return SkeletonNote(renderCallback: _loadMore());
                    }

                    final event = timelineEvents[index];

                    return NoteCardContainer(
                      key: ValueKey(event.id),
                      note: event,
                    );
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
