import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:isolate';
import 'package:camelus/domain/models/isolate_note_transport.dart';
import 'package:camelus/domain/models/nostr_note.dart';
import 'package:camelus/domain/models/nostr_request.dart';
import 'package:camelus/domain/models/nostr_request_close.dart';
import 'package:camelus/domain/models/nostr_request_event.dart';
import 'package:camelus/domain/models/nostr_request_query.dart';
import 'package:camelus/services/nostr/metadata/block_mute_service.dart';
import 'package:isar/isar.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MyRelay {
  final Isar database;

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
  final StreamController<List> _eoseStreamController =
      StreamController<List>.broadcast();

  Stream<List> get eoseStream => _eoseStreamController.stream;

  final Map<String, Completer<String>> _completers = {};

  late SendPort dbWorkerSendPort;

  BlockMuteService blockMuteService;

  MyRelay(
      {required this.database,
      required this.persistance,
      required this.relayUrl,
      required this.read,
      required this.write,
      required this.blockMuteService,
      required this.dbWorkerSendPort});

  /// connects to the relay and listens for events
  Future<void> connect() async {
    final wssUrl = Uri.parse(relayUrl);
    WebSocketChannel channel = WebSocketChannel.connect(wssUrl);
    _channel = channel;

    channel.ready.catchError((error) {
      log(error.toString());
      //throw Exception("Error in socket");
      failing = true;
      return;
    });

    await channel.ready;

    connected = true;
    _listen(channel);
    log("connteected to relay: $relayUrl");
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

  /// sends a request to the relay
  /// if request is a query, it returns the subscriptionId when the server sends EOSE
  /// if request is an event, it returns the eventId when the server sends OK
  Future<String> request(NostrRequest request) {
    var requestJson = request.toRawList();
    _write(_channel, requestJson);

    return _buildCompleter(request);
  }

  Future<String> _buildCompleter(NostrRequest request) {
    var completer = Completer<String>();

    // returns EOSE with subscriptionId
    if (request is NostrRequestQuery) {
      if (_completers.containsKey(request.subscriptionId)) {
        try {
          _completers[request.subscriptionId]?.complete("closed by new query");
        } catch (e) {
          // probably already completed
        }
        // delete completer
        _completers.remove(request.subscriptionId);
      }

      _completers[request.subscriptionId] = completer;
    }

    // returns OK with event Id
    if (request is NostrRequestEvent) {
      _completers[request.body.id] = completer;
    }

    if (request is NostrRequestClose) {
      return Future.value("closed");
    }

    var future =
        completer.future.timeout(const Duration(seconds: 10), onTimeout: () {
      log("Rtimeout: ${request.subscriptionId}, $relayUrl");
      return "timeout";
    });
    return future;
  }

  _write(WebSocketChannel channel, dynamic data) {
    channel.sink.add(data);
  }

  /// closes the websocket
  Future<void> close() {
    return _close(_channel);
  }

  Future<void> _close(WebSocketChannel channel) {
    return channel.sink.close();
  }

  _handleIncommingMessage(dynamic message) async {
    List<dynamic> eventJson = json.decode(message);

    if (eventJson[0] == 'OK') {
      //nip 20 used to notify clients if an EVENT was successful
      log("OK: ${eventJson[1]}");

      // used for await on query
      _completers[eventJson[1]]?.complete(eventJson[1]);
      return;
    }

    if (eventJson[0] == 'NOTICE') {
      log("NOTICE: ${eventJson[1]}");
      return;
    }

    if (eventJson[0] == 'EVENT') {
      var note = NostrNote.fromJson(eventJson[2]);

      if (eventJson[1] == 'efeed-tmp-unresolvedLoop') {
        log("efeed-tmp-unresolvedLoop-WORKS: ${note.id}");
      }

      _insertNoteIntoDb(note, relayUrl);

      return;
    }
    if (eventJson[0] == 'EOSE') {
      log("EOSE: ${eventJson[1]}, $relayUrl");
      _eoseStreamController.add(eventJson);
      // used for await on query
      _completers[eventJson[1]]?.complete(eventJson[1]);
      return;
    }
    if (eventJson[0] == 'AUTH') {
      log("AUTH: ${eventJson[1]}");
      // nip 42 used to send authentication challenges
      return;
    }

    if (eventJson[0] == 'COUNT') {
      log("COUNT: ${eventJson[1]}");
      // nip 45 used to send requested event counts to clients
      return;
    }

    log("unknown event: $eventJson");
  }

  _insertNoteIntoDb(NostrNote note, String? relayUrl) async {
    if (blockMuteService.isPubkeyBlocked(note.pubkey)) {
      return;
    }

    final transport = IsolateNoteTransport(
      note: note,
      relayUrl: relayUrl,
    );

    // insert into db via isolate
    dbWorkerSendPort.send(transport);
  }

  @override
  String toString() {
    return "MyRelay: $relayUrl, read: $read, write: $write, persistance: $persistance";
  }
}

/// manual - added by user
/// gossip - added by gossip
/// tmp - used to query some events
enum RelayPersistance { manual, gossip, tmp, auto }
