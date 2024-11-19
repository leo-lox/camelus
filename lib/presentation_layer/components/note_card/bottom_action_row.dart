import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
  final bool isLiked;

  static const iconSize = 24.0;
  static const defaultColor = Palette.darkGray;

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
  });

  @override
  _BottomActionRowState createState() => _BottomActionRowState();
}

class _BottomActionRowState extends State<BottomActionRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      }
    });
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          onTap: widget.onComment,
          icon: Icon(
            PhosphorIcons.chatTeardropText(),
            size: BottomActionRow.iconSize,
            color: BottomActionRow.defaultColor,
          ),
          count: widget.commentCount,
        ),
        _buildActionButton(
          onTap: widget.onRetweet,
          svgIcon: 'assets/icons/retweet.svg',
          count: widget.retweetCount,
        ),
        _buildLikeButton(),
        _buildActionButton(
          onTap: widget.onShare,
          icon: Icon(
            PhosphorIcons.share(),
            size: BottomActionRow.iconSize,
            color: BottomActionRow.defaultColor,
          ),
        ),
        _buildActionButton(
          onTap: widget.onMore,
          icon: Icon(
            PhosphorIcons.dotsThree(PhosphorIconsStyle.bold),
            size: BottomActionRow.iconSize,
            color: BottomActionRow.defaultColor,
          ),
        )
      ],
    );
  }

  Widget _buildLikeButton() {
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
                      ? Palette.likeActive
                      : BottomActionRow.defaultColor,
                ),
              ),
              if (widget.likeCount != null) ...[
                const SizedBox(width: 5),
                Text(
                  widget.likeCount.toString(),
                  style: const TextStyle(color: Palette.gray, fontSize: 16),
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
  }) {
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
                  colorFilter: const ColorFilter.mode(
                    BottomActionRow.defaultColor,
                    BlendMode.srcATop,
                  ),
                ),
              if (count != null) ...[
                const SizedBox(width: 5),
                Text(
                  count.toString(),
                  style: const TextStyle(color: Palette.gray, fontSize: 16),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
