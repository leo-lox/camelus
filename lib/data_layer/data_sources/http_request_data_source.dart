import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class HttpRequestDataSource {
  final http.Client _client;

  HttpRequestDataSource(this._client);

  Future<Map<String, dynamic>> jsonRequest(String url) async {
    http.Response response = await _client.get(
      Uri.parse(url),
      headers: {"Accept": "application/json"},
    );

    if (response.statusCode != 200) {
      return throw Exception(
        "error fetching STATUS: ${response.statusCode}, Link: $url",
      );
    }
    return jsonDecode(response.body);
  }

  Future<String> getRequest(String url) async {
    http.Response response = await _client.get(Uri.parse(url));

    if (response.statusCode != 200) {
      return throw Exception(
        "error fetching STATUS: ${response.statusCode}, Link: $url",
      );
    }
    return response.body;
  }

  Future<Uint8List> getBytes(String url) async {
    http.Response response = await _client.get(Uri.parse(url));

    if (response.statusCode != 200) {
      return throw Exception(
        "error fetching STATUS: ${response.statusCode}, Link: $url",
      );
    }
    return response.bodyBytes;
  }

  Future<http.Response> postRequest(
    String url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return await _client.post(Uri.parse(url), headers: headers, body: body);
  }
}
