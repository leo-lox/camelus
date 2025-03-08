import '../entities/nostr_note.dart';
import '../entities/user_metadata.dart';
import '../repositories/search_repository.dart';

class Search {
  final SearchRepository repository;

  Search(this.repository);

  Future<List<UserMetadata>> searchMetadata(String query) async {
    return await repository.metadataSearch(query, limit: 10);
  }

  Future<List<NostrNote>> searchNotes({
    List<String>? ids,
    List<String>? authors,
    List<int>? kinds,
    Map<String, List<String>>? tags,
    int? since,
    int? until,
    String? search,
    int limit = 10,
  }) async {
    return await repository.searchEvents(
      ids: ids,
      authors: authors,
      kinds: kinds,
      tags: tags,
      since: since,
      until: until,
      search: search,
      limit: limit,
    );
  }
}
