class Nip05 {
  String nip05;

  bool valid;
  int? lastCheck;
  List<String>? relays;

  Nip05({
    required this.nip05,
    this.valid = false,
    this.lastCheck,
    this.relays = const [],
  });
}
