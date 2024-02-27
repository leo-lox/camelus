import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class EditProfile extends ConsumerStatefulWidget {
  const EditProfile({Key? key}) : super(key: key);

  @override
  ConsumerState<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends ConsumerState<EditProfile> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: "Please Type in",
              border: OutlineInputBorder(),
            ),
          ),
          TextButton(onPressed: () => {}, child: Text("Go"))
        ],
      ),
    );
  }
}
