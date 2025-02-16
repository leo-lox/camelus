import '../repositories/app_db.dart';

class InitialRoute {
  static const defaultRoute = '/';

  final AppDb _appDb;

  InitialRoute({
    required AppDb appDb,
  }) : _appDb = appDb;

  Future<String> getInitialRoute() async {
    final savedRoute = await _appDb.read('initalRoute');
    return savedRoute ?? defaultRoute;
  }

  Future<void> saveInitialRoute(String route) async {
    await _appDb.save(key: 'initalRoute', value: route);
  }
}
