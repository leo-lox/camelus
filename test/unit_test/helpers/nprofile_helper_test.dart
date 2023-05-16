import 'package:camelus/helpers/nprofile_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:test/test.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  SharedPreferences.setMockInitialValues({});

  //WidgetsFlutterBinding.ensureInitialized();
  TestWidgetsFlutterBinding.ensureInitialized();
  group('main', () {
    final mockSharedPreferences = MockSharedPreferences();
    when(mockSharedPreferences.getString('')).thenReturn('mock');
    test('decode', () {
      var nprofileHelper = NprofileHelper();

      String nprofile =
          "nprofile1qqsrhuxx8l9ex335q7he0f09aej04zpazpl0ne2cgukyawd24mayt8gpp4mhxue69uhhytnc9e3k7mgpz4mhxue69uhkg6nzv9ejuumpv34kytnrdaksjlyr9p";

      Map<String, dynamic> expected = {
        "pubkey":
            "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d",
        "relays": ["wss://r.x.com", "wss://djbas.sadkb.com"]
      };

      var result = nprofileHelper.bech32toMap(nprofile);

      expect(result, expected);
    });

    test('encode', () {
      var nprofileHelper = NprofileHelper();

      Map<String, dynamic> map = {
        "pubkey":
            "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d",
        "relays": ["wss://r.x.com", "wss://djbas.sadkb.com"]
      };

      String expected =
          "nprofile1qqsrhuxx8l9ex335q7he0f09aej04zpazpl0ne2cgukyawd24mayt8gpp4mhxue69uhhytnc9e3k7mgpz4mhxue69uhkg6nzv9ejuumpv34kytnrdaksjlyr9p";

      var result = nprofileHelper.mapToBech32(map);

      expect(result, expected);
    });
  });
}
