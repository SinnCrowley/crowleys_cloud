// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Crowley\'s Cloud';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get rename => 'Umbenennen';

  @override
  String get close => 'Schließen';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get loading => 'Wird geladen...';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get error => 'Fehler';

  @override
  String errorWithMessage(String message) {
    return 'Fehler: $message';
  }

  @override
  String get unknown => 'Unbekannt';

  @override
  String get upload => 'Hochladen';

  @override
  String get download => 'Herunterladen';

  @override
  String get share => 'Teilen';

  @override
  String get copy => 'Kopieren';

  @override
  String get move => 'Verschieben';

  @override
  String get restore => 'Wiederherstellen';

  @override
  String get apply => 'Anwenden';

  @override
  String get create => 'Erstellen';

  @override
  String get clear => 'Leeren';

  @override
  String get add => 'Hinzufügen';

  @override
  String get remove => 'Entfernen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get switchLabel => 'Wechseln';

  @override
  String get search => 'Suchen';

  @override
  String get name => 'Name';

  @override
  String get date => 'Datum';

  @override
  String get size => 'Größe';

  @override
  String get type => 'Typ';

  @override
  String get ascending => 'Aufsteigend';

  @override
  String get descending => 'Absteigend';

  @override
  String get allFiles => 'Alle';

  @override
  String get categoryImages => 'Bilder';

  @override
  String get categoryPhotos => 'Fotos';

  @override
  String get categoryVideos => 'Videos';

  @override
  String get categoryAudio => 'Audio';

  @override
  String get categoryDocuments => 'Dokumente';

  @override
  String get categoryArchives => 'Archive';

  @override
  String get categoryShared => 'Geteilt';

  @override
  String get categoryOther => 'Sonstiges';

  @override
  String get categoryOtherFiles => 'Andere Dateien';

  @override
  String get noFilesFound => 'Keine Dateien gefunden.';

  @override
  String get noFilesInFolder => 'Keine Dateien in diesem Ordner.';

  @override
  String get thisActionCannotBeUndone =>
      'Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get passwordsDoNotMatch => 'Passwörter stimmen nicht überein.';

  @override
  String get navLocalFiles => 'Lokale Dateien';

  @override
  String get navServerFiles => 'Serverdateien';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get navTrash => 'Papierkorb';

  @override
  String get navLocal => 'Lokal';

  @override
  String get navServer => 'Server';

  @override
  String get addServer => 'Server hinzufügen';

  @override
  String get noServersConfigured => 'Keine Server konfiguriert.';

  @override
  String get addAServerInSettings =>
      'Fügen Sie in den Einstellungen einen Server hinzu.';

  @override
  String get addFirstServerHint =>
      'Fügen Sie Ihren ersten Server hinzu, um fortzufahren.';

  @override
  String get noServersConfiguredYet => 'Noch keine Server konfiguriert.';

  @override
  String get crowleysCloudSetup => 'Einrichtung von Crowley\'s Cloud';

  @override
  String get connect => 'Verbinden';

  @override
  String get connecting => 'Verbindung wird hergestellt...';

  @override
  String get connected => 'Verbunden';

  @override
  String get disconnected => 'Getrennt';

  @override
  String get switchServer => 'Server wechseln';

  @override
  String get chooseOtherServer => 'Anderen Server auswählen';

  @override
  String get switchServerTitle => 'Server wechseln?';

  @override
  String switchServerBody(String serverName) {
    return 'Aktiven Server zu „$serverName“ wechseln?';
  }

  @override
  String get chooseServer => 'Server auswählen';

  @override
  String get authenticationRequired => 'Anmeldung erforderlich';

  @override
  String signInToAccess(String serverName) {
    return 'Melden Sie sich an, um auf Dateien auf $serverName zuzugreifen';
  }

  @override
  String get signInWithPassword => 'Mit Passwort anmelden';

  @override
  String get useBiometrics => 'Biometrie verwenden';

  @override
  String get openingSignIn => 'Anmeldung wird geöffnet...';

  @override
  String get serverConnectionFailed => 'Serververbindung fehlgeschlagen';

  @override
  String get unableToConnectToServer =>
      'Verbindung zum aktiven Server nicht möglich.';

  @override
  String unableToConnectTo(String serverName) {
    return 'Verbindung zu $serverName nicht möglich.';
  }

  @override
  String get searchHint => 'Suchen...';

  @override
  String get searchFilesHint => 'Dateien suchen...';

  @override
  String get searchServerFilesHint => 'Serverdateien suchen...';

  @override
  String get searchTrashHint => 'Papierkorb durchsuchen...';

  @override
  String get storagePermissionRequired => 'Speicherberechtigung erforderlich';

  @override
  String get grantPermission => 'Berechtigung erteilen';

  @override
  String get permissionDeniedOpenSettings =>
      'Berechtigung verweigert. Erteilen Sie den Speicherzugriff in den Einstellungen.';

  @override
  String get manageStoragePermissionRequired =>
      'Die Berechtigung „Speicher verwalten“ ist erforderlich, um Ordner zu durchsuchen und auszuwählen.';

  @override
  String get storagePermissionsRequired =>
      'Für die Synchronisierung sind Speicherberechtigungen erforderlich.';

  @override
  String updateAvailableTitle(String version) {
    return 'Update verfügbar: v$version';
  }

  @override
  String get updateAvailableTapToSeeNew =>
      'Tippen Sie, um die Neuerungen zu sehen';

  @override
  String get updateView => 'Ansehen';

  @override
  String get updateAvailableDialogTitle => 'Update verfügbar';

  @override
  String updateVersionSubtitle(String version) {
    return 'Version $version';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'Aktuell: v$version';
  }

  @override
  String updateNewVersion(String version) {
    return 'Neu: v$version';
  }

  @override
  String get updateWhatsNew => 'Neuerungen:';

  @override
  String get updateGitHub => 'GitHub';

  @override
  String get updateNoReleaseNotes => 'Keine Versionshinweise verfügbar.';

  @override
  String get updateLater => 'Später';

  @override
  String get updateDownloadApk => 'APK herunterladen';

  @override
  String get updateInstall => 'Aktualisieren';

  @override
  String get shareLinkTitle => 'Freigabelink';

  @override
  String get shareViaLink => 'Per Link teilen';

  @override
  String get shareInServer => 'Auf dem Server teilen';

  @override
  String get expiryDays => 'Gültigkeit (Tage)';

  @override
  String get expiryNever => 'Nie';

  @override
  String get expiry1Day => '1 Tag';

  @override
  String get expiry7Days => '7 Tage';

  @override
  String get expiry30Days => '30 Tage';

  @override
  String get expiry90Days => '90 Tage';

  @override
  String get expiry180Days => '180 Tage';

  @override
  String get expiry365Days => '365 Tage';

  @override
  String get createLink => 'Link erstellen';

  @override
  String get sharedLinkCopied =>
      'Freigabelink wurde in die Zwischenablage kopiert!';

  @override
  String failedToCopySharedLink(String error) {
    return 'Freigabelink konnte nicht kopiert werden: $error';
  }

  @override
  String get cannotShareThisFileType =>
      'Dieser Dateityp kann nicht freigegeben werden.';

  @override
  String failedToCreateShare(String error) {
    return 'Freigabe konnte nicht erstellt werden: $error';
  }

  @override
  String get newFolderTitle => 'Ordner erstellen';

  @override
  String get newFolderHint => 'Ordnername';

  @override
  String get newFolder => 'Neuer Ordner';

  @override
  String get folderCreated => 'Ordner erstellt.';

  @override
  String failedToCreateFolder(String error) {
    return 'Ordner konnte nicht erstellt werden: $error';
  }

  @override
  String get creatingFolder => 'Ordner wird erstellt...';

  @override
  String get renameDialogTitle => 'Umbenennen';

  @override
  String get renameHint => 'Neuer Name';

  @override
  String get enterNewName => 'Neuen Namen eingeben';

  @override
  String get renamedSuccessfully => 'Erfolgreich umbenannt.';

  @override
  String renameFailed(String error) {
    return 'Umbenennen fehlgeschlagen: $error';
  }

  @override
  String get moveDialogTitle => 'Verschieben nach';

  @override
  String moveTo(String path) {
    return 'Verschieben nach: $path';
  }

  @override
  String get moveHere => 'Hierher verschieben';

  @override
  String moveFailed(String error) {
    return 'Verschieben fehlgeschlagen: $error';
  }

  @override
  String get movedToFolder => 'In den Ordner verschoben.';

  @override
  String copyFailed(String error) {
    return 'Kopieren fehlgeschlagen: $error';
  }

  @override
  String get selectFolder => 'Ordner auswählen';

  @override
  String get useThisFolder => 'Diesen Ordner verwenden';

  @override
  String get storageRoot => 'Speicher';

  @override
  String get serverRoot => 'Stammverzeichnis';

  @override
  String deleteNItemsTitle(int count) {
    return '$count Elemente löschen?';
  }

  @override
  String get deleteFilesTitle => 'Dateien löschen?';

  @override
  String deleteFilesBody(int count) {
    return 'Möchten Sie die $count ausgewählten Elemente wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String get deletePermanently => 'Dauerhaft löschen';

  @override
  String get deletePermanentlyTitle => 'Dauerhaft löschen?';

  @override
  String deletePermanentlyBody(String filename) {
    return '$filename wird dauerhaft gelöscht.';
  }

  @override
  String get deleteFileTitle => 'Datei löschen?';

  @override
  String deleteFileBody(String filename) {
    return 'Möchten Sie $filename wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String get deleteServerFileTitle => 'Dauerhaft löschen';

  @override
  String deleteServerFileBody(String filename) {
    return 'Möchten Sie „$filename“ wirklich dauerhaft löschen? Diese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String get unshareItemsTitle => 'Freigabe der Elemente aufheben?';

  @override
  String unshareItemsBody(int count) {
    return 'Möchten Sie die Freigabe der $count ausgewählten Elemente wirklich aufheben? Dadurch werden sie aus dem Ordner „Freigegeben“ entfernt.';
  }

  @override
  String get unshare => 'Freigabe aufheben';

  @override
  String get moveToTrash => 'In den Papierkorb verschieben';

  @override
  String get movedToTrash => 'In den Papierkorb verschoben.';

  @override
  String movedNItemsToTrash(int count) {
    return '$count Elemente in den Papierkorb verschoben.';
  }

  @override
  String failedToMoveToTrash(String error) {
    return 'Verschieben in den Papierkorb fehlgeschlagen: $error';
  }

  @override
  String deletedNItems(int count) {
    return '$count Elemente gelöscht.';
  }

  @override
  String failedToDelete(String error) {
    return 'Löschen fehlgeschlagen: $error';
  }

  @override
  String failedToDeleteItem(String error) {
    return 'Löschen fehlgeschlagen: $error';
  }

  @override
  String deletedFilename(String filename) {
    return '$filename gelöscht.';
  }

  @override
  String get failedToOpenFile => 'Datei konnte nicht geöffnet werden';

  @override
  String fileDownloadFailed(String error) {
    return 'Dateidownload fehlgeschlagen: $error';
  }

  @override
  String get downloading => 'Wird heruntergeladen...';

  @override
  String get downloadingFile => 'Datei wird heruntergeladen...';

  @override
  String downloadComplete(String filename) {
    return 'Download abgeschlossen: $filename';
  }

  @override
  String downloadFailed(String error) {
    return 'Download fehlgeschlagen: $error';
  }

  @override
  String get failedToDownloadPreview =>
      'Dateivorschau konnte nicht heruntergeladen werden';

  @override
  String uploadComplete(String filename) {
    return 'Upload abgeschlossen: $filename';
  }

  @override
  String uploadFailed(String error) {
    return 'Upload fehlgeschlagen: $error';
  }

  @override
  String get failedToPickFiles => 'Dateien konnten nicht ausgewählt werden';

  @override
  String uploadedNItems(int count) {
    return '$count Element(e) hochgeladen';
  }

  @override
  String get copiedLinkToClipboard => 'Link in die Zwischenablage kopiert.';

  @override
  String failedToCopyLink(String error) {
    return 'Link konnte nicht kopiert werden: $error';
  }

  @override
  String get selectingAll => 'Alles wird ausgewählt...';

  @override
  String get allItemsSelected => 'Alle Elemente ausgewählt.';

  @override
  String get failedToLoadSearchResults =>
      'Suchergebnisse konnten nicht geladen werden';

  @override
  String get shareNotSupportedForType =>
      'Freigabe wird für diesen Dateityp nicht unterstützt.';

  @override
  String nSelected(int count) {
    return '$count ausgewählt';
  }

  @override
  String get noServerSelected => 'Kein Server ausgewählt';

  @override
  String get pleaseConnectToServerFirst =>
      'Verbinden Sie sich zuerst mit einem Server.';

  @override
  String get signInRequired => 'Anmeldung erforderlich';

  @override
  String pleaseSignInToServer(String serverName) {
    return 'Melden Sie sich zuerst bei $serverName an.';
  }

  @override
  String get connectingToServer => 'Verbindung zum Server wird hergestellt...';

  @override
  String connectedToServer(String serverName) {
    return 'Mit $serverName verbunden.';
  }

  @override
  String connectionFailed(String error) {
    return 'Verbindung fehlgeschlagen: $error';
  }

  @override
  String failedToConnect(String error) {
    return 'Verbindung fehlgeschlagen: $error';
  }

  @override
  String authFailed(String error) {
    return 'Anmeldung fehlgeschlagen: $error';
  }

  @override
  String get authFailedGeneric =>
      'Anmeldung fehlgeschlagen. Bitte versuchen Sie es erneut.';

  @override
  String biometricLoginFailed(String error) {
    return 'Biometrische Anmeldung fehlgeschlagen: $error';
  }

  @override
  String get biometricLoginFailedGeneric =>
      'Biometrische Anmeldung fehlgeschlagen.';

  @override
  String get noServerSessionToken =>
      'Kein Serversitzungstoken. Melden Sie sich erneut am Server an.';

  @override
  String failedToSaveServer(String error) {
    return 'Server konnte nicht gespeichert werden: $error';
  }

  @override
  String get addToFolder => 'Zu Ordner hinzufügen';

  @override
  String get loginTabLabel => 'Anmelden';

  @override
  String get registerTabLabel => 'Registrieren';

  @override
  String get welcomeBack => 'Willkommen zurück';

  @override
  String get signInToContinue => 'Melden Sie sich an, um fortzufahren';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get joinTheServer => 'Dem Server beitreten';

  @override
  String get usernameLabel => 'Benutzername';

  @override
  String get usernameHint => 'Benutzernamen eingeben';

  @override
  String get passwordLabel => 'Passwort';

  @override
  String get passwordHint => 'Passwort eingeben';

  @override
  String get showPassword => 'Passwort anzeigen';

  @override
  String get hidePassword => 'Passwort ausblenden';

  @override
  String get confirmPassword => 'Passwort bestätigen';

  @override
  String get logIn => 'Anmelden';

  @override
  String get loggingIn => 'Anmeldung läuft...';

  @override
  String get registering => 'Registrierung läuft...';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get doNotHaveAccount => 'Noch kein Konto? Zur Registrierung wechseln.';

  @override
  String get alreadyHaveAccount =>
      'Sie haben bereits ein Konto? Zur Anmeldung wechseln.';

  @override
  String get usernameCannotBeEmpty => 'Benutzername darf nicht leer sein.';

  @override
  String get passwordCannotBeEmpty => 'Passwort darf nicht leer sein.';

  @override
  String get usernameInvalid =>
      'Der Benutzername muss 3–32 Zeichen lang sein und darf Buchstaben, Zahlen, _ oder - enthalten.';

  @override
  String get passwordTooShort =>
      'Das Passwort muss mindestens 8 Zeichen lang sein.';

  @override
  String loginFailed(String error) {
    return 'Anmeldung fehlgeschlagen: $error';
  }

  @override
  String registrationFailed(String error) {
    return 'Registrierung fehlgeschlagen: $error';
  }

  @override
  String get resetPasswordTitle => 'Passwort zurücksetzen';

  @override
  String get enterResetCodeTitle => 'Zurücksetzungscode eingeben';

  @override
  String get resetPasswordStep1Body =>
      'Geben Sie Ihren Benutzernamen ein. Der 6-stellige Bestätigungscode wird in den Serverprotokollen bzw. der Konsole ausgegeben.';

  @override
  String get resetPasswordStep2Body =>
      'Der Bestätigungscode wurde in der Serverkonsole ausgegeben. Geben Sie den 6-stelligen Code und Ihr neues Passwort ein.';

  @override
  String get resetCodeLabel => 'Zurücksetzungscode';

  @override
  String get resetCodeHint => '6-stelligen Code eingeben';

  @override
  String get newPasswordLabel => 'Neues Passwort';

  @override
  String get newPasswordHint => 'Neues Passwort eingeben';

  @override
  String get passwordResetSuccessfully => 'Passwort erfolgreich zurückgesetzt!';

  @override
  String get usernameIsRequired => 'Benutzername ist erforderlich.';

  @override
  String get codeAndPasswordRequired =>
      'Code und neues Passwort sind erforderlich.';

  @override
  String get failedToRequestReset =>
      'Zurücksetzung konnte nicht angefordert werden. Überprüfen Sie die Server-URL.';

  @override
  String get failedToResetPassword =>
      'Passwort konnte nicht zurückgesetzt werden. Überprüfen Sie den Code.';

  @override
  String get pleaseEnterServerUrlFirst =>
      'Geben Sie zuerst eine Server-URL ein.';

  @override
  String get sendCode => 'Code senden';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get sectionBackupSync => 'Sicherung und Synchronisierung';

  @override
  String get sectionStorageCache => 'Speicher und Cache';

  @override
  String get sectionSecurityBehavior => 'Sicherheit und Verhalten';

  @override
  String get sectionAboutUpdates => 'Info und Updates';

  @override
  String get sectionAppearance => 'Darstellung und Anpassung';

  @override
  String get noServersConfiguredSync => 'Keine Server konfiguriert';

  @override
  String get addServerBeforeSync =>
      'Fügen Sie vor dem Einrichten der Synchronisierung einen Server hinzu.';

  @override
  String get selectServerToConfigureSync =>
      'Wählen Sie einen Server aus, um dessen Synchronisierungseinstellungen zu konfigurieren.';

  @override
  String get activeServerSuffix => '· aktiv';

  @override
  String get folderAndCategorySync => 'Ordner- und Kategoriensynchronisierung';

  @override
  String get keepCategoriesSynced =>
      'Ausgewählte lokale Kategorien oder Ordner mit diesem Server synchron halten.';

  @override
  String get addServerBeforeSyncEnable =>
      'Fügen Sie einen Server hinzu, bevor Sie die Synchronisierung aktivieren.';

  @override
  String get onlyOnWifi => 'Nur über WLAN';

  @override
  String get onlyWhileCharging => 'Nur beim Laden';

  @override
  String get serverTargetDirectory => 'Zielordner auf dem Server';

  @override
  String get serverTargetDirectoryHint => '/backup/mobile_phone';

  @override
  String get synchronizationFrequency => 'Synchronisierungshäufigkeit';

  @override
  String get syncNow => 'Jetzt synchronisieren';

  @override
  String get syncing => 'Synchronisierung läuft...';

  @override
  String get categoriesToSynchronize => 'Zu synchronisierende Kategorien';

  @override
  String get noCategoriesSelected => 'Keine Kategorien ausgewählt.';

  @override
  String nCategoriesSelected(int count) {
    return '$count ausgewählt';
  }

  @override
  String get foldersToSynchronize => 'Zu synchronisierende Ordner';

  @override
  String get noCustomFolders =>
      'Keine benutzerdefinierten Ordner konfiguriert.';

  @override
  String nFolders(int count) {
    return '$count Ordner';
  }

  @override
  String get addFolder => 'Ordner hinzufügen';

  @override
  String get removeFolder => 'Ordner entfernen';

  @override
  String get removeServer => 'Server entfernen';

  @override
  String get syncFreqEvery15Min => 'Alle 15 Minuten';

  @override
  String get syncFreqEvery30Min => 'Alle 30 Minuten';

  @override
  String get syncFreqEvery1Hour => 'Stündlich';

  @override
  String syncFreqEveryNHours(int hours) {
    return 'Alle $hours Stunden';
  }

  @override
  String syncFreqEveryNMin(int minutes) {
    return 'Alle $minutes Minuten';
  }

  @override
  String get syncFreqDaily => 'Täglich';

  @override
  String get chooseSyncFrequencyTitle =>
      'Synchronisierungshäufigkeit auswählen';

  @override
  String get cacheSize => 'Cachegröße';

  @override
  String get refreshTooltip => 'Aktualisieren';

  @override
  String get cacheLimit => 'Cache-Limit';

  @override
  String get downloadPath => 'Downloadpfad';

  @override
  String get defaultDownloadFolder => 'Standardordner von CrowleysCloud';

  @override
  String get clearCache => 'Cache leeren';

  @override
  String get clearCacheTitle => 'Cache leeren?';

  @override
  String get clearCacheBody =>
      'Dadurch werden lokale Vorschaubilder und zwischengespeicherte Serverlisten entfernt.';

  @override
  String get downloadPathDialogTitle => 'Downloadpfad';

  @override
  String get downloadPathHint => '/storage/emulated/0/CrowleysCloud';

  @override
  String get useDefault => 'Standard verwenden';

  @override
  String get serverTargetDirDialogTitle => 'Zielordner auf dem Server';

  @override
  String get requireLogin => 'Anmeldung erforderlich';

  @override
  String get biometricLogin => 'Biometrische Anmeldung';

  @override
  String get biometricLoginSubtitle =>
      'Anmeldung mit gespeicherten Zugangsdaten per Biometrie erlauben.';

  @override
  String get biometricsNotAvailable =>
      'Biometrie ist auf diesem Gerät nicht verfügbar.';

  @override
  String get showHiddenFiles => 'Ausgeblendete Dateien anzeigen';

  @override
  String get showHiddenFilesSubtitle =>
      'Dateien und Ordner mit führendem Punkt anzeigen.';

  @override
  String get changePassword => 'Passwort ändern';

  @override
  String changePasswordSubtitle(String serverName) {
    return 'Passwort für $serverName ändern.';
  }

  @override
  String get addServerBeforeChangePassword =>
      'Fügen Sie vor dem Ändern des Passworts einen Server hinzu.';

  @override
  String get deleteUserAccount => 'Benutzerkonto löschen';

  @override
  String get deleteUserAccountSubtitle =>
      'Löscht den Benutzer und alle privaten Cloud-Dateien.';

  @override
  String get deleteAccountTitle => 'Konto löschen?';

  @override
  String deleteAccountBody(String serverName) {
    return 'Dadurch wird Ihr Konto auf $serverName dauerhaft gelöscht und alle Dateien in Ihrem privaten Cloud-Ordner werden entfernt. Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get deleteAccountButton => 'Konto löschen';

  @override
  String get changePasswordDialogTitle => 'Passwort ändern';

  @override
  String get newPasswordFieldLabel => 'Neues Passwort';

  @override
  String get confirmPasswordLabel => 'Passwort bestätigen';

  @override
  String get enterNewPassword => 'Geben Sie ein neues Passwort ein.';

  @override
  String get passwordUpdated => 'Passwort aktualisiert.';

  @override
  String passwordChangeFailed(String error) {
    return 'Passwortänderung fehlgeschlagen: $error';
  }

  @override
  String get passwordChangeFailedGeneric => 'Passwortänderung fehlgeschlagen.';

  @override
  String get accountDeleted => 'Konto gelöscht.';

  @override
  String accountDeletionFailed(String error) {
    return 'Kontolöschung fehlgeschlagen: $error';
  }

  @override
  String get accountDeletionFailedGeneric => 'Kontolöschung fehlgeschlagen.';

  @override
  String get checkForUpdates => 'Nach Updates suchen';

  @override
  String get checkingForUpdates => 'GitHub-Releases werden geprüft...';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String appIsUpToDate(String version) {
    return 'Crowley\'s Cloud ist auf dem neuesten Stand (v$version).';
  }

  @override
  String get updateCheckFailed =>
      'Updates konnten nicht geprüft werden. Bitte versuchen Sie es später erneut.';

  @override
  String get themeModeTitle => 'Darstellungsmodus';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeCustom => 'Benutzerdefiniert';

  @override
  String get themeDarkFull => 'Dunkles Design';

  @override
  String get themeLightFull => 'Helles Design';

  @override
  String get themeCustomFull => 'Benutzerdefiniertes Design';

  @override
  String get accentColor => 'Akzentfarbe';

  @override
  String get primaryAccentColor => 'Primäre Akzentfarbe';

  @override
  String get selectAccentColor => 'Akzentfarbe auswählen';

  @override
  String get backgroundColor => 'Hintergrundfarbe';

  @override
  String get surfaceColor => 'Flächenfarbe';

  @override
  String get textColor => 'Textfarbe';

  @override
  String get subtextColor => 'Sekundäre Textfarbe';

  @override
  String get borderColor => 'Rahmenfarbe';

  @override
  String get fontSizeScale => 'Schriftgrößenskalierung';

  @override
  String selectColor(String title) {
    return '$title auswählen';
  }

  @override
  String get categoriesToSyncDialogTitle => 'Zu synchronisierende Kategorien';

  @override
  String get categoriesToSyncBody =>
      'Wählen Sie eine oder mehrere Kategorien. Sie können auch alles abgewählt lassen.';

  @override
  String get syncCategorySectionMedia => 'Medien';

  @override
  String get syncCategorySectionAudioDocs => 'Audio und Dokumente';

  @override
  String get syncCategorySectionOther => 'Sonstiges';

  @override
  String get clearAll => 'Alles löschen';

  @override
  String get noSyncHasRunYet =>
      'Es wurde noch keine Synchronisierung ausgeführt.';

  @override
  String lastRunAt(String date) {
    return 'Zuletzt ausgeführt: $date';
  }

  @override
  String syncResultSuccess(int uploaded, int skipped) {
    return '$uploaded synchronisiert, $skipped übersprungen.';
  }

  @override
  String get syncResultNoFiles =>
      'Keine Dateien zur Synchronisierung ausgewählt.';

  @override
  String syncResultPartial(int uploaded, int failed) {
    return '$uploaded synchronisiert, $failed fehlgeschlagen.';
  }

  @override
  String get syncResultAuthRequired =>
      'Melden Sie sich vor der Synchronisierung an.';

  @override
  String get syncResultUnreachable =>
      'Server nicht erreichbar. Verbindung verloren.';

  @override
  String get syncResultFailed => 'Synchronisierung fehlgeschlagen.';

  @override
  String get serverSetupAddServer => 'Server hinzufügen';

  @override
  String get serverSetupCardTitle => 'Mit Server verbinden';

  @override
  String get serverSetupCardSubtitle =>
      'Fügen Sie Ihren Dateiserver zu Hause hinzu und melden Sie sich an.';

  @override
  String get serverSetupSubmitButton => 'Server speichern';

  @override
  String get serverNameLabel => 'Servername';

  @override
  String get serverNameHint => 'Home NAS';

  @override
  String get baseUrlLabel => 'Base URL';

  @override
  String get baseUrlHint => 'https://cloud.example.com';

  @override
  String get allFieldsRequired => 'Alle Felder sind erforderlich.';

  @override
  String get localFilesTitle => 'Lokale Dateien';

  @override
  String get serverFilesTitle => 'Serverdateien';

  @override
  String get restoreItemsTitle => 'Elemente wiederherstellen';

  @override
  String restoreItemsBody(int count) {
    return 'Möchten Sie $count Element(e) wirklich wiederherstellen?';
  }

  @override
  String get permanentlyDeleteTitle => 'Dauerhaft löschen';

  @override
  String permanentlyDeleteBody(int count) {
    return 'Möchten Sie $count Element(e) wirklich dauerhaft löschen? Diese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String get trashIsEmpty => 'Der Papierkorb ist leer.';

  @override
  String trashRetentionInfo(int days) {
    return 'Elemente im Papierkorb werden nach $days Tagen automatisch gelöscht.';
  }

  @override
  String get deletionDate => 'Löschdatum';

  @override
  String get deletePermanentlyAction => 'Dauerhaft löschen';

  @override
  String get conflictFileAlreadyExists => 'Datei ist bereits vorhanden';

  @override
  String conflictNofM(int current, int total) {
    return 'Konflikt $current von $total';
  }

  @override
  String get conflictAFileNamed => 'Eine Datei mit dem Namen ';

  @override
  String get conflictAlreadyExistsAt => ' ist bereits vorhanden unter ';

  @override
  String get conflictAlreadyExistsInFolder =>
      ' ist bereits in diesem Ordner vorhanden.';

  @override
  String get conflictInFolder => 'Im Ordner';

  @override
  String get conflictFromTrash => 'Aus dem Papierkorb';

  @override
  String get conflictExisting => 'Vorhanden';

  @override
  String get conflictNewUpload => 'Neuer Upload';

  @override
  String conflictSizeLabel(String size) {
    return 'Größe: $size';
  }

  @override
  String conflictDateLabel(String date) {
    return 'Datum: $date';
  }

  @override
  String conflictDeletedLabel(String date) {
    return 'Gelöscht: $date';
  }

  @override
  String conflictApplyToRemaining(int count) {
    return 'Auf die verbleibenden $count Konflikte anwenden';
  }

  @override
  String get conflictKeepAllCopies => 'Alle Kopien behalten';

  @override
  String get conflictOverwriteAll => 'Alle überschreiben';

  @override
  String get conflictRestoreAllAsCopies => 'Alle als Kopien wiederherstellen';

  @override
  String get conflictRestoreAsCopy => 'Als Kopie wiederherstellen';

  @override
  String get conflictOverwriteAllRemaining =>
      'Alle verbleibenden überschreiben';

  @override
  String get conflictSkipAll => 'Alle überspringen';

  @override
  String get conflictSkipAllRemaining => 'Alle verbleibenden überspringen';

  @override
  String get conflictSkip => 'Überspringen';

  @override
  String get conflictOverwrite => 'Überschreiben';

  @override
  String get transfersTitle => 'Übertragungen';

  @override
  String get transferResume => 'Fortsetzen';

  @override
  String get transferPause => 'Pausieren';

  @override
  String get transferCancel => 'Abbrechen';

  @override
  String get transferResumeAll => 'Alle fortsetzen';

  @override
  String get transferPauseAll => 'Alle pausieren';

  @override
  String get transferCancelAll => 'Alle abbrechen';

  @override
  String get transferCancelFile => 'Datei abbrechen';

  @override
  String get noTransfers => 'Keine Übertragungen.';

  @override
  String get transferStatusQueued => 'In Warteschlange';

  @override
  String get transferStatusRunning => 'Läuft';

  @override
  String get transferStatusPaused => 'Pausiert';

  @override
  String get transferStatusCompleted => 'Abgeschlossen';

  @override
  String get transferStatusFailed => 'Fehlgeschlagen';

  @override
  String get transferStatusCanceled => 'Abgebrochen';

  @override
  String get themePresetsSection => 'Voreinstellungen';

  @override
  String get themeCustomPaletteSection => 'Benutzerdefinierte Palette';

  @override
  String get themeHexRgbLabel => 'HEX RGB Code';

  @override
  String get themeHexRgbHint => '#FA5252';

  @override
  String get imageViewerNoFetchHandler => 'Kein Abruf-Handler konfiguriert';

  @override
  String get imageViewerFailedToLoad => 'Bild konnte nicht geladen werden';

  @override
  String errorDeletingFile(String filename, String error) {
    return 'Fehler beim Löschen von $filename: $error';
  }

  @override
  String errorReadingFile(String error) {
    return 'Fehler beim Lesen der Datei: $error';
  }

  @override
  String get syncChannelName => 'Hintergrundsynchronisierung';

  @override
  String get syncChannelDescription =>
      'Zeigt den Status der Dateisynchronisierung im Hintergrund.';

  @override
  String get storageStatsTitle => 'Speicherstatistik';

  @override
  String get storageStatsUsedSpace => 'Belegter Speicher';

  @override
  String get storageStatsTotalFiles => 'Dateien insgesamt';

  @override
  String storageStatsNItems(int count) {
    return '$count Elemente';
  }

  @override
  String userFallback(int userId) {
    return 'Benutzer #$userId';
  }

  @override
  String get biometricUnlockReason =>
      'Gespeicherte Zugangsdaten für Crowley\'s Cloud entsperren.';

  @override
  String get tokenLifetimeEveryOpen => 'Bei jedem Öffnen der App';

  @override
  String get tokenLifetimeOneHour => 'Nach 1 Stunde';

  @override
  String get tokenLifetime1Hour => 'Nach 1 Stunde';

  @override
  String get tokenLifetimeOneDay => 'Nach 1 Tag';

  @override
  String get tokenLifetime1Day => 'Nach 1 Tag';

  @override
  String get tokenLifetimeOneWeek => 'Nach 1 Woche';

  @override
  String get tokenLifetime1Week => 'Nach 1 Woche';

  @override
  String get tokenLifetimeOneMonth => 'Nach 1 Monat';

  @override
  String get tokenLifetime1Month => 'Nach 1 Monat';

  @override
  String get tokenLifetimeThreeMonths => 'Nach 3 Monaten';

  @override
  String get tokenLifetime3Months => 'Nach 3 Monaten';

  @override
  String get tokenLifetimeNever => 'Nie auf diesem Gerät';

  @override
  String get cacheLimitUnlimited => 'Unbegrenzt';

  @override
  String get syncCategoryOtherFiles => 'Andere Dateien';

  @override
  String get internalStorage => 'Interner Speicher';

  @override
  String get localStorageRootName => 'Interner Speicher';

  @override
  String syncNotificationSyncingWith(String serverName) {
    return 'Synchronisierung mit $serverName';
  }

  @override
  String syncNotificationPausedTitle(String serverName) {
    return 'Synchronisierung mit $serverName pausiert';
  }

  @override
  String get syncNotificationUnreachableBody =>
      'Server nicht erreichbar. Hintergrundsynchronisierung bis zum Öffnen der App pausiert.';

  @override
  String get syncNotificationAuthRequiredBody =>
      'Anmeldung erforderlich. Öffnen Sie die App, um sich anzumelden.';

  @override
  String syncNotificationFailedTitle(String serverName) {
    return 'Synchronisierung mit $serverName fehlgeschlagen';
  }

  @override
  String get syncNotificationGenericErrorBody =>
      'Während der Synchronisierung ist ein Fehler aufgetreten.';

  @override
  String syncNotificationCompleteTitle(String serverName) {
    return 'Synchronisierung mit $serverName abgeschlossen';
  }

  @override
  String get syncNotificationCompleteBody => 'Synchronisierung abgeschlossen.';

  @override
  String get syncStatusConnecting =>
      'Verbindung zum Server wird hergestellt...';

  @override
  String syncStatusConnectionLost(String serverName) {
    return 'Verbindung zu $serverName nicht möglich. Verbindung verloren.';
  }

  @override
  String syncResultServerUnreachableWithServer(String serverName) {
    return 'Verbindung zu $serverName nicht möglich. Verbindung verloren.';
  }

  @override
  String get syncStatusScanningFiles =>
      'Dateien auf dem Gerät werden durchsucht...';

  @override
  String get syncStatusNoFilesFound =>
      'Keine Dateien zur Synchronisierung gefunden.';

  @override
  String get syncStatusNoFilesSelected =>
      'Keine Dateien für die Synchronisierung ausgewählt.';

  @override
  String syncStatusCalculatingChecksum(
    int current,
    int total,
    String filename,
  ) {
    return 'Prüfsumme wird berechnet ($current/$total): $filename';
  }

  @override
  String get syncStatusCheckingDuplicates =>
      'Auf Duplikate auf dem Server wird geprüft...';

  @override
  String syncStatusSyncingFile(int current, int total, String filename) {
    return 'Synchronisierung ($current/$total): $filename';
  }

  @override
  String get syncStatusCompleting => 'Synchronisierung wird abgeschlossen...';

  @override
  String get showingCachedFiles =>
      'Zwischengespeicherte Dateien werden angezeigt.';

  @override
  String get showingCachedFilesRefreshFailed =>
      'Zwischengespeicherte Dateien werden angezeigt. Aktualisierung fehlgeschlagen.';

  @override
  String get downloadCanceled => 'Download abgebrochen.';

  @override
  String downloadedNFilesToPath(int count, String path) {
    return '$count Datei(en) nach $path heruntergeladen';
  }

  @override
  String downloadedNFilesFailedM(int downloaded, int failed, String detail) {
    return '$downloaded Datei(en) heruntergeladen, $failed fehlgeschlagen: $detail';
  }

  @override
  String downloadedNFilesWithFailures(int count, int failed, String error) {
    return '$count Datei(en) heruntergeladen, $failed fehlgeschlagen: $error';
  }

  @override
  String createdNShareLinks(int count) {
    return '$count Freigabelink(s) erstellt.';
  }

  @override
  String get failedToCreateShareLinks =>
      'Freigabelink(s) konnten nicht erstellt werden.';

  @override
  String get alreadyInSharedScope => 'Bereits im freigegebenen Bereich.';

  @override
  String sharedNItemsInServer(int count) {
    return '$count Element(e) auf dem Server freigegeben.';
  }

  @override
  String sharedNItemsWithFailures(int count, int failed) {
    return '$count Element(e) freigegeben, $failed fehlgeschlagen.';
  }

  @override
  String sharedNItemsFailedM(int shared, int failed) {
    return '$shared Element(e) freigegeben, $failed fehlgeschlagen.';
  }

  @override
  String get folderNameCannotBeEmpty => 'Ordnername darf nicht leer sein.';

  @override
  String get folderAlreadyExists => 'Ordner ist bereits vorhanden.';

  @override
  String get folderCreationOnlyInAllFiles =>
      'Ordner können nur unter „Alle Dateien“ erstellt werden.';

  @override
  String get currentDirectoryUnavailable =>
      'Der aktuelle Ordner ist nicht verfügbar.';

  @override
  String get nothingSelected => 'Nichts ausgewählt.';

  @override
  String get destinationFolderDoesNotExist => 'Zielordner existiert nicht.';

  @override
  String cannotMoveFolderIntoItself(String name) {
    return 'Der Ordner „$name“ kann nicht in sich selbst verschoben werden.';
  }

  @override
  String failedToMoveItem(String name, String error) {
    return 'Verschieben von $name fehlgeschlagen: $error';
  }

  @override
  String movedNItems(int count) {
    return '$count Element(e) verschoben.';
  }

  @override
  String movedNItemsWithFailures(int count, int failed) {
    return '$count Element(e) verschoben, $failed fehlgeschlagen.';
  }

  @override
  String movedNItemsFailedM(int moved, int failed) {
    return '$moved Element(e) verschoben, $failed fehlgeschlagen.';
  }

  @override
  String get failedToMoveSelectedItems =>
      'Ausgewählte Elemente konnten nicht verschoben werden.';

  @override
  String get noFilesWereMoved => 'Keine Dateien wurden verschoben.';

  @override
  String renamedOldToNew(String oldName, String newName) {
    return '„$oldName“ wurde in „$newName“ umbenannt.';
  }

  @override
  String renamedFileFromTo(String oldName, String newName) {
    return '„$oldName“ wurde in „$newName“ umbenannt.';
  }

  @override
  String failedToRenameWithStatus(String name, int statusCode) {
    return 'Umbenennen von „$name“ fehlgeschlagen ($statusCode).';
  }

  @override
  String failedToRenameFileWithCode(String name, int statusCode) {
    return 'Umbenennen von „$name“ fehlgeschlagen ($statusCode).';
  }

  @override
  String failedToRenameWithError(String name, String error) {
    return 'Umbenennen von „$name“ fehlgeschlagen: $error';
  }

  @override
  String failedToRenameFile(String name, String error) {
    return 'Umbenennen von „$name“ fehlgeschlagen: $error';
  }

  @override
  String get renameConflictAlreadyExists =>
      'Umbenennen fehlgeschlagen: Eine Datei oder ein Ordner mit diesem Namen existiert bereits.';

  @override
  String get renameFailedAlreadyExists =>
      'Umbenennen fehlgeschlagen: Eine Datei oder ein Ordner mit diesem Namen existiert bereits.';

  @override
  String failedToCreateFolderWithCode(int statusCode) {
    return 'Ordner konnte nicht erstellt werden ($statusCode).';
  }

  @override
  String deletedNItemsFailedM(int deleted, int failed) {
    return '$deleted Element(e) gelöscht, $failed fehlgeschlagen.';
  }

  @override
  String transferSummaryFiles(int percent, int completed, int total) {
    return '$percent%  $completed/$total Dateien';
  }

  @override
  String transferSummaryProgress(int percent, int completed, int total) {
    return '$percent%  $completed/$total Dateien';
  }

  @override
  String get downloadFailedGeneric => 'Download fehlgeschlagen';

  @override
  String uploadedNItemsWithFailures(int uploaded, int failed) {
    return '$uploaded Element(e) hochgeladen, $failed fehlgeschlagen';
  }

  @override
  String uploadedNItemsFailedM(int uploaded, int failed) {
    return '$uploaded Element(e) hochgeladen, $failed fehlgeschlagen.';
  }

  @override
  String uploadSummaryFailedCount(int count) {
    return ', $count fehlgeschlagen';
  }

  @override
  String uploadLocalPathEmpty(String name) {
    return '$name: lokaler Pfad ist leer';
  }

  @override
  String uploadErrorLocalPathEmpty(String name) {
    return '$name: lokaler Pfad ist leer';
  }

  @override
  String get directoryUploadFailed => 'Ordner-Upload fehlgeschlagen';

  @override
  String get uploadDirectoryFailed => 'Ordner-Upload fehlgeschlagen';

  @override
  String get localFileNotFound => 'Lokale Datei nicht gefunden';

  @override
  String get uploadErrorLocalFileNotFound => 'Lokale Datei nicht gefunden';

  @override
  String get noSessionToken => 'Kein aktives Sitzungstoken';

  @override
  String get uploadErrorNoSessionToken => 'Kein aktives Sitzungstoken';

  @override
  String get serverDisconnectedStatus => 'Serververbindung getrennt';

  @override
  String get serverDisconnected => 'Serververbindung getrennt';

  @override
  String get serverIsUnreachable => 'Server ist nicht erreichbar.';

  @override
  String get serverUnreachable => 'Server ist nicht erreichbar.';

  @override
  String get uploadErrorLocalDirectoryNotFound =>
      'Lokaler Ordner nicht gefunden';

  @override
  String get uploadErrorFailedToScanDirectory =>
      'Ordner konnte nicht durchsucht werden';

  @override
  String uploadErrorFolderCreateHttp(int statusCode) {
    return 'Ordnererstellung fehlgeschlagen (HTTP $statusCode)';
  }

  @override
  String get authErrorMissingAccessToken =>
      'Zugriffstoken fehlt in der Antwort';

  @override
  String get authErrorMissingRefreshToken =>
      'Aktualisierungstoken fehlt in der Antwort';

  @override
  String get authErrorNoSavedCredentials =>
      'Keine gespeicherten Zugangsdaten verfügbar';

  @override
  String get authErrorNoRefreshToken => 'Kein Aktualisierungstoken verfügbar';

  @override
  String get authErrorNoActiveSession => 'Keine aktive Sitzung verfügbar';

  @override
  String get authErrorNoSavedUsername =>
      'Kein gespeicherter Benutzername verfügbar';

  @override
  String get updateNoReleasesPublished => 'Noch keine Releases veröffentlicht.';

  @override
  String get language => 'Sprache';
}
