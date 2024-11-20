import 'dart:convert';

import 'package:camelus/config/default_relays.dart';
import 'package:camelus/data_layer/models/nostr_note_model.dart';

import '../entities/nostr_note.dart';
import '../entities/nostr_tag.dart';
import '../repositories/note_repository.dart';

class UserReposts {
  final NoteRepository _noteRepository;
  final String? selfPubkey;

  UserReposts({
    required NoteRepository noteRepository,
    this.selfPubkey,
  }) : _noteRepository = noteRepository;

  Future<bool> isPostSelfReposted({required String postId}) async {
    if (selfPubkey == null) {
      return Future.value(false);
    }
    final res = await isPostRepostedBy(
      repostedByPubkey: selfPubkey!,
      postId: postId,
    );
    return res != null;
  }

  /// Check if a post is liked by a specific user
  /// [returns] the reaction if the post is liked, null otherwise
  Future<NostrNote?> isPostRepostedBy({
    required String repostedByPubkey,
    required String postId,
  }) async {
    final reposts = await _noteRepository.getReposts(
      postId: postId,
      authors: [repostedByPubkey],
    );
    if (reposts.isEmpty) {
      return null;
    }

    final res = reposts.where((reaction) {
      return reaction.tags.any((tag) => tag.type == "e" && tag.value == postId);
    }).first;

    return res;
  }

  /// repost a post \
  /// [postToRepost] the post to repost \
  ///
  Future<void> repostPost({
    required NostrNote postToRepost,
  }) {
    if (selfPubkey == null) {
      throw Exception("selfPubkey is null");
    }

    final recivedOnRelays = postToRepost.sources;

    final selectedSource = recivedOnRelays.isNotEmpty
        ? recivedOnRelays.first
        : DEFAULT_ACCOUNT_CREATION_RELAYS.keys.last;

    final postToRepostModel = NostrNoteModel(
      id: postToRepost.id,
      pubkey: postToRepost.pubkey,
      created_at: postToRepost.created_at,
      kind: postToRepost.kind,
      content: postToRepost.content,
      sig: postToRepost.sig,
      tags: postToRepost.tags,
    );

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final myRepost = NostrNote(
      content: jsonEncode(postToRepostModel.toJson()),
      pubkey: selfPubkey!,
      created_at: now,
      kind: 6,
      id: "",
      sig: "",
      tags: [
        NostrTag(
          type: "e",
          value: postToRepost.id,
          recommended_relay: selectedSource,
        ),
        NostrTag(type: "p", value: postToRepost.pubkey),
      ],
    );
    return _noteRepository.broadcastNote(myRepost);
  }

  /// delete a repost \
  /// [postId] the id of the post to delete the repost from \
  /// [throws] an exception if the repost is not found \
  /// [returns] a future that completes when the repost is deleted
  Future<void> deleteRepost({required String postId}) async {
    if (selfPubkey == null) {
      throw Exception("selfPubkey is null");
    }

    // get the repost to delete
    final myRepostEvent =
        await isPostRepostedBy(repostedByPubkey: selfPubkey!, postId: postId);
    if (myRepostEvent == null) {
      throw Exception("Repost event not found");
    }

    return _noteRepository.deleteNote(
      myRepostEvent.id,
    );
  }
}
