import 'dart:convert';
import 'dart:developer';

import 'package:camelus/db/database.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/services/nostr/metadata/nip_05.dart';
import 'package:http/http.dart' as http;

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

  Future<Map<String, dynamic>?> searchNip05(String nip05) async {
    String username = nip05.split("@")[0];
    try {
      String url = nip05.split("@")[1];
    } catch (e) {
      return null;
    }

    http.Client client = http.Client();
    Map response;
    try {
      response = await Nip05.rawNip05Request(nip05, client);
    } catch (e) {
      log("error serachNip05 nip05: $e");
      return null;
    }

    Map names = response["names"];
    Map relays = response["relays"] ?? {};

    if (names[username] == null) {
      return null;
    }

    String myPubkey = names[username];
    List<String> myRelays = List<String>.from(relays[myPubkey]) ?? [];

    return {
      "nip05": nip05,
      "pubkey": myPubkey,
      "relays": myRelays,
    };
  }
}
