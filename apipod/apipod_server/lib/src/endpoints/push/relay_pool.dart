import 'relay.dart';

class RelayPool {
  Map<String, Function> onfn = {};
  List<Relay> relays = [];
  Map<String, dynamic> opts;

  RelayPool(List<String> relayUrls, [this.opts = const {}]) {
    for (final relay in relayUrls) {
      add(relay);
    }
  }

  void close() {
    for (final relay in relays) {
      relay.close();
    }
  }

  RelayPool on(String method, Function fn) {
    onfn[method] = fn;
    for (final relay in relays) {
      relay.onfn[method] = (dynamic arg1, [dynamic arg2]) {
        return fn(relay, arg1, arg2);
      };
    }
    return this;
  }

  bool has(String relayUrl) {
    for (final relay in relays) {
      if (relay.url == relayUrl) {
        return true;
      }
    }
    return false;
  }

  void send(List<dynamic> payload, [List<String>? relayIds]) {
    final targetRelays = relayIds != null ? findRelays(relayIds) : relays;
    for (final relay in targetRelays) {
      relay.send(payload);
    }
  }

  void setupHandlers() {
    // Set up message handlers with the ones we have already
    final keys = onfn.keys.toList();
    for (final handler in keys) {
      for (final relay in relays) {
        relay.onfn[handler] = (dynamic arg1, [dynamic arg2]) {
          return onfn[handler]!(relay, arg1, arg2);
        };
      }
    }
  }

  bool remove(String url) {
    for (int i = 0; i < relays.length; i++) {
      if (relays[i].url == url) {
        relays[i].close();
        relays.removeAt(i);
        return true;
      }
    }
    return false;
  }

  void subscribe(String subId, dynamic filters, [List<String>? relayIds]) {
    final targetRelays = relayIds != null ? findRelays(relayIds) : relays;
    for (final relay in targetRelays) {
      relay.subscribe(subId, filters);
    }
  }

  void unsubscribe(String subId, [List<String>? relayIds]) {
    final targetRelays = relayIds != null ? findRelays(relayIds) : relays;
    for (final relay in targetRelays) {
      relay.unsubscribe(subId);
    }
  }

  bool add(dynamic relay) {
    if (relay is Relay) {
      if (has(relay.url)) {
        return false;
      }

      relays.add(relay);
      setupHandlers();
      return true;
    }

    if (relay is String) {
      if (has(relay)) {
        return false;
      }

      final r = Relay(relay, opts);
      relays.add(r);
      setupHandlers();
      return true;
    }

    return false;
  }

  List<Relay> findRelays(List<dynamic> relayIds) {
    if (relayIds.isEmpty) {
      return [];
    }

    if (relayIds[0] is Relay) {
      return relayIds.cast<Relay>();
    }

    return relays
        .where((relay) => relayIds.any((rid) => relay.url == rid))
        .toList();
  }
}
