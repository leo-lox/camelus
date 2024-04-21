import 'dart:async';

import 'package:camelus/data_layer/models/nostr_request_query.dart';
import 'package:camelus/data_layer/models/nostr_request_close.dart';
import 'package:camelus/services/nostr/relays/my_relay.dart';

class RelaySubscriptionHolder {
  final NostrRequestQuery _request;
  final List<MyRelay> _relays = [];

  final List<Map> _EOSEvents = [];
  final List<StreamSubscription> _subscriptions = [];

  RelaySubscriptionHolder({required NostrRequestQuery request})
      : _request = request;

  String get subscriptionId => _request.subscriptionId;

  void addRelay(MyRelay relay) {
    _relays.add(relay);
    //todo listen to relay eos stream
    _subscriptions.add(
      relay.eoseStream.listen((event) {
        var now = DateTime.now().millisecondsSinceEpoch / 1000;
        _EOSEvents.add({
          'subscriptionId': subscriptionId,
          'relayUrl': relay.relayUrl,
          'receivedAt': now,
          'event': event,
        });
      }),
    );
  }

  void addRelays(List<MyRelay> relays) {
    for (var element in relays) {
      addRelay(element);
    }
  }

  void removeRelay(MyRelay relay) {
    _relays.remove(relay);
  }

  /// closes the subscription in the sockets
  void close() {
    _closeAllSubscriptions();
    NostrRequestClose closeRequest = NostrRequestClose(
      subscriptionId: subscriptionId,
    );
    for (var element in _relays) {
      element.request(closeRequest);
    }
    _EOSEvents.clear();
  }

  void _closeAllSubscriptions() {
    for (var element in _subscriptions) {
      element.cancel();
    }
  }
}
