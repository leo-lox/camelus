import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/helpers/tlv_helpers.dart';
import 'package:camelus/services/nostr/relays/relays_injector.dart';
import 'package:camelus/services/nostr/relays/relays_ranking.dart';
import 'package:hex/hex.dart';

class NprofileHelper {
  late RelaysRanking _relayRanking;

  NprofileHelper() {
    RelaysInjector injector = RelaysInjector();
    _relayRanking = injector.relaysRanking;
  }

  // return nprofile in bech32 populated with user relays
  Future<String> getNprofile(String pubkey) async {
    // get user relays
    List<String> userRelays = await getUserBestRelays(pubkey);

    var nProfile = NprofileHelper().mapToBech32({
      "pubkey": pubkey,
      "relays": userRelays,
    });

    return nProfile;
  }

  Future<List<String>> getUserBestRelays(pubkey) async {
    List userRelaysTmp =
        await _relayRanking.getBestRelays(pubkey, Direction.read);

    // turn list of map {relay: url, score: s} into list of url strings with only the 5 best scores
    List<String> userRelays = [];
    for (var i = 0; i < userRelaysTmp.length; i++) {
      if (i > 4) break;
      try {
        userRelays.add(userRelaysTmp[i]["relay"]);
      } catch (e) {
        log(e.toString());
      }
    }

    return userRelays;
  }

  /// {pubkey: 02b0e, relays: [relay1, relay2]} => nprofile1qdfdf:qdfdf
  String mapToBech32Hr(Map<String, dynamic> map) {
    String bech32 = mapToBech32(map);

    return bech32toHr(bech32);
  }

  String bech32toHr(String bech32) {
    var length = bech32.length;
    // split in first 20 chars and last 20 chars
    String first = bech32.substring(0, 15);
    String last = bech32.substring(length - 15, length);

    return "$first:$last";
  }

  Map<String, dynamic> bech32toMap(String bech32) {
    var helper = Helpers();
    var decodedBech32 = helper.decodeBech32(bech32);

    String dataString = decodedBech32[0];
    List<int> data = HEX.decode(dataString);
    String hrp = decodedBech32[1];

    // convert data string to bytes using utf8

    Uint8List bytes = Uint8List.fromList(data);
    List<TLV> tlvList = TlvUtils.decode(bytes);

    String pubkey = "";
    var relays = [];
    for (int i = 0; i < tlvList.length; i++) {
      if (tlvList[i].type == 0) {
        var value = tlvList[i].value;
        pubkey = HEX.encode(value);
      } else if (tlvList[i].type == 1) {
        var decoded = ascii.decode(tlvList[i].value);
        relays.add(decoded);
      }
    }
    if (pubkey.length != 64) {
      throw Exception("Invalid pubkey length");
    }

    return {
      "pubkey": pubkey,
      "relays": relays,
    };
  }

  String mapToBech32(Map<String, dynamic> map) {
    var helper = Helpers();
    String pubkey = map["pubkey"];
    List<String> relays = List<String>.from(map['relays']);

    List<int> pubkeyInt = HEX.decode(pubkey);
    Uint8List pubkeyBytes = Uint8List.fromList(pubkeyInt);

    List<TLV> tlvList = [];
    tlvList.add(TLV(type: 0, length: 32, value: pubkeyBytes));

    for (int i = 0; i < relays.length; i++) {
      var relay = relays[i];
      var relayBytes = Uint8List.fromList(ascii.encode(relay));
      tlvList.add(TLV(type: 1, length: relayBytes.length, value: relayBytes));
    }

    Uint8List bytes = TlvUtils.encode(tlvList);
    String dataString = HEX.encode(bytes);

    String bech32 = helper.encodeBech32(dataString, "nprofile");

    return bech32;
  }
}
