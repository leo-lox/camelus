import 'package:camelus/services/nostr/nostr_injector.dart';
import 'package:camelus/services/nostr/nostr_service.dart';

class Search {
  late NostrService _nostrService;

  Search() {
    NostrServiceInjector injector = NostrServiceInjector();
    _nostrService = injector.nostrService;
  }

  /// search in nostr metadata for name and nip05
  List<Map<String, dynamic>> searchUsersMetadata(String query) {
    var metadata = _nostrService.usersMetadata;

    //search in metadata name and nip05
    List<Map<String, dynamic>> results = [];

    for (var entry in metadata.entries) {
      var name = entry.value['name'] ?? '';
      var nip05 = entry.value['nip05'] ?? '';

      if (name.toLowerCase().contains(query.toLowerCase()) ||
          nip05.toLowerCase().contains(query.toLowerCase())) {
        // check if already in results
        if (results.any((element) => element['id'] == entry.key)) {
          continue;
        }
        results.add({...entry.value, "id": entry.key});
      }
    }

    return results;
  }
}
