import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart' as ndk;

import '../../../helpers/bloom_filter_prehash.dart';

class BloomFilterState {
  final BloomFilterPrehash filterProfiles;
  final BloomFilterPrehash filterEvents;
  final bool isEnabled;

  BloomFilterState({
    required this.filterProfiles,
    required this.filterEvents,
    this.isEnabled = true,
  });

  BloomFilterState copyWith({
    BloomFilterPrehash? filterProfiles,
    BloomFilterPrehash? filterEvents,
    bool? isEnabled,
  }) {
    return BloomFilterState(
      filterProfiles: filterProfiles ?? this.filterProfiles,
      filterEvents: filterEvents ?? this.filterEvents,
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
      filterEvents:
          BloomFilterPrehash(falsePositiveProbability: 0.001, numItems: 1),
      isEnabled: true,
    );
  }

  void toggleFilter(bool enabled) {
    state = state.copyWith(isEnabled: enabled);
  }

  Future<void> setFilter({
    BloomFilterPrehash? newFilterProfiles,
    BloomFilterPrehash? newFilterEvents,
  }) async {
    state = state.copyWith(
      filterProfiles: newFilterProfiles,
      filterEvents: newFilterEvents,
    );
  }
}

final bloomFilterNotifierProvider =
    NotifierProvider<BloomFilterNotifier, BloomFilterState>(() {
  return BloomFilterNotifier();
});

final camelusBloomFilterProvider = Provider<ndk.EventFilter>((ref) {
  final bloomFilterState = ref.watch(bloomFilterNotifierProvider);

  return MyProfilesBloomFilter(
    bloomFilterProfiles: bloomFilterState.filterProfiles,
    bloomFilterEvents: bloomFilterState.filterEvents,
    enabled: bloomFilterState.isEnabled,
  );
});

final bloomFilterReferenceProvider = Provider<MyProfilesBloomFilter>((ref) {
  // Create a mutable filter instance
  final filter = MyProfilesBloomFilter(
    bloomFilterProfiles:
        BloomFilterPrehash(falsePositiveProbability: 0.001, numItems: 1),
    bloomFilterEvents:
        BloomFilterPrehash(falsePositiveProbability: 0.001, numItems: 1),
    enabled: true,
  );

  // Set up a listener to update the filter when the state changes
  ref.listen(bloomFilterNotifierProvider, (previous, next) {
    filter.updateFilter(
      newFilterProfiles: next.filterProfiles,
      newFilterEvents: next.filterEvents,
      enabled: next.isEnabled,
    );
  });

  return filter;
});

class MyProfilesBloomFilter implements ndk.EventFilter {
  BloomFilterPrehash _bloomFilterProfiles;
  BloomFilterPrehash _bloomFilterEvents;
  bool _enabled;

  MyProfilesBloomFilter({
    required BloomFilterPrehash bloomFilterProfiles,
    required BloomFilterPrehash bloomFilterEvents,
    required bool enabled,
  })  : _bloomFilterProfiles = bloomFilterProfiles,
        _bloomFilterEvents = bloomFilterEvents,
        _enabled = enabled;

  void updateFilter({
    BloomFilterPrehash? newFilterProfiles,
    BloomFilterPrehash? newFilterEvents,
    required bool enabled,
  }) {
    if (newFilterProfiles != null) {
      _bloomFilterProfiles = newFilterProfiles;
    }
    if (newFilterEvents != null) {
      _bloomFilterEvents = newFilterEvents;
    }

    _enabled = enabled;
  }

  @override
  bool filter(ndk.Nip01Event event) {
    if (_enabled &&
        (_bloomFilterProfiles.contains(event.pubKey) ||
            _bloomFilterEvents.contains(event.id))) {
      return false;
    }
    return true;
  }
}
