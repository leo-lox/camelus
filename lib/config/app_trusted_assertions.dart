// ignore_for_file: constant_identifier_names

import 'package:ndk/entities.dart';

/// Default relay for NIP-85 trusted assertions
const String DEFAULT_NIP85_RELAY = 'ws://localhost:3334';

/// Default trusted providers for NIP-85 assertions
const List<Nip85TrustedProvider> APP_DEFAULT_NIP85_PROVIDERS = [
  // ===========================================================================
  // USER METRICS (kind 30382)
  // ===========================================================================
  // Nip85TrustedProvider(
  //   kind: Nip85Kind.user,
  //   metric: Nip85Metric.followers,
  //   pubkey: '3116ea6afb590a19455d7b39ae3317c62b2bbb236986788b7e0ae12ec2281101',
  //   relay: DEFAULT_NIP85_RELAY,
  // ),
  // Nip85TrustedProvider(
  //   kind: Nip85Kind.user,
  //   metric: Nip85Metric.rank,
  //   pubkey: 'cbeb151f3f5c4925c392c2b79936c3acd3c5c73a8ad60173ee6e43ff9112cfe1',
  //   relay: DEFAULT_NIP85_RELAY,
  // ),
  // Nip85TrustedProvider(
  //   kind: Nip85Kind.user,
  //   metric: Nip85Metric.firstCreatedAt,
  //   pubkey: '367afc8744a62f99f0d6aa70b7a5506f57c302aff3ea72cf7cc7346371f82a25',
  //   relay: DEFAULT_NIP85_RELAY,
  // ),
  // Nip85TrustedProvider(
  //   kind: Nip85Kind.user,
  //   metric: Nip85Metric.postCount,
  //   pubkey: 'c3e5ec4ccddc5b8535dab6dd3db3281923ee280f9aea6295ed68b571fc296fbc',
  //   relay: DEFAULT_NIP85_RELAY,
  // ),
  // Nip85TrustedProvider(
  //   kind: Nip85Kind.user,
  //   metric: Nip85Metric.replyCount,
  //   pubkey: '9527682db2b48a7430fcd08750e2f925fc7b8cc2a2cb324239eb136ff06fe712',
  //   relay: DEFAULT_NIP85_RELAY,
  // ),
  // Nip85TrustedProvider(
  //   kind: Nip85Kind.user,
  //   metric: Nip85Metric.reactionsCount,
  //   pubkey: '971c2269983ff452d945e32168486ff258003d5b778acbfe889bda54fc06a0b5',
  //   relay: DEFAULT_NIP85_RELAY,
  // ),
  // Nip85TrustedProvider(
  //   kind: Nip85Kind.user,
  //   metric: Nip85Metric.zapAmountReceived,
  //   pubkey: '91a82c20fc3f020f990aae0c26b6661a91926cb702d9bd9f8f2a2a1cbf72bc22',
  //   relay: DEFAULT_NIP85_RELAY,
  // ),
  // Nip85TrustedProvider(
  //   kind: Nip85Kind.user,
  //   metric: Nip85Metric.zapAmountSent,
  //   pubkey: '86175feae9b938c8a399680c1be162cd47a9aac00e78ab0069b3f7831793ceb2',
  //   relay: DEFAULT_NIP85_RELAY,
  // ),
  // Nip85TrustedProvider(
  //   kind: Nip85Kind.user,
  //   metric: Nip85Metric.zapCountReceived,
  //   pubkey: 'f2066eb230b2fd7937c1e93d98b308de4c1fefa041c17604bd944164cbf8701d',
  //   relay: DEFAULT_NIP85_RELAY,
  // ),
  // Nip85TrustedProvider(
  //   kind: Nip85Kind.user,
  //   metric: Nip85Metric.zapCountSent,
  //   pubkey: '780c6f1e2b531c710bcaf87c25ec9d3e927a2de1a72c3e22ee68077d30430c98',
  //   relay: DEFAULT_NIP85_RELAY,
  // ),
  // Nip85TrustedProvider(
  //   kind: Nip85Kind.user,
  //   metric: Nip85Metric.zapAvgAmountDayReceived,
  //   pubkey: 'a30c5ffee52284e21a7acca7aab8d45ed1f1f5461d802a602e887c7a1f680955',
  //   relay: DEFAULT_NIP85_RELAY,
  // ),
  // Nip85TrustedProvider(
  //   kind: Nip85Kind.user,
  //   metric: Nip85Metric.zapAvgAmountDaySent,
  //   pubkey: '3ee65e119f9d0feaaaa18a001ccfe186bd050e2f4c1e679ae0fbeedfd2f53ca3',
  //   relay: DEFAULT_NIP85_RELAY,
  // ),
  // Nip85TrustedProvider(
  //   kind: Nip85Kind.user,
  //   metric: Nip85Metric.reportsCountReceived,
  //   pubkey: 'e9229572ed302c073ee1e30834f3d964a809532966c2082302574cfa1638931a',
  //   relay: DEFAULT_NIP85_RELAY,
  // ),
  // Nip85TrustedProvider(
  //   kind: Nip85Kind.user,
  //   metric: Nip85Metric.reportsCountSent,
  //   pubkey: 'c7b8bdc6212193586a1a5c5053f0221705a8b9060650b942f0069adbbf77b346',
  //   relay: DEFAULT_NIP85_RELAY,
  // ),
  // Nip85TrustedProvider(
  //   kind: Nip85Kind.user,
  //   metric: Nip85Metric.activeHoursStart,
  //   pubkey: 'e9087d8dbdfe211eb9b6e112aa78d313300a2ac48fa5ef0cbc480fd96c1bd558',
  //   relay: DEFAULT_NIP85_RELAY,
  // ),
  // Nip85TrustedProvider(
  //   kind: Nip85Kind.user,
  //   metric: Nip85Metric.activeHoursEnd,
  //   pubkey: '816548ad83107b9adae3074df90a0faa85004559cda47b8d7da2bafebcd79b05',
  //   relay: DEFAULT_NIP85_RELAY,
  // ),

  // ===========================================================================
  // EVENT METRICS (kind 30383)
  // ===========================================================================
  Nip85TrustedProvider(
    kind: Nip85Kind.event,
    metric: Nip85Metric.commentCount,
    pubkey: 'bc96b59ff2fff7a2597dadcf5bddafb2880169df24c0f9eb7210cdf916d9c620',
    relay: DEFAULT_NIP85_RELAY,
  ),
  Nip85TrustedProvider(
    kind: Nip85Kind.event,
    metric: Nip85Metric.quoteCount,
    pubkey: 'bc96b59ff2fff7a2597dadcf5bddafb2880169df24c0f9eb7210cdf916d9c620',
    relay: DEFAULT_NIP85_RELAY,
  ),
  Nip85TrustedProvider(
    kind: Nip85Kind.event,
    metric: Nip85Metric.repostCount,
    pubkey: 'bc96b59ff2fff7a2597dadcf5bddafb2880169df24c0f9eb7210cdf916d9c620',
    relay: DEFAULT_NIP85_RELAY,
  ),
  Nip85TrustedProvider(
    kind: Nip85Kind.event,
    metric: Nip85Metric.reactionCount,
    pubkey: 'bc96b59ff2fff7a2597dadcf5bddafb2880169df24c0f9eb7210cdf916d9c620',
    relay: DEFAULT_NIP85_RELAY,
  ),
  Nip85TrustedProvider(
    kind: Nip85Kind.event,
    metric: Nip85Metric.zapCount,
    pubkey: 'bc96b59ff2fff7a2597dadcf5bddafb2880169df24c0f9eb7210cdf916d9c620',
    relay: DEFAULT_NIP85_RELAY,
  ),
  Nip85TrustedProvider(
    kind: Nip85Kind.event,
    metric: Nip85Metric.zapAmount,
    pubkey: 'bc96b59ff2fff7a2597dadcf5bddafb2880169df24c0f9eb7210cdf916d9c620',
    relay: DEFAULT_NIP85_RELAY,
  ),

  // ===========================================================================
  // ADDRESSABLE METRICS (kind 30384)
  // ===========================================================================
  // Nip85TrustedProvider(
  //   kind: Nip85Kind.addressable,
  //   metric: Nip85Metric.commentCount,
  //   pubkey: '6352c486e590896220b5964d46225bc57059a90971273ddfa50ed2da6cae8eaa',
  //   relay: DEFAULT_NIP85_RELAY,
  // ),
  // Nip85TrustedProvider(
  //   kind: Nip85Kind.addressable,
  //   metric: Nip85Metric.quoteCount,
  //   pubkey: '35ad1c3d023180e1fd96dece9a51bfeed721dafb0a80e72517f338aae1b1f7de',
  //   relay: DEFAULT_NIP85_RELAY,
  // ),
  // Nip85TrustedProvider(
  //   kind: Nip85Kind.addressable,
  //   metric: Nip85Metric.repostCount,
  //   pubkey: 'b18ceb02a32e73994685ddd2f417d042d88c676e0da715e802b994701c78f61b',
  //   relay: DEFAULT_NIP85_RELAY,
  // ),
  // Nip85TrustedProvider(
  //   kind: Nip85Kind.addressable,
  //   metric: Nip85Metric.reactionCount,
  //   pubkey: '52251a59c4a62b0bd7dc3b3786b7ebf51f9cb6d2907123fc82334e4903612926',
  //   relay: DEFAULT_NIP85_RELAY,
  // ),
  // Nip85TrustedProvider(
  //   kind: Nip85Kind.addressable,
  //   metric: Nip85Metric.zapCount,
  //   pubkey: 'ef072743789afc5cbf93d7862d3be744a4d34562606444f9405062a3cd774971',
  //   relay: DEFAULT_NIP85_RELAY,
  // ),
  // Nip85TrustedProvider(
  //   kind: Nip85Kind.addressable,
  //   metric: Nip85Metric.zapAmount,
  //   pubkey: '2ee673c52e97c5a92815f9d4555365196860121a17a1cc54c06818f5d21c59bf',
  //   relay: DEFAULT_NIP85_RELAY,
  // ),
];
