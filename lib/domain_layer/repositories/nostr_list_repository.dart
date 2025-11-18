import '../entities/nostr_list.dart';

abstract class NostrListRepository {
  Stream<List<NostrStarterPack>?> getPublicNostrStarterPacks({
    required String pubKey,
    required int kind,
  });

  Future<NostrStarterPack> broadcastStarterPack({
    required NostrStarterPack starterPack,
  });

  Future deleteStarterPack({required String name});

  Future<NostrStarterPack?> addUserToStarterPack({
    required String name,
    required String pubkey,
  });
}
