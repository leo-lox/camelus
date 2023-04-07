import 'dart:developer';

import 'package:camelus/config/palette.dart';
import 'package:camelus/models/tweet.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class SeenOnRelaysPage extends StatefulWidget {
  Tweet tweet;
  SeenOnRelaysPage({Key? key, required this.tweet}) : super(key: key);

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
          child: ListView.builder(
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
        ));
  }
}
