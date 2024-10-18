import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/palette.dart';

class EditProfile extends ConsumerStatefulWidget {
  const EditProfile({super.key});

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
          /*InkWell(
            onTap: () {
              log("CircleButtonPressed");
            },
            child: Container(
              
              width: 100.0,
              height: 100.0,
'assets/images/default_header.jpg',
/*image: DecorationImage(
      image: NetworkImage('<https://example.com/image.jpg>'),
      fit: BoxFit.cover,*/

              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromARGB(218, 33, 149, 243),
              ),
              child: Icon(Icons.add),
            ),
          ),*/

          SizedBox(
            height: (MediaQuery.of(context).size.height / 6) + 60,
            child: Stack(
              children: <Widget>[
                InkWell(
                  onTap: () {
                    log("Header Pressed");
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height / 6,
                    decoration: const BoxDecoration(
                      //shape: BoxShape.circle,
                      color: Palette.darkGray,
                    ),
                  ),
                ),
                Positioned(
                  top: 90,
                  left: MediaQuery.of(context).size.width / 6,
                  child: InkWell(
                    onTap: () {
                      log("CircleButtonPressed");
                    },
                    child: Container(
                      //padding: const EdgeInsets.only(bottom: 20.0),
                      alignment: Alignment.bottomLeft,
                      width: 100.0,
                      height: 100.0,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Palette.darkGray,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /* InkWell(
            onTap: () {
              log("Header Pressed");
            },
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 6,
              decoration: BoxDecoration(
                //shape: BoxShape.circle,
                image: DecorationImage(
                  image: new AssetImage("assets/images/default_header.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              log("CircleButtonPressed");
            },
            child: Container(
              alignment: Alignment.bottomLeft,
              width: 100.0,
              height: 100.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: new AssetImage("assets/images/default_header.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),*/
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
          const TextField(
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
          Column(
            children: <Widget>[
              SizedBox(
                width: double.infinity,
                child: Container(
                  /// color: Colors.red,
                  child: Text(
                    "Bio",
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
          const TextField(
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
          Column(
            children: <Widget>[
              SizedBox(
                width: double.infinity,
                child: Container(
                  /// color: Colors.red,
                  child: Text(
                    "Location",
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
          const TextField(
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
          Column(
            children: <Widget>[
              SizedBox(
                width: double.infinity,
                child: Container(
                  /// color: Colors.red,
                  child: Text(
                    "Website",
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
          const TextField(
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
          Column(
            children: <Widget>[
              SizedBox(
                width: double.infinity,
                child: Container(
                  /// color: Colors.red,
                  child: Text(
                    "Birth date",
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
          const TextField(
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
          Column(
            children: <Widget>[
              SizedBox(
                width: double.infinity,
                child: Container(
                  /// color: Colors.red,
                  child: Text(
                    "Pronouns",
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
          const TextField(
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
          TextButton(onPressed: () => {readText()}, child: const Text("Go"))
        ],
      ),
    );
  }
}
