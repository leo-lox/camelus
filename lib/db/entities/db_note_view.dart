// ignore_for_file: non_constant_identifier_names

import 'package:camelus/db/entities/db_note_view_base.dart';
import 'package:floor/floor.dart';

@DatabaseView(
    'SELECT Note.*, GROUP_CONCAT(Tag.type) as tag_types, GROUP_CONCAT(Tag.value) as tag_values, GROUP_CONCAT(Tag.recommended_relay) as tag_recommended_relays, GROUP_CONCAT(Tag.marker) as tag_markers, GROUP_CONCAT(Tag.index) as tag_index FROM Note LEFT JOIN Tag ON Note.id = Tag.note_id GROUP BY Note.id;',
    viewName: 'noteView')
class DbNoteView extends DbNoteViewBase {
  DbNoteView(
      {required super.id,
      required super.pubkey,
      required super.created_at,
      required super.kind,
      required super.content,
      required super.sig,
      super.tag_index,
      super.tag_types,
      super.tag_values,
      super.tag_recommended_relays,
      super.tag_markers});
}
