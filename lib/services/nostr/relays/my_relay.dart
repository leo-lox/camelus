import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:camelus/db/database.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/models/nostr_request.dart';
import 'package:camelus/models/nostr_request_query.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MyRelay {
  final AppDatabase database;
  final RelayPersistance persistance;
  final String relayUrl;
  final bool read;
  final bool write;
  final int createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  bool connected = false;
  int reconnectCount = 0;
  bool failing = false;

  late WebSocketChannel _channel;

  // stream
  final StreamController<Map> _eoseStreamController =
      StreamController<Map>.broadcast();

  Stream<Map> get eoseStream => _eoseStreamController.stream;

  MyRelay({
    required this.database,
    required this.persistance,
    required this.relayUrl,
    required this.read,
    required this.write,
  });

  Future<void> connect() async {
    final wssUrl = Uri.parse(relayUrl);
    WebSocketChannel channel = WebSocketChannel.connect(wssUrl);
    _channel = channel;
    await channel.ready;

    connected = true;
    _listen(channel);
    return;
  }

  _listen(WebSocketChannel channel) {
    channel.stream.listen((message) {
      _handleIncommingMessage(message);
    });
    channel.stream.handleError((error) {
      log(error);
      throw Exception("Error in socket");
    });
  }

  void request(NostrRequest request) {
    _write(_channel, request.toRawList());
  }

  _write(WebSocketChannel channel, dynamic data) {
    channel.sink.add(data);
  }

  Future<void> close() {
    return _close(_channel);
  }

  Future<void> _close(WebSocketChannel channel) {
    return channel.sink.close();
  }

  _handleIncommingMessage(dynamic message) async {
    log(message);
    var eventJson = json.decode(message);

    if (eventJson[0] == 'OK') {
      //nip 20 used to notify clients if an EVENT was successful
      log("OK: ${eventJson[1]}");
      return;
    }

    if (eventJson[0] == 'NOTICE') {
      log("NOTICE: ${eventJson[1]}");
      return;
    }
    if (eventJson[0] == 'EVENT') {
      var note = NostrNote.fromJson(eventJson);
      _insertNoteIntoDb(note);
      return;
    }
    if (eventJson[0] == 'EOSE') {
      log("EOSE: ${eventJson[1]}");
      _eoseStreamController.add(eventJson);
      return;
    }
    if (eventJson[0] == 'AUTH') {
      log("AUTH: ${eventJson[1]}");
      // nip 42 used to send authentication challenges
    }

    if (eventJson[0] == 'COUNT') {
      log("COUNT: ${eventJson[1]}");
      // nip 45 used to send requested event counts to clients
    }
  }

  _insertNoteIntoDb(NostrNote note) {
    database.noteDao.insertNostrNote(note).onError((error, stackTrace) => {
          // probably already in db
        });
  }

  @override
  String toString() {
    return "MyRelay: $relayUrl, read: $read, write: $write, persistance: $persistance";
  }
}

/// manual - added by user
/// gossip - added by gossip
/// tmp - used to query some events
enum RelayPersistance { manual, gossip, tmp }
