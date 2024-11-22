import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data_layer/data_sources/dart_ndk_source.dart';
import '../../data_layer/repositories/nostr_list_repository_impl.dart';
import '../../domain_layer/repositories/nostr_list_repository.dart';
import '../../domain_layer/usecases/get_nostr_lists.dart';

import 'ndk_provider.dart';

final nostrListProvider = Provider<GetNostrLists>((ref) {
  final ndk = ref.watch(ndkProvider);

  final DartNdkSource dartNdkSource = DartNdkSource(ndk);

  final NostrListRepository listsRepo = NostrListRepositoryImpl(
    dartNdkSource: dartNdkSource,
  );

  final GetNostrLists getLists = GetNostrLists(nostrListRepository: listsRepo);

  return getLists;
});
