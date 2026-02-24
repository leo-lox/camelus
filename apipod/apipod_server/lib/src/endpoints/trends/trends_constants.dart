const int trendsDefaultTopK = 100;
const Duration trendsBucketDuration = Duration(minutes: 5);
const int trendsMaxHashtagsPerEvent = 10;

const Map<String, Duration> trendsIntervals = {
  '4h': Duration(hours: 4),
  '6h': Duration(hours: 6),
  '12h': Duration(hours: 12),
  '24h': Duration(hours: 24),
};

const Set<String> trendsHashtagDenylist = {
  'airdrop',
  'nsfw',
  'porn',
  'nude',
};

String trendsCacheKey(String interval) => 'trends:$interval';
