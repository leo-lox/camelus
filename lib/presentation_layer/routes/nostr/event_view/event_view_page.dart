import 'dart:async';
import 'dart:developer';
import 'package:camelus/presentation_layer/components/note_card/note_card_container.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/presentation_layer/components/note_card/skeleton_note.dart';
import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain_layer/entities/tree_node.dart';
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
  late FlutterListViewController eventViewController;

  // Flattened list of comments with their depth information
  List<FlattenedComment> _flattenedComments = [];

  bool _userHasScrolled = false;
  double _lastScrollPosition = 0;

  @override
  void initState() {
    super.initState();
    eventViewController = FlutterListViewController();

    eventViewController.addListener(_onScroll);
  }

  @override
  void dispose() {
    super.dispose();
    eventViewController.removeListener(_onScroll);
    eventViewController.dispose();
  }

  void scrollToNote(String? noteId) {
    if (noteId == null || _userHasScrolled) {
      return;
    }
    if (noteId == widget._rootNoteId) {
      eventViewController.sliverController.animateToIndex(0,
          duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
      return;
    }

    // Find the index in the flattened comments list
    for (int i = 0; i < _flattenedComments.length; i++) {
      if (_flattenedComments[i].note.id == noteId) {
        // Add 1 to account for the root note at index 0
        eventViewController.sliverController.animateToIndex(i + 1,
            duration: Duration(milliseconds: 300), curve: Curves.easeInOutExpo);
        return;
      }
    }
  }

  void _onScroll() {
    // Get the current scroll position
    final currentPosition = eventViewController.offset;

    // Check if the position has changed significantly (to filter out small changes)
    if ((currentPosition - _lastScrollPosition).abs() > 1.0) {
      setState(() {
        _userHasScrolled = true;
      });
      eventViewController.removeListener(_onScroll);
    }

    // Update the last position
    _lastScrollPosition = currentPosition;
  }

  // Flatten the comment tree into a list with depth information
  List<FlattenedComment> _flattenCommentTree(
      List<TreeNode<NostrNote>> comments) {
    List<FlattenedComment> result = [];

    // Sort direct replies to root by creation time (oldest first)
    final sortedComments = List<TreeNode<NostrNote>>.from(comments)
      ..sort((a, b) => a.value.created_at.compareTo(b.value.created_at));

    // Process each top-level comment
    for (final comment in sortedComments) {
      // Add the comment itself
      result.add(FlattenedComment(
        note: comment.value,
        depth: 0,
        ancestorHasSibling: [false],
      ));

      // Add all its children recursively (with child comments sorted by creation time)
      if (comment.children.isNotEmpty) {
        result.addAll(_flattenChildComments(
            comment.children, 1, [comment != sortedComments.last]));
      }
    }

    return result;
  }

  // Helper method to recursively flatten child comments
  List<FlattenedComment> _flattenChildComments(
      List<TreeNode<NostrNote>> children,
      int depth,
      List<bool> ancestorHasSibling) {
    List<FlattenedComment> result = [];

    // Sort child comments by creation time (older first)
    final sortedChildren = List<TreeNode<NostrNote>>.from(children)
      ..sort((a, b) => a.value.created_at.compareTo(b.value.created_at));

    for (var i = 0; i < sortedChildren.length; i++) {
      final child = sortedChildren[i];
      final isLastChild = i == sortedChildren.length - 1;

      // Add the child comment
      result.add(FlattenedComment(
        note: child.value,
        depth: depth,
        ancestorHasSibling: [...ancestorHasSibling, !isLastChild],
      ));

      // Add all its children recursively
      if (child.children.isNotEmpty) {
        result.addAll(_flattenChildComments(
            child.children, depth + 1, [...ancestorHasSibling, !isLastChild]));
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (!_userHasScrolled) {
      Future.delayed(Duration(milliseconds: 200)).then((_) {
        scrollToNote(widget._openNoteId);
      });
    }

    final eventFeedState =
        ref.watch(eventFeedStateProvider(widget._rootNoteId));

    // Flatten the comment tree
    _flattenedComments = _flattenCommentTree(eventFeedState.comments);

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
          childCount: _flattenedComments.length + 1, // +1 for root note
          keepPosition: true,
          (BuildContext context, int index) {
            if (index == 0) {
              // Root note
              return eventFeedState.rootNote != null
                  ? NoteCardContainer(
                      note: eventFeedState.rootNote!,
                      key: ValueKey(widget._rootNoteId),
                    )
                  : const SkeletonNote();
            }

            // Comment
            final flatComment = _flattenedComments[index - 1];
            return FlatCommentWidget(
              key: ValueKey(flatComment.note.id),
              comment: flatComment,
              isHighlighted: flatComment.note.id == widget._openNoteId,
            );
          },
        ),
      ),
    );
  }
}
