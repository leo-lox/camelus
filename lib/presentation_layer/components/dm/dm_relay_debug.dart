import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/messaging/dm_relay_health_provider.dart';
import '../../providers/ndk_provider.dart';
import '../../providers/relay_dm_test_provider.dart';

/// Shows the DM relay debug UI adaptively:
/// - Bottom sheet on mobile (width < 600)
/// - Dialog on desktop (width >= 600)
void showDmRelayDebug(BuildContext context, String peerPubkey) {
  final isDesktop = MediaQuery.of(context).size.width >= 600;

  if (isDesktop) {
    showDialog(
      context: context,
      builder: (context) => DmRelayDebugDialog(peerPubkey: peerPubkey),
    );
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DmRelayDebugBottomSheet(peerPubkey: peerPubkey),
    );
  }
}

/// Dialog version for desktop.
class DmRelayDebugDialog extends ConsumerWidget {
  final String peerPubkey;

  const DmRelayDebugDialog({super.key, required this.peerPubkey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.chatRelayStatus,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Content
            Flexible(
              child: SingleChildScrollView(
                child: DmRelayDebugContent(peerPubkey: peerPubkey),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet version for mobile.
class DmRelayDebugBottomSheet extends ConsumerWidget {
  final String peerPubkey;

  const DmRelayDebugBottomSheet({super.key, required this.peerPubkey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [DmRelayDebugContent(peerPubkey: peerPubkey)],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Shared content widget used by both dialog and bottom sheet.
class DmRelayDebugContent extends ConsumerWidget {
  final String peerPubkey;

  const DmRelayDebugContent({super.key, required this.peerPubkey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(dmRelayHealthProvider(peerPubkey));
    final deletionTestState = ref.watch(relayDmTestProvider);
    final l10n = AppLocalizations.of(context)!;
    final myPubkey = ref.read(ndkProvider).accounts.getPublicKey();
    final isSelfConversation = peerPubkey == myPubkey;

    const horizontalPadding = EdgeInsets.symmetric(horizontal: 20);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with status
        Padding(
          padding: horizontalPadding,
          child: _buildStatusHeader(context, healthState, l10n),
        ),

        const SizedBox(height: 24),

        // Your DM Relays section
        Padding(
          padding: horizontalPadding,
          child: _buildRelaySection(
            context,
            ref,
            title: l10n.yourDmRelays,
            relays: healthState.myRelays,
            emptyMessage: l10n.noRelaysFound,
            deletionTestState: deletionTestState,
          ),
        ),

        // Peer's DM Relays section (hidden for self-conversation)
        if (!isSelfConversation) ...[
          const SizedBox(height: 20),
          Padding(
            padding: horizontalPadding,
            child: _buildRelaySection(
              context,
              ref,
              title: l10n.peerDmRelays,
              relays: healthState.peerRelays,
              emptyMessage: l10n.noRelaysFound,
              deletionTestState: deletionTestState,
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Debug Tools section (ListTiles touch edges)
        _buildDebugTools(context, ref, healthState, l10n),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStatusHeader(
    BuildContext context,
    DmRelayHealthState state,
    AppLocalizations l10n,
  ) {
    final statusText = _getStatusText(state.status, l10n);
    final description = _getStatusDescription(state, l10n);
    final icon = _getStatusIcon(state.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PhosphorIcon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              statusText,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildRelaySection(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required List<DmRelayInfo> relays,
    required String emptyMessage,
    required RelayDmTestState deletionTestState,
  }) {
    final connectedCount = relays.where((r) => r.isConnected).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$connectedCount/${relays.length}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (relays.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...relays.map(
            (relay) => _buildRelayTile(context, ref, relay, deletionTestState),
          ),
      ],
    );
  }

  Widget _buildRelayTile(
    BuildContext context,
    WidgetRef ref,
    DmRelayInfo relay,
    RelayDmTestState deletionTestState,
  ) {
    final displayUrl = relay.url
        .replaceFirst('wss://', '')
        .replaceFirst('ws://', '')
        .replaceFirst(RegExp(r'/$'), '');

    final deletionResult = deletionTestState.deletionResults[relay.url];
    final privacyResult = deletionTestState.privacyResults[relay.url];
    final isTesting = deletionTestState.currentlyTesting == relay.url;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Connection status icon
          PhosphorIcon(
            relay.isConnected
                ? PhosphorIcons.plugsConnected()
                : PhosphorIcons.plugs(),
            size: 20,
          ),
          const SizedBox(width: 12),
          // Relay URL
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayUrl,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                if (privacyResult != null &&
                    privacyResult.status != RelayPrivacySupport.unknown)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _buildTestBadge(
                      context,
                      status: privacyResult.status,
                      errorMessage: privacyResult.errorMessage,
                    ),
                  ),
                if (deletionResult != null &&
                    deletionResult.status != RelayDeletionSupport.unknown)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _buildTestBadge(
                      context,
                      status: deletionResult.status,
                      errorMessage: deletionResult.errorMessage,
                    ),
                  ),
              ],
            ),
          ),
          // Test button
          if (relay.isConnected)
            isTesting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: Icon(
                      PhosphorIcons.flask(),
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    tooltip: AppLocalizations.of(context)!.testAllRelays,
                    onPressed: () {
                      ref
                          .read(relayDmTestProvider.notifier)
                          .testRelayComplete(relay.url);
                    },
                  ),
        ],
      ),
    );
  }

  /// Generic badge builder for both privacy and deletion test results.
  Widget _buildTestBadge(
    BuildContext context, {
    required dynamic status,
    String? errorMessage,
  }) {
    final l10n = AppLocalizations.of(context)!;

    Color color;
    String text;
    IconData icon;

    // Handle privacy status
    if (status is RelayPrivacySupport) {
      switch (status) {
        case RelayPrivacySupport.private:
          color = Colors.green;
          text = l10n.privacyPrivate;
          icon = PhosphorIcons.lockKey();
        case RelayPrivacySupport.leaksToEveryone:
          color = Colors.red;
          text = l10n.privacyLeaks;
          icon = PhosphorIcons.warning();
        case RelayPrivacySupport.relayRejectsGiftWrap:
          color = Colors.orange;
          text = l10n.relayRejectsGiftWrap;
          icon = PhosphorIcons.prohibit();
        case RelayPrivacySupport.networkError:
          color = Colors.orange;
          text = l10n.networkError;
          icon = PhosphorIcons.wifiSlash();
        case RelayPrivacySupport.timeout:
          color = Colors.orange;
          text = l10n.timeout;
          icon = PhosphorIcons.clockCountdown();
        case RelayPrivacySupport.otherError:
          color = Colors.orange;
          text = l10n.testFailed;
          icon = PhosphorIcons.warning();
        case RelayPrivacySupport.testing:
          color = Colors.blue;
          text = l10n.testing;
          icon = PhosphorIcons.circleNotch();
        case RelayPrivacySupport.unknown:
          return const SizedBox.shrink();
      }
    }
    // Handle deletion status
    else if (status is RelayDeletionSupport) {
      switch (status) {
        case RelayDeletionSupport.supported:
          color = Colors.green;
          text = l10n.deletionSupported;
          icon = PhosphorIcons.checkCircle();
        case RelayDeletionSupport.notSupported:
          color = Colors.red;
          text = l10n.deletionNotSupported;
          icon = PhosphorIcons.xCircle();
        case RelayDeletionSupport.relayRejectsGiftWrap:
          color = Colors.orange;
          text = l10n.relayRejectsGiftWrap;
          icon = PhosphorIcons.prohibit();
        case RelayDeletionSupport.relayRejectsDeletion:
          color = Colors.orange;
          text = l10n.relayRejectsDeletion;
          icon = PhosphorIcons.prohibit();
        case RelayDeletionSupport.networkError:
          color = Colors.orange;
          text = l10n.networkError;
          icon = PhosphorIcons.wifiSlash();
        case RelayDeletionSupport.timeout:
          color = Colors.orange;
          text = l10n.timeout;
          icon = PhosphorIcons.clockCountdown();
        case RelayDeletionSupport.otherError:
          color = Colors.orange;
          text = l10n.testFailed;
          icon = PhosphorIcons.warning();
        case RelayDeletionSupport.testing:
          color = Colors.blue;
          text = l10n.testing;
          icon = PhosphorIcons.circleNotch();
        case RelayDeletionSupport.unknown:
          return const SizedBox.shrink();
      }
    } else {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color),
            ),
          ],
        ),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildDebugTools(
    BuildContext context,
    WidgetRef ref,
    DmRelayHealthState healthState,
    AppLocalizations l10n,
  ) {
    // Collect all relay URLs for batch testing
    final allRelayUrls = {
      ...healthState.myRelays.where((r) => r.isConnected).map((r) => r.url),
      ...healthState.peerRelays.where((r) => r.isConnected).map((r) => r.url),
    }.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            l10n.debugTools,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 4),
        ListTile(
          leading: Icon(
            PhosphorIcons.arrowClockwise(),
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(l10n.refreshRelayDiscovery),
          onTap: () {
            ref
                .read(dmRelayHealthProvider(peerPubkey).notifier)
                .refreshRelayDiscovery();
          },
        ),
        ListTile(
          leading: Icon(
            PhosphorIcons.flask(),
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(l10n.testAllRelays),
          subtitle: Text(
            l10n.testAllRelaysDescription,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          onTap: allRelayUrls.isEmpty
              ? null
              : () {
                  ref
                      .read(relayDmTestProvider.notifier)
                      .testAllRelays(allRelayUrls);
                },
        ),
      ],
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

  String _getStatusText(DmRelayHealthStatus status, AppLocalizations l10n) {
    switch (status) {
      case DmRelayHealthStatus.excellent:
        return l10n.chatRelayExcellent;
      case DmRelayHealthStatus.degraded:
        return l10n.chatRelayDegraded;
      case DmRelayHealthStatus.poor:
        return l10n.chatRelayPoor;
      case DmRelayHealthStatus.unknown:
        return l10n.loading;
    }
  }

  String _getStatusDescription(
    DmRelayHealthState state,
    AppLocalizations l10n,
  ) {
    final myConnected = state.connectedMyRelaysCount;
    final peerConnected = state.connectedPeerRelaysCount;

    switch (state.status) {
      case DmRelayHealthStatus.excellent:
        return l10n.relayStatusExcellentDescription(myConnected, peerConnected);
      case DmRelayHealthStatus.degraded:
        if (myConnected > 0 && peerConnected == 0) {
          return l10n.relayStatusDegradedMyOnly;
        } else if (myConnected == 0 && peerConnected > 0) {
          return l10n.relayStatusDegradedPeerOnly;
        }
        return l10n.relayStatusDegradedPartial;
      case DmRelayHealthStatus.poor:
        return l10n.relayStatusPoorDescription;
      case DmRelayHealthStatus.unknown:
        return l10n.relayStatusLoadingDescription;
    }
  }
}
