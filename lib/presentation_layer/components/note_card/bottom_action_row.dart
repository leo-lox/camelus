import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class BottomActionRow extends StatelessWidget {
  final Function onComment;
  final Function onRetweet;
  final Function onLike;
  final Function onShare;

  const BottomActionRow({
    super.key,
    required this.onComment,
    required this.onRetweet,
    required this.onLike,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => onComment(),
          child: Container(
            padding:
                const EdgeInsets.only(left: 10, right: 10, top: 2, bottom: 2),
            //color: Palette.primary,
            child: Row(
              children: [
                SvgPicture.asset(
                  height: 23,
                  'assets/icons/chat-teardrop-text.svg',
                  color: Palette.darkGray,
                ),
                const SizedBox(width: 5),
                const Text(
                  // show number of comments if >0
                  "",

                  style: TextStyle(color: Palette.gray, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => onRetweet(),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/retweet.svg',
                color: Palette.darkGray,
              ),
              const SizedBox(width: 5),
              Text(
                "" //widget.tweet.retweetsCount
                    .toString(),
                style: const TextStyle(color: Palette.gray, fontSize: 16),
              ),
            ],
          ),
        ),
        // like button
        GestureDetector(
          onTap: () => onLike(),
          child: Row(
            children: [
              SvgPicture.asset(
                height: 23,
                'assets/icons/heart.svg',
                color: Palette.darkGray,
              ),
              const SizedBox(width: 5),
              Text(
                "" //widget.tweet.likesCount
                    .toString(),
                style: const TextStyle(color: Palette.gray, fontSize: 16),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => onShare(),
          child: SvgPicture.asset(
            height: 23,
            'assets/icons/share.svg',
            color: Palette.darkGray,
          ),
        ),
      ],
    );
  }
}
