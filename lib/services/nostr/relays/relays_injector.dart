import 'package:camelus/services/nostr/relays/relay_tracker.dart';

import 'package:camelus/services/nostr/relays/relays_ranking.dart';

class RelaysInjector {
  static final _singleton = RelaysInjector._internal();
  static RelaysInjector? _injector;

  RelayTracker? _relayTracker;
  RelaysRanking? _relaysRanking;

  factory RelaysInjector() {
    return _injector != null ? _injector! : _singleton;
  }

  RelaysInjector._internal();

  static void configure(RelaysInjector injector) {
    _injector = injector;
  }

  RelayTracker get relayTracker {
    return _relayTracker ??= RelayTracker();
  }

  RelaysRanking get relaysRanking {
    return _relaysRanking ??= RelaysRanking();
  }
}
