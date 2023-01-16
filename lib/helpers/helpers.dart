import 'dart:convert';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';
import 'dart:math';
import 'package:bech32/bech32.dart';
import 'package:hex/hex.dart';

class Helpers {
  static const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

  final Random _rnd = Random();

  /// UNSECURE! use getSecureRandomString() instead
  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  /// Generate UUID
  String getUuid() {
    const uuid = Uuid();
    return uuid.v4();
  }

  /// Secure random string generator
  String getSecureRandomString(int length) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64UrlEncode(values);
  }

  String getSecureRandomHex(int length) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return HEX.encode(values);
  }

  /// converts a hex string to bech32
  /// hrp = human readable part
  /// returns bech32 string
  String encodeBech32(String myHex, String hrp) {
    var bytes = HEX.decode(myHex);

    // Convert the 8-bit words to 5-bit words.
    List<int> fiveBitWords = convertBits(bytes, 8, 5, true);

    var bech32String = bech32.encode(Bech32(hrp, fiveBitWords));

    return bech32String;
  }

  /// converts a bech32 string to hex
  /// returns a list of [hex, hrp]
  List<String> decodeBech32(String myBech32) {
    Bech32Codec codec = const Bech32Codec();
    Bech32 bech32 = codec.decode(
      myBech32,
      myBech32.length,
    );

    // Convert the 5-bit words to 8-bit words.
    List<int> eightBitWords = convertBits(bech32.data, 5, 8, false);

    return [HEX.encode(eightBitWords), bech32.hrp];
  }

  List<int> convertBits(List<int> data, int fromBits, int toBits, bool pad) {
    int acc = 0;
    int bits = 0;
    List<int> ret = [];
    for (int value in data) {
      acc = (acc << fromBits) | value;
      bits += fromBits;
      while (bits >= toBits) {
        bits -= toBits;
        ret.add((acc >> bits) & (1 << toBits) - 1);
      }
    }
    if (pad) {
      if (bits > 0) {
        ret.add(acc << (toBits - bits) & (1 << toBits) - 1);
      }
    } else if (bits >= fromBits || (acc & ((1 << bits) - 1)) != 0) {
      throw Exception('Invalid padding');
    }
    return ret;
  }

  List<String> getPubkeysFromTags(tag) {
    var pubkeys = <String>[];
    for (var i = 0; i < tag.length; i++) {
      if (tag[i][0] == "p") {
        pubkeys.add(tag[i][1]);
      }
    }
    return pubkeys;
  }

  List<String> getEventsFromTags(tag) {
    var events = <String>[];
    for (var i = 0; i < tag.length; i++) {
      if (tag[i][0] == "e") {
        events.add(tag[i][1]);
      }
    }
    return events;
  }
}
