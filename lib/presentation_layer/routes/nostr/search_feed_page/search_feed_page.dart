import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../domain_layer/entities/feed_filter.dart';
import '../../../components/generic_feed.dart';
import '../../../components/search_bar.dart';

class SearchFeedPage extends StatefulWidget {
  final String query;

  const SearchFeedPage({super.key, required this.query});

  @override
  State<SearchFeedPage> createState() => _SearchFeedPageState();
}

class _SearchFeedPageState extends State<SearchFeedPage> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  late String _currentQuery;

  @override
  void initState() {
    super.initState();
    _currentQuery = widget.query;
    _searchController = TextEditingController(text: widget.query);
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // real time search
  }

  void _onSubmit(String value) {
    if (value.trim().isNotEmpty && value.trim() != _currentQuery) {
      // Navigate to a new SearchFeedPage with the new query
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              SearchFeedPage(query: value.trim()),
          // no animation
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  void _helpSearch(BuildContext context) {
    // Implement your help functionality here
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Help'),
        content: const Text('Enter keywords to search for posts.'),
        backgroundColor: Palette.darkGray,
        titleTextStyle: const TextStyle(color: Palette.white, fontSize: 18),
        contentTextStyle: const TextStyle(color: Palette.white),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Palette.primary)),
          ),
        ],
      ),
    );
  }

  FeedFilter _buildFeedFilter(String query) {
    if (query.startsWith('#')) {
      return FeedFilter(
        feedId: "hashtag-feed-${query.substring(1)}",
        kinds: [1, 6],
        tTags: [query.substring(1).toLowerCase()],
      );
    }

    return FeedFilter(
      feedId: "search-feed-$query",
      kinds: [1, 6],
      search: query,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      body: SafeArea(
        child: Column(
          children: [
            SearchBarWidget(
              onSearchChanged: _onSearchChanged,
              onSubmit: _onSubmit,
              helpSearch: _helpSearch,
              externalFocusNode: _searchFocusNode,
              externalController: _searchController,
              leading: IconButton(
                icon: Icon(PhosphorIcons.arrowLeft()),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            Expanded(
              child: GenericFeed(
                feedFilter: _buildFeedFilter(_currentQuery),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
