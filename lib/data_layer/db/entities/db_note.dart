// ignore_for_file: non_constant_identifier_names

import 'package:camelus/domain/models/nostr_note.dart';
import 'package:camelus/domain/models/nostr_tag.dart';
import 'package:isar/isar.dart';

part 'db_note.g.dart';

@collection
class DbNote {
  Id id = Isar
      .autoIncrement; // Für auto-increment kannst du auch id = null zuweisen

  @Index(unique: true, type: IndexType.value, replace: false)
  String nostr_id;

  @Index()
  String pubkey;

  @Index()
  int created_at;

  @Index()
  int kind;

  String? content;

  String sig;

  bool? sig_valid;

  List<DbTag>? tags;

  // not nostr related fields

  // used for full text search
  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get contentWords => Isar.splitWords(content ?? '');

  int? last_fetch;

  DbNote({
    required this.nostr_id,
    required this.pubkey,
    required this.created_at,
    required this.kind,
    this.content,
    required this.sig,
    this.tags,
    this.last_fetch,
  });

  @override
  String toString() {
    return '{"id": "$id", "nostr_id": "$nostr_id", "pubkey": "$pubkey", "created_at": "$created_at", "kind": "$kind", "content": "$content", "sig": "$sig", "tags": "$tags"}';
  }

  NostrNote toNostrNote() {
    return NostrNote(
      id: nostr_id,
      pubkey: pubkey,
      created_at: created_at,
      kind: kind,
      content: content ?? '',
      sig: sig,
      sig_valid: sig_valid,
      tags: toNostrTags(),
    );
  }

  List<NostrTag> toNostrTags() {
    return tags?.map((e) => e.toNostrTag()).toList() ?? [];
  }
}

@embedded
class DbTag {
  String? type;

  String? value;

  String? recommended_relay;

  String? marker;

  DbTag({
    this.type,
    this.value,
    this.recommended_relay,
    this.marker,
  });

  @override
  String toString() {
    return '{"type": "$type", "value": "$value", "recommended_relay": "$recommended_relay", "marker": "$marker"}';
  }

  NostrTag toNostrTag() {
    return NostrTag(
      type: type ?? '',
      value: value ?? '',
      recommended_relay: recommended_relay,
      marker: marker,
    );
  }
}
