import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../l10n/app_localizations.dart';
import 'map_location_provider.dart';
import 'route_provider.dart';
import 'route_panel.dart';
import 'route_fab.dart';
import 'route_summary_sheet.dart';
import 'valhalla_routing_service.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  late MapboxMap _mapboxMap;

  // Route annotation managers
  PolylineAnnotationManager? _routeLineManager;
  PolylineAnnotationManager? _altRouteLineManager;
  CircleAnnotationManager? _waypointCircleManager;

  static const double _bottomSheetMinChildSize = 0.12;
  static const double _bottomSheetInitialChildSize = 0.22;
  static const double _bottomSheetMaxChildSize = 0.55;

  @override
  void dispose() {
    _routeLineManager?.deleteAll();
    _altRouteLineManager?.deleteAll();
    _waypointCircleManager?.deleteAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapLocationProvider);
    final routeState = ref.watch(routeProvider);
    final l10n = AppLocalizations.of(context)!;

    ref.listen(mapLocationProvider, (previous, next) {
      if (next.isSheetOpen &&
          next.selectedLocation != null &&
          (previous?.selectedLocation?.lat != next.selectedLocation!.lat ||
              previous?.selectedLocation?.lng != next.selectedLocation!.lng)) {
        _animateToLocation(next.selectedLocation!.point);
      }
      if (!next.isSheetOpen && previous?.isSheetOpen == true) {
        _resetCameraPadding();
      }
    });

    // Listen for route responses to draw the route polyline
    ref.listen(routeProvider, (previous, next) {
      final prevResponses = previous?.routeResponses;
      final nextResponses = next.routeResponses;

      // Clear route annotations when panel closes
      if (previous?.isRoutePanelOpen == true && !next.isRoutePanelOpen) {
        _clearRouteAnnotations();
        return;
      }

      // Clear old routes when routes are cleared or changed
      if (prevResponses != null &&
          prevResponses.isNotEmpty &&
          (nextResponses.isEmpty ||
              !_listEquals(prevResponses, nextResponses))) {
        _clearRouteAnnotations();
      }

      // Draw new routes (all alternatives)
      if (nextResponses.isNotEmpty &&
          nextResponses.every((r) => r.isSuccess) &&
          (prevResponses == null ||
              !_listEquals(prevResponses, nextResponses))) {
        _drawRoutes(nextResponses, next.selectedRouteIndex);
      }

      // Redraw when selection changes (style update only)
      if (prevResponses != null &&
          nextResponses.isNotEmpty &&
          _listEquals(prevResponses, nextResponses) &&
          previous?.selectedRouteIndex != next.selectedRouteIndex) {
        _drawRoutes(nextResponses, next.selectedRouteIndex);
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      // appBar: AppBar(
      //   title: Text(l10n.map),
      //   backgroundColor: Colors.transparent,
      //   elevation: 1,
      //   surfaceTintColor: Colors.transparent,
      // ),
      floatingActionButton: const RouteFab(),
      body: Stack(
        children: [
          MapWidget(
            // viewport: CameraViewportState(
            //   center: Point(coordinates: Position(4.891791, 52.355290)),
            //   zoom: 15.0,
            //   pitch: 45.0,
            //   bearing: 20.0,
            // ),
            onMapCreated: _onMapCreated,
          ),
          // Route planning panel (top of map)
          const RoutePanel(),
          // Location details bottom sheet
          if (mapState.isSheetOpen && mapState.selectedLocation != null)
            Positioned.fill(
              child: NotificationListener<DraggableScrollableNotification>(
                onNotification: (notification) {
                  if (notification.extent <= _bottomSheetMinChildSize + 0.02) {
                    ref.read(mapLocationProvider.notifier).dismissSheet();
                  }
                  return false;
                },
                child: DraggableScrollableSheet(
                  initialChildSize: _bottomSheetInitialChildSize,
                  minChildSize: _bottomSheetMinChildSize,
                  maxChildSize: _bottomSheetMaxChildSize,
                  snap: true,
                  snapSizes: const [_bottomSheetInitialChildSize],
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: ListView(
                        controller: scrollController,
                        padding: EdgeInsets.zero,
                        children: [
                          const SizedBox(height: 8),
                          _buildDragHandle(context),
                          const SizedBox(height: 16),
                          _buildSheetContent(
                            context,
                            mapState.selectedLocation!,
                            mapState.isReverseGeocoding,
                            l10n,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          // Route summary sheet (bottom, shows turn-by-turn directions)
          if (routeState.isRoutePanelOpen && routeState.routeResponse != null)
            const Positioned.fill(
              child: IgnorePointer(ignoring: false, child: RouteSummarySheet()),
            ),
        ],
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildSheetContent(
    BuildContext context,
    TappedLocation location,
    bool isReverseGeocoding,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.mapPin(),
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.locationDetails,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isReverseGeocoding)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else ...[
            if (location.isPoi) ...[
              _buildInfoRow(
                context,
                icon: PhosphorIcons.mapPin(),
                label: l10n.name,
                value: location.poiName!,
              ),
              if (location.poiCategory != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  context,
                  icon: PhosphorIcons.tag(),
                  label: l10n.category,
                  value: location.poiCategory!,
                ),
              ],
              if (location.poiGroup != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  context,
                  icon: PhosphorIcons.folderOpen(),
                  label: l10n.poiGroup,
                  value: location.poiGroup!,
                ),
              ],
            ],
            _buildInfoRow(
              context,
              icon: PhosphorIcons.navigationArrow(),
              label: l10n.latitude,
              value: location.lat.toStringAsFixed(6),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              icon: PhosphorIcons.navigationArrow(),
              label: l10n.longitude,
              value: location.lng.toStringAsFixed(6),
            ),
            if (location.address != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                icon: PhosphorIcons.mapPinLine(),
                label: l10n.address,
                value: location.address!,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    // Tap on POI features → get name/category directly from map data
    _mapboxMap.addInteraction(TapInteraction(StandardPOIs(), _onPoiTap));
    // Tap on empty map area → get raw coordinates
    _mapboxMap.addInteraction(TapInteraction.onMap(_onMapTap));
  }

  void _onPoiTap(
    TypedFeaturesetFeature<StandardPOIs> feature,
    MapContentGestureContext context,
  ) {
    final lat = context.point.coordinates.lat.toDouble();
    final lng = context.point.coordinates.lng.toDouble();

    // If route panel is open, fill the focused waypoint
    final routeState = ref.read(routeProvider);
    if (routeState.isRoutePanelOpen) {
      ref
          .read(routeProvider.notifier)
          .setWaypointFromMapTap(
            routeState.focusedWaypointIndex,
            lat,
            lng,
            label: feature.name,
          );
      return;
    }

    ref
        .read(mapLocationProvider.notifier)
        .onMapTapped(
          lat,
          lng,
          poiName: feature.name,
          poiCategory: feature.category,
          poiGroup: feature.group,
        );
  }

  void _onMapTap(MapContentGestureContext context) {
    final lat = context.point.coordinates.lat.toDouble();
    final lng = context.point.coordinates.lng.toDouble();

    // If routes are displayed, check if the tap is near a route for selection
    final routeState = ref.read(routeProvider);
    if (routeState.isRoutePanelOpen && routeState.routeResponses.isNotEmpty) {
      _selectNearestRoute(lat, lng);
      return;
    }

    // If route panel is open, fill the focused waypoint instead of showing the location sheet
    if (routeState.isRoutePanelOpen) {
      ref
          .read(routeProvider.notifier)
          .setWaypointFromMapTap(routeState.focusedWaypointIndex, lat, lng);
      return;
    }

    ref.read(mapLocationProvider.notifier).onMapTapped(lat, lng);
  }

  Future<void> _animateToLocation(Point point) async {
    final sheetHeight =
        MediaQuery.of(context).size.height * _bottomSheetInitialChildSize;
    final appBarHeight =
        AppBar().preferredSize.height + MediaQuery.of(context).padding.top;

    _mapboxMap.flyTo(
      CameraOptions(
        center: point,
        padding: MbxEdgeInsets(
          top: appBarHeight + 16,
          left: 16,
          bottom: sheetHeight + 16,
          right: 16,
        ),
      ),
      MapAnimationOptions(duration: 500, startDelay: 0),
    );
  }

  /// Draw all route alternatives on the map.
  ///
  /// The selected route is drawn in bold blue, alternatives in lighter gray.
  /// Tapping on a polyline selects that route.
  Future<void> _drawRoutes(
    List<ValhallaRouteResponse> responses,
    int selectedIndex,
  ) async {
    // Create annotation managers if needed
    _routeLineManager ??= await _mapboxMap.annotations
        .createPolylineAnnotationManager(id: 'route-line');
    _altRouteLineManager ??= await _mapboxMap.annotations
        .createPolylineAnnotationManager(id: 'alt-route-line');
    _waypointCircleManager ??= await _mapboxMap.annotations
        .createCircleAnnotationManager(id: 'route-waypoints');

    // Clear previous annotations
    await _routeLineManager!.deleteAll();
    await _altRouteLineManager!.deleteAll();
    await _waypointCircleManager!.deleteAll();

    // Colors for alternatives
    const altColors = [
      Color(0xFF90CAF9), // light blue
      Color(0xFFCE93D8), // light purple
    ];

    // Draw each route
    for (int i = 0; i < responses.length; i++) {
      final response = responses[i];
      final points = ValhallaRoutingService.decodePolyline6(response.fullShape);
      if (points.isEmpty) continue;

      final coordinates = points
          .map((p) => Position(p.coordinates.lng, p.coordinates.lat))
          .toList();

      final isSelected = i == selectedIndex;

      // Selected route gets its own manager (thicker, darker blue)
      if (isSelected) {
        await _routeLineManager!.create(
          PolylineAnnotationOptions(
            geometry: LineString(coordinates: coordinates),
            lineColor: Colors.blue.value,
            lineWidth: 6.0,
            lineOpacity: 0.9,
            lineJoin: LineJoin.ROUND,
          ),
        );
      } else {
        // Alternative routes on the alt manager (thinner, lighter color)
        final color = altColors[(i - 1) % altColors.length];
        await _altRouteLineManager!.create(
          PolylineAnnotationOptions(
            geometry: LineString(coordinates: coordinates),
            lineColor: color.value,
            lineWidth: 4.0,
            lineOpacity: 0.6,
            lineJoin: LineJoin.ROUND,
          ),
        );
      }
    }

    // Draw waypoint markers (on top of all routes)
    final routeState = ref.read(routeProvider);
    for (int i = 0; i < routeState.waypoints.length; i++) {
      final wp = routeState.waypoints[i];
      await _waypointCircleManager!.create(
        CircleAnnotationOptions(
          geometry: Point(coordinates: Position(wp.lon, wp.lat)),
          circleRadius: i == 0 ? 10.0 : 8.0,
          circleColor: i == 0
              ? Colors.green.value
              : i == routeState.waypoints.length - 1
              ? Colors.red.value
              : Colors.orange.value,
          circleOpacity: 1.0,
          circleStrokeColor: Colors.white.value,
          circleStrokeWidth: 2.0,
        ),
      );
    }

    // Set up tap interaction on the main route line manager to select alternatives
    _setupRouteTapHandler(responses, selectedIndex);

    // Fit camera to the selected route bounding box
    final selectedResponse = responses[selectedIndex];
    final summary = selectedResponse.tripSummary;
    if (summary.minLat != null &&
        summary.minLon != null &&
        summary.maxLat != null &&
        summary.maxLon != null) {
      // Compute a bounding box that includes all alternatives for better overview
      double? allMinLat, allMinLon, allMaxLat, allMaxLon;
      for (final r in responses) {
        final s = r.tripSummary;
        if (s.minLat == null) continue;
        allMinLat = (allMinLat == null)
            ? s.minLat!
            : (s.minLat! < allMinLat ? s.minLat : allMinLat);
        allMinLon = (allMinLon == null)
            ? s.minLon!
            : (s.minLon! < allMinLon ? s.minLon : allMinLon);
        allMaxLat = (allMaxLat == null)
            ? s.maxLat!
            : (s.maxLat! > allMaxLat ? s.maxLat : allMaxLat);
        allMaxLon = (allMaxLon == null)
            ? s.maxLon!
            : (s.maxLon! > allMaxLon ? s.maxLon : allMaxLon);
      }

      if (allMinLat != null &&
          allMinLon != null &&
          allMaxLat != null &&
          allMaxLon != null) {
        final bounds = CoordinateBounds(
          southwest: Point(coordinates: Position(allMinLon, allMinLat)),
          northeast: Point(coordinates: Position(allMaxLon, allMaxLat)),
          infiniteBounds: false,
        );
        final appBarHeight =
            AppBar().preferredSize.height + MediaQuery.of(context).padding.top;
        final padding = MbxEdgeInsets(
          top: appBarHeight + 200,
          left: 32,
          bottom: 100,
          right: 32,
        );
        final cameraOptions = await _mapboxMap.cameraForCoordinateBounds(
          bounds,
          padding,
          null,
          null,
          null,
          null,
        );
        await _mapboxMap.flyTo(
          cameraOptions,
          MapAnimationOptions(duration: 500, startDelay: 0),
        );
      }
    }
  }

  /// Set up a tap handler on route polylines so the user can select alternatives.
  ///
  /// We use the onMap tap handler and check proximity to each route.
  void _setupRouteTapHandler(
    List<ValhallaRouteResponse> responses,
    int selectedIndex,
  ) {
    // We'll reuse the existing _onMapTap, but check if the tap is near a route.
    // Store the route data for tap detection.
    _routeAlternatives = responses;
  }

  List<ValhallaRouteResponse> _routeAlternatives = [];

  /// Simple list equality check (by identity, since responses are new objects each time).
  bool _listEquals(
    List<ValhallaRouteResponse> a,
    List<ValhallaRouteResponse> b,
  ) {
    if (a.length != b.length) return false;
    // If the state was just updated with new selections, the list references are the same.
    return identical(a, b);
  }

  /// Find the nearest route to a given point and select it.
  void _selectNearestRoute(double lat, double lng) {
    if (_routeAlternatives.isEmpty) return;

    int nearestIndex = 0;
    double minDist = double.infinity;

    for (int i = 0; i < _routeAlternatives.length; i++) {
      final points = ValhallaRoutingService.decodePolyline6(
        _routeAlternatives[i].fullShape,
      );
      for (final point in points) {
        final dLat = point.coordinates.lat.toDouble() - lat;
        final dLng = point.coordinates.lng.toDouble() - lng;
        final dist = dLat * dLat + dLng * dLng;
        if (dist < minDist) {
          minDist = dist;
          nearestIndex = i;
        }
      }
    }

    // Only select if the tap was reasonably close to a route (< ~50m)
    // 0.0005 degrees ≈ 50m
    if (minDist < 0.00025 &&
        nearestIndex != ref.read(routeProvider).selectedRouteIndex) {
      ref.read(routeProvider.notifier).selectRoute(nearestIndex);
    }
  }

  /// Clear all route-related annotations from the map.
  Future<void> _clearRouteAnnotations() async {
    await _routeLineManager?.deleteAll();
    await _altRouteLineManager?.deleteAll();
    await _waypointCircleManager?.deleteAll();
    _routeAlternatives = [];
  }

  Future<void> _resetCameraPadding() async {
    _mapboxMap.flyTo(
      CameraOptions(
        padding: MbxEdgeInsets(
          top:
              AppBar().preferredSize.height +
              MediaQuery.of(context).padding.top +
              16,
          left: 16,
          bottom: 16,
          right: 16,
        ),
      ),
      MapAnimationOptions(duration: 300, startDelay: 0),
    );
  }
}
