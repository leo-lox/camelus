import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    _animation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
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
    final defaultColor = Paletter.getDarkGray(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          onTap: widget.onComment,
          icon: Icon(
            PhosphorIcons.chatTeardropText(),
            size: BottomActionRow.iconSize,
            color: defaultColor,
          ),
          count: widget.commentCount,
        ),
        _buildRetweetButton(
          color: widget.isRetweeted ? Color.fromARGB(255, 22, 163, 74) : null,
          onTap: widget.onRetweet,
          repostController: _repostController,
        ),
        _buildLikeButton(),
        _buildActionButton(
          onTap: widget.onShare,
          icon: Icon(
            PhosphorIcons.share(),
            size: BottomActionRow.iconSize,
            color: defaultColor,
          ),
        ),
        _buildActionButton(
          onTap: widget.onMore,
          icon: Icon(
            PhosphorIcons.dotsThree(PhosphorIconsStyle.bold),
            size: BottomActionRow.iconSize,
            color: defaultColor,
          ),
        )
      ],
    );
  }

  Widget _buildLikeButton() {
    final defaultColor = Paletter.getDarkGray(context);
    return SizedBox(
      height: 35,
      width: 65,
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
                  style:
                      TextStyle(color: Paletter.getGray(context), fontSize: 16),
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
    String? svgIcon,
    int? count,
    Color? color,
  }) {
    final defaultColor = Paletter.getDarkGray(context);
    return SizedBox(
      height: 35,
      width: 65,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) icon,
              if (svgIcon != null)
                SvgPicture.asset(
                  svgIcon,
                  height: 35,
                  colorFilter: ColorFilter.mode(
                    color ?? defaultColor,
                    BlendMode.srcATop,
                  ),
                ),
              if (count != null) ...[
                const SizedBox(width: 5),
                Text(
                  count.toString(),
                  style:
                      TextStyle(color: Paletter.getGray(context), fontSize: 16),
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
  return Builder(builder: (context) {
    final defaultColor = Paletter.getDarkGray(context);
    return SizedBox(
      height: 35,
      width: 65,
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
                  child: SvgPicture.asset(
                    'assets/icons/retweet.svg',
                    height: 35,
                    colorFilter: ColorFilter.mode(
                      color ?? defaultColor,
                      BlendMode.srcATop,
                    ),
                  ),
                  builder: (context, Widget? child) {
                    return Transform.rotate(
                      angle: repostController.value * 2 * math.pi,
                      child: child,
                    );
                  }),
              if (count != null) ...[
                const SizedBox(width: 5),
                Text(
                  count.toString(),
                  style:
                      TextStyle(color: Paletter.getGray(context), fontSize: 16),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  });
}
