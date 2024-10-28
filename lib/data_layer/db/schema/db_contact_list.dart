import 'package:isar/isar.dart';
import 'package:ndk/entities.dart' as ndk_entities;

part 'db_contact_list.g.dart';

@collection
class DbContactList {
  Id dbId = Isar.autoIncrement;

  late String pubKey;

  /// contacts (public keys)
  List<String> contacts = [];

  /// contacts relays
  List<String> contactRelays = [];

  /// petnames
  List<String> petnames = [];

  /// followed tags
  List<String> followedTags = [];

  /// followed communities
  List<String> followedCommunities = [];

  /// followed events
  List<String> followedEvents = [];

  /// create at timestamp
  int createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  /// loaded at timestamp
  int? loadedTimestamp;

  /// relay sources
  List<String> sources = [];

  DbContactList({
    required this.pubKey,
    required this.contacts,
  });

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

  factory DbContactList.fromNdk(ndk_entities.ContactList ndkContactList) {
    final dbContactList = DbContactList(
      pubKey: ndkContactList.pubKey,
      contacts: ndkContactList.contacts,
    );
    dbContactList.contactRelays = ndkContactList.contactRelays;
    dbContactList.petnames = ndkContactList.petnames;
    dbContactList.followedTags = ndkContactList.followedTags;
    dbContactList.followedCommunities = ndkContactList.followedCommunities;
    dbContactList.followedEvents = ndkContactList.followedEvents;
    dbContactList.sources = ndkContactList.sources;
    dbContactList.createdAt = ndkContactList.createdAt;
    dbContactList.loadedTimestamp = ndkContactList.loadedTimestamp;
    return dbContactList;
  }
}
