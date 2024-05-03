import 'dart:convert';
import 'package:http/http.dart' as http;

class HttpRequestDataSource {
  final http.Client _client;

  HttpRequestDataSource(this._client);

  Future<Map<String, dynamic>> jsonRequest(String url) async {
    http.Response response = await _client
        .get(Uri.parse(url), headers: {"Accept": "application/json"});

    if (response.statusCode != 200) {
      return throw Exception(
          "error fetching nip05.json STATUS: ${response.statusCode}, Link: $url");
    }
    return jsonDecode(response.body);
  }
}
