import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class Relay {
  final String url;
  final Map<String, dynamic> opts;
  WebSocketChannel? ws;
  bool manualClose = false;
  bool reconnecting = false;
  Map<String, Function> onfn = {};

  Relay(this.url, [this.opts = const {}]) {
    final options = Map<String, dynamic>.from(opts);
    if (options['reconnect'] == null) {
      options['reconnect'] = true;
    }

    initWebsocket().catchError((e) {
      if (onfn.containsKey('error')) {
        onfn['error']!(e);
      }
    });
  }

  Future<Relay> initWebsocket() async {
    try {
      final headers = {'User-Agent': 'Amethyst Push Server'};
      ws = WebSocketChannel.connect(Uri.parse(url));

      bool resolved = false;

      // Set up message handler
      ws!.stream.listen(
        (message) {
          handleNostrMessage(message);
          if (onfn.containsKey('message')) {
            onfn['message']!(message);
          }
        },
        onDone: () {
          if (onfn.containsKey('close')) {
            onfn['close']!(null);
          }
          if (reconnecting) return;
          if (!manualClose && opts['reconnect'] == true) {
            reconnect();
          }
        },
        onError: (e) {
          if (onfn.containsKey('error')) {
            onfn['error']!(e);
          }
          if (reconnecting) return;
          if (!manualClose && opts['reconnect'] == true) {
            reconnect();
          }
        },
      );

      // Trigger open event after connection is established
      if (onfn.containsKey('open')) {
        onfn['open']!(null);
      }

      return this;
    } catch (e) {
      if (onfn.containsKey('error')) {
        onfn['error']!(e);
      }
      rethrow;
    }
  }

  Future<void> waitConnected() async {
    int retry = 100000;
    while (true) {
      if (!manualClose && ws != null && ws!.sink is! WebSocketSink) {
        await Future.delayed(Duration(milliseconds: retry));
        retry = (retry * 1.5).toInt();
      } else {
        return;
      }
    }
  }

  Future<void> reconnect() async {
    reconnecting = true;
    int n = 100;

    try {
      await initWebsocket();
      reconnecting = false;
    } catch (e) {
      await Future.delayed(Duration(milliseconds: n));
      n = (n * 1.5).toInt();
      reconnect(); // Try again with exponential backoff
    }
  }

  Relay on(String method, Function fn) {
    onfn[method] = fn;
    return this;
  }

  void close() {
    manualClose = true;
    if (ws != null) {
      ws!.sink.close();
    }
  }

  void subscribe(String subId, dynamic filters) {
    if (filters is List) {
      send(['REQ', subId, ...filters]);
    } else {
      send(['REQ', subId, filters]);
    }
  }

  void unsubscribe(String subId) {
    send(['CLOSE', subId]);
  }

  Future<void> send(List<dynamic> data) async {
    await waitConnected();
    if (!manualClose && ws != null) {
      ws!.sink.add(jsonEncode(data));
    } else {
      print('WS not found while sending to $url');
    }
  }

  void handleNostrMessage(dynamic msg) {
    try {
      final data = jsonDecode(msg);
      if (data is List && data.length >= 2) {
        switch (data[0]) {
          case 'EVENT':
            if (data.length < 3) return;
            if (onfn.containsKey('event')) {
              onfn['event']!(data[1], data[2]);
            }
            break;
          case 'EOSE':
            if (onfn.containsKey('eose')) {
              onfn['eose']!(data[1]);
            }
            break;
          case 'NOTICE':
            if (onfn.containsKey('notice')) {
              Function.apply(onfn['notice']!, data.sublist(1));
            }
            break;
          case 'OK':
            if (onfn.containsKey('ok')) {
              Function.apply(onfn['ok']!, data.sublist(1));
            }
            break;
        }
      }
    } catch (e) {
      print('handleNostrMessage error: $url, $msg, $e');
    }
  }
}
