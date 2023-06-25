import 'dart:convert';
import 'dart:developer';

import 'package:camelus/db/database.dart';
import 'package:camelus/models/nostr_note.dart';

class Search {
  final AppDatabase _db;

  late Map<String, dynamic> _usersMetadata;

  Search(
    this._db,
  ) {
    _init();
    _initStream();
  }

  // keep memory up to date with db
  void _initStream() {
    _db.noteDao.findAllNotesByKindStream(0).listen((event) {
      List<NostrNote> notesMetadata =
          event.map((e) => e.toNostrNote()).toList();

      for (var note in notesMetadata) {
        try {
          _usersMetadata[note.pubkey] = jsonDecode(note.content);
        } catch (e) {
          log("error decoding user metadata: $e");
        }
      }
    });
  }

  void _init() async {
    // keep users metadata in memory
    var notesDb = await _db.noteDao.findAllNotesByKind(0);
    List<NostrNote> notesMetadata =
        notesDb.map((e) => e.toNostrNote()).toList();

    _usersMetadata = {};
    for (var note in notesMetadata) {
      try {
        _usersMetadata[note.pubkey] = jsonDecode(note.content);
      } catch (e) {
        log("error decoding user metadata: $e");
      }
    }
  }

  List<Map<String, dynamic>> searchUsersMetadata(String query) {
    //search in notes title and content
    List<Map<String, dynamic>> results = [];

    for (var entry in _usersMetadata.entries) {
      var name = entry.value['name'] ?? '';
      var nip05 = entry.value['nip05'] ?? '';

      if (name.toLowerCase().contains(query.toLowerCase()) ||
          nip05.toLowerCase().contains(query.toLowerCase())) {
        // check if already in results
        if (results.any((element) => element['pubkey'] == entry.key)) {
          continue;
        }
        results.add({...entry.value, "pubkey": entry.key});
      }
    }

    return results;
  }
}
