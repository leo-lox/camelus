import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents the user's current location and heading.
class UserLocation {
  final double latitude;
  final double longitude;

  /// Heading in degrees, 0 = North, clockwise. Fused from compass + GPS.
  final double heading;

  /// Speed in meters per second.
  final double speed;

  /// Horizontal accuracy in meters.
  final double accuracy;
  final DateTime timestamp;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.speed,
    required this.accuracy,
    required this.timestamp,
  });

  UserLocation copyWith({
    double? latitude,
    double? longitude,
    double? heading,
    double? speed,
    double? accuracy,
    DateTime? timestamp,
  }) {
    return UserLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

/// Permission status for location services.
enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  notDetermined,
}

/// Provides the user's live location fused with compass heading.
///
/// Uses [Geolocator] for GPS position and [FlutterCompass] for magnetic
/// heading. When speed >= 5 m/s, GPS heading is used (more reliable at
/// speed). When speed < 5 m/s, compass heading is used (more reliable
/// when stationary or walking slowly).
class LiveLocationNotifier extends Notifier<UserLocation?> {
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<CompassEvent>? _compassSub;
  LocationPermissionStatus? _permissionStatus;

  // Latest values from each sensor for fusion.
  Position? _lastPosition;
  double? _compassHeading; // 0-360 degrees, null if compass unavailable

  LiveLocationNotifier();

  LocationPermissionStatus? get permissionStatus => _permissionStatus;

  /// The speed threshold (m/s) above which GPS heading is preferred over
  /// compass heading.
  static const double _gpsHeadingSpeedThreshold = 5.0;

  @override
  UserLocation? build() {
    ref.onDispose(() {
      _positionSub?.cancel();
      _compassSub?.cancel();
    });
    return null;
  }

  /// Check and request location permission, then start tracking.
  Future<void> requestPermissionAndStart() async {
    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _permissionStatus = LocationPermissionStatus.denied;
      return;
    }

    // Check current permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _permissionStatus = LocationPermissionStatus.denied;
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      _permissionStatus = LocationPermissionStatus.permanentlyDenied;
      return;
    }

    _permissionStatus = LocationPermissionStatus.granted;
    await _startTracking();
  }

  Future<void> _startTracking() async {
    // Start compass stream first (it's fast to init)
    _startCompassStream();

    late LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(milliseconds: 800),

        forceLocationManager: true,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText:
              "Example app will continue to receive your location even when you aren't using it",
          notificationTitle: "Running in Background",
          enableWakeLock: true,
        ),
      );
    } else {
      locationSettings = const LocationSettings(
        distanceFilter: 0,

        accuracy: LocationAccuracy.bestForNavigation,
      );
    }

    // Get initial position for an immediate fix
    try {
      final initial = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      _lastPosition = initial;
      _emitFusedLocation();
    } catch (_) {
      // If initial fix fails, the stream will provide the first update
    }

    // Start continuous position stream
    _positionSub =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (position) {
            _lastPosition = position;
            _emitFusedLocation();
          },
          onError: (_) {
            // Position stream errors are non-fatal; keep compass running
          },
        );
  }

  void _startCompassStream() {
    _compassSub = FlutterCompass.events?.listen(
      (event) {
        if (event.heading != null) {
          _compassHeading = event.heading!;
          // Re-emit with new heading even if position hasn't changed
          _emitFusedLocation();
        }
      },
      onError: (_) {
        // Compass not available on this device — non-fatal
      },
    );
  }

  /// Fuse GPS position with the best available heading source.
  void _emitFusedLocation() {
    if (_lastPosition == null) return;

    final gpsHeading = _lastPosition!.heading;
    final gpsSpeed = _lastPosition!.speed;

    // Choose heading source based on speed:
    // - At high speed (>= 5 m/s ≈ 18 km/h), GPS heading is more reliable
    // - At low speed / stationary, compass is more reliable
    double heading;
    if (gpsSpeed >= _gpsHeadingSpeedThreshold && gpsHeading >= 0) {
      heading = gpsHeading;
    } else if (_compassHeading != null) {
      heading = _compassHeading!;
    } else if (gpsHeading >= 0) {
      // Fallback to GPS heading if compass is unavailable
      heading = gpsHeading;
    } else {
      heading = 0.0; // Default to north
    }

    state = UserLocation(
      latitude: _lastPosition!.latitude,
      longitude: _lastPosition!.longitude,
      heading: heading,
      speed: gpsSpeed,
      accuracy: _lastPosition!.accuracy,
      timestamp: _lastPosition!.timestamp,
    );
  }
}

final liveLocationProvider =
    NotifierProvider<LiveLocationNotifier, UserLocation?>(
      LiveLocationNotifier.new,
    );
