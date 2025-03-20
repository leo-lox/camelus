class BloomFilterData {
  final int size;
  final int numHashFunctions;
  final String bitArray;
  final DateTime createdAt;

  BloomFilterData({
    required this.size,
    required this.bitArray,
    required this.createdAt,
    required this.numHashFunctions,
  });
}
