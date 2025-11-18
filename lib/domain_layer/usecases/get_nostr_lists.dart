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

  /// Get a single list (kind 10000-10030) for the logged-in user
  /// Use this for bookmarks (10003), mutes (10000), pins (10001), etc.
  Future<NostrList?> getSingleList({
    required int kind,
  }) {
    return _nostrListRepository.getSingleList(
      kind: kind,
    );
  }

  /// Add an element to a list
  /// For bookmarks: tag='e', value=eventId, kind=NostrList.bookmarks, private=true/false
  /// For mutes: tag='p', value=pubkey, kind=NostrList.mute
  Future<NostrList> addElementToList({
    required String tag,
    required String value,
    required int kind,
    bool private = false,
  }) {
    return _nostrListRepository.addElementToList(
      tag: tag,
      value: value,
      kind: kind,
      private: private,
    );
  }

  /// Remove an element from a list
  /// Note: The NDK will automatically handle private elements
  Future<NostrList?> removeElementFromList({
    required String tag,
    required String value,
    required int kind,
  }) {
    return _nostrListRepository.removeElementFromList(
      tag: tag,
      value: value,
      kind: kind,
    );
  }
}
