import 'package:camelus/config/app_update_config.dart';
import 'package:camelus/data_layer/models/app_update_model.dart';
import 'package:camelus/domain_layer/entities/app_update.dart';
import 'package:camelus/domain_layer/repositories/app_update_repository.dart';

import '../data_sources/http_request_data_source.dart';

class AppUpdateRepositoryImpl implements AppUpdateRepository {
  final HttpRequestDataSource httpJsonDataSource;

  AppUpdateRepositoryImpl({required this.httpJsonDataSource});

  @override
  Future<AppUpdate> checkAppUpdate() async {
    final json =
        await httpJsonDataSource.jsonRequest(AppUpdateConfig.appUpdateCheckUrl);

    final myUpdate = AppUpdateModel.fromJson(json);
    myUpdate.currentVersion = await AppUpdateConfig.getBuildNumber();

    return myUpdate;
  }
}
