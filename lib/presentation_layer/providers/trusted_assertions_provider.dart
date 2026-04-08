import 'package:ndk/ndk.dart';
import 'package:riverpod/riverpod.dart';

import '../../config/app_trusted_assertions.dart';
import 'ndk_provider.dart';

/// Parameters for event metrics query
/// Results are cached per unique parameter combination
class EventMetricsParams {
  final String eventId;
  final Set<Nip85Metric>? metrics;
  final List<Nip85TrustedProvider>? providers;

  const EventMetricsParams({
    required this.eventId,
    this.metrics,
    this.providers = APP_DEFAULT_NIP85_PROVIDERS,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventMetricsParams &&
          runtimeType == other.runtimeType &&
          eventId == other.eventId &&
          _setEquals(metrics, other.metrics) &&
          _listEquals(providers, other.providers);

  @override
  int get hashCode =>
      Object.hash(eventId, _setHash(metrics), _listHash(providers));

  static bool _setEquals<T>(Set<T>? a, Set<T>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (final value in a) {
      if (!b.contains(value)) return false;
    }
    return true;
  }

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static int _setHash<T>(Set<T>? values) {
    if (values == null) return 0;
    return Object.hashAllUnordered(values);
  }

  static int _listHash<T>(List<T>? values) {
    if (values == null) return 0;
    return Object.hashAll(values);
  }
}

/// Provider for getting event metrics from NIP-85 trusted assertions
/// Results are streamed per unique parameter combination
///
/// Usage:
/// ```dart
/// final metricsFiltered = ref.watch(eventMetricsProvider(
///   EventMetricsParams(
///     eventId: 'event-id',
///     metrics: {Nip85Metric.zapAmount, Nip85Metric.repostCount},
///   ),
/// ));
/// ```
final eventMetricsProvider =
    StreamProvider.family<Nip85EventMetrics, EventMetricsParams>((ref, params) {
      final ndk = ref.watch(ndkProvider);

      // ignore: experimental_member_use
      return ndk.ta.streamEventMetrics(
        params.eventId,
        metrics: params.metrics,
        providers: params.providers,
      );
    });
