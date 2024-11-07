import 'package:camelus/domain_layer/entities/nip05.dart';

abstract class DatabaseRepository {
  Future<Nip05?> getNip05(String nip05);
  Future<void> setNip05(Nip05 nip05);
}
