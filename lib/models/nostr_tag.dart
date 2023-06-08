// ignore_for_file: non_constant_identifier_names

class NostrTag {
  final String type;

  final String value;

  final String? recommended_relay;

  final String? marker;

  NostrTag(
      {required this.type,
      required this.value,
      this.recommended_relay,
      this.marker});

  // ["e", <32-bytes hex of the id of another event>, <recommended relay URL>, <marker>]
  factory NostrTag.fromJson(List<String> json) {
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

    return NostrTag(
        type: newTag["type"],
        value: newTag["value"],
        recommended_relay: newTag["recommended_relay"],
        marker: newTag["marker"]);
  }
}
