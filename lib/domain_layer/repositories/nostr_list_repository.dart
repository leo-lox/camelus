import '../entities/nostr_list.dart';

abstract class NostrListRepository {
  Future<NostrSet?> getNostrFollowSet({
    required String pubKey,
    required String name,
  });
}
