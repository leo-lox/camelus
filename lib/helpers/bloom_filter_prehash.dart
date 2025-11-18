import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// bloom filter that works with pre-hashed values \
/// this is useful in nostr because ids are already a sha256 hash, ensuring even distribution \
/// benifit of mutch better performance
class BloomFilterPrehash {
  late int _size;
  late int _numHashFunctions;
  late Uint8List _bitArray;

  BloomFilterPrehash({
    required double falsePositiveProbability,
    required int numItems,
  }) {
    if (falsePositiveProbability <= 0 || falsePositiveProbability >= 1) {
      throw ArgumentError(
        "False positive probability must be in range (0, 1).",
      );
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

  BloomFilterPrehash.fromNumHashFunctionsAndByteArray({
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

  Map<String, dynamic> serializeToMap() {
    return {
      'size': _size,
      'numHashFunctions': _numHashFunctions,
      'bitArray': base64Encode(_bitArray),
    };
  }

  String serialize() {
    return base64Encode(_bitArray);
  }

  static BloomFilterPrehash deserialize(Map<String, dynamic> data) {
    return BloomFilterPrehash.fromNumHashFunctionsAndByteArray(
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

  /// [hexHash] must be a 64 character hash value with even distribution!
  void add(String hexHash) {
    if (!_isValidHexHash(hexHash)) {
      throw ArgumentError("Input must be a 64-character hexadecimal string");
    }

    final List<int> hashValues = _getHashValuesFromHex(hexHash);
    for (int bitPosition in hashValues) {
      _setBit(bitPosition);
    }
  }

  bool contains(String hexHash) {
    if (!_isValidHexHash(hexHash)) {
      throw ArgumentError("Input must be a 64-character hexadecimal string");
    }

    final List<int> hashValues = _getHashValuesFromHex(hexHash);
    for (int bitPosition in hashValues) {
      if (!_getBit(bitPosition)) {
        return false;
      }
    }
    return true;
  }

  bool _isValidHexHash(String hexHash) {
    return hexHash.length == 64 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(hexHash);
  }

  // Generate multiple hash values directly from the hex string
  // using the Kirsch-Mitzenmacher technique
  List<int> _getHashValuesFromHex(String hexHash) {
    final List<int> hashValues = [];

    // Extract two 8-byte chunks from different parts of the hash
    // and use them as our two independent hash functions
    final String chunk1 = hexHash.substring(
      0,
      16,
    ); // First 16 hex chars (8 bytes)
    final String chunk2 = hexHash.substring(
      32,
      48,
    ); // Another 16 hex chars from the middle

    // Convert to integers
    final BigInt hash1 = BigInt.parse(chunk1, radix: 16);
    final BigInt hash2 = BigInt.parse(chunk2, radix: 16);

    // Use the Kirsch-Mitzenmacher technique to generate k hash functions
    // h_i(x) = (h1(x) + i * h2(x)) % m
    final BigInt sizeAsBigInt = BigInt.from(_size);

    for (int i = 0; i < _numHashFunctions; i++) {
      final BigInt iAsBigInt = BigInt.from(i);
      final BigInt combinedHash = (hash1 + iAsBigInt * hash2) % sizeAsBigInt;
      hashValues.add(combinedHash.toInt());
    }

    return hashValues;
  }

  void _setBit(int position) {
    final byteIndex = position ~/ 8;
    final bitIndex = position % 8;
    _bitArray[byteIndex] |= (1 << bitIndex);
  }

  bool _getBit(int position) {
    final byteIndex = position ~/ 8;
    final bitIndex = position % 8;
    return (_bitArray[byteIndex] & (1 << bitIndex)) != 0;
  }
}
