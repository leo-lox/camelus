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
      int type = data[offset++];
      int length = _decodeLength(data, offset);
      offset += _getLengthBytes(length);
      Uint8List value = data.sublist(offset, offset + length);
      offset += length;
      tlvList.add(TLV(type: type, length: length, value: value));
    }
    return tlvList;
  }

  /// Decode length from list bytes
  static int _decodeLength(Uint8List buffer, int offset) {
    int length = buffer[offset] & 255;
    if ((length & 128) == 128) {
      int numberOfBytes = length & 127;
      if (numberOfBytes > 3) {
        throw Exception("Invalid length");
      }
      length = 0;
      for (int i = offset + 1; i < offset + 1 + numberOfBytes; ++i) {
        length = length * 256 + (buffer[i] & 255);
      }
    }
    return length;
  }

  static int _getLengthBytes(int length) {
    return (length & 128) == 128 ? 1 + (length & 127) : 1;
  }

  /// Encode list tlv to list bytes
  static Uint8List encode(List<TLV> tlvList) {
    List<Uint8List> byteLists = [];
    for (TLV tlv in tlvList) {
      Uint8List typeBytes = Uint8List.fromList([tlv.type]);
      Uint8List lengthBytes = _encodeLength(tlv.value.length);
      byteLists.addAll([typeBytes, lengthBytes, tlv.value]);
    }
    return _concatenateUint8List(byteLists);
  }

  /// Encode length to list bytes
  static Uint8List _encodeLength(int length) {
    if (length < 128) {
      return Uint8List.fromList([length]);
    }
    List<int> lengthBytesList = [0x82 | (length >> 8), length & 0xFF];
    return Uint8List.fromList(lengthBytesList);
  }

  /// concatenate/chain list bytes
  static Uint8List _concatenateUint8List(List<Uint8List> lists) {
    int totalLength = lists.map((list) => list.length).reduce((a, b) => a + b);
    var result = Uint8List(totalLength);
    int offset = 0;
    for (var list in lists) {
      result.setRange(offset, offset + list.length, list);
      offset += list.length;
    }
    return result;
  }
}
