import 'dart:developer';

import 'package:camelus/l10n/app_localizations.dart';
import 'package:apipod_client/apipod_client.dart' as api_pod;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../atoms/hashtag_card.dart';
import '../../providers/trends_provider.dart';

class TrendingHashtagsWidget extends ConsumerWidget {
  final bool showHeading;
  const TrendingHashtagsWidget({super.key, this.showHeading = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendsAsync = ref.watch(trendsProvider);

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
          trendsAsync.when(
            data: (data) {
              if (!data.success) {
                log(data.error ?? 'trends endpoint returned success=false');
                return Text(
                  AppLocalizations.of(context)!.somethingWentWrong,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inverseSurface,
                  ),
                );
              }

              if (data.top.isEmpty) {
                return Text(
                  AppLocalizations.of(context)!.noConnection,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inverseSurface,
                  ),
                );
              }

              return _buildHashtagsList(context, data, 10);
            },
            error: (error, stackTrace) {
              log(error.toString());
              return Text(
                AppLocalizations.of(context)!.somethingWentWrong,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inverseSurface,
                ),
              );
            },
            loading: () => Column(
              children: List.generate(10, (i) => const HashtagCardSkeleton()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHashtagsList(
    BuildContext context,
    api_pod.TrendsResponse response,
    int limit,
  ) {
    final hashtags = response.top;
    final displayLimit = limit > hashtags.length ? hashtags.length : limit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(displayLimit, (i) {
        final hashtag = hashtags[i];
        return HashtagCard(
          index: i,
          hashtag: hashtag.tag,
          postsCount: hashtag.count,
          onTap: (hashtag) {
            final encodedQuery = Uri.encodeQueryComponent("#$hashtag");
            context.push('/search/feed?q=$encodedQuery');
          },
        );
      }),
    );
  }
}
