import 'package:flutter/widgets.dart';

import '../../../../../domain_layer/entities/user_metadata.dart';
import '../../../../atoms/my_profile_picture.dart';

class GraphProfile extends StatelessWidget {
  final UserMetadata _userMetadata;

  const GraphProfile({
    super.key,
    required UserMetadata metadata,
  }) : _userMetadata = metadata;

  @override
  build(context) {
    return Row(
      children: [
        const SizedBox(
          height: 2,
          width: 2,
        ),
        UserImage(
          imageUrl: _userMetadata.picture,
          pubkey: _userMetadata.pubkey,
          filterQuality: FilterQuality.low,
          disableGif: true,
        ),
        const SizedBox(
          width: 10,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 170, // Set your desired max width
              child: Text(
                _userMetadata.name ?? _userMetadata.pubkey,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            SizedBox(
              width: 170, // Set your desired max width
              child: Text(
                _userMetadata.nip05 ?? '',
                style: const TextStyle(
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            )
          ],
        )
      ],
    );
  }
}
