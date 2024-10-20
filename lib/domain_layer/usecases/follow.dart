import 'package:camelus/domain_layer/entities/contact_list.dart';

import '../entities/nostr_tag.dart';
import '../repositories/follow_repository.dart';

class Follow {
  final String? selfPubkey;

  final FollowRepository followRepository;

  Follow({
    required this.selfPubkey,
    required this.followRepository,
  });

  _checkSelfPubkey() {
    if (selfPubkey == null) {
      throw Exception("selfPubkey is null");
    }
  }

  Future<void> followUser(String npub) async {
    return followRepository.followUser(npub);
  }

  Future<void> unfollowUser(String npub) async {
    return followRepository.unfollowUser(npub);
  }

  Future<void> setContacts(List<String> contacts) async {
    throw UnimplementedError();
  }

  Future<bool> isFollowing(String npub) async {
    throw UnimplementedError();
  }

  Future<ContactList> getContacts(String npub) {
    return followRepository.getContacts(npub);
  }

  Future<ContactList> getContactsSelf() {
    _checkSelfPubkey();
    return getContacts(selfPubkey!);
  }

  Stream<ContactList> getContactsStream(String npub) {
    return followRepository.getContactsStream(npub);
  }

  Stream<ContactList> getContactsStreamSelf() {
    _checkSelfPubkey();
    return getContactsStream(selfPubkey!);
  }

  Stream<List<NostrTag>> getFollowers(String npub) {
    throw UnimplementedError();
  }

  Stream<List<NostrTag>> getFollowersSelf() {
    _checkSelfPubkey();
    return getFollowers(selfPubkey!);
  }
}
