import 'dart:async';
import 'dart:developer';

import 'package:camelus/helpers/helpers.dart';
import 'package:rxdart/rxdart.dart';

import '../entities/nostr_note.dart';
import '../entities/tree_node.dart';
import '../repositories/note_repository.dart';

class EventFeed {
  final NoteRepository _noteRepository;

  final String repliesFetchId = "replies-${Helpers().getRandomString(5)}";

  /// the complete build tree of replies => new updates = new state
  final StreamController<List<TreeNode<NostrNote>>> _repliesTreeController =
      StreamController<List<TreeNode<NostrNote>>>();
  Stream<List<TreeNode<NostrNote>>> get repliesTreeStream =>
      _repliesTreeController.stream;

  /// raw replies
  final StreamController<NostrNote> _replyNotesController =
      StreamController<NostrNote>();
  Stream<NostrNote> get replyNotesStream => _replyNotesController.stream;

  /// root note
  final StreamController<NostrNote> _rootNoteController =
      StreamController<NostrNote>();
  Stream<NostrNote> get rootNoteStream => _rootNoteController.stream;

  EventFeed(this._noteRepository);

  Future<void> subscribeToReplyNotes({
    required String rootNoteId,
  }) async {
    final replyNotes = _noteRepository.subscribeReplyNotes(
      requestId: repliesFetchId,
      rootNoteId: rootNoteId,
    );

    replyNotes
        .bufferTime(const Duration(milliseconds: 500))
        .where((events) => events.isNotEmpty)
        .listen((events) {
      for (final event in events) {
        _replyNotesController.add(event);
      }

      final tree = buildRepliesTree(
        rootNoteId: rootNoteId,
        replies: events,
      );

      _repliesTreeController.add(tree);
    });
  }

  Future<void> subscribeToRootNote({
    required String noteId,
  }) async {
    final rootNote = _noteRepository.getTextNote(
      noteId,
    );

    rootNote.listen((event) {
      _rootNoteController.add(event);
    });
  }

  /// build a tree from the replies \
  /// [returns] a list of first level replies \
  /// the cildren are replies of replies
  static List<TreeNode<NostrNote>> buildRepliesTree({
    required String rootNoteId,
    required List<NostrNote> replies,
  }) {
    final List<NostrNote> workingList = List.from(replies, growable: true);
    workingList.sort((a, b) => a.created_at.compareTo(b.created_at));
    final List<TreeNode<NostrNote>> tree = [];

    // find top level replies
    for (var i = 0; i < workingList.length; i++) {
      final reply = workingList[i];

      if (reply.getDirectReply?.value == rootNoteId) {
        tree.add(TreeNode<NostrNote>(reply));
        workingList.remove(reply);
        i--; // Adjust index after removal
      }
    }

    // build the tree
    for (final node in tree) {
      _buildSubtree(workingList: workingList, parent: node);
    }

    return tree;
  }

  /// recursive function to build the tree
  ///
  static _buildSubtree({
    required List<NostrNote> workingList,
    required TreeNode<NostrNote> parent,
  }) {
    for (var i = 0; i < workingList.length; i++) {
      final reply = workingList[i];

      if (reply.getDirectReply?.value == parent.value.id) {
        final child = TreeNode<NostrNote>(reply);
        parent.addChild(child);
        workingList.remove(reply);
        i--; // Adjust index after removal
        _buildSubtree(workingList: workingList, parent: child);
      }
    }
  }

  /// clean up everything including closing subscriptions
  Future<void> dispose() async {
    final List<Future> futures = [];
    futures.add(_noteRepository.closeSubscription(repliesFetchId));
    futures.add(_rootNoteController.close());
    futures.add(_replyNotesController.close());
    futures.add(_repliesTreeController.close());

    await Future.wait(futures);
  }
}
