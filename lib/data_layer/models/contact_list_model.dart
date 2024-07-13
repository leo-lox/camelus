import 'package:camelus/domain_layer/entities/contact_list.dart';
import 'package:dart_ndk/entities.dart' as ndk_entities;

class ContactListModel extends ContactList {
  ContactListModel({
    required super.pubKey,
    required super.contacts,
    required super.contactRelays,
    required super.petnames,
    required super.followedTags,
    required super.followedCommunities,
    required super.followedEvents,
    required super.sources,
    required super.createdAt,
    required super.loadedTimestamp,
  });

  factory ContactListModel.fromNdk(ndk_entities.ContactList ndkContactList) {
    return ContactListModel(
      pubKey: ndkContactList.pubKey,
      contacts: ndkContactList.contacts,
      contactRelays: ndkContactList.contactRelays,
      petnames: ndkContactList.petnames,
      followedTags: ndkContactList.followedTags,
      followedCommunities: ndkContactList.followedCommunities,
      followedEvents: ndkContactList.followedEvents,
      sources: ndkContactList.sources,
      createdAt: ndkContactList.createdAt,
      loadedTimestamp: ndkContactList.loadedTimestamp,
    );
  }
}
