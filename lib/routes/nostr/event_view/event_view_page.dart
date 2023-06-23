import 'dart:async';
import 'dart:developer';

import 'package:camelus/config/palette.dart';
import 'package:camelus/db/database.dart';
import 'package:camelus/providers/database_provider.dart';
import 'package:camelus/services/nostr/feeds/event_feed.dart';
import 'package:camelus/services/nostr/relays/relays.dart';
import 'package:camelus/services/nostr/relays/relays_injector.dart';
import 'package:flutter/material.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

class EventViewPage extends ConsumerStatefulWidget {
  final String _rootId;
  final String? _scrollIntoView;
  final Relays _relays;

  EventViewPage({Key? key, required String rootId, String? scrollIntoView})
      : _scrollIntoView = scrollIntoView,
        _rootId = rootId,
        _relays = RelaysInjector().relays,
        super(key: key);

  @override
  _EventViewPageState createState() => _EventViewPageState();
}

class _EventViewPageState extends ConsumerState<EventViewPage> {
  late AppDatabase db;
  late EventFeed _eventFeed;

  final Completer<void> _servicesReady = Completer<void>();

  Future<void> _initDb() async {
    db = await ref.read(databaseProvider.future);
    return;
  }

  Future<void> _initSequence() async {
    await _initDb();

    _eventFeed = EventFeed(db, widget._rootId, widget._relays);
    await _eventFeed.feedRdy;
    _servicesReady.complete();
  }

  @override
  void initState() {
    super.initState();
    _initSequence();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Palette.background,
        appBar: AppBar(
          backgroundColor: Palette.background,
          title: const Text("thread"),
        ),
        body: Center(
          child: Text(
              "event view ROOT: ${widget._rootId} \n\n REPLY: ${widget._scrollIntoView}}"),
        ));
  }
}
