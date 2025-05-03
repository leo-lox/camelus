import 'package:camelus/config/palette.dart';
import 'package:camelus/presentation_layer/providers/ndk_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/entities.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
    final ndk = ref.watch(ndkProvider);

    return Scaffold(
      backgroundColor: Palette.background,
      body: SafeArea(
        child: StreamBuilder<Map<String, RelayConnectivity>>(
          stream: ndk.relays.relayConnectivityChanges,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              final relaysMap = snapshot.data!;
              final entries = relaysMap.entries.toList();

              return ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final url = entry.key;
                  final relay = entry.value;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: ListTile(
                      title: Text("$url - ${relay.relayInfo?.name}"),
                      leading: relay.relayInfo?.icon != null
                          ? Image.network(
                              "${relay.relayInfo?.icon}",
                              width: 40,
                              errorBuilder: (context, error, stackTrace) {
                                return SizedBox(
                                  width: 40,
                                  height: 40,
                                );
                              },
                            )
                          : SizedBox(
                              width: 40,
                              height: 40,
                            ),
                      subtitle: Text(
                          'events read: ${relay.stats.eventsRead} | events write ${relay.stats.eventsWritten} '),
                      trailing: Icon(
                        relay.isConnected
                            ? PhosphorIcons.plugsConnected()
                            : PhosphorIcons.plugs(),
                        color:
                            relay.isConnected ? Palette.primary : Palette.warn,
                      ),
                    ),
                  );
                },
              );
            }

            return const Center(child: Text("No data available"));
          },
        ),
      ),
    );
  }
}
