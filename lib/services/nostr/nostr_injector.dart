import 'package:http/http.dart';
import 'nostr_service.dart';

class NostrServiceInjector {
  static final _singleton = NostrServiceInjector._internal();
  static NostrServiceInjector? _injector;

  NostrService? _nostrService;
  Client? _client;

  factory NostrServiceInjector() {
    return _injector != null ? _injector! : _singleton;
  }

  NostrServiceInjector._internal();

  static void configure(NostrServiceInjector injector) {
    _injector = injector;
  }

  NostrService get nostrService {
    return _nostrService ??= NostrService();
  }

  Client get client {
    return _client ??= Client();
  }
}
