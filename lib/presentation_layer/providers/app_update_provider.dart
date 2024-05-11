import 'package:camelus/data_layer/repositories/app_update_repository_impl.dart';
import 'package:camelus/domain_layer/repositories/app_update_repository.dart';
import 'package:camelus/domain_layer/usecases/check_app_update.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../data_layer/data_sources/http_request_data_source.dart';

final appUpdateProvider = Provider<CheckAppUpdate>((ref) {
  final http.Client client = http.Client();
  final HttpRequestDataSource dataSource = HttpRequestDataSource(client);
  final AppUpdateRepository appUpdateRepository =
      AppUpdateRepositoryImpl(httpJsonDataSource: dataSource);

  final CheckAppUpdate appUpdate = CheckAppUpdate(appUpdateRepository);

  return appUpdate;
});
