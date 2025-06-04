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
  Stream<List<NostrStarterPack>?> getPublicNostrStarterPacks({
    required String pubKey,
    required int kind,
  }) {
    final ndkSets = dartNdkSource.dartNdk.lists.getPublicSets(
      kind: kind,
      publicKey: pubKey,
      forceRefresh: false,
    );

    final listSets = ndkSets.asyncMap((sets) async {
      if (sets == null) return null;

      final starterPacks = <NostrStarterPack>[];
      for (final set in sets) {
        final starterPack = NostrStarterPackModel.fromNDK(set);
        starterPacks.add(starterPack);
      }
      return starterPacks;
    });
    return listSets;
  }

  // todo get list by name
}
