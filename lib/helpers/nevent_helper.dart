import 'dart:convert';
import 'dart:developer';

import 'dart:typed_data';

import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/helpers/tlv_helpers.dart';

import 'package:hex/hex.dart';

class NeventHelper {
  String mapToBech32(Map<String, dynamic> map) {
    var helper = Helpers();
    String eventId = map["eventId"];
    String? authorPubkey = map["authorPubkey"];
    List<String> relays = List<String>.from(map['relays']);

    List<int> pubkeyInt = HEX.decode(eventId);
    Uint8List pubkeyBytes = Uint8List.fromList(pubkeyInt);

    List<TLV> tlvList = [];
    tlvList.add(TLV(type: 0, length: 32, value: pubkeyBytes));

    for (int i = 0; i < relays.length; i++) {
      var relay = relays[i];
      var relayBytes = Uint8List.fromList(ascii.encode(relay));
      tlvList.add(TLV(type: 1, length: relayBytes.length, value: relayBytes));
    }

    if (authorPubkey != null) {
      List<int> pubkeyInt = HEX.decode(authorPubkey);
      Uint8List pubkeyBytes = Uint8List.fromList(pubkeyInt);
      tlvList.add(TLV(type: 2, length: 32, value: pubkeyBytes));
    }

    Uint8List bytes = TlvUtils.encode(tlvList);
    String dataString = HEX.encode(bytes);

    String bech32 = helper.encodeBech32(dataString, "nevent");

    return bech32;
  }
}
