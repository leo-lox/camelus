import 'package:camelus/domain_layer/entities/nostr_tag.dart';

class NostrTagModel extends NostrTag {
  NostrTagModel({
    required super.type,
    required super.value,
    super.recommended_relay,
    super.marker,
  });

  // ["e", <32-bytes hex of the id of another event>, <recommended relay URL>, <marker>]
  factory NostrTagModel.fromJson(List<dynamic> json) {
    // chec

    Map newTag = {
      "type": json[0],
      "value": json[1],
    };

    if (json.length > 2) {
      newTag["recommended_relay"] = json[2];
    }

    if (json.length > 3) {
      newTag["marker"] = json[3];
    }

    return NostrTagModel(
        type: newTag["type"],
        value: newTag["value"],
        recommended_relay: newTag["recommended_relay"],
        marker: newTag["marker"]);
  }
}
