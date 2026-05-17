import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'live_location_provider.dart';

/// A reusable overlay that shows the user's location on a Mapbox map with:
/// - Blue puck with heading chevron arrow
/// - Automatic camera following with gesture detection
/// - Recenter button (appears when user pans/zooms away)
/// - North-up / heading-up orientation toggle
///
/// Both [MapPage] and [NavigationPage] include this widget in their [Stack]
/// to avoid duplicating puck + camera logic.
///
/// Wrap your [MapWidget] in a [Stack] and place this as a sibling:
/// ```dart
/// Stack(children: [
///   MapWidget(onMapCreated: (map) { ... }),
///   UserLocationOverlay(mapboxMap: _mapboxMap),
/// ])
/// ```
class UserLocationOverlay extends ConsumerStatefulWidget {
  /// The [MapboxMap] instance — must already be created via [MapWidget.onMapCreated].
  final MapboxMap mapboxMap;

  /// Optional: when non-null, the overlay also updates a callback with the
  /// current [UserLocation] so the parent can feed it to other providers
  /// (e.g. navigation auto-advance).
  final void Function(UserLocation)? onLocationUpdate;

  /// Optional: provide the current zoom level for the camera.
  /// When null, a default zoom of 16.0 is used.
  final double? defaultZoom;

  /// Optional: provide the pitch for the camera.
  /// When null, 0.0 (flat) is used for the map page.
  final double? defaultPitch;

  /// Optional: callback that returns dynamic zoom for each camera update.
  /// If non-null, takes precedence over [defaultZoom].
  final double? Function()? zoomProvider;

  /// Optional: callback that returns dynamic pitch for each camera update.
  /// If non-null, takes precedence over [defaultPitch].
  final double? Function()? pitchProvider;

  /// Optional: camera padding. When null, uses SafeArea-aware defaults.
  final MbxEdgeInsets? cameraPadding;

  /// Optional: show an additional action button (e.g. preview toggle in nav).
  final Widget? extraControl;

  const UserLocationOverlay({
    super.key,
    required this.mapboxMap,
    this.onLocationUpdate,
    this.defaultZoom,
    this.defaultPitch,
    this.zoomProvider,
    this.pitchProvider,
    this.cameraPadding,
    this.extraControl,
  });

  @override
  ConsumerState<UserLocationOverlay> createState() =>
      _UserLocationOverlayState();
}

