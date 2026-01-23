import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';

import '../../presentation_layer/providers/ndk_provider.dart';

void listenToConnectivityChanges(WidgetRef ref) {
  Connectivity().onConnectivityChanged
      .skip(1) // do not fire on app startup
      .listen((List<ConnectivityResult> result) {
        if (result.any((e) => e == ConnectivityResult.none)) {
          return;
        }
        final ndkInstance = ref.read(ndkProvider);
        ndkTryReconnect(ndkInstance);
      });
}

void ndkTryReconnect(Ndk ndkInstance) {
  ndkInstance.connectivity.tryReconnect();
}
