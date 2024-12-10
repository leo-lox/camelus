import 'package:ndk/ndk.dart';
import 'package:riverpod/riverpod.dart';

final dbNdkProvider =
    StateNotifierProvider<DbProviderNotifier, CacheManager?>((ref) {
  return DbProviderNotifier();
});

class DbProviderNotifier extends StateNotifier<CacheManager?> {
  DbProviderNotifier() : super(null);

  void setDB(CacheManager newDb) {
    state = newDb;
  }
}
