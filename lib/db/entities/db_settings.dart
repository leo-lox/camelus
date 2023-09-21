import 'package:isar/isar.dart';

part 'db_settings.g.dart';

@collection
class DbSettings {
  Id id = Isar.autoIncrement;

  List<DbManualRelay>? manualRelays;
}

@embedded
class DbManualRelay {
  String? url;
  bool? read;
  bool? write;

  DbManualRelay({
    this.url,
    this.read,
    this.write,
  });
}
