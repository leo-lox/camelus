import 'dart:convert';

import 'otso_sync_model.dart';

class Wish implements OtsoSyncModelSource {
  final int id;
  final String locationName;
  final String body;
  final String permalink;
  final String createdAt;
  final double longitude;
  final double latitude;

  Wish({
    required this.id,
    required this.locationName,
    required this.body,
    required this.permalink,
    required this.createdAt,
    required this.latitude,
    required this.longitude,
  });

  factory Wish.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'];
    return Wish(
      id: attributes['id'],
      locationName: attributes['location_name'],
      body: attributes['body'],
      permalink: attributes['permalink'],
      createdAt: attributes['created_at'],
      latitude: attributes['location_point']['latitude'],
      longitude: attributes['location_point']['longitude'],
    );
  }

  @override
  OtsoSyncModel toOtosSyncModel() {
    DateTime postCreatedAt = DateTime.parse(createdAt);
    final postCreatedAtEpoch = postCreatedAt.millisecondsSinceEpoch ~/ 1000;

    return OtsoSyncModel(
        id: id,
        source: "padlet",
        body: body,
        createdAt: postCreatedAtEpoch,
        latitude: latitude,
        longitude: longitude);
  }

  @override
  String toString() {
    return 'Wish(id: $id, locationName: $locationName, body: $body, permalink: $permalink, createdAt: $createdAt)';
  }

  static List<OtsoSyncModel> parse(String unparsed) {
    final wishes = parseWishes(unparsed);
    return wishes.map((e) => e.toOtosSyncModel()).toList();
  }
}

List<Wish> parseWishes(String responseBody) {
  final parsed = jsonDecode(responseBody);
  final List<dynamic> data = parsed['data'];
  return data.map((json) => Wish.fromJson(json)).toList();
}
