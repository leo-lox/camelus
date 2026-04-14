import 'dart:async';

import 'package:apipod_client/apipod_client.dart' as api_pod;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'serverpod_provider.dart';

class TrendsNotifier extends Notifier<AsyncValue<api_pod.TrendsResponse>> {
  static const String _defaultInterval = '12h';
  static const int _defaultLimit = 10;
  static const Duration _refreshInterval = Duration(minutes: 5);

  Timer? _refreshTimer;

  @override
  AsyncValue<api_pod.TrendsResponse> build() {
    load();
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      load(showLoading: false);
    });
    ref.onDispose(() => _refreshTimer?.cancel());

    return const AsyncValue.loading();
  }

  Future<void> load({
    String interval = _defaultInterval,
    int limit = _defaultLimit,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      state = const AsyncValue.loading();
    }

    try {
      final serverpodDs = ref.read(serverpodProvider);
      final response = await serverpodDs.client.trends.trends(
        interval: interval,
        limit: limit,
      );

      state = AsyncValue.data(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final trendsProvider =
    NotifierProvider<TrendsNotifier, AsyncValue<api_pod.TrendsResponse>>(
      TrendsNotifier.new,
    );

class TrendsPeopleNotifier
    extends Notifier<AsyncValue<api_pod.TrendsResponse>> {
  static const String _defaultInterval = '24h';
  static const int _defaultLimit = 10;
  static const Duration _refreshInterval = Duration(minutes: 5);

  Timer? _refreshTimer;

  @override
  AsyncValue<api_pod.TrendsResponse> build() {
    load();
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      load(showLoading: false);
    });
    ref.onDispose(() => _refreshTimer?.cancel());

    return const AsyncValue.loading();
  }

  Future<void> load({
    String interval = _defaultInterval,
    int limit = _defaultLimit,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      state = const AsyncValue.loading();
    }

    try {
      final serverpodDs = ref.read(serverpodProvider);
      final response = await serverpodDs.client.trends.trendingPeople(
        interval: interval,
        limit: limit,
      );

      state = AsyncValue.data(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final trendsPeopleProvider =
    NotifierProvider<TrendsPeopleNotifier, AsyncValue<api_pod.TrendsResponse>>(
      TrendsPeopleNotifier.new,
    );
