import 'package:camelus/services/nostr/metadata/nip_05.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final nip05provider = Provider<Nip05>((ref) {
  var nip05 = Nip05();

  return nip05;
});
