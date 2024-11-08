import '../../domain_layer/entities/nip_65.dart';
import 'package:ndk/entities.dart' as ndk_entities;

class Nip65Model extends Nip65 {
  Nip65Model({
    required super.createdAt,
    required super.pubKey,
    required super.relays,
  });

  ndk_entities.Nip65 toNdk() {
    return ndk_entities.Nip65(
      createdAt: super.createdAt,
      pubKey: super.pubKey,
      relays: super.relays,
    );
  }

  factory Nip65Model.fromNdk(ndk_entities.Nip65 ndkNip65) {
    return Nip65Model(
      createdAt: ndkNip65.createdAt,
      pubKey: ndkNip65.pubKey,
      relays: ndkNip65.relays,
    );
  }
}
