class FeedFilter {
  // feed id is included in the query to better track errors
  String feedId;

  /// List of event IDs to filter by.
  List<String>? ids;

  /// List of author public keys to filter by.
  List<String>? authors;

  /// List of event kinds to filter by.
  List<int>? kinds;

  /// Text to search for in event content.
  String? search;

  /// List of event tags to filter by.
  List<String>? eTags;

  /// List of pubkey tags to filter by.
  List<String>? pTags;

  /// List of hashtag tags to filter by.
  List<String>? tTags;

  /// List of replaceable event tags to filter by.
  List<String>? aTags;

  List<String>? dTags; // d tags

  FeedFilter({
    required this.feedId,
    this.ids,
    this.authors,
    this.kinds,
    this.eTags,
    this.pTags,
    this.tTags,
    this.aTags,
    this.dTags,
  });
}
