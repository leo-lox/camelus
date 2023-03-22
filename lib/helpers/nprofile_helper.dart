import 'dart:convert';
import 'dart:typed_data';

import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/helpers/tlv_helpers.dart';
import 'package:hex/hex.dart';

class NprofileHelper {
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
    List<String> relays = map["relays"];

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
