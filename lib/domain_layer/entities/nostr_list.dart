class NostrList {
  static const int MUTE = 10000;
  static const int PIN = 10001;
  static const int BOOKMARKS = 10003;
  static const int COMMUNITIES = 10004;
  static const int PUBLIC_CHATS = 10005;
  static const int BLOCKED_RELAYS = 10006;
  static const int SEARCH_RELAYS = 10007;
  static const int INTERESTS = 10015;
  static const int EMOJIS = 10030;

  static const int FOLLOW_SET = 30000;
  static const int RELAY_SET = 30002;
  static const int BOOKMARKS_SET = 30003;
  static const int CURATION_SET = 30004;
  static const int INTERESTS_SET = 30015;
  static const int EMOJIS_SET = 30030;

  static const String RELAY = "relay";
  static const String PUB_KEY = "p";
  static const String HASHTAG = "t";
  static const String WORD = "word";
  static const String THREAD = "e";
  static const String RESOURCE = "r";
  static const String EMOJI = "emoji";
  static const String A = "a";

  static const List<int> POSSIBLE_KINDS = [
    MUTE,
    PIN,
    BOOKMARKS,
    COMMUNITIES,
    PUBLIC_CHATS,
    BLOCKED_RELAYS,
    SEARCH_RELAYS,
    INTERESTS,
    EMOJIS,
    FOLLOW_SET,
    RELAY_SET,
    BOOKMARKS_SET,
    CURATION_SET,
    INTERESTS_SET,
    EMOJIS_SET
  ];

  static const List<String> POSSIBLE_TAGS = [
    RELAY,
    PUB_KEY,
    HASHTAG,
    WORD,
    THREAD,
    RESOURCE,
    EMOJI,
    A
  ];

  late String id;
  late String pubKey;
  late int kind;

  List<NostrListElement> elements = [];

  List<NostrListElement> byTag(String tag) =>
      elements.where((element) => element.tag == tag).toList();

  List<NostrListElement> get relays => byTag(RELAY);
  List<NostrListElement> get pubKeys => byTag(PUB_KEY);
  List<NostrListElement> get hashtags => byTag(HASHTAG);
  List<NostrListElement> get words => byTag(WORD);
  List<NostrListElement> get threads => byTag(THREAD);

  List<String> get publicRelays =>
      relays.where((element) => !element.private).map((e) => e.value).toList();
  List<String> get privateRelays =>
      relays.where((element) => !element.private).map((e) => e.value).toList();

  set privateRelays(List<String> list) {
    elements.removeWhere((element) => element.tag == RELAY && element.private);
    elements.addAll(list
        .map((url) => NostrListElement(tag: RELAY, value: url, private: true)));
  }

  set publicRelays(List<String> list) {
    elements.removeWhere((element) => element.tag == RELAY && !element.private);
    elements.addAll(list.map(
        (url) => NostrListElement(tag: RELAY, value: url, private: false)));
  }

  late int createdAt;

  @override
  // coverage:ignore-start
  String toString() {
    return 'Nip51List { $kind}';
  }
  // coverage:ignore-end

  String get displayTitle {
    if (kind == NostrList.SEARCH_RELAYS) {
      return "Search";
    }
    if (kind == NostrList.BLOCKED_RELAYS) {
      return "Blocked";
    }
    if (kind == NostrList.MUTE) {
      return "Mute";
    }
    return "kind $kind";
  }

  List<String> get allRelays => relays.map((e) => e.value).toList();

  NostrList({
    required this.pubKey,
    required this.kind,
    required this.createdAt,
    required this.elements,
  });

  void parseTags(List tags, {required bool private}) {
    for (var tag in tags) {
      if (tag is! List<dynamic>) continue;
      final length = tag.length;
      if (length <= 1) continue;
      final tagName = tag[0];
      final value = tag[1];
      if (POSSIBLE_TAGS.contains(tagName)) {
        elements.add(
            NostrListElement(tag: tagName, value: value, private: private));
      }
    }
  }

  void addRelay(String relayUrl, bool private) {
    elements
        .add(NostrListElement(tag: RELAY, value: relayUrl, private: private));
  }

  void addElement(String tag, String value, bool private) {
    elements.add(NostrListElement(tag: tag, value: value, private: private));
  }

  void removeRelay(String relayUrl) {
    elements.removeWhere(
        (element) => element.tag == RELAY && element.value == relayUrl);
  }

  void removeElement(String tag, String value) {
    elements
        .removeWhere((element) => element.tag == tag && element.value == value);
  }
}

class NostrListElement {
  bool private;
  String tag;
  String value;

  NostrListElement({
    required this.tag,
    required this.value,
    required this.private,
  });
}

class NostrSet extends NostrList {
  late String name;
  String? title;
  String? description;
  String? image;

  @override
  String toString() {
    return 'Nip51Set { $name}';
  }

  /// Create a new Nip51Set
  /// default kind is Nip51List.FOLLOW_SET
  NostrSet({
    required super.pubKey,
    required this.name,
    required super.createdAt,
    required super.elements,
    this.title,
    super.kind = NostrList.FOLLOW_SET,
  });

  void parseSetTags(List tags) {
    for (var tag in tags) {
      if (tag is! List<dynamic>) continue;
      final length = tag.length;
      if (length <= 1) continue;
      final tagName = tag[0];
      final value = tag[1];
      if (tagName == "d") {
        name = value;
        continue;
      }
      if (tagName == "title") {
        title = value;
        continue;
      }
      if (tagName == "description") {
        description = value;
        continue;
      }
      if (tagName == "image") {
        image = value;
        continue;
      }
    }
  }
}
