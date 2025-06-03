import '../entities/nostr_list.dart';
import '../repositories/nostr_list_repository.dart';

class GetNostrLists {
  final NostrListRepository _nostrListRepository;

  GetNostrLists({
    required NostrListRepository nostrListRepository,
  }) : _nostrListRepository = nostrListRepository;

  /// gives you all the public sets by a user
  Future<List<NostrStarterPack>?> getPublicNostrStarterPacks({
    required String pubKey,
  }) {
    return _nostrListRepository.getPublicNostrStarterPacks(
      pubKey: pubKey,
      kind: NostrList.STARTER_PACK,
    );
  }
}
