import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../config/palette.dart';
import '../../../../domain_layer/entities/nostr_list.dart';
import '../../../../domain_layer/entities/starter_pack_identifier.dart';
import '../../../atoms/long_button.dart';
import '../../../providers/ndk_provider.dart';
import '../../../providers/nostr_lists_follow_state_provider.dart';
import '../starter_pack_card.dart';
import 'edit_starter_pack_provider.dart';

class EditStarterPackSummary extends ConsumerStatefulWidget {
  final StarterPackIdentifier starterPackIdentifier;
  final Function onNext;
  const EditStarterPackSummary({
    super.key,
    required this.starterPackIdentifier,
    required this.onNext,
  });
  @override
  ConsumerState<EditStarterPackSummary> createState() =>
      _EditStarterPackSummaryState();
}

class _EditStarterPackSummaryState extends ConsumerState<EditStarterPackSummary>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<double> _shareContentFadeAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.5), // move up value
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));

    _titleFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _shareContentFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    ));
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final starterPackData =
        ref.watch(editStarterPackProvider(widget.starterPackIdentifier));
    final starterPackNotifier = ref
        .watch(editStarterPackProvider(widget.starterPackIdentifier).notifier);

    final ndk = ref.watch(ndkProvider);

    // trigger animations when broadcasted becomes true
    ref.listen(editStarterPackProvider(widget.starterPackIdentifier),
        (previous, next) {
      if (previous?.broadcasted == false && next.broadcasted == true) {
        _slideController.forward();
        _fadeController.forward();
      }
    });

    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final myNostrPack = NostrStarterPack(
      name: starterPackData.name,
      title: starterPackData.title,
      description: starterPackData.description,
      pubKey: ndk.accounts.getPublicKey()!,
      createdAt: now,
      image: starterPackData.imageUrl,
      elements: starterPackData.selectedUsers.map((userPubkey) {
        return NostrListElement(tag: "p", value: userPubkey, private: false);
      }).toList(),
    );

    return Scaffold(
      backgroundColor: Palette.background,
      body: Column(
        children: [
          Column(
            children: [],
          ),
          Expanded(
            child: ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height / 7,
                ),
                AnimatedBuilder(
                  animation: _titleFadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _titleFadeAnimation.value,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            Text(
                              "your starter pack",
                              style: const TextStyle(
                                fontSize: 30,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: StarterPackCard(
                      pack: myNostrPack,
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _shareContentFadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _shareContentFadeAnimation.value,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const Text(
                              "🎉 Your starter pack is live!",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Share it with your friends and help them discover amazing people!",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            if (starterPackData.shortLinkPart != null)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Palette.extraDarkGray,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Palette.gray),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'camelus.app/i/${starterPackData.shortLinkPart}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: longButton(
                                name: "share starter pack",
                                inverted: true,
                                disabled: false,
                                onPressed: () {
                                  SharePlus.instance.share(
                                    ShareParams(
                                      uri: Uri(
                                        scheme: 'https',
                                        host: 'camelus.app',
                                        path:
                                            '/i/${starterPackData.shortLinkPart}',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (!starterPackData.broadcasted)
            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: longButton(
                    name: "publish starter pack",
                    inverted: true,
                    disabled: starterPackData.selectedUsers.isEmpty,
                    loading: starterPackData.broadcasting,
                    onPressed: () {
                      starterPackNotifier.broadcast(myNostrPack);

                      widget.onNext();
                    },
                  ),
                ),
              ),
            ),
          if (starterPackData.broadcasted)
            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: longButton(
                    name: "close",
                    inverted: false,
                    onPressed: () {
                      starterPackNotifier.reset();
                      Navigator.pop(context);

                      ref.invalidate(
                        editStarterPackProvider(widget.starterPackIdentifier),
                      );

                      /// invalidate user starter pack lists so refresh is triggered
                      ref.invalidate(nostrListsFollowStateProvider(
                          widget.starterPackIdentifier.pubkey));
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
