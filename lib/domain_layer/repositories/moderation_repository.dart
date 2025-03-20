import '../entities/bloom_filter_data.dart';
import '../entities/nostr_note.dart';

abstract class ModerationRepository {
  Future<BloomFilterData?> fetchBloomFilterProfiles();
  Future<String> reportToCamelus(NostrNote report);
}
