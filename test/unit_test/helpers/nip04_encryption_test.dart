import 'dart:convert';
import 'dart:developer';

import 'package:camelus/helpers/nip04_encryption.dart';
import 'package:hex/hex.dart';
import 'package:test/test.dart';

void main() {
  group('nip04Encryption', () {
    test('decrypt', () {
      final nip04 = Nip04Encryption();
      const priv =
          "fb505c65d4df950f5d28c9e4d285ee12ffaf315deef1fc24e3c7cd1e7e35f2b1";
      const pub =
          "b1a5c93edcc8d586566fde53a20bdb50049a97b15483cb763854e57016e0fa3d";

      const ciphertext =
          "VezuSvWak++ASjFMRqBPWS3mK5pZ0vRLL325iuIL4S+r8n9z+DuMau5vMElz1tGC/UqCDmbzE2kwplafaFo/FnIZMdEj4pdxgptyBV1ifZpH3TEF6OMjEtqbYRRqnxgIXsuOSXaerWgpi0pm+raHQPseoELQI/SZ1cvtFqEUCXdXpa5AYaSd+quEuthAEw7V1jP+5TDRCEC8jiLosBVhCtaPpLcrm8HydMYJ2XB6Ixs=?iv=/rtV49RFm0XyFEwG62Eo9A==";

      final desiredResult = [
        [
          "p",
          "9ec7a778167afb1d30c4833de9322da0c08ba71a69e1911d5578d3144bb56437"
        ],
        [
          "p",
          "8c0da4862130283ff9e67d889df264177a508974e2feb96de139804ea66d6168"
        ]
      ];

      final result = nip04.decrypt(priv, pub, ciphertext);
      final parsedResult = json.decode(result);

      expect(parsedResult, desiredResult);
    });

    test('encrypt only type', () {
      const priv =
          "fb505c65d4df950f5d28c9e4d285ee12ffaf315deef1fc24e3c7cd1e7e35f2b1";
      const pub =
          "b1a5c93edcc8d586566fde53a20bdb50049a97b15483cb763854e57016e0fa3d";

      const clearTextObj = [
        [
          "p",
          "9ec7a778167afb1d30c4833de9322da0c08ba71a69e1911d5578d3144bb56437"
        ],
        [
          "p",
          "8c0da4862130283ff9e67d889df264177a508974e2feb96de139804ea66d6168"
        ]
      ];

      const desiredResult =
          "VezuSvWak++ASjFMRqBPWS3mK5pZ0vRLL325iuIL4S+r8n9z+DuMau5vMElz1tGC/UqCDmbzE2kwplafaFo/FnIZMdEj4pdxgptyBV1ifZpH3TEF6OMjEtqbYRRqnxgIXsuOSXaerWgpi0pm+raHQPseoELQI/SZ1cvtFqEUCXdXpa5AYaSd+quEuthAEw7V1jP+5TDRCEC8jiLosBVhCtaPpLcrm8HydMYJ2XB6Ixs=?iv=/rtV49RFm0XyFEwG62Eo9A==";

      final clearTextString = json.encode(clearTextObj);
      final nip04 = Nip04Encryption();
      final result = nip04.encrypt(priv, pub, clearTextString);

      expect(result.runtimeType, desiredResult.runtimeType);
    });
  });
}
