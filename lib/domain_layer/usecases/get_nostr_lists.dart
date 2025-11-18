import '../entities/nostr_list.dart';
import '../repositories/nostr_list_repository.dart';

class GetNostrLists {
  final NostrListRepository _nostrListRepository;

  GetNostrLists({required NostrListRepository nostrListRepository})
    : _nostrListRepository = nostrListRepository;

  /// gives you all the public sets by a user
  Stream<List<NostrStarterPack>?> getPublicNostrStarterPacks({
    required String pubKey,
  }) {
    return _nostrListRepository.getPublicNostrStarterPacks(
      pubKey: pubKey,
      kind: NostrList.starterPack,
    );
  }

  Future<NostrStarterPack> broadcastStarterPack({
    required NostrStarterPack starterPack,
  }) {
    return _nostrListRepository.broadcastStarterPack(starterPack: starterPack);
  }

  Future deleteStarterPack({required String name}) {
    return _nostrListRepository.deleteStarterPack(name: name);
  }

  Future<NostrStarterPack?> addUserToStarterPack({
    required String name,
    required String pubkey,
  }) {
    return _nostrListRepository.addUserToStarterPack(
      name: name,
      pubkey: pubkey,
    );
  }
}
