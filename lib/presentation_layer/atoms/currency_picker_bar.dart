import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

class ChangeResult {
  final String currentUnit;
  final String previousUnit;

  ChangeResult({required this.currentUnit, required this.previousUnit});
}

class CurrencyPickerBar extends StatefulWidget {
  const CurrencyPickerBar({
    super.key,
    required this.currencies,
    this.initialIndex = 0,
    this.onChanged,
    this.height = 84,
    this.lensRadius = 28,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.trackColor,
    this.activeColor,
    this.inactiveColor,
    this.showHaptics = true,
    this.labelFontSize = 18,
    this.snapDuration = const Duration(milliseconds: 180),
    this.isDark = true,
  });

  final List<String> currencies;
  final int initialIndex;
  final ValueChanged<ChangeResult>? onChanged;
  final double height;
  final double lensRadius;
  final EdgeInsets padding;
  final Color? trackColor;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showHaptics;
  final bool isDark;

  final double labelFontSize;

  final Duration snapDuration;

  @override
  State<CurrencyPickerBar> createState() => _CurrencyPickerBarState();
}

class _CurrencyPickerBarState extends State<CurrencyPickerBar>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late double _lensX;
  late AnimationController _snapController;
  Animation<double>? _snapAnim;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currencies.isEmpty
        ? 0
        : widget.initialIndex.clamp(
            0,
            math.max(0, widget.currencies.length - 1),
          );
    _lensX = 0; // will be set on first layout
    _snapController = AnimationController(
      vsync: this,
      duration: widget.snapDuration,
    );
  }

  @override
  void didUpdateWidget(covariant CurrencyPickerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapDuration != widget.snapDuration) {
      _snapController.duration = widget.snapDuration;
    }
    // if (oldWidget.currencies != widget.currencies) {
    //   widget.onChanged?.call(_selectedIndex);
    // }
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  double _leftBound(double width) => widget.padding.left + widget.lensRadius;
  double _rightBound(double width) =>
      width - widget.padding.right - widget.lensRadius;

  // position for index i across the track
  double _xForIndex(int i, double width) {
    if (widget.currencies.length <= 1) {
      return (_leftBound(width) + _rightBound(width)) / 2;
    }
    final span = _rightBound(width) - _leftBound(width);
    final t = i / (widget.currencies.length - 1);
    return _leftBound(width) + span * t;
  }

  int _nearestIndexForX(double x, double width) {
    if (widget.currencies.isEmpty) return 0;
    int closest = 0;
    double best = double.infinity;
    for (int i = 0; i < widget.currencies.length; i++) {
      final xi = _xForIndex(i, width);
      final d = (x - xi).abs();
      if (d < best) {
        best = d;
        closest = i;
      }
    }
    return closest;
  }

  void _animateLensToIndex(int index, double width) {
    final targetX = _xForIndex(index, width);
    _snapController.stop();
    final start = _lensX;
    _snapAnim = Tween<double>(
      begin: start,
      end: targetX,
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_snapController);
    _snapAnim!.addListener(() {
      setState(() {
        _lensX = _snapAnim!.value;
      });
    });
    _snapController.forward(from: 0);
  }

  void _setSelectedIndex(int index, {bool fromUser = true}) {
    final previousIndex = _selectedIndex;
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
    if (widget.showHaptics && fromUser) {
      HapticFeedback.selectionClick();
    }

    final currentUnit = widget.currencies[_selectedIndex];
    final previousUnit = widget.currencies[previousIndex];

    widget.onChanged?.call(
      ChangeResult(currentUnit: currentUnit, previousUnit: previousUnit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final trackColor =
        widget.trackColor ??
        (widget.isDark
            ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.22)
            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.85));

    final inactiveColor =
        widget.inactiveColor ??
        (widget.isDark
            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.88)
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9));

    final activeColor =
        widget.activeColor ?? theme.colorScheme.primaryContainer;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = widget.height;

        // initialize lens position on first layout
        if (_lensX == 0 && width > 0) {
          _lensX = _xForIndex(_selectedIndex, width);
        }

        void handleTapOrPanTo(Offset localPos) {
          final clamped = localPos.dx.clamp(
            _leftBound(width),
            _rightBound(width),
          );
          setState(() => _lensX = clamped.toDouble());
          final nearest = _nearestIndexForX(_lensX, width);
          _setSelectedIndex(nearest);
        }

        Widget buildTrackContent() {
          final labels = <Widget>[];
          for (int i = 0; i < widget.currencies.length; i++) {
            final x = _xForIndex(i, width);
            final t = (i == _selectedIndex) ? 1.0 : 0.0;
            final color =
                Color.lerp(inactiveColor, activeColor, t) ?? activeColor;

            labels.add(
              Positioned(
                left: x - 36, // centered width=72
                width: 72,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Text(
                    widget.currencies[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: widget.labelFontSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: color,
                    ),
                  ),
                ),
              ),
            );
          }

          return Stack(
            children: [
              // track background
              Positioned.fill(
                child: Container(
                  margin: widget.padding,
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      if (!widget.isDark)
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.shadow.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                    ],
                  ),
                ),
              ),

              ...labels,
            ],
          );
        }

        final lensRadius = widget.lensRadius;
        final lensDiameter = lensRadius * 2;
        final lensCenterY = height / 2;
        final hasItems = widget.currencies.isNotEmpty;
        final canDecrease = hasItems && _selectedIndex > 0;
        final canIncrease =
            hasItems && _selectedIndex < widget.currencies.length - 1;

        return Semantics(
          label: 'Currency picker',
          value: hasItems ? widget.currencies[_selectedIndex] : '',
          increasedValue: canIncrease
              ? widget.currencies[_selectedIndex + 1]
              : null,
          decreasedValue: canDecrease
              ? widget.currencies[_selectedIndex - 1]
              : null,
          onIncrease: canIncrease
              ? () {
                  _setSelectedIndex(_selectedIndex + 1);
                  _animateLensToIndex(_selectedIndex, width);
                }
              : null,
          onDecrease: canDecrease
              ? () {
                  _setSelectedIndex(_selectedIndex - 1);
                  _animateLensToIndex(_selectedIndex, width);
                }
              : null,
          child: SizedBox(
            height: height,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (d) {
                handleTapOrPanTo(d.localPosition);
                _animateLensToIndex(_selectedIndex, width);
              },
              onHorizontalDragUpdate: (d) {
                final moved = (_lensX + d.delta.dx).clamp(
                  _leftBound(width),
                  _rightBound(width),
                );
                setState(() => _lensX = moved.toDouble());
                final nearest = _nearestIndexForX(_lensX, width);
                _setSelectedIndex(nearest);
              },
              onHorizontalDragEnd: (d) {
                _animateLensToIndex(_selectedIndex, width);
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // background track
                  Positioned.fill(child: buildTrackContent()),

                  // lens
                  Positioned(
                    left: _lensX - lensRadius,
                    top: lensCenterY - lensRadius,
                    width: lensDiameter,
                    height: lensDiameter,
                    child: _LensRing(
                      isDark: widget.isDark,
                      borderWidth: 3,

                      highlightColor: widget.isDark
                          ? Theme.of(
                              context,
                            ).colorScheme.surface.withValues(alpha: 0.08)
                          : Theme.of(
                              context,
                            ).colorScheme.surface.withValues(alpha: 0.18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LensRing extends StatelessWidget {
  const _LensRing({
    required this.isDark,
    this.borderWidth = 3,
    this.highlightColor,
  });

  final bool isDark;
  final double borderWidth;

  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            width: borderWidth,
            color: isDark
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.surface,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.transparent,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color:
                  highlightColor ??
                  Theme.of(context).colorScheme.onSurfaceVariant,
              blurRadius: 8,
              spreadRadius: -2,
              offset: const Offset(0, -1),
            ),
          ],
        ),
      ),
    );
  }
}
