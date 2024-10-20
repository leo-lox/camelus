import 'package:camelus/config/palette.dart';
import 'package:camelus/domain_layer/usecases/get_user_metadata.dart';
import 'package:camelus/presentation_layer/providers/metadata_provider.dart';
import 'package:camelus/presentation_layer/routes/nostr/nostr_page/user_feed_original_view.dart';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:matomo_tracker/matomo_tracker.dart';

class PerspectiveFeedPage extends ConsumerStatefulWidget {
  final String pubkey;

  const PerspectiveFeedPage({super.key, required this.pubkey});

  @override
  ConsumerState<PerspectiveFeedPage> createState() =>
      _PerspectiveFeedPageState();
}

class _PerspectiveFeedPageState extends ConsumerState<PerspectiveFeedPage>
    with TraceableClientMixin {
  late GetUserMetadata _metadata;
  @override
  String get traceName => 'Created PerspectiveFeedPage'; // optional

  @override
  String get traceTitle => "perspective_feed_page";

  void _initNostrService() {
    _metadata = ref.read(metadataProvider);
  }

  @override
  void initState() {
    super.initState();
    _initNostrService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder(
          stream: _metadata.getMetadataByPubkey(widget.pubkey),
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
      body: UserFeedOriginalView(
        pubkey: widget.pubkey,
        scrollControllerFeed: ScrollController(),
      ),
    );
  }
}
