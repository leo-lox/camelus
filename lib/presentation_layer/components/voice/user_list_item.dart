import 'package:flutter/material.dart';

/// Widget for displaying a user in the voice channel
class UserListItem extends StatelessWidget {
  final String pubkey;
  final bool isSpeaking;
  final bool isMuted;
  final bool isDeafened;

  const UserListItem({
    Key? key,
    required this.pubkey,
    this.isSpeaking = false,
    this.isMuted = false,
    this.isDeafened = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract short username from pubkey
    final username = pubkey.substring(0, 8);

    return ListTile(
      dense: true,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 16,
            child: Text(
              username.substring(0, 2).toUpperCase(),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (isSpeaking)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        username,
        style: const TextStyle(fontSize: 14),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMuted)
            const Icon(Icons.mic_off, size: 16, color: Colors.red),
          if (isDeafened)
            const Icon(Icons.headset_off, size: 16, color: Colors.red),
        ],
      ),
    );
  }
}
