import 'dart:convert';
import 'dart:developer';

import 'package:riverpod/riverpod.dart';

import '../../helpers/bloom_filter_prehash.dart';
import '../providers/db_app_provider.dart';
import '../providers/moderation/camelus_bloom_filter_provider.dart';
import '../providers/moderation/moderation_provider.dart';

class InitModeration {
  static Future<void> initBloomFilter({
    required ProviderContainer provider,
  }) async {
    final appDb = provider.read(dbAppProvider);
    final bloomFilter = provider.read(bloomFilterNotifierProvider.notifier);

    final dbResult = await appDb.read("camelus_filter");

    if (dbResult == "true") {
      bloomFilter.toggleFilter(true);

      await _updateFilterFromNetwork(provider: provider);
    } else if (dbResult == "false") {
      bloomFilter.toggleFilter(false);
    } else {
      bloomFilter.toggleFilter(true);

      await _updateFilterFromNetwork(provider: provider);
      await appDb.save(key: "camelus_filter", value: "true");
    }
  }

  static Future<void> _updateFilterFromNetwork({
    required ProviderContainer provider,
  }) async {
    final moderation = provider.read(moderationProvider);

    try {
      final serializedBloom = await moderation.fetchBloomFilterProfiles();
      if (serializedBloom == null) {
        return;
      }

      final newFilter = BloomFilterPrehash.fromNumHashFunctionsAndByteArray(
        numHashFunctions: serializedBloom.numHashFunctions,
        byteArray: base64Decode(serializedBloom.bitArray),
        size: serializedBloom.size,
      );
      final bloomProvider = provider.read(bloomFilterNotifierProvider.notifier);
      bloomProvider.setFilter(newFilter);
    } catch (e) {
      log("err downloading filter: $e");
    }
  }
}
