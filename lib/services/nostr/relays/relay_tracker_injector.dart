import 'package:camelus/services/nostr/relays/relay_tracker.dart';

class RelayTrackerInjector {
  static final _singleton = RelayTrackerInjector._internal();
  static RelayTrackerInjector? _injector;

  RelayTracker? _relayTracker;

  factory RelayTrackerInjector() {
    return _injector != null ? _injector! : _singleton;
  }

  RelayTrackerInjector._internal();

  static void configure(RelayTrackerInjector injector) {
    _injector = injector;
  }

  RelayTracker get relayTracker {
    return _relayTracker ??= RelayTracker();
  }
}
