import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'otso_sync_model.dart';

class OtsoSyncXmlModel implements OtsoSyncModelSource {
  int id;
  String url;
  double lat;
  double long;
  String priorityImg;
  String thisPriority;
  String location;
  String timestamp;
  String comments;
  List<String> media;

  OtsoSyncXmlModel({
    required this.id,
    required this.url,
    required this.lat,
    required this.long,
    required this.priorityImg,
    required this.thisPriority,
    required this.location,
    required this.timestamp,
    required this.comments,
    required this.media,
  });

  // Parse multiple map_data elements from a single string
  static List<OtsoSyncXmlModel> fromXmlChunk(String xmlChunk) {
    final regex = RegExp(r'<map_data>([\s\S]*?)</map_data>');
    final matches = regex.allMatches(xmlChunk);

    return matches.map((match) {
      final mapDataXml = '<map_data>${match.group(1)}</map_data>';
      return OtsoSyncXmlModel.fromXml(mapDataXml);
    }).toList();
  }

  static List<OtsoSyncModel> parse(String xmlChunk) {
    final data = fromXmlChunk(xmlChunk);
    return data.map((e) => e.toOtosSyncModel()).toList();
  }

  factory OtsoSyncXmlModel.fromXml(String xmlString) {
    String getValue(String tag) {
      final startTag = '<$tag>';
      final endTag = '</$tag>';
      final startIndex = xmlString.indexOf(startTag);
      final endIndex = xmlString.indexOf(endTag);
      if (startIndex != -1 && endIndex != -1) {
        return xmlString.substring(startIndex + startTag.length, endIndex);
      } else {
        return '';
      }
    }

    return OtsoSyncXmlModel(
      id: parseId(getValue('id')),
      url: getValue('url'),
      lat: double.parse(getValue('lat')),
      long: double.parse(getValue('long')),
      priorityImg: getValue('priorityimg'),
      thisPriority: getValue('thispriority'),
      location: getValue('location'),
      timestamp: getValue('timestamp'),
      comments: getValue('comments'),
      media: getValue('media').split(',').where((s) => s.isNotEmpty).toList(),
    );
  }

  // mixed string and number ids
  static int parseId(String unsafeId) {
    int? myid = int.tryParse(unsafeId);

    myid ??= numericHash(unsafeId);

    return myid;
  }

  static int numericHash(String input) {
    var bytes = utf8.encode(input);
    var digest = sha256.convert(bytes);

    // Convert hex to numeric
    String hexHash = digest.toString();

    String numericOnly = hexHash.replaceAll(RegExp(r'[^0-9]'), '');

    // cut length
    numericOnly = numericOnly.padLeft(10, '0').substring(0, 10);

    return int.parse(numericOnly);
  }

  @override
  String toString() {
    return '''
MapData(
  id: $id,
  url: $url,
  lat: $lat,
  long: $long,
  priorityImg: $priorityImg,
  thisPriority: $thisPriority,
  location: $location,
  timestamp: $timestamp,
  comments: $comments,
  media: $media
)''';
  }

  DateTime parseCustomDateTime(String dateTimeString) {
    try {
      // Custom parsing logic
      final parts = dateTimeString.split(' ');

      // Month mapping
      final monthMap = {
        'jan': 1,
        'feb': 2,
        'mar': 3,
        'apr': 4,
        'may': 5,
        'jun': 6,
        'jul': 7,
        'aug': 8,
        'sep': 9,
        'oct': 10,
        'nov': 11,
        'dec': 12
      };

      // Parse month
      final month = monthMap[parts[0].toLowerCase()];

      // Parse day
      final day = int.parse(parts[1].replaceAll(',', ''));

      // Parse year
      final year = int.parse(parts[2]);

      // Parse time
      final timeParts =
          parts[3].replaceAll('(', '').replaceAll(')', '').split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final second = int.parse(timeParts[2]);

      return DateTime(year, month!, day, hour, minute, second);
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  OtsoSyncModel toOtosSyncModel() {
    DateTime postCreatedAt = parseCustomDateTime(timestamp);
    final postCreatedAtEpoch = postCreatedAt.millisecondsSinceEpoch ~/ 1000;

    return OtsoSyncModel(
      id: id,
      source: "stopice",
      body: "$comments",
      createdAt: postCreatedAtEpoch,
      latitude: lat,
      longitude: long,
    );
  }
}
