import '../entities/nostr_note.dart';

abstract class ModerationRepository {
  Future<Map<String, dynamic>?> fetchBloomFilterProfiles();
  Future<String> reportToCamelus(NostrNote report);
}
