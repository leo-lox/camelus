import 'package:camelus/data_layer/repositories/database_repository_impl.dart';
import 'package:camelus/data_layer/repositories/nip05_repository_impl.dart';
import 'package:camelus/domain_layer/repositories/database_repository.dart';
import 'package:camelus/domain_layer/repositories/nip05_repository.dart';
import 'package:camelus/domain_layer/usecases/verify_nip05.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart';

import '../../data_layer/data_sources/http_request_data_source.dart';

final nip05provider = FutureProvider<VerifyNip05>((ref) async {
  final Client client = Client();
  final HttpRequestDataSource dataSource = HttpRequestDataSource(client);
  final Nip05Repository nip05Repository =
      Nip05RepositoryImpl(dataSource: dataSource);

  final DatabaseRepository databaseRepository = DatabaseRepositoryImpl();

  var nip05 = VerifyNip05(databaseRepository, nip05Repository);

  return nip05;
});
