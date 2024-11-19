import 'package:camelus/domain_layer/entities/nostr_tag.dart';

import '../entities/nostr_note.dart';
import '../repositories/note_repository.dart';

class UserReactions {
  final NoteRepository _noteRepository;
  final String? selfPubkey;

  UserReactions({
    required NoteRepository noteRepository,
    this.selfPubkey,
  }) : _noteRepository = noteRepository;

  Future<bool> isPostSelfLiked({required String postId}) async {
    if (selfPubkey == null) {
      return Future.value(false);
    }
    final res = await isPostLiked(likedByPubkey: selfPubkey!, postId: postId);
    return res != null;
  }

  /// Check if a post is liked by a specific user
  /// [returns] the reaction if the post is liked, null otherwise
  Future<NostrNote?> isPostLiked({
    required String likedByPubkey,
    required String postId,
  }) async {
    final reactions = await _noteRepository.getReactions(
      postId: postId,
      authors: [likedByPubkey],
    );
    if (reactions.isEmpty) {
      return null;
    }

    final res = reactions.where((reaction) {
      return reaction.tags.any((tag) => tag.type == "e" && tag.value == postId);
    }).first;

    if (res.content != "+") {
      return null;
    }

    return res;
  }

  Future<void> likePost({
    required String pubkeyOfEventAuthor,
    required String postId,
  }) {
    if (selfPubkey == null) {
      throw Exception("selfPubkey is null");
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final myReaction = NostrNote(
        content: "+",
        pubkey: selfPubkey!,
        created_at: now,
        kind: 7,
        id: "",
        sig: "",
        tags: [
          NostrTag(type: "e", value: postId),
          NostrTag(type: "p", value: pubkeyOfEventAuthor),
        ]);
    return _noteRepository.broadcastNote(myReaction);
  }

  Future<void> deleteReaction({required String postId}) async {
    if (selfPubkey == null) {
      throw Exception("selfPubkey is null");
    }

    // get the reaction to delete
    final reaction =
        await isPostLiked(likedByPubkey: selfPubkey!, postId: postId);
    if (reaction == null) {
      throw Exception("Reaction not found");
    }

    return _noteRepository.deleteNote(
      reaction.id,
    );
  }
}
