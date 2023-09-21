import 'dart:convert';
import 'dart:developer';
import 'package:camelus/db/entities/db_nip05.dart';
import 'package:camelus/db/queries/db_nip05_queries.dart';
import 'package:isar/isar.dart';
import 'package:http/http.dart' as http;

class Nip05 {
  //Map<String, dynamic> _history = {};
  final List<String> _inFlight = [];
  http.Client client = http.Client();

  Isar db;

  Nip05({required this.db});

  /// returns {nip05, valid, lastCheck, relayHints} or exception
  Future<DbNip05?> checkNip05(String nip05, String pubkey) async {
    if (nip05.isEmpty || pubkey.isEmpty) {
      throw Exception("nip05 or pubkey empty");
    }

    var rawResult = await DbNip05Queries.nip05Future(db, nip05: nip05);

    if (rawResult != null) {
      int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      int lastCheck = rawResult.lastCheck ?? 0;
      if (now - lastCheck < 60 * 60 * 24) {
        return rawResult;
      }
    }

    if (_inFlight.contains(nip05)) {
      //  wait for result
      var maxRetries = 10;
      while (_inFlight.contains(nip05)) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (maxRetries-- < 0) {
          continue;
        }
      }
      var rawResult = await DbNip05Queries.nip05Future(db, nip05: nip05);
      return rawResult;
    }

    _inFlight.add(nip05);

    var result = await _checkNip05Request(nip05, pubkey);
    _inFlight.remove(nip05);

    return result;
  }

  /// returns {nip05, valid, lastCheck, relays}
  Future<DbNip05?> _checkNip05Request(String nip05, String pubkey) async {
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // split in username and url/domain
    String username = nip05.split("@")[0];
    try {
      String url = nip05.split("@")[1];
    } catch (e) {
      log("invalid nip05: $nip05");
      return null;
      throw Exception("invalid nip05 $nip05");
    }

    var json;
    try {
      json = await rawNip05Request(nip05, client);
    } catch (e) {
      log("error fetching nip05: $e");
      return null;
    }

    Map names = json["names"];

    Map relays = json["relays"] ?? {};

    List<String> pRelays = [];
    if (relays[pubkey] != null) {
      pRelays = List<String>.from(relays[pubkey]);
    }

    var result = DbNip05(nip05: nip05, valid: false, lastCheck: now);

    if (pRelays.isNotEmpty) {
      result.relays = pRelays;
    }

    if (names[username] == pubkey) {
      result.valid = true;
    }
    // insert into db
    db.writeTxn(() async {
      await db.dbNip05s.put(result);
    });

    return result;
  }

  static Future rawNip05Request(String nip05, http.Client client) async {
    String username = nip05.split("@")[0];
    String url = nip05.split("@")[1];
    // make get request
    try {
      String myUrl = "https://$url/.well-known/nostr.json?name=$username";
      http.Response response = await client
          .get(Uri.parse(myUrl), headers: {"Accept": "application/json"});

      if (response.statusCode != 200) {
        return throw Exception(
            "error fetching nip05.json STATUS: ${response.statusCode}}, Link: $myUrl");
      }

      var json = jsonDecode(response.body);
      return json;
    } catch (e) {
      throw Exception("error fetching nip05.json $e");
    }
  }
}
