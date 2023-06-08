import 'package:camelus/atoms/long_button.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/providers/nostr_service_provider.dart';
import 'package:camelus/services/nostr/nostr_service.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class BlockPage extends ConsumerStatefulWidget {
  String? userPubkey;
  String? postId;

  BlockPage({Key? key, this.userPubkey, this.postId}) : super(key: key);

  @override
  ConsumerState<BlockPage> createState() => _BlockPageState();
}

class _BlockPageState extends ConsumerState<BlockPage> {
  late NostrService _nostrService;
  bool isUserBlocked = false;

  void _initNostrService() {
    _nostrService = ref.read(nostrServiceProvider);
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
        title: const Text('block/report'),
        backgroundColor: Palette.background,
      ),
      backgroundColor: Palette.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // block user
            Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('user',
                          style: TextStyle(
                              color: Palette.lightGray, fontSize: 20)),
                      const SizedBox(width: 10),
                      FutureBuilder<Map>(
                        future:
                            _nostrService.getUserMetadata(widget.userPubkey!),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              snapshot.data?['name'] ?? widget.userPubkey,
                              style: const TextStyle(
                                  color: Palette.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold),
                            );
                          }
                          return Container();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 40,
                    width: MediaQuery.of(context).size.width * 0.75,
                    child: longButton(
                        name: isUserBlocked ? "unblock" : "block",
                        onPressed: () {
                          if (isUserBlocked) {
                            _nostrService
                                .removeFromBlocklist(widget.userPubkey!);
                          } else {
                            _nostrService.addToBlocklist(widget.userPubkey!);
                          }
                          setState(() {
                            isUserBlocked = !isUserBlocked;
                          });
                        }),
                  ),
                  const SizedBox(height: 10),
                  // SizedBox(
                  //   height: 40,
                  //   width: MediaQuery.of(context).size.width * 0.75,
                  //   child: longButton(name: "report", onPressed: () => {}),
                  // ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
