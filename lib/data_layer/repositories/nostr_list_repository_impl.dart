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
  Future<NostrSet?> getPublicNostrFollowSet({
    required String pubKey,
    required String name,
  }) async {
    final ndkSet =
        await dartNdkSource.dartNdk.lists.getSinglePublicNip51RelaySet(
      name: name,
      publicKey: pubKey,
    );

    if (ndkSet == null) {
      return null;
    }
    final listSet = NostrSetModel.fromNDK(ndkSet);
    return listSet;
  }

  @override
  Future<List<NostrSet>?> getPublicNostrSets({
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

    final listSets = ndkSets.map((e) => NostrSetModel.fromNDK(e)).toList();
    return listSets;
  }
}
