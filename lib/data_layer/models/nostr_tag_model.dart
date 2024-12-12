import 'package:camelus/domain_layer/entities/nostr_tag.dart';

class NostrTagModel extends NostrTag {
  NostrTagModel({
    required super.type,
    required super.value,
    super.recommended_relay,
    super.marker,
  });

  // ["e", <32-bytes hex of the id of another event>, <recommended relay URL>, <marker>]
  factory NostrTagModel.fromJson(List<dynamic>? json) {
    if (json == null || json.isEmpty) {
      throw ArgumentError("Invalid tag format: Tag cannot be empty");
    }

    final String type = json[0];
    final String value = json.length > 1 ? json[1] : '';
    final String? recommendedRelay = json.length > 2 ? json[2] : null;
    final String? marker = json.length > 3 ? json[3] : null;

    return NostrTagModel(
      type: type,
      value: value,
      recommended_relay: recommendedRelay,
      marker: marker,
    );
  }

  List<dynamic> toJson() {
    final List<dynamic> json = [type];

    if (value.isNotEmpty) {
      json.add(value);
      if (recommended_relay != null) {
        json.add(recommended_relay);
        if (marker != null) {
          json.add(marker);
        }
      }
    }

    return json;
  }
}
