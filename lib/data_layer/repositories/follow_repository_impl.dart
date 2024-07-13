import 'package:dart_ndk/relay_jit_manager/request_jit.dart';

import 'package:dart_ndk/entities.dart' as ndk_entities;
import 'package:dart_ndk/dart_ndk.dart';

import '../../domain_layer/entities/contact_list.dart';
import '../../domain_layer/repositories/follow_repository.dart';
import '../data_sources/dart_ndk_source.dart';
import '../models/contact_list_model.dart';

class FollowRepositoryImpl implements FollowRepository {
  final DartNdkSource dartNdkSource;
  final EventVerifier eventVerifier;

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
    Filter filter = Filter(
      authors: [npub],
      kinds: [ndk_entities.ContactList.KIND],
    );
    NostrRequestJit request = NostrRequestJit.query(
      'get_contacts',
      eventVerifier: eventVerifier,
      filters: [filter],
    );
    dartNdkSource.relayJitManager.handleRequest(request);

    final responseList = await request.responseList;

    responseList.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final ndkContactList =
        ndk_entities.ContactList.fromEvent(responseList.first);

    return ContactListModel.fromNdk(ndkContactList);
  }

  @override
  Stream<ContactList> getContactsStream(String npub) {
    Filter filter = Filter(
      authors: [npub],
      kinds: [ndk_entities.ContactList.KIND],
    );
    NostrRequestJit request = NostrRequestJit.subscription(
      'get_contacts_stream',
      eventVerifier: eventVerifier,
      filters: [filter],
    );
    dartNdkSource.relayJitManager.handleRequest(request);

    var lastReceived = 0;
    final contactListStream = request.responseStream.where((event) {
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
