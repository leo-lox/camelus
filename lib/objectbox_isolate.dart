import 'dart:isolate';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_objectbox/ndk_objectbox.dart';

/// inits the db in a isolate
Future<CacheManager> getDbWithIsolate() async {
  final rootToken = RootIsolateToken.instance;
  if (rootToken == null) {
    throw StateError(
        'Cannot get the root isolate token. This is required for plugins to work in background isolates.');
  }
  final dbIsolateManager = DbIsolateManager();
  await dbIsolateManager.start();

  DbObjectBox dbCacheManager = DbObjectBox(attach: true);
  await dbCacheManager.dbRdy;

  return dbCacheManager;
}

/// inits db on main thread
Future<CacheManager> getDbMainThread() async {
  DbObjectBox dbCacheManager = DbObjectBox(attach: false);
  await dbCacheManager.dbRdy;
  return dbCacheManager;
}

class DbIsolateData {
  final SendPort sendPort;
  final RootIsolateToken rootToken;

  DbIsolateData(this.sendPort, this.rootToken);
}

// This will be the entry point for your database isolate
void dbIsolateEntry(DbIsolateData data) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(data.rootToken);
  // Create a receive port for this isolate
  final receivePort = ReceivePort();

  // Send the send port to the main isolate
  data.sendPort.send(receivePort.sendPort);

  // Initialize the database (not attaching since this is the primary instance)
  final dbCacheManager = DbObjectBox(attach: false);
  await dbCacheManager.dbRdy;

  // Listen for messages from the main isolate
  receivePort.listen((message) {
    // Handle commands from main isolate
    if (message is Map) {
      if (message['command'] == 'close') {
        dbCacheManager.close();
        Isolate.exit();
      }
      // Add other command handlers as needed
    }
  });

  // Notify main isolate that DB is ready
  data.sendPort.send({'status': 'ready'});
}

// Class to manage the database isolate
class DbIsolateManager {
  static DbIsolateManager? _instance;
  Isolate? _dbIsolate;
  SendPort? _dbSendPort;
  final _receivePort = ReceivePort();
  final Completer _dbReadyCompleter = Completer();

  Future get dbReady => _dbReadyCompleter.future;

  factory DbIsolateManager() {
    _instance ??= DbIsolateManager._internal();
    return _instance!;
  }

  DbIsolateManager._internal();

  Future<void> start() async {
    if (_dbIsolate != null) return;

    final rootToken = RootIsolateToken.instance!;

    // Start the database isolate
    _dbIsolate = await Isolate.spawn(
      dbIsolateEntry,
      DbIsolateData(_receivePort.sendPort, rootToken),
    );

    // Set up communication with the isolate
    _receivePort.listen((message) {
      if (message is SendPort) {
        _dbSendPort = message;
      } else if (message is Map && message['status'] == 'ready') {
        if (!_dbReadyCompleter.isCompleted) {
          _dbReadyCompleter.complete();
        }
      }
    });

    // Wait for the database to be ready
    await dbReady;
  }

  void dispose() {
    if (_dbSendPort != null) {
      _dbSendPort!.send({'command': 'close'});
    }
    _receivePort.close();
    _dbIsolate = null;
  }
}
