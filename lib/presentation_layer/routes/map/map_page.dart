import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../domain_layer/entities/map_coordinate.dart';
import '../../../domain_layer/entities/navigation_route.dart';
import '../../routing/route_paths.dart';
import 'map_state_notifier.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final _searchController = TextEditingController();
  MapboxMap? _map;
  PointAnnotationManager? _pointManager;
  PolylineAnnotationManager? _lineManager;
  Future<Uint8List>? _pinImage;

  @override
  void dispose() {
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
      final pinImage = await (_pinImage ??= _createPinImage(colorScheme.error));
      if (!mounted || _map != map) return;
      await _pointManager?.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              destination.coordinate.longitude,
              destination.coordinate.latitude,
            ),
          ),
          image: pinImage,
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

  Future<Uint8List> _createPinImage(Color color) async {
    const size = ui.Size(72, 72);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.location_on.codePoint),
        style: TextStyle(
          color: color,
          fontFamily: Icons.location_on.fontFamily,
          package: Icons.location_on.fontPackage,
          fontSize: size.width,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset((size.width - painter.width) / 2, 0));
    final image = await recorder.endRecording().toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes!.buffer.asUint8List();
  }

  Future<void> _locateUser() async {
    await ref.read(mapStateProvider.notifier).locateUser();
    final location = ref.read(mapStateProvider).currentLocation;
    if (location != null) {
      await _map?.flyTo(
        CameraOptions(
          center: Point(coordinates: _position(location)),
          zoom: 14,
        ),
        MapAnimationOptions(duration: 650),
      );
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

  Widget _locationSheet(MapState state) {
    final destination = state.destination!;
    return DraggableScrollableSheet(
      initialChildSize: 0.32,
      minChildSize: 0.18,
      maxChildSize: 0.72,
      builder: (context, scrollController) => Material(
        elevation: 12,
        color: Theme.of(context).colorScheme.surface,
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    destination.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Close location details',
                  onPressed: ref
                      .read(mapStateProvider.notifier)
                      .closeLocationSheet,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (destination.address.isNotEmpty) Text(destination.address),
            const SizedBox(height: 16),
            SegmentedButton<TravelMode>(
              segments: const [
                ButtonSegment(
                  value: TravelMode.driving,
                  icon: Icon(Icons.directions_car),
                  tooltip: 'Driving',
                ),
                ButtonSegment(
                  value: TravelMode.walking,
                  icon: Icon(Icons.directions_walk),
                  tooltip: 'Walking',
                ),
                ButtonSegment(
                  value: TravelMode.cycling,
                  icon: Icon(Icons.directions_bike),
                  tooltip: 'Cycling',
                ),
              ],
              selected: {state.travelMode},
              onSelectionChanged: (modes) => ref
                  .read(mapStateProvider.notifier)
                  .setTravelMode(modes.first),
            ),
            const SizedBox(height: 16),
            if (state.isRouting)
              const LinearProgressIndicator()
            else if (state.route != null)
              FilledButton.icon(
                onPressed: () => context.push(RoutePaths.mapNavigation()),
                icon: const Icon(Icons.navigation),
                label: Text(
                  'Start ${(state.route!.lengthMeters / 1000).toStringAsFixed(1)} km',
                ),
              )
            else
              FilledButton.icon(
                onPressed: () =>
                    ref.read(mapStateProvider.notifier).calculateRoute(),
                icon: const Icon(Icons.directions),
                label: const Text('Get directions'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapStateProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            viewport: CameraViewportState(
              center: Point(coordinates: Position(13.405, 52.52)),
              zoom: 10,
            ),
            onMapCreated: _onMapCreated,
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Material(
                    elevation: 5,
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: ref
                              .read(mapStateProvider.notifier)
                              .setQuery,
                          decoration: InputDecoration(
                            hintText: 'Search for a destination',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: state.isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                          ),
                        ),
                        if (state.suggestions.isNotEmpty)
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 280),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: state.suggestions.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final place = state.suggestions[index];
                                return ListTile(
                                  leading: const Icon(
                                    Icons.location_on_outlined,
                                  ),
                                  title: Text(place.name),
                                  subtitle: place.address.isEmpty
                                      ? null
                                      : Text(place.address),
                                  onTap: () {
                                    _searchController.text = place.name;
                                    ref
                                        .read(mapStateProvider.notifier)
                                        .selectDestination(place);
                                    _focusPlace(place.coordinate);
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: state.route == null ? 24 : 150,
            child: FloatingActionButton(
              tooltip: 'Find my location',
              backgroundColor: scheme.surface,
              foregroundColor: scheme.onSurface,
              onPressed: _locateUser,
              child: const Icon(Icons.my_location),
            ),
          ),
          if (state.destination != null && state.isLocationSheetOpen)
            _locationSheet(state),
          if (state.error != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: MaterialBanner(
                content: Text(state.error!),
                actions: [
                  TextButton(
                    onPressed: _locateUser,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
