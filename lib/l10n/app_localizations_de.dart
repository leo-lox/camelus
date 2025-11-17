// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get helloWorld => 'Hallo Welt!';

  @override
  String get whatShouldWeCallYou => 'wie sollen wir dich nennen?';

  @override
  String get next => 'weiter';

  @override
  String get skip => 'überspringen';

  @override
  String get selectImage => 'Bild auswählen';

  @override
  String get unsupportedImageFormat => 'nicht unterstütztes Bildformat';

  @override
  String get invalidPrivateKeyOrSeedPhrase =>
      'Ungültiger privater Schlüssel oder Seed-Phrase';

  @override
  String get pleaseReadAndAcceptTerms =>
      'Bitte lesen und akzeptieren Sie zuerst die Allgemeinen Geschäftsbedingungen';

  @override
  String get pleaseImportPrivateKeyFirst =>
      'Bitte importieren Sie zuerst Ihren privaten Schlüssel';

  @override
  String get publicKeyErrorMessage =>
      'Sie haben einen öffentlichen Schlüssel eingegeben, bitte geben Sie einen privaten Schlüssel ein, er beginnt mit nsec1';

  @override
  String wordNotValid(String word) {
    return 'Wort: $word ist nicht gültig, überprüfen Sie die Schreibweise';
  }

  @override
  String get login => 'anmelden';

  @override
  String get yourPublicKeyIs => 'Ihr öffentlicher Schlüssel ist:';

  @override
  String get enterSeedPhraseOrNsec =>
      'Geben Sie Ihre Seed-Phrase oder nsec1 ein';

  @override
  String get paste => 'einfügen';

  @override
  String get add => 'hinzufügen';

  @override
  String get iHaveReadAndAccept => 'Ich habe die ';

  @override
  String get termsAndConditions => 'Allgemeinen Geschäftsbedingungen';

  @override
  String get privacyPolicy => 'Datenschutzrichtlinie';

  @override
  String get settingUpYourAccount => 'Ihr Konto wird eingerichtet';

  @override
  String get followingPeople => 'Personen folgen';

  @override
  String get movingData => 'Daten werden verschoben';

  @override
  String get cleaningUp => 'aufräumen';

  @override
  String get uploadingProfilePicture => 'Profilbild wird hochgeladen';

  @override
  String get recoveryPhrase => 'Wiederherstellungsphrase';

  @override
  String get newSeedPhraseGenerated => 'eine neue Seed-Phrase wurde generiert';

  @override
  String get regenerate => 'neu generieren';

  @override
  String get copiedSeedPhraseToClipboard =>
      'Seed-Phrase in Zwischenablage kopiert';

  @override
  String get copy => 'kopieren';

  @override
  String get hideWords => 'Wörter verbergen';

  @override
  String get showWords => 'Wörter anzeigen';

  @override
  String get recoveryPhraseWarning =>
      'Sie benötigen die Wiederherstellungsphrase, um sich erneut anzumelden. Bewahren Sie sie sicher auf!';

  @override
  String get publishAccount => 'Konto veröffentlichen';

  @override
  String get starterPacks => 'Starter-Pakete';

  @override
  String get additionalStarterPacks => 'Zusätzliche Starter-Pakete';

  @override
  String continueWithAccounts(int count) {
    return 'mit $count Konten fortfahren';
  }

  @override
  String get selectStarterPack => 'ein Starter-Paket auswählen';

  @override
  String by(String name) {
    return 'von $name';
  }

  @override
  String get unselectAll => 'alle abwählen';

  @override
  String get followAll => 'allen folgen';

  @override
  String followAccounts(int count) {
    return '$count Konten folgen';
  }

  @override
  String get invitedYouToJoin => ' hat dich eingeladen beizutreten';

  @override
  String get youWillFollowThesePeople =>
      'Sie werden diesen Personen sofort folgen';

  @override
  String get noStarterPackFound => '👀 kein Starter-Paket gefunden ';

  @override
  String get noWorriesYouCanStillJoin =>
      'keine Sorge, Sie können Camelus trotzdem beitreten!';

  @override
  String get joinCamelus => 'Camelus beitreten';

  @override
  String get signupWithoutStarterPack => 'Ohne Starter-Paket registrieren';

  @override
  String copiedToClipboard(String text) {
    return 'In Zwischenablage kopiert: $text';
  }

  @override
  String get shareYourProfile => 'Profil teilen';

  @override
  String get following => 'Folge ich';

  @override
  String get followers => 'Follower';

  @override
  String get profile => 'Profil';

  @override
  String get bookmarks => 'Lesezeichen';

  @override
  String get removeBookmark => 'Dieses Lesezeichen entfernen?';

  @override
  String get bookmarkRemoved => 'Lesezeichen entfernt';

  @override
  String get noPrivateBookmarks => 'Noch keine privaten Lesezeichen';

  @override
  String get noPublicBookmarks => 'Noch keine öffentlichen Lesezeichen';

  @override
  String get privateBookmarks => 'Privat';

  @override
  String get publicBookmarks => 'Öffentlich';

  @override
  String get addToBookmarks => 'Zu Lesezeichen hinzufügen';

  @override
  String get removeFromBookmarks => 'Aus Lesezeichen entfernen';

  @override
  String get addingToBookmarks => 'Wird zu Lesezeichen hinzugefügt...';

  @override
  String get removingFromBookmarks => 'Wird aus Lesezeichen entfernt...';

  @override
  String get failedToAddBookmark =>
      'Lesezeichen konnte nicht hinzugefügt werden';

  @override
  String get failedToRemoveBookmark =>
      'Lesezeichen konnte nicht entfernt werden';

  @override
  String get notImplementedYet => 'Noch nicht implementiert';

  @override
  String get payments => 'Zahlungen';

  @override
  String get blocklist => 'Blockierliste';

  @override
  String get settings => 'Einstellungen';

  @override
  String get termsOfService => 'Nutzungsbedingungen';

  @override
  String get languageSettings => 'Spracheinstellungen';

  @override
  String get initialRoute => 'Anfangsroute';

  @override
  String get moderation => 'Moderation';

  @override
  String get fileServers => 'Dateiserver';

  @override
  String get logout => 'Abmelden';

  @override
  String get unsavedChanges => 'Nicht gespeicherte Änderungen';

  @override
  String get unsavedChangesMessage =>
      'Sie haben nicht gespeicherte Änderungen. Möchten Sie diese verwerfen?';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get discard => 'Verwerfen';

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get saving => 'Speichern...';

  @override
  String get changesSavedSuccessfully => 'Änderungen erfolgreich gespeichert';

  @override
  String get failedToSaveChanges => 'Fehler beim Speichern der Änderungen';

  @override
  String get setupDefaultServers => 'Standardserver einrichten';

  @override
  String get defaultLabel => ' (Standard)';

  @override
  String get restoreDefaults => 'Standardeinstellungen wiederherstellen';

  @override
  String get restoreDefaultsMessage =>
      'Sind Sie sicher, dass Sie die Standardserver wiederherstellen möchten? Dadurch werden alle benutzerdefinierten Server entfernt.';

  @override
  String get restore => 'Wiederherstellen';

  @override
  String get enterBlossomUrl => 'Blossom-URL eingeben';

  @override
  String errorUpdatingFilter(String error) {
    return 'Fehler beim Aktualisieren des Filters $error';
  }

  @override
  String get moderationSettings => 'Moderationseinstellungen';

  @override
  String get camelusContentFiltering => 'Camelus Inhaltsfilterung';

  @override
  String get enableContentFilteringDescription =>
      'Aktivieren Sie die Inhaltsfilterung, um potenziell unangemessene Inhalte auszublenden.';

  @override
  String get enableContentFilter => 'Inhaltsfilter aktivieren';

  @override
  String get contentFilterNote =>
      'Hinweis: Filter werden lokal (auf dem Gerät) angewendet. Wenn Benutzer nostr-Inhalte direkt an camelus melden, werden sie zum Filter hinzugefügt.';

  @override
  String get errorUploadingImage =>
      'Fehler beim Hochladen des Bildes, Upload-Server konfiguriert?';

  @override
  String get editProfile => 'Profil bearbeiten';

  @override
  String get save => 'speichern';

  @override
  String get loadingProfile => 'Profil wird geladen...';

  @override
  String get uploading => 'Hochladen...';

  @override
  String get uploadingCapitalized => 'Hochladen';

  @override
  String get name => 'Name';

  @override
  String get bio => 'Biografie';

  @override
  String get pronouns => 'Pronomen';

  @override
  String get website => 'Webseite';

  @override
  String get username => 'Benutzername (nip05)';

  @override
  String get lightningAddress => 'Lightning-Adresse';

  @override
  String get editRelays => 'Relays bearbeiten';

  @override
  String get error => 'Fehler:';

  @override
  String get whatsOnYourMind => 'Was denken Sie gerade?';

  @override
  String get writePost => 'einen Beitrag schreiben';

  @override
  String replyTo(String name) {
    return 'antworten an $name';
  }

  @override
  String get addToStarterPack => 'zum Starter-Paket hinzufügen';

  @override
  String get blockReport => 'Blockieren/Melden';

  @override
  String get blockedUsers => 'Blockierte Benutzer';

  @override
  String get notImplemented => 'nicht implementiert';

  @override
  String get impersonation => 'Identitätsdiebstahl';

  @override
  String get spam => 'Spam';

  @override
  String get illegal => 'illegal';

  @override
  String get profanity => 'Obszönität';

  @override
  String get nudity => 'Nacktheit';

  @override
  String get malware => 'Malware';

  @override
  String get other => 'andere';

  @override
  String get reportSent => 'Meldung gesendet';

  @override
  String get thankYouForReport => 'vielen Dank für Ihre Meldung';

  @override
  String get goBack => 'zurück';

  @override
  String get blockReportTitle => 'blockieren/melden';

  @override
  String get user => 'Benutzer';

  @override
  String get loading => 'lädt';

  @override
  String get unblock => 'Blockierung aufheben';

  @override
  String get block => 'blockieren';

  @override
  String get whatIsWrongWithPost => 'was ist falsch mit diesem Beitrag?';

  @override
  String get whatIsWrongWithUser => 'was ist falsch mit diesem Benutzer?';

  @override
  String get reportsAreSentToRelays =>
      'Meldungen werden an die Relays gesendet, von denen Sie die Notiz erhalten haben.';

  @override
  String get additionallyReportToCamelus =>
      'Zusätzlich direkt an camelus melden';

  @override
  String get reportPost => 'Beitrag melden';

  @override
  String get reportUser => 'Benutzer melden';

  @override
  String get relays => 'Relays';

  @override
  String get eventsRead => 'Gelesene Events';

  @override
  String get eventsWritten => 'Geschriebene Events';

  @override
  String get connectionSource => 'Verbindungsquelle';

  @override
  String get noDataAvailable => 'Keine Daten verfügbar';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get searchHelp => 'Suchhilfe';

  @override
  String get searchHelpMessage =>
      'Geben Sie Schlüsselwörter ein, um nach Beiträgen zu suchen.';

  @override
  String get ok => 'OK';

  @override
  String get thread => 'Thread';

  @override
  String get workInProgress => 'in Arbeit';

  @override
  String get update => 'Aktualisieren';

  @override
  String get initialRouteSettings => 'Anfangsroute-Einstellungen';

  @override
  String get useSystemLanguage => 'Systemsprache verwenden';

  @override
  String get edit => 'bearbeiten';

  @override
  String get postSettings => 'Beitragseinstellungen';

  @override
  String get enableContentWarning => 'Inhaltswarnung aktivieren';

  @override
  String get warningType => 'Warnungstyp';

  @override
  String get customWarning => 'Benutzerdefinierte Warnung';

  @override
  String get specifyContentWarning => 'Inhaltswarnung angeben';

  @override
  String get enableClientTag => 'Client-Tag aktivieren';

  @override
  String get close => 'Schließen';

  @override
  String get sensitiveContent => 'Sensible Inhalte';

  @override
  String get flashingLights => 'Blitzende Lichter';

  @override
  String get loudNoises => 'Laute Geräusche';

  @override
  String get graphicContent => 'Grafische Inhalte';

  @override
  String get discrimination => 'Diskriminierung';

  @override
  String get health => 'Gesundheit';

  @override
  String get abuse => 'Missbrauch';

  @override
  String get routeHome => 'Startseite';

  @override
  String get routePostsAndReplies => 'Beiträge und Antworten';

  @override
  String get routeSearch => 'Suchen';

  @override
  String get routeNotifications => 'Benachrichtigungen';

  @override
  String get scrollToTop => 'Nach oben scrollen';

  @override
  String get home => 'Startseite';

  @override
  String get search => 'Suchen';

  @override
  String get explore => 'Erkunden';

  @override
  String get more => 'Mehr';

  @override
  String get posts => 'Beiträge';

  @override
  String get postsAndReplies => 'Beiträge und Antworten';

  @override
  String get themeSettings => 'Design-Einstellungen';

  @override
  String get themeMode => 'Design-Modus';

  @override
  String get system => 'System';

  @override
  String get light => 'Hell';

  @override
  String get dark => 'Dunkel';

  @override
  String get theme => 'Design';

  @override
  String get camelus => 'Camelus';

  @override
  String get nostr => 'Nostr';

  @override
  String get customColorTheme => 'Benutzerdefiniertes Farbschema';

  @override
  String get blue => 'Blau';

  @override
  String get purple => 'Lila';

  @override
  String get green => 'Grün';

  @override
  String get orange => 'Orange';

  @override
  String get red => 'Rot';

  @override
  String get teal => 'Türkis';

  @override
  String get pink => 'Rosa';

  @override
  String get indigo => 'Indigo';

  @override
  String get welcome => 'Willkommen';
}
