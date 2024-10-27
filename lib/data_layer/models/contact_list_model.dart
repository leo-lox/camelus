import 'package:camelus/domain_layer/entities/contact_list.dart';
import 'package:ndk/entities.dart' as ndk_entities;

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

  ndk_entities.ContactList toNdk() {
    final ndkContactList = ndk_entities.ContactList(
      pubKey: pubKey,
      contacts: contacts,
    );

    ndkContactList.contactRelays = contactRelays;
    ndkContactList.petnames = petnames;
    ndkContactList.followedTags = followedTags;
    ndkContactList.followedCommunities = followedCommunities;
    ndkContactList.followedEvents = followedEvents;
    ndkContactList.sources = sources;
    ndkContactList.createdAt = createdAt;
    ndkContactList.loadedTimestamp = loadedTimestamp;

    return ndkContactList;
  }

  factory ContactListModel.fromContactList(ContactList contactList) {
    return ContactListModel(
      pubKey: contactList.pubKey,
      contacts: contactList.contacts,
      contactRelays: contactList.contactRelays,
      petnames: contactList.petnames,
      followedTags: contactList.followedTags,
      followedCommunities: contactList.followedCommunities,
      followedEvents: contactList.followedEvents,
      sources: contactList.sources,
      createdAt: contactList.createdAt,
      loadedTimestamp: contactList.loadedTimestamp,
    );
  }
}
