import 'package:camelus/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../atoms/long_button.dart';
import '../../../providers/metadata_state_provider.dart';
import '../../../providers/moderation/blocklist_provider.dart';
import '../../../providers/moderation/moderation_provider.dart';
import '../../../providers/ndk_provider.dart';

class BlockPage extends ConsumerStatefulWidget {
  final String userPubkey;
  final String? postId;

  const BlockPage({super.key, required this.userPubkey, this.postId});

  @override
  ConsumerState<BlockPage> createState() => _BlockPageState();
}

class _BlockPageState extends ConsumerState<BlockPage> {
  bool requestLoading = false;
  bool reportToCamelus = true;

  final TextEditingController _textController = TextEditingController();
  String _reportReason = "";
  bool _reportSuccessful = false;
  bool _reportLoading = false;

  List<String> getReportReasons(BuildContext context) {
    return [
      AppLocalizations.of(context)!.impersonation,
      AppLocalizations.of(context)!.spam,
      AppLocalizations.of(context)!.illegal,
      AppLocalizations.of(context)!.profanity,
      AppLocalizations.of(context)!.nudity,
      AppLocalizations.of(context)!.malware,
      AppLocalizations.of(context)!.other,
    ];
  }

  @override
  void initState() {
    super.initState();
  }

  void _blockUser(String pubkey) async {
    setState(() {
      requestLoading = true;
    });

    try {
      await ref.read(blocklistNotifierProvider.notifier).blockPubkey(pubkey);
    } finally {
      if (mounted) {
        setState(() {
          requestLoading = false;
        });
      }
    }
  }

  void _unblockUser(String pubkey) async {
    setState(() {
      requestLoading = true;
    });

    try {
      await ref.read(blocklistNotifierProvider.notifier).unblockPubkey(pubkey);
    } finally {
      if (mounted) {
        setState(() {
          requestLoading = false;
        });
      }
    }
  }

  void _setReportReason(String reason) {
    if (reason == _reportReason) {
      reason = "";
    }
    setState(() {
      _reportReason = reason;
    });
  }

  Future _submitReport() async {
    setState(() {
      _reportLoading = true;
    });
    final ndk = ref.read(ndkProvider);
    final myPubkey = ndk.accounts.getPublicKey();
    if (myPubkey == null) {
      throw Exception("cannot report without account");
    }

    final moderation = ref.read(moderationProvider);
    await moderation.report(
      pubkeySubmittingReport: myPubkey,
      reportReason: _reportReason,
      userReport: _textController.text,
      reportedPubkey: widget.userPubkey,
      postId: widget.postId,
      reportToCamelus: reportToCamelus,
    );

    setState(() {
      _reportLoading = false;
      _reportSuccessful = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref
        .watch(metadataStateProvider(widget.userPubkey))
        .userMetadata;
    final blocklistState = ref.watch(blocklistNotifierProvider);
    final isUserBlocked = blocklistState.blockedPubkeys.contains(
      widget.userPubkey,
    );

    if (_reportSuccessful) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 250),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!.reportSent,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context)!.thankYouForReport,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inverseSurface,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 40,
                    width: MediaQuery.of(context).size.width * 0.75,
                    child: longButton(
                      inverted: true,
                      name: AppLocalizations.of(context)!.goBack,
                      onPressed: () => {context.pop()},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.blockReportTitle),
      ),
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
                      Text(
                        AppLocalizations.of(context)!.user,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inverseSurface,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        user?.name ?? user?.nip05 ?? widget.userPubkey,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (blocklistState.isLoading)
                    SizedBox(
                      height: 40,
                      width: MediaQuery.of(context).size.width * 0.75,
                      child: longButton(
                        name: AppLocalizations.of(context)!.loading,
                        loading: true,
                        onPressed: () {},
                      ),
                    )
                  else
                    SizedBox(
                      height: 40,
                      width: MediaQuery.of(context).size.width * 0.75,
                      child: longButton(
                        name: isUserBlocked
                            ? AppLocalizations.of(context)!.unblock
                            : AppLocalizations.of(context)!.block,
                        inverted: !isUserBlocked,
                        loading: requestLoading,
                        onPressed: () {
                          if (isUserBlocked) {
                            _unblockUser(widget.userPubkey);
                          } else {
                            _blockUser(widget.userPubkey);
                          }
                        },
                      ),
                    ),
                  const SizedBox(height: 10),
                  Column(
                    children: [
                      const SizedBox(height: 100),

                      //text user input
                      GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 4.5 / 1,
                        shrinkWrap: true,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        children: getReportReasons(context)
                            .map(
                              (reason) => longButton(
                                name: reason,
                                onPressed: () => {_setReportReason(reason)},
                                inverted: _reportReason == reason,
                              ),
                            )
                            .toList(),
                      ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.90,
                        child: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: widget.postId != null
                                ? AppLocalizations.of(
                                    context,
                                  )!.whatIsWrongWithPost
                                : AppLocalizations.of(
                                    context,
                                  )!.whatIsWrongWithUser,
                            hintStyle: TextStyle(letterSpacing: 1.1),
                            filled: true,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                          ),
                          minLines: 3,
                          maxLines: 5,
                        ),
                      ),
                      const SizedBox(height: 30),

                      Text(
                        AppLocalizations.of(context)!.reportsAreSentToRelays,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inverseSurface,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.additionallyReportToCamelus,
                          ),
                          const SizedBox(width: 10),
                          Switch(
                            value: reportToCamelus,
                            onChanged: (value) {
                              setState(() {
                                reportToCamelus = value;
                              });
                            },
                            activeThumbColor: Theme.of(
                              context,
                            ).colorScheme.onSurface,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 40,
                        width: MediaQuery.of(context).size.width * 0.75,
                        child: longButton(
                          name: widget.postId != null
                              ? AppLocalizations.of(context)!.reportPost
                              : AppLocalizations.of(context)!.reportUser,
                          inverted: true,
                          loading: _reportLoading,
                          onPressed: () => {_submitReport()},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
