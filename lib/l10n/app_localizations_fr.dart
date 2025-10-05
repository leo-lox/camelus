// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get helloWorld => 'Bonjour le monde!';

  @override
  String get whatShouldWeCallYou => 'comment devrions-nous vous appeler?';

  @override
  String get next => 'suivant';

  @override
  String get skip => 'passer';

  @override
  String get selectImage => 'sélectionner une image';

  @override
  String get unsupportedImageFormat => 'format d\'image non pris en charge';

  @override
  String get invalidPrivateKeyOrSeedPhrase =>
      'Clé privée ou phrase de récupération invalide';

  @override
  String get pleaseReadAndAcceptTerms =>
      'Veuillez d\'abord lire et accepter les termes et conditions';

  @override
  String get pleaseImportPrivateKeyFirst =>
      'Veuillez d\'abord importer votre clé privée';

  @override
  String get publicKeyErrorMessage =>
      'vous avez entré une clé publique, veuillez entrer une clé privée, elle commence par nsec1';

  @override
  String wordNotValid(String word) {
    return 'mot: $word n\'est pas valide, vérifiez s\'il est correctement orthographié';
  }

  @override
  String get login => 'se connecter';

  @override
  String get yourPublicKeyIs => 'votre clé publique est:';

  @override
  String get enterSeedPhraseOrNsec =>
      'entrez votre phrase de récupération ou nsec1';

  @override
  String get paste => 'coller';

  @override
  String get add => 'ajouter';

  @override
  String get iHaveReadAndAccept => 'J\'ai lu et j\'accepte les ';

  @override
  String get termsAndConditions => 'termes et conditions';

  @override
  String get privacyPolicy => 'politique de confidentialité';

  @override
  String get settingUpYourAccount => 'configuration de votre compte';

  @override
  String get followingPeople => 'abonnement aux personnes';

  @override
  String get movingData => 'déplacement des données';

  @override
  String get cleaningUp => 'nettoyage';

  @override
  String get uploadingProfilePicture => 'téléchargement de la photo de profil';

  @override
  String get recoveryPhrase => 'phrase de récupération';

  @override
  String get newSeedPhraseGenerated =>
      'une nouvelle phrase de récupération a été générée';

  @override
  String get regenerate => 'régénérer';

  @override
  String get copiedSeedPhraseToClipboard =>
      'phrase de récupération copiée dans le presse-papiers';

  @override
  String get copy => 'copier';

  @override
  String get hideWords => 'Masquer les mots';

  @override
  String get showWords => 'Afficher les mots';

  @override
  String get recoveryPhraseWarning =>
      'Vous avez besoin de la phrase de récupération pour vous reconnecter. Assurez-vous de la garder en sécurité!';

  @override
  String get publishAccount => 'publier le compte';

  @override
  String get starterPacks => 'Packs de démarrage';

  @override
  String get additionalStarterPacks => 'Packs de démarrage supplémentaires';

  @override
  String continueWithAccounts(int count) {
    return 'continuer avec $count comptes';
  }

  @override
  String get selectStarterPack => 'sélectionner un pack de démarrage';

  @override
  String by(String name) {
    return 'par $name';
  }

  @override
  String get unselectAll => 'tout désélectionner';

  @override
  String get followAll => 'tout suivre';

  @override
  String followAccounts(int count) {
    return 'suivre $count comptes';
  }

  @override
  String get invitedYouToJoin => ' vous a invité à rejoindre';

  @override
  String get youWillFollowThesePeople =>
      'Vous suivrez ces personnes immédiatement';

  @override
  String get noStarterPackFound => '👀 aucun pack de démarrage trouvé ';

  @override
  String get noWorriesYouCanStillJoin =>
      'ne vous inquiétez pas, vous pouvez toujours rejoindre Camelus!';

  @override
  String get joinCamelus => 'Rejoindre Camelus';

  @override
  String get signupWithoutStarterPack => 'S\'inscrire sans pack de démarrage';

  @override
  String copiedToClipboard(String text) {
    return 'Copié dans le presse-papiers: $text';
  }

  @override
  String get shareYourProfile => 'Partager votre Profil';

  @override
  String get following => 'Abonnements';

  @override
  String get followers => 'Abonnés';

  @override
  String get profile => 'Profil';

  @override
  String get bookmarks => 'Favoris';

  @override
  String get notImplementedYet => 'Pas encore implémenté';

  @override
  String get payments => 'Paiements';

  @override
  String get blocklist => 'Liste de blocage';

  @override
  String get settings => 'Paramètres';

  @override
  String get termsOfService => 'Conditions d\'utilisation';

  @override
  String get languageSettings => 'Paramètres de langue';

  @override
  String get initialRoute => 'Route initiale';

  @override
  String get moderation => 'Modération';

  @override
  String get fileServers => 'Serveurs de fichiers';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get unsavedChanges => 'Modifications non enregistrées';

  @override
  String get unsavedChangesMessage =>
      'Vous avez des modifications non enregistrées. Voulez-vous les abandonner?';

  @override
  String get cancel => 'Annuler';

  @override
  String get discard => 'Abandonner';

  @override
  String get saveChanges => 'enregistrer les modifications';

  @override
  String get saving => 'Enregistrement...';

  @override
  String get changesSavedSuccessfully =>
      'Modifications enregistrées avec succès';

  @override
  String get failedToSaveChanges =>
      'Échec de l\'enregistrement des modifications';

  @override
  String get setupDefaultServers => 'configurer les serveurs par défaut';

  @override
  String get defaultLabel => ' (par défaut)';

  @override
  String get restoreDefaults => 'Restaurer les valeurs par défaut';

  @override
  String get restoreDefaultsMessage =>
      'Êtes-vous sûr de vouloir restaurer les serveurs par défaut? Cela supprimera tous les serveurs personnalisés.';

  @override
  String get restore => 'Restaurer';

  @override
  String get enterBlossomUrl => 'Entrez l\'URL de blossom';

  @override
  String errorUpdatingFilter(String error) {
    return 'Erreur lors de la mise à jour du filtre $error';
  }

  @override
  String get moderationSettings => 'Paramètres de modération';

  @override
  String get camelusContentFiltering => 'Filtrage de contenu Camelus';

  @override
  String get enableContentFilteringDescription =>
      'Activez le filtrage de contenu pour masquer le contenu potentiellement inapproprié.';

  @override
  String get enableContentFilter => 'Activer le filtre de contenu';

  @override
  String get contentFilterNote =>
      'Remarque: Les filtres sont appliqués localement (sur l\'appareil). Lorsque les utilisateurs signalent du contenu nostr directement à camelus, il est ajouté au filtre.';

  @override
  String get errorUploadingImage =>
      'erreur lors du téléchargement de l\'image, serveurs de téléchargement configurés?';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get save => 'enregistrer';

  @override
  String get loadingProfile => 'Chargement du profil...';

  @override
  String get uploading => 'Téléchargement...';

  @override
  String get uploadingCapitalized => 'Téléchargement';

  @override
  String get name => 'Nom';

  @override
  String get bio => 'Biographie';

  @override
  String get pronouns => 'Pronoms';

  @override
  String get website => 'Site web';

  @override
  String get username => 'Nom d\'utilisateur (nip05)';

  @override
  String get lightningAddress => 'Adresse Lightning';

  @override
  String get editRelays => 'Modifier les relais';

  @override
  String get error => 'erreur:';

  @override
  String get whatsOnYourMind => 'À quoi pensez-vous?';

  @override
  String get writePost => 'écrire une publication';

  @override
  String replyTo(String name) {
    return 'répondre à $name';
  }

  @override
  String get addToStarterPack => 'ajouter au pack de démarrage';

  @override
  String get blockReport => 'Bloquer/Signaler';

  @override
  String get blockedUsers => 'Utilisateurs bloqués';

  @override
  String get notImplemented => 'pas implémenté';

  @override
  String get impersonation => 'usurpation d\'identité';

  @override
  String get spam => 'spam';

  @override
  String get illegal => 'illégal';

  @override
  String get profanity => 'blasphème';

  @override
  String get nudity => 'nudité';

  @override
  String get malware => 'logiciel malveillant';

  @override
  String get other => 'autre';

  @override
  String get reportSent => 'signalement envoyé';

  @override
  String get thankYouForReport => 'merci pour votre signalement';

  @override
  String get goBack => 'retour';

  @override
  String get blockReportTitle => 'bloquer/signaler';

  @override
  String get user => 'utilisateur';

  @override
  String get loading => 'chargement';

  @override
  String get unblock => 'débloquer';

  @override
  String get block => 'bloquer';

  @override
  String get whatIsWrongWithPost =>
      'quel est le problème avec cette publication?';

  @override
  String get whatIsWrongWithUser =>
      'quel est le problème avec cet utilisateur?';

  @override
  String get reportsAreSentToRelays =>
      'Les signalements sont envoyés aux relais d\'où vous avez reçu la note.';

  @override
  String get additionallyReportToCamelus =>
      'De plus, signaler directement à camelus';

  @override
  String get reportPost => 'signaler la publication';

  @override
  String get reportUser => 'signaler l\'utilisateur';

  @override
  String get relays => 'Relais';

  @override
  String get eventsRead => 'Événements lus';

  @override
  String get eventsWritten => 'Événements écrits';

  @override
  String get connectionSource => 'Source de connexion';

  @override
  String get noDataAvailable => 'Aucune donnée disponible';

  @override
  String get notifications => 'Notifications';

  @override
  String get searchHelp => 'Aide à la recherche';

  @override
  String get searchHelpMessage =>
      'Entrez des mots-clés pour rechercher des publications.';

  @override
  String get ok => 'OK';

  @override
  String get thread => 'fil';

  @override
  String get workInProgress => 'travail en cours';

  @override
  String get update => 'Mettre à jour';

  @override
  String get initialRouteSettings => 'Paramètres de route initiale';

  @override
  String get useSystemLanguage => 'Utiliser la langue du système';

  @override
  String get edit => 'modifier';

  @override
  String get postSettings => 'Paramètres de publication';

  @override
  String get enableContentWarning => 'Activer l\'avertissement de contenu';

  @override
  String get warningType => 'Type d\'avertissement';

  @override
  String get customWarning => 'Avertissement personnalisé';

  @override
  String get specifyContentWarning => 'Spécifier l\'avertissement de contenu';

  @override
  String get enableClientTag => 'Activer la balise client';

  @override
  String get close => 'Fermer';

  @override
  String get sensitiveContent => 'Contenu sensible';

  @override
  String get flashingLights => 'Lumières clignotantes';

  @override
  String get loudNoises => 'Bruits forts';

  @override
  String get graphicContent => 'Contenu graphique';

  @override
  String get discrimination => 'Discrimination';

  @override
  String get health => 'Santé';

  @override
  String get abuse => 'Abus';

  @override
  String get routeHome => 'Accueil';

  @override
  String get routePostsAndReplies => 'Publications et Réponses';

  @override
  String get routeSearch => 'Rechercher';

  @override
  String get routeNotifications => 'Notifications';

  @override
  String get scrollToTop => 'Faire défiler vers le haut';

  @override
  String get home => 'Accueil';

  @override
  String get search => 'Rechercher';
}
