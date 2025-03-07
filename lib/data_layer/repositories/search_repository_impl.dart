import 'package:camelus/data_layer/models/user_metadata_model.dart';

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
}
