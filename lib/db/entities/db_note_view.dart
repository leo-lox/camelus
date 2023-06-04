// ignore_for_file: non_constant_identifier_names

import 'package:floor/floor.dart';

@DatabaseView(
    'SELECT Note.*, GROUP_CONCAT(Tag.type) as tag_types, GROUP_CONCAT(Tag.value) as tag_values, GROUP_CONCAT(Tag.recommended_relay) as tag_recommended_relays, GROUP_CONCAT(Tag.marker) as tag_markers FROM Note LEFT JOIN Tag ON Note.id = Tag.note_id GROUP BY Note.id;',
    viewName: 'noteView')
class DbNoteView {
  String id;
  String pubkey;
  int created_at;
  int kind;
  String content;
  String sig;
  String? tag_types;
  String? tag_values;
  String? tag_recommended_relays;
  String? tag_markers;

  DbNoteView(
      {required this.id,
      required this.pubkey,
      required this.created_at,
      required this.kind,
      required this.content,
      required this.sig,
      this.tag_types,
      this.tag_values,
      this.tag_recommended_relays,
      this.tag_markers});

  @override
  String toString() {
    return 'DbNostrNote{id: $id, pubkey: $pubkey, created_at: $created_at, kind: $kind, content: $content, sig: $sig, tag_types: $tag_types, tag_values: $tag_values, tag_recommended_relays: $tag_recommended_relays, tag_markers: $tag_markers}';
  }
}
