import 'package:camelus/config/palette.dart';
import 'package:camelus/providers/nostr_service_provider.dart';
import 'package:camelus/routes/nostr/nostr_page/user_feed_original_view.dart';
import 'package:camelus/services/nostr/nostr_service.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:matomo_tracker/matomo_tracker.dart';

class PerspectiveFeedPage extends ConsumerStatefulWidget {
  late String pubkey;

  PerspectiveFeedPage({Key? key, required this.pubkey}) : super(key: key);

  @override
  ConsumerState<PerspectiveFeedPage> createState() =>
      _PerspectiveFeedPageState();
}

class _PerspectiveFeedPageState extends ConsumerState<PerspectiveFeedPage>
    with TraceableClientMixin {
  late NostrService _nostrService;
  @override
  String get traceName => 'Created PerspectiveFeedPage'; // optional

  @override
  String get traceTitle => "perspective_feed_page";

  void _initNostrService() {
    _nostrService = ref.read(nostrServiceProvider);
  }

  @override
  void initState() {
    super.initState();
    _initNostrService();
    //clear user feed cache
    _nostrService.clearCache();
    _nostrService.userFeedObj.feed = [];
  }

  @override
  void dispose() {
    _nostrService.clearCache();
    _nostrService.userFeedObj.feed = [];
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder(
          future: _nostrService.getUserMetadata(widget.pubkey),
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
