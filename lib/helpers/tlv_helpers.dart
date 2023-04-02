import 'dart:typed_data';

class TLV {
  final int type;
  final int length;
  final Uint8List value;

  TLV({
    required this.type,
    required this.length,
    required this.value,
  });
}

class TlvUtils {
  /// Decode list bytes to list tlv model
  static List<TLV> decode(Uint8List data) {
    var tlvList = <TLV>[];
    var offset = 0;
    while (offset < data.length) {
      /// Read the type field (1 byte)
      var type = data[offset];
      offset += 1;

      /// Read the length field (1, 2 or 3 bytes)
      var length = _getLength(data, offset);
      offset += length;

      /// Read the value field
      var valueLength =
          _getValueLength(data.sublist(offset - length, offset), 0);
      var value = data.sublist(offset, offset + valueLength);
      offset += valueLength;

      tlvList.add(TLV(type: type, length: length, value: value));
    }
    return tlvList;
  }

  /// Count the number of bytes
  static int _getLength(Uint8List aBuf, int aOffset) {
    int len = aBuf[aOffset] & 255;
    return (len & 128) == 128 ? 1 + (len & 127) : 1;
  }

  /// Length value
  static int _getValueLength(Uint8List aBuf, int aOffset) {
    int length = aBuf[aOffset] & 255;
    if ((length & 128) == 128) {
      int numberOfBytes = length & 127;
      if (numberOfBytes > 3) {
        throw Exception();
      }
      length = 0;
      for (int i = aOffset + 1; i < aOffset + 1 + numberOfBytes; ++i) {
        length = length * 256 + (aBuf[i] & 255);
      }
    }
    return length;
  }

  /// Encode list tlv to list bytes
  static Uint8List encode(List<TLV> tlvList) {
    var data = Uint8List(0);
    for (TLV tlv in tlvList) {
      var value = tlv.value;
      var length = value.length;

      var typeBytes = Uint8List.fromList([tlv.type]);
      var lengthBytes = _encodeLength(length);
      var valueBytes = Uint8List.fromList(value);

      data = _concatUint8List([data, typeBytes, lengthBytes, valueBytes]);
    }
    return data;
  }

  /// Convert length int to bytes
  static Uint8List _encodeLength(int length) {
    if (length < 128) {
      return Uint8List.fromList([length]);
    }
    var lengthBytes = Uint8List(3);
    lengthBytes[0] = 0x82;
    lengthBytes.setRange(1, 3, Uint8List.fromList([length]));
    return lengthBytes;
  }

  /// Concat list bytes
  static Uint8List _concatUint8List(List<Uint8List> lists) {
    var totalLength = lists.map((list) => list.length).reduce((a, b) => a + b);
    var result = Uint8List(totalLength);
    var offset = 0;
    for (var list in lists) {
      result.setRange(offset, offset + list.length, list);
      offset += list.length;
    }
    return result;
  }
}
