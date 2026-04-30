import '../../domain_layer/entities/nostr_list.dart';
import '../../domain_layer/repositories/nostr_list_repository.dart';
import '../data_sources/dart_ndk_source.dart';
import '../models/nostr_lists_model.dart';

class NostrListRepositoryImpl implements NostrListRepository {
  final DartNdkSource dartNdkSource;

  NostrListRepositoryImpl({required this.dartNdkSource});

  @override
  Stream<List<NostrSet>?> getPublicNostrStarterPacks({
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

      final starterPacks = <NostrSet>[];
      for (final set in sets) {
        final starterPack = NostrSetModel.fromNDK(set);
        starterPacks.add(starterPack);
      }
      return starterPacks;
    });
    return listSets;
  }

  @override
  Future<NostrSet> broadcastStarterPack({required NostrSet starterPack}) async {
    final ndkSet = NostrSetModel.fromEntity(starterPack).toNDK();
    final result = await dartNdkSource.dartNdk.lists.setCompleteSet(
      set: ndkSet,
      kind: NostrList.starterPack,
    );
    return NostrSetModel.fromNDK(result);
  }

  @override
  Future deleteStarterPack({required String name}) {
    return dartNdkSource.dartNdk.lists.deleteSet(
      name: name,
      kind: NostrList.starterPack,
    );
  }

  @override
  Future<NostrSet?> addUserToStarterPack({
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
    return NostrSetModel.fromNDK(ndkSet);
  }

  @override
  Future<NostrList?> getSingleList({required int kind}) async {
    final ndkList = await dartNdkSource.dartNdk.lists.getSingleNip51List(
      kind,

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

  @override
  Stream<List<NostrSet>?> getMyNostrSets({required int kind}) {
    // Call without publicKey so NDK uses the full account signer,
    // which allows decryption of private elements.
    final ndkSets = dartNdkSource.dartNdk.lists.getPublicSets(
      kind: kind,
      forceRefresh: false,
    );

    return ndkSets.asyncMap((sets) async {
      if (sets == null) return null;
      final result = <NostrSet>[];
      for (final set in sets) {
        result.add(NostrSetModel.fromNDK(set));
      }
      return result;
    });
  }

  @override
  Future<NostrSet> broadcastSet({required NostrSet set}) async {
    final ndkSet = NostrSetModel.fromEntity(set).toNDK();
    final result = await dartNdkSource.dartNdk.lists.setCompleteSet(
      set: ndkSet,
      kind: set.kind,
    );
    return NostrSetModel.fromNDK(result);
  }

  @override
  Future<void> deleteListSet({required String name, required int kind}) {
    return dartNdkSource.dartNdk.lists.deleteSet(name: name, kind: kind);
  }
}
