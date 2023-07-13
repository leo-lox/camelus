import 'package:camelus/db_drift/entities/db_note.dart';
import 'package:camelus/db_drift/entities/db_tag.dart';
import 'package:drift/drift.dart';

abstract class DbNoteView extends View {
  // Getters define the tables that this view is reading from.
  DbNote get dbNote;
  DbTag get dbTag;


  //'SELECT Note.*,
  //GROUP_CONCAT(Tag.type) as tag_types,
  //GROUP_CONCAT(Tag.value) as tag_values,
  //GROUP_CONCAT(Tag.recommended_relay) as tag_recommended_relays,
  //GROUP_CONCAT(Tag.marker) as tag_markers,
  //GROUP_CONCAT(Tag.tag_index) as tag_index
  //FROM Note LEFT JOIN Tag ON Note.id = Tag.note_id
  //GROUP BY Note.id;',

 // turn this into query

 @override
  Query as() =>
      // Views can select columns defined as expression getters on the class, or
      // they can reference columns from other tables.
      select([dbNote.content, dbTag.type])
          .from(dbTag)
          .join([innerJoin(to dos, todos.category.equalsExp(categories.id))]);
}
