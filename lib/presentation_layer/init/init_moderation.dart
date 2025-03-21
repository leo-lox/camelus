import 'dart:convert';
import 'dart:developer';

import 'package:riverpod/riverpod.dart';

import '../../domain_layer/entities/bloom_filter_data.dart';
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
    final bloomProvider = provider.read(bloomFilterNotifierProvider.notifier);

    try {
      // Fetch filter data
      final profilesFilterData = await moderation.fetchBloomFilterProfiles();
      final eventsFilterData = await moderation.fetchBloomFilterEvents();

      if (profilesFilterData == null && eventsFilterData == null) {
        return;
      }

      // Process filters
      final profilesFilter = _createFilterFromData(profilesFilterData);
      final eventsFilter = _createFilterFromData(eventsFilterData);

      // Update filters
      bloomProvider.setFilter(
        newFilterProfiles: profilesFilter,
        newFilterEvents: eventsFilter,
      );
    } catch (_) {}
  }

  static BloomFilterPrehash? _createFilterFromData(
      BloomFilterData? filterData) {
    if (filterData == null) return null;

    return BloomFilterPrehash.fromNumHashFunctionsAndByteArray(
      numHashFunctions: filterData.numHashFunctions,
      byteArray: base64Decode(filterData.bitArray),
      size: filterData.size,
    );
  }
}
