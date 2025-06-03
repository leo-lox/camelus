import 'dart:developer';

import 'package:ndk/ndk.dart' as ndk;

import '../../domain_layer/entities/nostr_list.dart';
import '../../domain_layer/repositories/nostr_list_repository.dart';
import '../data_sources/dart_ndk_source.dart';
import '../models/nostr_lists_model.dart';

class NostrListRepositoryImpl implements NostrListRepository {
  final DartNdkSource dartNdkSource;

  NostrListRepositoryImpl({
    required this.dartNdkSource,
  });

  @override
  Future<List<NostrStarterPack>?> getPublicNostrStarterPacks({
    required String pubKey,
    required int kind,
  }) async {
    final ndkSets = await dartNdkSource.dartNdk.lists.getPublicNip51RelaySets(
      kind: kind,
      publicKey: pubKey,
      forceRefresh: false,
    );

    if (ndkSets == null) {
      return null;
    }

    final listSets =
        ndkSets.map((e) => NostrStarterPackModel.fromNDK(e)).toList();
    return listSets;
  }
}
