import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class BottomActionRow extends StatelessWidget {
  final VoidCallback onComment;
  final VoidCallback onRetweet;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onMore;
  final int? commentCount;
  final int? retweetCount;
  final int? likeCount;
  final bool? isRetweeted;
  final bool? isLiked;

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
    this.isRetweeted,
    this.isLiked,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          onTap: onComment,
          //icon: 'assets/icons/chat-teardrop-text.svg',
          icon: Icon(
            PhosphorIcons.chatTeardropText(),
            size: iconSize,
            color: defaultColor,
          ),
          count: commentCount,
        ),
        _buildActionButton(
          onTap: onRetweet,
          svgIcon: 'assets/icons/retweet.svg',
          count: retweetCount,
        ),
        _buildActionButton(
          onTap: onLike,
          icon: Icon(
            PhosphorIcons.heart(),
            size: iconSize,
            color: defaultColor,
          ),
          count: likeCount,
        ),
        _buildActionButton(
          onTap: onShare,
          icon: Icon(
            PhosphorIcons.share(),
            size: iconSize,
            color: defaultColor,
          ),
        ),
        _buildActionButton(
          onTap: onMore,
          icon: Icon(
            PhosphorIcons.dotsThree(),
            size: iconSize,
            color: defaultColor,
          ),
        )
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    Icon? icon,
    String? svgIcon,
    int? count,
    bool? isToggled,
    Color? activeColor,
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
                    defaultColor,
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
