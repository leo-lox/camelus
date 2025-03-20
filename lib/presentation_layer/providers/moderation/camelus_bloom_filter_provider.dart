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

  Future<void> setFilter(BloomFilterPrehash newFilter) async {
    state = state.copyWith(filter: newFilter);
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
    enabled: bloomFilterState.isEnabled,
  );
});

final bloomFilterReferenceProvider = Provider<MyProfilesBloomFilter>((ref) {
  // Create a mutable filter instance
  final filter = MyProfilesBloomFilter(
    bloomFilter:
        BloomFilterPrehash(falsePositiveProbability: 0.001, numItems: 1),
    enabled: true,
  );

  // Set up a listener to update the filter when the state changes
  ref.listen(bloomFilterNotifierProvider, (previous, next) {
    filter.updateFilter(next.filterProfiles, next.isEnabled);
  });

  return filter;
});

class MyProfilesBloomFilter implements ndk.EventFilter {
  BloomFilterPrehash _bloomFilter;
  bool _enabled;

  MyProfilesBloomFilter(
      {required BloomFilterPrehash bloomFilter, required bool enabled})
      : _bloomFilter = bloomFilter,
        _enabled = enabled;

  void updateFilter(BloomFilterPrehash newFilter, bool enabled) {
    _bloomFilter = newFilter;
    _enabled = enabled;
  }

  @override
  bool filter(ndk.Nip01Event event) {
    if (_enabled && _bloomFilter.contains(event.id)) {
      return false;
    }
    return true;
  }
}
