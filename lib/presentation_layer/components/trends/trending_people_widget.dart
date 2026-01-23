import 'dart:convert';
import 'dart:developer';

import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain_layer/entities/contact_list.dart';
import '../../../domain_layer/entities/nostr_band_people.dart';
import '../../providers/following_contact_state_provider.dart';
import '../../providers/nostr_band_provider.dart';
import '../../routes/nostr/profile/profile_page_2.dart';
import '../person_card.dart';

class TrendingPeopleWidget extends ConsumerWidget {
  final bool showFollowButton;
  final Function(bool, String) onFollowChange;

  const TrendingPeopleWidget({
    super.key,
    required this.onFollowChange,
    this.showFollowButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.trendingPeople,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _TrendingPeopleList(
            onFollowChange: onFollowChange,
            showFollowButton: showFollowButton,
          ),
        ],
      ),
    );
  }
}

class _TrendingPeopleList extends ConsumerWidget {
  final bool showFollowButton;
  final Function(bool, String) onFollowChange;

  const _TrendingPeopleList({
    required this.onFollowChange,
    required this.showFollowButton,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactList = ref.watch(contactListSelfStateProvider).contactList;
    final nostrBandAsync = ref.watch(
      nostrBandProvider.select((provider) => provider.getTrendingPeople()),
    );

    return FutureBuilder<NostrBandPeople?>(
      future: nostrBandAsync,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          log(snapshot.error.toString());
          return Text(
            AppLocalizations.of(context)!.somethingWentWrong,
            style: TextStyle(
              color: Theme.of(context).colorScheme.inverseSurface,
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return _buildPeopleList(
            context,
            snapshot.data!,
            10,
            contactList,
            showFollowButton,
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return Text(
            AppLocalizations.of(context)!.noConnection,
            style: TextStyle(
              color: Theme.of(context).colorScheme.inverseSurface,
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildPeopleList(
    BuildContext context,
    NostrBandPeople api,
    int limit,
    ContactList contactList,
    bool showFollowButton,
  ) {
    final profiles = api.profiles.take(limit).toList();

    return Column(
      children: profiles.map((profile) {
        try {
          final metadata = jsonDecode(profile.profile.content);
          return PersonCard(
            pubkey: profile.pubkey,
            name: metadata['name'] ?? '',
            pictureUrl: metadata['picture'] ?? '',
            about: metadata['about'] ?? '',
            nip05: metadata['nip05'],
            showFollowButton: showFollowButton,
            isFollowing: contactList.contacts.contains(profile.pubkey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage2(pubkey: profile.pubkey),
                ),
              );
            },
            onFollowTab: (followState) =>
                onFollowChange(followState, profile.pubkey),
          );
        } catch (e) {
          log('Error parsing profile metadata: $e');
          return const SizedBox.shrink();
        }
      }).toList(),
    );
  }
}
