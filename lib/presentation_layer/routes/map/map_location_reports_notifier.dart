import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain_layer/entities/map_coordinate.dart';
import '../../../domain_layer/entities/user_location_report.dart';
import '../../providers/map_providers.dart';
import 'utils/geohash_viewport.dart';

class MapLocationReportsState {
  final List<UserLocationReport> reports;

  const MapLocationReportsState({this.reports = const []});

  MapLocationReportsState copyWith({List<UserLocationReport>? reports}) =>
      MapLocationReportsState(reports: reports ?? this.reports);
}

final mapLocationReportsProvider =
    NotifierProvider<MapLocationReportsNotifier, MapLocationReportsState>(
      MapLocationReportsNotifier.new,
    );

/// Loads user location reports for the currently visible map viewport,
/// pruning reports outside of it whenever the viewport changes.
class MapLocationReportsNotifier extends Notifier<MapLocationReportsState> {
  /// Below this zoom the area covered by the viewport is too large to query
  /// cheaply, so reports are hidden and no query is made.
  static const double minZoomForReports = 8.0;

  Timer? _debounce;
  StreamSubscription<UserLocationReport>? _subscription;
  Set<String> _activeGeohashes = {};

  @override
  MapLocationReportsState build() {
    ref.onDispose(() {
      _debounce?.cancel();
      _subscription?.cancel();
    });
    return const MapLocationReportsState();
  }

  void onViewportChanged(MapCoordinate center, double zoom) {
    _debounce?.cancel();
    if (zoom < minZoomForReports) {
      _debounce = Timer(const Duration(milliseconds: 400), _clearForLowZoom);
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _reload(center, zoom),
    );
  }

  void _clearForLowZoom() {
    _subscription?.cancel();
    _subscription = null;
    if (_activeGeohashes.isEmpty && state.reports.isEmpty) return;
    _activeGeohashes = {};
    state = state.copyWith(reports: const []);
  }

  void _reload(MapCoordinate center, double zoom) {
    final geohashes = geohashesForViewport(center, zoom);
    final geohashSet = geohashes.toSet();
    if (setEquals(geohashSet, _activeGeohashes)) return;
    _activeGeohashes = geohashSet;

    // drop reports that fell outside of the new viewport to keep memory/render load in check
    state = state.copyWith(
      reports: state.reports
          .where((report) => report.geohashes.any(geohashSet.contains))
          .toList(),
    );

    final since =
        DateTime.now()
            .subtract(const Duration(hours: 24))
            .millisecondsSinceEpoch ~/
        1000;

    _subscription?.cancel();
    _subscription = ref
        .read(getLocationReportsProvider)(geohashes: geohashes, since: since)
        .listen(_onReport);
  }

  void _onReport(UserLocationReport report) {
    if (!report.geohashes.any(_activeGeohashes.contains)) return;
    final reports = [...state.reports];
    final existingIndex = reports.indexWhere(
      (existing) => existing.eventId == report.eventId,
    );
    if (existingIndex >= 0) {
      reports[existingIndex] = report;
    } else {
      reports.add(report);
    }
    state = state.copyWith(reports: reports);
  }
}
