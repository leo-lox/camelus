// ignore_for_file: non_constant_identifier_names

import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/models/nostr_tag.dart';

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

  NostrNote toNostrNote() {
    return NostrNote(
        id,
        pubkey,
        created_at,
        kind,
        content,
        sig,
        toNostrTags(
            tag_types: tag_types!,
            tag_values: tag_values!,
            tag_recommended_relays: tag_recommended_relays!,
            tag_markers: tag_markers!));
  }

  List<NostrTag> toNostrTags(
      {required String tag_types,
      required String tag_values,
      required String tag_recommended_relays,
      required String tag_markers}) {
    List<NostrTag> tags = [];
    List<String> types = tag_types.split(',');
    List<String> values = tag_values.split(',');
    List<String> recommended_relays = tag_recommended_relays.split(',');
    List<String> markers = tag_markers.split(',');
    for (int i = 0; i < types.length; i++) {
      tags.add(NostrTag(
          type: types[i],
          value: values[i],
          recommended_relay: recommended_relays[i],
          marker: markers[i]));
    }
    return tags;
  }
}
