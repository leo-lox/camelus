import 'dart:async';
import 'dart:io';

class SocketControl {
  WebSocket socket;
  String id;
  String connectionUrl;
  Map<String, dynamic> requestInFlight = {};
  Map<String, Completer> completers = {};
  Map<String, StreamController> streamControllers = {};
  Map<String, Map> additionalData = {};
  SocketControl(this.socket, this.id, this.connectionUrl);
}
