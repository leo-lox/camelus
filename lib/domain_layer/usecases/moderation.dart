import '../entities/nostr_note.dart';
import '../entities/nostr_tag.dart';
import '../repositories/moderation_repository.dart';
import 'get_notes.dart';

class Moderation {
  static const _reportKind = 1984;

  final ModerationRepository _moderationRepository;

  final GetNotes _notes;

  Moderation({
    required ModerationRepository moderationrepository,
    required GetNotes notes,
  })  : _moderationRepository = moderationrepository,
        _notes = notes;

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
    final report = NostrNote(
      content: userReport,
      created_at: 0,
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

    // send report
    try {
      await Future.wait([
        _moderationRepository.reportToCamelus(report),
        _notes.broadcastNote(report)
      ]);
    } catch (e) {
      return false;
    }
    return true;
  }
}
