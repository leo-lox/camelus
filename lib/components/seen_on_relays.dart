import 'dart:developer';

import 'package:camelus/config/palette.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/providers/database_provider.dart';
import 'package:camelus/services/nostr/relays/relay_tracker.dart';

import 'package:camelus/services/nostr/relays/relays_ranking.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

class SeenOnRelaysPage extends ConsumerStatefulWidget {
  NostrNote myNote;

  SeenOnRelaysPage({Key? key, required this.myNote}) : super(key: key) {}

  @override
  ConsumerState<SeenOnRelaysPage> createState() => _SeenOnRelaysPageState();
}

class _SeenOnRelaysPageState extends ConsumerState<SeenOnRelaysPage> {
  late RelaysRanking _relaysRanking;
  late RelayTracker _relayTracker;

  void _initServices() async {
    var db = await ref.watch(databaseProvider.future);
    _relaysRanking = RelaysRanking(db: db);
    _relayTracker = RelayTracker(db: db);
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
                const Text('event seen on',
                    style: TextStyle(color: Palette.white, fontSize: 35)),
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
                const SizedBox(height: 25),
                const Text('author gossip hints',
                    style: TextStyle(color: Palette.white, fontSize: 35)),
                FutureBuilder<List>(
                  future: _relaysRanking.getBestRelays(
                      widget.myNote.pubkey, Direction.read),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                              snapshot.data![index]['relay'],
                              style: const TextStyle(
                                  color: Palette.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                                "score: ${snapshot.data![index]['score'].toString()}",
                                style: const TextStyle(color: Palette.white)),
                          );
                        },
                      );
                    } else {
                      return const Text("Loading...");
                    }
                  },
                ),
                const SizedBox(
                  height: 25,
                ),
                const Text('recorded data',
                    style: TextStyle(color: Palette.white, fontSize: 35)),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 0,
                  itemBuilder: (context, index) {
                    // todo: implement this
                    return null;
                    // return ListTile(
                    //     title: Text(
                    //       widget._relayTracker.tracker[widget.myNote.pubkey]
                    //               ?.keys
                    //               .elementAt(index) ??
                    //           "not found",
                    //       style: const TextStyle(
                    //           color: Palette.white,
                    //           fontWeight: FontWeight.bold),
                    //     ),
                    //     subtitle: Column(
                    //       crossAxisAlignment: CrossAxisAlignment.start,
                    //       children: [
                    //         if (widget._relayTracker
                    //                 .tracker[widget.myNote.pubkey]?.values
                    //                 .elementAt(index)['lastSuggestedKind3'] !=
                    //             null)
                    //           Text(
                    //               "lastSuggestedKind3: ${_timeago(widget._relayTracker.tracker[widget.myNote.pubkey]?.values.elementAt(index)['lastSuggestedKind3'])}",
                    //               style: const TextStyle(color: Palette.white)),
                    //         if (widget._relayTracker
                    //                 .tracker[widget.myNote.pubkey]?.values
                    //                 .elementAt(index)['lastSuggestedNip05'] !=
                    //             null)
                    //           Text(
                    //               "lastSuggestedNip05: ${_timeago(widget._relayTracker.tracker[widget.myNote.pubkey]?.values.elementAt(index)['lastSuggestedNip05'])}",
                    //               style: const TextStyle(color: Palette.white)),
                    //         if (widget._relayTracker
                    //                 .tracker[widget.myNote.pubkey]?.values
                    //                 .elementAt(index)['lastSuggestedBytag'] !=
                    //             null)
                    //           Text(
                    //               "lastSuggestedBytag: ${_timeago(widget._relayTracker.tracker[widget.myNote.pubkey]?.values.elementAt(index)['lastSuggestedBytag'])}",
                    //               style: const TextStyle(color: Palette.white)),
                    //         if (widget._relayTracker
                    //                 .tracker[widget.myNote.pubkey]?.values
                    //                 .elementAt(index)['lastFetched'] !=
                    //             null)
                    //           Text(
                    //               "lastFetched: ${_timeago(widget._relayTracker.tracker[widget.myNote.pubkey]?.values.elementAt(index)['lastFetched'])}",
                    //               style: const TextStyle(color: Palette.white)),
                    //       ],
                    //     ));
                  },
                ),
              ],
            ),
          ),
        ));
  }
}
