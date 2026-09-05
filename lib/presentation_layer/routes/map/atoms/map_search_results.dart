import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain_layer/entities/map_place.dart';
import '../map_state_notifier.dart';

class MapSearchResults extends ConsumerWidget {
  final ValueChanged<MapPlace> onPlaceTap;

  const MapSearchResults({super.key, required this.onPlaceTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(
      mapStateProvider.select((s) => s.suggestions),
    );

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Material(
      elevation: 6,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: suggestions.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final place = suggestions[index];
            return ListTile(
              leading: Icon(
                Icons.location_on_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                place.name,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: place.address.isEmpty
                  ? null
                  : Text(
                      place.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              onTap: () => onPlaceTap(place),
            );
          },
        ),
      ),
    );
  }
}
