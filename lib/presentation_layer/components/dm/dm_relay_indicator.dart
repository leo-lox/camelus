import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../providers/messaging/dm_relay_health_provider.dart';
import 'dm_relay_debug.dart';

/// Shield icon indicator showing DM relay health status.
/// Tapping opens a debug view with detailed relay information.
class DmRelayIndicator extends ConsumerWidget {
  final String peerPubkey;

  const DmRelayIndicator({super.key, required this.peerPubkey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(dmRelayHealthProvider(peerPubkey));
    final icon = _getStatusIcon(healthState.status);

    return IconButton(
      onPressed: () => showDmRelayDebug(context, peerPubkey),
      icon: PhosphorIcon(icon),
      iconSize: 20,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }

  PhosphorIconData _getStatusIcon(DmRelayHealthStatus status) {
    switch (status) {
      case DmRelayHealthStatus.excellent:
        return PhosphorIcons.shieldCheck;
      case DmRelayHealthStatus.degraded:
        return PhosphorIcons.shieldWarning;
      case DmRelayHealthStatus.poor:
        return PhosphorIcons.shieldSlash;
      case DmRelayHealthStatus.unknown:
        return PhosphorIcons.shield;
    }
  }
}