class _UserLocationOverlayState extends ConsumerState<UserLocationOverlay>
    with TickerProviderStateMixin {
  // Annotation managers
  CircleAnnotationManager? _userPuckManager;
  PolylineAnnotationManager? _headingIndicatorManager;

  // Annotation instances for smooth in-place updates (no flicker)
  CircleAnnotation? _puckAnnotation;
  final List<PolylineAnnotation?> _headingAnnotations = [];

  // Smooth interpolation between GPS fixes
  late final AnimationController _puckAnimController;
  double _fromLat = 0.0;
  double _fromLng = 0.0;
  double _fromHeading = 0.0;
  double _toLat = 0.0;
  double _toLng = 0.0;
  double _toHeading = 0.0;
  double _displayLat = 0.0;
  double _displayLng = 0.0;
  double _displayHeading = 0.0;
  static const _puckAnimDurationMs = 500;

  // Camera state
  DateTime _lastCameraUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  static const _cameraThrottleMs = 400;
  // Heading throttle: update bearing more frequently (compass is smooth)
  DateTime _lastHeadingUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  static const _headingThrottleMs = 200;

  bool _isFollowingUser = true;
  bool _isHeadingUp = true;

  // Stored subscriptions so we can cancel them before dispose
  ProviderSubscription<UserLocation?>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _puckAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _puckAnimDurationMs),
    )..addListener(_onPuckAnimTick);
    // Request permission and start GPS tracking on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(liveLocationProvider.notifier).requestPermissionAndStart();
      _init();
    });
  }

  Future<void> _init() async {
    await _createAnnotationManagers();
    await _ensurePuckAnnotations();
    _setupGestureListeners();
    _listenToLocation();
  }

  @override
  void didUpdateWidget(covariant UserLocationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapboxMap != widget.mapboxMap) {
      // Map instance changed (shouldn't normally happen, but handle it)
      _init();
    }
  }

  @override
  void dispose() {
    _puckAnimController.dispose();
    _locationSubscription?.close();
    _userPuckManager?.deleteAll();
    _headingIndicatorManager?.deleteAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locPermission = ref
        .watch(liveLocationProvider.notifier)
        .permissionStatus;
    final userLoc = ref.watch(liveLocationProvider);

    // Show controls when we have a location fix
    return Stack(
      children: [
        // Permission banner
        if (locPermission == LocationPermissionStatus.denied ||
            locPermission == LocationPermissionStatus.permanentlyDenied)
          _PermissionBanner(
            isPermanentlyDenied:
                locPermission == LocationPermissionStatus.permanentlyDenied,
          ),

        // Controls cluster (bottom-right)
        if (userLoc != null)
          Positioned(
            right: 16,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NavControlButton(
                    icon: _isFollowingUser
                        ? PhosphorIcons.navigationArrow()
                        : PhosphorIcons.crosshair(),
                    tooltip: _isFollowingUser ? 'Following' : 'Re-center',
                    isActive: _isFollowingUser,
                    onPressed: _recenter,
                  ),
                  const SizedBox(height: 8),
                  _NavControlButton(
                    icon: _isHeadingUp
                        ? PhosphorIcons.compass()
                        : PhosphorIcons.compassRose(),
                    tooltip: _isHeadingUp ? 'Heading up' : 'North up',
                    isActive: _isHeadingUp,
                    onPressed: () =>
                        setState(() => _isHeadingUp = !_isHeadingUp),
                  ),
                  if (widget.extraControl != null) ...[
                    const SizedBox(height: 8),
                    widget.extraControl!,
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  Future<void> _createAnnotationManagers() async {
    _userPuckManager ??= await widget.mapboxMap.annotations
        .createCircleAnnotationManager(id: 'user-puck');
    _headingIndicatorManager ??= await widget.mapboxMap.annotations
        .createPolylineAnnotationManager(id: 'heading-indicator');
  }

  Future<void> _ensurePuckAnnotations() async {
    if (_userPuckManager == null || _headingIndicatorManager == null) return;

    if (_puckAnnotation == null) {
      _puckAnnotation = await _userPuckManager!.create(
        CircleAnnotationOptions(
          geometry: Point(coordinates: Position(0, 0)),
          circleRadius: 10.0,
          circleColor: const Color(0xFF2196F3).value,
          circleStrokeColor: Colors.white.value,
          circleStrokeWidth: 4.0,
        ),
      );
    }

    if (_headingAnnotations.length < 3) {
      _headingAnnotations.clear();
      final created = await _headingIndicatorManager!.createMulti([
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: [Position(0, 0), Position(0, 0)]),
          lineColor: const Color(0xFF2196F3).value,
          lineWidth: 5.0,
          lineOpacity: 0.9,
        ),
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: [Position(0, 0), Position(0, 0)]),
          lineColor: const Color(0xFF2196F3).value,
          lineWidth: 4.0,
          lineOpacity: 0.8,
        ),
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: [Position(0, 0), Position(0, 0)]),
          lineColor: const Color(0xFF2196F3).value,
          lineWidth: 4.0,
          lineOpacity: 0.8,
        ),
      ]);
      _headingAnnotations.addAll(created);
    }
  }

  /// Recreate annotations after they were removed from the map
  /// (e.g. due to a style change). Clears cached references and re-adds them.
  Future<void> _recreateAnnotations() async {
    _puckAnnotation = null;
    _headingAnnotations.clear();
    // Annotation managers may also be invalid after a style change
    _userPuckManager = null;
    _headingIndicatorManager = null;
    await _createAnnotationManagers();
    await _ensurePuckAnnotations();
  }

  void _setupGestureListeners() {
    widget.mapboxMap.setOnMapMoveListener((context) {
      if (_isFollowingUser) {
        setState(() => _isFollowingUser = false);
      }
    });
    widget.mapboxMap.setOnMapZoomListener((context) {
      if (_isFollowingUser) {
        setState(() => _isFollowingUser = false);
      }
    });
  }

  void _listenToLocation() {
    _locationSubscription?.close();
    _locationSubscription = ref.listenManual<UserLocation?>(
      liveLocationProvider,
      (prev, next) {
        if (!mounted) return;
        if (next != null) {
          _updateUserPuck(next);

          // Notify parent (e.g. navigation auto-advance)
          widget.onLocationUpdate?.call(next);

          // Camera updates — only when following
          if (_isFollowingUser) {
            final headingChanged =
                prev != null &&
                next.latitude == prev.latitude &&
                next.longitude == prev.longitude &&
                next.heading != prev.heading;

            if (headingChanged) {
              _updateBearingOnly(next);
            } else {
              _updateCamera(next);
            }
          }
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Smooth puck interpolation
  // ---------------------------------------------------------------------------

  void _onPuckAnimTick() {
    final t = Curves.easeOutSine.transform(_puckAnimController.value);
    // Lerping angles requires wrapping to handle 350→10 correctly.
    final dHeading = _toHeading - _fromHeading;
    final shortestAngle = (dHeading + 540) % 360 - 180;
    _displayLat = _fromLat + (_toLat - _fromLat) * t;
    _displayLng = _fromLng + (_toLng - _fromLng) * t;
    _displayHeading = _fromHeading + shortestAngle * t;
    _renderPuck(_displayLat, _displayLng, _displayHeading);
  }

  /// Snap the puck immediately to a location (no animation),
  /// used for the very first fix and after recentering.
  void _snapPuck(double lat, double lng, double heading) {
    _displayLat = lat;
    _displayLng = lng;
    _displayHeading = heading;
    _fromLat = lat;
    _fromLng = lng;
    _fromHeading = heading;
    _toLat = lat;
    _toLng = lng;
    _toHeading = heading;
    _puckAnimController.stop();
    _renderPuck(lat, lng, heading);
  }

  void _animatePuckTo(double lat, double lng, double heading) {
    _fromLat = _displayLat;
    _fromLng = _displayLng;
    _fromHeading = _displayHeading;
    _toLat = lat;
    _toLng = lng;
    _toHeading = heading;
    _puckAnimController.forward(from: 0);
  }

  // ---------------------------------------------------------------------------
  // Puck
  // ---------------------------------------------------------------------------

  Future<void> _updateUserPuck(UserLocation loc) async {
    if (_puckAnnotation == null || _headingAnnotations.length < 3) {
      // Annotations not ready yet — snap when they become available
      _snapPuck(loc.latitude, loc.longitude, loc.heading);
      return;
    }

    // First fix ever — just snap (nothing to interpolate from)
    if (_puckAnimController.status == AnimationStatus.dismissed &&
        _displayLat == 0.0 &&
        _displayLng == 0.0) {
      _snapPuck(loc.latitude, loc.longitude, loc.heading);
      return;
    }

    _animatePuckTo(loc.latitude, loc.longitude, loc.heading);
  }

  /// Actually move the annotation objects to the given position.
  Future<void> _renderPuck(double lat, double lng, double heading) async {
    if (_puckAnnotation == null || _headingAnnotations.length < 3) return;

    final userPoint = Point(coordinates: Position(lng, lat));

    // Update puck dot in-place
    _puckAnnotation!.geometry = userPoint;
    try {
      await _userPuckManager!.update(_puckAnnotation!);
    } catch (_) {
      await _recreateAnnotations();
      return;
    }

    // Compute heading arrow geometry
    final headingRad = heading * math.pi / 180;
    const arrowLengthMeters = 25.0;
    const metersPerDegree = 111320.0;
    final tailLatDelta = arrowLengthMeters / metersPerDegree;
    final tailLngDelta =
        arrowLengthMeters / (metersPerDegree * math.cos(lat * math.pi / 180));

    final tailLat = lat - tailLatDelta * math.cos(headingRad);
    final tailLng = lng - tailLngDelta * math.sin(headingRad);

    const armLengthMeters = 8.0;
    final armLatDelta = armLengthMeters / metersPerDegree;
    final armLngDelta =
        armLengthMeters / (metersPerDegree * math.cos(lat * math.pi / 180));
    const armAngle = 0.4;

    final leftArmLat =
        tailLat -
        armLatDelta * math.cos(headingRad - armAngle) +
        armLatDelta * math.cos(headingRad);
    final leftArmLng =
        tailLng -
        armLngDelta * math.sin(headingRad - armAngle) +
        armLngDelta * math.sin(headingRad);
    final rightArmLat =
        tailLat -
        armLatDelta * math.cos(headingRad + armAngle) +
        armLatDelta * math.cos(headingRad);
    final rightArmLng =
        tailLng -
        armLngDelta * math.sin(headingRad + armAngle) +
        armLngDelta * math.sin(headingRad);

    // Update polylines in-place
    for (int i = 0; i < 3; i++) {
      final LineString geom;
      if (i == 0) {
        geom = LineString(
          coordinates: [Position(tailLng, tailLat), Position(lng, lat)],
        );
      } else if (i == 1) {
        geom = LineString(
          coordinates: [
            Position(tailLng, tailLat),
            Position(leftArmLng, leftArmLat),
          ],
        );
      } else {
        geom = LineString(
          coordinates: [
            Position(tailLng, tailLat),
            Position(rightArmLng, rightArmLat),
          ],
        );
      }
      _headingAnnotations[i]!.geometry = geom;
      try {
        await _headingIndicatorManager!.update(_headingAnnotations[i]!);
      } catch (_) {
        await _recreateAnnotations();
        return;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Camera
  // ---------------------------------------------------------------------------

  Future<void> _updateBearingOnly(UserLocation loc) async {
    if (!_isHeadingUp) return;

    final now = DateTime.now();
    if (now.difference(_lastHeadingUpdate).inMilliseconds <
        _headingThrottleMs) {
      return;
    }
    _lastHeadingUpdate = now;

    final pitch = widget.pitchProvider?.call() ?? widget.defaultPitch ?? 0.0;

    await widget.mapboxMap.flyTo(
      CameraOptions(bearing: loc.heading, pitch: pitch),
      MapAnimationOptions(duration: 150, startDelay: 0),
    );
  }

  Future<void> _updateCamera(UserLocation loc) async {
    final now = DateTime.now();
    if (now.difference(_lastCameraUpdate).inMilliseconds < _cameraThrottleMs) {
      return;
    }
    _lastCameraUpdate = now;
    _lastHeadingUpdate = now;

    final zoom = widget.zoomProvider?.call() ?? widget.defaultZoom ?? 16.0;
    final pitch = widget.pitchProvider?.call() ?? widget.defaultPitch ?? 0.0;

    final userPoint = Point(coordinates: Position(loc.longitude, loc.latitude));

    await widget.mapboxMap.flyTo(
      CameraOptions(
        center: userPoint,
        zoom: zoom,
        bearing: _isHeadingUp ? loc.heading : 0.0,
        pitch: pitch,
        padding:
            widget.cameraPadding ??
            MbxEdgeInsets(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              bottom: 16,
              right: 80,
            ),
      ),
      MapAnimationOptions(duration: 300, startDelay: 0),
    );
  }

  Future<void> _recenter() async {
    setState(() => _isFollowingUser = true);
    final loc = ref.read(liveLocationProvider);
    if (loc != null) {
      _snapPuck(loc.latitude, loc.longitude, loc.heading);
      _lastCameraUpdate = DateTime.fromMillisecondsSinceEpoch(0);
      _lastHeadingUpdate = DateTime.fromMillisecondsSinceEpoch(0);
      await _updateCamera(loc);
    }
  }
}

// =============================================================================
// Shared UI components
// =============================================================================

/// Location permission request banner.
class _PermissionBanner extends ConsumerWidget {
  final bool isPermanentlyDenied;

  const _PermissionBanner({required this.isPermanentlyDenied});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.mapPinLine(),
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Location Access Required',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPermanentlyDenied
                          ? 'Location permission was permanently denied. Please enable it in your device settings.'
                          : 'Location access is needed to show your position on the map.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () {
                        ref
                            .read(liveLocationProvider.notifier)
                            .requestPermissionAndStart();
                      },
                      icon: Icon(PhosphorIcons.navigationArrow()),
                      label: Text(
                        isPermanentlyDenied
                            ? 'Open Settings'
                            : 'Grant Permission',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual button in the navigation controls cluster.
class _NavControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onPressed;

  const _NavControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(28),
      color: isActive
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surface,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            size: 22,
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
