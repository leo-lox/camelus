import 'package:camelus/data_layer/models/nip05_model.dart';
import 'package:camelus/domain_layer/entities/nip05.dart';

import '../../domain_layer/repositories/nip05_repository.dart';
import '../data_sources/http_request_data_source.dart';

class Nip05RepositoryImpl implements Nip05Repository {
  final HttpRequestDataSource dataSource;

  Nip05RepositoryImpl({required this.dataSource});

  @override
  Future<Nip05?> requestNip05(String nip05, String pubkey) async {
    String username = nip05.split("@")[0];
    String url = nip05.split("@")[1];

    String myUrl = "https://$url/.well-known/nostr.json?name=$username";

    final json = await dataSource.jsonRequest(myUrl);

    Map names = json["names"];

    Map relays = json["relays"] ?? {};

    List<String> pRelays = [];
    if (relays[pubkey] != null) {
      pRelays = List<String>.from(relays[pubkey]);
    }

    bool valid = names[username] == pubkey;

    var result = Nip05Model(
      nip05: nip05,
      valid: valid,
      lastCheck: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      relays: pRelays,
    );

    return result;
  }
}
