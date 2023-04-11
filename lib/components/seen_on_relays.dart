import 'dart:developer';

import 'package:camelus/config/palette.dart';
import 'package:camelus/models/tweet.dart';
import 'package:camelus/services/nostr/relays/relay_tracker.dart';
import 'package:camelus/services/nostr/relays/relays_injector.dart';
import 'package:camelus/services/nostr/relays/relays_ranking.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class SeenOnRelaysPage extends StatefulWidget {
  Tweet tweet;
  late RelaysRanking _relaysRanking;
  late RelayTracker _relayTracker;
  SeenOnRelaysPage({Key? key, required this.tweet}) : super(key: key) {
    RelaysInjector injector = RelaysInjector();
    _relaysRanking = injector.relaysRanking;
    _relayTracker = injector.relayTracker;
  }

  @override
  State<SeenOnRelaysPage> createState() => _SeenOnRelaysPageState();
}

class _SeenOnRelaysPageState extends State<SeenOnRelaysPage> {
  @override
  void initState() {
    log(widget.tweet.relayHints.toString());
    super.initState();
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
              children: [
                const SizedBox(height: 20),
                const Text('this event was seen on',
                    style: TextStyle(color: Palette.lightGray, fontSize: 20)),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.tweet.relayHints.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        widget.tweet.relayHints.keys.elementAt(index),
                        style: const TextStyle(
                            color: Palette.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                          _timeago(widget.tweet.relayHints.values
                              .elementAt(index)['lastFetched']),
                          style: const TextStyle(color: Palette.white)),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text('author gossip hints',
                    style: TextStyle(color: Palette.lightGray, fontSize: 20)),
                FutureBuilder<List>(
                  future: widget._relaysRanking
                      .getBestRelays(widget.tweet.pubkey, Direction.read),
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
                  height: 20,
                ),
                const Text('recorded data',
                    style: TextStyle(color: Palette.lightGray, fontSize: 20)),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount:
                      widget._relayTracker.tracker[widget.tweet.pubkey]?.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                        title: Text(
                          widget._relayTracker.tracker[widget.tweet.pubkey]
                                  ?.keys
                                  .elementAt(index) ??
                              "not found",
                          style: const TextStyle(
                              color: Palette.white,
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget._relayTracker
                                    .tracker[widget.tweet.pubkey]?.values
                                    .elementAt(index)['lastSuggestedKind3'] !=
                                null)
                              Text(
                                  "lastSuggestedKind3: ${_timeago(widget._relayTracker.tracker[widget.tweet.pubkey]?.values.elementAt(index)['lastSuggestedKind3'])}",
                                  style: const TextStyle(color: Palette.white)),
                            if (widget._relayTracker
                                    .tracker[widget.tweet.pubkey]?.values
                                    .elementAt(index)['lastSuggestedNip05'] !=
                                null)
                              Text(
                                  "lastSuggestedNip05: ${_timeago(widget._relayTracker.tracker[widget.tweet.pubkey]?.values.elementAt(index)['lastSuggestedNip05'])}",
                                  style: const TextStyle(color: Palette.white)),
                            if (widget._relayTracker
                                    .tracker[widget.tweet.pubkey]?.values
                                    .elementAt(index)['lastSuggestedBytag'] !=
                                null)
                              Text(
                                  "lastSuggestedBytag: ${_timeago(widget._relayTracker.tracker[widget.tweet.pubkey]?.values.elementAt(index)['lastSuggestedBytag'])}",
                                  style: const TextStyle(color: Palette.white)),
                            if (widget._relayTracker
                                    .tracker[widget.tweet.pubkey]?.values
                                    .elementAt(index)['lastFetched'] !=
                                null)
                              Text(
                                  "lastFetched: ${_timeago(widget._relayTracker.tracker[widget.tweet.pubkey]?.values.elementAt(index)['lastFetched'])}",
                                  style: const TextStyle(color: Palette.white)),
                          ],
                        ));
                  },
                ),
              ],
            ),
          ),
        ));
  }
}
