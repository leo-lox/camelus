class KeyPair {
  /// [privateKey] is a 32-bytes hex-encoded string
  final String privateKey;

  /// [publicKey] is a 32-bytes hex-encoded string
  final String publicKey;

  /// [privateKeyHr] is a human readable private key e.g. nsec
  final String privateKeyHr;

  /// [publicKeyHr] is a human readable public key e.g. npub
  final String publicKeyHr;

  KeyPair({
    required this.privateKey,
    required this.publicKey,
    required this.privateKeyHr,
    required this.publicKeyHr,
  });

  Map<String, dynamic> toJson() => {
        'privateKey': privateKey,
        'publicKey': publicKey,
        'privateKeyHr': privateKeyHr,
        'publicKeyHr': publicKeyHr,
      };

  factory KeyPair.fromJson(Map<String, dynamic> json) => KeyPair(
        privateKey: json['privateKey'],
        publicKey: json['publicKey'],
        privateKeyHr: json['privateKeyHr'],
        publicKeyHr: json['publicKeyHr'],
      );
}
