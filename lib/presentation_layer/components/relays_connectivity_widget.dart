import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../providers/ndk_provider.dart';

class RelaysConnectivityWidget extends ConsumerWidget {
  final VoidCallback onTap;

  const RelaysConnectivityWidget({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ndk = ref.watch(ndkProvider);

    return GestureDetector(
      onTap: onTap,
      child: StreamBuilder(
        stream: ndk.connectivity.relayConnectivityChanges,
        builder: (context, snapshot) {
          final isConnected =
              snapshot.hasData &&
              snapshot.data!.isNotEmpty &&
              snapshot.data!.values.any((e) => e.isConnected);

          final connectedCount = snapshot.hasData && snapshot.data!.isNotEmpty
              ? snapshot.data!.values.where((e) => e.isConnected).length
              : 0;

          //log("Stream updated: isConnected=$isConnected, count=$connectedCount");
          return Row(
            children: [
              Icon(
                isConnected
                    ? PhosphorIcons.cellSignalFull
                    : PhosphorIcons.cellSignalSlash,
                key: ValueKey(isConnected),
              ),
              const SizedBox(width: 5),
              Text(
                connectedCount.toString(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inverseSurface,
                ),
                key: ValueKey(connectedCount),
              ),
              const SizedBox(width: 5),
            ],
          );
        },
      ),
    );
  }
}
