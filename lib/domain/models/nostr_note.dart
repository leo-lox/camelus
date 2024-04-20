import 'package:camelus/domain/models/nostr_tag.dart';

class NostrNote {
  final String id;
  final String pubkey;
  // ignore: non_constant_identifier_names
  final int created_at;
  final int kind;
  final String content;
  final String sig;
  // ignore: non_constant_identifier_names
  final bool? sig_valid;
  final List<NostrTag> tags;

  NostrNote({
    required this.id,
    required this.pubkey,
    // ignore: non_constant_identifier_names
    required this.created_at,
    required this.kind,
    required this.content,
    required this.sig,
    required this.tags,
    this.sig_valid,
  });

  List<String> get relayHints => _extractRelayHints();

  List<String> _extractRelayHints() {
    List<String> relayHints = [];
    for (NostrTag tag in tags) {
      if (tag.recommended_relay != null) {
        relayHints.add(tag.recommended_relay!);
      }
    }
    return relayHints;
  }

  factory NostrNote.empty({String? id, String? pubkey, int? kind}) {
    return NostrNote(
        id: id ?? 'missing',
        pubkey: pubkey ?? 'missing',
        created_at: 0,
        kind: kind ?? 1,
        content: 'missing event',
        sig: '',
        tags: []);
  }

  factory NostrNote.fromJson(Map<String, dynamic> json) {
    List<dynamic> tagsJson = json['tags'] ?? [];
    List<List<String>> tags = [];
    //cast using for loop
    for (List tag in tagsJson) {
      tags.add(tag.cast<String>());
    }

    return NostrNote(
      id: json['id'],
      pubkey: json['pubkey'],
      created_at: json['created_at'],
      kind: json['kind'],
      content: json['content'],
      sig: json['sig'],
      tags: tags.map((tag) => NostrTag.fromJson(tag)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pubkey': pubkey,
        'created_at': created_at,
        'kind': kind,
        'content': content,
        'sig': sig,
        'tags': tags
      };

  @override
  String toString() {
    return 'NostrNote{id: $id, pubkey: $pubkey, created_at: $created_at, kind: $kind, content: $content, sig: $sig, tags: $tags}';
  }

  List<NostrTag> get getTagPubkeys {
    List<NostrTag> mytags = [];
    for (NostrTag tag in tags) {
      if (tag.type == 'p') {
        mytags.add(tag);
      }
    }
    return mytags;
  }

  List<NostrTag> get getTagEvents {
    List<NostrTag> mytags = [];
    for (NostrTag tag in tags) {
      if (tag.type == 'e') {
        mytags.add(tag);
      }
    }
    return mytags;
  }

  bool get isRoot {
    return getRootReply == null && getDirectReply == null;
  }

  NostrTag? get getRootReply {
    for (NostrTag tag in getTagEvents) {
      // in spec
      if (tag.marker == "root") {
        return tag;
      }

      // support off spec
      if (tags.length == 1) {
        return getTagEvents[0];
      }
      // off spec
      if (tags.length > 1) {
        var root = getTagEvents.first;
        return root;
      }
    }

    return null;
  }

  NostrTag? get getDirectReply {
    for (NostrTag tag in getTagEvents) {
      // in spec
      if (tag.marker == "reply") {
        return tag;
      }
    }
    // off spec
    if (getTagEvents.isNotEmpty) {
      var reply = getTagEvents.last;

      return reply;
    }
    return null;
  }
}
