import 'dart:async';
import 'dart:developer';

import 'package:camelus/presentation_layer/atoms/refresh_indicator_no_need.dart';
import 'package:camelus/presentation_layer/components/note_card/note_card_container.dart';
import 'package:camelus/config/palette.dart';

import 'package:camelus/data_layer/models/nostr_note.dart';
import 'package:camelus/presentation_layer/providers/database_provider.dart';
import 'package:camelus/presentation_layer/providers/relay_provider.dart';
import 'package:camelus/presentation_layer/scroll_controller/retainable_scroll_controller.dart';
import 'package:camelus/services/nostr/feeds/event_feed.dart';
import 'package:flutter/material.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';

class EventViewPage extends ConsumerStatefulWidget {
  final String _rootId;
  final String? _scrollIntoView;

  const EventViewPage(
      {super.key, required String rootId, String? scrollIntoView})
      : _scrollIntoView = scrollIntoView,
        _rootId = rootId;

  @override
  _EventViewPageState createState() => _EventViewPageState();
}

class _EventViewPageState extends ConsumerState<EventViewPage> {
  late Isar db;
  late EventFeed _eventFeed;
  late final RetainableScrollController _scrollControllerFeed =
      RetainableScrollController();

  final Completer<void> _servicesReady = Completer<void>();

  final String eventFeedFreshId = "fresh";

  NostrNote? _lastNoteInFeed;

