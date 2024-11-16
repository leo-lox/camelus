import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomActionRow extends StatelessWidget {
  final VoidCallback onComment;
  final VoidCallback onRetweet;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onMore;
  final int? commentCount;
  final int? retweetCount;
  final int? likeCount;

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
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          onTap: onComment,
          icon: 'assets/icons/chat-teardrop-text.svg',
          count: commentCount,
        ),
        _buildActionButton(
          onTap: onRetweet,
          icon: 'assets/icons/retweet.svg',
          count: retweetCount,
        ),
        _buildActionButton(
          onTap: onLike,
          icon: 'assets/icons/heart.svg',
          count: likeCount,
        ),
        _buildActionButton(
          onTap: onShare,
          icon: 'assets/icons/share.svg',
        ),
        _buildActionButton(
          onTap: onMore,
          icon: 'assets/icons/tweetSetting.svg',
        )
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required String icon,
    int? count,
  }) {
    return SizedBox(
      height: 35,
      width: 65,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                icon,
                height: 35,
                colorFilter: const ColorFilter.mode(
                  Palette.darkGray,
                  BlendMode.srcIn,
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
