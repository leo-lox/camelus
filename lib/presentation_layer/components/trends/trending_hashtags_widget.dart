import 'dart:developer';

import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain_layer/entities/nostr_band_hashtags.dart';
import '../../atoms/hashtag_card.dart';
import '../../providers/nostr_band_provider.dart';

class TrendingHashtagsWidget extends ConsumerWidget {
  final bool showHeading;
  const TrendingHashtagsWidget({super.key, this.showHeading = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nostrBandAsync = ref.watch(
      nostrBandProvider.select((provider) => provider.getTrendingHashtags()),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeading)
            Text(
              AppLocalizations.of(context)!.trendingHashtags,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 10),
          FutureBuilder<NostrBandHashtags?>(
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
                return _buildHashtagsList(context, snapshot.data!, 10);
              }

              if (snapshot.connectionState == ConnectionState.done) {
                return Text(
                  AppLocalizations.of(context)!.noConnection,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inverseSurface,
                  ),
                );
              }

              return Column(
                children: List.generate(10, (i) => const HashtagCardSkeleton()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHashtagsList(
    BuildContext context,
    NostrBandHashtags api,
    int limit,
  ) {
    final hashtags = api.hashtags;
    final displayLimit = limit > hashtags.length ? hashtags.length : limit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(displayLimit, (i) {
        final hashtag = hashtags[i];
        return HashtagCard(
          index: i,
          hashtag: hashtag.hashtag,
          postsCount: hashtag.posts,
          onTap: (hashtag) {
            final encodedQuery = Uri.encodeQueryComponent("#$hashtag");
            context.push('/search/feed?q=$encodedQuery');
          },
        );
      }),
    );
  }
}
