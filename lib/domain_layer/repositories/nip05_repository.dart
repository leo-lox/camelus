import '../entities/nip05.dart';

abstract class Nip05Repository {
  /// makes a network request to get the Nip05 object
  Future<Nip05?> requestNip05(String nip05, String pubkey);
}
