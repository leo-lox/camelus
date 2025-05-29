import 'dart:async';

import 'package:camelus/presentation_layer/providers/ndk_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ndk/ndk.dart';
import 'package:riverpod/riverpod.dart';

void listenToConnectivityChanges(ProviderContainer provider) {
  StreamSubscription<List<ConnectivityResult>> subscription = Connectivity()
      .onConnectivityChanged
      .skip(1) // do not fire on app startup
      .listen((List<ConnectivityResult> result) {
    if (result.any((e) => e == ConnectivityResult.none)) {
      return;
    }
    final ndkInstance = provider.read(ndkProvider);
    ndkTryReconnect(ndkInstance);
  });
}

void ndkTryReconnect(Ndk ndkInstance) {
  ndkInstance.connectivity.tryReconnect();
}
