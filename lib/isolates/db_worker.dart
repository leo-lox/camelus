import 'dart:async';
import 'dart:isolate';

import 'package:camelus/data_layer/db/custom_inserts/db_note_stack_insert.dart';
import 'package:camelus/data_layer/db/entities/db_nip05.dart';
import 'package:camelus/data_layer/db/entities/db_note.dart';
import 'package:camelus/data_layer/db/entities/db_relay_tracker.dart';
import 'package:camelus/data_layer/db/entities/db_settings.dart';
import 'package:camelus/data_layer/db/entities/db_user_metadata.dart';
import 'package:camelus/data_layer/db/migrations/migrations.dart';
import 'package:camelus/domain/models/isolate_note_transport.dart';
import 'package:camelus/services/nostr/relays/relay_tracker.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

Future<SendPort> initIsolate() async {
  Completer<SendPort> completer = Completer<SendPort>();
  ReceivePort isolateToMainStream = ReceivePort();

  isolateToMainStream.listen((data) {
    if (data is SendPort) {
      SendPort mainToIsolateStream = data;

      completer.complete(mainToIsolateStream);
    } else {
      print('[isolateToMainStream] $data');
    }
  });

  RootIsolateToken rootToken = RootIsolateToken.instance!;
  Isolate myIsolateInstance =
      await Isolate.spawn(dbWorker, [isolateToMainStream.sendPort, rootToken]);

  return completer.future;
}

// this is the entry point for the isolate
void dbWorker(List initMsg) async {
  SendPort sendPort = initMsg[0];
  RootIsolateToken token = initMsg[1];

  BackgroundIsolateBinaryMessenger.ensureInitialized(token);

  final dir = await getApplicationDocumentsDirectory();
  final db = await Isar.open(
    directory: dir.path,
    [
      DbNoteSchema,
      DbNip05Schema,
      DbRelayTrackerSchema,
      DbSettingsSchema,
      DbUserMetadataSchema,
    ],
    inspector: false,
  );
  await performMigrationIfNeeded(db);

  final DbNoteStackInsert stackInsertNotes = DbNoteStackInsert(db: db);
  final RelayTracker relayTracker = RelayTracker(db: db);

  /// setup receivePort to listen for messages from main isolate
  var receivePort = ReceivePort();
  receivePort.listen((message) {
    if (message is IsolateNoteTransport) {
      stackInsertNotes.stackInsertNotes([message.note]);
      if (message.relayUrl != null) {
        relayTracker.analyzeNostrEvent(message.note, message.relayUrl!);
      }
    }
  });
  sendPort.send(receivePort.sendPort);

  ///
  ///

  sendPort.send("message from isolate!");
}
