import '../../helpers/helpers.dart';

class GeneratedPrivateKey {
  final String mnemonicSentence;
  final List<String> mnemonicWords;
  final String privateKey;
  final String publicKey;

  String get privKeyHr => Helpers().encodeBech32(privateKey, 'nsec');
  String get publicKeyHr => Helpers().encodeBech32(publicKey, 'npub');

  GeneratedPrivateKey({
    required this.mnemonicSentence,
    required this.mnemonicWords,
    required this.privateKey,
    required this.publicKey,
  });
}
