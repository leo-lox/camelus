import '../../config/app_update_config.dart';
import '../../domain_layer/entities/app_update.dart';
import '../../domain_layer/repositories/app_update_repository.dart';
import '../data_sources/serverpod_data_source.dart';
import '../models/app_update_model.dart';

class AppUpdateRepositoryImpl implements AppUpdateRepository {
  final ServerpodDataSource serverpodDataSource;

  AppUpdateRepositoryImpl({
    required this.serverpodDataSource,
  });

  @override
  Future<AppUpdate> checkAppUpdate() async {
    final result = await serverpodDataSource.client.appUpdate.checkVersion();

    final myUpdate = AppUpdateModel.fromServerpod(result);
    myUpdate.currentVersion = await AppUpdateConfig.getBuildNumber();

    return myUpdate;
  }
}
