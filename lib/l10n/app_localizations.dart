import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_th.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('pt'),
    Locale('ru'),
    Locale('th'),
    Locale('zh'),
  ];

  /// The conventional newborn programmer greeting
  ///
  /// In en, this message translates to:
  /// **'Hello World!'**
  String get helloWorld;

  /// Hint text for name input during onboarding
  ///
  /// In en, this message translates to:
  /// **'what should we call you?'**
  String get whatShouldWeCallYou;

  /// Next button label
  ///
  /// In en, this message translates to:
  /// **'next'**
  String get next;

  /// Skip button label
  ///
  /// In en, this message translates to:
  /// **'skip'**
  String get skip;

  /// Dialog title for image selection
  ///
  /// In en, this message translates to:
  /// **'select image'**
  String get selectImage;

  /// Error message for unsupported image format
  ///
  /// In en, this message translates to:
  /// **'unsupported image format'**
  String get unsupportedImageFormat;

  /// Error message for invalid credentials
  ///
  /// In en, this message translates to:
  /// **'Invalid private key or seed phrase'**
  String get invalidPrivateKeyOrSeedPhrase;

  /// Error message when terms not accepted
  ///
  /// In en, this message translates to:
  /// **'Please read and accept the terms and conditions first'**
  String get pleaseReadAndAcceptTerms;

  /// Error message when private key not imported
  ///
  /// In en, this message translates to:
  /// **'Please import your private key first'**
  String get pleaseImportPrivateKeyFirst;

  /// Error message when user enters public key instead of private key
  ///
  /// In en, this message translates to:
  /// **'you entered a public key, please enter a private key, it starts with nsec1'**
  String get publicKeyErrorMessage;

  /// Error message when a seed phrase word is invalid
  ///
  /// In en, this message translates to:
  /// **'word: {word} is not valid, check if it is spelled correctly'**
  String wordNotValid(String word);

  /// Login button and page title
  ///
  /// In en, this message translates to:
  /// **'login'**
  String get login;

  /// Label for public key display
  ///
  /// In en, this message translates to:
  /// **'your public key is:'**
  String get yourPublicKeyIs;

  /// Hint text for login input field
  ///
  /// In en, this message translates to:
  /// **'enter your seed phrase or nsec1'**
  String get enterSeedPhraseOrNsec;

  /// Paste button label
  ///
  /// In en, this message translates to:
  /// **'paste'**
  String get paste;

  /// Add button label
  ///
  /// In en, this message translates to:
  /// **'add'**
  String get add;

  /// Checkbox label prefix for terms acceptance
  ///
  /// In en, this message translates to:
  /// **'I have read and accept the '**
  String get iHaveReadAndAccept;

  /// Terms and conditions link text
  ///
  /// In en, this message translates to:
  /// **'terms and conditions'**
  String get termsAndConditions;

  /// Privacy policy link text
  ///
  /// In en, this message translates to:
  /// **'privacy policy'**
  String get privacyPolicy;

  /// Loading message during account setup
  ///
  /// In en, this message translates to:
  /// **'setting up your account'**
  String get settingUpYourAccount;

  /// Loading message while following users
  ///
  /// In en, this message translates to:
  /// **'following people'**
  String get followingPeople;

  /// Loading message during data migration
  ///
  /// In en, this message translates to:
  /// **'moving data'**
  String get movingData;

  /// Loading message during cleanup process
  ///
  /// In en, this message translates to:
  /// **'cleaning up'**
  String get cleaningUp;

  /// Loading message while uploading profile picture
  ///
  /// In en, this message translates to:
  /// **'uploading profile picture'**
  String get uploadingProfilePicture;

  /// Recovery phrase section title
  ///
  /// In en, this message translates to:
  /// **'recovery phrase'**
  String get recoveryPhrase;

  /// Snackbar message when seed phrase is generated
  ///
  /// In en, this message translates to:
  /// **'a new seed phrase has been generated'**
  String get newSeedPhraseGenerated;

  /// Regenerate button label
  ///
  /// In en, this message translates to:
  /// **'regenerate'**
  String get regenerate;

  /// Snackbar message when seed phrase is copied
  ///
  /// In en, this message translates to:
  /// **'copied seed phrase to clipboard'**
  String get copiedSeedPhraseToClipboard;

  /// Copy button label
  ///
  /// In en, this message translates to:
  /// **'copy'**
  String get copy;

  /// Tooltip to hide seed phrase words
  ///
  /// In en, this message translates to:
  /// **'Hide words'**
  String get hideWords;

  /// Tooltip to show seed phrase words
  ///
  /// In en, this message translates to:
  /// **'Show words'**
  String get showWords;

  /// Warning message about recovery phrase importance
  ///
  /// In en, this message translates to:
  /// **'You need the recovery phrase to login again. Make sure to keep it safe!'**
  String get recoveryPhraseWarning;

  /// Button to publish account after onboarding
  ///
  /// In en, this message translates to:
  /// **'publish account'**
  String get publishAccount;

  /// Main starter packs section title
  ///
  /// In en, this message translates to:
  /// **'Starter Packs'**
  String get starterPacks;

  /// Additional starter packs section title
  ///
  /// In en, this message translates to:
  /// **'Additional Starter Packs'**
  String get additionalStarterPacks;

  /// Button text showing number of accounts selected
  ///
  /// In en, this message translates to:
  /// **'continue with {count} accounts'**
  String continueWithAccounts(int count);

  /// Button text when no starter pack is selected
  ///
  /// In en, this message translates to:
  /// **'select a starter pack'**
  String get selectStarterPack;

  /// Author attribution
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String by(String name);

  /// Button to unselect all accounts
  ///
  /// In en, this message translates to:
  /// **'unselect all'**
  String get unselectAll;

  /// Button to follow all accounts in a starter pack
  ///
  /// In en, this message translates to:
  /// **'follow all'**
  String get followAll;

  /// Follow specific number of accounts
  ///
  /// In en, this message translates to:
  /// **'follow {count} accounts'**
  String followAccounts(int count);

  /// Text showing who invited the user
  ///
  /// In en, this message translates to:
  /// **' invited you to join'**
  String get invitedYouToJoin;

  /// Message about auto-following from starter pack
  ///
  /// In en, this message translates to:
  /// **'You\'ll follow these people right away'**
  String get youWillFollowThesePeople;

  /// Message when no starter pack is found
  ///
  /// In en, this message translates to:
  /// **'👀 no starter pack found '**
  String get noStarterPackFound;

  /// Reassurance message when no starter pack found
  ///
  /// In en, this message translates to:
  /// **'no worries, you can still join Camelus!'**
  String get noWorriesYouCanStillJoin;

  /// Button to join Camelus with starter pack
  ///
  /// In en, this message translates to:
  /// **'Join Camelus'**
  String get joinCamelus;

  /// Button to signup without using a starter pack
  ///
  /// In en, this message translates to:
  /// **'Signup without a starter pack'**
  String get signupWithoutStarterPack;

  /// Snackbar message when text is copied
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard: {text}'**
  String copiedToClipboard(String text);

  /// Dialog title for sharing profile
  ///
  /// In en, this message translates to:
  /// **'Share your Profile'**
  String get shareYourProfile;

  /// Label for following count
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// Label for followers count
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// Profile menu item
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Bookmarks menu item
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// Snackbar message for unimplemented features
  ///
  /// In en, this message translates to:
  /// **'Not implemented yet'**
  String get notImplementedYet;

  /// Payments menu item
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// Blocklist menu item
  ///
  /// In en, this message translates to:
  /// **'Blocklist'**
  String get blocklist;

  /// Settings button and page title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Terms of service button
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Language settings menu item
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get languageSettings;

  /// Initial route settings menu item
  ///
  /// In en, this message translates to:
  /// **'Initial route'**
  String get initialRoute;

  /// Moderation settings menu item
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get moderation;

  /// File servers settings menu item and page title
  ///
  /// In en, this message translates to:
  /// **'File servers'**
  String get fileServers;

  /// Logout menu item
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Dialog title for unsaved changes warning
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChanges;

  /// Dialog message for unsaved changes warning
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to discard them?'**
  String get unsavedChangesMessage;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Discard button label
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// Save changes button label
  ///
  /// In en, this message translates to:
  /// **'save changes'**
  String get saveChanges;

  /// Saving status message
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// Success message when changes are saved
  ///
  /// In en, this message translates to:
  /// **'Changes saved successfully'**
  String get changesSavedSuccessfully;

  /// Error message when save fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save changes'**
  String get failedToSaveChanges;

  /// Button to setup default file servers
  ///
  /// In en, this message translates to:
  /// **'setup default servers'**
  String get setupDefaultServers;

  /// Label suffix for default items
  ///
  /// In en, this message translates to:
  /// **' (default)'**
  String get defaultLabel;

  /// Button and dialog title to restore default servers
  ///
  /// In en, this message translates to:
  /// **'Restore Defaults'**
  String get restoreDefaults;

  /// Confirmation message for restoring default servers
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restore default servers? This will remove all custom servers.'**
  String get restoreDefaultsMessage;

  /// Restore button label
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// Hint text for blossom URL input
  ///
  /// In en, this message translates to:
  /// **'Enter blossom URL'**
  String get enterBlossomUrl;

  /// Error message when filter update fails
  ///
  /// In en, this message translates to:
  /// **'Error updating filter {error}'**
  String errorUpdatingFilter(String error);

  /// Moderation settings page title
  ///
  /// In en, this message translates to:
  /// **'Moderation Settings'**
  String get moderationSettings;

  /// Content filtering section title
  ///
  /// In en, this message translates to:
  /// **'Camelus Content Filtering'**
  String get camelusContentFiltering;

  /// Description for content filtering feature
  ///
  /// In en, this message translates to:
  /// **'Enable content filtering to hide potentially inappropriate content.'**
  String get enableContentFilteringDescription;

  /// Switch label for content filter
  ///
  /// In en, this message translates to:
  /// **'Enable Content Filter'**
  String get enableContentFilter;

  /// Note about how content filtering works
  ///
  /// In en, this message translates to:
  /// **'Note: Filters are applied locally (on device). When users report nostr content directly to camelus it gets added to the filter.'**
  String get contentFilterNote;

  /// Error message when image upload fails
  ///
  /// In en, this message translates to:
  /// **'err uploading image, upload servers configured?'**
  String get errorUploadingImage;

  /// Edit profile page title
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'save'**
  String get save;

  /// Loading message when fetching profile
  ///
  /// In en, this message translates to:
  /// **'Loading profile...'**
  String get loadingProfile;

  /// Upload status message
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// Upload status message capitalized
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get uploadingCapitalized;

  /// Name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Bio field label
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// Pronouns field label
  ///
  /// In en, this message translates to:
  /// **'Pronouns'**
  String get pronouns;

  /// Website field label
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// Username field label with NIP-05 specification
  ///
  /// In en, this message translates to:
  /// **'Username (nip05)'**
  String get username;

  /// Lightning address field label
  ///
  /// In en, this message translates to:
  /// **'Lightning address'**
  String get lightningAddress;

  /// Edit relays page title
  ///
  /// In en, this message translates to:
  /// **'Edit Relays'**
  String get editRelays;

  /// Error label prefix
  ///
  /// In en, this message translates to:
  /// **'error:'**
  String get error;

  /// Hint text for post composition
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind?'**
  String get whatsOnYourMind;

  /// Title for post composition page
  ///
  /// In en, this message translates to:
  /// **'write a post'**
  String get writePost;

  /// Title for reply composition page
  ///
  /// In en, this message translates to:
  /// **'reply to {name}'**
  String replyTo(String name);

  /// Menu item to add user to starter pack
  ///
  /// In en, this message translates to:
  /// **'add to starter pack'**
  String get addToStarterPack;

  /// Menu item for blocking or reporting
  ///
  /// In en, this message translates to:
  /// **'Block/Report'**
  String get blockReport;

  /// Blocked users page title
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get blockedUsers;

  /// Message for unimplemented features
  ///
  /// In en, this message translates to:
  /// **'not implemented'**
  String get notImplemented;

  /// Report reason: impersonation
  ///
  /// In en, this message translates to:
  /// **'impersonation'**
  String get impersonation;

  /// Report reason: spam
  ///
  /// In en, this message translates to:
  /// **'spam'**
  String get spam;

  /// Report reason: illegal content
  ///
  /// In en, this message translates to:
  /// **'illegal'**
  String get illegal;

  /// Report reason: profanity
  ///
  /// In en, this message translates to:
  /// **'profanity'**
  String get profanity;

  /// Report reason: nudity
  ///
  /// In en, this message translates to:
  /// **'nudity'**
  String get nudity;

  /// Report reason: malware
  ///
  /// In en, this message translates to:
  /// **'malware'**
  String get malware;

  /// Report reason: other
  ///
  /// In en, this message translates to:
  /// **'other'**
  String get other;

  /// Title shown after report is submitted
  ///
  /// In en, this message translates to:
  /// **'report sent'**
  String get reportSent;

  /// Thank you message after report submission
  ///
  /// In en, this message translates to:
  /// **'thank you for your report'**
  String get thankYouForReport;

  /// Button to go back after report submission
  ///
  /// In en, this message translates to:
  /// **'go back'**
  String get goBack;

  /// Block/report page title
  ///
  /// In en, this message translates to:
  /// **'block/report'**
  String get blockReportTitle;

  /// User label
  ///
  /// In en, this message translates to:
  /// **'user'**
  String get user;

  /// Loading button state
  ///
  /// In en, this message translates to:
  /// **'loading'**
  String get loading;

  /// Unblock button label
  ///
  /// In en, this message translates to:
  /// **'unblock'**
  String get unblock;

  /// Block button label
  ///
  /// In en, this message translates to:
  /// **'block'**
  String get block;

  /// Hint text for post report input
  ///
  /// In en, this message translates to:
  /// **'what is wrong with this post?'**
  String get whatIsWrongWithPost;

  /// Hint text for user report input
  ///
  /// In en, this message translates to:
  /// **'what is wrong with this user?'**
  String get whatIsWrongWithUser;

  /// Information about how reports are handled
  ///
  /// In en, this message translates to:
  /// **'Reports are sent to the relays where you received the note from.'**
  String get reportsAreSentToRelays;

  /// Checkbox label for direct reporting to Camelus
  ///
  /// In en, this message translates to:
  /// **'Additionally, report to camelus directly'**
  String get additionallyReportToCamelus;

  /// Button to report a post
  ///
  /// In en, this message translates to:
  /// **'report post'**
  String get reportPost;

  /// Button to report a user
  ///
  /// In en, this message translates to:
  /// **'report user'**
  String get reportUser;

  /// Relays page title
  ///
  /// In en, this message translates to:
  /// **'Relays'**
  String get relays;

  /// Label for events read count
  ///
  /// In en, this message translates to:
  /// **'Events Read'**
  String get eventsRead;

  /// Label for events written count
  ///
  /// In en, this message translates to:
  /// **'Events Written'**
  String get eventsWritten;

  /// Label for connection source
  ///
  /// In en, this message translates to:
  /// **'Connection Source'**
  String get connectionSource;

  /// Message when no data is available to display
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// Notifications page title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Search help dialog title
  ///
  /// In en, this message translates to:
  /// **'Search Help'**
  String get searchHelp;

  /// Search help dialog message
  ///
  /// In en, this message translates to:
  /// **'Enter keywords to search for posts.'**
  String get searchHelpMessage;

  /// OK button label
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Thread page title
  ///
  /// In en, this message translates to:
  /// **'thread'**
  String get thread;

  /// Work in progress message
  ///
  /// In en, this message translates to:
  /// **'work in progress'**
  String get workInProgress;

  /// Update button label
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// Initial route settings page title
  ///
  /// In en, this message translates to:
  /// **'Initial Route Settings'**
  String get initialRouteSettings;

  /// Option to use device's system language
  ///
  /// In en, this message translates to:
  /// **'Use System Language'**
  String get useSystemLanguage;

  /// Edit button label
  ///
  /// In en, this message translates to:
  /// **'edit'**
  String get edit;

  /// Post settings dialog title
  ///
  /// In en, this message translates to:
  /// **'Post Settings'**
  String get postSettings;

  /// Switch to enable content warning
  ///
  /// In en, this message translates to:
  /// **'Enable Content Warning'**
  String get enableContentWarning;

  /// Label for warning type dropdown
  ///
  /// In en, this message translates to:
  /// **'Warning Type:'**
  String get warningType;

  /// Custom warning input label
  ///
  /// In en, this message translates to:
  /// **'Custom Warning'**
  String get customWarning;

  /// Hint text for custom warning input
  ///
  /// In en, this message translates to:
  /// **'Specify content warning'**
  String get specifyContentWarning;

  /// Switch to enable client tag
  ///
  /// In en, this message translates to:
  /// **'Enable Client Tag'**
  String get enableClientTag;

  /// Close button label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Content warning option
  ///
  /// In en, this message translates to:
  /// **'Sensitive Content'**
  String get sensitiveContent;

  /// Content warning option
  ///
  /// In en, this message translates to:
  /// **'Flashing Lights/Patterns'**
  String get flashingLights;

  /// Content warning option
  ///
  /// In en, this message translates to:
  /// **'Loud Noises'**
  String get loudNoises;

  /// Content warning option
  ///
  /// In en, this message translates to:
  /// **'Graphic Content'**
  String get graphicContent;

  /// Content warning option
  ///
  /// In en, this message translates to:
  /// **'Discrimination'**
  String get discrimination;

  /// Content warning option
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// Content warning option
  ///
  /// In en, this message translates to:
  /// **'Abuse'**
  String get abuse;

  /// Home route label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get routeHome;

  /// Posts and replies route label
  ///
  /// In en, this message translates to:
  /// **'Posts and Replies'**
  String get routePostsAndReplies;

  /// Search route label
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get routeSearch;

  /// Notifications route label
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get routeNotifications;

  /// Tooltip for scrolling to top
  ///
  /// In en, this message translates to:
  /// **'scroll to top'**
  String get scrollToTop;

  /// Home tab label
  ///
  /// In en, this message translates to:
  /// **'home'**
  String get home;

  /// Search tab label
  ///
  /// In en, this message translates to:
  /// **'search'**
  String get search;

  /// Explore menu item
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// More options tooltip
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// Posts tab label
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get posts;

  /// Posts and replies tab label
  ///
  /// In en, this message translates to:
  /// **'Posts & Replies'**
  String get postsAndReplies;

  /// Theme settings page title
  ///
  /// In en, this message translates to:
  /// **'Theme Settings'**
  String get themeSettings;

  /// Theme mode section title
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// System option for theme mode and type
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// Light theme mode option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// Dark theme mode option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// Theme selection section title
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Camelus theme option
  ///
  /// In en, this message translates to:
  /// **'Camelus'**
  String get camelus;

  /// Nostr theme option
  ///
  /// In en, this message translates to:
  /// **'Nostr'**
  String get nostr;

  /// Custom color theme section title
  ///
  /// In en, this message translates to:
  /// **'Custom Color Theme'**
  String get customColorTheme;

  /// Blue color option
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get blue;

  /// Purple color option
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get purple;

  /// Green color option
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get green;

  /// Orange color option
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get orange;

  /// Red color option
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get red;

  /// Teal color option
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get teal;

  /// Pink color option
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get pink;

  /// Indigo color option
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get indigo;

  /// Welcome greeting text
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'ja',
    'pt',
    'ru',
    'th',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'th':
      return AppLocalizationsTh();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
