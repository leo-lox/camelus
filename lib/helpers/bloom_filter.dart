import 'dart:math';
import 'dart:typed_data';
import 'dart:convert' show base64Decode, base64Encode, utf8;
import 'package:xxh3/xxh3.dart';

class BloomFilter {
  late int _size;
  late int _numHashFunctions;
  late Uint8List _bitArray;

  BloomFilter({
    required double falsePositiveProbability,
    required int numItems,
  }) {
    if (falsePositiveProbability <= 0 || falsePositiveProbability >= 1) {
      throw ArgumentError(
          "False positive probability must be in range (0, 1).");
    }
    if (numItems <= 0) {
      throw ArgumentError("Number of items must be positive.");
    }

    _size = _calculateOptimalSize(falsePositiveProbability, numItems);
    _numHashFunctions = _calculateOptimalNumHashFunctions(_size, numItems);
    // Calculate bytes needed (size in bits / 8 bits per byte, rounded up)
    final byteSize = (_size / 8).ceil();
    _bitArray = Uint8List(byteSize);
  }

  // Modified constructor to ensure exact size preservation
  BloomFilter.fromNumHashFunctionsAndByteArray({
    required int numHashFunctions,
    required Uint8List byteArray,
    required int size,
  }) {
    if (numHashFunctions <= 0) {
      throw ArgumentError("Number of hash functions must be positive.");
    }
    if (byteArray.isEmpty) {
      throw ArgumentError("Bit array must not be empty.");
    }
    if (size <= 0) {
      throw ArgumentError("Size must be positive.");
    }

    _bitArray = byteArray;
    _size = size;
    _numHashFunctions = numHashFunctions;
  }

  int get size => _size;
  int get numHashFunctions => _numHashFunctions;

  // Modified serialization to include the exact size
  Map<String, dynamic> serializeToMap() {
    return {
      'size': _size,
      'numHashFunctions': _numHashFunctions,
      'bitArray': base64Encode(_bitArray),
    };
  }

  // Basic serialization for backward compatibility
  String serialize() {
    return base64Encode(_bitArray);
  }

  // Static method to deserialize from a map
  static BloomFilter deserialize(Map<String, dynamic> data) {
    return BloomFilter.fromNumHashFunctionsAndByteArray(
      numHashFunctions: data['numHashFunctions'],
      byteArray: base64Decode(data['bitArray']),
      size: data['size'],
    );
  }

  int _calculateOptimalSize(double p, int n) {
    return (-1 * (n * log(p)) / pow(log(2), 2)).ceil();
  }

  int _calculateOptimalNumHashFunctions(int m, int n) {
    return ((m / n) * log(2)).ceil();
  }

  void add(String item) {
    final List<int> hashValues = _getHashValues(item);
    for (int bitPosition in hashValues) {
      _setBit(bitPosition);
    }
  }

  bool contains(String item) {
    final List<int> hashValues = _getHashValues(item);
    for (int bitPosition in hashValues) {
      if (!_getBit(bitPosition)) {
        return false;
      }
    }
    return true;
  }

  // Using the Kirsch-Mitzenmacher technique to generate multiple hash values
  // from two independent hash functions
  List<int> _getHashValues(String item) {
    final List<int> hashValues = [];
    final bytes = utf8.encode(item);

    final int hash1 = xxh3(bytes, seed: 0).abs();
    final int hash2 = xxh3(bytes, seed: 1).abs();

    for (int i = 0; i < _numHashFunctions; i++) {
      int combinedHash = (hash1 + i * hash2) % _size;
      hashValues.add(combinedHash);
    }

    return hashValues;
  }

  // Set a bit at the specified position
  void _setBit(int position) {
    final byteIndex = position ~/ 8;
    final bitIndex = position % 8;
    _bitArray[byteIndex] |= (1 << bitIndex);
  }

  // Get a bit at the specified position
  bool _getBit(int position) {
    final byteIndex = position ~/ 8;
    final bitIndex = position % 8;
    return (_bitArray[byteIndex] & (1 << bitIndex)) != 0;
  }
}
