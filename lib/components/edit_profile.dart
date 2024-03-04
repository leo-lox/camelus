import 'dart:developer';

import 'package:camelus/config/palette.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class EditProfile extends ConsumerStatefulWidget {
  const EditProfile({Key? key}) : super(key: key);

  @override
  ConsumerState<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends ConsumerState<EditProfile> {
  final myController = TextEditingController();
  readText() {
    log(myController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      child: Column(
        children: [
          Text(
            "welcome to",
            style: TextStyle(
              color: Palette.extraLightGray,
              fontSize: MediaQuery.of(context).size.width / 33,
            ),
          ),
          Column(
            children: <Widget>[
              SizedBox(
                width: double.infinity,
                child: Container(
                 /// color: Colors.red,
                  child: Text(
                    "Name",
                    textAlign: TextAlign.left,
                    style: TextStyle(
              color: const Color.fromARGB(213, 245, 248, 250),
              fontSize: MediaQuery.of(context).size.width / 28,
            ),
                    
                  ),
                ),
              ),
            ],
          ),
          TextField(
            decoration: InputDecoration(
              hintText: "",
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  width: 1, //<-- SEE HERE
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          TextField(
            controller: myController,
            decoration: const InputDecoration(
              hintText: "Please Type in",
              border: OutlineInputBorder(),
            ),
          ),
          const TextField(
            decoration: InputDecoration(
              hintText: "Please Type in",
              border: OutlineInputBorder(),
            ),
          ),
          TextButton(onPressed: () => {readText()}, child: const Text("Go"))
        ],
      ),
    );
  }
}
