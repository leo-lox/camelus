// ignore_for_file: non_constant_identifier_names

class NostrTag {
  final String type;

  final String value;

  final String? recommended_relay;

  final String? marker;

  NostrTag({
    required this.type,
    required this.value,
    this.recommended_relay,
    this.marker,
  });

  List<String> toList() {
    List<String> raw = [type, value];

    if (recommended_relay != null && recommended_relay!.isNotEmpty) {
      raw.add(recommended_relay!);
    }
    if (marker != null && marker!.isNotEmpty) {
      raw.add(marker!);
    }

    return raw;
  }

  @override
  String toString() {
    return 'NostrTag{type: $type, value: $value, recommended_relay: $recommended_relay, marker: $marker}';
  }
}
