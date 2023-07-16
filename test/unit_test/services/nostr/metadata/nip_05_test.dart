import 'package:camelus/services/nostr/metadata/nip_05.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http/testing.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

//class MockClient extends Mock implements http.Client {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

@GenerateMocks([http.Client])
void main() {
  SharedPreferences.setMockInitialValues({}); //set values here

  //TestWidgetsFlutterBinding.ensureInitialized();
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  group('Nip05', () {
    Future<http.Response> requestHandler(http.Request request) async {
      const apiResponse =
          '{"names": {"username": "pubkey"}, "relays": {"pubkey": ["relay1", "relay2"]}}';
      return http.Response(apiResponse, 200);
    }

    Future<http.Response> requestHandlerErr(http.Request request) async {
      const apiResponse = '';
      return http.Response(apiResponse, 500);
    }

    test('returns a Map if the http call completes successfully', () async {
      final client = MockClient(requestHandler);

      final mockSharedPreferences = MockSharedPreferences();
      when(mockSharedPreferences.getString('')).thenReturn('mock');

      // Use Mockito to return a successful response when it calls the provided http.Client.
      // when(client.get(
      //         Uri.parse('https://lox.de/.well-known/nostr.json?name=username')))
      //     .thenAnswer((_) async => http.Response(
      //         '{"names": {"username": "pubkey"}, "relays": {"pubkey": ["relay1", "relay2"]}}',
      //         200));

      Nip05 nip05 = Nip05();
      await Future.delayed(const Duration(milliseconds: 500));

      // insert mock http client
      nip05.client = client;

      expect(await nip05.checkNip05('username@lox.de', 'pubkey'),
          isA<Map<String, dynamic>>());
    });

    test('throws an exception if the http call completes with an error',
        () async {
      final client = MockClient(requestHandlerErr);
      final mockSharedPreferences = MockSharedPreferences();
      when(mockSharedPreferences.getString('')).thenReturn('mock');

      var nip05 = Nip05(); // Initialize your class

      // Comment out the following lines if you have implemented dependency injection for http.Client in your class
      // And pass the mock client to your class like this: var nip05 = Nip05(client: client);

      nip05.client =
          client; // Make sure to add this line in your class for testing purposes

      expect(nip05.checkNip05('username@url', 'pubkey'), throwsException);
    });
    test('result is invalid', () async {
      final client = MockClient(requestHandler);
      final mockSharedPreferences = MockSharedPreferences();
      when(mockSharedPreferences.getString('')).thenReturn('mock');

      var nip05 = Nip05(); // Initialize your class

      // Comment out the following lines if you have implemented dependency injection for http.Client in your class
      // And pass the mock client to your class like this: var nip05 = Nip05(client: client);

      nip05.client =
          client; // Make sure to add this line in your class for testing purposes

      var result =
          await nip05.checkNip05('username@url', 'non-existing-pubkey');

      expect(result['valid'], false);
    });
    test('result is valid', () async {
      final client = MockClient(requestHandler);
      final mockSharedPreferences = MockSharedPreferences();
      when(mockSharedPreferences.getString('')).thenReturn('mock');

      var nip05 = Nip05(); // Initialize your class

      // Comment out the following lines if you have implemented dependency injection for http.Client in your class
      // And pass the mock client to your class like this: var nip05 = Nip05(client: client);

      nip05.client =
          client; // Make sure to add this line in your class for testing purposes

      var result = await nip05.checkNip05('username@url', 'pubkey');

      expect(result['valid'], true);
    });
  });

  // mockito not working
  // group('mockito test', () {
  //   test('returns a Map if the http call completes successfully', () async {
  //     final client = MockClient();

  //     when(client.get(
  //       Uri.parse('https://lox.de/.well-known/nostr.json?name=username'),
  //     )).thenAnswer(
  //       (_) => Future.value(http.Response(
  //           '{"names": {"username": "pubkey"}, "relays": {"pubkey": ["relay1", "relay2"]}}',
  //           200)),
  //     );

  //     var response = await client.get(
  //         Uri.parse('https://lox.de/.well-known/nostr.json?name=username'));

  //     print(response
  //         .body); // prints {"names": {"username": "pubkey"}, "relays": {"pubkey": ["relay1", "relay2"]}}
  //   });
  // });

  group('working mock http', () {
    Future<http.Response> requestHandler(http.Request request) async {
      const apiResponse =
          '{"names": {"username": "pubkey"}, "relays": {"pubkey": ["relay1", "relay2"]}}';
      return http.Response(apiResponse, 200);
    }

    var mockHttpClient = MockClient(requestHandler);

    setUp(() {
      var mockHttpClient = MockClient(requestHandler);
    });

    test('test of mock http client', () async {
      var response = await mockHttpClient.get(
          Uri.parse('https://lox.de/.well-known/nostr.json?name=username'));
      print(response.body);
    });
  });
}
