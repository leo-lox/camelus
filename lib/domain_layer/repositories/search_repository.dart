import '../entities/nostr_note.dart';
import '../entities/user_metadata.dart';

abstract class SearchRepository {
  Future<List<UserMetadata>> metadataSearch(String query, {int limit = 10});

  Future<List<NostrNote>> searchEvents({
    List<String>? ids,
    List<String>? authors,
    List<int>? kinds,
    Map<String, List<String>>? tags,
    int? since,
    int? until,
    String? search,
    int limit = 10,
  });
}
