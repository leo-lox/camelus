import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data_layer/repositories/app_update_repository_impl.dart';
import '../../domain_layer/repositories/app_update_repository.dart';
import '../../domain_layer/usecases/check_app_update.dart';
import 'serverpod_provider.dart';

// Provider for checking app updates.
//  interacts with the AppUpdateRepository to check for app updates.
final appUpdateProvider = Provider<CheckAppUpdate>((ref) {
  final serverpodDs = ref.watch(serverpodProvider);

  final AppUpdateRepository appUpdateRepository =
      AppUpdateRepositoryImpl(serverpodDataSource: serverpodDs);

  final CheckAppUpdate appUpdate = CheckAppUpdate(appUpdateRepository);

  // Returning the CheckAppUpdate instance, which will be used by consumers.
  return appUpdate;
});
