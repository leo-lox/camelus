import 'package:isar/isar.dart';

part 'db_nip05.g.dart';

@collection
class DbNip05 {
  Id id = Isar
      .autoIncrement; // Für auto-increment kannst du auch id = null zuweisen

  @Index(unique: true, type: IndexType.value, replace: true)
  String nip05;

  bool valid;
  int? lastCheck;
  List<String>? relays;

  DbNip05({
    required this.nip05,
    this.valid = false,
    this.lastCheck,
    this.relays = const [],
  });
}
