import 'dart:convert';

import 'otso_sync_model.dart';

class Iceout implements OtsoSyncModelSource {
  final int id;
  final String locationDescription;
  final bool approved;
  final int categoryEnum;
  final String smallThumbnail;
  final String incidentTime;
  final String createdAt;
  final double longitude;
  final double latitude;

  Iceout({
    required this.id,
    required this.locationDescription,
    required this.approved,
    required this.categoryEnum,
    required this.smallThumbnail,
    required this.incidentTime,
    required this.createdAt,
    required this.latitude,
    required this.longitude,
  });

  factory Iceout.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    final coordinates =
        (location?['coordinates'] as List<dynamic>? ?? const []);

    return Iceout(
      id: json['id'] as int,
      locationDescription: (json['location_description'] ?? '') as String,
      approved: (json['approved'] ?? false) as bool,
      categoryEnum: (json['category_enum'] ?? 0) as int,
      smallThumbnail: (json['small_thumbnail'] ?? '') as String,
      incidentTime: (json['incident_time'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      longitude:
          coordinates.isNotEmpty ? (coordinates[0] as num).toDouble() : 0,
      latitude: coordinates.length > 1 ? (coordinates[1] as num).toDouble() : 0,
    );
  }

  @override
  OtsoSyncModel toOtosSyncModel() {
    final postCreatedAt = DateTime.tryParse(createdAt) ??
        DateTime.tryParse(incidentTime) ??
        DateTime.now().toUtc();
    final postCreatedAtEpoch = postCreatedAt.millisecondsSinceEpoch ~/ 1000;

    return OtsoSyncModel(
      id: id,
      source: 'iceout',
      body: "$locationDescription \nsource: iceout.org",
      createdAt: postCreatedAtEpoch,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  String toString() {
    return 'Iceout(id: $id, locationDescription: $locationDescription, incidentTime: $incidentTime, createdAt: $createdAt)';
  }

  static List<OtsoSyncModel> parse(String unparsed) {
    final iceouts = parseIceouts(unparsed);
    return iceouts.map((e) => e.toOtosSyncModel()).toList();
  }
}

List<Iceout> parseIceouts(String responseBody) {
  final parsed = jsonDecode(responseBody) as List<dynamic>;
  return parsed
      .map((json) => Iceout.fromJson(json as Map<String, dynamic>))
      .toList();
}
