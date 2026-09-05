import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../domain_layer/entities/map_coordinate.dart';
import 'atoms/location_action_button.dart';
import 'atoms/location_details_sheet.dart';
import 'atoms/map_error_banner.dart';
import 'atoms/map_search_bar.dart';
import 'atoms/map_search_results.dart';
import 'atoms/navigation_action_button.dart';
import 'map_state_notifier.dart';
import 'utils/map_pin_generator.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final _searchController = TextEditingController();
  late final DraggableScrollableController _sheetController;
  MapboxMap? _map;
  PointAnnotationManager? _pointManager;
  PolylineAnnotationManager? _lineManager;
  Uint8List? _cachedPinBytes;

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController();
    _sheetController.addListener(_onSheetChanged);
  }

  void _onSheetChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onSheetChanged);
    _sheetController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    if (!mounted) return;
    _map = map;
    map.addInteraction(
      TapInteraction.onMap(_selectMapLocation),
      interactionID: 'select-map-location',
    );
    if (!mounted || _map != map) return;
    _pointManager = await map.annotations.createPointAnnotationManager();
    if (!mounted || _map != map) return;
    _lineManager = await map.annotations.createPolylineAnnotationManager();
    if (!mounted || _map != map) return;
    await map.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        puckBearingEnabled: true,
        puckBearing: PuckBearing.HEADING,
        showAccuracyRing: true,
      ),
    );
    if (!mounted || _map != map) return;
    await _render(ref.read(mapStateProvider));
  }

  Future<void> _render(MapState state) async {
    final map = _map;
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary.toARGB32();
    if (!mounted || map == null) return;
    await _pointManager?.deleteAll();
    if (!mounted || _map != map) return;
    await _lineManager?.deleteAll();
    if (!mounted || _map != map) return;

    final destination = state.destination;
    if (destination != null) {
      _cachedPinBytes ??= await MapPinGenerator.createPinImage(
        colorScheme.error,
      );
      if (!mounted || _map != map) return;
      await _pointManager?.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              destination.coordinate.longitude,
              destination.coordinate.latitude,
            ),
          ),
          image: _cachedPinBytes!,
          iconAnchor: IconAnchor.BOTTOM,
        ),
      );
    }
    if (!mounted || _map != map) return;
    final route = state.route;
    if (route != null && route.geometry.length > 1) {
      await _lineManager?.create(
        PolylineAnnotationOptions(
          geometry: LineString(
            coordinates: route.geometry.map(_position).toList(),
          ),
          lineColor: primaryColor,
          lineWidth: 6,
        ),
      );
    }
  }

  Position _position(MapCoordinate coordinate) =>
      Position(coordinate.longitude, coordinate.latitude);

  Future<void> _flyToLocation(MapCoordinate location) async {
    final map = _map;
    if (map == null || !mounted) return;
    await map.flyTo(
      CameraOptions(center: Point(coordinates: _position(location)), zoom: 15),
      MapAnimationOptions(duration: 650),
    );
  }

  Future<void> _handleLocationFabTap() async {
    await ref.read(mapStateProvider.notifier).onLocationFabPressed();
    final currentState = ref.read(mapStateProvider);
    if (currentState.currentLocation != null &&
        currentState.locationStatus == LocationLockStatus.lockedCentered) {
      await _flyToLocation(currentState.currentLocation!);
    }
  }

  Future<void> _selectMapLocation(MapContentGestureContext context) async {
    if (!mounted) return;
    final coordinate = MapCoordinate(
      longitude: context.point.coordinates.lng.toDouble(),
      latitude: context.point.coordinates.lat.toDouble(),
    );
    ref.read(mapStateProvider.notifier).selectMapLocation(coordinate);
    await _focusPlace(coordinate);
  }

  Future<void> _focusPlace(MapCoordinate coordinate) =>
      _map?.flyTo(
        CameraOptions(
          center: Point(coordinates: _position(coordinate)),
          zoom: 15,
        ),
        MapAnimationOptions(duration: 650),
      ) ??
      Future.value();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapStateProvider);

    ref.listen<MapState>(mapStateProvider, (previous, next) {
      if (previous?.destination != next.destination ||
          previous?.route != next.route) {
        _render(next);
      }

      if (next.destination == null && _searchController.text.isNotEmpty) {
        _searchController.clear();
      }

      final location = next.currentLocation;
      if (location != null) {
        final becameLocked =
            previous?.locationStatus != LocationLockStatus.lockedCentered &&
            next.locationStatus == LocationLockStatus.lockedCentered;
        if (becameLocked) {
          _flyToLocation(location);
        }
      }
    });

    final hasRoute = state.route != null;
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final isSheetOpen = state.destination != null && state.isLocationSheetOpen;

    final double currentSheetExtent = isSheetOpen && _sheetController.isAttached
        ? _sheetController.size
        : (isSheetOpen ? 0.35 : 0.0);

    final double fabBottom = isSheetOpen
        ? (currentSheetExtent * screenHeight) + 16.0
        : 24.0;

    final bool hideFabGroup = isSheetOpen && currentSheetExtent >= 0.50;

    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            onMapCreated: _onMapCreated,
            onScrollListener: (_) {
              ref.read(mapStateProvider.notifier).onMapMovedByUser();
            },
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MapSearchBar(controller: _searchController),
                      const SizedBox(height: 8),
                      MapSearchResults(
                        onPlaceTap: (place) {
                          _searchController.text = place.name;
                          ref
                              .read(mapStateProvider.notifier)
                              .selectDestination(place);
                          _focusPlace(place.coordinate);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: fabBottom,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: hideFabGroup ? 0.0 : 1.0,
              child: IgnorePointer(
                ignoring: hideFabGroup,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    NavigationActionButton(
                      onPressed: () {
                        // Start route navigation (no logic for now)
                      },
                    ),
                    const SizedBox(height: 12),
                    LocationActionButton(
                      onPressed: _handleLocationFabTap,
                      hasActiveRoute: hasRoute,
                    ),
                  ],
                ),
              ),
            ),
          ),
          LocationDetailsSheet(controller: _sheetController),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: MapErrorBanner(),
          ),
        ],
      ),
    );
  }
}
