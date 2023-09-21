import 'package:camelus/atoms/long_button.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/db/entities/db_user_metadata.dart';
import 'package:camelus/providers/metadata_provider.dart';
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
  bool isUserBlocked = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var metadata = ref.watch(metadataProvider);
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
                      FutureBuilder<DbUserMetadata?>(
                        future:
                            metadata.getMetadataByPubkey(widget.userPubkey!),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              snapshot.data?.name ?? widget.userPubkey!,
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
                          //! todo: block user
                          // if (isUserBlocked) {
                          //   _nostrService
                          //       .removeFromBlocklist(widget.userPubkey!);
                          // } else {
                          //   _nostrService.addToBlocklist(widget.userPubkey!);
                          // }
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
