import '../entities/user_metadata.dart';

abstract class SearchRepository {
  Future<List<UserMetadata>> metadataSearch(String query, {int limit = 10});
}
