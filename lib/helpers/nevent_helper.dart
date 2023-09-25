import 'dart:convert';
import 'dart:typed_data';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/helpers/tlv_helpers.dart';
import 'package:hex/hex.dart';

class NeventHelper {
  final Helpers _helper = Helpers();

  String mapToBech32(Map<String, dynamic> map) {
    final String eventId = map['eventId'];
    final String? authorPubkey = map['authorPubkey'];
    final List<String> relays = List<String>.from(map['relays']);

    final List<TLV> tlvList = _generateTlvList(eventId, authorPubkey, relays);
    final String dataString = HEX.encode(TlvUtils.encode(tlvList));

    return _helper.encodeBech32(dataString, 'nevent');
  }

  /// Generates a list of TLV objects
  List<TLV> _generateTlvList(
      String eventId, String? authorPubkey, List<String> relays) {
    final List<TLV> tlvList = [];
    tlvList.add(_generateEventIdTlv(eventId));

    tlvList.addAll(relays.map(_generateRelayTlv));

    if (authorPubkey != null) {
      tlvList.add(_generateAuthorPubkeyTlv(authorPubkey));
    }

    return tlvList;
  }

  // specified in https://github.com/nostr-protocol/nips/blob/master/19.md

  /// TLV type 0
  /// [eventId] must be 32 bytes long
  TLV _generateEventIdTlv(String eventId) {
    final Uint8List eventIdBytes = Uint8List.fromList(HEX.decode(eventId));
    return TLV(type: 0, length: 32, value: eventIdBytes);
  }

  /// TLV type 1
  /// [relay] must be a string
  TLV _generateRelayTlv(String relay) {
    final Uint8List relayBytes = Uint8List.fromList(ascii.encode(relay));
    return TLV(type: 1, length: relayBytes.length, value: relayBytes);
  }

  /// TLV type 2
  /// [authorPubkey] must be 32 bytes long
  TLV _generateAuthorPubkeyTlv(String authorPubkey) {
    final Uint8List authorPubkeyBytes =
        Uint8List.fromList(HEX.decode(authorPubkey));
    return TLV(type: 2, length: 32, value: authorPubkeyBytes);
  }

  /// Decodes a bech32 string into a map
  /// throws if bech32 string is invalid
  ///
  Map<String, dynamic> bech32ToMap(String bech32) {
    final List<String> dataString = _helper.decodeBech32(bech32);
    final Uint8List dataBytes = Uint8List.fromList(HEX.decode(dataString[0]));
    final List<TLV> tlvList = TlvUtils.decode(dataBytes);

    final Map<String, dynamic> map = _generateMapFromTlvList(tlvList);

    return map;
  }

  /// Generates a map from a list of TLV objects
  Map<String, dynamic> _generateMapFromTlvList(List<TLV> tlvList) {
    final Map<String, dynamic> map = {};

    for (var i = 0; i < tlvList.length; i++) {
      final TLV tlv = tlvList[i];
      if (tlv.type == 0) {
        map['eventId'] = HEX.encode(tlv.value);
      } else if (tlv.type == 1) {
        map['relays'] = _generateRelaysFromTlvList(tlvList);
      } else if (tlv.type == 2) {
        map['authorPubkey'] = HEX.encode(tlv.value);
      }
    }

    return map;
  }

  /// Generates a list of relays from a list of TLV objects
  List<String> _generateRelaysFromTlvList(List<TLV> tlvList) {
    final List<String> relays = [];

    for (var i = 0; i < tlvList.length; i++) {
      final TLV tlv = tlvList[i];
      if (tlv.type == 1) {
        relays.add(ascii.decode(tlv.value));
      }
    }

    return relays;
  }
}
