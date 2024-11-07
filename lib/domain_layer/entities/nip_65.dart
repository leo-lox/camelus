import 'package:ndk/entities.dart';

class Nip65 {
  String pubKey;

  Map<String, ReadWriteMarker> relays = {};

  int createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  // Nip65(this.relays);

  Nip65({
    required this.pubKey,
    required this.relays,
    required this.createdAt,
  });
}
