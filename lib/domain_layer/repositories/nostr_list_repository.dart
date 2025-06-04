import '../entities/nostr_list.dart';

abstract class NostrListRepository {
  Stream<List<NostrStarterPack>?> getPublicNostrStarterPacks({
    required String pubKey,
    required int kind,
  });
}
