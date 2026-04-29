import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../atoms/my_profile_picture.dart';
import '../atoms/nip_05_text.dart';
import '../providers/metadata_state_provider.dart';

class PersonSelect extends ConsumerWidget {
  final String pubkey;
  final bool selected;
  final Function onTab;
  final bool isReorderMode;
  final int? reorderIndex;

  const PersonSelect({
    super.key,
    required this.pubkey,
    required this.selected,
    required this.onTab,
    this.isReorderMode = false,
    this.reorderIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metadata = ref.watch(metadataStateProvider(pubkey)).userMetadata;
    return ListTile(
      onTap: isReorderMode ? null : () => onTab(),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserImage(imageUrl: metadata?.picture, pubkey: pubkey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metadata?.name ?? '',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Nip05Text(pubkey: pubkey, nip05verified: metadata?.nip05),
                const SizedBox(height: 4),
                Text(
                  metadata?.about ?? '',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inverseSurface,
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isReorderMode)
            Icon(
              selected ? PhosphorIcons.checkCircle() : PhosphorIcons.circle(),
              color: Theme.of(context).colorScheme.onSurface,
            ),
          if (isReorderMode)
            ReorderableDragStartListener(
              index: reorderIndex!,
              child: Container(
                color: Colors.transparent,
                height: 80,
                width: 50,
                child: Icon(PhosphorIcons.dotsSixVertical()),
              ),
            ),
        ],
      ),
    );
  }
}
