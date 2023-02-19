import 'package:camelus/services/nostr/relays/relays.dart';

class RelaysInjector {
  static final _singleton = RelaysInjector._internal();
  static RelaysInjector? _injector;

  Relays? _relays;

  factory RelaysInjector() {
    return _injector != null ? _injector! : _singleton;
  }

  RelaysInjector._internal();

  static void configure(RelaysInjector injector) {
    _injector = injector;
  }

  Relays get relays {
    return _relays ??= Relays();
  }
}
