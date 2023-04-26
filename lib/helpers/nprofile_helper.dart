import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/helpers/tlv_helpers.dart';
import 'package:camelus/services/nostr/relays/relays_injector.dart';
import 'package:camelus/services/nostr/relays/relays_ranking.dart';
import 'package:hex/hex.dart';

class NprofileHelper {
  late final RelaysRanking _relayRanking;

  NprofileHelper() {
    _relayRanking = RelaysInjector().relaysRanking;
  }

  /// finds relays and [returns] a bech32 encoded nprofile with relay hints
  Future<String> getNprofile(String pubkey) async {
    final List<String> userRelays = await _getUserBestRelays(pubkey);
    return mapToBech32({"pubkey": pubkey, "relays": userRelays});
  }

  /// tries to find the best relays for a user and [returns] a list of relay urls
  Future<List<String>> _getUserBestRelays(pubkey, {numberOfRelays = 5}) async {
    List userRelaysTmp =
        await _relayRanking.getBestRelays(pubkey, Direction.read);

    // turn list of map {relay: url, score: s} into list of url strings with only the 5 best scores
    List<String> userRelays = [];
    for (var i = 0; i < userRelaysTmp.length; i++) {
      if (i >= numberOfRelays) break;
      try {
        userRelays.add(userRelaysTmp[i]["relay"]);
      } catch (e) {
        log(e.toString());
      }
    }

    return userRelays;
  }

  /// [returns] a short version nprofile1:sdf54e:ewfd54
  String mapToBech32Hr(Map<String, dynamic> map) {
    return bech32toHr(mapToBech32(map));
  }

  /// [returns] a short version nprofile1:sdf54e:ewfd54
  String bech32toHr(String bech32, {int cutLength = 15}) {
    final int length = bech32.length;
    final String first = bech32.substring(0, cutLength);
    final String last = bech32.substring(length - cutLength, length);
    return "$first:$last";
  }

  /// [returns] a map with pubkey and relays
  Map<String, dynamic> bech32toMap(String bech32) {
    final Helpers helper = Helpers();
    final List<String> decodedBech32 = helper.decodeBech32(bech32);
    final String dataString = decodedBech32[0];
    final List<int> data = HEX.decode(dataString);

    final List<TLV> tlvList = TlvUtils.decode(Uint8List.fromList(data));
    final Map<String, dynamic> resultMap = _parseTlvList(tlvList);

    if (resultMap["pubkey"].length != 64) {
      throw Exception("Invalid pubkey length");
    }

    return resultMap;
  }

  /// expects a map with pubkey and relays and [returns] a bech32 encoded nprofile
  String mapToBech32(Map<String, dynamic> map) {
    final Helpers helper = Helpers();
    final String pubkey = map["pubkey"];
    final List<String> relays = List<String>.from(map['relays']);

    final List<TLV> tlvList = _generateTlvList(pubkey, relays);
    final Uint8List bytes = TlvUtils.encode(tlvList);
    final String dataString = HEX.encode(bytes);

    return helper.encodeBech32(dataString, "nprofile");
  }

  Map<String, dynamic> _parseTlvList(List<TLV> tlvList) {
    String pubkey = "";
    List<String> relays = [];
    for (TLV tlv in tlvList) {
      if (tlv.type == 0) {
        pubkey = HEX.encode(tlv.value);
      } else if (tlv.type == 1) {
        relays.add(ascii.decode(tlv.value));
      }
    }
    return {"pubkey": pubkey, "relays": relays};
  }

  List<TLV> _generateTlvList(String pubkey, List<String> relays) {
    final Uint8List pubkeyBytes = _hexDecodeToUint8List(pubkey);
    List<TLV> tlvList = [TLV(type: 0, length: 32, value: pubkeyBytes)];

    for (String relay in relays) {
      final Uint8List relayBytes = _asciiEncodeToUint8List(relay);
      tlvList.add(TLV(type: 1, length: relayBytes.length, value: relayBytes));
    }

    return tlvList;
  }

  Uint8List _hexDecodeToUint8List(String hexString) {
    return Uint8List.fromList(HEX.decode(hexString));
  }

  Uint8List _asciiEncodeToUint8List(String asciiString) {
    return Uint8List.fromList(ascii.encode(asciiString));
  }
}
