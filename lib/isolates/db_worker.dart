import 'dart:async';
import 'dart:isolate';

import 'package:camelus/db/custom_inserts/db_note_stack_insert.dart';
import 'package:camelus/db/entities/db_nip05.dart';
import 'package:camelus/db/entities/db_note.dart';
import 'package:camelus/db/entities/db_relay_tracker.dart';
import 'package:camelus/db/entities/db_settings.dart';
import 'package:camelus/db/entities/db_user_metadata.dart';
import 'package:camelus/helpers/bip340.dart';
import 'package:camelus/models/nostr_note.dart';
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

  DbNoteStackInsert stackInsertNotes = DbNoteStackInsert(db: db);
  Bip340 bip340 = Bip340();

  /// setup receivePort to listen for messages from main isolate
  var receivePort = ReceivePort();
  receivePort.listen((message) {
    if (message is NostrNote) {
      stackInsertNotes.stackInsertNotes([message]);
    }
  });
  sendPort.send(receivePort.sendPort);

  ///
  ///

  sendPort.send("message from isolate!");
}
