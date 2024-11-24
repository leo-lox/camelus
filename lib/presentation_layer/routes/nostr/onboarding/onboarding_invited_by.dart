import 'package:camelus/presentation_layer/atoms/long_button.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/presentation_layer/atoms/my_profile_picture.dart';
import 'package:camelus/presentation_layer/providers/metadata_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain_layer/entities/nostr_list.dart';
import '../../../../domain_layer/entities/onboarding_user_info.dart';
import '../../../providers/nostr_lists_follow_state_provider.dart';

class OnboardingInvitedBy extends ConsumerStatefulWidget {
  Function nextCallback;
  OnboardingUserInfo userInfo;
  String invitedByPubkey;
  String inviteListName;

  OnboardingInvitedBy({
    super.key,
    required this.nextCallback,
    required this.userInfo,
    required this.invitedByPubkey,
    required this.inviteListName,
  });
  @override
  ConsumerState<OnboardingInvitedBy> createState() =>
      _OnboardingInvitedByState();
}

class _OnboardingInvitedByState extends ConsumerState<OnboardingInvitedBy> {
  NostrSet? _getInvitedSet(WidgetRef ref) {
    final inviteeLists =
        ref.watch(nostrListsFollowStateProvider(widget.invitedByPubkey));

    for (var set in inviteeLists.publicNostrFollowSets) {
      if (set.title == widget.inviteListName) {
        return set;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final inviteeLists =
        ref.watch(nostrListsFollowStateProvider(widget.invitedByPubkey));

    final inviteeMetadata =
        ref.watch(metadataStateProvider(widget.invitedByPubkey));

    /// filter the invited set by the inviteListName
    final invitedSet = _getInvitedSet(ref);

    return Scaffold(
      backgroundColor: Palette.background,
      body: inviteeLists.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                // Header section (1/4 of the screen)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomCenter,
                      colors: [
                        Palette.primary.withOpacity(0.7),
                        Palette.primary,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: Text(
                          invitedSet?.title ?? '',
                          style: TextStyle(
                            color: Palette.extraLightGray,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          UserImage(
                            imageUrl: inviteeMetadata.userMetadata?.picture,
                            pubkey: widget.invitedByPubkey,
                            size: 30,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text.rich(
                                overflow: TextOverflow.ellipsis,
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: inviteeMetadata.userMetadata?.name,
                                      style: TextStyle(
                                        color: Palette.extraLightGray,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' invited you to join',
                                      style: TextStyle(
                                        color: Palette.extraLightGray,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (invitedSet != null)
                  const Text(
                    "You'll follow these people right away",
                    style: TextStyle(
                      color: Palette.extraLightGray,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 10),
                if (invitedSet == null)
                  Expanded(
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("👀 no starter pack found "),
                          SizedBox(height: 10),
                          Text("no worries, you can still join Camelus!"),
                        ],
                      ),
                    ),
                  ),
                if (invitedSet != null)
                  Expanded(
                    child: ListView.builder(
                      itemCount: invitedSet
                          .elements.length, // Adjust based on your data
                      itemBuilder: (context, index) {
                        final displayPubkey = invitedSet.elements[index].value;

                        final displayMetadata = ref
                            .watch(metadataStateProvider(displayPubkey))
                            .userMetadata;
                        return ListTile(
                          onTap: () {
                            // Toggle selection
                            //setState(() {
                            //  if (wselectedPubkeys.contains(displayPubkey)) {
                            //    selectedPubkeys.remove(displayPubkey);
                            //  } else {
                            //    selectedPubkeys.add(displayPubkey);
                            //  }
                            //});
                          },
                          title: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              UserImage(
                                imageUrl: displayMetadata?.picture,
                                pubkey: displayPubkey,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayMetadata?.name ?? "",
                                      style: const TextStyle(
                                        color: Palette.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      displayMetadata?.about ?? "",
                                      style: const TextStyle(
                                        color: Palette.gray,
                                        fontSize: 12,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                // Bottom buttons section
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 400,
                        height: 40,
                        child: longButton(
                          name: "Join Camelus",
                          onPressed: () {
                            widget.nextCallback();
                          },
                          inverted: true,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        width: 400,
                        height: 40,
                        child: longButton(
                          name: "Signup without a starter pack",
                          onPressed: () {
                            // Add cancel functionality
                          },
                          inverted: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
