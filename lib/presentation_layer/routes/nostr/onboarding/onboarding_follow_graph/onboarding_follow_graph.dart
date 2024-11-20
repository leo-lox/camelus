import 'dart:math';

import 'package:camelus/presentation_layer/atoms/long_button.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/domain_layer/entities/onboarding_user_info.dart';
import 'package:camelus/presentation_layer/atoms/my_profile_picture.dart';
import 'package:camelus/presentation_layer/providers/following_provider.dart';
import 'package:camelus/presentation_layer/providers/metadata_provider.dart';
import 'package:camelus/presentation_layer/routes/nostr/onboarding/onboarding_follow_graph/graph_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_force_directed_graph/flutter_force_directed_graph.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../config/onboard_conf.dart';
import '../../../../../domain_layer/entities/contact_list.dart';
import 'graph_node_data.dart';

class OnboardingFollowGraph extends ConsumerStatefulWidget {
  final Function(List<String>) submitCallback;

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
  bool _loading = true;

  final followedList = <String>[];
  final int followTarget = 5;

  late final ForceDirectedGraphController<GraphNodeData> _graphController =
      ForceDirectedGraphController(
    graph: ForceDirectedGraph(
        config: const GraphConfig(
      length: 200,
      elasticity: 0.5,
      // maxStaticFriction: 20,
      repulsionRange: 250,
      repulsion: 70,
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

  /// if addedBy Pubkey drawas a edge to the old and new node
  addNode(GraphNodeData data, {String? addedByPubkey}) async {
    // add data

    _graphController.addNode(data);

    if (addedByPubkey != null) {
      try {
        final rootNode = _graphController.graph.nodes
            .firstWhere((data) => data.data.pubkey == addedByPubkey);

        _graphController.addEdgeByData(data, rootNode.data);
        _edges[data.pubkey] = rootNode.data.pubkey;
      } catch (_) {}
    }

    _nodes.add(data);
  }

  /// adds all the contacts (with cutoff) from a given pubkey (from node)
  addContactsOfPubkey(String pubkey, {int cutoff = 3}) async {
    final List<String> contacts =
        _nodes.firstWhere((n) => n.pubkey == pubkey).contactList.contacts;

    for (int i = 0; i < contacts.length; i++) {
      if (i > cutoff) {
        break;
      }

      // skip if node already exists
      if (_nodes.any((n) => n.pubkey == contacts[i])) {
        continue;
      }

      // add node to graph

      await addPubkeyNode(contacts[i], addedByPubkey: pubkey);
    }
  }

  /// removes the subtree
  removeAncestors(String pubkey) {
    final pubkeyNode = _nodes.firstWhere((n) => n.pubkey == pubkey);

    final List<GraphNodeData> ancestors = [];

    // delete by traversing through the subgraph using a for loop in _edges
    for (final edge in _edges.entries) {
      if (edge.value == pubkey) {
        ancestors.add(_nodes.firstWhere((n) => n.pubkey == edge.key));
      }
    }

    // delete all edges and nodes
    // delete the edges first, then the nodes
    // delete the edges in reverse order to avoid deleting edges that are not in the graph anymore
    ancestors.sort((a, b) => b.pubkey.compareTo(a.pubkey));

    for (final ancestorNode in ancestors) {
      if (ancestorNode.selected) continue;
      _graphController.deleteEdgeByData(pubkeyNode, ancestorNode);

      _graphController.deleteNodeByData(ancestorNode);
      _nodes.remove(ancestorNode);
    }
  }

  /// fetches and adds a node to the graph
  addPubkeyNode(String pubkey, {String? addedByPubkey}) async {
    try {
      _fetchNodePubkeyData(pubkey).then((mynode) {
        addNode(mynode, addedByPubkey: addedByPubkey);
      });
    } catch (e) {
      print("error adding node $pubkey");
    }
  }

  _addRecommendations() async {
    final List<GraphNodeData> recommendationsNodes = [];

    for (final pubkey in ONBOARD_RECOMMANDATIONS) {
      try {
        final GraphNodeData mynode = await _fetchNodePubkeyData(pubkey);

        recommendationsNodes.add(mynode);
      } catch (_) {}
    }
    for (final node in recommendationsNodes) {
      addNode(node);
    }
    setState(() {
      _loading = false;
    });
  }

  Future<GraphNodeData> _fetchNodePubkeyData(String pubkey) async {
    final metadataP = ref.watch(metadataProvider);
    final followP = ref.watch(followingProvider);

    final metadata =
        (await metadataP.getMetadataByPubkey(pubkey).toList()).first;
    ContactList? followInfo = await followP.getContacts(pubkey);

    // replace with empty contact list if null
    followInfo ??= ContactList(
      pubKey: pubkey,
      contacts: [],
      contactRelays: [],
      createdAt: 0,
      followedCommunities: [],
      followedEvents: [],
      followedTags: [],
      loadedTimestamp: 0,
      petnames: [],
      sources: [],
    );

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
      _addRecommendations();
    });
  }

  @override
  void dispose() {
    _graphController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double miniViewCutoff = 0.35;
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

                  if (_draggingData == data) {
                    color = Colors.yellow;
                  } else if (_nodes.contains(data)) {
                    color = Colors.green;
                  } else {
                    color = Colors.red;
                  }

                  return GestureDetector(
                    key: ValueKey(data.pubkey),
                    onTap: () {
                      setState(() {
                        data.selected = !data.selected;
                        if (data.selected) {
                          followedList.add(data.pubkey);
                          addContactsOfPubkey(data.pubkey, cutoff: 3);
                        } else {
                          followedList.remove(data.pubkey);
                          removeAncestors(data.pubkey);
                        }
                      });
                    },
                    child: AnimatedContainer(
                        width: _scale > miniViewCutoff ? 250 : 60,
                        height: _scale > miniViewCutoff ? 84 : 60,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: Palette.extraDarkGray,
                          border: Border.all(
                            color: data.selected
                                ? Colors.white
                                : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: _scale > miniViewCutoff
                            ? GraphProfile(metadata: data.userMetadata)
                            : UserImage(
                                imageUrl: data.userMetadata.picture,
                                pubkey: data.userMetadata.pubkey,
                                filterQuality: FilterQuality.low,
                                disableGif: true,
                              )),
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
                      color: Palette.darkGray,
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
              inactiveColor: Palette.extraDarkGray,
              activeColor: Palette.lightGray,
              value: _scale,
              min: _graphController.minScale,
              max: 1.0,
              onChanged: (value) {
                _graphController.scale = value;
              },
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              width: 400,
              height: 40,
              child: longButton(
                loading: _loading,
                disabled: followedList.length < followTarget,
                name: "follow ${followedList.length}/$followTarget",
                onPressed: (() {
                  widget.submitCallback(followedList);
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
