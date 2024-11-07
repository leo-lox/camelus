import 'package:objectbox/objectbox.dart';
import 'package:ndk/entities.dart' as ndk_entities;

@Entity()
class DbContactList {
  @Id()
  int dbId = 0;

  @Property()
  late String pubKey;

  @Property()
  List<String> contacts = [];

  @Property()
  List<String> contactRelays = [];

  @Property()
  List<String> petnames = [];

  @Property()
  List<String> followedTags = [];

  @Property()
  List<String> followedCommunities = [];

  @Property()
  List<String> followedEvents = [];

  @Property()
  int createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  @Property()
  int? loadedTimestamp;

  @Property()
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
