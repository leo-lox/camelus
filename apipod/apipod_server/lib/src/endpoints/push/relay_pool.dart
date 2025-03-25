import 'dart:async';
import 'package:ndk/ndk.dart' as ndk;

import 'relay.dart';

/// Manages a pool of Nostr relay connections
class RelayPool {
  /// List of active relay connections
  final List<Relay> _relays = [];

  /// Configuration options
  final RelayOptions _options;

  /// Stream controllers for aggregated events
  final _openController = StreamController<Relay>.broadcast();
  final _closeController = StreamController<Relay>.broadcast();
  final _errorController = StreamController<RelayError>.broadcast();
  final _eventController = StreamController<RelayEvent>.broadcast();
  final _eoseController = StreamController<RelaySubscriptionEnd>.broadcast();
  final _noticeController = StreamController<RelayNotice>.broadcast();
  final _okController = StreamController<RelayOk>.broadcast();

  /// Public streams for events
  Stream<Relay> get onOpen => _openController.stream;
  Stream<Relay> get onClose => _closeController.stream;
  Stream<RelayError> get onError => _errorController.stream;
  Stream<RelayEvent> get onEvent => _eventController.stream;
  Stream<RelaySubscriptionEnd> get onEose => _eoseController.stream;
  Stream<RelayNotice> get onNotice => _noticeController.stream;
  Stream<RelayOk> get onOk => _okController.stream;

  /// Creates a new relay pool
  RelayPool(List<String> relayUrls, {RelayOptions? options})
      : _options = options ?? RelayOptions() {
    for (final url in relayUrls) {
      add(url);
    }
  }

  /// Adds a relay to the pool
  bool add(String relayUrl) {
    if (has(relayUrl)) {
      return false;
    }

    final relay = Relay(relayUrl, options: _options);
    _relays.add(relay);

    // Forward events from this relay to the pool's streams
    relay.onOpen.listen((r) => _openController.add(r));
    relay.onClose.listen((_) => _closeController.add(relay));
    relay.onError.listen((e) => _errorController.add(RelayError(relay, e)));
    relay.onEvent.listen((e) => _eventController.add(RelayEvent(relay, e)));
    relay.onEose
        .listen((s) => _eoseController.add(RelaySubscriptionEnd(relay, s)));
    relay.onNotice.listen((n) => _noticeController.add(RelayNotice(relay, n)));
    relay.onOk.listen((o) => _okController.add(RelayOk(relay, o)));

    return true;
  }

  /// Checks if a relay URL is already in the pool
  bool has(String relayUrl) {
    return _relays.any((relay) => relay.url == relayUrl);
  }

  /// Removes a relay from the pool
  bool remove(String relayUrl) {
    final index = _relays.indexWhere((relay) => relay.url == relayUrl);
    if (index >= 0) {
      _relays[index].close();
      _relays.removeAt(index);
      return true;
    }
    return false;
  }

  /// Subscribes to events on all relays
  void subscribe(String subId, dynamic filters, {List<String>? relayUrls}) {
    final targetRelays = relayUrls != null
        ? _relays.where((r) => relayUrls.contains(r.url)).toList()
        : _relays;

    for (final relay in targetRelays) {
      relay.subscribe(subId, filters);
    }
  }

  /// Unsubscribes from events on all relays
  void unsubscribe(String subId, {List<String>? relayUrls}) {
    final targetRelays = relayUrls != null
        ? _relays.where((r) => relayUrls.contains(r.url)).toList()
        : _relays;

    for (final relay in targetRelays) {
      relay.unsubscribe(subId);
    }
  }

  /// Closes all relay connections
  void close() {
    for (final relay in _relays) {
      relay.close();
    }

    _relays.clear();

    // Close all stream controllers
    _openController.close();
    _closeController.close();
    _errorController.close();
    _eventController.close();
    _eoseController.close();
    _noticeController.close();
    _okController.close();
  }
}

/// Represents an event from a specific relay
class RelayEvent {
  final Relay relay;
  final ndk.Nip01Event event;

  RelayEvent(this.relay, this.event);
}

/// Represents an error from a specific relay
class RelayError {
  final Relay relay;
  final dynamic error;

  RelayError(this.relay, this.error);
}

/// Represents a subscription end from a specific relay
class RelaySubscriptionEnd {
  final Relay relay;
  final String subscriptionId;

  RelaySubscriptionEnd(this.relay, this.subscriptionId);
}

/// Represents a notice from a specific relay
class RelayNotice {
  final Relay relay;
  final String message;

  RelayNotice(this.relay, this.message);
}

/// Represents an OK response from a specific relay
class RelayOk {
  final Relay relay;
  final List<dynamic> data;

  RelayOk(this.relay, this.data);
}
