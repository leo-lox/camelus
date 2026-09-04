import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk_flutter/ndk_flutter.dart';
import 'package:flutter/foundation.dart';

import '../presentation_layer/components/update_check/update_check.dart';
import '../presentation_layer/providers/app_lifecycle_provider.dart';
import '../presentation_layer/providers/language_provider.dart';
import '../presentation_layer/providers/ndk_provider.dart';
import 'connectivity/connectivity.dart';
import 'deeplinks/deep_link_service.dart';

class AppInitializationShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppInitializationShell({super.key, required this.child});

  @override
  ConsumerState<AppInitializationShell> createState() =>
      _AppInitializationShellState();
}

class _AppInitializationShellState
    extends ConsumerState<AppInitializationShell> {
  @override
  void initState() {
    super.initState();
    _initializeAppServices();

    String mapboxAccessToken = const String.fromEnvironment(
      "MAPBOX_ACCESS_TOKEN",
    );
    MapboxOptions.setAccessToken(mapboxAccessToken);
  }

  void _initializeAppServices() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(languageProvider.notifier)
          .initializeWithSystemLocaleIfNeeded(context);

      if (!kIsWeb) {
        // deep links
        DeepLinkService.initialize(context);
      }

      // connectivity
      listenToConnectivityChanges(ref);

      // init lifecycle
      ref.read(appLifecycleProvider);
    });
  }

  @override
  void dispose() {
    DeepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ndkFlutter = ref.read(ndkFlutterProvider);

    return Stack(
      children: [
        UpdateCheck(child: widget.child),
        NPendingRequests(ndkFlutter: ndkFlutter),
      ],
    );
  }
}
