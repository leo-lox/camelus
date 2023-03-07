import 'package:camelus/services/nostr/metadata/nip_05.dart';

class MetadataInjector {
  static final _singleton = MetadataInjector._internal();
  static MetadataInjector? _injector;

  Nip05? _nip05;

  factory MetadataInjector() {
    return _injector != null ? _injector! : _singleton;
  }

  MetadataInjector._internal();

  static void configure(MetadataInjector injector) {
    _injector = injector;
  }

  Nip05 get nip05 {
    return _nip05 ??= Nip05();
  }
}
