import '../entities/bloom_filter_data.dart';
import '../entities/nostr_note.dart';

abstract class ModerationRepository {
  Future<BloomFilterData?> fetchBloomFilterProfiles();
  Future<BloomFilterData?> fetchBloomFilterEvents();
  Future<String> reportToCamelus(NostrNote report);
}
