import 'package:camelus/domain_layer/entities/nostr_tag.dart';

class NostrNote {
  final String id;
  final String pubkey;
  final int createdAt;
  final int kind;
  final String content;
  final String sig;
  final bool? sigValid;
  final List<NostrTag> tags;

  /// Relay that an event was received from
  List<String> sources = [];

  NostrNote({
    required this.id,
    required this.pubkey,
    required this.createdAt,
    required this.kind,
    required this.content,
    required this.sig,
    required this.tags,
    this.sigValid,
    this.sources = const [],
  });

  List<String> get relayHints => _extractRelayHints();

  List<String> _extractRelayHints() {
    List<String> relayHints = [];
    for (NostrTag tag in tags) {
      if (tag.recommendedRelay != null) {
        relayHints.add(tag.recommendedRelay!);
      }
    }
    return relayHints;
  }

  factory NostrNote.empty({String? id, String? pubkey, int? kind}) {
    return NostrNote(
        id: id ?? 'missing',
        pubkey: pubkey ?? 'missing',
        createdAt: 0,
        kind: kind ?? 1,
        content: 'missing event',
        sig: '',
        tags: []);
  }

  @override
  String toString() {
    return 'NostrNote{id: $id, pubkey: $pubkey, created_at: $createdAt, kind: $kind, content: $content, sig: $sig, tags: $tags}';
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

  /// check if the note is a root note (only works on kind 1)
  /// all other kinds are root notes
  bool get isRoot {
    if (kind == 1) {
      return getRootReply == null && getDirectReply == null;
    }

    return true;
  }

  /// checks if ther is a content warning for the note, \
  /// if yes returns the reason
  String? get contentWarning {
    for (NostrTag tag in tags) {
      if (tag.type == "content-warning") {
        return tag.value;
      }
    }
    return null;
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NostrNote) return false;

    final NostrNote otherNote = other;
    return id == otherNote.id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
