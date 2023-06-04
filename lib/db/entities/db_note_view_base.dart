// ignore_for_file: non_constant_identifier_names

abstract class DbNoteViewBase {
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

  DbNoteViewBase(
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
