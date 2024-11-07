import 'package:camelus/domain_layer/repositories/database_repository.dart';
import 'package:camelus/domain_layer/repositories/nip05_repository.dart';

import '../entities/nip05.dart';

class VerifyNip05 {
  final List<String> _inFlight = [];

  final DatabaseRepository _database;
  final Nip05Repository _nip05Repository;

  VerifyNip05(this._database, this._nip05Repository);

  Future<Nip05?> check(String nip05, String pubkey) async {
    if (nip05.isEmpty || pubkey.isEmpty) {
      throw Exception("nip05 or pubkey empty");
    }

    var databaseResult = await _database.getNip05(nip05);

    if (databaseResult != null) {
      int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      int lastCheck = databaseResult.lastCheck ?? 0;
      if (now - lastCheck < 60 * 60 * 24) {
        return databaseResult;
      }
    }

    if (_inFlight.contains(nip05)) {
      //  wait for result
      var maxRetries = 10;
      while (_inFlight.contains(nip05)) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (maxRetries-- < 0) {
          continue;
        }
      }
      var rawResult = await _database.getNip05(nip05);
      return rawResult;
    }

    _inFlight.add(nip05);

    var result = await _nip05Repository.requestNip05(nip05, pubkey);
    _inFlight.remove(nip05);

    return result;
  }
}
