import '../entities/nostr_list.dart';
import '../repositories/nostr_list_repository.dart';

class GetNostrLists {
  final NostrListRepository _nostrListRepository;

  GetNostrLists({
    required NostrListRepository nostrListRepository,
  }) : _nostrListRepository = nostrListRepository;

  Future<NostrSet?> getPublicNostrFollowSet({
    required String pubKey,
    required String name,
  }) {
    return _nostrListRepository.getPublicNostrFollowSet(
      pubKey: pubKey,
      name: name,
    );
  }

  /// gives you all the public sets by a user
  Future<List<NostrSet>?> getPublicNostrFollowSets({
    required String pubKey,
  }) {
    return _nostrListRepository.getPublicNostrSets(
      pubKey: pubKey,
      kind: NostrList.FOLLOW_SET,
    );
  }
}
