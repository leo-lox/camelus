import 'package:camelus/domain_layer/entities/nip05.dart';

class Nip05Model extends Nip05 {
  Nip05Model({
    required super.nip05,
    required super.valid,
    super.lastCheck,
    super.relays,
  });
}
