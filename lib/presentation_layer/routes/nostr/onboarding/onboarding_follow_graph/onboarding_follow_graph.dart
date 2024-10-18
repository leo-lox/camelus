import 'package:camelus/presentation_layer/atoms/long_button.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/domain_layer/entities/onboarding_user_info.dart';
import 'package:camelus/presentation_layer/providers/following_provider.dart';
import 'package:camelus/presentation_layer/providers/metadata_provider.dart';
import 'package:camelus/presentation_layer/routes/nostr/onboarding/onboarding_follow_graph/graph_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_force_directed_graph/flutter_force_directed_graph.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'graph_node_data.dart';

class OnboardingFollowGraph extends ConsumerStatefulWidget {
  final Function submitCallback;

  final OnboardingUserInfo userInfo;

  const OnboardingFollowGraph({
    super.key,
    required this.submitCallback,
    required this.userInfo,
  });
  @override
  ConsumerState<OnboardingFollowGraph> createState() =>
      _OnboardingFollowGraphState();
}

class _OnboardingFollowGraphState extends ConsumerState<OnboardingFollowGraph> {
  // npubs in hex
  final List<String> recommendations = [
    '717ff238f888273f5d5ee477097f2b398921503769303a0c518d06a952f2a75e',
    '84dee6e676e5bb67b4ad4e042cf70cbd8681155db535942fcc6a0533858a7240',
    '30782a8323b7c98b172c5a2af7206bb8283c655be6ddce11133611a03d5f1177',
    '76c71aae3a491f1d9eec47cba17e229cda4113a0bbb6e6ae1776d7643e29cafa'
  ];

  late final ForceDirectedGraphController<GraphNodeData> _graphController =
      ForceDirectedGraphController(
    graph: ForceDirectedGraph(
        config: const GraphConfig(
      length: 200,
    )),
  )..setOnScaleChange((scale) {
          // can use to optimize the performance
          // if scale is too small, can use simple node and edge builder to improve performance
          if (!mounted) return;
          setState(() {
            _scale = scale;
          });
        });

  final Set<GraphNodeData> _nodes = {};
  final Map<String, String> _edges = {};
  double _scale = 1.0;
  int _locatedTo = 0;
  GraphNodeData? _draggingData;

  addNode(GraphNodeData data) async {
    // add data

    _graphController.addNode(data);

    // add edges
    for (final existingNode in _nodes) {
      final contacts = existingNode.contactList.contacts;

      // check if pubkey data.pubkey is in contacts

      final match = contacts.any((c) => c == data.pubkey);

      // check if the edge already exists

      final exists = _edges.entries.any((e) =>
          e.key == data.pubkey && e.value == existingNode.pubkey ||
          e.key == existingNode.pubkey && e.value == data.pubkey);

      if (match && !exists) {
        _graphController.addEdgeByData(data, existingNode);

        // update outside representation
        _edges[data.pubkey] = existingNode.pubkey;
      }
    }

    // update outside representation
    _nodes.add(data);
  }

  /// fetches and adds a node to the graph
  addPubkeyNode(String pubkey) async {
    final mynode = await _fetchNodePubkeyData(pubkey);
    addNode(mynode);
  }

  _addRecommendations() async {
    final List<GraphNodeData> recommendationsNodes = [];

    for (final pubkey in recommendations) {
      final GraphNodeData mynode = await _fetchNodePubkeyData(pubkey);

      recommendationsNodes.add(mynode);
    }
    for (final node in recommendationsNodes) {
      addNode(node);
    }
  }

  Future<GraphNodeData> _fetchNodePubkeyData(String pubkey) async {
    final metadataP = ref.watch(metadataProvider);
    final followP = ref.watch(followingProvider);

    final metadata =
        (await metadataP.getMetadataByPubkey(pubkey).toList()).first;
    final followInfo = await followP.getContacts(pubkey);

    final GraphNodeData mynode = GraphNodeData(
      pubkey: pubkey,
      userMetadata: metadata,
      contactList: followInfo,
    );
    return mynode;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _graphController.needUpdate();
    });
    //_addRecommendations();
  }

  @override
  void dispose() {
    _graphController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: ForceDirectedGraphWidget(
                controller: _graphController,
                onDraggingStart: (data) {
                  setState(() {
                    _draggingData = data;
                  });
                },
                onDraggingEnd: (data) {
                  setState(() {
                    _draggingData = null;
                  });
                },
                onDraggingUpdate: (data) {},
                nodesBuilder: (context, data) {
                  final Color color;
                  bool _isLarge = false;
                  if (_draggingData == data) {
                    color = Colors.yellow;
                    _isLarge = true;
                  } else if (_nodes.contains(data)) {
                    color = Colors.green;
                  } else {
                    color = Colors.red;
                  }

                  return GestureDetector(
                    onTap: () {
                      print("onTap $data");
                      setState(() {
                        data.selected = !data.selected;
                        // if (_nodes.contains(data)) {
                        //   _nodes.remove(data);
                        // } else {
                        //   _nodes.add(data);
                        // }
                      });
                    },
                    child: AnimatedContainer(
                      width: 250,
                      height: 84,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: Palette.extraDarkGray,
                        border: Border.all(
                          color:
                              data.selected ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: _scale > 0.5
                          ? GraphProfile(metadata: data.userMetadata)
                          : null,
                    ),
                  );
                },
                edgesBuilder: (context, a, b, distance) {
                  final Color color;

                  return GestureDetector(
                    onTap: () {
                      final edge = "$a <-> $b";
                      setState(() {
                        print("onTap $a <-$distance-> $b");
                      });
                    },
                    child: Container(
                      width: distance,
                      height: 2,
                      color: Palette.gray,
                      alignment: Alignment.center,
                      child: _scale > 0.5
                          ? Text(
                              '${a.userMetadata.name} <-> ${b.userMetadata.name}')
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Slider(
              value: _scale,
              min: _graphController.minScale,
              max: _graphController.maxScale,
              onChanged: (value) {
                _graphController.scale = value;
              },
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              width: 400,
              height: 40,
              child: longButton(
                name: "next",
                onPressed: (() {
                  _addRecommendations();
                  widget.submitCallback();
                }),
                inverted: true,
              ),
            ),
            const SizedBox(
              height: 15,
            ),
          ],
        ),
      ),
    );
  }
}
