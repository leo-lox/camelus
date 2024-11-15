import 'package:camelus/data_layer/repositories/app_update_repository_impl.dart'; 
import 'package:camelus/domain_layer/repositories/app_update_repository.dart';
import 'package:camelus/domain_layer/usecases/check_app_update.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../data_layer/data_sources/http_request_data_source.dart';

// Provider for checking app updates.
//  interacts with the AppUpdateRepository to check for app updates.
final appUpdateProvider = Provider<CheckAppUpdate>((ref) {
  // Creating an HTTP client for making requests to the data source.
  final http.Client client = http.Client();

  // Creating an instance of HttpRequestDataSource, which handles HTTP requests.
  final HttpRequestDataSource dataSource = HttpRequestDataSource(client);

  final AppUpdateRepository appUpdateRepository =
      AppUpdateRepositoryImpl(httpJsonDataSource: dataSource);

  final CheckAppUpdate appUpdate = CheckAppUpdate(appUpdateRepository);

  // Returning the CheckAppUpdate instance, which will be used by consumers.
  return appUpdate;
});
