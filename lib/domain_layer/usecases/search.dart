import '../entities/user_metadata.dart';
import '../repositories/search_repository.dart';

class Search {
  final SearchRepository repository;

  Search(this.repository);

  Future<List<UserMetadata>> searchMetadata(String query) async {
    return await repository.metadataSearch(query, limit: 10);
  }
}
