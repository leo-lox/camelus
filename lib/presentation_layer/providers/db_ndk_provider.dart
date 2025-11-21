import 'package:flutter_riverpod/legacy.dart';
import 'package:ndk/ndk.dart';

final dbNdkProvider = StateNotifierProvider<DbProviderNotifier, CacheManager?>((
  ref,
) {
  return DbProviderNotifier();
});

class DbProviderNotifier extends StateNotifier<CacheManager?> {
  DbProviderNotifier() : super(null);

  void setDB(CacheManager newDb) {
    state = newDb;
  }
}
