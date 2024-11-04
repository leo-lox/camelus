import 'dart:async';
import 'dart:developer';
import 'package:camelus/domain_layer/usecases/get_notes.dart';
import 'package:camelus/presentation_layer/atoms/refresh_indicator_no_need.dart';
import 'package:camelus/presentation_layer/components/note_card/note_card_container.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/presentation_layer/components/note_card/sceleton_note.dart';
import 'package:camelus/presentation_layer/providers/get_notes_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../components/comments_section.dart';
import '../../../providers/event_feed_provider.dart';

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
  _EventViewPageState createState() => _EventViewPageState();
}

class _EventViewPageState extends ConsumerState<EventViewPage> {
  late GetNotes _getNotes;

  Stream<List<NostrNote>> notesStream = Stream.empty();

  late final ScrollController _scrollControllerFeed = ScrollController();

  final Completer<void> _servicesReady = Completer<void>();

  final String eventFeedFreshId = "fresh";

  NostrNote? _lastNoteInFeed;

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
    _getNotes = ref.read(getNotesProvider);
    _setupScrollListener();
  }

  @override
  void initState() {
    super.initState();
    _initSequence();
  }

  @override
  void dispose() {
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
      body: Column(
        children: [
          // Root note

          // Comments section scroll
          Expanded(
            child: ListView.builder(
              controller: _scrollControllerFeed,
              itemCount: eventFeedState.comments.length + 1,
              itemBuilder: (context, index) {
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
                  commentTree: event,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
