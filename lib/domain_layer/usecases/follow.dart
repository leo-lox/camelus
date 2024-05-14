import '../entities/nostr_tag.dart';

class Follow {
  final String? selfPubkey;

  Follow({this.selfPubkey});

  set selfPubkey(String? value) {
    selfPubkey = value;
  }

  _checkSelfPubkey() {
    if (selfPubkey == null) {
      throw Exception("selfPubkey is null");
    }
  }

  Future<void> followUser(String npub) async {
    throw UnimplementedError();
  }

  Future<void> unfollowUser(String npub) async {
    throw UnimplementedError();
  }

  Future<void> setFollowing(List<NostrTag> contacts) async {
    throw UnimplementedError();
  }

  Future<bool> isFollowing(String npub) async {
    throw UnimplementedError();
  }

  Stream<List<NostrTag>> getFollowing(String npub) {
    throw UnimplementedError();
  }

  Stream<List<NostrTag>> getFollowingSelf() {
    _checkSelfPubkey();
    return getFollowing(selfPubkey!);
  }

  Stream<List<NostrTag>> getFollowers(String npub) {
    throw UnimplementedError();
  }

  Stream<List<NostrTag>> getFollowersSelf() {
    _checkSelfPubkey();
    return getFollowers(selfPubkey!);
  }
}
