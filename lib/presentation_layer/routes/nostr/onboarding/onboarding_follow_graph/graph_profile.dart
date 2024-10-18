import 'package:flutter/widgets.dart';

import '../../../../../domain_layer/entities/user_metadata.dart';
import '../../../../atoms/my_profile_picture.dart';

class GraphProfile extends StatelessWidget {
  final UserMetadata _userMetadata;

  GraphProfile({
    super.key,
    required UserMetadata metadata,
  }) : _userMetadata = metadata;

  @override
  build(context) {
    return Column(
      children: [
        UserImage(
          imageUrl: _userMetadata.picture,
          pubkey: _userMetadata.pubkey,
        ),
        Text(_userMetadata.name ?? _userMetadata.pubkey),
      ],
    );
  }
}
