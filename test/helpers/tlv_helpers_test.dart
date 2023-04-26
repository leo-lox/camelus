import 'package:camelus/helpers/tlv_helpers.dart';
import 'package:test/test.dart';
import 'dart:typed_data';

void main() {
  group('TlvUtils', () {
    test('encode and decode should be consistent', () {
      List<TLV> tlvList = [
        TLV(type: 0, length: 4, value: Uint8List.fromList([1, 2, 3, 4])),
        TLV(type: 1, length: 3, value: Uint8List.fromList([5, 6, 7])),
        TLV(type: 2, length: 2, value: Uint8List.fromList([8, 9])),
      ];

      Uint8List encodedData = TlvUtils.encode(tlvList);
      List<TLV> decodedTlvList = TlvUtils.decode(encodedData);

      expect(decodedTlvList.length, tlvList.length);

      for (int i = 0; i < tlvList.length; i++) {
        expect(decodedTlvList[i].type, tlvList[i].type);
        expect(decodedTlvList[i].value, tlvList[i].value);
      }
    });

    test('encode should return correct byte representation', () {
      List<TLV> tlvList = [
        TLV(type: 0, length: 4, value: Uint8List.fromList([1, 2, 3, 4])),
        TLV(type: 1, length: 3, value: Uint8List.fromList([5, 6, 7])),
      ];

      Uint8List encodedData = TlvUtils.encode(tlvList);
      Uint8List expectedEncodedData =
          Uint8List.fromList([0, 4, 1, 2, 3, 4, 1, 3, 5, 6, 7]);

      expect(encodedData, expectedEncodedData);
    });

    test('decode should return correct TLV list', () {
      Uint8List encodedData =
          Uint8List.fromList([0, 4, 1, 2, 3, 4, 1, 3, 5, 6, 7]);
      List<TLV> decodedTlvList = TlvUtils.decode(encodedData);

      List<TLV> expectedTlvList = [
        TLV(type: 0, length: 4, value: Uint8List.fromList([1, 2, 3, 4])),
        TLV(type: 1, length: 3, value: Uint8List.fromList([5, 6, 7])),
      ];

      expect(decodedTlvList.length, expectedTlvList.length);

      for (int i = 0; i < expectedTlvList.length; i++) {
        expect(decodedTlvList[i].type, expectedTlvList[i].type);
        expect(decodedTlvList[i].value, expectedTlvList[i].value);
      }
    });
  });
}
