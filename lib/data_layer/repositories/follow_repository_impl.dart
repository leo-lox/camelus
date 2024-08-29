import 'package:ndk/entities.dart' as ndk_entities;
import 'package:ndk/ndk.dart' as dart_ndk;

import '../../domain_layer/entities/contact_list.dart';
import '../../domain_layer/repositories/follow_repository.dart';
import '../data_sources/dart_ndk_source.dart';
import '../models/contact_list_model.dart';

class FollowRepositoryImpl implements FollowRepository {
  final DartNdkSource dartNdkSource;
  final dart_ndk.EventVerifier eventVerifier;

  FollowRepositoryImpl({
    required this.dartNdkSource,
    required this.eventVerifier,
  });

  @override
  Future<void> followUser(String npub) {
    // TODO: implement followUser
    throw UnimplementedError();
  }

  @override
  Future<ContactList> getContacts(String npub) async {
    dart_ndk.Filter filter = dart_ndk.Filter(
      authors: [npub],
      kinds: [ndk_entities.ContactList.KIND],
    );

    final response = dartNdkSource.dartNdk.requests
        .query(filters: [filter], idPrefix: 'get_contacts');

    final responseList = await response.stream.toList();

    responseList.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final ndkContactList =
        ndk_entities.ContactList.fromEvent(responseList.first);

    return ContactListModel.fromNdk(ndkContactList);
  }

  @override
  Stream<ContactList> getContactsStream(String npub) {
    dart_ndk.Filter filter = dart_ndk.Filter(
      authors: [npub],
      kinds: [ndk_entities.ContactList.KIND],
    );

    final response = dartNdkSource.dartNdk.requests
        .subscription(filters: [filter], id: 'get_contact_stream');

    var lastReceived = 0;
    final contactListStream = response.stream.where((event) {
      // Extract the timestamp from the event.
      final eventTimestamp = event.createdAt;

      // Check if the event is older than the last received timestamp.
      final isOlder = eventTimestamp < lastReceived;

      // Update the last received timestamp if the event is newer.
      if (!isOlder) {
        lastReceived = eventTimestamp;
      }

      // Return true to keep the event if it's older, false to discard it.
      return isOlder;
    }).map((event) {
      // Convert the event to a ndk_nip02.ContactList object.
      final ndkContactList = ndk_entities.ContactList.fromEvent(event);
      // Convert the ndk_nip02.ContactList object to a ContactListModel object.
      return ContactListModel.fromNdk(ndkContactList);
    });

    return contactListStream;
  }

  @override
  Stream<List<String>> getFollowers(String npub) {
    // TODO: implement getFollowers
    throw UnimplementedError();
  }

  @override
  Future<bool> isFollowing(String npub) {
    // TODO: implement isFollowing
    throw UnimplementedError();
  }

  @override
  Future<void> setFollowing(ContactList contactList) {
    // TODO: implement setFollowing
    throw UnimplementedError();
  }

  @override
  Future<void> unfollowUser(String npub) {
    // TODO: implement unfollowUser
    throw UnimplementedError();
  }
}
