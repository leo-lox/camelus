import 'dart:async';
import 'dart:io';

class SocketControl {
  late WebSocket socket;
  String id;
  String connectionUrl;
  Map<String, dynamic> requestInFlight = {};
  Map<String, Completer> completers = {};
  Map<String, StreamController> streamControllers = {};
  Map<String, Map> additionalData = {};
  bool socketIsRdy = false;
  bool socketIsFailing = false;
  int socketFailingAttempts = 0;
  int socketReceivedEventsCount = 0;
  SocketControl(this.id, this.connectionUrl);
}
