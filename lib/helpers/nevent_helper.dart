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
}
