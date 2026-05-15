import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'geocoding_service.dart';
import 'route_provider.dart';

/// A reusable search field for route waypoints with geocoding suggestions.
///
/// Displays a leading indicator icon, text input, and a dropdown list of
/// geocoding results when typing.
class RouteSearchField extends ConsumerStatefulWidget {
  final int waypointIndex;
  final String hintText;
  final bool isFirst;
  final bool isLast;
  final Widget? leadingIcon;

  const RouteSearchField({
    super.key,
    required this.waypointIndex,
    required this.hintText,
    this.isFirst = false,
    this.isLast = false,
    this.leadingIcon,
  });

  @override
  ConsumerState<RouteSearchField> createState() => _RouteSearchFieldState();
}

class _RouteSearchFieldState extends ConsumerState<RouteSearchField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onChanged(String value) {
    // Update the waypoint label
    ref
        .read(routeProvider.notifier)
        .updateWaypointLabel(widget.waypointIndex, value);

    // Debounced geocoding search
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(routeProvider.notifier).searchGeocoding(value);
    });
  }

  void _onResultSelected(GeocodingResult result) {
    ref
        .read(routeProvider.notifier)
        .setWaypointFromResult(widget.waypointIndex, result);
    _controller.text = result.name ?? result.displayName;
    _focusNode.unfocus();
    _removeOverlay();
  }

  void _showSuggestions(List<GeocodingResult> results) {
    _removeOverlay();
    if (results.isEmpty || !_focusNode.hasFocus) return;

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final result = results[index];
                  return InkWell(
                    onTap: () => _onResultSelected(result),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            PhosphorIcons.mapPin(),
                            size: 18,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  result.name ?? result.displayName,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  result.displayName,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final routeState = ref.watch(routeProvider);

    // Sync controller with waypoint label
    final waypointLabel = widget.waypointIndex < routeState.waypoints.length
        ? routeState.waypoints[widget.waypointIndex].label
        : '';
    if (_controller.text != waypointLabel && !_focusNode.hasFocus) {
      _controller.text = waypointLabel;
    }

    // Update focused waypoint when this field is focused
    ref.listenManual(routeProvider, (previous, next) {
      // When geocoding results change for this field, show suggestions
      if (next.focusedWaypointIndex == widget.waypointIndex) {
        _showSuggestions(next.geocodingResults);
      } else if (previous?.focusedWaypointIndex == widget.waypointIndex &&
          next.focusedWaypointIndex != widget.waypointIndex) {
        _removeOverlay();
      }
    });

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon:
              widget.leadingIcon ??
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(
                  widget.isFirst
                      ? PhosphorIcons.circle()
                      : widget.isLast
                      ? PhosphorIcons.mapPin()
                      : PhosphorIcons.diamond(),
                  size: 14,
                  color: widget.isFirst
                      ? Colors.green
                      : widget.isLast
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    PhosphorIcons.x(),
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    _controller.clear();
                    ref
                        .read(routeProvider.notifier)
                        .updateWaypointLabel(widget.waypointIndex, '');
                    _removeOverlay();
                  },
                )
              : null,
        ),
        onTap: () {
          ref
              .read(routeProvider.notifier)
              .setFocusedWaypoint(widget.waypointIndex);
        },
        onChanged: _onChanged,
        onSubmitted: (_) {
          // If we have geocoding results, pick the first one
          if (routeState.geocodingResults.isNotEmpty) {
            _onResultSelected(routeState.geocodingResults.first);
          }
        },
      ),
    );
  }
}
