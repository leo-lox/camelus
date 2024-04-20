import 'dart:async';
import 'dart:developer';

import 'package:camelus/presentation_layer/atoms/spinner_center.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/data_layer/db/entities/db_relay_tracker.dart';
import 'package:camelus/domain/models/nostr_note.dart';
import 'package:camelus/providers/database_provider.dart';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:timeago/timeago.dart' as timeago;

class SeenOnRelaysPage extends ConsumerStatefulWidget {
  NostrNote myNote;

  SeenOnRelaysPage({super.key, required this.myNote});

  @override
  ConsumerState<SeenOnRelaysPage> createState() => _SeenOnRelaysPageState();
}

class _SeenOnRelaysPageState extends ConsumerState<SeenOnRelaysPage> {
  late final Isar db;

  Completer<DbRelayTracker?> relayTracker = Completer<DbRelayTracker?>();

  void _initServices() async {
    db = await ref.read(databaseProvider.future);
    _getRelayTracker(widget.myNote.pubkey);
  }

  @override
  void initState() {
    log(widget.myNote.relayHints.toString());
    super.initState();
    _initServices();
  }

  String _timeago(int time) {
    return timeago.format(DateTime.fromMillisecondsSinceEpoch(time * 1000));
  }

  Future<DbRelayTracker?> _getRelayTracker(String pubkey) async {
    final result =
        await db.dbRelayTrackers.filter().pubkeyEqualTo(pubkey).findFirst();
    relayTracker.complete(result);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Seen on relays'),
          backgroundColor: Palette.background,
        ),
        backgroundColor: Palette.background,
        body: Container(
          padding: const EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                if (widget.myNote.relayHints.isNotEmpty)
                  const Text('note relay hints',
                      style: TextStyle(color: Palette.white, fontSize: 25)),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.myNote.relayHints.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        widget.myNote.relayHints.elementAt(index),
                        style: const TextStyle(
                            color: Palette.white, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
                const SizedBox(
                  height: 25,
                ),
                const Text('user seen on these relays',
                    style: TextStyle(color: Palette.white, fontSize: 25)),
                const SizedBox(
                  height: 10,
                ),
                FutureBuilder<DbRelayTracker?>(
                    future: relayTracker.future,
                    initialData: null,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return spinnerCenter();
                      }
                      if (snapshot.data == null) {
                        return const Text('no data');
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: snapshot.data!.relays.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                              snapshot.data!.relays.elementAt(index).relayUrl!,
                              style: const TextStyle(
                                  color: Palette.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (snapshot.data!.relays
                                        .elementAt(index)
                                        .lastSuggestedKind3 !=
                                    null)
                                  Text(
                                    'last suggested kind3: ${_timeago(snapshot.data!.relays.elementAt(index).lastSuggestedKind3!)}',
                                    style:
                                        const TextStyle(color: Palette.white),
                                  ),
                                if (snapshot.data!.relays
                                        .elementAt(index)
                                        .lastSuggestedNip05 !=
                                    null)
                                  Text(
                                    'last suggested nip05: ${_timeago(snapshot.data!.relays.elementAt(index).lastSuggestedNip05!)}',
                                    style:
                                        const TextStyle(color: Palette.white),
                                  ),
                                if (snapshot.data!.relays
                                        .elementAt(index)
                                        .lastSuggestedTag !=
                                    null)
                                  Text(
                                    'last suggested tag: ${_timeago(snapshot.data!.relays.elementAt(index).lastSuggestedTag!)}',
                                    style:
                                        const TextStyle(color: Palette.white),
                                  ),
                                if (snapshot.data!.relays
                                        .elementAt(index)
                                        .lastFetched !=
                                    null)
                                  Text(
                                    'last fetched: ${_timeago(snapshot.data!.relays.elementAt(index).lastFetched!)}',
                                    style:
                                        const TextStyle(color: Palette.white),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    })
              ],
            ),
          ),
        ));
  }
}
