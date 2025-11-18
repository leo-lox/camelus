import 'package:riverpod/riverpod.dart';

import '../../data_layer/data_sources/dart_ndk_source.dart';
import '../../data_layer/repositories/search_repository_impl.dart';
import '../../domain_layer/repositories/search_repository.dart';
import '../../domain_layer/usecases/search.dart';
import 'ndk_provider.dart';

final searchProvider = Provider<Search>((ref) {
  final ndk = ref.watch(ndkProvider);

  final DartNdkSource dartNdkSource = DartNdkSource(ndk);

  final SearchRepository searchRepo = SearchRepositoryImpl(
    dartNdkSource: dartNdkSource,
  );

  final Search search = Search(searchRepo);

  return search;
});
