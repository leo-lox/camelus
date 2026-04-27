class NostrList {
  static const int mute = 10000;
  static const int pin = 10001;
  static const int bookmarks = 10003;
  static const int communities = 10004;
  static const int publicChats = 10005;
  static const int blockedRelays = 10006;
  static const int searchRelays = 10007;
  static const int interests = 10015;
  static const int emojis = 10030;

  static const int followSet = 30000;
  static const int starterPack = 39089;
  static const int relaySet = 30002;
  static const int bookmarksSet = 30003;
  static const int curationSet = 30004;
  static const int interestsSet = 30015;
  static const int emojisSet = 30030;

  static const String relay = "relay";
  static const String pubkeyTagKey = "p";
  static const String hashtag = "t";
  static const String word = "word";
  static const String thread = "e";
  static const String ressource = "r";
  static const String emoji = "emoji";
  static const String A = "a";

  static const List<int> possibleKinds = [
    mute,
    pin,
    bookmarks,
    communities,
    publicChats,
    blockedRelays,
    searchRelays,
    interests,
    emojis,
    followSet,
    starterPack,
    relaySet,
    bookmarksSet,
    curationSet,
    interestsSet,
    emojisSet,
  ];

  static const List<String> possibleTags = [
    relay,
    pubkeyTagKey,
    hashtag,
    word,
    thread,
    ressource,
    emoji,
    A,
  ];

  String? id;
  late String pubKey;
  late int kind;

  List<NostrListElement> elements = [];

  List<NostrListElement> byTag(String tag) =>
      elements.where((element) => element.tag == tag).toList();

  List<NostrListElement> get relays => byTag(relay);
  List<NostrListElement> get pubKeys => byTag(pubkeyTagKey);
  List<NostrListElement> get hashtags => byTag(hashtag);
  List<NostrListElement> get words => byTag(word);
  List<NostrListElement> get threads => byTag(thread);

  List<String> get publicRelays =>
      relays.where((element) => !element.private).map((e) => e.value).toList();
  List<String> get privateRelays =>
      relays.where((element) => !element.private).map((e) => e.value).toList();

  set privateRelays(List<String> list) {
    elements.removeWhere((element) => element.tag == relay && element.private);
    elements.addAll(
      list.map(
        (url) => NostrListElement(tag: relay, value: url, private: true),
      ),
    );
  }

  set publicRelays(List<String> list) {
    elements.removeWhere((element) => element.tag == relay && !element.private);
    elements.addAll(
      list.map(
        (url) => NostrListElement(tag: relay, value: url, private: false),
      ),
    );
  }

  late int createdAt;

  @override
  // coverage:ignore-start
  String toString() {
    return 'Nip51List { $kind}';
  }
  // coverage:ignore-end

  String get displayTitle {
    if (kind == NostrList.searchRelays) {
      return "Search";
    }
    if (kind == NostrList.blockedRelays) {
      return "Blocked";
    }
    if (kind == NostrList.mute) {
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
    this.id,
  });

  void parseTags(List tags, {required bool private}) {
    for (var tag in tags) {
      if (tag is! List<dynamic>) continue;
      final length = tag.length;
      if (length <= 1) continue;
      final tagName = tag[0];
      final value = tag[1];
      if (possibleTags.contains(tagName)) {
        elements.add(
          NostrListElement(tag: tagName, value: value, private: private),
        );
      }
    }
  }

  void addRelay(String relayUrl, bool private) {
    elements.add(
      NostrListElement(tag: relay, value: relayUrl, private: private),
    );
  }

  void addElement(String tag, String value, bool private) {
    elements.add(NostrListElement(tag: tag, value: value, private: private));
  }

  void removeRelay(String relayUrl) {
    elements.removeWhere(
      (element) => element.tag == relay && element.value == relayUrl,
    );
  }

  void removeElement(String tag, String value) {
    elements.removeWhere(
      (element) => element.tag == tag && element.value == value,
    );
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
  // name is d tag
  late String name;
  String? title;
  String? description;
  String? image;

  @override
  String toString() {
    return 'Nip51Set { $name}';
  }

  /// Generic NIP-51 named set. Pass [kind] to specify the set type
  /// (e.g. [NostrList.followSet], [NostrList.curationSet], [NostrList.starterPack]).
  NostrSet({
    required super.pubKey,
    this.title,
    required this.name,
    this.image,
    this.description,
    required super.createdAt,
    required super.elements,
    required super.kind,
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
