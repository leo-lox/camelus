import 'dart:developer';

import 'package:camelus/config/palette.dart';
import 'package:camelus/models/socket_control.dart';
import 'package:camelus/services/nostr/relays/relays.dart';
import 'package:camelus/services/nostr/relays/relays_injector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class RelaysPage extends StatefulWidget {
  late Relays _relaysService;
  RelaysPage({Key? key}) : super(key: key) {
    RelaysInjector injector = RelaysInjector();
    _relaysService = injector.relays;
  }

  @override
  State<RelaysPage> createState() => _RelaysPageState();
}

class _RelaysPageState extends State<RelaysPage> {
  @override
  Widget build(BuildContext context) {
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
                height: MediaQuery.of(context).size.height - 110,
                child: ListView(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('dynamic',
                            style: TextStyle(
                              color: Palette.white,
                              fontSize: 28.0,
                              fontWeight: FontWeight.w500,
                            )),
                        SizedBox(width: 8.0),
                        Text("read",
                            style: TextStyle(
                              color: Palette.lightGray,
                              fontSize: 16.0,
                            )),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    _dynamicRelays(widget._relaysService),
                    const SizedBox(height: 30.0),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('static/manual',
                            style: TextStyle(
                              color: Palette.white,
                              fontSize: 28.0,
                              fontWeight: FontWeight.w500,
                            )),
                        SizedBox(width: 8.0),
                        Text("write",
                            style: TextStyle(
                              color: Palette.lightGray,
                              fontSize: 16.0,
                            )),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    _staticRelays(),
                    const SizedBox(height: 30.0),
                    const Text('failing',
                        style: TextStyle(
                          color: Palette.white,
                          fontSize: 28.0,
                          fontWeight: FontWeight.w500,
                        )),
                    const SizedBox(height: 8.0),
                    _failingRelays(),
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

Widget _dynamicRelays(Relays relaysService) {
  // define the number of columns and rows
  int columnCount = 3;
  int rowCount = relaysService.relayAssignments.length;

// create a list to hold the rows
  List<TableRow> rows = [];

// create the first row with labels
  List<Widget> labelRow = const [
    Text('relay', style: TextStyle(color: Palette.white)),
    Text('events', style: TextStyle(color: Palette.white)),
    Text('coverage', style: TextStyle(color: Palette.white))
  ];

  rows.add(TableRow(children: labelRow));

// create the remaining rows with data
  for (int i = 0; i < rowCount; i++) {
    List<Widget> dataRow = [];
    String relayUrl = relaysService.relayAssignments[i].relayUrl;
    dataRow.add(Text(relayUrl, style: const TextStyle(color: Palette.white)));

    for (int j = 1; j < columnCount; j++) {
      if (j == 1) {
        Iterable<SocketControl> tmp = relaysService.connectedRelaysRead.values;
        var socketReceivedEventsCount = -1;
        try {
          socketReceivedEventsCount = tmp
              .singleWhere((element) => element.connectionUrl == relayUrl)
              .socketReceivedEventsCount;
        } catch (e) {
          //log('error: $e');
        }

        dataRow.add(Text('$socketReceivedEventsCount',
            style: const TextStyle(color: Palette.white)));
      } else if (j == 2) {
        dataRow.add(Text('${relaysService.relayAssignments[i].pubkeys.length}',
            style: const TextStyle(color: Palette.white)));
      }
    }
    rows.add(TableRow(children: dataRow));
  }

// create the table with the generated rows
  return Table(
    border: TableBorder.all(color: Palette.gray, width: 1.0),
    columnWidths: {
      0: const FlexColumnWidth(4),
      for (int i = 1; i < columnCount; i++) i: FlexColumnWidth(1),
    },
    children: rows,
  );
}

Widget _staticRelays() {
  // define the number of columns and rows
  int columnCount = 5;
  int rowCount = 2;

// create a list to hold the rows
  List<TableRow> rows = [];

  List<Widget> labelRow = const [
    Text('relay', style: TextStyle(color: Palette.white)),
    Text('events', style: TextStyle(color: Palette.white)),
    Text('coverage', style: TextStyle(color: Palette.white)),
    Text('read', style: TextStyle(color: Palette.white)),
    Text('write', style: TextStyle(color: Palette.white)),
  ];

  rows.add(TableRow(children: labelRow));

// create the remaining rows with data
  for (int i = 0; i < rowCount; i++) {
    List<Widget> dataRow = [];
    dataRow.add(Text('Row $i', style: const TextStyle(color: Palette.white)));

    for (int j = 1; j < columnCount; j++) {
      if (j == 1) {
        dataRow
            .add(Text('$j -a', style: const TextStyle(color: Palette.white)));
      } else if (j == 2) {
        dataRow
            .add(Text('$j -b', style: const TextStyle(color: Palette.white)));
      } else if (j == 3) {
        dataRow
            .add(Text('$j -c', style: const TextStyle(color: Palette.white)));
      } else if (j == 4) {
        dataRow
            .add(Text('$j -d', style: const TextStyle(color: Palette.white)));
      }
    }
    rows.add(TableRow(children: dataRow));
  }

// create the table with the generated rows
  return Table(
    border: TableBorder.all(color: Palette.gray, width: 1.0),
    defaultVerticalAlignment: TableCellVerticalAlignment.top,
    columnWidths: {
      0: const FlexColumnWidth(4),
      for (int i = 1; i < columnCount; i++) i: FlexColumnWidth(1),
    },
    children: rows,
  );
}

Widget _failingRelays() {
  // define the number of columns and rows
  int columnCount = 4;
  int rowCount = 2;

// create a list to hold the rows
  List<TableRow> rows = [];

// create the first row with labels
  List<Widget> labelRow = const [
    Text('relay', style: TextStyle(color: Palette.white)),
    Text('events', style: TextStyle(color: Palette.white)),
    Text('coverage', style: TextStyle(color: Palette.white)),
    Text('static/dynamic', style: TextStyle(color: Palette.white)),
  ];

  rows.add(TableRow(children: labelRow));

// create the remaining rows with data
  for (int i = 0; i < rowCount; i++) {
    List<Widget> dataRow = [];
    dataRow.add(Text('Row $i', style: const TextStyle(color: Palette.white)));

    for (int j = 1; j < columnCount; j++) {
      if (j == 1) {
        dataRow
            .add(Text('$j -a', style: const TextStyle(color: Palette.white)));
      } else if (j == 2) {
        dataRow
            .add(Text('$j -b', style: const TextStyle(color: Palette.white)));
      } else if (j == 3) {
        dataRow
            .add(Text('$j -c', style: const TextStyle(color: Palette.white)));
      }
    }
    rows.add(TableRow(children: dataRow));
  }

// create the table with the generated rows
  return Table(
    border: TableBorder.all(color: Palette.gray, width: 1.0),
    defaultVerticalAlignment: TableCellVerticalAlignment.top,
    columnWidths: {
      0: const FlexColumnWidth(4),
      for (int i = 1; i < columnCount; i++) i: FlexColumnWidth(1),
    },
    children: rows,
  );
}

Widget _explainerText() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 30.0),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
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
        const SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
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
        const SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
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
