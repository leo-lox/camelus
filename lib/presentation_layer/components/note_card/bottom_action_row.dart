import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:math' as math;

class BottomActionRow extends StatefulWidget {
  final VoidCallback onComment;
  final VoidCallback onRetweet;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onMore;
  final int? commentCount;
  final int? retweetCount;
  final int? likeCount;
  final bool isRetweeted;
  final bool retweetLoading;
  final bool isLiked;

  static const iconSize = 24.0;

  const BottomActionRow({
    super.key,
    required this.onComment,
    required this.onRetweet,
    required this.onLike,
    required this.onShare,
    required this.onMore,
    this.commentCount,
    this.retweetCount,
    this.likeCount,
    this.isRetweeted = false,
    this.isLiked = false,
    this.retweetLoading = false,
  });

  @override
  State<BottomActionRow> createState() => _BottomActionRowState();
}

class _BottomActionRowState extends State<BottomActionRow>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  late AnimationController _repostController;

  @override
  void didUpdateWidget(BottomActionRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.retweetLoading != oldWidget.retweetLoading) {
      if (widget.retweetLoading) {
        _repostController.repeat();
      } else {
        _repostController.reset();
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // like animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: 1.4,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
    _animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      }
    });

    // repost animation
    _repostController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    _repostController.stop();
    // start state
    if (widget.retweetLoading) {
      // _repostController.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerLike() {
    _controller.forward();
    widget.onLike();
  }

  @override
  Widget build(BuildContext context) {
    final defaultColor = Theme.of(context).colorScheme.secondary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: _buildActionButton(
            onTap: widget.onComment,
            icon: Icon(
              PhosphorIcons.chatTeardropText(),
              size: BottomActionRow.iconSize,
              color: defaultColor,
            ),
            count: widget.commentCount,
          ),
        ),
        Expanded(
          child: _buildRetweetButton(
            color: widget.isRetweeted ? Color.fromARGB(255, 22, 163, 74) : null,
            onTap: widget.onRetweet,
            repostController: _repostController,
            count: widget.retweetCount,
          ),
        ),
        Expanded(child: _buildLikeButton()),
        Expanded(
          child: _buildActionButton(
            onTap: widget.onShare,
            icon: Icon(
              PhosphorIcons.share(),
              size: BottomActionRow.iconSize,
              color: defaultColor,
            ),
          ),
        ),
        Expanded(
          child: _buildActionButton(
            onTap: widget.onMore,
            icon: Icon(
              PhosphorIcons.dotsThree(PhosphorIconsStyle.bold),
              size: BottomActionRow.iconSize,
              color: defaultColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLikeButton() {
    final defaultColor = Theme.of(context).colorScheme.secondary;
    return SizedBox(
      height: 35,
      // width is removed so that parent Flex (Expanded) can control sizing
      child: InkWell(
        onTap: _triggerLike,
        borderRadius: BorderRadius.circular(50),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _animation,
                child: Icon(
                  widget.isLiked
                      ? PhosphorIcons.heart(PhosphorIconsStyle.fill)
                      : PhosphorIcons.heart(),
                  size: BottomActionRow.iconSize,
                  color: widget.isLiked
                      ? Color.fromARGB(255, 230, 40, 85)
                      : defaultColor,
                ),
              ),
              if (widget.likeCount != null) ...[
                const SizedBox(width: 5),
                Text(
                  widget.likeCount.toString(),
                  style: TextStyle(color: defaultColor, fontSize: 16),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    Icon? icon,

    int? count,
  }) {
    return SizedBox(
      height: 35,
      // allow flexible horizontal sizing
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ?icon,

              if (count != null) ...[
                const SizedBox(width: 5),
                Text(
                  count.toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 16,
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

Widget _buildRetweetButton({
  required VoidCallback onTap,
  required AnimationController repostController,
  int? count,
  Color? color,
}) {
  return Builder(
    builder: (context) {
      final defaultColor = Theme.of(context).colorScheme.secondary;
      return SizedBox(
        height: 35,
        // width removed for flexibility
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: repostController,
                  child: Icon(
                    PhosphorIcons.repeat(),
                    size: BottomActionRow.iconSize,
                    color: color ?? defaultColor,
                  ),
                  builder: (context, Widget? child) {
                    return Transform.rotate(
                      angle: repostController.value * 2 * math.pi,
                      child: child,
                    );
                  },
                ),
                if (count != null) ...[
                  const SizedBox(width: 5),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inverseSurface,
                      fontSize: 16,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
