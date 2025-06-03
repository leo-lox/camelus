import '../entities/nostr_list.dart';

abstract class NostrListRepository {
  Future<List<NostrStarterPack>?> getPublicNostrStarterPacks({
    required String pubKey,
    required int kind,
  });
}
