import 'dart:async';
import 'dart:developer';
import 'package:camelus/data_layer/db/entities/db_user_metadata.dart';
import 'package:camelus/data_layer/db/queries/db_user_metadata_queries.dart';
import 'package:camelus/services/nostr/metadata/nip_05.dart';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';

class Search {
  final Isar _db;

  List<DbUserMetadata> _usersMetadata = [];

  Search(
    this._db,
  ) {
    _init();
    _initStream();
  }

  // keep memory up to date with db
  void _initStream() {
    DbUserMetadataQueries.getAllStream(_db).listen((event) {
      _usersMetadata = event;
    });
  }

  void _init() async {
    // keep users metadata in memory
    _usersMetadata = await DbUserMetadataQueries.getAllFuture(_db);
  }

  List<DbUserMetadata> searchUsersMetadata(String query) {
    //search in notes title and content
    List<DbUserMetadata> results = [];

    for (var entry in _usersMetadata) {
      final name = entry.name ?? '';
      final nip05 = entry.nip05 ?? '';

      if (name.toLowerCase().contains(query.toLowerCase()) ||
          nip05.toLowerCase().contains(query.toLowerCase())) {
        // check if already in results
        if (results.any((element) => element.pubkey == entry.pubkey)) {
          continue;
        }
        results.add(entry);
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
    List<String> myRelays;
    try {
      myRelays = List<String>.from(relays[myPubkey]);
    } catch (e) {
      myRelays = [];
    }

    return {
      "nip05": nip05,
      "pubkey": myPubkey,
      "relays": myRelays,
    };
  }
}
