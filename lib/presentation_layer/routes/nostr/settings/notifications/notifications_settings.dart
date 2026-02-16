import 'package:camelus/l10n/app_localizations.dart';
import 'package:camelus/presentation_layer/providers/notification_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class NotificationsSettingsPage extends ConsumerWidget {
  const NotificationsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft()),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l10n.pushNotifications),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          // Main notification toggle card
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        PhosphorIcons.bell(),
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.pushNotifications,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.notificationsEnabled
                                  ? l10n.receiveNotificationsAboutReplies
                                  : l10n.enableNotificationsForReplies,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: state.notificationsEnabled,
                        onChanged: state.isLoading
                            ? null
                            : (enabled) async {
                                if (enabled) {
                                  await notifier.requestPermission();
                                } else {
                                  await notifier.disableNotifications();
                                }
                              },
                      ),
                    ],
                  ),
                  if (state.permissionRequested && state.notificationsDenied)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orangeAccent.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              PhosphorIcons.warning(),
                              color: Colors.orangeAccent,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.notificationsDeniedInSettings,
                                style: TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Last sync info
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        if (state.syncSuccessVisible)
                          Icon(
                            PhosphorIcons.checkCircle(),
                            color: Theme.of(context).colorScheme.primary,
                            size: 18,
                          )
                        else if (state.syncError != null &&
                            state.syncError!.isNotEmpty)
                          Icon(
                            PhosphorIcons.xCircle(),
                            color: Theme.of(context).colorScheme.error,
                            size: 18,
                          )
                        else
                          Icon(
                            PhosphorIcons.clockCounterClockwise(),
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            size: 18,
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _lastSyncText(state.lastSyncAt),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              if (state.syncError != null &&
                                  state.syncError!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Error: ${state.syncError}',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Event kinds section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.faders(),
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Event types',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: _kindOptions.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final enabled = state.selectedKinds.contains(option.kind);
                final isLast = index == _kindOptions.length - 1;

                return Column(
                  children: [
                    SwitchListTile(
                      title: Text(option.label),
                      subtitle: Text(
                        option.description,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      value: enabled,
                      onChanged: state.isLoading
                          ? null
                          : (value) =>
                                notifier.setKindEnabled(option.kind, value),
                    ),
                    if (!isLast) Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

String _lastSyncText(DateTime? lastSyncAt) {
  if (lastSyncAt == null) {
    return 'Last sync: never';
  }
  final local = lastSyncAt.toLocal();
  final date =
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
  final time =
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  return 'Last sync: $date $time';
}

class _NotificationKindOption {
  final int kind;
  final String label;
  final String description;

  const _NotificationKindOption({
    required this.kind,
    required this.label,
    required this.description,
  });
}

const List<_NotificationKindOption> _kindOptions = [
  _NotificationKindOption(
    kind: 1,
    label: 'Text notes',
    description: 'Regular text posts and updates',
  ),
  _NotificationKindOption(
    kind: 3,
    label: 'Contacts',
    description: 'Contact list updates',
  ),
  _NotificationKindOption(
    kind: 6,
    label: 'Reposts',
    description: 'When someone reposts content',
  ),
  _NotificationKindOption(
    kind: 7,
    label: 'Reactions',
    description: 'Likes and other reactions',
  ),
  _NotificationKindOption(
    kind: 9,
    label: 'Chat Message',
    description: 'Public chat messages',
  ),
  _NotificationKindOption(
    kind: 13,
    label: 'Seals',
    description: 'Sealed messages',
  ),
  _NotificationKindOption(
    kind: 14,
    label: 'Direct messages',
    description: 'Private direct messages',
  ),
  _NotificationKindOption(
    kind: 15,
    label: 'File Message',
    description: 'Private Direct Messages',
  ),
  _NotificationKindOption(
    kind: 1059,
    label: 'Gift Wrap',
    description:
        'Used for encrypted events that require unwrapping (e.g. group chats, sealed messages, etc.)',
  ),
];
