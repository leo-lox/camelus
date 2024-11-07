import '../entities/app_update.dart';
import '../repositories/app_update_repository.dart';

class CheckAppUpdate {
  final AppUpdateRepository appUpdateRepository;

  CheckAppUpdate(this.appUpdateRepository);

  Future<AppUpdate> call() async {
    return await appUpdateRepository.checkAppUpdate();
  }
}
