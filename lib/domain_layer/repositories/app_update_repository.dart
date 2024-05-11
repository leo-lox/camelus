import '../entities/app_update.dart';

abstract class AppUpdateRepository {
  Future<AppUpdate> checkAppUpdate();
}
