import '../../domain_layer/entities/nip05.dart';
import '../../domain_layer/repositories/database_repository.dart';

class DatabaseRepositoryImpl implements DatabaseRepository {
  //final DatabaseProvider databaseProvider;

  //DatabaseRepositoryImpl({required this.databaseProvider});

  @override
  Future<Nip05?> getNip05(String nip05) {
    throw UnimplementedError();
  }

  @override
  Future<void> setNip05(Nip05 nip05) {
    throw UnimplementedError();
  }
}
