import 'dart:async';
import 'dart:convert';
import 'package:ndk/ndk.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../config/push_config.dart';

/// Represents a Nostr relay connection
class Relay {
  /// The WebSocket URL of the relay
  final String url;

  /// Configuration options
  final RelayOptions options;

  /// The WebSocket connection
  WebSocketChannel? _ws;

  /// Flag indicating if the connection was manually closed
  bool _manualClose = false;

  String? closeReason;

  /// Flag indicating if reconnection is in progress
  bool _reconnecting = false;

  int reconnectDelay = 100;
  int reconnectAttempts = 0;

  /// Stream controllers for different event types
  final _openController = StreamController<Relay>.broadcast();
  final _closeController = StreamController<void>.broadcast();
  final _errorController = StreamController<dynamic>.broadcast();
  final _eventController = StreamController<Nip01Event>.broadcast();
  final _eoseController = StreamController<String>.broadcast();
  final _noticeController = StreamController<String>.broadcast();
  final _okController = StreamController<List<dynamic>>.broadcast();

  /// Public streams for events
  Stream<Relay> get onOpen => _openController.stream;
  Stream<void> get onClose => _closeController.stream;
  Stream<dynamic> get onError => _errorController.stream;
  Stream<Nip01Event> get onEvent => _eventController.stream;
  Stream<String> get onEose => _eoseController.stream;
  Stream<String> get onNotice => _noticeController.stream;
  Stream<List<dynamic>> get onOk => _okController.stream;

  /// Creates a new relay connection
  Relay(this.url, {RelayOptions? options})
      : options = options ?? RelayOptions() {
    _initWebsocket();
  }

  /// Initializes the WebSocket connection
  Future<void> _initWebsocket() async {
    try {
      _ws = WebSocketChannel.connect(
        Uri.parse(url),
      );

      await _ws!.ready;

      //closeReason = null;

      _ws!.stream.listen(
        _handleMessage,
        onDone: () {
          closeReason = _ws!.closeReason;
          _handleClose();
        },
        onError: _handleError,
      );

      _ws!.ready.then((value) {
        // Emit open event
        _openController.add(this);
      });
    } catch (e) {
      _errorController.add(e);
      if (options.reconnect) {
        _scheduleReconnect();
      }
    }
  }

  /// Handles incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      if (data is List && data.length >= 2) {
        switch (data[0]) {
          case 'EVENT':
            if (data.length < 3) return;
            final event = Nip01EventModel.fromJson(data[2]);
            _eventController.add(event);
            break;
          case 'EOSE':
            _eoseController.add(data[1]);
            break;
          case 'NOTICE':
            if (data.length > 1) {
              _noticeController.add(data[1]);
            }
            break;
          case 'OK':
            if (data.length > 1) {
              _okController.add(data.sublist(1));
            }
            break;
        }
      }
    } catch (e) {
      print('Error handling message from $url: $e');
    }
  }

  /// Handles WebSocket close events
  void _handleClose() {
    _closeController.add(null);
    if (!_manualClose && options.reconnect) {
      _scheduleReconnect();
    }
  }

  /// Handles WebSocket error events
  void _handleError(dynamic error) {
    _errorController.add(error);
    if (!_manualClose && options.reconnect) {
      _scheduleReconnect();
    }
  }

  /// Schedules a reconnection attempt with exponential backoff
  void _scheduleReconnect() {
    if (_reconnecting) return;
    _reconnecting = true;

    Future.delayed(Duration(milliseconds: reconnectDelay), () async {
      try {
        await _initWebsocket();
        _reconnecting = false;
        reconnectDelay = 100; // reset reconnect delay
        reconnectAttempts = 0;
        _handleOpen();
      } catch (e) {
        reconnectDelay = (reconnectDelay * 1.5).toInt();
        reconnectAttempts = reconnectAttempts + 1;

        if (reconnectAttempts >= 10) {
          _errorController.add("to many reconnection attempts");
        }

        _scheduleReconnect();
      }
    });
  }

  /// Resubscribe after reconnect
  void _handleOpen() {
    subscribe(
      PushConfig.subscriptionId,
      PushConfig.subscriptionFilter,
    );
    print("Resubscribed to $url after reconnect");
  }

  /// Waits until the connection is established
  Future<void> waitUntilConnected() async {
    if (_manualClose || _ws == null) {
      return;
    }
  }

  /// Closes the connection
  void close() {
    _manualClose = true;
    if (_ws != null) {
      _ws!.sink.close();
    }

    // Close all stream controllers
    _openController.close();
    _closeController.close();
    _errorController.close();
    _eventController.close();
    _eoseController.close();
    _noticeController.close();
    _okController.close();
  }

  /// Subscribes to events matching the given filters
  Future<void> subscribe(String subId, dynamic filters) async {
    await waitUntilConnected();

    List<dynamic> request = ['REQ', subId];
    if (filters is List) {
      request.addAll(filters);
    } else {
      request.add(filters);
    }

    _send(request);
  }

  /// Unsubscribes from a subscription
  Future<void> unsubscribe(String subId) async {
    await waitUntilConnected();
    _send(['CLOSE', subId]);
  }

  /// Sends data to the relay
  void _send(List<dynamic> data) {
    if (_manualClose || _ws == null) {
      print('Cannot send to $url: connection closed');
      return;
    }

    _ws!.sink.add(jsonEncode(data));
  }
}

/// Configuration options for a relay connection
class RelayOptions {
  /// Whether to automatically reconnect on disconnection
  final bool reconnect;

  /// Creates a new options object
  const RelayOptions({this.reconnect = true});
}
