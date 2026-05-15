import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../l10n/app_localizations.dart';
import 'map_location_provider.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  late MapboxMap _mapboxMap;

  static const double _bottomSheetMinChildSize = 0.12;
  static const double _bottomSheetInitialChildSize = 0.22;
  static const double _bottomSheetMaxChildSize = 0.55;

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapLocationProvider);
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.map),
        backgroundColor: Colors.transparent,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          MapWidget(
            viewport: CameraViewportState(
              center: Point(coordinates: Position(4.891791, 52.355290)),
              zoom: 15.0,
              pitch: 45.0,
              bearing: 20.0,
            ),
            onMapCreated: _onMapCreated,
          ),
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
