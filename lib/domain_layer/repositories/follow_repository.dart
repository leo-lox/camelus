import 'package:camelus/domain_layer/entities/contact_list.dart';

abstract class FollowRepository {
  FollowRepository();

  Future<void> followUser(String npub);

  Future<void> unfollowUser(String npub);

  Future<void> setFollowing(ContactList contactList);

  Future<bool> isFollowing(String npub);

  Stream<ContactList> getContacts(String npub);

  Stream<List<String>> getFollowers(String npub);
}
