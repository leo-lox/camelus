import 'package:camelus/config/palette.dart';
import 'package:camelus/routes/nostr/nostr_page/user_feed_original_view.dart';
import 'package:camelus/services/nostr/nostr_injector.dart';
import 'package:camelus/services/nostr/nostr_service.dart';
import 'package:flutter/material.dart';
import 'package:matomo_tracker/matomo_tracker.dart';

class PerspectiveFeedPage extends StatefulWidget {
  late String pubkey;
  late NostrService _nostrService;
  PerspectiveFeedPage({Key? key, required this.pubkey}) : super(key: key) {
    NostrServiceInjector injector = NostrServiceInjector();
    _nostrService = injector.nostrService;
  }

  @override
  State<PerspectiveFeedPage> createState() => _PerspectiveFeedPageState();
}

class _PerspectiveFeedPageState extends State<PerspectiveFeedPage>
    with TraceableClientMixin {
  @override
  String get traceName => 'Created PerspectiveFeedPage'; // optional

  @override
  String get traceTitle => "perspective_feed_page";

  @override
  void initState() {
    //clear user feed cache
    widget._nostrService.clearCache();
    widget._nostrService.userFeedObj.feed = [];

    super.initState();
  }

  @override
  void dispose() {
    widget._nostrService.clearCache();
    widget._nostrService.userFeedObj.feed = [];
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder(
          future: widget._nostrService.getUserMetadata(widget.pubkey),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              return Text("perspective of ${snapshot.data['name']}");
            } else {
              return Text("perspective of ${widget.pubkey}");
            }
          },
        ),
        backgroundColor: Palette.background,
      ),
      backgroundColor: Palette.background,
      body: UserFeedOriginalView(pubkey: widget.pubkey),
    );
  }
}
