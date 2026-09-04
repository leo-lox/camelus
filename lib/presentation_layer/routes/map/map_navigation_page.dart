import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../domain_layer/entities/map_coordinate.dart';
import 'map_state_notifier.dart';

class MapNavigationPage extends ConsumerStatefulWidget {
  const MapNavigationPage({super.key});

  @override
  ConsumerState<MapNavigationPage> createState() => _MapNavigationPageState();
}

class _MapNavigationPageState extends ConsumerState<MapNavigationPage> {
  MapboxMap? _map;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mapStateProvider.notifier).startNavigation();
    });
  }

  @override
  void dispose() {
    ref.read(mapStateProvider.notifier).stopNavigation();
    super.dispose();
  }

  void _onMapCreated(MapboxMap map) {
    _map = map;
  }

  void _follow(MapCoordinate location) {
    _map?.easeTo(
      CameraOptions(
        center: Point(
          coordinates: Position(location.longitude, location.latitude),
        ),
        zoom: 16,
        bearing: 0,
      ),
      MapAnimationOptions(duration: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapStateProvider);
    final route = state.route;
    if (route == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/map'),
            child: const Text('Choose a destination first'),
          ),
        ),
      );
    }
    ref.listen<MapState>(mapStateProvider, (previous, next) {
      final location = next.currentLocation;
      if (location != null && location != previous?.currentLocation) {
        _follow(location);
      }
    });
    final maneuver =
        route.maneuvers[state.activeManeuverIndex.clamp(
          0,
          route.maneuvers.length - 1,
        )];
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(
                  maneuver.beginCoordinate.longitude,
                  maneuver.beginCoordinate.latitude,
                ),
              ),
              zoom: 16,
            ),
            onMapCreated: _onMapCreated,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Stop navigation',
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          maneuver.instruction,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Theme.of(context).colorScheme.surface,
                child: Text(
                  '${(maneuver.lengthMeters / 1000).toStringAsFixed(1)} km remaining  |  ${route.duration.inMinutes} min',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
