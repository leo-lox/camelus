import 'package:camelus/domain_layer/entities/contact_list.dart';

abstract class FollowRepository {
  FollowRepository();

  Future<ContactList?> followUser(String npub);

  Future<ContactList?> unfollowUser(String npub);

  Future<void> setFollowing(ContactList contactList);

  Future<bool> isFollowing(String npub);

  Future<ContactList?> getContacts(String npub, {int? timeout});

  Stream<ContactList> getContactsStream(String npub);

  Stream<List<String>> getFollowers(String npub);
}
