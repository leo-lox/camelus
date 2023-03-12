import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

class Nip05 {
  final Map<String, dynamic> _history = {};
  final List<String> _inFlight = [];

  Nip05() {
    // todo cache
  }

  /// returns {nip05, valid, lastCheck, relayHint} or {} when error
  Future<Map<String, dynamic>> checkNip05(String nip05, String pubkey) async {
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
      return _history[nip05];
    }

    _inFlight.add(nip05);

    var result = await _checkNip05Request(nip05, pubkey);
    _inFlight.remove(nip05);
    return result;
  }

  /// returns {nip05, valid, lastCheck, relayHint}
  Future<Map<String, dynamic>> _checkNip05Request(
      String nip05, String pubkey) async {
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // split in username and url/domain
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

      String pRelays = relays[pubkey] ?? "";

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
    } catch (e) {
      log("err, decoding nip5 json ${e.toString()}}");
    }

    return {};
  }
}
