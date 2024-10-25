import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../domain_layer/entities/mem_file.dart';

class NostrBuildFileUpload {
  Future<String> uploadImage(MemFile file) async {
    final uri = Uri.parse('https://nostr.build/upload.php');
    var request = http.MultipartRequest('POST', uri);

    final httpImage = http.MultipartFile.fromBytes(
      "fileToUpload",
      file.bytes,
      contentType: MediaType.parse(file.mimeType),
      filename: file.name,
    );
    request.files.add(httpImage);

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception("Error uploading image, status ${response.statusCode}");
    }

    var responseString = await response.stream.transform(utf8.decoder).join();

    // extract url https://image.nostr.build/random00values.jpg
    final RegExp urlPattern =
        RegExp(r'https:\/\/image\.nostr\.build\S+\.(?:jpg|jpeg|png|gif)');
    final Match? urlMatch = urlPattern.firstMatch(responseString);
    if (urlMatch != null) {
      final String myUrl = urlMatch.group(0)!;
      return myUrl;
    } else {
      throw Exception("No url found in response");
    }
  }
}
