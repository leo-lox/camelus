import 'package:dart_geohash/dart_geohash.dart';
import 'package:ndk/ndk.dart' as ndk;

import '../../domain_layer/entities/map_coordinate.dart';
import '../../domain_layer/entities/user_location_report.dart';

class UserLocationReportModel extends UserLocationReport {
  UserLocationReportModel({
    required super.eventId,
    required super.pubkey,
    required super.coordinate,
    required super.geohash,
    required super.geohashes,
    required super.content,
    required super.createdAt,
  });

  /// Returns null if [event] has no valid "#g" geohash tag. Events tag "g"
  /// once per precision (full geohash down to 1 char), so we keep them all
  /// for viewport matching and decode the most precise one for coordinates.
  static UserLocationReportModel? fromNDKEvent(ndk.Nip01Event event) {
    final geohashes = event.tags
        .where((tag) => tag.length >= 2 && tag[0] == 'g')
        .map((tag) => tag[1])
        .toList();
    if (geohashes.isEmpty) return null;

    final mostPrecise = geohashes.reduce(
      (a, b) => a.length >= b.length ? a : b,
    );
    try {
      final decoded = GeoHasher().decode(mostPrecise);
      return UserLocationReportModel(
        eventId: event.id,
        pubkey: event.pubKey,
        coordinate: MapCoordinate(latitude: decoded[1], longitude: decoded[0]),
        geohash: mostPrecise,
        geohashes: geohashes,
        content: event.content,
        createdAt: event.createdAt,
      );
    } catch (_) {
      return null;
    }
  }
}
