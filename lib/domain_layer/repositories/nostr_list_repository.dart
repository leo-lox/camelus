import '../entities/nostr_list.dart';

abstract class NostrListRepository {
  Stream<List<NostrStarterPack>?> getPublicNostrStarterPacks({
    required String pubKey,
    required int kind,
  });

  Future<NostrStarterPack> broadcastStarterPack({
    required NostrStarterPack starterPack,
  });

  Future deleteStarterPack({
    required String name,
  });

  Future<NostrStarterPack?> addUserToStarterPack({
    required String name,
    required String pubkey,
  });

  /// Get a single list (kind 10000-10030) for the logged-in user
  Future<NostrList?> getSingleList({
    required int kind,
  });

  /// Add an element to a list (kind 10000-10030)
  Future<NostrList> addElementToList({
    required String tag,
    required String value,
    required int kind,
    bool private,
  });

  /// Remove an element from a list (kind 10000-10030)
  Future<NostrList?> removeElementFromList({
    required String tag,
    required String value,
    required int kind,
  });
}
