// required package imports
import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'dao/note_dao.dart';
import 'entities/note.dart';

part 'database.g.dart'; // the generated code will be there

@Database(version: 1, entities: [Note])
abstract class AppDatabase extends FloorDatabase {
  NoteDao get personDao;
}
