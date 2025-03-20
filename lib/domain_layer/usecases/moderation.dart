import 'package:ndk/ndk.dart';

import '../../data_layer/models/nostr_note_model.dart';
import '../entities/nostr_note.dart';
import '../entities/nostr_tag.dart';
import '../repositories/moderation_repository.dart';
import 'get_notes.dart';

class Moderation {
  static const _reportKind = 1984;

  final ModerationRepository _moderationRepository;

  final GetNotes _notes;
  final Ndk _ndk;

  Moderation({
    required ModerationRepository moderationrepository,
    required GetNotes notes,
    required Ndk ndk,
  })  : _moderationRepository = moderationrepository,
        _notes = notes,
        _ndk = ndk;

  Future<void> muteUser(String npub) async {
    throw UnimplementedError();
  }

  Future<void> unmuteUser(String npub) async {
    throw UnimplementedError();
  }

  Future<bool> isMuted(String npub) async {
    throw UnimplementedError();
  }

  /// returns a stream of mutet users by given npub
  Stream<List<String>> getMuted(String npub) {
    throw UnimplementedError();
  }

  ///    'size': <int>,
  ///    'numHashFunctions': <int>,
  ///    'bitArray': <string>,
  Future<Map<String, dynamic>?> fetchBloomFilterProfiles() {
    return _moderationRepository.fetchBloomFilterProfiles();
  }

  Future<bool> report({
    required String pubkeySubmittingReport,
    required String reportedPubkey,
    required bool reportToCamelus,
    required String reportReason,
    required String userReport,
    String? postId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final report = NostrNote(
      content: userReport,
      created_at: now,
      id: "",
      kind: _reportKind,
      pubkey: pubkeySubmittingReport,
      tags: [],
      sig: "",
    );
    // profile report
    if (postId == null) {
      report.tags.add(NostrTag(
        type: "p",
        value: reportedPubkey,
        marker: reportReason,
      ));
    } else {
      // event report
      report.tags.addAll([
        NostrTag(
          type: "e",
          value: postId,
          marker: reportReason,
        ),
        NostrTag(
          type: "p",
          value: reportedPubkey,
        ),
      ]);
    }

    final NostrNoteModel model = NostrNoteModel.fromEntity(report);
    final ndkEvent = model.toNDKEvent();

    // sign
    await _ndk.accounts.sign(ndkEvent);

    final signedReport = NostrNoteModel.fromNDKEvent(ndkEvent);

    final List<Future> futures = [
      _notes.broadcastNote(signedReport),
    ];

    if (reportToCamelus) {
      futures.add(
        _moderationRepository.reportToCamelus(signedReport),
      );
    }

    // send report
    try {
      await Future.wait(futures);
    } catch (e) {
      return false;
    }
    return true;
  }
}
