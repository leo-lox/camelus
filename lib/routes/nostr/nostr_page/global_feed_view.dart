import 'dart:async';
import 'dart:developer';

import 'package:camelus/components/tweet_card.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/models/tweet.dart';
import 'package:camelus/providers/nostr_service_provider.dart';
import 'package:camelus/scroll_controller/retainable_scroll_controller.dart';
import 'package:camelus/services/nostr/nostr_injector.dart';
import 'package:camelus/services/nostr/nostr_service.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GlobalFeedView extends ConsumerStatefulWidget {
  GlobalFeedView({Key? key}) : super(key: key);

  @override
  ConsumerState<GlobalFeedView> createState() => _GlobalFeedViewState();
}

class _GlobalFeedViewState extends ConsumerState<GlobalFeedView> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("testing ground"),
    );
  }
}
