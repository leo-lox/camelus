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
  String? tag_index;
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
      this.tag_index,
      this.tag_types,
      this.tag_values,
      this.tag_recommended_relays,
      this.tag_markers});

  @override
  String toString() {
    return 'DbNostrNote{id: $id, pubkey: $pubkey, created_at: $created_at, kind: $kind, content: $content, sig: $sig, tag_types: $tag_types, tag_values: $tag_values, tag_recommended_relays: $tag_recommended_relays, tag_markers: $tag_markers}';
  }

  NostrNote toNostrNote() {
    List<NostrTag> mytags = [];
    if (tag_values != null && tag_values!.isNotEmpty) {
      mytags = toNostrTags(
          tag_intexs: tag_index ?? '',
          tag_types: tag_types!,
          tag_values: tag_values!,
          tag_recommended_relays: tag_recommended_relays ?? '',
          tag_markers: tag_markers ?? '');
    }

    return NostrNote(
        id: id,
        pubkey: pubkey,
        created_at: created_at,
        kind: kind,
        content: content,
        sig: sig,
        tags: mytags);
  }

  List<NostrTag> toNostrTags(
      {required String tag_intexs,
      required String tag_types,
      required String tag_values,
      required String tag_recommended_relays,
      required String tag_markers}) {
    List<NostrTag> tags = [];
    List<String> tag_index_list = tag_intexs.split(',');
    List<String> tag_types_list = tag_types.split(',');
    List<String> tag_values_list = tag_values.split(',');
    List<String> tag_recommended_relays_list =
        tag_recommended_relays.split(',');
    List<String> tag_markers_list = tag_markers.split(',');
    //cast to int
    List<int> tag_index_list_int =
        tag_index_list.map((e) => int.parse(e)).toList();
    // crate a list but put them in the order provided by tag_index

    for (int i = 0; i < tag_index_list_int.length; i++) {
      int posIndex = tag_index_list_int.indexOf(i);

      Map newNostrTag = {
        "type": tag_types_list[posIndex],
        "value": tag_values_list[posIndex],
      };

      if (tag_recommended_relays_list.length > posIndex &&
          tag_recommended_relays_list[posIndex].isNotEmpty) {
        newNostrTag["recommended_relay"] =
            tag_recommended_relays_list[posIndex];
      }
      if (tag_markers_list.length > posIndex &&
          tag_markers_list[posIndex].isNotEmpty) {
        newNostrTag["marker"] = tag_markers_list[posIndex];
      }

      tags.add(NostrTag(
          type: newNostrTag["type"],
          value: newNostrTag["value"],
          recommended_relay: newNostrTag["recommended_relay"],
          marker: newNostrTag["marker"]));
    }
    return tags;
  }
}
