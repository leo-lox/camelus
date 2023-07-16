import 'dart:convert';
import 'dart:developer';
import 'package:cross_local_storage/cross_local_storage.dart';
//import 'package:cross_local_storage/cross_json_storage.dart';
import 'package:json_cache/json_cache.dart';
import 'package:http/http.dart' as http;

class Nip05 {
  Map<String, dynamic> _history = {};
  final List<String> _inFlight = [];
  http.Client client = http.Client();

  late JsonCache jsonCache;

  Nip05() {
    _initJsonCache();
  }

  void _initJsonCache() async {
    LocalStorageInterface? prefs = await LocalStorage.getInstance();
    jsonCache = JsonCacheCrossLocalStorage(prefs);
    _restoreFromCache();
  }

  void _restoreFromCache() async {
    var cache = (await jsonCache.value('nip05'));

    if (cache == null) {
      return;
    }

    // purge entries older than 24h
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    cache.removeWhere((key, value) => now - value["lastCheck"] > 60 * 60 * 24);

    _history = cache;
  }

  _updateCache() async {
    await jsonCache.refresh('nip05', _history);
  }

  /// returns {nip05, valid, lastCheck, relayHints} or exception
  Future<Map<String, dynamic>> checkNip05(String nip05, String pubkey) async {
    if (nip05.isEmpty || pubkey.isEmpty) {
      throw Exception("nip05 or pubkey empty");
    }

    if (_history.containsKey(nip05)) {
      Map<String, dynamic> result = _history[nip05];
      int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      int lastCheck = result["lastCheck"];
      if (now - lastCheck < 60 * 60 * 24) {
        return result;
      }
    }

    if (_inFlight.contains(nip05)) {
      //  wait for result
      while (_inFlight.contains(nip05)) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      return _history[nip05] ?? {};
    }

    _inFlight.add(nip05);

    var result = await _checkNip05Request(nip05, pubkey);
    _inFlight.remove(nip05);
    _updateCache();
    return result;
  }

  /// returns {nip05, valid, lastCheck, relays}
  Future<Map<String, dynamic>> _checkNip05Request(
      String nip05, String pubkey) async {
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // split in username and url/domain
    String username = nip05.split("@")[0];
    try {
      String url = nip05.split("@")[1];
    } catch (e) {
      log("invalid nip05: $nip05");
      return {};
      throw Exception("invalid nip05 $nip05");
    }

    var json;
    try {
      json = await rawNip05Request(nip05, client);
    } catch (e) {
      log("error fetching nip05: $e");
      return {};
    }

    Map names = json["names"];

    Map relays = json["relays"] ?? {};

    List<String> pRelays = [];
    if (relays[pubkey] != null) {
      pRelays = List<String>.from(relays[pubkey]);
    }

    Map<String, dynamic> result = {
      "nip05": nip05,
      "valid": false,
      "lastCheck": now
    };
    if (pRelays.isNotEmpty) {
      result["relays"] = pRelays;
    }

    if (names[username] == pubkey) {
      result["valid"] = true;
      _history[nip05] = result;

      return result;
    } else {
      if (result.isNotEmpty) {
        _history[nip05] = result;
      }

      return result;
    }
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
