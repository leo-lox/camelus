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
          metrics == other.metrics &&
          providers == other.providers;

  @override
  int get hashCode => Object.hash(eventId, metrics, providers);
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
