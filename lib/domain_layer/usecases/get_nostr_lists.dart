import '../entities/nostr_list.dart';
import '../repositories/nostr_list_repository.dart';

class GetNostrLists {
  final NostrListRepository _nostrListRepository;

  GetNostrLists({required NostrListRepository nostrListRepository})
    : _nostrListRepository = nostrListRepository;

  /// gives you all the public sets by a user
  Stream<List<NostrSet>?> getPublicNostrStarterPacks({required String pubKey}) {
    return _nostrListRepository.getPublicNostrStarterPacks(
      pubKey: pubKey,
      kind: NostrList.starterPack,
    );
  }

  Future<NostrSet> broadcastStarterPack({required NostrSet starterPack}) {
    return _nostrListRepository.broadcastStarterPack(starterPack: starterPack);
  }

  Future deleteStarterPack({required String name}) {
    return _nostrListRepository.deleteStarterPack(name: name);
  }

  Future<NostrSet?> addUserToStarterPack({
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
  Future<NostrList?> getSingleList({required int kind}) {
    return _nostrListRepository.getSingleList(kind: kind);
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

  /// Get public sets of any kind for a given pubkey
  Stream<List<NostrSet>?> getPublicSets({
    required String pubKey,
    required int kind,
  }) {
    return _nostrListRepository.getPublicNostrStarterPacks(
      pubKey: pubKey,
      kind: kind,
    );
  }

  /// Broadcast a NIP-51 set of any kind (uses list.kind)
  Future<NostrSet> broadcastList({required NostrSet list}) {
    return _nostrListRepository.broadcastSet(set: list);
  }

  /// Delete a NIP-51 set of any kind
  Future<void> deleteList({required String name, required int kind}) {
    return _nostrListRepository.deleteListSet(name: name, kind: kind);
  }
}