  void _setupScrollListener() {
    _scrollControllerFeed.addListener(() {
      if (_scrollControllerFeed.position.pixels ==
          _scrollControllerFeed.position.maxScrollExtent) {
        log("reached end of scroll");

        _eventFeedLoadMore();
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

  Future<void> _initDb() async {
    db = await ref.read(databaseProvider.future);
    return;
  }

  Future<void> _initSequence() async {
    await _initDb();

    var relayCoordinator = ref.watch(relayServiceProvider);

    _eventFeed = EventFeed(db, widget._rootId, relayCoordinator);
    await _eventFeed.feedRdy;
    _servicesReady.complete();

    _initUserFeed();
    _setupScrollListener();
  }

  @override
  void initState() {
    super.initState();
    _initSequence();
  }

  @override
  void dispose() {
    _eventFeed.cleanup();
    super.dispose();
  }

  void _initUserFeed() {
    _eventFeed.requestRelayEventFeed(
      eventIds: [widget._rootId],
      requestId: eventFeedFreshId,
      limit: 5,
    );
  }

  void _eventFeedLoadMore() async {
    log("load more called");

    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    // schould not be needed
    int defaultUntil = now - 86400 * 7; // -1 week

    _eventFeed.requestRelayEventFeed(
      eventIds: [widget._rootId],
      requestId: eventFeedFreshId,
      limit: 5,
      until: _lastNoteInFeed?.created_at ?? defaultUntil,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        foregroundColor: Palette.white,
        backgroundColor: Palette.background,
        title: const Text("thread"),
      ),
      body: FutureBuilder(
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
            return RefreshIndicatorNoNeed(
              onRefresh: () {
                return Future.delayed(const Duration(milliseconds: 0));
              },
              child: StreamBuilder(
                stream: _eventFeed.feedStream,
                initialData: _eventFeed.feed,
                builder: (BuildContext context,
                    AsyncSnapshot<List<NostrNote>> snapshot) {
                  if (snapshot.hasData) {
                    var notes = snapshot.data!;
                    if (notes.isEmpty) {
                      return const Center(
                        child: Text("no notes found",
                            style:
                                TextStyle(fontSize: 20, color: Palette.white)),
                      );
                    }
                    return _buildScrollView(notes);
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
            );
          }
          return const Center(child: Text('Error'));
        },
      ),
    );
  }

  CustomScrollView _buildScrollView(List<NostrNote> notes) {
    _lastNoteInFeed = notes.last;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      controller: _scrollControllerFeed,
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              return _buildReplyTree(notes, widget._rootId);
            },
            childCount: 1,
          ),
        ),
      ],
    );
  }

  // return the root
  NoteCardContainer _buildReplyTree(List<NostrNote> notes, String rootId) {
    var workingList = [...notes];
    var rootNote = workingList.firstWhere(
      (element) => element.id == rootId,
      orElse: () => NostrNote.empty(id: rootId),
    );
    // remove the root from the working list
    try {
      workingList.removeWhere((element) => element.id == rootId);
    } catch (e) {
      log("root not in tree");
    }

    // get author first level replies
    List<NostrNote> authorFirstLevelSelfReplies = workingList
        .where((element) =>
            element.getRootReply?.value == rootId &&
            element.pubkey == rootNote.pubkey &&
            element.getDirectReply == null)
        .toList();

    // get root level replies and build containers
    List<NostrNote> rootLevelReplies = workingList.where((element) {
      return element.getDirectReply?.value == rootNote.id;
    }).toList();

    // remove root level replies from working list
    for (var element in rootLevelReplies) {
      workingList.removeWhere((e) => e.id == element.id);
    }

    List<NoteCardContainer> rootLevelRepliesContainers = rootLevelReplies
        .map((e) => NoteCardContainer(
              notes: [e],
            ))
        .toList();

    // add remaining replies to containers
    var foundNotes = <NostrNote>[];
    for (var container in rootLevelRepliesContainers) {
      for (var note in workingList) {
        for (var tag in note.getTagEvents) {
          if (container.notes.map((e) => e.id).contains(tag.value)) {
            container.notes.add(note);
            // remove note from working list
            foundNotes.add(note);
            break;
          } else {}
        }
      }
    }
    // remove found notes from working list
    for (var note in foundNotes) {
      workingList.removeWhere((e) => e.id == note.id);
    }

    log("unresolved notes: ${workingList.length}");

    _tryToFetchUnresolvedNotes(workingList, rootNote);

    // add unresolved notes to root level replies with missing Note

    for (var note in workingList) {
      rootLevelRepliesContainers.add(NoteCardContainer(
        notes: [NostrNote.empty(id: note.getDirectReply?.value ?? ""), note],
      ));
    }

    return NoteCardContainer(
      notes: [
        rootNote,
      ],
      otherContainers: rootLevelRepliesContainers,
    );
  }

  List<NostrNote> unresolvedNotesLoopWaiting = [];
  _tryToFetchUnresolvedNotes(List<NostrNote> notes, NostrNote rootNote) async {
    if (notes.isEmpty) return;

    if (!unresolvedNotesLoopWaiting.contains(notes.first) ||
        !unresolvedNotesLoop.contains(notes.first)) {
      unresolvedNotesLoopWaiting.addAll(notes);
    }

    if (unresolvedNotesLoop.isEmpty) {
      unresolvedNotesLoop.addAll(unresolvedNotesLoopWaiting);
      unresolvedNotesLoopWaiting.clear();
      await _unresolvedLoop(rootNote);
      unresolvedNotesLoop.clear();
      return;
    }

    // if the loop is already running then it will be triggered again after the loop is done

    await Future.delayed(const Duration(milliseconds: 500));

    _tryToFetchUnresolvedNotes(notes, rootNote);
  }

  List<NostrNote> unresolvedNotesLoop = [];
  Future _unresolvedLoop(NostrNote rootNote) async {
    List<String> myEventIds = [];
    List<String> myAuthorPubkeys = [];
    List<String> myRelayCandidates = [];

    for (var note in unresolvedNotesLoop) {
      var noteIdReply = note.getDirectReply?.value;
      var relayReplyRelay = note.getDirectReply?.recommended_relay;

      var noteIdRoot = note.getRootReply?.value;
      var relayRootRelay = note.getRootReply?.recommended_relay;

      List<String> authorPubkeys =
          note.getTagPubkeys.map((e) => e.value).toList();

      List<String> authorPubkeysRelays = [];
      for (var tag in note.getTagPubkeys) {
        if (tag.recommended_relay != null) {
          authorPubkeysRelays.add(tag.recommended_relay!);
        }
      }

      log("noteIdReplyRelay: $relayReplyRelay, noteIdRootRelay: $relayRootRelay");

      if (noteIdReply != null) {
        myEventIds.add(noteIdReply);
      }
      if (noteIdRoot != null) {
        myEventIds.add(noteIdRoot);
      }
      if (relayReplyRelay != null) {
        myRelayCandidates.add(relayReplyRelay);
      }
      if (relayRootRelay != null) {
        myRelayCandidates.add(relayRootRelay);
      }
      if (authorPubkeys.isNotEmpty) {
        myAuthorPubkeys.addAll(authorPubkeys);
      }
      if (authorPubkeysRelays.isNotEmpty) {
        myRelayCandidates.addAll(authorPubkeysRelays);
      }
    }

    if (myRelayCandidates.isEmpty) {
      //return;
    }

    // remove duplicates
    myRelayCandidates = myRelayCandidates.toSet().toList();
    myAuthorPubkeys = myAuthorPubkeys.toSet().toList();
    myEventIds = myEventIds.toSet().toList();

    var result = await _eventFeed.requestRelayEventFeedFixedRelays(
        pubkeys: myAuthorPubkeys,
        eventIds: myEventIds,
        relayCandidates: myRelayCandidates,
        requestId: "efeed-tmp-unresolvedLoop",
        timeout: const Duration(seconds: 1),
        limit: 5,
        until: rootNote.created_at // root note
        );
    log("resultRelay: $result");
    _eventFeed.closeRelaySubscription("efeed-tmp-unresolvedLoop");
    return;
  }
}
