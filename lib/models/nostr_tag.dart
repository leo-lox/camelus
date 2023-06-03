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
}
