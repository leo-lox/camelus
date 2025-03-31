import 'dart:async';
import 'dart:developer';
import 'package:camelus/presentation_layer/components/note_card/note_card_container.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/presentation_layer/components/note_card/skeleton_note.dart';
import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain_layer/entities/feed_event_view_model.dart';
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

  // Map to store indices of notes for quick lookup
  final Map<String, int> _noteIndices = {};

  @override
  void initState() {
    super.initState();
    eventViewController = FlutterListViewController();

    // If we have a note ID to open, scroll to it after build
    if (widget._openNoteId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(Duration(milliseconds: 1200)).then(
          (_) {
            scrollToNote(widget._openNoteId!);
          },
        );
      });
    }
  }

  void scrollToNote(String noteId) {
    if (_noteIndices.containsKey(noteId)) {
      // eventViewController.sliverController.animateToIndex(_noteIndices[noteId]!,
      //     duration: Duration(milliseconds: 400), curve: Curves.easeInOut);
      eventViewController.sliverController.animateToIndex(_noteIndices[noteId]!,
          duration: Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  // Rest of your existing code...

  @override
  Widget build(BuildContext context) {
    final eventFeedState =
        ref.watch(eventFeedStateProvider(widget._rootNoteId));

    _buildNoteIndices(eventFeedState);

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

          // itemKey: (index) {
          //   if (index == 0) {
          //     return widget._rootNoteId;
          //   }
          //   return eventFeedState.comments[index - 1].value.id;
          // },
          keepPosition: true,
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
              openNoteId: widget._openNoteId,
            );
          },
        ),
      ),
    );
  }

  // Build a map of note IDs to their indices for quick lookup
  void _buildNoteIndices(FeedEventViewModel eventFeedState) {
    _noteIndices.clear();

    // Add root note
    if (eventFeedState.rootNote != null) {
      _noteIndices[eventFeedState.rootNote!.id] = 0;
    }

    // Add all comments
    for (int i = 0; i < eventFeedState.comments.length; i++) {
      _noteIndices[eventFeedState.comments[i].value.id] = i + 1;
    }
  }
}
