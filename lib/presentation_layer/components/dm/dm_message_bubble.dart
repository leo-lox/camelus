import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../domain_layer/entities/direct_message.dart';

/// A message bubble for displaying a single DM.
class DmMessageBubble extends StatefulWidget {
  final DirectMessage message;
  final bool showTimestamp;
  final Future<bool> Function(String messageId)? onDelete;
  final Future<bool> Function(String messageId)? onRetry;
  final void Function(String messageId)? onRemoveFailedMessage;

  const DmMessageBubble({
    super.key,
    required this.message,
    this.showTimestamp = true,
    this.onDelete,
    this.onRetry,
    this.onRemoveFailedMessage,
  });

  @override
  State<DmMessageBubble> createState() => _DmMessageBubbleState();
}

class _DmMessageBubbleState extends State<DmMessageBubble> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isOutgoing = widget.message.isOutgoing;
    final isFailed = widget.message.sendStatus == MessageSendStatus.failed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Row(
          mainAxisAlignment: isOutgoing
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Delete button before message (for outgoing only)
            if (isOutgoing && _isHovered && !isFailed) ...[
              _buildDeleteButton(context),
              const SizedBox(width: 8),
            ] else if (isOutgoing && !isFailed)
              const SizedBox(width: 40),
            // Failed message actions
            if (isFailed && isOutgoing) ...[
              _buildFailedMessageActions(context),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: GestureDetector(
                onLongPress: isFailed ? null : () => _showMessageMenu(context),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isFailed
                        ? Theme.of(context).colorScheme.errorContainer
                        : isOutgoing
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isOutgoing ? 18 : 4),
                      bottomRight: Radius.circular(isOutgoing ? 4 : 18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        widget.message.content,
                        style: TextStyle(
                          color: isFailed
                              ? Theme.of(context).colorScheme.onErrorContainer
                              : isOutgoing
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                          fontSize: 15,
                        ),
                      ),
                      if (widget.showTimestamp) ...[
                        const SizedBox(height: 4),
                        _buildStatusRow(context),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (isOutgoing && !isFailed) const SizedBox(width: 8),
            // Delete button after message (for incoming)
            if (!isOutgoing && _isHovered) ...[
              const SizedBox(width: 8),
              _buildDeleteButton(context),
            ] else if (!isOutgoing)
              const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context) {
    final isOutgoing = widget.message.isOutgoing;
    final sendStatus = widget.message.sendStatus;
    final isFailed = sendStatus == MessageSendStatus.failed;
    final isSent = sendStatus == MessageSendStatus.sent;

    final textColor = isFailed
        ? Theme.of(context).colorScheme.onErrorContainer.withValues(alpha: 0.7)
        : isOutgoing
        ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isFailed) ...[
          Icon(
            Icons.error_outline,
            size: 12,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 4),
        ],
        Tooltip(
          message: _formatExactTime(context, widget.message.createdAt),
          child: Text(
            isFailed
                ? AppLocalizations.of(context)!.failed
                : _formatTime(context, widget.message.createdAt),
            style: TextStyle(
              color: isFailed ? Theme.of(context).colorScheme.error : textColor,
              fontSize: 11,
            ),
          ),
        ),
        // Reserve space for check mark on outgoing messages
        if (isOutgoing && !isFailed) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.check,
            size: 12,
            color: isSent ? textColor : Colors.transparent,
          ),
        ],
      ],
    );
  }

  Widget _buildFailedMessageActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => widget.onRetry?.call(widget.message.id),
          icon: Icon(
            Icons.refresh,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          splashRadius: 16,
          tooltip: AppLocalizations.of(context)!.retry,
        ),
        IconButton(
          onPressed: () =>
              widget.onRemoveFailedMessage?.call(widget.message.id),
          icon: Icon(
            Icons.close,
            size: 18,
            color: Theme.of(context).colorScheme.error,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          splashRadius: 16,
          tooltip: AppLocalizations.of(context)!.delete,
        ),
      ],
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return IconButton(
      onPressed: () {
        if (HardwareKeyboard.instance.isShiftPressed) {
          // Shift+click: delete immediately without confirmation
          widget.onDelete?.call(widget.message.id);
        } else {
          _confirmDelete(context);
        }
      },
      icon: Icon(
        Icons.delete_outline,
        size: 18,
        color: Theme.of(context).colorScheme.error,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      splashRadius: 16,
    );
  }

  String _formatTime(BuildContext context, int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      // Today - show time
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return AppLocalizations.of(context)!.yesterday;
    } else {
      return timeago.format(dateTime, locale: 'en_short');
    }
  }

  String _formatExactTime(BuildContext context, int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.yMd(locale).add_Hm();
    return dateFormat.format(dateTime);
  }

  void _showMessageMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatExactTime(context, widget.message.createdAt),
                  style: TextStyle(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(AppLocalizations.of(context)!.copy),
              onTap: () {
                Clipboard.setData(ClipboardData(text: widget.message.content));
                Navigator.of(sheetContext).pop();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(sheetContext).colorScheme.error,
              ),
              title: Text(
                AppLocalizations.of(context)!.deleteMessage,
                style: TextStyle(
                  color: Theme.of(sheetContext).colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteMessageConfirmTitle),
        content: Text(
          AppLocalizations.of(context)!.deleteMessageConfirmContent,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              if (widget.onDelete != null) {
                final deletedFromRelays = await widget.onDelete!(
                  widget.message.id,
                );
                if (!deletedFromRelays && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(
                          context,
                        )!.deletionNotSupportedByRelays,
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A date separator for grouping messages by date.
class DmDateSeparator extends StatelessWidget {
  final int timestamp;

  const DmDateSeparator({super.key, required this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDate(context, timestamp),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      return AppLocalizations.of(context)!.today;
    } else if (diff.inDays == 1) {
      return AppLocalizations.of(context)!.yesterday;
    } else if (diff.inDays < 7) {
      final l10n = AppLocalizations.of(context)!;
      final weekdays = [
        l10n.monday,
        l10n.tuesday,
        l10n.wednesday,
        l10n.thursday,
        l10n.friday,
        l10n.saturday,
        l10n.sunday,
      ];
      return weekdays[dateTime.weekday - 1];
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
