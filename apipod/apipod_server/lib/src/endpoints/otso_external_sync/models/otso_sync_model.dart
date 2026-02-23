class OtsoSyncModel {
  final int id;
  final String source;
  final String body;
  final int createdAt;
  final double longitude;
  final double latitude;

  OtsoSyncModel({
    required this.id,
    required this.source,
    required this.body,
    required this.createdAt,
    required this.latitude,
    required this.longitude,
  });
}

abstract class OtsoSyncModelSource {
  OtsoSyncModel toOtosSyncModel();
}
