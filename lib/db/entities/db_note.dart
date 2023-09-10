// ignore_for_file: non_constant_identifier_names

import 'package:isar/isar.dart';

part 'db_note.g.dart';

@collection
class DbNote {
  Id id = Isar
      .autoIncrement; // Für auto-increment kannst du auch id = null zuweisen

  @Index(unique: true)
  String? nostr_id;

  @Index()
  String? pubkey;

  @Index()
  int? created_at;

  @Index()
  int? kind;

  String? content;

  // used for full text search
  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get contentWords => Isar.splitWords(content ?? '');

  String? sig;

  List<Tag>? tags;

  @override
  String toString() {
    return '{"id": "$id", "nostr_id": "$nostr_id", "pubkey": "$pubkey", "created_at": "$created_at", "kind": "$kind", "content": "$content", "sig": "$sig", "tags": "$tags"}';
  }
}

@embedded
class Tag {
  String? type;

  String? value;

  String? recommended_relay;

  String? marker;

  @override
  String toString() {
    return '{"type": "$type", "value": "$value", "recommended_relay": "$recommended_relay", "marker": "$marker"}';
  }
}
