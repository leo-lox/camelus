import 'dart:async';
import 'dart:developer';

import '../entities/nostr_note.dart';
import '../entities/tree_node.dart';
import '../repositories/note_repository.dart';
import 'follow.dart';

///
/// idea is to combine multiple streams here into the feed stream
/// the feed stream gets then sorted on the ui in an intervall to prevent huge layout shifts
///
/// there could be one update stream and one for scrolling
///
///

class EventFeed {
  final NoteRepository _noteRepository;
  final Follow _follow;

  final String rootNoteFetchId = "event-root";
  final String repliesFetchId = "event-replies";

  // root streams
  final StreamController<NostrNote> _rootNoteController =
      StreamController<NostrNote>();
  Stream<NostrNote> get rootNoteStream => _rootNoteController.stream;

  final StreamController<NostrNote> _replyNotesController =
      StreamController<NostrNote>();
  Stream<NostrNote> get replyNotesStream => _replyNotesController.stream;

  EventFeed(this._noteRepository, this._follow);

  Future<void> subscribeToReplyNotes({
    required String rootNoteId,
    required int since,
  }) async {
    final replyNotes = _noteRepository.subscribeReplyNotes(
      requestId: repliesFetchId,
      rootNoteId: rootNoteId,
    );

    replyNotes.listen((event) {
      _replyNotesController.add(event);
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

    await Future.wait(futures);
  }
}
