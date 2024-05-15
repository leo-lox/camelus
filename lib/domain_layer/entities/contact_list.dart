class ContactList {
  late String pubKey;

  List<String> contacts = [];
  List<String> contactRelays = [];
  List<String> petnames = [];

  List<String> followedTags = [];
  List<String> followedCommunities = [];
  List<String> followedEvents = [];

  List<String> sources = [];

  int createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  int? loadedTimestamp;

  ContactList({
    required this.pubKey,
    required this.contacts,
    required this.contactRelays,
    required this.petnames,
    required this.followedTags,
    required this.followedCommunities,
    required this.followedEvents,
    required this.sources,
    required this.createdAt,
    required this.loadedTimestamp,
  });
}
