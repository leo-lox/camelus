// ignore_for_file: non_constant_identifier_names

class NostrTag {
  final String type;

  final String value;

  final String? recommendedRelay;

  final String? marker;

  NostrTag({
    required this.type,
    required this.value,
    this.recommendedRelay,
    this.marker,
  });

  List<String> toList() {
    List<String> raw = [type, value];

    if (marker != null && marker!.isNotEmpty) {
      raw.add(recommendedRelay ?? '');
      raw.add(marker!);
    } else if (recommendedRelay != null && recommendedRelay!.isNotEmpty) {
      raw.add(recommendedRelay!);
    }

    return raw;
  }

  @override
  String toString() {
    return 'NostrTag{type: $type, value: $value, recommended_relay: $recommendedRelay, marker: $marker}';
  }
}
