import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/palette.dart';
import '../../../../domain_layer/entities/nostr_list.dart';
import '../../../../domain_layer/entities/onboarding_user_info.dart';
import '../../../atoms/long_button.dart';
import '../../../atoms/my_profile_picture.dart';
import '../../../providers/metadata_state_provider.dart';
import '../../../providers/nostr_lists_follow_state_provider.dart';

class OnboardingInvitedBy extends ConsumerStatefulWidget {
  final Function nextCallback;
  final OnboardingUserInfo userInfo;
  final String invitedByPubkey;
  final String listName;
  final String listPubkey;

  const OnboardingInvitedBy({
    super.key,
    required this.nextCallback,
    required this.userInfo,
    required this.invitedByPubkey,
    required this.listName,
    required this.listPubkey,
  });
  @override
  ConsumerState<OnboardingInvitedBy> createState() =>
      _OnboardingInvitedByState();
}

class _OnboardingInvitedByState extends ConsumerState<OnboardingInvitedBy> {
  onJoinWithStarterPack(NostrStarterPack? invitedSet) {
    if (invitedSet == null) {
      widget.nextCallback();
      return;
    }

    widget.userInfo.followPubkeys.addAll(
      invitedSet.elements.map((e) => e.value),
    );

    // remove duplicates
    widget.userInfo.followPubkeys = widget.userInfo.followPubkeys
        .toSet()
        .toList();
    widget.nextCallback();
  }

  NostrStarterPack? _getInvitedSet(WidgetRef ref) {
    final inviteeLists = ref.watch(
      nostrListsFollowStateProvider(widget.listPubkey),
    );

    for (final set in inviteeLists.publicNostrFollowSets) {
      if (set.name == widget.listName) {
        return set;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final inviteeLists = ref.watch(
      nostrListsFollowStateProvider(widget.invitedByPubkey),
    );

    final inviteeMetadata = ref.watch(
      metadataStateProvider(widget.invitedByPubkey),
    );

    /// filter the invited set by the inviteListName
    final invitedSet = _getInvitedSet(ref);

    return Scaffold(
      body: inviteeLists.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header section (1/4 of the screen)
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.7),
                        Theme.of(context).colorScheme.primary,
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
                            color: Paletter.getExtraLightGray(context),
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
                                        color: Paletter.getExtraLightGray(
                                          context,
                                        ),
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: AppLocalizations.of(
                                        context,
                                      )!.invitedYouToJoin,
                                      style: TextStyle(
                                        color: Paletter.getExtraLightGray(
                                          context,
                                        ),
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
                  Text(
                    AppLocalizations.of(context)!.youWillFollowThesePeople,
                    style: TextStyle(
                      color: Paletter.getExtraLightGray(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 10),
                if (invitedSet == null)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.noStarterPackFound,
                          ),
                          SizedBox(height: 10),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.noWorriesYouCanStillJoin,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (invitedSet != null)
                  Expanded(
                    child: ListView.builder(
                      itemCount: invitedSet
                          .elements
                          .length, // Adjust based on your data
                      itemBuilder: (context, index) {
                        final displayPubkey = invitedSet.elements[index].value;

                        final displayMetadata = ref
                            .watch(metadataStateProvider(displayPubkey))
                            .userMetadata;
                        return ListTile(
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
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      displayMetadata?.about ?? "",
                                      style: TextStyle(
                                        color: Paletter.getGray(context),
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
                      SizedBox(
                        width: 400,
                        height: 40,
                        child: longButton(
                          name: AppLocalizations.of(context)!.joinCamelus,
                          onPressed: () {
                            onJoinWithStarterPack(invitedSet);
                          },
                          inverted: true,
                        ),
                      ),
                      const SizedBox(height: 15),
                      if (invitedSet != null)
                        SizedBox(
                          width: 400,
                          height: 40,
                          child: longButton(
                            name: AppLocalizations.of(
                              context,
                            )!.signupWithoutStarterPack,
                            onPressed: () {
                              widget.nextCallback();
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
