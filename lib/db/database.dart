// required package imports
import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'package:camelus/models/nostr_note.dart';
import 'dao/note_dao.dart';
import 'dao/tag_dao.dart';
import 'entities/db_note.dart';
import 'entities/db_tag.dart';
import 'entities/db_note_view.dart';

part 'database.g.dart'; // the generated code will be there

@Database(version: 1, entities: [DbNote, DbTag], views: [DbNoteView])
abstract class AppDatabase extends FloorDatabase {
  NoteDao get noteDao;
  TagDao get tagDao;
}
