import 'dart:async';
import 'dart:developer';

import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

class EventViewPage extends ConsumerStatefulWidget {
  final String rootId;
  final String? scrollIntoView;

  const EventViewPage({Key? key, required this.rootId, this.scrollIntoView})
      : super(key: key);

  @override
  _EventViewPageState createState() => _EventViewPageState();
}

class _EventViewPageState extends ConsumerState<EventViewPage> {
  @override
  void initState() {
    super.initState();
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
              "event view ROOT: ${widget.rootId} \n\n REPLY: ${widget.scrollIntoView}}"),
        ));
  }
}
