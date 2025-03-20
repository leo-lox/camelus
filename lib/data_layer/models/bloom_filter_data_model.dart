import '../../domain_layer/entities/bloom_filter_data.dart';

import 'package:apipod_client/apipod_client.dart' as sp;

class BloomFilterDataModel extends BloomFilterData {
  BloomFilterDataModel({
    required super.bitArray,
    required super.createdAt,
    required super.numHashFunctions,
    required super.size,
  });

  factory BloomFilterDataModel.fromServerpod(sp.BloomFilterData data) {
    return BloomFilterDataModel(
      bitArray: data.bitArray,
      createdAt: data.createdAt,
      numHashFunctions: data.numHashFunctions,
      size: data.size,
    );
  }
}
