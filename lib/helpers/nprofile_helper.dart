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
      if (i == 0) {
        var value = tlvList[i].value;
        pubkey = HEX.encode(value);
      } else {
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
}
