// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get helloWorld => 'Hello World!';

  @override
  String get whatShouldWeCallYou => 'what should we call you?';

  @override
  String get next => 'next';

  @override
  String get skip => 'skip';

  @override
  String get selectImage => 'select image';

  @override
  String get unsupportedImageFormat => 'unsupported image format';

  @override
  String get invalidPrivateKeyOrSeedPhrase =>
      'Invalid private key or seed phrase';

  @override
  String get pleaseReadAndAcceptTerms =>
      'Please read and accept the terms and conditions first';

  @override
  String get pleaseImportPrivateKeyFirst =>
      'Please import your private key first';

  @override
  String get publicKeyErrorMessage =>
      'you entered a public key, please enter a private key, it starts with nsec1';

  @override
  String wordNotValid(String word) {
    return 'word: $word is not valid, check if it is spelled correctly';
  }

  @override
  String get login => 'login';

  @override
  String get yourPublicKeyIs => 'your public key is:';

  @override
  String get enterSeedPhraseOrNsec => 'enter your seed phrase or nsec1';

  @override
  String get paste => 'paste';

  @override
  String get add => 'add';

  @override
  String get iHaveReadAndAccept => 'I have read and accept the ';

  @override
  String get termsAndConditions => 'terms and conditions';

  @override
  String get privacyPolicy => 'privacy policy';

  @override
  String get settingUpYourAccount => 'setting up your account';

  @override
  String get followingPeople => 'following people';

  @override
  String get movingData => 'moving data';

  @override
  String get cleaningUp => 'cleaning up';

  @override
  String get uploadingProfilePicture => 'uploading profile picture';

  @override
  String get recoveryPhrase => 'recovery phrase';

  @override
  String get newSeedPhraseGenerated => 'a new seed phrase has been generated';

  @override
  String get regenerate => 'regenerate';

  @override
  String get copiedSeedPhraseToClipboard => 'copied seed phrase to clipboard';

  @override
  String get copy => 'copy';

  @override
  String get hideWords => 'Hide words';

  @override
  String get showWords => 'Show words';

  @override
  String get recoveryPhraseWarning =>
      'You need the recovery phrase to login again. Make sure to keep it safe!';

  @override
  String get publishAccount => 'publish account';

  @override
  String get starterPacks => 'Starter Packs';

  @override
  String get additionalStarterPacks => 'Additional Starter Packs';

  @override
  String continueWithAccounts(int count) {
    return 'continue with $count accounts';
  }

  @override
  String get selectStarterPack => 'select a starter pack';

  @override
  String by(String name) {
    return 'by $name';
  }

  @override
  String get unselectAll => 'unselect all';

  @override
  String get followAll => 'follow all';

  @override
  String followAccounts(int count) {
    return 'follow $count accounts';
  }

  @override
  String get invitedYouToJoin => ' invited you to join';

  @override
  String get youWillFollowThesePeople =>
      'You\'ll follow these people right away';

  @override
  String get noStarterPackFound => '👀 no starter pack found ';

  @override
  String get noWorriesYouCanStillJoin =>
      'no worries, you can still join Camelus!';

  @override
  String get joinCamelus => 'Join Camelus';

  @override
  String get signupWithoutStarterPack => 'Signup without a starter pack';

  @override
  String copiedToClipboard(String text) {
    return 'Copied to clipboard: $text';
  }

  @override
  String get shareYourProfile => 'Share your Profile';

  @override
  String get following => 'Following';

  @override
  String get followers => 'Followers';

  @override
  String get profile => 'Profile';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get removeBookmark => 'Remove this bookmark?';

  @override
  String get bookmarkRemoved => 'Bookmark removed';

  @override
  String get noPrivateBookmarks => 'No private bookmarks yet';

  @override
  String get noPublicBookmarks => 'No public bookmarks yet';

  @override
  String get privateBookmarks => 'Private';

  @override
  String get publicBookmarks => 'Public';

  @override
  String get addToBookmarks => 'Add to bookmarks';

  @override
  String get removeFromBookmarks => 'Remove from bookmarks';

  @override
  String get addingToBookmarks => 'Adding to bookmarks...';

  @override
  String get removingFromBookmarks => 'Removing from bookmarks...';

  @override
  String get failedToAddBookmark => 'Failed to add bookmark';

  @override
  String get failedToRemoveBookmark => 'Failed to remove bookmark';

  @override
  String get notImplementedYet => 'Not implemented yet';

  @override
  String get payments => 'Payments';

  @override
  String get blocklist => 'Blocklist';

  @override
  String get settings => 'Settings';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get languageSettings => 'Language Settings';

  @override
  String get initialRoute => 'Initial route';

  @override
  String get moderation => 'Moderation';

  @override
  String get fileServers => 'File servers';

  @override
  String get logout => 'Logout';

  @override
  String get unsavedChanges => 'Unsaved Changes';

  @override
  String get unsavedChangesMessage =>
      'You have unsaved changes. Do you want to discard them?';

  @override
  String get cancel => 'Cancel';

  @override
  String get discard => 'Discard';

  @override
  String get saveChanges => 'save changes';

  @override
  String get saving => 'Saving...';

  @override
  String get changesSavedSuccessfully => 'Changes saved successfully';

  @override
  String get failedToSaveChanges => 'Failed to save changes';

  @override
  String get setupDefaultServers => 'setup default servers';

  @override
  String get defaultLabel => ' (default)';

  @override
  String get restoreDefaults => 'Restore Defaults';

  @override
  String get restoreDefaultsMessage =>
      'Are you sure you want to restore default servers? This will remove all custom servers.';

  @override
  String get restore => 'Restore';

  @override
  String get enterBlossomUrl => 'Enter blossom URL';

  @override
  String errorUpdatingFilter(String error) {
    return 'Error updating filter $error';
  }

  @override
  String get moderationSettings => 'Moderation Settings';

  @override
  String get camelusContentFiltering => 'Camelus Content Filtering';

  @override
  String get enableContentFilteringDescription =>
      'Enable content filtering to hide potentially inappropriate content.';

  @override
  String get enableContentFilter => 'Enable Content Filter';

  @override
  String get contentFilterNote =>
      'Note: Filters are applied locally (on device). When users report nostr content directly to camelus it gets added to the filter.';

  @override
  String get errorUploadingImage =>
      'err uploading image, upload servers configured?';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get save => 'save';

  @override
  String get loadingProfile => 'Loading profile...';

  @override
  String get uploading => 'Uploading...';

  @override
  String get uploadingCapitalized => 'Uploading';

  @override
  String get name => 'Name';

  @override
  String get bio => 'Bio';

  @override
  String get pronouns => 'Pronouns';

  @override
  String get website => 'Website';

  @override
  String get username => 'Username (nip05)';

  @override
  String get lightningAddress => 'Lightning address';

  @override
  String get editRelays => 'Edit Relays';

  @override
  String get error => 'error:';

  @override
  String get whatsOnYourMind => 'What\'s on your mind?';

  @override
  String get writePost => 'write a post';

  @override
  String replyTo(String name) {
    return 'reply to $name';
  }

  @override
  String get addToStarterPack => 'add to starter pack';

  @override
  String get blockReport => 'Block/Report';

  @override
  String get blockedUsers => 'Blocked Users';

  @override
  String get notImplemented => 'not implemented';

  @override
  String get impersonation => 'impersonation';

  @override
  String get spam => 'spam';

  @override
  String get illegal => 'illegal';

  @override
  String get profanity => 'profanity';

  @override
  String get nudity => 'nudity';

  @override
  String get malware => 'malware';

  @override
  String get other => 'other';

  @override
  String get reportSent => 'report sent';

  @override
  String get thankYouForReport => 'thank you for your report';

  @override
  String get goBack => 'go back';

  @override
  String get blockReportTitle => 'block/report';

  @override
  String get user => 'user';

  @override
  String get loading => 'loading';

  @override
  String get unblock => 'unblock';

  @override
  String get block => 'block';

  @override
  String get whatIsWrongWithPost => 'what is wrong with this post?';

  @override
  String get whatIsWrongWithUser => 'what is wrong with this user?';

  @override
  String get reportsAreSentToRelays =>
      'Reports are sent to the relays where you received the note from.';

  @override
  String get additionallyReportToCamelus =>
      'Additionally, report to camelus directly';

  @override
  String get reportPost => 'report post';

  @override
  String get reportUser => 'report user';

  @override
  String get relays => 'Relays';

  @override
  String get eventsRead => 'Events Read';

  @override
  String get eventsWritten => 'Events Written';

  @override
  String get connectionSource => 'Connection Source';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get notifications => 'Notifications';

  @override
  String get searchHelp => 'Search Help';

  @override
  String get searchHelpMessage => 'Enter keywords to search for posts.';

  @override
  String get ok => 'OK';

  @override
  String get thread => 'thread';

  @override
  String get workInProgress => 'work in progress';

  @override
  String get update => 'Update';

  @override
  String get initialRouteSettings => 'Initial Route Settings';

  @override
  String get useSystemLanguage => 'Use System Language';

  @override
  String get edit => 'edit';

  @override
  String get postSettings => 'Post Settings';

  @override
  String get enableContentWarning => 'Enable Content Warning';

  @override
  String get warningType => 'Warning Type:';

  @override
  String get customWarning => 'Custom Warning';

  @override
  String get specifyContentWarning => 'Specify content warning';

  @override
  String get enableClientTag => 'Enable Client Tag';

  @override
  String get close => 'Close';

  @override
  String get sensitiveContent => 'Sensitive Content';

  @override
  String get flashingLights => 'Flashing Lights/Patterns';

  @override
  String get loudNoises => 'Loud Noises';

  @override
  String get graphicContent => 'Graphic Content';

  @override
  String get discrimination => 'Discrimination';

  @override
  String get health => 'Health';

  @override
  String get abuse => 'Abuse';

  @override
  String get routeHome => 'Home';

  @override
  String get routePostsAndReplies => 'Posts and Replies';

  @override
  String get routeSearch => 'Search';

  @override
  String get routeNotifications => 'Notifications';

  @override
  String get scrollToTop => 'scroll to top';

  @override
  String get home => 'home';

  @override
  String get search => 'search';

  @override
  String get explore => 'Explore';

  @override
  String get more => 'More';

  @override
  String get posts => 'Posts';

  @override
  String get postsAndReplies => 'Posts & Replies';

  @override
  String get themeSettings => 'Theme Settings';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get theme => 'Theme';

  @override
  String get camelus => 'Camelus';

  @override
  String get nostr => 'Nostr';

  @override
  String get customColorTheme => 'Custom Color Theme';

  @override
  String get blue => 'Blue';

  @override
  String get purple => 'Purple';

  @override
  String get green => 'Green';

  @override
  String get orange => 'Orange';

  @override
  String get red => 'Red';

  @override
  String get teal => 'Teal';

  @override
  String get pink => 'Pink';

  @override
  String get indigo => 'Indigo';

  @override
  String get welcome => 'Welcome';

  @override
  String get pleaseLoginToManageFileServers =>
      'Please login to manage file servers';
}
