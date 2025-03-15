import 'dart:convert';

import 'package:camelus/presentation_layer/providers/moderation/moderation_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart' as ndk;

import '../../../helpers/bloom_filter_prehash.dart';

class BloomFilterState {
  final BloomFilterPrehash filterProfiles;
  final bool isEnabled;

  BloomFilterState({
    required this.filterProfiles,
    this.isEnabled = true,
  });

  BloomFilterState copyWith({
    BloomFilterPrehash? filter,
    bool? isEnabled,
  }) {
    return BloomFilterState(
      filterProfiles: filter ?? this.filterProfiles,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

class BloomFilterNotifier extends Notifier<BloomFilterState> {
  @override
  BloomFilterState build() {
    return BloomFilterState(
      filterProfiles:
          BloomFilterPrehash(falsePositiveProbability: 0.001, numItems: 1),
      isEnabled: true,
    );
  }

  void toggleFilter(bool enabled) {
    state = state.copyWith(isEnabled: enabled);
  }

  // Update the filter from network
  Future<void> updateFromNetwork() async {
    final moderation = await ref.read(moderationProvider.future);
    final serializedBloom = await moderation.fetchBloomFilter();

    try {
      final newFilter = BloomFilterPrehash.fromNumHashFunctionsAndByteArray(
        numHashFunctions: serializedBloom["numHashFunctions"],
        byteArray: base64Decode(serializedBloom["bitArray"]),
        size: serializedBloom["size"],
      );

      state = state.copyWith(filter: newFilter);
    } catch (e) {
      print('Error updating bloom filter: $e');
    }
  }
}

final bloomFilterNotifierProvider =
    NotifierProvider<BloomFilterNotifier, BloomFilterState>(() {
  return BloomFilterNotifier();
});

final camelusBloomFilterProvider = Provider<ndk.EventFilter>((ref) {
  final bloomFilterState = ref.watch(bloomFilterNotifierProvider);

  return MyProfilesBloomFilter(
      bloomFilter: bloomFilterState.filterProfiles,
      enabled: bloomFilterState.isEnabled);
});

class MyProfilesBloomFilter implements ndk.EventFilter {
  final BloomFilterPrehash _bloomFilter;
  final bool _enabled;

  MyProfilesBloomFilter(
      {required BloomFilterPrehash bloomFilter, required bool enabled})
      : _bloomFilter = bloomFilter,
        _enabled = enabled;

  @override
  bool filter(ndk.Nip01Event event) {
    if (_enabled && _bloomFilter.contains(event.id)) {
      return false;
    }
    return true;
  }
}
