import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';

final dbNdkProvider = NotifierProvider<DbProviderNotifier, CacheManager?>(
  DbProviderNotifier.new,
);

class DbProviderNotifier extends Notifier<CacheManager?> {
  @override
  CacheManager? build() {
    return null;
  }

  void setDB(CacheManager newDb) {
    state = newDb;
  }
}
