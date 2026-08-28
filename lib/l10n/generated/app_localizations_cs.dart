// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get appTitle => 'Crowley\'s Cloud';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Zrušit';

  @override
  String get save => 'Uložit';

  @override
  String get delete => 'Smazat';

  @override
  String get rename => 'Přejmenovat';

  @override
  String get close => 'Zavřít';

  @override
  String get retry => 'Zkusit znovu';

  @override
  String get loading => 'Načítání...';

  @override
  String get confirm => 'Potvrdit';

  @override
  String get error => 'Chyba';

  @override
  String errorWithMessage(String message) {
    return 'Chyba: $message';
  }

  @override
  String get unknown => 'Neznámé';

  @override
  String get upload => 'Nahrát';

  @override
  String get download => 'Stáhnout';

  @override
  String get share => 'Sdílet';

  @override
  String get copy => 'Kopírovat';

  @override
  String get move => 'Přesunout';

  @override
  String get restore => 'Obnovit';

  @override
  String get apply => 'Použít';

  @override
  String get create => 'Vytvořit';

  @override
  String get clear => 'Vymazat';

  @override
  String get add => 'Přidat';

  @override
  String get remove => 'Odebrat';

  @override
  String get edit => 'Upravit';

  @override
  String get switchLabel => 'Přepnout';

  @override
  String get search => 'Hledat';

  @override
  String get name => 'Název';

  @override
  String get date => 'Datum';

  @override
  String get size => 'Velikost';

  @override
  String get type => 'Typ';

  @override
  String get ascending => 'Vzestupně';

  @override
  String get descending => 'Sestupně';

  @override
  String get allFiles => 'Vše';

  @override
  String get categoryImages => 'Obrázky';

  @override
  String get categoryPhotos => 'Fotografie';

  @override
  String get categoryVideos => 'Videa';

  @override
  String get categoryAudio => 'Zvuk';

  @override
  String get categoryDocuments => 'Dokumenty';

  @override
  String get categoryArchives => 'Archivy';

  @override
  String get categoryShared => 'Sdílené';

  @override
  String get categoryOther => 'Ostatní';

  @override
  String get categoryOtherFiles => 'Ostatní soubory';

  @override
  String get noFilesFound => 'Nenalezeny žádné soubory.';

  @override
  String get noFilesInFolder => 'V této složce nejsou žádné soubory.';

  @override
  String get thisActionCannotBeUndone => 'Tuto akci nelze vrátit zpět.';

  @override
  String get passwordsDoNotMatch => 'Hesla se neshodují.';

  @override
  String get navLocalFiles => 'Místní soubory';

  @override
  String get navServerFiles => 'Soubory na serveru';

  @override
  String get navSettings => 'Nastavení';

  @override
  String get navTrash => 'Koš';

  @override
  String get navLocal => 'Místní';

  @override
  String get navServer => 'Server';

  @override
  String get addServer => 'Přidat server';

  @override
  String get noServersConfigured => 'Nejsou nastaveny žádné servery.';

  @override
  String get addAServerInSettings => 'Přidejte server v Nastavení.';

  @override
  String get addFirstServerHint =>
      'Chcete-li pokračovat, přidejte první server.';

  @override
  String get noServersConfiguredYet => 'Zatím nejsou nastaveny žádné servery.';

  @override
  String get crowleysCloudSetup => 'Nastavení Crowley\'s Cloud';

  @override
  String get connect => 'Připojit';

  @override
  String get connecting => 'Připojování...';

  @override
  String get connected => 'Připojeno';

  @override
  String get disconnected => 'Odpojeno';

  @override
  String get switchServer => 'Přepnout server';

  @override
  String get chooseOtherServer => 'Vybrat jiný server';

  @override
  String get switchServerTitle => 'Přepnout server?';

  @override
  String switchServerBody(String serverName) {
    return 'Přepnout aktivní server na „$serverName“?';
  }

  @override
  String get chooseServer => 'Vybrat server';

  @override
  String get authenticationRequired => 'Vyžadováno ověření';

  @override
  String signInToAccess(String serverName) {
    return 'Přihlaste se pro přístup k souborům na serveru $serverName';
  }

  @override
  String get signInWithPassword => 'Přihlásit se heslem';

  @override
  String get useBiometrics => 'Použít biometrii';

  @override
  String get openingSignIn => 'Otevírání přihlášení...';

  @override
  String get serverConnectionFailed => 'Připojení k serveru selhalo';

  @override
  String get unableToConnectToServer =>
      'K aktivnímu serveru se nelze připojit.';

  @override
  String unableToConnectTo(String serverName) {
    return 'K serveru $serverName se nelze připojit.';
  }

  @override
  String get searchHint => 'Hledat...';

  @override
  String get searchFilesHint => 'Hledat soubory...';

  @override
  String get searchServerFilesHint => 'Hledat soubory na serveru...';

  @override
  String get searchTrashHint => 'Hledat v koši...';

  @override
  String get storagePermissionRequired => 'Vyžadováno oprávnění k úložišti';

  @override
  String get grantPermission => 'Udělit oprávnění';

  @override
  String get permissionDeniedOpenSettings =>
      'Oprávnění bylo zamítnuto. Udělte přístup k úložišti v Nastavení.';

  @override
  String get manageStoragePermissionRequired =>
      'K procházení a výběru složek je nutné oprávnění ke správě úložiště.';

  @override
  String get storagePermissionsRequired =>
      'Pro synchronizaci jsou nutná oprávnění k úložišti.';

  @override
  String updateAvailableTitle(String version) {
    return 'Dostupná aktualizace: v$version';
  }

  @override
  String get updateAvailableTapToSeeNew => 'Klepnutím zobrazíte novinky';

  @override
  String get updateView => 'Zobrazit';

  @override
  String get updateAvailableDialogTitle => 'Dostupná aktualizace';

  @override
  String updateVersionSubtitle(String version) {
    return 'Verze $version';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'Aktuální: v$version';
  }

  @override
  String updateNewVersion(String version) {
    return 'Nová: v$version';
  }

  @override
  String get updateWhatsNew => 'Co je nového:';

  @override
  String get updateGitHub => 'GitHub';

  @override
  String get updateNoReleaseNotes => 'Poznámky k vydání nejsou k dispozici.';

  @override
  String get updateLater => 'Později';

  @override
  String get updateDownloadApk => 'Stáhnout APK';

  @override
  String get updateInstall => 'Aktualizovat';

  @override
  String get shareLinkTitle => 'Odkaz ke sdílení';

  @override
  String get shareViaLink => 'Sdílet odkazem';

  @override
  String get shareInServer => 'Sdílet na serveru';

  @override
  String get expiryDays => 'Platnost (dny)';

  @override
  String get expiryNever => 'Nikdy';

  @override
  String get expiry1Day => '1 den';

  @override
  String get expiry7Days => '7 dní';

  @override
  String get expiry30Days => '30 dní';

  @override
  String get expiry90Days => '90 dní';

  @override
  String get expiry180Days => '180 dní';

  @override
  String get expiry365Days => '365 dní';

  @override
  String get createLink => 'Vytvořit odkaz';

  @override
  String get sharedLinkCopied => 'Odkaz ke sdílení byl zkopírován do schránky!';

  @override
  String failedToCopySharedLink(String error) {
    return 'Odkaz ke sdílení se nepodařilo zkopírovat: $error';
  }

  @override
  String get cannotShareThisFileType => 'Tento typ souboru nelze sdílet.';

  @override
  String failedToCreateShare(String error) {
    return 'Sdílení se nepodařilo vytvořit: $error';
  }

  @override
  String get newFolderTitle => 'Vytvořit složku';

  @override
  String get newFolderHint => 'Název složky';

  @override
  String get newFolder => 'Nová složka';

  @override
  String get folderCreated => 'Složka byla vytvořena.';

  @override
  String failedToCreateFolder(String error) {
    return 'Složku se nepodařilo vytvořit: $error';
  }

  @override
  String get creatingFolder => 'Vytváření složky...';

  @override
  String get renameDialogTitle => 'Přejmenovat';

  @override
  String get renameHint => 'Nový název';

  @override
  String get enterNewName => 'Zadejte nový název';

  @override
  String get renamedSuccessfully => 'Přejmenování proběhlo úspěšně.';

  @override
  String renameFailed(String error) {
    return 'Přejmenování selhalo: $error';
  }

  @override
  String get moveDialogTitle => 'Přesunout do';

  @override
  String moveTo(String path) {
    return 'Přesunout do: $path';
  }

  @override
  String get moveHere => 'Přesunout sem';

  @override
  String moveFailed(String error) {
    return 'Přesun selhal: $error';
  }

  @override
  String get movedToFolder => 'Přesunuto do složky.';

  @override
  String copyFailed(String error) {
    return 'Kopírování selhalo: $error';
  }

  @override
  String get selectFolder => 'Vybrat složku';

  @override
  String get useThisFolder => 'Použít tuto složku';

  @override
  String get storageRoot => 'Úložiště';

  @override
  String get serverRoot => 'kořen';

  @override
  String deleteNItemsTitle(int count) {
    return 'Smazat položek: $count?';
  }

  @override
  String get deleteFilesTitle => 'Smazat soubory?';

  @override
  String deleteFilesBody(int count) {
    return 'Opravdu chcete smazat $count vybraných položek? Tuto akci nelze vrátit zpět.';
  }

  @override
  String get deletePermanently => 'Trvale smazat';

  @override
  String get deletePermanentlyTitle => 'Trvale smazat?';

  @override
  String deletePermanentlyBody(String filename) {
    return 'Soubor $filename bude trvale smazán.';
  }

  @override
  String get deleteFileTitle => 'Smazat soubor?';

  @override
  String deleteFileBody(String filename) {
    return 'Opravdu chcete smazat $filename? Tuto akci nelze vrátit zpět.';
  }

  @override
  String get deleteServerFileTitle => 'Trvale smazat';

  @override
  String deleteServerFileBody(String filename) {
    return 'Opravdu chcete trvale smazat „$filename“? Tuto akci nelze vrátit zpět.';
  }

  @override
  String get unshareItemsTitle => 'Zrušit sdílení položek?';

  @override
  String unshareItemsBody(int count) {
    return 'Opravdu chcete zrušit sdílení $count vybraných položek? Budou odstraněny ze složky Sdílené.';
  }

  @override
  String get unshare => 'Zrušit sdílení';

  @override
  String get moveToTrash => 'Přesunout do koše';

  @override
  String get movedToTrash => 'Přesunuto do koše.';

  @override
  String movedNItemsToTrash(int count) {
    return 'Přesunuto do koše položek: $count.';
  }

  @override
  String failedToMoveToTrash(String error) {
    return 'Přesun do koše selhal: $error';
  }

  @override
  String deletedNItems(int count) {
    return 'Smazáno položek: $count.';
  }

  @override
  String failedToDelete(String error) {
    return 'Smazání selhalo: $error';
  }

  @override
  String failedToDeleteItem(String error) {
    return 'Smazání položky selhalo: $error';
  }

  @override
  String deletedFilename(String filename) {
    return 'Soubor $filename byl smazán.';
  }

  @override
  String get failedToOpenFile => 'Soubor se nepodařilo otevřít';

  @override
  String fileDownloadFailed(String error) {
    return 'Stažení souboru selhalo: $error';
  }

  @override
  String get downloading => 'Stahování...';

  @override
  String get downloadingFile => 'Stahování souboru...';

  @override
  String downloadComplete(String filename) {
    return 'Stahování dokončeno: $filename';
  }

  @override
  String downloadFailed(String error) {
    return 'Stahování selhalo: $error';
  }

  @override
  String get failedToDownloadPreview => 'Náhled souboru se nepodařilo stáhnout';

  @override
  String uploadComplete(String filename) {
    return 'Nahrávání dokončeno: $filename';
  }

  @override
  String uploadFailed(String error) {
    return 'Nahrávání selhalo: $error';
  }

  @override
  String get failedToPickFiles => 'Soubory se nepodařilo vybrat';

  @override
  String uploadedNItems(int count) {
    return 'Nahráno položek: $count';
  }

  @override
  String get copiedLinkToClipboard => 'Odkaz byl zkopírován do schránky.';

  @override
  String failedToCopyLink(String error) {
    return 'Odkaz se nepodařilo zkopírovat: $error';
  }

  @override
  String get selectingAll => 'Vybírá se vše...';

  @override
  String get allItemsSelected => 'Všechny položky jsou vybrány.';

  @override
  String get failedToLoadSearchResults =>
      'Výsledky hledání se nepodařilo načíst';

  @override
  String get shareNotSupportedForType =>
      'Sdílení není pro tento typ souboru podporováno.';

  @override
  String nSelected(int count) {
    return 'Vybráno: $count';
  }

  @override
  String get noServerSelected => 'Není vybrán žádný server';

  @override
  String get pleaseConnectToServerFirst => 'Nejprve se připojte k serveru.';

  @override
  String get signInRequired => 'Je nutné se přihlásit';

  @override
  String pleaseSignInToServer(String serverName) {
    return 'Nejprve se přihlaste k serveru $serverName.';
  }

  @override
  String get connectingToServer => 'Připojování k serveru...';

  @override
  String connectedToServer(String serverName) {
    return 'Připojeno k $serverName.';
  }

  @override
  String connectionFailed(String error) {
    return 'Připojení selhalo: $error';
  }

  @override
  String failedToConnect(String error) {
    return 'Připojení se nepodařilo: $error';
  }

  @override
  String authFailed(String error) {
    return 'Ověření selhalo: $error';
  }

  @override
  String get authFailedGeneric => 'Ověření selhalo. Zkuste to znovu.';

  @override
  String biometricLoginFailed(String error) {
    return 'Biometrické přihlášení selhalo: $error';
  }

  @override
  String get biometricLoginFailedGeneric => 'Biometrické přihlášení selhalo.';

  @override
  String get noServerSessionToken =>
      'Chybí token relace serveru. Ověřte server znovu.';

  @override
  String failedToSaveServer(String error) {
    return 'Server se nepodařilo uložit: $error';
  }

  @override
  String get addToFolder => 'Přidat do složky';

  @override
  String get loginTabLabel => 'Přihlásit se';

  @override
  String get registerTabLabel => 'Registrovat se';

  @override
  String get welcomeBack => 'Vítejte zpět';

  @override
  String get signInToContinue => 'Přihlaste se pro pokračování';

  @override
  String get createAccount => 'Vytvořit účet';

  @override
  String get joinTheServer => 'Připojit se k serveru';

  @override
  String get usernameLabel => 'Uživatelské jméno';

  @override
  String get usernameHint => 'Zadejte uživatelské jméno';

  @override
  String get passwordLabel => 'Heslo';

  @override
  String get passwordHint => 'Zadejte heslo';

  @override
  String get showPassword => 'Zobrazit heslo';

  @override
  String get hidePassword => 'Skrýt heslo';

  @override
  String get confirmPassword => 'Potvrdit heslo';

  @override
  String get logIn => 'Přihlásit se';

  @override
  String get loggingIn => 'Přihlašování...';

  @override
  String get registering => 'Registrace...';

  @override
  String get forgotPassword => 'Zapomněli jste heslo?';

  @override
  String get doNotHaveAccount => 'Nemáte účet? Přepněte na registraci.';

  @override
  String get alreadyHaveAccount => 'Už máte účet? Přepněte na přihlášení.';

  @override
  String get usernameCannotBeEmpty => 'Uživatelské jméno nesmí být prázdné.';

  @override
  String get passwordCannotBeEmpty => 'Heslo nesmí být prázdné.';

  @override
  String get usernameInvalid =>
      'Uživatelské jméno musí mít 3–32 znaků: písmena, čísla, _ nebo -.';

  @override
  String get passwordTooShort => 'Heslo musí mít alespoň 8 znaků.';

  @override
  String loginFailed(String error) {
    return 'Přihlášení selhalo: $error';
  }

  @override
  String registrationFailed(String error) {
    return 'Registrace selhala: $error';
  }

  @override
  String get resetPasswordTitle => 'Obnovit heslo';

  @override
  String get enterResetCodeTitle => 'Zadejte obnovovací kód';

  @override
  String get resetPasswordStep1Body =>
      'Zadejte uživatelské jméno. Šestimístný ověřovací kód se zobrazí v protokolu nebo konzoli serveru.';

  @override
  String get resetPasswordStep2Body =>
      'Ověřovací kód byl vypsán do konzole serveru. Zadejte šestimístný kód a nové heslo.';

  @override
  String get resetCodeLabel => 'Obnovovací kód';

  @override
  String get resetCodeHint => 'Zadejte šestimístný kód';

  @override
  String get newPasswordLabel => 'Nové heslo';

  @override
  String get newPasswordHint => 'Zadejte nové heslo';

  @override
  String get passwordResetSuccessfully => 'Heslo bylo úspěšně obnoveno!';

  @override
  String get usernameIsRequired => 'Uživatelské jméno je povinné.';

  @override
  String get codeAndPasswordRequired => 'Kód a nové heslo jsou povinné.';

  @override
  String get failedToRequestReset =>
      'Požadavek na obnovu selhal. Ověřte adresu URL serveru.';

  @override
  String get failedToResetPassword =>
      'Heslo se nepodařilo obnovit. Zkontrolujte kód.';

  @override
  String get pleaseEnterServerUrlFirst => 'Nejprve zadejte adresu URL serveru.';

  @override
  String get sendCode => 'Odeslat kód';

  @override
  String get settingsTitle => 'Nastavení';

  @override
  String get sectionBackupSync => 'Zálohování a synchronizace';

  @override
  String get sectionStorageCache => 'Úložiště a mezipaměť';

  @override
  String get sectionSecurityBehavior => 'Zabezpečení a chování';

  @override
  String get sectionAboutUpdates => 'Informace a aktualizace';

  @override
  String get sectionAppearance => 'Vzhled a přizpůsobení';

  @override
  String get noServersConfiguredSync => 'Nejsou nastaveny žádné servery';

  @override
  String get addServerBeforeSync =>
      'Před nastavením synchronizace přidejte server.';

  @override
  String get selectServerToConfigureSync =>
      'Vyberte server pro nastavení synchronizace.';

  @override
  String get activeServerSuffix => '· aktivní';

  @override
  String get folderAndCategorySync => 'Synchronizace složek a kategorií';

  @override
  String get keepCategoriesSynced =>
      'Udržujte vybrané místní kategorie nebo složky synchronizované s tímto serverem.';

  @override
  String get addServerBeforeSyncEnable =>
      'Před zapnutím synchronizace přidejte server.';

  @override
  String get onlyOnWifi => 'Pouze přes Wi-Fi';

  @override
  String get onlyWhileCharging => 'Pouze při nabíjení';

  @override
  String get serverTargetDirectory => 'Cílový adresář na serveru';

  @override
  String get serverTargetDirectoryHint => '/backup/mobile_phone';

  @override
  String get synchronizationFrequency => 'Frekvence synchronizace';

  @override
  String get syncNow => 'Synchronizovat nyní';

  @override
  String get syncing => 'Synchronizace...';

  @override
  String get categoriesToSynchronize => 'Kategorie k synchronizaci';

  @override
  String get noCategoriesSelected => 'Nejsou vybrány žádné kategorie.';

  @override
  String nCategoriesSelected(int count) {
    return 'Vybráno: $count';
  }

  @override
  String get foldersToSynchronize => 'Složky k synchronizaci';

  @override
  String get noCustomFolders => 'Nejsou nastaveny žádné vlastní složky.';

  @override
  String nFolders(int count) {
    return 'Složek: $count';
  }

  @override
  String get addFolder => 'Přidat složku';

  @override
  String get removeFolder => 'Odebrat složku';

  @override
  String get removeServer => 'Odebrat server';

  @override
  String get syncFreqEvery15Min => 'Každých 15 minut';

  @override
  String get syncFreqEvery30Min => 'Každých 30 minut';

  @override
  String get syncFreqEvery1Hour => 'Každou hodinu';

  @override
  String syncFreqEveryNHours(int hours) {
    return 'Každých $hours hodin';
  }

  @override
  String syncFreqEveryNMin(int minutes) {
    return 'Každých $minutes minut';
  }

  @override
  String get syncFreqDaily => 'Denně';

  @override
  String get chooseSyncFrequencyTitle => 'Vyberte frekvenci synchronizace';

  @override
  String get cacheSize => 'Velikost mezipaměti';

  @override
  String get refreshTooltip => 'Obnovit';

  @override
  String get cacheLimit => 'Limit mezipaměti';

  @override
  String get downloadPath => 'Cesta pro stahování';

  @override
  String get defaultDownloadFolder => 'Výchozí složka CrowleysCloud';

  @override
  String get clearCache => 'Vymazat mezipaměť';

  @override
  String get clearCacheTitle => 'Vymazat mezipaměť?';

  @override
  String get clearCacheBody =>
      'Tímto odstraníte místní náhledy a uložené výpisy serveru.';

  @override
  String get downloadPathDialogTitle => 'Cesta pro stahování';

  @override
  String get downloadPathHint => '/storage/emulated/0/CrowleysCloud';

  @override
  String get useDefault => 'Použít výchozí';

  @override
  String get serverTargetDirDialogTitle => 'Cílový adresář na serveru';

  @override
  String get requireLogin => 'Vyžadovat přihlášení';

  @override
  String get biometricLogin => 'Biometrické přihlášení';

  @override
  String get biometricLoginSubtitle =>
      'Povolit přihlášení uloženými údaji pomocí biometrie.';

  @override
  String get biometricsNotAvailable =>
      'Biometrie není na tomto zařízení k dispozici.';

  @override
  String get showHiddenFiles => 'Zobrazit skryté soubory';

  @override
  String get showHiddenFilesSubtitle =>
      'Zobrazit soubory a složky začínající tečkou.';

  @override
  String get changePassword => 'Změnit heslo';

  @override
  String changePasswordSubtitle(String serverName) {
    return 'Změnit heslo pro $serverName.';
  }

  @override
  String get addServerBeforeChangePassword =>
      'Před změnou hesla přidejte server.';

  @override
  String get deleteUserAccount => 'Smazat uživatelský účet';

  @override
  String get deleteUserAccountSubtitle =>
      'Smaže uživatele a všechny soukromé soubory v cloudu.';

  @override
  String get deleteAccountTitle => 'Smazat účet?';

  @override
  String deleteAccountBody(String serverName) {
    return 'Tímto trvale smažete účet na $serverName a všechny soubory uložené v soukromé cloudové složce. Tuto akci nelze vrátit zpět.';
  }

  @override
  String get deleteAccountButton => 'Smazat účet';

  @override
  String get changePasswordDialogTitle => 'Změnit heslo';

  @override
  String get newPasswordFieldLabel => 'Nové heslo';

  @override
  String get confirmPasswordLabel => 'Potvrdit heslo';

  @override
  String get enterNewPassword => 'Zadejte nové heslo.';

  @override
  String get passwordUpdated => 'Heslo bylo změněno.';

  @override
  String passwordChangeFailed(String error) {
    return 'Změna hesla selhala: $error';
  }

  @override
  String get passwordChangeFailedGeneric => 'Změna hesla selhala.';

  @override
  String get accountDeleted => 'Účet byl smazán.';

  @override
  String accountDeletionFailed(String error) {
    return 'Smazání účtu selhalo: $error';
  }

  @override
  String get accountDeletionFailedGeneric => 'Smazání účtu selhalo.';

  @override
  String get checkForUpdates => 'Zkontrolovat aktualizace';

  @override
  String get checkingForUpdates => 'Kontrola vydání na GitHubu...';

  @override
  String versionLabel(String version) {
    return 'Verze $version';
  }

  @override
  String appIsUpToDate(String version) {
    return 'Crowley\'s Cloud je aktuální (v$version).';
  }

  @override
  String get updateCheckFailed =>
      'Aktualizace se nepodařilo zkontrolovat. Zkuste to později.';

  @override
  String get themeModeTitle => 'Režim motivu';

  @override
  String get themeDark => 'Tmavý';

  @override
  String get themeLight => 'Světlý';

  @override
  String get themeCustom => 'Vlastní';

  @override
  String get themeDarkFull => 'Tmavý motiv';

  @override
  String get themeLightFull => 'Světlý motiv';

  @override
  String get themeCustomFull => 'Vlastní motiv';

  @override
  String get accentColor => 'Barva zvýraznění';

  @override
  String get primaryAccentColor => 'Hlavní barva zvýraznění';

  @override
  String get selectAccentColor => 'Vyberte barvu zvýraznění';

  @override
  String get backgroundColor => 'Barva pozadí';

  @override
  String get surfaceColor => 'Barva povrchu';

  @override
  String get textColor => 'Barva textu';

  @override
  String get subtextColor => 'Barva doplňkového textu';

  @override
  String get borderColor => 'Barva okraje';

  @override
  String get fontSizeScale => 'Měřítko velikosti písma';

  @override
  String selectColor(String title) {
    return 'Vyberte $title';
  }

  @override
  String get categoriesToSyncDialogTitle => 'Kategorie k synchronizaci';

  @override
  String get categoriesToSyncBody =>
      'Vyberte jednu nebo více kategorií. Je možné nechat vše nezaškrtnuté.';

  @override
  String get syncCategorySectionMedia => 'Média';

  @override
  String get syncCategorySectionAudioDocs => 'Zvuk a dokumenty';

  @override
  String get syncCategorySectionOther => 'Ostatní';

  @override
  String get clearAll => 'Vymazat vše';

  @override
  String get noSyncHasRunYet => 'Synchronizace zatím nebyla spuštěna.';

  @override
  String lastRunAt(String date) {
    return 'Poslední spuštění: $date';
  }

  @override
  String syncResultSuccess(int uploaded, int skipped) {
    return 'Synchronizováno: $uploaded, přeskočeno: $skipped.';
  }

  @override
  String get syncResultNoFiles =>
      'K synchronizaci nejsou vybrány žádné soubory.';

  @override
  String syncResultPartial(int uploaded, int failed) {
    return 'Synchronizováno: $uploaded, selhalo: $failed.';
  }

  @override
  String get syncResultAuthRequired => 'Před synchronizací se přihlaste.';

  @override
  String get syncResultUnreachable =>
      'Server není dostupný. Připojení bylo ztraceno.';

  @override
  String get syncResultFailed => 'Synchronizace selhala.';

  @override
  String get serverSetupAddServer => 'Přidat server';

  @override
  String get serverSetupCardTitle => 'Připojit server';

  @override
  String get serverSetupCardSubtitle =>
      'Přidejte domácí souborový server a přihlaste se.';

  @override
  String get serverSetupSubmitButton => 'Uložit server';

  @override
  String get serverNameLabel => 'Název serveru';

  @override
  String get serverNameHint => 'Home NAS';

  @override
  String get baseUrlLabel => 'Základní adresa URL';

  @override
  String get baseUrlHint => 'https://cloud.example.com';

  @override
  String get allFieldsRequired => 'Všechna pole jsou povinná.';

  @override
  String get localFilesTitle => 'Místní soubory';

  @override
  String get serverFilesTitle => 'Soubory na serveru';

  @override
  String get restoreItemsTitle => 'Obnovit položky';

  @override
  String restoreItemsBody(int count) {
    return 'Opravdu chcete obnovit $count položek?';
  }

  @override
  String get permanentlyDeleteTitle => 'Trvale smazat';

  @override
  String permanentlyDeleteBody(int count) {
    return 'Opravdu chcete trvale smazat $count položek? Tuto akci nelze vrátit zpět.';
  }

  @override
  String get trashIsEmpty => 'Koš je prázdný.';

  @override
  String trashRetentionInfo(int days) {
    return 'Položky v koši se automaticky smažou po $days dnech.';
  }

  @override
  String get deletionDate => 'Datum smazání';

  @override
  String get deletePermanentlyAction => 'Trvale smazat';

  @override
  String get conflictFileAlreadyExists => 'Soubor již existuje';

  @override
  String conflictNofM(int current, int total) {
    return 'Konflikt $current z $total';
  }

  @override
  String get conflictAFileNamed => 'Soubor s názvem ';

  @override
  String get conflictAlreadyExistsAt => ' již existuje v umístění ';

  @override
  String get conflictAlreadyExistsInFolder => ' již v této složce existuje.';

  @override
  String get conflictInFolder => 'Ve složce';

  @override
  String get conflictFromTrash => 'Z koše';

  @override
  String get conflictExisting => 'Existující';

  @override
  String get conflictNewUpload => 'Nové nahrání';

  @override
  String conflictSizeLabel(String size) {
    return 'Velikost: $size';
  }

  @override
  String conflictDateLabel(String date) {
    return 'Datum: $date';
  }

  @override
  String conflictDeletedLabel(String date) {
    return 'Smazáno: $date';
  }

  @override
  String conflictApplyToRemaining(int count) {
    return 'Použít na zbývajících konfliktů: $count';
  }

  @override
  String get conflictKeepAllCopies => 'Ponechat všechny kopie';

  @override
  String get conflictOverwriteAll => 'Přepsat vše';

  @override
  String get conflictRestoreAllAsCopies => 'Obnovit vše jako kopie';

  @override
  String get conflictRestoreAsCopy => 'Obnovit jako kopii';

  @override
  String get conflictOverwriteAllRemaining => 'Přepsat vše zbývající';

  @override
  String get conflictSkipAll => 'Přeskočit vše';

  @override
  String get conflictSkipAllRemaining => 'Přeskočit vše zbývající';

  @override
  String get conflictSkip => 'Přeskočit';

  @override
  String get conflictOverwrite => 'Přepsat';

  @override
  String get transfersTitle => 'Přenosy';

  @override
  String get transferResume => 'Pokračovat';

  @override
  String get transferPause => 'Pozastavit';

  @override
  String get transferCancel => 'Zrušit';

  @override
  String get transferResumeAll => 'Obnovit vše';

  @override
  String get transferPauseAll => 'Pozastavit vše';

  @override
  String get transferCancelAll => 'Zrušit vše';

  @override
  String get transferCancelFile => 'Zrušit soubor';

  @override
  String get noTransfers => 'Žádné přenosy.';

  @override
  String get transferStatusQueued => 'Ve frontě';

  @override
  String get transferStatusRunning => 'Probíhá';

  @override
  String get transferStatusPaused => 'Pozastaveno';

  @override
  String get transferStatusCompleted => 'Dokončeno';

  @override
  String get transferStatusFailed => 'Selhalo';

  @override
  String get transferStatusCanceled => 'Zrušeno';

  @override
  String get themePresetsSection => 'Předvolby';

  @override
  String get themeCustomPaletteSection => 'Vlastní paleta';

  @override
  String get themeHexRgbLabel => 'Kód HEX RGB';

  @override
  String get themeHexRgbHint => '#FA5252';

  @override
  String get imageViewerNoFetchHandler =>
      'Není nastaven obslužný program načítání';

  @override
  String get imageViewerFailedToLoad => 'Obrázek se nepodařilo načíst';

  @override
  String errorDeletingFile(String filename, String error) {
    return 'Chyba při mazání $filename: $error';
  }

  @override
  String errorReadingFile(String error) {
    return 'Chyba při čtení souboru: $error';
  }

  @override
  String get syncChannelName => 'Synchronizace na pozadí';

  @override
  String get syncChannelDescription =>
      'Zobrazuje stav souborů synchronizovaných na pozadí.';

  @override
  String get storageStatsTitle => 'Statistiky úložiště';

  @override
  String get storageStatsUsedSpace => 'Využité místo';

  @override
  String get storageStatsTotalFiles => 'Celkem souborů';

  @override
  String storageStatsNItems(int count) {
    return 'Položek: $count';
  }

  @override
  String userFallback(int userId) {
    return 'Uživatel č. $userId';
  }

  @override
  String get biometricUnlockReason =>
      'Odemkněte uložené přihlašovací údaje pro Crowley\'s Cloud.';

  @override
  String get tokenLifetimeEveryOpen => 'Při každém otevření aplikace';

  @override
  String get tokenLifetimeOneHour => 'Po 1 hodině';

  @override
  String get tokenLifetime1Hour => 'Po 1 hodině';

  @override
  String get tokenLifetimeOneDay => 'Po 1 dni';

  @override
  String get tokenLifetime1Day => 'Po 1 dni';

  @override
  String get tokenLifetimeOneWeek => 'Po 1 týdnu';

  @override
  String get tokenLifetime1Week => 'Po 1 týdnu';

  @override
  String get tokenLifetimeOneMonth => 'Po 1 měsíci';

  @override
  String get tokenLifetime1Month => 'Po 1 měsíci';

  @override
  String get tokenLifetimeThreeMonths => 'Po 3 měsících';

  @override
  String get tokenLifetime3Months => 'Po 3 měsících';

  @override
  String get tokenLifetimeNever => 'Nikdy na tomto zařízení';

  @override
  String get cacheLimitUnlimited => 'Bez omezení';

  @override
  String get syncCategoryOtherFiles => 'Ostatní soubory';

  @override
  String get internalStorage => 'Interní úložiště';

  @override
  String get localStorageRootName => 'Interní úložiště';

  @override
  String syncNotificationSyncingWith(String serverName) {
    return 'Synchronizace s $serverName';
  }

  @override
  String syncNotificationPausedTitle(String serverName) {
    return 'Synchronizace s $serverName pozastavena';
  }

  @override
  String get syncNotificationUnreachableBody =>
      'Server není dostupný. Synchronizace na pozadí je pozastavena do otevření aplikace.';

  @override
  String get syncNotificationAuthRequiredBody =>
      'Je vyžadováno ověření. Otevřete aplikaci a přihlaste se.';

  @override
  String syncNotificationFailedTitle(String serverName) {
    return 'Synchronizace s $serverName selhala';
  }

  @override
  String get syncNotificationGenericErrorBody =>
      'Během synchronizace došlo k chybě.';

  @override
  String syncNotificationCompleteTitle(String serverName) {
    return 'Synchronizace s $serverName dokončena';
  }

  @override
  String get syncNotificationCompleteBody => 'Synchronizace dokončena.';

  @override
  String get syncStatusConnecting => 'Připojování k serveru...';

  @override
  String syncStatusConnectionLost(String serverName) {
    return 'K serveru $serverName se nepodařilo připojit. Připojení bylo ztraceno.';
  }

  @override
  String syncResultServerUnreachableWithServer(String serverName) {
    return 'K serveru $serverName se nepodařilo připojit. Připojení bylo ztraceno.';
  }

  @override
  String get syncStatusScanningFiles => 'Prohledávání souborů v zařízení...';

  @override
  String get syncStatusNoFilesFound =>
      'Nenalezeny žádné soubory k synchronizaci.';

  @override
  String get syncStatusNoFilesSelected =>
      'K synchronizaci nejsou vybrány žádné soubory.';

  @override
  String syncStatusCalculatingChecksum(
    int current,
    int total,
    String filename,
  ) {
    return 'Výpočet kontrolního součtu ($current/$total): $filename';
  }

  @override
  String get syncStatusCheckingDuplicates => 'Kontrola duplicit na serveru...';

  @override
  String syncStatusSyncingFile(int current, int total, String filename) {
    return 'Synchronizace ($current/$total): $filename';
  }

  @override
  String get syncStatusCompleting => 'Dokončování synchronizace...';

  @override
  String get showingCachedFiles => 'Zobrazují se soubory z mezipaměti.';

  @override
  String get showingCachedFilesRefreshFailed =>
      'Zobrazují se soubory z mezipaměti. Obnovení selhalo.';

  @override
  String get downloadCanceled => 'Stahování zrušeno.';

  @override
  String downloadedNFilesToPath(int count, String path) {
    return 'Staženo souborů: $count do $path';
  }

  @override
  String downloadedNFilesFailedM(int downloaded, int failed, String detail) {
    return 'Staženo souborů: $downloaded, selhalo: $failed: $detail';
  }

  @override
  String downloadedNFilesWithFailures(int count, int failed, String error) {
    return 'Staženo souborů: $count, selhalo: $failed: $error';
  }

  @override
  String createdNShareLinks(int count) {
    return 'Vytvořeno odkazů ke sdílení: $count.';
  }

  @override
  String get failedToCreateShareLinks =>
      'Odkazy ke sdílení se nepodařilo vytvořit.';

  @override
  String get alreadyInSharedScope => 'Již je v rozsahu sdílení.';

  @override
  String sharedNItemsInServer(int count) {
    return 'Na serveru bylo sdíleno položek: $count.';
  }

  @override
  String sharedNItemsWithFailures(int count, int failed) {
    return 'Sdíleno položek: $count, selhalo: $failed.';
  }

  @override
  String sharedNItemsFailedM(int shared, int failed) {
    return 'Sdíleno položek: $shared, selhalo: $failed.';
  }

  @override
  String get folderNameCannotBeEmpty => 'Název složky nesmí být prázdný.';

  @override
  String get folderAlreadyExists => 'Složka již existuje.';

  @override
  String get folderCreationOnlyInAllFiles =>
      'Složky lze vytvářet pouze ve Všech souborech.';

  @override
  String get currentDirectoryUnavailable =>
      'Aktuální adresář není k dispozici.';

  @override
  String get nothingSelected => 'Není nic vybráno.';

  @override
  String get destinationFolderDoesNotExist => 'Cílová složka neexistuje.';

  @override
  String cannotMoveFolderIntoItself(String name) {
    return 'Složku „$name“ nelze přesunout do ní samotné.';
  }

  @override
  String failedToMoveItem(String name, String error) {
    return 'Položku $name se nepodařilo přesunout: $error';
  }

  @override
  String movedNItems(int count) {
    return 'Přesunuto položek: $count.';
  }

  @override
  String movedNItemsWithFailures(int count, int failed) {
    return 'Přesunuto položek: $count, selhalo: $failed.';
  }

  @override
  String movedNItemsFailedM(int moved, int failed) {
    return 'Přesunuto položek: $moved, selhalo: $failed.';
  }

  @override
  String get failedToMoveSelectedItems =>
      'Vybrané položky se nepodařilo přesunout.';

  @override
  String get noFilesWereMoved => 'Žádné soubory nebyly přesunuty.';

  @override
  String renamedOldToNew(String oldName, String newName) {
    return 'Přejmenováno „$oldName“ na „$newName“.';
  }

  @override
  String renamedFileFromTo(String oldName, String newName) {
    return 'Přejmenováno „$oldName“ na „$newName“.';
  }

  @override
  String failedToRenameWithStatus(String name, int statusCode) {
    return 'Soubor „$name“ se nepodařilo přejmenovat ($statusCode).';
  }

  @override
  String failedToRenameFileWithCode(String name, int statusCode) {
    return 'Soubor „$name“ se nepodařilo přejmenovat ($statusCode).';
  }

  @override
  String failedToRenameWithError(String name, String error) {
    return 'Soubor „$name“ se nepodařilo přejmenovat: $error';
  }

  @override
  String failedToRenameFile(String name, String error) {
    return 'Soubor „$name“ se nepodařilo přejmenovat: $error';
  }

  @override
  String get renameConflictAlreadyExists =>
      'Přejmenování selhalo: soubor nebo složka s tímto názvem již existuje.';

  @override
  String get renameFailedAlreadyExists =>
      'Přejmenování selhalo: soubor nebo složka s tímto názvem již existuje.';

  @override
  String failedToCreateFolderWithCode(int statusCode) {
    return 'Složku se nepodařilo vytvořit ($statusCode).';
  }

  @override
  String deletedNItemsFailedM(int deleted, int failed) {
    return 'Smazáno položek: $deleted, selhalo: $failed.';
  }

  @override
  String transferSummaryFiles(int percent, int completed, int total) {
    return '$percent%  souborů: $completed/$total';
  }

  @override
  String transferSummaryProgress(int percent, int completed, int total) {
    return '$percent%  souborů: $completed/$total';
  }

  @override
  String get downloadFailedGeneric => 'Stahování selhalo';

  @override
  String uploadedNItemsWithFailures(int uploaded, int failed) {
    return 'Nahráno položek: $uploaded, selhalo: $failed';
  }

  @override
  String uploadedNItemsFailedM(int uploaded, int failed) {
    return 'Nahráno položek: $uploaded, selhalo: $failed.';
  }

  @override
  String uploadSummaryFailedCount(int count) {
    return ', selhalo: $count';
  }

  @override
  String uploadLocalPathEmpty(String name) {
    return '$name: místní cesta je prázdná';
  }

  @override
  String uploadErrorLocalPathEmpty(String name) {
    return '$name: místní cesta je prázdná';
  }

  @override
  String get directoryUploadFailed => 'Nahrání adresáře selhalo';

  @override
  String get uploadDirectoryFailed => 'Nahrání adresáře selhalo';

  @override
  String get localFileNotFound => 'Místní soubor nebyl nalezen';

  @override
  String get uploadErrorLocalFileNotFound => 'Místní soubor nebyl nalezen';

  @override
  String get noSessionToken => 'Chybí aktivní token relace';

  @override
  String get uploadErrorNoSessionToken => 'Chybí aktivní token relace';

  @override
  String get serverDisconnectedStatus => 'Server odpojen';

  @override
  String get serverDisconnected => 'Server odpojen';

  @override
  String get serverIsUnreachable => 'Server není dostupný.';

  @override
  String get serverUnreachable => 'Server není dostupný.';

  @override
  String get uploadErrorLocalDirectoryNotFound =>
      'Místní adresář nebyl nalezen';

  @override
  String get uploadErrorFailedToScanDirectory =>
      'Adresář se nepodařilo prohledat';

  @override
  String uploadErrorFolderCreateHttp(int statusCode) {
    return 'Vytvoření složky selhalo (HTTP $statusCode)';
  }

  @override
  String get authErrorMissingAccessToken => 'V odpovědi chybí přístupový token';

  @override
  String get authErrorMissingRefreshToken =>
      'V odpovědi chybí obnovovací token';

  @override
  String get authErrorNoSavedCredentials =>
      'Nejsou k dispozici žádné uložené přihlašovací údaje';

  @override
  String get authErrorNoRefreshToken =>
      'Není k dispozici žádný obnovovací token';

  @override
  String get authErrorNoActiveSession =>
      'Není k dispozici žádná aktivní relace';

  @override
  String get authErrorNoSavedUsername =>
      'Není k dispozici žádné uložené uživatelské jméno';

  @override
  String get updateNoReleasesPublished =>
      'Zatím nebylo zveřejněno žádné vydání.';

  @override
  String get language => 'Jazyk';
}
