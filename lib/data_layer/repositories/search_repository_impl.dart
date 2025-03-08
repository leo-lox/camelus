import 'package:camelus/data_layer/models/nostr_note_model.dart';
import 'package:camelus/data_layer/models/user_metadata_model.dart';
import 'package:camelus/domain_layer/entities/nostr_note.dart';

import '../../domain_layer/entities/user_metadata.dart';
import '../../domain_layer/repositories/search_repository.dart';
import '../data_sources/dart_ndk_source.dart';

class SearchRepositoryImpl implements SearchRepository {
  final DartNdkSource _ndkDataSource;

  SearchRepositoryImpl({
    required DartNdkSource dartNdkSource,
  }) : _ndkDataSource = dartNdkSource;

  @override
  Future<List<UserMetadata>> metadataSearch(String query,
      {int limit = 10}) async {
    final results =
        await _ndkDataSource.dartNdk.search.metadataSearch(query, limit: limit);
    return results.map((e) => UserMetadataModel.fromNDKMetadata(e)).toList();
  }

  @override
  Future<List<NostrNote>> searchEvents({
    List<String>? ids,
    List<String>? authors,
    List<int>? kinds,
    Map<String, List<String>>? tags,
    int? since,
    int? until,
    String? search,
    int limit = 10,
  }) async {
    final results = await _ndkDataSource.dartNdk.search.searchEvents(
      ids: ids,
      authors: authors,
      kinds: kinds,
      tags: tags,
      since: since,
      until: until,
      search: search,
      limit: limit,
    );
    return results.map((e) => NostrNoteModel.fromNDKEvent(e)).toList();
  }
}
