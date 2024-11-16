import 'package:objectbox/objectbox.dart';
import 'package:ndk/entities.dart' as ndk_entities;

@Entity()
class DbNip05 {
  @Id()
  int dbId = 0;

  @Property()
  late String pubKey;

  @Property()
  late String nip05;

  @Property()
  bool valid = false;

  @Property()
  int? networkFetchTime;

  @Property()
  List<String> relays = [];

  DbNip05({
    required this.pubKey,
    required this.nip05,
    this.valid = false,
    this.networkFetchTime,
    this.relays = const [],
  });

  ndk_entities.Nip05 toNdk() {
    final ndkNip05 = ndk_entities.Nip05(
      pubKey: pubKey,
      nip05: nip05,
      valid: valid,
      networkFetchTime: networkFetchTime,
      relays: relays,
    );

    return ndkNip05;
  }

  factory DbNip05.fromNdk(ndk_entities.Nip05 ndkNip05) {
    final dbNip05 = DbNip05(
      pubKey: ndkNip05.pubKey,
      nip05: ndkNip05.nip05,
      valid: ndkNip05.valid,
      networkFetchTime: ndkNip05.networkFetchTime,
      relays: ndkNip05.relays ?? [],
    );
    return dbNip05;
  }
}
