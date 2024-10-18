import 'package:ndk/entities.dart' as ndk_entities;
import 'package:ndk/ndk.dart' as dart_ndk;

import '../../domain_layer/entities/contact_list.dart';
import '../../domain_layer/repositories/follow_repository.dart';
import '../data_sources/dart_ndk_source.dart';
import '../models/contact_list_model.dart';

class FollowRepositoryImpl implements FollowRepository {
  final DartNdkSource dartNdkSource;
  final dart_ndk.EventVerifier eventVerifier;
  final dart_ndk.EventSigner eventSigner;

  FollowRepositoryImpl({
    required this.dartNdkSource,
    required this.eventVerifier,
    required this.eventSigner,
  });

  @override
  Future<ContactList> getContacts(String npub) async {
    dart_ndk.Filter filter = dart_ndk.Filter(
      authors: [npub],
      kinds: [ndk_entities.ContactList.KIND],
    );

    final response = dartNdkSource.dartNdk.requests
        .query(filters: [filter], name: 'get_contacts');

    final responseList = await response.stream.toList();

    responseList.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final ndkContactList =
        ndk_entities.ContactList.fromEvent(responseList.first);

    return ContactListModel.fromNdk(ndkContactList);
  }

  @override
  Stream<ContactList> getContactsStream(String npub) {
    final ndkResponse = dartNdkSource.dartNdk.follows.getContactList(npub);

    return ndkResponse.asStream().map((ndkContactList) {
      return ContactListModel.fromNdk(ndkContactList!);
    });
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
    final ndkContactList = (contactList as ContactListModel).toNdk();

    throw UnimplementedError();
    // return dartNdkSource.dartNdk.follows
    //     .broadcastSetContacts(ndkContactList, [], eventSigner);
  }

  @override
  Future<void> followUser(String npub) async {
    final newContactList =
        await dartNdkSource.dartNdk.follows.broadcastAddContact(npub);
    print(newContactList.contacts);
  }

  @override
  Future<void> unfollowUser(String npub) {
    // TODO: implement unfollowUser
    throw UnimplementedError();
  }
}
