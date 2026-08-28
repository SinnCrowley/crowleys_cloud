// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Crowley\'s Cloud';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Annulla';

  @override
  String get save => 'Salva';

  @override
  String get delete => 'Elimina';

  @override
  String get rename => 'Rinomina';

  @override
  String get close => 'Chiudi';

  @override
  String get retry => 'Riprova';

  @override
  String get loading => 'Caricamento...';

  @override
  String get confirm => 'Conferma';

  @override
  String get error => 'Errore';

  @override
  String errorWithMessage(String message) {
    return 'Errore: $message';
  }

  @override
  String get unknown => 'Sconosciuto';

  @override
  String get upload => 'Carica';

  @override
  String get download => 'Scarica';

  @override
  String get share => 'Condividi';

  @override
  String get copy => 'Copia';

  @override
  String get move => 'Sposta';

  @override
  String get restore => 'Ripristina';

  @override
  String get apply => 'Applica';

  @override
  String get create => 'Crea';

  @override
  String get clear => 'Cancella';

  @override
  String get add => 'Aggiungi';

  @override
  String get remove => 'Rimuovi';

  @override
  String get edit => 'Modifica';

  @override
  String get switchLabel => 'Cambia';

  @override
  String get search => 'Cerca';

  @override
  String get name => 'Nome';

  @override
  String get date => 'Data';

  @override
  String get size => 'Dimensione';

  @override
  String get type => 'Tipo';

  @override
  String get ascending => 'Crescente';

  @override
  String get descending => 'Decrescente';

  @override
  String get allFiles => 'Tutti';

  @override
  String get categoryImages => 'Immagini';

  @override
  String get categoryPhotos => 'Foto';

  @override
  String get categoryVideos => 'Video';

  @override
  String get categoryAudio => 'Audio';

  @override
  String get categoryDocuments => 'Documenti';

  @override
  String get categoryArchives => 'Archivi';

  @override
  String get categoryShared => 'Condivisi';

  @override
  String get categoryOther => 'Altro';

  @override
  String get categoryOtherFiles => 'Altri file';

  @override
  String get noFilesFound => 'Nessun file trovato.';

  @override
  String get noFilesInFolder => 'Nessun file in questa cartella.';

  @override
  String get thisActionCannotBeUndone =>
      'Questa azione non può essere annullata.';

  @override
  String get passwordsDoNotMatch => 'Le password non corrispondono.';

  @override
  String get navLocalFiles => 'File locali';

  @override
  String get navServerFiles => 'File del server';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get navTrash => 'Cestino';

  @override
  String get navLocal => 'Locale';

  @override
  String get navServer => 'Server';

  @override
  String get addServer => 'Aggiungi server';

  @override
  String get noServersConfigured => 'Nessun server configurato.';

  @override
  String get addAServerInSettings => 'Aggiungi un server nelle impostazioni.';

  @override
  String get addFirstServerHint =>
      'Aggiungi il tuo primo server per continuare.';

  @override
  String get noServersConfiguredYet => 'Non è ancora configurato alcun server.';

  @override
  String get crowleysCloudSetup => 'Configurazione di Crowley\'s Cloud';

  @override
  String get connect => 'Connetti';

  @override
  String get connecting => 'Connessione in corso...';

  @override
  String get connected => 'Connesso';

  @override
  String get disconnected => 'Disconnesso';

  @override
  String get switchServer => 'Cambia server';

  @override
  String get chooseOtherServer => 'Scegli un altro server';

  @override
  String get switchServerTitle => 'Cambiare server?';

  @override
  String switchServerBody(String serverName) {
    return 'Passare il server attivo a «$serverName»?';
  }

  @override
  String get chooseServer => 'Scegli server';

  @override
  String get authenticationRequired => 'Autenticazione richiesta';

  @override
  String signInToAccess(String serverName) {
    return 'Accedi per visualizzare i file su $serverName';
  }

  @override
  String get signInWithPassword => 'Accedi con password';

  @override
  String get useBiometrics => 'Usa dati biometrici';

  @override
  String get openingSignIn => 'Apertura dell’accesso...';

  @override
  String get serverConnectionFailed => 'Connessione al server non riuscita';

  @override
  String get unableToConnectToServer =>
      'Impossibile connettersi al server attivo.';

  @override
  String unableToConnectTo(String serverName) {
    return 'Impossibile connettersi a $serverName.';
  }

  @override
  String get searchHint => 'Cerca...';

  @override
  String get searchFilesHint => 'Cerca file...';

  @override
  String get searchServerFilesHint => 'Cerca file del server...';

  @override
  String get searchTrashHint => 'Cerca nel cestino...';

  @override
  String get storagePermissionRequired =>
      'Autorizzazione di archiviazione richiesta';

  @override
  String get grantPermission => 'Concedi autorizzazione';

  @override
  String get permissionDeniedOpenSettings =>
      'Autorizzazione negata. Concedi l’accesso all’archiviazione nelle impostazioni.';

  @override
  String get manageStoragePermissionRequired =>
      'L’autorizzazione a gestire l’archiviazione è richiesta per sfogliare e selezionare cartelle.';

  @override
  String get storagePermissionsRequired =>
      'Per la sincronizzazione sono richieste autorizzazioni di archiviazione.';

  @override
  String updateAvailableTitle(String version) {
    return 'Aggiornamento disponibile: v$version';
  }

  @override
  String get updateAvailableTapToSeeNew => 'Tocca per vedere le novità';

  @override
  String get updateView => 'Visualizza';

  @override
  String get updateAvailableDialogTitle => 'Aggiornamento disponibile';

  @override
  String updateVersionSubtitle(String version) {
    return 'Versione $version';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'Attuale: v$version';
  }

  @override
  String updateNewVersion(String version) {
    return 'Nuova: v$version';
  }

  @override
  String get updateWhatsNew => 'Novità:';

  @override
  String get updateGitHub => 'GitHub';

  @override
  String get updateNoReleaseNotes => 'Nessuna nota di rilascio disponibile.';

  @override
  String get updateLater => 'Più tardi';

  @override
  String get updateDownloadApk => 'Scarica APK';

  @override
  String get updateInstall => 'Aggiorna';

  @override
  String get shareLinkTitle => 'Link di condivisione';

  @override
  String get shareViaLink => 'Condividi tramite link';

  @override
  String get shareInServer => 'Condividi sul server';

  @override
  String get expiryDays => 'Scadenza (giorni)';

  @override
  String get expiryNever => 'Mai';

  @override
  String get expiry1Day => '1 giorno';

  @override
  String get expiry7Days => '7 giorni';

  @override
  String get expiry30Days => '30 giorni';

  @override
  String get expiry90Days => '90 giorni';

  @override
  String get expiry180Days => '180 giorni';

  @override
  String get expiry365Days => '365 giorni';

  @override
  String get createLink => 'Crea link';

  @override
  String get sharedLinkCopied => 'Link di condivisione copiato negli appunti!';

  @override
  String failedToCopySharedLink(String error) {
    return 'Impossibile copiare il link di condivisione: $error';
  }

  @override
  String get cannotShareThisFileType =>
      'Questo tipo di file non può essere condiviso.';

  @override
  String failedToCreateShare(String error) {
    return 'Impossibile creare la condivisione: $error';
  }

  @override
  String get newFolderTitle => 'Crea cartella';

  @override
  String get newFolderHint => 'Nome cartella';

  @override
  String get newFolder => 'Nuova cartella';

  @override
  String get folderCreated => 'Cartella creata.';

  @override
  String failedToCreateFolder(String error) {
    return 'Impossibile creare la cartella: $error';
  }

  @override
  String get creatingFolder => 'Creazione cartella...';

  @override
  String get renameDialogTitle => 'Rinomina';

  @override
  String get renameHint => 'Nuovo nome';

  @override
  String get enterNewName => 'Inserisci nuovo nome';

  @override
  String get renamedSuccessfully => 'Rinominato correttamente.';

  @override
  String renameFailed(String error) {
    return 'Ridenominazione non riuscita: $error';
  }

  @override
  String get moveDialogTitle => 'Sposta in';

  @override
  String moveTo(String path) {
    return 'Sposta in: $path';
  }

  @override
  String get moveHere => 'Sposta qui';

  @override
  String moveFailed(String error) {
    return 'Spostamento non riuscito: $error';
  }

  @override
  String get movedToFolder => 'Spostato nella cartella.';

  @override
  String copyFailed(String error) {
    return 'Copia non riuscita: $error';
  }

  @override
  String get selectFolder => 'Seleziona cartella';

  @override
  String get useThisFolder => 'Usa questa cartella';

  @override
  String get storageRoot => 'Archiviazione';

  @override
  String get serverRoot => 'radice';

  @override
  String deleteNItemsTitle(int count) {
    return 'Eliminare $count elementi?';
  }

  @override
  String get deleteFilesTitle => 'Eliminare file?';

  @override
  String deleteFilesBody(int count) {
    return 'Vuoi davvero eliminare i $count elementi selezionati? Questa azione non può essere annullata.';
  }

  @override
  String get deletePermanently => 'Elimina definitivamente';

  @override
  String get deletePermanentlyTitle => 'Eliminare definitivamente?';

  @override
  String deletePermanentlyBody(String filename) {
    return '$filename verrà eliminato definitivamente.';
  }

  @override
  String get deleteFileTitle => 'Eliminare file?';

  @override
  String deleteFileBody(String filename) {
    return 'Vuoi davvero eliminare $filename? Questa azione non può essere annullata.';
  }

  @override
  String get deleteServerFileTitle => 'Elimina definitivamente';

  @override
  String deleteServerFileBody(String filename) {
    return 'Vuoi davvero eliminare definitivamente «$filename»? Questa azione non può essere annullata.';
  }

  @override
  String get unshareItemsTitle => 'Rimuovere la condivisione degli elementi?';

  @override
  String unshareItemsBody(int count) {
    return 'Vuoi davvero rimuovere la condivisione dei $count elementi selezionati? Verranno rimossi dalla cartella Condivisi.';
  }

  @override
  String get unshare => 'Rimuovi condivisione';

  @override
  String get moveToTrash => 'Sposta nel cestino';

  @override
  String get movedToTrash => 'Spostato nel cestino.';

  @override
  String movedNItemsToTrash(int count) {
    return '$count elementi spostati nel cestino.';
  }

  @override
  String failedToMoveToTrash(String error) {
    return 'Impossibile spostare nel cestino: $error';
  }

  @override
  String deletedNItems(int count) {
    return '$count elementi eliminati.';
  }

  @override
  String failedToDelete(String error) {
    return 'Eliminazione non riuscita: $error';
  }

  @override
  String failedToDeleteItem(String error) {
    return 'Eliminazione non riuscita: $error';
  }

  @override
  String deletedFilename(String filename) {
    return '$filename eliminato.';
  }

  @override
  String get failedToOpenFile => 'Impossibile aprire il file';

  @override
  String fileDownloadFailed(String error) {
    return 'Download del file non riuscito: $error';
  }

  @override
  String get downloading => 'Download in corso...';

  @override
  String get downloadingFile => 'Download del file in corso...';

  @override
  String downloadComplete(String filename) {
    return 'Download completato: $filename';
  }

  @override
  String downloadFailed(String error) {
    return 'Download non riuscito: $error';
  }

  @override
  String get failedToDownloadPreview =>
      'Impossibile scaricare l’anteprima del file';

  @override
  String uploadComplete(String filename) {
    return 'Caricamento completato: $filename';
  }

  @override
  String uploadFailed(String error) {
    return 'Caricamento non riuscito: $error';
  }

  @override
  String get failedToPickFiles => 'Impossibile selezionare i file';

  @override
  String uploadedNItems(int count) {
    return '$count elemento/i caricato/i';
  }

  @override
  String get copiedLinkToClipboard => 'Link copiato negli appunti.';

  @override
  String failedToCopyLink(String error) {
    return 'Impossibile copiare il link: $error';
  }

  @override
  String get selectingAll => 'Selezione di tutti gli elementi...';

  @override
  String get allItemsSelected => 'Tutti gli elementi selezionati.';

  @override
  String get failedToLoadSearchResults =>
      'Impossibile caricare i risultati della ricerca';

  @override
  String get shareNotSupportedForType =>
      'La condivisione non è supportata per questo tipo di file.';

  @override
  String nSelected(int count) {
    return '$count selezionati';
  }

  @override
  String get noServerSelected => 'Nessun server selezionato';

  @override
  String get pleaseConnectToServerFirst => 'Connettiti prima a un server.';

  @override
  String get signInRequired => 'Accesso richiesto';

  @override
  String pleaseSignInToServer(String serverName) {
    return 'Accedi prima a $serverName.';
  }

  @override
  String get connectingToServer => 'Connessione al server...';

  @override
  String connectedToServer(String serverName) {
    return 'Connesso a $serverName.';
  }

  @override
  String connectionFailed(String error) {
    return 'Connessione non riuscita: $error';
  }

  @override
  String failedToConnect(String error) {
    return 'Impossibile connettersi: $error';
  }

  @override
  String authFailed(String error) {
    return 'Autenticazione non riuscita: $error';
  }

  @override
  String get authFailedGeneric => 'Autenticazione non riuscita. Riprova.';

  @override
  String biometricLoginFailed(String error) {
    return 'Accesso biometrico non riuscito: $error';
  }

  @override
  String get biometricLoginFailedGeneric => 'Accesso biometrico non riuscito.';

  @override
  String get noServerSessionToken =>
      'Nessun token di sessione del server. Autentica nuovamente il server.';

  @override
  String failedToSaveServer(String error) {
    return 'Impossibile salvare il server: $error';
  }

  @override
  String get addToFolder => 'Aggiungi alla cartella';

  @override
  String get loginTabLabel => 'Accedi';

  @override
  String get registerTabLabel => 'Registrati';

  @override
  String get welcomeBack => 'Bentornato';

  @override
  String get signInToContinue => 'Accedi per continuare';

  @override
  String get createAccount => 'Crea account';

  @override
  String get joinTheServer => 'Unisciti al server';

  @override
  String get usernameLabel => 'Nome utente';

  @override
  String get usernameHint => 'Inserisci il tuo nome utente';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Inserisci la tua password';

  @override
  String get showPassword => 'Mostra password';

  @override
  String get hidePassword => 'Nascondi password';

  @override
  String get confirmPassword => 'Conferma password';

  @override
  String get logIn => 'Accedi';

  @override
  String get loggingIn => 'Accesso in corso...';

  @override
  String get registering => 'Registrazione in corso...';

  @override
  String get forgotPassword => 'Password dimenticata?';

  @override
  String get doNotHaveAccount =>
      'Non hai un account? Passa alla registrazione.';

  @override
  String get alreadyHaveAccount => 'Hai già un account? Passa all’accesso.';

  @override
  String get usernameCannotBeEmpty => 'Il nome utente non può essere vuoto.';

  @override
  String get passwordCannotBeEmpty => 'La password non può essere vuota.';

  @override
  String get usernameInvalid =>
      'Il nome utente deve contenere 3–32 caratteri: lettere, numeri, _ o -.';

  @override
  String get passwordTooShort =>
      'La password deve contenere almeno 8 caratteri.';

  @override
  String loginFailed(String error) {
    return 'Accesso non riuscito: $error';
  }

  @override
  String registrationFailed(String error) {
    return 'Registrazione non riuscita: $error';
  }

  @override
  String get resetPasswordTitle => 'Reimposta password';

  @override
  String get enterResetCodeTitle => 'Inserisci il codice di reimpostazione';

  @override
  String get resetPasswordStep1Body =>
      'Inserisci il nome utente. Il codice di verifica a 6 cifre verrà mostrato nei registri o nella console del server.';

  @override
  String get resetPasswordStep2Body =>
      'Il codice di verifica è stato mostrato nella console del server. Inserisci il codice a 6 cifre e la nuova password.';

  @override
  String get resetCodeLabel => 'Codice di reimpostazione';

  @override
  String get resetCodeHint => 'Inserisci il codice a 6 cifre';

  @override
  String get newPasswordLabel => 'Nuova password';

  @override
  String get newPasswordHint => 'Inserisci nuova password';

  @override
  String get passwordResetSuccessfully => 'Password reimpostata correttamente!';

  @override
  String get usernameIsRequired => 'Il nome utente è obbligatorio.';

  @override
  String get codeAndPasswordRequired =>
      'Il codice e la nuova password sono obbligatori.';

  @override
  String get failedToRequestReset =>
      'Impossibile richiedere la reimpostazione. Verifica l’URL del server.';

  @override
  String get failedToResetPassword =>
      'Impossibile reimpostare la password. Controlla il codice.';

  @override
  String get pleaseEnterServerUrlFirst => 'Inserisci prima l’URL del server.';

  @override
  String get sendCode => 'Invia codice';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get sectionBackupSync => 'Backup e sincronizzazione';

  @override
  String get sectionStorageCache => 'Archiviazione e cache';

  @override
  String get sectionSecurityBehavior => 'Sicurezza e comportamento';

  @override
  String get sectionAboutUpdates => 'Informazioni e aggiornamenti';

  @override
  String get sectionAppearance => 'Aspetto e personalizzazione';

  @override
  String get noServersConfiguredSync => 'Nessun server configurato';

  @override
  String get addServerBeforeSync =>
      'Aggiungi un server prima di configurare la sincronizzazione.';

  @override
  String get selectServerToConfigureSync =>
      'Seleziona un server per configurarne le impostazioni di sincronizzazione.';

  @override
  String get activeServerSuffix => '· attivo';

  @override
  String get folderAndCategorySync =>
      'Sincronizzazione di cartelle e categorie';

  @override
  String get keepCategoriesSynced =>
      'Mantieni sincronizzate con questo server le categorie o cartelle locali selezionate.';

  @override
  String get addServerBeforeSyncEnable =>
      'Aggiungi un server prima di abilitare la sincronizzazione.';

  @override
  String get onlyOnWifi => 'Solo tramite Wi-Fi';

  @override
  String get onlyWhileCharging => 'Solo durante la ricarica';

  @override
  String get serverTargetDirectory => 'Cartella di destinazione sul server';

  @override
  String get serverTargetDirectoryHint => '/backup/mobile_phone';

  @override
  String get synchronizationFrequency => 'Frequenza di sincronizzazione';

  @override
  String get syncNow => 'Sincronizza ora';

  @override
  String get syncing => 'Sincronizzazione in corso...';

  @override
  String get categoriesToSynchronize => 'Categorie da sincronizzare';

  @override
  String get noCategoriesSelected => 'Nessuna categoria selezionata.';

  @override
  String nCategoriesSelected(int count) {
    return '$count selezionati';
  }

  @override
  String get foldersToSynchronize => 'Cartelle da sincronizzare';

  @override
  String get noCustomFolders => 'Nessuna cartella personalizzata configurata.';

  @override
  String nFolders(int count) {
    return '$count cartella/e';
  }

  @override
  String get addFolder => 'Aggiungi cartella';

  @override
  String get removeFolder => 'Rimuovi cartella';

  @override
  String get removeServer => 'Rimuovi server';

  @override
  String get syncFreqEvery15Min => 'Ogni 15 minuti';

  @override
  String get syncFreqEvery30Min => 'Ogni 30 minuti';

  @override
  String get syncFreqEvery1Hour => 'Ogni ora';

  @override
  String syncFreqEveryNHours(int hours) {
    return 'Ogni $hours ore';
  }

  @override
  String syncFreqEveryNMin(int minutes) {
    return 'Ogni $minutes minuti';
  }

  @override
  String get syncFreqDaily => 'Ogni giorno';

  @override
  String get chooseSyncFrequencyTitle =>
      'Scegli la frequenza di sincronizzazione';

  @override
  String get cacheSize => 'Dimensione cache';

  @override
  String get refreshTooltip => 'Aggiorna';

  @override
  String get cacheLimit => 'Limite cache';

  @override
  String get downloadPath => 'Percorso di download';

  @override
  String get defaultDownloadFolder => 'Cartella CrowleysCloud predefinita';

  @override
  String get clearCache => 'Svuota cache';

  @override
  String get clearCacheTitle => 'Svuotare la cache?';

  @override
  String get clearCacheBody =>
      'Rimuove miniature locali ed elenchi del server memorizzati nella cache.';

  @override
  String get downloadPathDialogTitle => 'Percorso di download';

  @override
  String get downloadPathHint => '/storage/emulated/0/CrowleysCloud';

  @override
  String get useDefault => 'Usa predefinito';

  @override
  String get serverTargetDirDialogTitle =>
      'Cartella di destinazione sul server';

  @override
  String get requireLogin => 'Richiedi accesso';

  @override
  String get biometricLogin => 'Accesso biometrico';

  @override
  String get biometricLoginSubtitle =>
      'Consenti l’accesso con credenziali salvate tramite biometria.';

  @override
  String get biometricsNotAvailable =>
      'La biometria non è disponibile su questo dispositivo.';

  @override
  String get showHiddenFiles => 'Mostra file nascosti';

  @override
  String get showHiddenFilesSubtitle =>
      'Mostra file e cartelle che iniziano con un punto.';

  @override
  String get changePassword => 'Cambia password';

  @override
  String changePasswordSubtitle(String serverName) {
    return 'Aggiorna la password per $serverName.';
  }

  @override
  String get addServerBeforeChangePassword =>
      'Aggiungi un server prima di cambiare la password.';

  @override
  String get deleteUserAccount => 'Elimina account utente';

  @override
  String get deleteUserAccountSubtitle =>
      'Elimina l’utente e tutti i file cloud privati.';

  @override
  String get deleteAccountTitle => 'Eliminare l’account?';

  @override
  String deleteAccountBody(String serverName) {
    return 'Elimina definitivamente l’account su $serverName e tutti i file nella cartella cloud privata. Questa azione non può essere annullata.';
  }

  @override
  String get deleteAccountButton => 'Elimina account';

  @override
  String get changePasswordDialogTitle => 'Cambia password';

  @override
  String get newPasswordFieldLabel => 'Nuova password';

  @override
  String get confirmPasswordLabel => 'Conferma password';

  @override
  String get enterNewPassword => 'Inserisci una nuova password.';

  @override
  String get passwordUpdated => 'Password aggiornata.';

  @override
  String passwordChangeFailed(String error) {
    return 'Modifica della password non riuscita: $error';
  }

  @override
  String get passwordChangeFailedGeneric =>
      'Modifica della password non riuscita.';

  @override
  String get accountDeleted => 'Account eliminato.';

  @override
  String accountDeletionFailed(String error) {
    return 'Eliminazione dell’account non riuscita: $error';
  }

  @override
  String get accountDeletionFailedGeneric =>
      'Eliminazione dell’account non riuscita.';

  @override
  String get checkForUpdates => 'Controlla aggiornamenti';

  @override
  String get checkingForUpdates => 'Controllo delle versioni di GitHub...';

  @override
  String versionLabel(String version) {
    return 'Versione $version';
  }

  @override
  String appIsUpToDate(String version) {
    return 'Crowley\'s Cloud è aggiornato (v$version).';
  }

  @override
  String get updateCheckFailed =>
      'Impossibile controllare gli aggiornamenti. Riprova più tardi.';

  @override
  String get themeModeTitle => 'Modalità tema';

  @override
  String get themeDark => 'Scuro';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeCustom => 'Personalizzato';

  @override
  String get themeDarkFull => 'Tema scuro';

  @override
  String get themeLightFull => 'Tema chiaro';

  @override
  String get themeCustomFull => 'Tema personalizzato';

  @override
  String get accentColor => 'Colore accento';

  @override
  String get primaryAccentColor => 'Colore accento principale';

  @override
  String get selectAccentColor => 'Seleziona colore accento';

  @override
  String get backgroundColor => 'Colore sfondo';

  @override
  String get surfaceColor => 'Colore superficie';

  @override
  String get textColor => 'Colore testo';

  @override
  String get subtextColor => 'Colore testo secondario';

  @override
  String get borderColor => 'Colore bordo';

  @override
  String get fontSizeScale => 'Scala dimensione carattere';

  @override
  String selectColor(String title) {
    return 'Seleziona $title';
  }

  @override
  String get categoriesToSyncDialogTitle => 'Categorie da sincronizzare';

  @override
  String get categoriesToSyncBody =>
      'Scegli una o più categorie. Puoi anche lasciare tutto deselezionato.';

  @override
  String get syncCategorySectionMedia => 'Elementi multimediali';

  @override
  String get syncCategorySectionAudioDocs => 'Audio e documenti';

  @override
  String get syncCategorySectionOther => 'Altro';

  @override
  String get clearAll => 'Cancella tutto';

  @override
  String get noSyncHasRunYet =>
      'Non è stata ancora eseguita alcuna sincronizzazione.';

  @override
  String lastRunAt(String date) {
    return 'Ultima esecuzione: $date';
  }

  @override
  String syncResultSuccess(int uploaded, int skipped) {
    return '$uploaded sincronizzati, $skipped ignorati.';
  }

  @override
  String get syncResultNoFiles =>
      'Nessun file selezionato per la sincronizzazione.';

  @override
  String syncResultPartial(int uploaded, int failed) {
    return '$uploaded sincronizzati, $failed non riusciti.';
  }

  @override
  String get syncResultAuthRequired => 'Accedi prima della sincronizzazione.';

  @override
  String get syncResultUnreachable =>
      'Server non raggiungibile. Connessione persa.';

  @override
  String get syncResultFailed => 'Sincronizzazione non riuscita.';

  @override
  String get serverSetupAddServer => 'Aggiungi server';

  @override
  String get serverSetupCardTitle => 'Connetti server';

  @override
  String get serverSetupCardSubtitle =>
      'Aggiungi il tuo server di file e accedi.';

  @override
  String get serverSetupSubmitButton => 'Salva server';

  @override
  String get serverNameLabel => 'Nome server';

  @override
  String get serverNameHint => 'NAS domestico';

  @override
  String get baseUrlLabel => 'Base URL';

  @override
  String get baseUrlHint => 'https://cloud.example.com';

  @override
  String get allFieldsRequired => 'Tutti i campi sono obbligatori.';

  @override
  String get localFilesTitle => 'File locali';

  @override
  String get serverFilesTitle => 'File del server';

  @override
  String get restoreItemsTitle => 'Ripristina elementi';

  @override
  String restoreItemsBody(int count) {
    return 'Vuoi davvero ripristinare $count elemento/i?';
  }

  @override
  String get permanentlyDeleteTitle => 'Elimina definitivamente';

  @override
  String permanentlyDeleteBody(int count) {
    return 'Vuoi davvero eliminare definitivamente $count elemento/i? Questa azione non può essere annullata.';
  }

  @override
  String get trashIsEmpty => 'Il cestino è vuoto.';

  @override
  String trashRetentionInfo(int days) {
    return 'Gli elementi nel cestino vengono eliminati automaticamente dopo $days giorni.';
  }

  @override
  String get deletionDate => 'Data di eliminazione';

  @override
  String get deletePermanentlyAction => 'Elimina definitivamente';

  @override
  String get conflictFileAlreadyExists => 'Il file esiste già';

  @override
  String conflictNofM(int current, int total) {
    return 'Conflitto $current di $total';
  }

  @override
  String get conflictAFileNamed => 'Un file denominato ';

  @override
  String get conflictAlreadyExistsAt => ' esiste già in ';

  @override
  String get conflictAlreadyExistsInFolder => ' esiste già in questa cartella.';

  @override
  String get conflictInFolder => 'Nella cartella';

  @override
  String get conflictFromTrash => 'Dal cestino';

  @override
  String get conflictExisting => 'Esistente';

  @override
  String get conflictNewUpload => 'Nuovo caricamento';

  @override
  String conflictSizeLabel(String size) {
    return 'Dimensione: $size';
  }

  @override
  String conflictDateLabel(String date) {
    return 'Data: $date';
  }

  @override
  String conflictDeletedLabel(String date) {
    return 'Eliminato: $date';
  }

  @override
  String conflictApplyToRemaining(int count) {
    return 'Applica ai $count conflitti rimanenti';
  }

  @override
  String get conflictKeepAllCopies => 'Mantieni tutte le copie';

  @override
  String get conflictOverwriteAll => 'Sovrascrivi tutto';

  @override
  String get conflictRestoreAllAsCopies => 'Ripristina tutto come copie';

  @override
  String get conflictRestoreAsCopy => 'Ripristina come copia';

  @override
  String get conflictOverwriteAllRemaining => 'Sovrascrivi tutti i rimanenti';

  @override
  String get conflictSkipAll => 'Ignora tutto';

  @override
  String get conflictSkipAllRemaining => 'Ignora tutti i rimanenti';

  @override
  String get conflictSkip => 'Ignora';

  @override
  String get conflictOverwrite => 'Sovrascrivi';

  @override
  String get transfersTitle => 'Trasferimenti';

  @override
  String get transferResume => 'Riprendi';

  @override
  String get transferPause => 'Pausa';

  @override
  String get transferCancel => 'Annulla';

  @override
  String get transferResumeAll => 'Riprendi tutto';

  @override
  String get transferPauseAll => 'Metti tutto in pausa';

  @override
  String get transferCancelAll => 'Annulla tutto';

  @override
  String get transferCancelFile => 'Annulla file';

  @override
  String get noTransfers => 'Nessun trasferimento.';

  @override
  String get transferStatusQueued => 'In coda';

  @override
  String get transferStatusRunning => 'In corso';

  @override
  String get transferStatusPaused => 'In pausa';

  @override
  String get transferStatusCompleted => 'Completato';

  @override
  String get transferStatusFailed => 'Non riuscito';

  @override
  String get transferStatusCanceled => 'Annullato';

  @override
  String get themePresetsSection => 'Preimpostazioni';

  @override
  String get themeCustomPaletteSection => 'Tavolozza personalizzata';

  @override
  String get themeHexRgbLabel => 'Codice HEX RGB';

  @override
  String get themeHexRgbHint => '#FA5252';

  @override
  String get imageViewerNoFetchHandler =>
      'Nessun gestore di recupero configurato';

  @override
  String get imageViewerFailedToLoad => 'Impossibile caricare l’immagine';

  @override
  String errorDeletingFile(String filename, String error) {
    return 'Errore nell’eliminazione di $filename: $error';
  }

  @override
  String errorReadingFile(String error) {
    return 'Errore nella lettura del file: $error';
  }

  @override
  String get syncChannelName => 'Sincronizzazione in background';

  @override
  String get syncChannelDescription =>
      'Mostra lo stato della sincronizzazione dei file in background.';

  @override
  String get storageStatsTitle => 'Statistiche archiviazione';

  @override
  String get storageStatsUsedSpace => 'Spazio utilizzato';

  @override
  String get storageStatsTotalFiles => 'File totali';

  @override
  String storageStatsNItems(int count) {
    return '$count elementi';
  }

  @override
  String userFallback(int userId) {
    return 'Utente #$userId';
  }

  @override
  String get biometricUnlockReason =>
      'Sblocca le credenziali salvate per Crowley\'s Cloud.';

  @override
  String get tokenLifetimeEveryOpen => 'A ogni apertura dell’app';

  @override
  String get tokenLifetimeOneHour => 'Dopo 1 ora';

  @override
  String get tokenLifetime1Hour => 'Dopo 1 ora';

  @override
  String get tokenLifetimeOneDay => 'Dopo 1 giorno';

  @override
  String get tokenLifetime1Day => 'Dopo 1 giorno';

  @override
  String get tokenLifetimeOneWeek => 'Dopo 1 settimana';

  @override
  String get tokenLifetime1Week => 'Dopo 1 settimana';

  @override
  String get tokenLifetimeOneMonth => 'Dopo 1 mese';

  @override
  String get tokenLifetime1Month => 'Dopo 1 mese';

  @override
  String get tokenLifetimeThreeMonths => 'Dopo 3 mesi';

  @override
  String get tokenLifetime3Months => 'Dopo 3 mesi';

  @override
  String get tokenLifetimeNever => 'Mai su questo dispositivo';

  @override
  String get cacheLimitUnlimited => 'Illimitato';

  @override
  String get syncCategoryOtherFiles => 'Altri file';

  @override
  String get internalStorage => 'Memoria interna';

  @override
  String get localStorageRootName => 'Memoria interna';

  @override
  String syncNotificationSyncingWith(String serverName) {
    return 'Sincronizzazione con $serverName';
  }

  @override
  String syncNotificationPausedTitle(String serverName) {
    return 'Sincronizzazione con $serverName in pausa';
  }

  @override
  String get syncNotificationUnreachableBody =>
      'Il server non è raggiungibile. Sincronizzazione in background sospesa finché l’app non viene aperta.';

  @override
  String get syncNotificationAuthRequiredBody =>
      'Autenticazione richiesta. Apri l’app per accedere.';

  @override
  String syncNotificationFailedTitle(String serverName) {
    return 'Sincronizzazione con $serverName non riuscita';
  }

  @override
  String get syncNotificationGenericErrorBody =>
      'Si è verificato un errore durante la sincronizzazione.';

  @override
  String syncNotificationCompleteTitle(String serverName) {
    return 'Sincronizzazione con $serverName completata';
  }

  @override
  String get syncNotificationCompleteBody => 'Sincronizzazione completata.';

  @override
  String get syncStatusConnecting => 'Connessione al server...';

  @override
  String syncStatusConnectionLost(String serverName) {
    return 'Impossibile connettersi a $serverName. Connessione persa.';
  }

  @override
  String syncResultServerUnreachableWithServer(String serverName) {
    return 'Impossibile connettersi a $serverName. Connessione persa.';
  }

  @override
  String get syncStatusScanningFiles => 'Analisi dei file sul dispositivo...';

  @override
  String get syncStatusNoFilesFound => 'Nessun file trovato da sincronizzare.';

  @override
  String get syncStatusNoFilesSelected =>
      'Nessun file selezionato per la sincronizzazione.';

  @override
  String syncStatusCalculatingChecksum(
    int current,
    int total,
    String filename,
  ) {
    return 'Calcolo del checksum ($current/$total): $filename';
  }

  @override
  String get syncStatusCheckingDuplicates =>
      'Ricerca di duplicati sul server...';

  @override
  String syncStatusSyncingFile(int current, int total, String filename) {
    return 'Sincronizzazione ($current/$total): $filename';
  }

  @override
  String get syncStatusCompleting => 'Completamento della sincronizzazione...';

  @override
  String get showingCachedFiles => 'Visualizzazione dei file in cache.';

  @override
  String get showingCachedFilesRefreshFailed =>
      'Visualizzazione dei file in cache. Aggiornamento non riuscito.';

  @override
  String get downloadCanceled => 'Download annullato.';

  @override
  String downloadedNFilesToPath(int count, String path) {
    return '$count file scaricato/i in $path';
  }

  @override
  String downloadedNFilesFailedM(int downloaded, int failed, String detail) {
    return '$downloaded file scaricato/i, $failed non riuscito/i: $detail';
  }

  @override
  String downloadedNFilesWithFailures(int count, int failed, String error) {
    return '$count file scaricato/i, $failed non riuscito/i: $error';
  }

  @override
  String createdNShareLinks(int count) {
    return '$count link di condivisione creato/i.';
  }

  @override
  String get failedToCreateShareLinks =>
      'Impossibile creare i link di condivisione.';

  @override
  String get alreadyInSharedScope => 'Già nell’ambito condiviso.';

  @override
  String sharedNItemsInServer(int count) {
    return '$count elemento/i condiviso/i sul server.';
  }

  @override
  String sharedNItemsWithFailures(int count, int failed) {
    return '$count elemento/i condiviso/i, $failed non riuscito/i.';
  }

  @override
  String sharedNItemsFailedM(int shared, int failed) {
    return '$shared elemento/i condiviso/i, $failed non riuscito/i.';
  }

  @override
  String get folderNameCannotBeEmpty =>
      'Il nome della cartella non può essere vuoto.';

  @override
  String get folderAlreadyExists => 'La cartella esiste già.';

  @override
  String get folderCreationOnlyInAllFiles =>
      'La creazione di cartelle è disponibile solo in Tutti i file.';

  @override
  String get currentDirectoryUnavailable =>
      'La cartella corrente non è disponibile.';

  @override
  String get nothingSelected => 'Nessun elemento selezionato.';

  @override
  String get destinationFolderDoesNotExist =>
      'La cartella di destinazione non esiste.';

  @override
  String cannotMoveFolderIntoItself(String name) {
    return 'Impossibile spostare la cartella «$name» al suo interno.';
  }

  @override
  String failedToMoveItem(String name, String error) {
    return 'Impossibile spostare $name: $error';
  }

  @override
  String movedNItems(int count) {
    return '$count elemento/i spostato/i.';
  }

  @override
  String movedNItemsWithFailures(int count, int failed) {
    return '$count elemento/i spostato/i, $failed non riuscito/i.';
  }

  @override
  String movedNItemsFailedM(int moved, int failed) {
    return '$moved elemento/i spostato/i, $failed non riuscito/i.';
  }

  @override
  String get failedToMoveSelectedItems =>
      'Impossibile spostare gli elementi selezionati.';

  @override
  String get noFilesWereMoved => 'Nessun file è stato spostato.';

  @override
  String renamedOldToNew(String oldName, String newName) {
    return '«$oldName» è stato rinominato in «$newName».';
  }

  @override
  String renamedFileFromTo(String oldName, String newName) {
    return '«$oldName» è stato rinominato in «$newName».';
  }

  @override
  String failedToRenameWithStatus(String name, int statusCode) {
    return 'Impossibile rinominare «$name» ($statusCode).';
  }

  @override
  String failedToRenameFileWithCode(String name, int statusCode) {
    return 'Impossibile rinominare «$name» ($statusCode).';
  }

  @override
  String failedToRenameWithError(String name, String error) {
    return 'Impossibile rinominare «$name»: $error';
  }

  @override
  String failedToRenameFile(String name, String error) {
    return 'Impossibile rinominare «$name»: $error';
  }

  @override
  String get renameConflictAlreadyExists =>
      'Impossibile rinominare: esiste già un file o una cartella con questo nome.';

  @override
  String get renameFailedAlreadyExists =>
      'Impossibile rinominare: esiste già un file o una cartella con questo nome.';

  @override
  String failedToCreateFolderWithCode(int statusCode) {
    return 'Impossibile creare la cartella ($statusCode).';
  }

  @override
  String deletedNItemsFailedM(int deleted, int failed) {
    return '$deleted elemento/i eliminato/i, $failed non riuscito/i.';
  }

  @override
  String transferSummaryFiles(int percent, int completed, int total) {
    return '$percent%  $completed/$total file';
  }

  @override
  String transferSummaryProgress(int percent, int completed, int total) {
    return '$percent%  $completed/$total file';
  }

  @override
  String get downloadFailedGeneric => 'Download non riuscito';

  @override
  String uploadedNItemsWithFailures(int uploaded, int failed) {
    return '$uploaded elemento/i caricato/i, $failed non riuscito/i';
  }

  @override
  String uploadedNItemsFailedM(int uploaded, int failed) {
    return '$uploaded elemento/i caricato/i, $failed non riuscito/i.';
  }

  @override
  String uploadSummaryFailedCount(int count) {
    return ', $count non riuscito/i';
  }

  @override
  String uploadLocalPathEmpty(String name) {
    return '$name: il percorso locale è vuoto';
  }

  @override
  String uploadErrorLocalPathEmpty(String name) {
    return '$name: il percorso locale è vuoto';
  }

  @override
  String get directoryUploadFailed => 'Caricamento della cartella non riuscito';

  @override
  String get uploadDirectoryFailed => 'Caricamento della cartella non riuscito';

  @override
  String get localFileNotFound => 'File locale non trovato';

  @override
  String get uploadErrorLocalFileNotFound => 'File locale non trovato';

  @override
  String get noSessionToken => 'Nessun token di sessione attivo';

  @override
  String get uploadErrorNoSessionToken => 'Nessun token di sessione attivo';

  @override
  String get serverDisconnectedStatus => 'Server disconnesso';

  @override
  String get serverDisconnected => 'Server disconnesso';

  @override
  String get serverIsUnreachable => 'Il server non è raggiungibile.';

  @override
  String get serverUnreachable => 'Il server non è raggiungibile.';

  @override
  String get uploadErrorLocalDirectoryNotFound => 'Cartella locale non trovata';

  @override
  String get uploadErrorFailedToScanDirectory =>
      'Impossibile analizzare la cartella';

  @override
  String uploadErrorFolderCreateHttp(int statusCode) {
    return 'Creazione della cartella non riuscita (HTTP $statusCode)';
  }

  @override
  String get authErrorMissingAccessToken =>
      'Token di accesso mancante nella risposta';

  @override
  String get authErrorMissingRefreshToken =>
      'Token di aggiornamento mancante nella risposta';

  @override
  String get authErrorNoSavedCredentials =>
      'Nessuna credenziale salvata disponibile';

  @override
  String get authErrorNoRefreshToken =>
      'Nessun token di aggiornamento disponibile';

  @override
  String get authErrorNoActiveSession => 'Nessuna sessione attiva disponibile';

  @override
  String get authErrorNoSavedUsername =>
      'Nessun nome utente salvato disponibile';

  @override
  String get updateNoReleasesPublished => 'Nessuna versione pubblicata finora.';

  @override
  String get language => 'Lingua';
}
