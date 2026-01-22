import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../providers/dm_relay_health_provider.dart';
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
        return PhosphorIcons.shieldCheck(PhosphorIconsStyle.regular);
      case DmRelayHealthStatus.degraded:
        return PhosphorIcons.shieldWarning(PhosphorIconsStyle.regular);
      case DmRelayHealthStatus.poor:
        return PhosphorIcons.shieldSlash(PhosphorIconsStyle.regular);
      case DmRelayHealthStatus.unknown:
        return PhosphorIcons.shield(PhosphorIconsStyle.regular);
    }
  }
}
