import 'package:camelus/config/palette.dart';
import 'package:camelus/providers/relay_provider.dart';
import 'package:camelus/services/nostr/relays/my_relay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class RelaysPage extends ConsumerStatefulWidget {
  const RelaysPage({super.key});

  @override
  ConsumerState<RelaysPage> createState() => _RelaysPageState();
}

class _RelaysPageState extends ConsumerState<RelaysPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var myRelays = ref.watch(relayServiceProvider);
    return Scaffold(
      backgroundColor: Palette.background,
      body: SafeArea(
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 4.0),
            // close x icon
            Padding(
              padding: const EdgeInsets.fromLTRB(18.0, 16.0, 0.0, 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // big text title
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, top: 4),
                    child: Text("relays",
                        style: TextStyle(
                          color: Palette.white,
                          fontSize: 38.0,
                          fontWeight: FontWeight.w500,
                        )),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 18.0),
                      child: SvgPicture.asset(
                        'assets/icons/x.svg',
                        color: Palette.white,
                        height: 27,
                        width: 27,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Center(
              child: Text('Relays'),
            ),
            //const SizedBox(height: 30.0),

            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 0.0),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 140,
                child: Column(
                  children: [
                    StreamBuilder<List<MyRelay>>(
                      initialData: myRelays.relays,
                      stream: myRelays.relaysStream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        return SizedBox(
                          height: MediaQuery.of(context).size.height - 400,
                          child: ListView.builder(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        snapshot.data![index].relayUrl,
                                        style: const TextStyle(
                                          color: Palette.white,
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 12.0),
                                      Expanded(
                                        child: Text(
                                          "conn: ${snapshot.data![index].connected.toString()}",
                                          textAlign: TextAlign.start,
                                          style: const TextStyle(
                                            color: Palette.white,
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12.0),
                                    ],
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                      "read ${snapshot.data![index].read.toString()}",
                                      style: const TextStyle(
                                        color: Palette.white,
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w400,
                                      )),
                                  Text(
                                      "write ${snapshot.data![index].write.toString()}",
                                      style: const TextStyle(
                                        color: Palette.white,
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w400,
                                      )),
                                  Text(
                                      "persistance ${snapshot.data![index].persistance.toString()}",
                                      style: const TextStyle(
                                        color: Palette.white,
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                      )),
                                  const SizedBox(height: 25.0),
                                ],
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 60.0),
                    _explainerText(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _explainerText() {
  return const Padding(
    padding: EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 30.0),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "dynamic:",
              style: TextStyle(
                color: Palette.gray,
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 12.0),
            Expanded(
              child: Text(
                textAlign: TextAlign.start,
                'camelus uses data on your device to determine the relays that cover the most users you are following. Therefore using less data and battery. This mode is also called gossip',
                style: TextStyle(
                  color: Palette.gray,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "static:",
              style: TextStyle(
                color: Palette.gray,
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 30.0),
            Expanded(
              child: Text(
                textAlign: TextAlign.start,
                'the relays you manually selected. If the gossip model works fine for you only enable these as write relays',
                style: TextStyle(
                  color: Palette.gray,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "failing:",
              style: TextStyle(
                color: Palette.gray,
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 27.0),
            Expanded(
              child: Text(
                textAlign: TextAlign.start,
                'relays that failed to connect',
                style: TextStyle(
                  color: Palette.gray,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        )
      ],
    ),
  );
}
