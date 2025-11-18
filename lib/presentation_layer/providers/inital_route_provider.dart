import 'package:riverpod/riverpod.dart';
import '../../domain_layer/usecases/initial_route.dart';
import 'db_app_provider.dart';

final initalRouteProvider = Provider<InitialRoute>((ref) {
  final appDb = ref.read(dbAppProvider);
  final InitialRoute initialRouteUsecase = InitialRoute(appDb: appDb);
  return initialRouteUsecase;
});
