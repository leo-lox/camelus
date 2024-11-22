import '../entities/nostr_list.dart';

abstract class NostrListRepository {
  Future<NostrSet?> getPublicNostrFollowSet({
    required String pubKey,
    required String name,
  });
}
