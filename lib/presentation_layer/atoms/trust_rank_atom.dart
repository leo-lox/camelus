import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Visual indicator for a trust rank value.
///
/// Shows a status icon and color for the trust range, and reveals
/// the numeric value plus description on hover or tap.
class TrustRankAtom extends StatelessWidget {
  final int? trustRank;
  final double iconSize;
  final bool showLabel;

  const TrustRankAtom({
    super.key,
    this.trustRank,
    this.iconSize = 20,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    if (trustRank == null) {
      return const SizedBox.shrink();
    }

    final normalizedValue = trustRank!.clamp(0, 100);
    final trustLevel = _TrustLevel.fromValue(normalizedValue);
    final label = _trustLabel(trustLevel);
    final description = _trustDescription(trustLevel);
    final icon = _trustIcon(trustLevel);
    final color = _trustColor(trustLevel, context);
    final tooltip = '$label · $normalizedValue / 100\n$description';
    final tooltipKey = GlobalKey<TooltipState>();

    return Tooltip(
      key: tooltipKey,
      message: tooltip,

      triggerMode: TooltipTriggerMode.manual,
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 100),
      showDuration: const Duration(seconds: 4),
      textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: MouseRegion(
        onEnter: (_) => tooltipKey.currentState?.ensureTooltipVisible(),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => tooltipKey.currentState?.ensureTooltipVisible(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: iconSize + 14,
                height: iconSize + 14,
                decoration: BoxDecoration(shape: BoxShape.circle),
                alignment: Alignment.center,
                child: PhosphorIcon(icon, color: color, size: iconSize),
              ),
              if (showLabel) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _TrustLevel {
  untrusted,
  somewhatTrusted,
  okTrust,
  goodTrust,
  trusted;

  static _TrustLevel fromValue(int value) {
    if (value <= 1) return _TrustLevel.untrusted;
    if (value < 10) return _TrustLevel.somewhatTrusted;
    if (value < 40) return _TrustLevel.okTrust;
    if (value < 50) return _TrustLevel.goodTrust;
    return _TrustLevel.trusted;
  }
}

PhosphorIconData _trustIcon(_TrustLevel level) {
  switch (level) {
    case _TrustLevel.untrusted:
      return PhosphorIcons.shieldSlash(PhosphorIconsStyle.regular);
    case _TrustLevel.somewhatTrusted:
      return PhosphorIcons.warning(PhosphorIconsStyle.regular);
    case _TrustLevel.okTrust:
      return PhosphorIcons.shield(PhosphorIconsStyle.regular);
    case _TrustLevel.goodTrust:
      return PhosphorIcons.shieldCheck(PhosphorIconsStyle.regular);
    case _TrustLevel.trusted:
      return PhosphorIcons.shieldStar(PhosphorIconsStyle.regular);
  }
}

Color _trustColor(_TrustLevel level, BuildContext context) {
  final scheme = Theme.of(context).colorScheme;

  switch (level) {
    case _TrustLevel.untrusted:
      return scheme.error;
    case _TrustLevel.somewhatTrusted:
      return scheme.secondary;
    case _TrustLevel.okTrust:
      return scheme.primary;
    case _TrustLevel.goodTrust:
      return scheme.primary;
    case _TrustLevel.trusted:
      return scheme.primary;
  }
}

String _trustLabel(_TrustLevel level) {
  switch (level) {
    case _TrustLevel.untrusted:
      return 'Untrusted';
    case _TrustLevel.somewhatTrusted:
      return 'Somewhat trusted';
    case _TrustLevel.okTrust:
      return 'OK trust';
    case _TrustLevel.goodTrust:
      return 'Good trust';
    case _TrustLevel.trusted:
      return 'Trusted';
  }
}

String _trustDescription(_TrustLevel level) {
  switch (level) {
    case _TrustLevel.untrusted:
      return 'Trust value is very low.';
    case _TrustLevel.somewhatTrusted:
      return 'Trust is weak but not completely unreliable.';
    case _TrustLevel.okTrust:
      return 'Trust is acceptable for most assertions.';
    case _TrustLevel.goodTrust:
      return 'Trust is strong and dependable.';
    case _TrustLevel.trusted:
      return 'Trust is very high and reliable.';
  }
}
