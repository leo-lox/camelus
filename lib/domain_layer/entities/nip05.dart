class Nip05 {
  String nip05;
  String pubkey;
  bool valid;
  int? lastCheck;
  List<String>? relays;

  Nip05({
    required this.nip05,
    required this.pubkey,
    this.valid = false,
    this.lastCheck,
    this.relays = const [],
  });
}
