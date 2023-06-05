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

  NostrNote(this.id, this.pubkey, this.created_at, this.kind, this.content,
      this.sig, this.tags);

  factory NostrNote.fromJson(Map<String, dynamic> json) {
    return NostrNote(
        json['id'],
        json['pubkey'],
        json['created_at'],
        json['kind'],
        json['content'],
        json['sig'],
        json['tags'].cast<String>());
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
          index: i,
          type: this.tags[i].type,
          value: this.tags[i].value,
          recommended_relay: this.tags[i].recommended_relay,
          marker: this.tags[i].marker));
    }
    return tags;
  }
}
