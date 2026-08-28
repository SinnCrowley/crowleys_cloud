// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Crowley\'s Cloud';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get rename => 'Renommer';

  @override
  String get close => 'Fermer';

  @override
  String get retry => 'Réessayer';

  @override
  String get loading => 'Chargement...';

  @override
  String get confirm => 'Confirmer';

  @override
  String get error => 'Erreur';

  @override
  String errorWithMessage(String message) {
    return 'Erreur : $message';
  }

  @override
  String get unknown => 'Inconnu';

  @override
  String get upload => 'Importer';

  @override
  String get download => 'Télécharger';

  @override
  String get share => 'Partager';

  @override
  String get copy => 'Copier';

  @override
  String get move => 'Déplacer';

  @override
  String get restore => 'Restaurer';

  @override
  String get apply => 'Appliquer';

  @override
  String get create => 'Créer';

  @override
  String get clear => 'Effacer';

  @override
  String get add => 'Ajouter';

  @override
  String get remove => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get switchLabel => 'Changer';

  @override
  String get search => 'Rechercher';

  @override
  String get name => 'Nom';

  @override
  String get date => 'Date';

  @override
  String get size => 'Taille';

  @override
  String get type => 'Type';

  @override
  String get ascending => 'Croissant';

  @override
  String get descending => 'Décroissant';

  @override
  String get allFiles => 'Tous';

  @override
  String get categoryImages => 'Images';

  @override
  String get categoryPhotos => 'Photos';

  @override
  String get categoryVideos => 'Vidéos';

  @override
  String get categoryAudio => 'Audio';

  @override
  String get categoryDocuments => 'Documents';

  @override
  String get categoryArchives => 'Archives';

  @override
  String get categoryShared => 'Partagés';

  @override
  String get categoryOther => 'Autres';

  @override
  String get categoryOtherFiles => 'Autres fichiers';

  @override
  String get noFilesFound => 'Aucun fichier trouvé.';

  @override
  String get noFilesInFolder => 'Aucun fichier dans ce dossier.';

  @override
  String get thisActionCannotBeUndone => 'Cette action est irréversible.';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas.';

  @override
  String get navLocalFiles => 'Fichiers locaux';

  @override
  String get navServerFiles => 'Fichiers du serveur';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get navTrash => 'Corbeille';

  @override
  String get navLocal => 'Local';

  @override
  String get navServer => 'Serveur';

  @override
  String get addServer => 'Ajouter un serveur';

  @override
  String get noServersConfigured => 'Aucun serveur configuré.';

  @override
  String get addAServerInSettings => 'Ajoutez un serveur dans les paramètres.';

  @override
  String get addFirstServerHint =>
      'Ajoutez votre premier serveur pour continuer.';

  @override
  String get noServersConfiguredYet => 'Aucun serveur n’est encore configuré.';

  @override
  String get crowleysCloudSetup => 'Configuration de Crowley\'s Cloud';

  @override
  String get connect => 'Se connecter';

  @override
  String get connecting => 'Connexion…';

  @override
  String get connected => 'Connecté';

  @override
  String get disconnected => 'Déconnecté';

  @override
  String get switchServer => 'Changer de serveur';

  @override
  String get chooseOtherServer => 'Choisir un autre serveur';

  @override
  String get switchServerTitle => 'Changer de serveur ?';

  @override
  String switchServerBody(String serverName) {
    return 'Basculer vers le serveur actif « $serverName » ?';
  }

  @override
  String get chooseServer => 'Choisir un serveur';

  @override
  String get authenticationRequired => 'Authentification requise';

  @override
  String signInToAccess(String serverName) {
    return 'Connectez-vous pour accéder aux fichiers sur $serverName';
  }

  @override
  String get signInWithPassword => 'Se connecter avec un mot de passe';

  @override
  String get useBiometrics => 'Utiliser la biométrie';

  @override
  String get openingSignIn => 'Ouverture de la connexion…';

  @override
  String get serverConnectionFailed => 'Échec de la connexion au serveur';

  @override
  String get unableToConnectToServer =>
      'Impossible de se connecter au serveur actif.';

  @override
  String unableToConnectTo(String serverName) {
    return 'Impossible de se connecter à $serverName.';
  }

  @override
  String get searchHint => 'Rechercher…';

  @override
  String get searchFilesHint => 'Rechercher des fichiers…';

  @override
  String get searchServerFilesHint => 'Rechercher des fichiers du serveur…';

  @override
  String get searchTrashHint => 'Rechercher dans la corbeille…';

  @override
  String get storagePermissionRequired => 'Autorisation de stockage requise';

  @override
  String get grantPermission => 'Accorder l’autorisation';

  @override
  String get permissionDeniedOpenSettings =>
      'Autorisation refusée. Accordez l’accès au stockage dans les paramètres.';

  @override
  String get manageStoragePermissionRequired =>
      'L’autorisation de gérer le stockage est requise pour parcourir et sélectionner des dossiers.';

  @override
  String get storagePermissionsRequired =>
      'Les autorisations de stockage sont requises pour la synchronisation.';

  @override
  String updateAvailableTitle(String version) {
    return 'Mise à jour disponible : v$version';
  }

  @override
  String get updateAvailableTapToSeeNew => 'Appuyez pour voir les nouveautés';

  @override
  String get updateView => 'Afficher';

  @override
  String get updateAvailableDialogTitle => 'Mise à jour disponible';

  @override
  String updateVersionSubtitle(String version) {
    return 'Version $version';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'Actuelle : v$version';
  }

  @override
  String updateNewVersion(String version) {
    return 'Nouvelle : v$version';
  }

  @override
  String get updateWhatsNew => 'Nouveautés :';

  @override
  String get updateGitHub => 'GitHub';

  @override
  String get updateNoReleaseNotes => 'Aucune note de version fournie.';

  @override
  String get updateLater => 'Plus tard';

  @override
  String get updateDownloadApk => 'Télécharger l’APK';

  @override
  String get updateInstall => 'Mettre à jour';

  @override
  String get shareLinkTitle => 'Lien de partage';

  @override
  String get shareViaLink => 'Partager par lien';

  @override
  String get shareInServer => 'Partager sur le serveur';

  @override
  String get expiryDays => 'Expiration (jours)';

  @override
  String get expiryNever => 'Jamais';

  @override
  String get expiry1Day => '1 jour';

  @override
  String get expiry7Days => '7 jours';

  @override
  String get expiry30Days => '30 jours';

  @override
  String get expiry90Days => '90 jours';

  @override
  String get expiry180Days => '180 jours';

  @override
  String get expiry365Days => '365 jours';

  @override
  String get createLink => 'Créer le lien';

  @override
  String get sharedLinkCopied =>
      'Lien de partage copié dans le presse-papiers !';

  @override
  String failedToCopySharedLink(String error) {
    return 'Impossible de copier le lien de partage : $error';
  }

  @override
  String get cannotShareThisFileType =>
      'Ce type de fichier ne peut pas être partagé.';

  @override
  String failedToCreateShare(String error) {
    return 'Impossible de créer le partage : $error';
  }

  @override
  String get newFolderTitle => 'Créer un dossier';

  @override
  String get newFolderHint => 'Nom du dossier';

  @override
  String get newFolder => 'Nouveau dossier';

  @override
  String get folderCreated => 'Dossier créé.';

  @override
  String failedToCreateFolder(String error) {
    return 'Impossible de créer le dossier : $error';
  }

  @override
  String get creatingFolder => 'Création du dossier…';

  @override
  String get renameDialogTitle => 'Renommer';

  @override
  String get renameHint => 'Nouveau nom';

  @override
  String get enterNewName => 'Saisir un nouveau nom';

  @override
  String get renamedSuccessfully => 'Renommage réussi.';

  @override
  String renameFailed(String error) {
    return 'Échec du renommage : $error';
  }

  @override
  String get moveDialogTitle => 'Déplacer vers';

  @override
  String moveTo(String path) {
    return 'Déplacer vers : $path';
  }

  @override
  String get moveHere => 'Déplacer ici';

  @override
  String moveFailed(String error) {
    return 'Échec du déplacement : $error';
  }

  @override
  String get movedToFolder => 'Déplacé dans le dossier.';

  @override
  String copyFailed(String error) {
    return 'Échec de la copie : $error';
  }

  @override
  String get selectFolder => 'Sélectionner un dossier';

  @override
  String get useThisFolder => 'Utiliser ce dossier';

  @override
  String get storageRoot => 'Stockage';

  @override
  String get serverRoot => 'Racine';

  @override
  String deleteNItemsTitle(int count) {
    return 'Supprimer $count éléments ?';
  }

  @override
  String get deleteFilesTitle => 'Supprimer les fichiers ?';

  @override
  String deleteFilesBody(int count) {
    return 'Voulez-vous vraiment supprimer les $count éléments sélectionnés ? Cette action est irréversible.';
  }

  @override
  String get deletePermanently => 'Supprimer définitivement';

  @override
  String get deletePermanentlyTitle => 'Supprimer définitivement ?';

  @override
  String deletePermanentlyBody(String filename) {
    return '$filename sera supprimé définitivement.';
  }

  @override
  String get deleteFileTitle => 'Supprimer le fichier ?';

  @override
  String deleteFileBody(String filename) {
    return 'Voulez-vous vraiment supprimer $filename ? Cette action est irréversible.';
  }

  @override
  String get deleteServerFileTitle => 'Supprimer définitivement';

  @override
  String deleteServerFileBody(String filename) {
    return 'Voulez-vous vraiment supprimer définitivement « $filename » ? Cette action est irréversible.';
  }

  @override
  String get unshareItemsTitle => 'Arrêter le partage des éléments ?';

  @override
  String unshareItemsBody(int count) {
    return 'Voulez-vous vraiment arrêter le partage des $count éléments sélectionnés ? Ils seront retirés du dossier Partagés.';
  }

  @override
  String get unshare => 'Arrêter le partage';

  @override
  String get moveToTrash => 'Déplacer vers la corbeille';

  @override
  String get movedToTrash => 'Déplacé vers la corbeille.';

  @override
  String movedNItemsToTrash(int count) {
    return '$count éléments déplacés vers la corbeille.';
  }

  @override
  String failedToMoveToTrash(String error) {
    return 'Impossible de déplacer vers la corbeille : $error';
  }

  @override
  String deletedNItems(int count) {
    return '$count éléments supprimés.';
  }

  @override
  String failedToDelete(String error) {
    return 'Échec de la suppression : $error';
  }

  @override
  String failedToDeleteItem(String error) {
    return 'Échec de la suppression : $error';
  }

  @override
  String deletedFilename(String filename) {
    return '$filename supprimé.';
  }

  @override
  String get failedToOpenFile => 'Impossible d’ouvrir le fichier';

  @override
  String fileDownloadFailed(String error) {
    return 'Échec du téléchargement du fichier : $error';
  }

  @override
  String get downloading => 'Téléchargement…';

  @override
  String get downloadingFile => 'Téléchargement du fichier…';

  @override
  String downloadComplete(String filename) {
    return 'Téléchargement terminé : $filename';
  }

  @override
  String downloadFailed(String error) {
    return 'Échec du téléchargement : $error';
  }

  @override
  String get failedToDownloadPreview =>
      'Impossible de télécharger l’aperçu du fichier';

  @override
  String uploadComplete(String filename) {
    return 'Importation terminée : $filename';
  }

  @override
  String uploadFailed(String error) {
    return 'Échec de l’importation : $error';
  }

  @override
  String get failedToPickFiles => 'Impossible de sélectionner les fichiers';

  @override
  String uploadedNItems(int count) {
    return '$count élément(s) importé(s)';
  }

  @override
  String get copiedLinkToClipboard => 'Lien copié dans le presse-papiers.';

  @override
  String failedToCopyLink(String error) {
    return 'Impossible de copier le lien : $error';
  }

  @override
  String get selectingAll => 'Sélection de tous les éléments…';

  @override
  String get allItemsSelected => 'Tous les éléments sont sélectionnés.';

  @override
  String get failedToLoadSearchResults =>
      'Impossible de charger les résultats de recherche';

  @override
  String get shareNotSupportedForType =>
      'Le partage n’est pas pris en charge pour ce type de fichier.';

  @override
  String nSelected(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String get noServerSelected => 'Aucun serveur sélectionné';

  @override
  String get pleaseConnectToServerFirst =>
      'Connectez-vous d’abord à un serveur.';

  @override
  String get signInRequired => 'Connexion requise';

  @override
  String pleaseSignInToServer(String serverName) {
    return 'Connectez-vous d’abord à $serverName.';
  }

  @override
  String get connectingToServer => 'Connexion au serveur…';

  @override
  String connectedToServer(String serverName) {
    return 'Connecté à $serverName.';
  }

  @override
  String connectionFailed(String error) {
    return 'Échec de la connexion : $error';
  }

  @override
  String failedToConnect(String error) {
    return 'Impossible de se connecter : $error';
  }

  @override
  String authFailed(String error) {
    return 'Échec de l’authentification : $error';
  }

  @override
  String get authFailedGeneric =>
      'Échec de l’authentification. Veuillez réessayer.';

  @override
  String biometricLoginFailed(String error) {
    return 'Échec de la connexion biométrique : $error';
  }

  @override
  String get biometricLoginFailedGeneric =>
      'Échec de la connexion biométrique.';

  @override
  String get noServerSessionToken =>
      'Aucun jeton de session serveur. Authentifiez à nouveau le serveur.';

  @override
  String failedToSaveServer(String error) {
    return 'Impossible d’enregistrer le serveur : $error';
  }

  @override
  String get addToFolder => 'Ajouter au dossier';

  @override
  String get loginTabLabel => 'Se connecter';

  @override
  String get registerTabLabel => 'S’inscrire';

  @override
  String get welcomeBack => 'Bon retour';

  @override
  String get signInToContinue => 'Connectez-vous pour continuer';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get joinTheServer => 'Rejoindre le serveur';

  @override
  String get usernameLabel => 'Nom d’utilisateur';

  @override
  String get usernameHint => 'Saisissez votre nom d’utilisateur';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get passwordHint => 'Saisissez votre mot de passe';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get logIn => 'Se connecter';

  @override
  String get loggingIn => 'Connexion…';

  @override
  String get registering => 'Inscription…';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get doNotHaveAccount =>
      'Vous n’avez pas de compte ? Passez à l’inscription.';

  @override
  String get alreadyHaveAccount =>
      'Vous avez déjà un compte ? Passez à la connexion.';

  @override
  String get usernameCannotBeEmpty =>
      'Le nom d’utilisateur ne peut pas être vide.';

  @override
  String get passwordCannotBeEmpty => 'Le mot de passe ne peut pas être vide.';

  @override
  String get usernameInvalid =>
      'Le nom d’utilisateur doit contenir 3 à 32 caractères : lettres, chiffres, _ ou -.';

  @override
  String get passwordTooShort =>
      'Le mot de passe doit comporter au moins 8 caractères.';

  @override
  String loginFailed(String error) {
    return 'Échec de la connexion : $error';
  }

  @override
  String registrationFailed(String error) {
    return 'Échec de l’inscription : $error';
  }

  @override
  String get resetPasswordTitle => 'Réinitialiser le mot de passe';

  @override
  String get enterResetCodeTitle => 'Saisir le code de réinitialisation';

  @override
  String get resetPasswordStep1Body =>
      'Saisissez votre nom d’utilisateur. Le code de vérification à 6 chiffres sera affiché dans les journaux ou la console du serveur.';

  @override
  String get resetPasswordStep2Body =>
      'Le code de vérification a été affiché dans la console du serveur. Saisissez le code à 6 chiffres et votre nouveau mot de passe.';

  @override
  String get resetCodeLabel => 'Code de réinitialisation';

  @override
  String get resetCodeHint => 'Saisir le code à 6 chiffres';

  @override
  String get newPasswordLabel => 'Nouveau mot de passe';

  @override
  String get newPasswordHint => 'Saisir le nouveau mot de passe';

  @override
  String get passwordResetSuccessfully => 'Mot de passe réinitialisé !';

  @override
  String get usernameIsRequired => 'Le nom d’utilisateur est requis.';

  @override
  String get codeAndPasswordRequired =>
      'Le code et le nouveau mot de passe sont requis.';

  @override
  String get failedToRequestReset =>
      'Impossible de demander la réinitialisation. Vérifiez l’URL du serveur.';

  @override
  String get failedToResetPassword =>
      'Impossible de réinitialiser le mot de passe. Vérifiez le code.';

  @override
  String get pleaseEnterServerUrlFirst => 'Saisissez d’abord l’URL du serveur.';

  @override
  String get sendCode => 'Envoyer le code';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get sectionBackupSync => 'Sauvegarde et synchronisation';

  @override
  String get sectionStorageCache => 'Stockage et cache';

  @override
  String get sectionSecurityBehavior => 'Sécurité et comportement';

  @override
  String get sectionAboutUpdates => 'À propos et mises à jour';

  @override
  String get sectionAppearance => 'Apparence et personnalisation';

  @override
  String get noServersConfiguredSync => 'Aucun serveur configuré';

  @override
  String get addServerBeforeSync =>
      'Ajoutez un serveur avant de configurer la synchronisation.';

  @override
  String get selectServerToConfigureSync =>
      'Sélectionnez un serveur pour configurer ses paramètres de synchronisation.';

  @override
  String get activeServerSuffix => '· actif';

  @override
  String get folderAndCategorySync =>
      'Synchronisation des dossiers et catégories';

  @override
  String get keepCategoriesSynced =>
      'Maintenir les catégories ou dossiers locaux sélectionnés synchronisés avec ce serveur.';

  @override
  String get addServerBeforeSyncEnable =>
      'Ajoutez un serveur avant d’activer la synchronisation.';

  @override
  String get onlyOnWifi => 'Uniquement en Wi‑Fi';

  @override
  String get onlyWhileCharging => 'Uniquement pendant la charge';

  @override
  String get serverTargetDirectory => 'Dossier cible sur le serveur';

  @override
  String get serverTargetDirectoryHint => '/backup/mobile_phone';

  @override
  String get synchronizationFrequency => 'Fréquence de synchronisation';

  @override
  String get syncNow => 'Synchroniser maintenant';

  @override
  String get syncing => 'Synchronisation…';

  @override
  String get categoriesToSynchronize => 'Catégories à synchroniser';

  @override
  String get noCategoriesSelected => 'Aucune catégorie sélectionnée.';

  @override
  String nCategoriesSelected(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String get foldersToSynchronize => 'Dossiers à synchroniser';

  @override
  String get noCustomFolders => 'Aucun dossier personnalisé configuré.';

  @override
  String nFolders(int count) {
    return '$count dossier(s)';
  }

  @override
  String get addFolder => 'Ajouter un dossier';

  @override
  String get removeFolder => 'Supprimer le dossier';

  @override
  String get removeServer => 'Supprimer le serveur';

  @override
  String get syncFreqEvery15Min => 'Toutes les 15 minutes';

  @override
  String get syncFreqEvery30Min => 'Toutes les 30 minutes';

  @override
  String get syncFreqEvery1Hour => 'Toutes les heures';

  @override
  String syncFreqEveryNHours(int hours) {
    return 'Toutes les $hours heures';
  }

  @override
  String syncFreqEveryNMin(int minutes) {
    return 'Toutes les $minutes minutes';
  }

  @override
  String get syncFreqDaily => 'Chaque jour';

  @override
  String get chooseSyncFrequencyTitle =>
      'Choisir la fréquence de synchronisation';

  @override
  String get cacheSize => 'Taille du cache';

  @override
  String get refreshTooltip => 'Actualiser';

  @override
  String get cacheLimit => 'Limite du cache';

  @override
  String get downloadPath => 'Dossier de téléchargement';

  @override
  String get defaultDownloadFolder => 'Dossier CrowleysCloud par défaut';

  @override
  String get clearCache => 'Vider le cache';

  @override
  String get clearCacheTitle => 'Vider le cache ?';

  @override
  String get clearCacheBody =>
      'Supprime les miniatures locales et les listes de serveurs mises en cache.';

  @override
  String get downloadPathDialogTitle => 'Dossier de téléchargement';

  @override
  String get downloadPathHint => '/storage/emulated/0/CrowleysCloud';

  @override
  String get useDefault => 'Utiliser le dossier par défaut';

  @override
  String get serverTargetDirDialogTitle => 'Dossier cible sur le serveur';

  @override
  String get requireLogin => 'Exiger une connexion';

  @override
  String get biometricLogin => 'Connexion biométrique';

  @override
  String get biometricLoginSubtitle =>
      'Autoriser la connexion avec des identifiants enregistrés via la biométrie.';

  @override
  String get biometricsNotAvailable =>
      'La biométrie n’est pas disponible sur cet appareil.';

  @override
  String get showHiddenFiles => 'Afficher les fichiers masqués';

  @override
  String get showHiddenFilesSubtitle =>
      'Afficher les fichiers et dossiers commençant par un point.';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String changePasswordSubtitle(String serverName) {
    return 'Mettre à jour le mot de passe pour $serverName.';
  }

  @override
  String get addServerBeforeChangePassword =>
      'Ajoutez un serveur avant de changer le mot de passe.';

  @override
  String get deleteUserAccount => 'Supprimer le compte utilisateur';

  @override
  String get deleteUserAccountSubtitle =>
      'Supprime l’utilisateur et tous les fichiers privés du cloud.';

  @override
  String get deleteAccountTitle => 'Supprimer le compte ?';

  @override
  String deleteAccountBody(String serverName) {
    return 'Cette opération supprime définitivement votre compte sur $serverName et tous les fichiers stockés dans votre dossier cloud privé. Elle est irréversible.';
  }

  @override
  String get deleteAccountButton => 'Supprimer le compte';

  @override
  String get changePasswordDialogTitle => 'Changer le mot de passe';

  @override
  String get newPasswordFieldLabel => 'Nouveau mot de passe';

  @override
  String get confirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get enterNewPassword => 'Saisissez un nouveau mot de passe.';

  @override
  String get passwordUpdated => 'Mot de passe mis à jour.';

  @override
  String passwordChangeFailed(String error) {
    return 'Échec du changement de mot de passe : $error';
  }

  @override
  String get passwordChangeFailedGeneric =>
      'Échec du changement de mot de passe.';

  @override
  String get accountDeleted => 'Compte supprimé.';

  @override
  String accountDeletionFailed(String error) {
    return 'Échec de la suppression du compte : $error';
  }

  @override
  String get accountDeletionFailedGeneric =>
      'Échec de la suppression du compte.';

  @override
  String get checkForUpdates => 'Rechercher des mises à jour';

  @override
  String get checkingForUpdates => 'Vérification des versions GitHub…';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String appIsUpToDate(String version) {
    return 'Crowley\'s Cloud est à jour (v$version).';
  }

  @override
  String get updateCheckFailed =>
      'Impossible de vérifier les mises à jour. Veuillez réessayer plus tard.';

  @override
  String get themeModeTitle => 'Mode de thème';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeCustom => 'Personnalisé';

  @override
  String get themeDarkFull => 'Thème sombre';

  @override
  String get themeLightFull => 'Thème clair';

  @override
  String get themeCustomFull => 'Thème personnalisé';

  @override
  String get accentColor => 'Couleur d’accentuation';

  @override
  String get primaryAccentColor => 'Couleur d’accentuation principale';

  @override
  String get selectAccentColor => 'Sélectionner la couleur d’accentuation';

  @override
  String get backgroundColor => 'Couleur d’arrière-plan';

  @override
  String get surfaceColor => 'Couleur de surface';

  @override
  String get textColor => 'Couleur du texte';

  @override
  String get subtextColor => 'Couleur du texte secondaire';

  @override
  String get borderColor => 'Couleur de bordure';

  @override
  String get fontSizeScale => 'Échelle de taille de police';

  @override
  String selectColor(String title) {
    return 'Sélectionner $title';
  }

  @override
  String get categoriesToSyncDialogTitle => 'Catégories à synchroniser';

  @override
  String get categoriesToSyncBody =>
      'Choisissez une ou plusieurs catégories. Vous pouvez aussi tout laisser décoché.';

  @override
  String get syncCategorySectionMedia => 'Médias';

  @override
  String get syncCategorySectionAudioDocs => 'Audio et documents';

  @override
  String get syncCategorySectionOther => 'Autres';

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get noSyncHasRunYet =>
      'Aucune synchronisation n’a encore été exécutée.';

  @override
  String lastRunAt(String date) {
    return 'Dernière exécution : $date';
  }

  @override
  String syncResultSuccess(int uploaded, int skipped) {
    return '$uploaded synchronisé(s), $skipped ignoré(s).';
  }

  @override
  String get syncResultNoFiles =>
      'Aucun fichier sélectionné pour la synchronisation.';

  @override
  String syncResultPartial(int uploaded, int failed) {
    return '$uploaded synchronisé(s), $failed échec(s).';
  }

  @override
  String get syncResultAuthRequired =>
      'Connectez-vous avant la synchronisation.';

  @override
  String get syncResultUnreachable => 'Serveur inaccessible. Connexion perdue.';

  @override
  String get syncResultFailed => 'Échec de la synchronisation.';

  @override
  String get serverSetupAddServer => 'Ajouter un serveur';

  @override
  String get serverSetupCardTitle => 'Connecter le serveur';

  @override
  String get serverSetupCardSubtitle =>
      'Ajoutez votre serveur de fichiers personnel et connectez-vous.';

  @override
  String get serverSetupSubmitButton => 'Enregistrer le serveur';

  @override
  String get serverNameLabel => 'Nom du serveur';

  @override
  String get serverNameHint => 'Home NAS';

  @override
  String get baseUrlLabel => 'Base URL';

  @override
  String get baseUrlHint => 'https://cloud.example.com';

  @override
  String get allFieldsRequired => 'Tous les champs sont requis.';

  @override
  String get localFilesTitle => 'Fichiers locaux';

  @override
  String get serverFilesTitle => 'Fichiers du serveur';

  @override
  String get restoreItemsTitle => 'Restaurer les éléments';

  @override
  String restoreItemsBody(int count) {
    return 'Voulez-vous vraiment restaurer $count élément(s) ?';
  }

  @override
  String get permanentlyDeleteTitle => 'Supprimer définitivement';

  @override
  String permanentlyDeleteBody(int count) {
    return 'Voulez-vous vraiment supprimer définitivement $count élément(s) ? Cette action est irréversible.';
  }

  @override
  String get trashIsEmpty => 'La corbeille est vide.';

  @override
  String trashRetentionInfo(int days) {
    return 'Les éléments de la corbeille sont supprimés automatiquement après $days jours.';
  }

  @override
  String get deletionDate => 'Date de suppression';

  @override
  String get deletePermanentlyAction => 'Supprimer définitivement';

  @override
  String get conflictFileAlreadyExists => 'Le fichier existe déjà';

  @override
  String conflictNofM(int current, int total) {
    return 'Conflit $current sur $total';
  }

  @override
  String get conflictAFileNamed => 'Un fichier nommé ';

  @override
  String get conflictAlreadyExistsAt => ' existe déjà à l’emplacement ';

  @override
  String get conflictAlreadyExistsInFolder => ' existe déjà dans ce dossier.';

  @override
  String get conflictInFolder => 'Dans le dossier';

  @override
  String get conflictFromTrash => 'Depuis la corbeille';

  @override
  String get conflictExisting => 'Existant';

  @override
  String get conflictNewUpload => 'Nouvel import';

  @override
  String conflictSizeLabel(String size) {
    return 'Taille : $size';
  }

  @override
  String conflictDateLabel(String date) {
    return 'Date : $date';
  }

  @override
  String conflictDeletedLabel(String date) {
    return 'Supprimé : $date';
  }

  @override
  String conflictApplyToRemaining(int count) {
    return 'Appliquer aux $count conflit(s) restants';
  }

  @override
  String get conflictKeepAllCopies => 'Conserver toutes les copies';

  @override
  String get conflictOverwriteAll => 'Tout remplacer';

  @override
  String get conflictRestoreAllAsCopies => 'Tout restaurer comme copies';

  @override
  String get conflictRestoreAsCopy => 'Restaurer comme copie';

  @override
  String get conflictOverwriteAllRemaining =>
      'Remplacer tous les éléments restants';

  @override
  String get conflictSkipAll => 'Tout ignorer';

  @override
  String get conflictSkipAllRemaining => 'Ignorer tous les éléments restants';

  @override
  String get conflictSkip => 'Ignorer';

  @override
  String get conflictOverwrite => 'Remplacer';

  @override
  String get transfersTitle => 'Transferts';

  @override
  String get transferResume => 'Reprendre';

  @override
  String get transferPause => 'Mettre en pause';

  @override
  String get transferCancel => 'Annuler';

  @override
  String get transferResumeAll => 'Tout reprendre';

  @override
  String get transferPauseAll => 'Tout mettre en pause';

  @override
  String get transferCancelAll => 'Tout annuler';

  @override
  String get transferCancelFile => 'Annuler le fichier';

  @override
  String get noTransfers => 'Aucun transfert.';

  @override
  String get transferStatusQueued => 'En attente';

  @override
  String get transferStatusRunning => 'En cours';

  @override
  String get transferStatusPaused => 'En pause';

  @override
  String get transferStatusCompleted => 'Terminé';

  @override
  String get transferStatusFailed => 'Échec';

  @override
  String get transferStatusCanceled => 'Annulé';

  @override
  String get themePresetsSection => 'Préréglages';

  @override
  String get themeCustomPaletteSection => 'Palette personnalisée';

  @override
  String get themeHexRgbLabel => 'HEX RGB Code';

  @override
  String get themeHexRgbHint => '#FA5252';

  @override
  String get imageViewerNoFetchHandler =>
      'Aucun gestionnaire de récupération configuré';

  @override
  String get imageViewerFailedToLoad => 'Impossible de charger l’image';

  @override
  String errorDeletingFile(String filename, String error) {
    return 'Erreur lors de la suppression de $filename : $error';
  }

  @override
  String errorReadingFile(String error) {
    return 'Erreur de lecture du fichier : $error';
  }

  @override
  String get syncChannelName => 'Synchronisation en arrière-plan';

  @override
  String get syncChannelDescription =>
      'Affiche l’état de synchronisation des fichiers en arrière-plan.';

  @override
  String get storageStatsTitle => 'Statistiques de stockage';

  @override
  String get storageStatsUsedSpace => 'Espace utilisé';

  @override
  String get storageStatsTotalFiles => 'Nombre total de fichiers';

  @override
  String storageStatsNItems(int count) {
    return '$count éléments';
  }

  @override
  String userFallback(int userId) {
    return 'Utilisateur #$userId';
  }

  @override
  String get biometricUnlockReason =>
      'Déverrouillez les identifiants enregistrés pour Crowley\'s Cloud.';

  @override
  String get tokenLifetimeEveryOpen => 'À chaque ouverture de l’application';

  @override
  String get tokenLifetimeOneHour => 'Après 1 heure';

  @override
  String get tokenLifetime1Hour => 'Après 1 heure';

  @override
  String get tokenLifetimeOneDay => 'Après 1 jour';

  @override
  String get tokenLifetime1Day => 'Après 1 jour';

  @override
  String get tokenLifetimeOneWeek => 'Après 1 semaine';

  @override
  String get tokenLifetime1Week => 'Après 1 semaine';

  @override
  String get tokenLifetimeOneMonth => 'Après 1 mois';

  @override
  String get tokenLifetime1Month => 'Après 1 mois';

  @override
  String get tokenLifetimeThreeMonths => 'Après 3 mois';

  @override
  String get tokenLifetime3Months => 'Après 3 mois';

  @override
  String get tokenLifetimeNever => 'Jamais sur cet appareil';

  @override
  String get cacheLimitUnlimited => 'Illimité';

  @override
  String get syncCategoryOtherFiles => 'Autres fichiers';

  @override
  String get internalStorage => 'Stockage interne';

  @override
  String get localStorageRootName => 'Stockage interne';

  @override
  String syncNotificationSyncingWith(String serverName) {
    return 'Synchronisation avec $serverName';
  }

  @override
  String syncNotificationPausedTitle(String serverName) {
    return 'Synchronisation avec $serverName en pause';
  }

  @override
  String get syncNotificationUnreachableBody =>
      'Le serveur est inaccessible. La synchronisation en arrière-plan est suspendue jusqu’à l’ouverture de l’application.';

  @override
  String get syncNotificationAuthRequiredBody =>
      'Authentification requise. Ouvrez l’application pour vous connecter.';

  @override
  String syncNotificationFailedTitle(String serverName) {
    return 'Échec de la synchronisation avec $serverName';
  }

  @override
  String get syncNotificationGenericErrorBody =>
      'Une erreur s’est produite pendant la synchronisation.';

  @override
  String syncNotificationCompleteTitle(String serverName) {
    return 'Synchronisation avec $serverName terminée';
  }

  @override
  String get syncNotificationCompleteBody => 'Synchronisation terminée.';

  @override
  String get syncStatusConnecting => 'Connexion au serveur…';

  @override
  String syncStatusConnectionLost(String serverName) {
    return 'Impossible de se connecter à $serverName. Connexion perdue.';
  }

  @override
  String syncResultServerUnreachableWithServer(String serverName) {
    return 'Impossible de se connecter à $serverName. Connexion perdue.';
  }

  @override
  String get syncStatusScanningFiles => 'Analyse des fichiers sur l’appareil…';

  @override
  String get syncStatusNoFilesFound => 'Aucun fichier à synchroniser trouvé.';

  @override
  String get syncStatusNoFilesSelected =>
      'Aucun fichier sélectionné pour la synchronisation.';

  @override
  String syncStatusCalculatingChecksum(
    int current,
    int total,
    String filename,
  ) {
    return 'Calcul de la somme de contrôle ($current/$total) : $filename';
  }

  @override
  String get syncStatusCheckingDuplicates =>
      'Recherche de doublons sur le serveur…';

  @override
  String syncStatusSyncingFile(int current, int total, String filename) {
    return 'Synchronisation ($current/$total) : $filename';
  }

  @override
  String get syncStatusCompleting => 'Finalisation de la synchronisation…';

  @override
  String get showingCachedFiles => 'Affichage des fichiers mis en cache.';

  @override
  String get showingCachedFilesRefreshFailed =>
      'Affichage des fichiers mis en cache. Échec de l’actualisation.';

  @override
  String get downloadCanceled => 'Téléchargement annulé.';

  @override
  String downloadedNFilesToPath(int count, String path) {
    return '$count fichier(s) téléchargé(s) vers $path';
  }

  @override
  String downloadedNFilesFailedM(int downloaded, int failed, String detail) {
    return '$downloaded fichier(s) téléchargé(s), $failed échec(s) : $detail';
  }

  @override
  String downloadedNFilesWithFailures(int count, int failed, String error) {
    return '$count fichier(s) téléchargé(s), $failed échec(s) : $error';
  }

  @override
  String createdNShareLinks(int count) {
    return '$count lien(s) de partage créé(s).';
  }

  @override
  String get failedToCreateShareLinks =>
      'Impossible de créer le(s) lien(s) de partage.';

  @override
  String get alreadyInSharedScope => 'Déjà dans l’espace partagé.';

  @override
  String sharedNItemsInServer(int count) {
    return '$count élément(s) partagé(s) sur le serveur.';
  }

  @override
  String sharedNItemsWithFailures(int count, int failed) {
    return '$count élément(s) partagé(s), $failed échec(s).';
  }

  @override
  String sharedNItemsFailedM(int shared, int failed) {
    return '$shared élément(s) partagé(s), $failed échec(s).';
  }

  @override
  String get folderNameCannotBeEmpty =>
      'Le nom du dossier ne peut pas être vide.';

  @override
  String get folderAlreadyExists => 'Le dossier existe déjà.';

  @override
  String get folderCreationOnlyInAllFiles =>
      'La création de dossiers n’est disponible que dans Tous les fichiers.';

  @override
  String get currentDirectoryUnavailable =>
      'Le dossier actuel n’est pas disponible.';

  @override
  String get nothingSelected => 'Aucun élément sélectionné.';

  @override
  String get destinationFolderDoesNotExist =>
      'Le dossier de destination n’existe pas.';

  @override
  String cannotMoveFolderIntoItself(String name) {
    return 'Impossible de déplacer le dossier « $name » dans lui-même.';
  }

  @override
  String failedToMoveItem(String name, String error) {
    return 'Impossible de déplacer $name : $error';
  }

  @override
  String movedNItems(int count) {
    return '$count élément(s) déplacé(s).';
  }

  @override
  String movedNItemsWithFailures(int count, int failed) {
    return '$count élément(s) déplacé(s), $failed échec(s).';
  }

  @override
  String movedNItemsFailedM(int moved, int failed) {
    return '$moved élément(s) déplacé(s), $failed échec(s).';
  }

  @override
  String get failedToMoveSelectedItems =>
      'Impossible de déplacer les éléments sélectionnés.';

  @override
  String get noFilesWereMoved => 'Aucun fichier n’a été déplacé.';

  @override
  String renamedOldToNew(String oldName, String newName) {
    return '« $oldName » a été renommé en « $newName ».';
  }

  @override
  String renamedFileFromTo(String oldName, String newName) {
    return '« $oldName » a été renommé en « $newName ».';
  }

  @override
  String failedToRenameWithStatus(String name, int statusCode) {
    return 'Impossible de renommer « $name » ($statusCode).';
  }

  @override
  String failedToRenameFileWithCode(String name, int statusCode) {
    return 'Impossible de renommer « $name » ($statusCode).';
  }

  @override
  String failedToRenameWithError(String name, String error) {
    return 'Impossible de renommer « $name » : $error';
  }

  @override
  String failedToRenameFile(String name, String error) {
    return 'Impossible de renommer « $name » : $error';
  }

  @override
  String get renameConflictAlreadyExists =>
      'Échec du renommage : un fichier ou dossier portant ce nom existe déjà.';

  @override
  String get renameFailedAlreadyExists =>
      'Échec du renommage : un fichier ou dossier portant ce nom existe déjà.';

  @override
  String failedToCreateFolderWithCode(int statusCode) {
    return 'Impossible de créer le dossier ($statusCode).';
  }

  @override
  String deletedNItemsFailedM(int deleted, int failed) {
    return '$deleted élément(s) supprimé(s), $failed échec(s).';
  }

  @override
  String transferSummaryFiles(int percent, int completed, int total) {
    return '$percent%  $completed/$total fichiers';
  }

  @override
  String transferSummaryProgress(int percent, int completed, int total) {
    return '$percent%  $completed/$total fichiers';
  }

  @override
  String get downloadFailedGeneric => 'Échec du téléchargement';

  @override
  String uploadedNItemsWithFailures(int uploaded, int failed) {
    return '$uploaded élément(s) importé(s), $failed échec(s)';
  }

  @override
  String uploadedNItemsFailedM(int uploaded, int failed) {
    return '$uploaded élément(s) importé(s), $failed échec(s).';
  }

  @override
  String uploadSummaryFailedCount(int count) {
    return ', $count échec(s)';
  }

  @override
  String uploadLocalPathEmpty(String name) {
    return '$name : le chemin local est vide';
  }

  @override
  String uploadErrorLocalPathEmpty(String name) {
    return '$name : le chemin local est vide';
  }

  @override
  String get directoryUploadFailed => 'Échec de l’importation du dossier';

  @override
  String get uploadDirectoryFailed => 'Échec de l’importation du dossier';

  @override
  String get localFileNotFound => 'Fichier local introuvable';

  @override
  String get uploadErrorLocalFileNotFound => 'Fichier local introuvable';

  @override
  String get noSessionToken => 'Aucun jeton de session actif';

  @override
  String get uploadErrorNoSessionToken => 'Aucun jeton de session actif';

  @override
  String get serverDisconnectedStatus => 'Serveur déconnecté';

  @override
  String get serverDisconnected => 'Serveur déconnecté';

  @override
  String get serverIsUnreachable => 'Le serveur est inaccessible.';

  @override
  String get serverUnreachable => 'Le serveur est inaccessible.';

  @override
  String get uploadErrorLocalDirectoryNotFound => 'Dossier local introuvable';

  @override
  String get uploadErrorFailedToScanDirectory =>
      'Impossible d’analyser le dossier';

  @override
  String uploadErrorFolderCreateHttp(int statusCode) {
    return 'Échec de la création du dossier (HTTP $statusCode)';
  }

  @override
  String get authErrorMissingAccessToken =>
      'Jeton d’accès manquant dans la réponse';

  @override
  String get authErrorMissingRefreshToken =>
      'Jeton de renouvellement manquant dans la réponse';

  @override
  String get authErrorNoSavedCredentials =>
      'Aucun identifiant enregistré disponible';

  @override
  String get authErrorNoRefreshToken =>
      'Aucun jeton de renouvellement disponible';

  @override
  String get authErrorNoActiveSession => 'Aucune session active disponible';

  @override
  String get authErrorNoSavedUsername =>
      'Aucun nom d’utilisateur enregistré disponible';

  @override
  String get updateNoReleasesPublished =>
      'Aucune version publiée pour le moment.';

  @override
  String get language => 'Langue';
}
