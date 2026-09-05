import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../map_state_notifier.dart';

class MapSearchBar extends ConsumerWidget {
  final TextEditingController controller;

  const MapSearchBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapStateProvider);

    return Material(
      elevation: 4,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(28),
      color: Theme.of(context).colorScheme.surface,
      child: TextField(
        controller: controller,
        onChanged: ref.read(mapStateProvider.notifier).setQuery,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search destination...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: state.isSearching
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    ref.read(mapStateProvider.notifier).setQuery('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
