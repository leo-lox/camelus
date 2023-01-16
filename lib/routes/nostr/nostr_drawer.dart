import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:camelus/atoms/my_profile_picture.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/services/nostr/nostr_injector.dart';
import 'package:camelus/services/nostr/nostr_service.dart';

class NostrDrawer extends StatelessWidget {
  late NostrService _nostrService;

  NostrDrawer({Key? key}) : super(key: key) {
    NostrServiceInjector injector = NostrServiceInjector();
    _nostrService = injector.nostrService;
  }

  void navigateToProfile(BuildContext context) {
    Navigator.pushNamed(context, "/nostr/profile",
        arguments: _nostrService.myKeys.publicKey);
  }

  Widget _drawerHeader(context) {
    return DrawerHeader(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => navigateToProfile(context),
              child: Container(
                decoration: const BoxDecoration(
                  color: Palette.primary,
                  shape: BoxShape.circle,
                ),
                child: FutureBuilder<Map>(
                    future: _nostrService
                        .getUserMetadata(_nostrService.myKeys.publicKey),
                    builder:
                        (BuildContext context, AsyncSnapshot<Map> snapshot) {
                      var picture = "";

                      if (snapshot.hasData) {
                        picture = snapshot.data?["picture"] ??
                            "https://avatars.dicebear.com/api/personas/${_nostrService.myKeys.publicKey}.svg";
                      } else if (snapshot.hasError) {
                        picture =
                            "https://avatars.dicebear.com/api/personas/${_nostrService.myKeys.publicKey}.svg";
                      } else {
                        // loading
                        picture =
                            "https://avatars.dicebear.com/api/personas/${_nostrService.myKeys.publicKey}.svg";
                      }
                      return myProfilePicture(
                          picture, _nostrService.myKeys.publicKey);
                    }),
              ),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          GestureDetector(
            onTap: () => navigateToProfile(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<Map>(
                        future: _nostrService
                            .getUserMetadata(_nostrService.myKeys.publicKey),
                        builder: (BuildContext context,
                            AsyncSnapshot<Map> snapshot) {
                          var name = "";
                          var nip05 = "";

                          if (snapshot.hasData) {
                            name = snapshot.data?["name"] ?? "";
                            nip05 = snapshot.data?["nip05"] ?? "";
                          } else if (snapshot.hasError) {
                            name = "error";
                            nip05 = "error";
                          } else {
                            // loading
                            name = "loading";
                            nip05 = "loading";
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                    color: Palette.extraLightGray,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Text(
                                nip05,
                                style: const TextStyle(
                                  color: Palette.gray,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          );
                        }),
                  ],
                ),
                //Icon(
                //  Icons.arrow_drop_down_rounded,
                //  color: Palette.primary,
                //  size: 30,
                //)
              ],
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          Row(
            children: [
              RichText(
                  text: const TextSpan(
                      text: 'n.a.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Palette.extraLightGray,
                      ),
                      children: [
                    TextSpan(
                      text: 'Following  ',
                      style: TextStyle(
                          color: Palette.gray,
                          fontSize: 13,
                          fontWeight: FontWeight.normal),
                    )
                  ])),
              const SizedBox(
                width: 6,
              ),
              RichText(
                  text: const TextSpan(
                      text: 'n.a.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Palette.extraLightGray,
                      ),
                      children: [
                    TextSpan(
                      text: 'Followers',
                      style: TextStyle(
                          color: Palette.gray,
                          fontSize: 13,
                          fontWeight: FontWeight.normal),
                    )
                  ])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({icon, label, onTap}) {
    return ListTile(
      onTap: onTap,
      leading: SvgPicture.asset(
        icon,
        height: 25,
        color: Palette.gray,
      ),
      title: Text(label,
          style: const TextStyle(color: Palette.lightGray, fontSize: 17)),
    );
  }

  Widget _textButton({text, onPressed}) {
    return TextButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(color: Palette.extraLightGray, fontSize: 16),
        ));
  }

  Widget _divider() {
    return const Divider(
      thickness: 0.3,
      color: Palette.darkGray,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Palette.background,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _drawerHeader(context),
            _divider(),
            _drawerItem(
                label: 'Profile',
                icon: 'assets/icons/user.svg',
                onTap: () {
                  navigateToProfile(context);
                }),
            _drawerItem(
                label: 'Bookmarks',
                icon: 'assets/icons/bookmark-simple.svg',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Not implemented yet'),
                    ),
                  );
                }),
            _drawerItem(
                label: 'Payments',
                icon: 'assets/icons/lightning.svg',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Not implemented yet'),
                    ),
                  );
                }),
            _drawerItem(
                label: 'Blocklist',
                icon: 'assets/icons/yin-yang.svg',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Not implemented yet'),
                    ),
                  );
                }),
            const Spacer(),
            const Spacer(),
            _divider(),
            Padding(
                padding: const EdgeInsets.only(left: 20),
                child: _textButton(text: 'Settings', onPressed: () {})),
            const SizedBox(height: 10),
            Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 15, 20),
                child: _textButton(text: 'contact', onPressed: () {})),
            const Spacer(),
            _divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 15, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset(
                    'assets/icons/sun.svg',
                    color: Palette.primary,
                    height: 22,
                    width: 22,
                  ),
                  SvgPicture.asset(
                    'assets/icons/qr-code.svg',
                    color: Palette.primary,
                    height: 22,
                    width: 22,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
