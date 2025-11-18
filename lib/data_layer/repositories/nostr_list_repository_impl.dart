import '../../domain_layer/entities/nostr_list.dart';
import '../../domain_layer/repositories/nostr_list_repository.dart';
import '../data_sources/dart_ndk_source.dart';
import '../models/nostr_lists_model.dart';

class NostrListRepositoryImpl implements NostrListRepository {
  final DartNdkSource dartNdkSource;

  NostrListRepositoryImpl({required this.dartNdkSource});

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

  @override
  Future<NostrStarterPack> broadcastStarterPack({
    required NostrStarterPack starterPack,
  }) async {
    final ndkStarterPack = NostrStarterPackModel.fromEntity(
      starterPack,
    ).toNDK();
    final result = await dartNdkSource.dartNdk.lists.setCompleteSet(
      set: ndkStarterPack,
      kind: NostrList.starterPack,
    );
    return NostrStarterPackModel.fromNDK(result);
  }

  @override
  Future deleteStarterPack({required String name}) {
    return dartNdkSource.dartNdk.lists.deleteSet(
      name: name,
      kind: NostrList.starterPack,
    );
  }

  @override
  Future<NostrStarterPack?> addUserToStarterPack({
    required String name,
    required String pubkey,
  }) async {
    final ndkSet = await dartNdkSource.dartNdk.lists.addElementToSet(
      tag: 'p',
      value: pubkey,
      name: name,
      kind: NostrList.starterPack,
    );
    if (ndkSet == null) {
      return null;
    }
    return NostrStarterPackModel.fromNDK(ndkSet);
  }

  @override
  Future<NostrList?> getSingleList({
    required int kind,
  }) async {
    final signer = dartNdkSource.dartNdk.accounts.getLoggedAccount()?.signer;
    if (signer == null) return null;

    final ndkList = await dartNdkSource.dartNdk.lists.getSingleNip51List(
      kind,
      signer,
      forceRefresh: false,
    );

    if (ndkList == null) return null;
    return NostrListModel.fromNDK(ndkList);
  }

  @override
  Future<NostrList> addElementToList({
    required String tag,
    required String value,
    required int kind,
    bool private = false,
  }) async {
    final ndkList = await dartNdkSource.dartNdk.lists.addElementToList(
      tag: tag,
      value: value,
      kind: kind,
      private: private,
    );
    return NostrListModel.fromNDK(ndkList);
  }

  @override
  Future<NostrList?> removeElementFromList({
    required String tag,
    required String value,
    required int kind,
  }) async {
    final ndkList = await dartNdkSource.dartNdk.lists.removeElementFromList(
      tag: tag,
      value: value,
      kind: kind,
    );
    if (ndkList == null) return null;
    return NostrListModel.fromNDK(ndkList);
  }
}
