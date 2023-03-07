import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

class Nip05 {
  final Map _history = {};

  Nip05() {
    // todo cache
  }

  Future<Map<String, dynamic>> checkNip05(String nip05, String pubkey) async {
    if (_history.containsKey(nip05)) {
      Map<String, dynamic> result = _history[nip05];
      int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      int lastCheck = result["lastCheck"];
      if (now - lastCheck < 60 * 60 * 24) {
        return result;
      }
    }

    return await _checkNip05(nip05, pubkey);
  }

  /// returns [nip5 identifier, true] if valid or [null, null] if not found
  Future<Map<String, dynamic>> _checkNip05(String nip05, String pubkey) async {
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // checks if the nip5 token is valid
    String username = nip05.split("@")[0];
    String url = nip05.split("@")[1];

    // make get request
    http.Response response = await http
        .get(Uri.parse("https://$url/.well-known/nostr.json?name=$username"));

    if (response.statusCode != 200) {
      return {};
    }

    try {
      var json = jsonDecode(response.body);
      Map names = json["names"];

      Map relays = json["relays"] ?? {};

      String pRelay = relays[pubkey] ?? "";

      Map<String, dynamic> result = {
        "nip05": nip05,
        "valid": false,
        "lastCheck": now
      };
      if (pRelay.isNotEmpty) {
        result["relayHint"](pRelay);
      }

      if (names[username] == pubkey) {
        result["valid"] = true;
        _history[nip05] = result;
        return result;
      } else {
        _history[nip05] = result;
        return result;
      }
    } catch (e) {
      log("err, decoding nip5 json ${e.toString()}}");
    }

    return {};
  }
}
