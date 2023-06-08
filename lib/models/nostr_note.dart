import 'package:camelus/db/entities/db_note.dart';
import 'package:camelus/db/entities/db_tag.dart';
import 'package:camelus/models/nostr_tag.dart';

class NostrNote {
  final String id;
  final String pubkey;
  // ignore: non_constant_identifier_names
  final int created_at;
  final int kind;
  final String content;
  final String sig;
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
  });

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

  DbNote toDbNote() {
    return DbNote(id, pubkey, created_at, kind, content, sig);
  }

  // ignore: non_constant_identifier_names
  List<DbTag> toDbTag() {
    List<DbTag> tags = [];
    for (int i = 0; i < this.tags.length; i++) {
      tags.add(DbTag(
          note_id: id,
          tag_index: i,
          type: this.tags[i].type,
          value: this.tags[i].value,
          recommended_relay: this.tags[i].recommended_relay,
          marker: this.tags[i].marker));
    }
    return tags;
  }
}
