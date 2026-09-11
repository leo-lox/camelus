import 'map_coordinate.dart';

/// A user-broadcast location report (geotagged nostr event).
///
/// Events tag "g" once per geohash precision (full geohash down to 1
/// character), so [geohashes] holds every precision and [geohash] is just
/// the most precise (longest) one, used for display.
class UserLocationReport {
  final String eventId;
  final String pubkey;
  final MapCoordinate coordinate;
  final String geohash;
  final List<String> geohashes;
  final String content;
  final int createdAt;

  const UserLocationReport({
    required this.eventId,
    required this.pubkey,
    required this.coordinate,
    required this.geohash,
    required this.geohashes,
    required this.content,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      other is UserLocationReport && other.eventId == eventId;

  @override
  int get hashCode => eventId.hashCode;
}
