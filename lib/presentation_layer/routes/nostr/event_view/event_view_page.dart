import 'dart:async';
import 'dart:developer';
import 'package:camelus/presentation_layer/components/note_card/note_card_container.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/presentation_layer/components/note_card/skeleton_note.dart';
import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/comments_section.dart';
import '../../../providers/event_feed/event_feed_provider.dart';

class EventViewPage extends ConsumerStatefulWidget {
  final String? _openNoteId;
  final String _rootNoteId;

  const EventViewPage({
    super.key,
    required String? openNoteId,
    required String rootNoteId,
  })  : _openNoteId = openNoteId,
        _rootNoteId = rootNoteId;

  @override
  EventViewPageState createState() => EventViewPageState();
}

class EventViewPageState extends ConsumerState<EventViewPage> {
  Stream<List<NostrNote>> notesStream = Stream.empty();

  late final ScrollController _scrollControllerFeed = ScrollController();

  final String eventFeedFreshId = "fresh";

  late FlutterListViewController eventViewController;

  void _setupScrollListener() {
    _scrollControllerFeed.addListener(() {
      if (_scrollControllerFeed.position.pixels ==
          _scrollControllerFeed.position.maxScrollExtent) {
        log("reached end of scroll");
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

  Future<void> _initSequence() async {
    _setupScrollListener();
  }

  @override
  void initState() {
    super.initState();
    eventViewController = FlutterListViewController();
    _initSequence();
  }

  @override
  void dispose() {
    _scrollControllerFeed.dispose();
    eventViewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventFeedState =
        ref.watch(eventFeedStateProvider(widget._rootNoteId));

    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        foregroundColor: Palette.white,
        backgroundColor: Palette.background,
        title: const Text("thread"),
      ),
      body: FlutterListView(
        controller: eventViewController,
        delegate: FlutterListViewDelegate(
          childCount: eventFeedState.comments.length + 1,
          // onItemKey: (index) => eventFeedState.comments[index].value.id,
          // keepPosition: true,
          (BuildContext context, int index) {
            if (index == 0) {
              return eventFeedState.rootNote != null
                  ? NoteCardContainer(
                      note: eventFeedState.rootNote!,
                      key: ValueKey(widget._rootNoteId),
                    )
                  : const SkeletonNote();
            }

            final event = eventFeedState.comments[index - 1];

            return CommentSection(
              key: ObjectKey(event),
              comment: event,
            );
          },
        ),
      ),
    );
  }
}
