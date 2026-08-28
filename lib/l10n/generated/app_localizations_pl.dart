// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Crowley\'s Cloud';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Anuluj';

  @override
  String get save => 'Zapisz';

  @override
  String get delete => 'Usuń';

  @override
  String get rename => 'Zmień nazwę';

  @override
  String get close => 'Zamknij';

  @override
  String get retry => 'Ponów';

  @override
  String get loading => 'Ładowanie...';

  @override
  String get confirm => 'Potwierdź';

  @override
  String get error => 'Błąd';

  @override
  String errorWithMessage(String message) {
    return 'Błąd: $message';
  }

  @override
  String get unknown => 'Nieznany';

  @override
  String get upload => 'Prześlij';

  @override
  String get download => 'Pobierz';

  @override
  String get share => 'Udostępnij';

  @override
  String get copy => 'Kopiuj';

  @override
  String get move => 'Przenieś';

  @override
  String get restore => 'Przywróć';

  @override
  String get apply => 'Zastosuj';

  @override
  String get create => 'Utwórz';

  @override
  String get clear => 'Wyczyść';

  @override
  String get add => 'Dodaj';

  @override
  String get remove => 'Usuń';

  @override
  String get edit => 'Edytuj';

  @override
  String get switchLabel => 'Przełącz';

  @override
  String get search => 'Szukaj';

  @override
  String get name => 'Nazwa';

  @override
  String get date => 'Data';

  @override
  String get size => 'Rozmiar';

  @override
  String get type => 'Typ';

  @override
  String get ascending => 'Rosnąco';

  @override
  String get descending => 'Malejąco';

  @override
  String get allFiles => 'Wszystkie';

  @override
  String get categoryImages => 'Obrazy';

  @override
  String get categoryPhotos => 'Zdjęcia';

  @override
  String get categoryVideos => 'Wideo';

  @override
  String get categoryAudio => 'Audio';

  @override
  String get categoryDocuments => 'Dokumenty';

  @override
  String get categoryArchives => 'Archiwa';

  @override
  String get categoryShared => 'Udostępnione';

  @override
  String get categoryOther => 'Inne';

  @override
  String get categoryOtherFiles => 'Inne pliki';

  @override
  String get noFilesFound => 'Nie znaleziono plików.';

  @override
  String get noFilesInFolder => 'Brak plików w tym folderze.';

  @override
  String get thisActionCannotBeUndone => 'Tej operacji nie można cofnąć.';

  @override
  String get passwordsDoNotMatch => 'Hasła nie są zgodne.';

  @override
  String get navLocalFiles => 'Pliki lokalne';

  @override
  String get navServerFiles => 'Pliki serwera';

  @override
  String get navSettings => 'Ustawienia';

  @override
  String get navTrash => 'Kosz';

  @override
  String get navLocal => 'Lokalne';

  @override
  String get navServer => 'Serwer';

  @override
  String get addServer => 'Dodaj serwer';

  @override
  String get noServersConfigured => 'Brak skonfigurowanych serwerów.';

  @override
  String get addAServerInSettings => 'Dodaj serwer w Ustawieniach.';

  @override
  String get addFirstServerHint =>
      'Dodaj swój pierwszy serwer, aby kontynuować.';

  @override
  String get noServersConfiguredYet => 'Brak skonfigurowanych serwerów.';

  @override
  String get crowleysCloudSetup => 'Konfiguracja Crowley\'s Cloud';

  @override
  String get connect => 'Połącz';

  @override
  String get connecting => 'Łączenie...';

  @override
  String get connected => 'Połączono';

  @override
  String get disconnected => 'Rozłączono';

  @override
  String get switchServer => 'Przełącz serwer';

  @override
  String get chooseOtherServer => 'Wybierz inny serwer';

  @override
  String get switchServerTitle => 'Przełączyć serwer?';

  @override
  String switchServerBody(String serverName) {
    return 'Przełączyć aktywny serwer na \"$serverName\"?';
  }

  @override
  String get chooseServer => 'Wybierz serwer';

  @override
  String get authenticationRequired => 'Wymagane uwierzytelnienie';

  @override
  String signInToAccess(String serverName) {
    return 'Zaloguj się, aby uzyskać dostęp do plików na $serverName';
  }

  @override
  String get signInWithPassword => 'Zaloguj się za pomocą hasła';

  @override
  String get useBiometrics => 'Użyj biometrii';

  @override
  String get openingSignIn => 'Otwieranie logowania...';

  @override
  String get serverConnectionFailed => 'Błąd połączenia z serwerem';

  @override
  String get unableToConnectToServer =>
      'Nie można połączyć się z aktywnym serwerem.';

  @override
  String unableToConnectTo(String serverName) {
    return 'Nie można połączyć się z $serverName.';
  }

  @override
  String get searchHint => 'Szukaj...';

  @override
  String get searchFilesHint => 'Szukaj plików...';

  @override
  String get searchServerFilesHint => 'Szukaj plików na serwerze...';

  @override
  String get searchTrashHint => 'Szukaj w koszu...';

  @override
  String get storagePermissionRequired => 'Wymagane uprawnienie do pamięci';

  @override
  String get grantPermission => 'Przyznaj uprawnienie';

  @override
  String get permissionDeniedOpenSettings =>
      'Odmowa uprawnień. Przyznaj dostęp do pamięci w Ustawieniach.';

  @override
  String get manageStoragePermissionRequired =>
      'Uprawnienie do zarządzania pamięcią jest wymagane do przeglądania i wybierania folderów.';

  @override
  String get storagePermissionsRequired =>
      'Uprawnienia do pamięci są wymagane do przeprowadzenia synchronizacji.';

  @override
  String updateAvailableTitle(String version) {
    return 'Dostępna aktualizacja: v$version';
  }

  @override
  String get updateAvailableTapToSeeNew => 'Dotknij, aby zobaczyć, co nowego';

  @override
  String get updateView => 'Zobacz';

  @override
  String get updateAvailableDialogTitle => 'Dostępna aktualizacja';

  @override
  String updateVersionSubtitle(String version) {
    return 'Wersja $version';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'Bieżąca: v$version';
  }

  @override
  String updateNewVersion(String version) {
    return 'Nowa: v$version';
  }

  @override
  String get updateWhatsNew => 'Co nowego:';

  @override
  String get updateGitHub => 'GitHub';

  @override
  String get updateNoReleaseNotes => 'Brak informacji o wydaniu.';

  @override
  String get updateLater => 'Później';

  @override
  String get updateDownloadApk => 'Pobierz APK';

  @override
  String get updateInstall => 'Aktualizuj';

  @override
  String get shareLinkTitle => 'Link udostępniania';

  @override
  String get shareViaLink => 'Udostępnij przez link';

  @override
  String get shareInServer => 'Udostępnij na serwerze';

  @override
  String get expiryDays => 'Ważność (dni)';

  @override
  String get expiryNever => 'Nigdy';

  @override
  String get expiry1Day => '1 dzień';

  @override
  String get expiry7Days => '7 dni';

  @override
  String get expiry30Days => '30 dni';

  @override
  String get expiry90Days => '90 dni';

  @override
  String get expiry180Days => '180 dni';

  @override
  String get expiry365Days => '365 dni';

  @override
  String get createLink => 'Utwórz link';

  @override
  String get sharedLinkCopied => 'Link udostępniania skopiowano do schowka!';

  @override
  String failedToCopySharedLink(String error) {
    return 'Nie udało się skopiować linku: $error';
  }

  @override
  String get cannotShareThisFileType => 'Nie można udostępnić tego typu pliku.';

  @override
  String failedToCreateShare(String error) {
    return 'Nie udało się utworzyć udostępnienia: $error';
  }

  @override
  String get newFolderTitle => 'Utwórz folder';

  @override
  String get newFolderHint => 'Nazwa folderu';

  @override
  String get newFolder => 'Nowy folder';

  @override
  String get folderCreated => 'Folder został utworzony.';

  @override
  String failedToCreateFolder(String error) {
    return 'Nie udało się utworzyć folderu: $error';
  }

  @override
  String get creatingFolder => 'Tworzenie folderu...';

  @override
  String get renameDialogTitle => 'Zmień nazwę';

  @override
  String get renameHint => 'Nowa nazwa';

  @override
  String get enterNewName => 'Wprowadź nową nazwę';

  @override
  String get renamedSuccessfully => 'Pomyślnie zmieniono nazwę.';

  @override
  String renameFailed(String error) {
    return 'Nie udało się zmienić nazwy: $error';
  }

  @override
  String get moveDialogTitle => 'Przenieś do';

  @override
  String moveTo(String path) {
    return 'Przenieś do: $path';
  }

  @override
  String get moveHere => 'Przenieś tutaj';

  @override
  String moveFailed(String error) {
    return 'Nie udało się przenieść: $error';
  }

  @override
  String get movedToFolder => 'Przeniesiono do folderu.';

  @override
  String copyFailed(String error) {
    return 'Nie udało się skopiować: $error';
  }

  @override
  String get selectFolder => 'Wybierz folder';

  @override
  String get useThisFolder => 'Użyj tego folderu';

  @override
  String get storageRoot => 'Pamięć urządzenia';

  @override
  String get serverRoot => 'katalog główny';

  @override
  String deleteNItemsTitle(int count) {
    return 'Usunąć $count elementów?';
  }

  @override
  String get deleteFilesTitle => 'Usunąć pliki?';

  @override
  String deleteFilesBody(int count) {
    return 'Czy na pewno chcesz usunąć $count wybranych elementów? Tej operacji nie można cofnąć.';
  }

  @override
  String get deletePermanently => 'Usuń trwale';

  @override
  String get deletePermanentlyTitle => 'Usunąć trwale?';

  @override
  String deletePermanentlyBody(String filename) {
    return '$filename zostanie trwale usunięty.';
  }

  @override
  String get deleteFileTitle => 'Usunąć plik?';

  @override
  String deleteFileBody(String filename) {
    return 'Czy na pewno chcesz usunąć $filename? Tej operacji nie można cofnąć.';
  }

  @override
  String get deleteServerFileTitle => 'Usuń trwale';

  @override
  String deleteServerFileBody(String filename) {
    return 'Czy na pewno chcesz trwale usunąć \"$filename\"? Tej operacji nie można cofnąć.';
  }

  @override
  String get unshareItemsTitle => 'Cofnąć udostępnienie elementów?';

  @override
  String unshareItemsBody(int count) {
    return 'Czy na pewno chcesz cofnąć udostępnienie $count wybranych elementów? Zostaną one usunięte z folderu Udostępnione.';
  }

  @override
  String get unshare => 'Cofnij udostępnienie';

  @override
  String get moveToTrash => 'Przenieś do kosza';

  @override
  String get movedToTrash => 'Przeniesiono do kosza.';

  @override
  String movedNItemsToTrash(int count) {
    return 'Przeniesiono $count elementów do kosza.';
  }

  @override
  String failedToMoveToTrash(String error) {
    return 'Nie udało się przenieść do kosza: $error';
  }

  @override
  String deletedNItems(int count) {
    return 'Usunięto $count elementów.';
  }

  @override
  String failedToDelete(String error) {
    return 'Nie udało się usunąć: $error';
  }

  @override
  String failedToDeleteItem(String error) {
    return 'Usuwanie nie powiodło się: $error';
  }

  @override
  String deletedFilename(String filename) {
    return 'Usunięto $filename.';
  }

  @override
  String get failedToOpenFile => 'Nie udało się otworzyć pliku';

  @override
  String fileDownloadFailed(String error) {
    return 'Pobieranie pliku nie powiodło się: $error';
  }

  @override
  String get downloading => 'Pobieranie...';

  @override
  String get downloadingFile => 'Pobieranie pliku...';

  @override
  String downloadComplete(String filename) {
    return 'Pobieranie ukończone: $filename';
  }

  @override
  String downloadFailed(String error) {
    return 'Pobieranie nie powiodło się: $error';
  }

  @override
  String get failedToDownloadPreview => 'Nie udało się pobrać podglądu pliku';

  @override
  String uploadComplete(String filename) {
    return 'Przesyłanie ukończone: $filename';
  }

  @override
  String uploadFailed(String error) {
    return 'Przesyłanie nie powiodło się: $error';
  }

  @override
  String get failedToPickFiles => 'Nie udało się wybrać plików';

  @override
  String uploadedNItems(int count) {
    return 'Przesłano $count elementów';
  }

  @override
  String get copiedLinkToClipboard => 'Link skopiowano do schowka.';

  @override
  String failedToCopyLink(String error) {
    return 'Nie udało się skopiować linku: $error';
  }

  @override
  String get selectingAll => 'Zaznaczanie wszystkiego...';

  @override
  String get allItemsSelected => 'Wszystkie elementy zaznaczone.';

  @override
  String get failedToLoadSearchResults =>
      'Nie udało się załadować wyników wyszukiwania';

  @override
  String get shareNotSupportedForType =>
      'Udostępnianie nie jest obsługiwane dla tego typu pliku.';

  @override
  String nSelected(int count) {
    return 'Wybrano: $count';
  }

  @override
  String get noServerSelected => 'Nie wybrano serwera';

  @override
  String get pleaseConnectToServerFirst => 'Najpierw połącz się z serwerem.';

  @override
  String get signInRequired => 'Wymagane logowanie';

  @override
  String pleaseSignInToServer(String serverName) {
    return 'Najpierw zaloguj się do $serverName.';
  }

  @override
  String get connectingToServer => 'Łączenie z serwerem...';

  @override
  String connectedToServer(String serverName) {
    return 'Połączono z $serverName.';
  }

  @override
  String connectionFailed(String error) {
    return 'Połączenie nie powiodło się: $error';
  }

  @override
  String failedToConnect(String error) {
    return 'Nie udało się połączyć: $error';
  }

  @override
  String authFailed(String error) {
    return 'Uwierzytelnianie nie powiodło się: $error';
  }

  @override
  String get authFailedGeneric =>
      'Uwierzytelnianie nie powiodło się. Spróbuj ponownie.';

  @override
  String biometricLoginFailed(String error) {
    return 'Logowanie biometryczne nie powiodło się: $error';
  }

  @override
  String get biometricLoginFailedGeneric =>
      'Logowanie biometryczne nie powiodło się.';

  @override
  String get noServerSessionToken =>
      'Brak tokenu sesji serwera. Zaloguj się ponownie do serwera.';

  @override
  String failedToSaveServer(String error) {
    return 'Nie udało się zapisać serwera: $error';
  }

  @override
  String get addToFolder => 'Dodaj do folderu';

  @override
  String get loginTabLabel => 'Zaloguj się';

  @override
  String get registerTabLabel => 'Zarejestruj się';

  @override
  String get welcomeBack => 'Witamy ponownie';

  @override
  String get signInToContinue => 'Zaloguj się, aby kontynuować';

  @override
  String get createAccount => 'Utwórz konto';

  @override
  String get joinTheServer => 'Dołącz do serwera';

  @override
  String get usernameLabel => 'Nazwa użytkownika';

  @override
  String get usernameHint => 'Wprowadź nazwę użytkownika';

  @override
  String get passwordLabel => 'Hasło';

  @override
  String get passwordHint => 'Wprowadź hasło';

  @override
  String get showPassword => 'Pokaż hasło';

  @override
  String get hidePassword => 'Ukryj hasło';

  @override
  String get confirmPassword => 'Potwierdź hasło';

  @override
  String get logIn => 'Zaloguj się';

  @override
  String get loggingIn => 'Logowanie...';

  @override
  String get registering => 'Rejestracja...';

  @override
  String get forgotPassword => 'Nie pamiętasz hasła?';

  @override
  String get doNotHaveAccount => 'Nie masz konta? Przejdź do rejestracji.';

  @override
  String get alreadyHaveAccount => 'Masz już konto? Przejdź do logowania.';

  @override
  String get usernameCannotBeEmpty => 'Nazwa użytkownika nie może być pusta.';

  @override
  String get passwordCannotBeEmpty => 'Hasło nie może być puste.';

  @override
  String get usernameInvalid =>
      'Nazwa użytkownika musi mieć 3–32 znaki: litery, cyfry, _ lub -.';

  @override
  String get passwordTooShort => 'Hasło musi mieć co najmniej 8 znaków.';

  @override
  String loginFailed(String error) {
    return 'Logowanie nie powiodło się: $error';
  }

  @override
  String registrationFailed(String error) {
    return 'Rejestracja nie powiodła się: $error';
  }

  @override
  String get resetPasswordTitle => 'Zresetuj hasło';

  @override
  String get enterResetCodeTitle => 'Wprowadź kod resetowania';

  @override
  String get resetPasswordStep1Body =>
      'Wprowadź nazwę użytkownika. 6-cyfrowy kod weryfikacyjny zostanie wyświetlony w dziennikach/konsoli serwera.';

  @override
  String get resetPasswordStep2Body =>
      'Kod weryfikacyjny został wyświetlony w konsoli serwera. Wprowadź 6-cyfrowy kod oraz nowe hasło.';

  @override
  String get resetCodeLabel => 'Kod resetowania';

  @override
  String get resetCodeHint => 'Wprowadź 6-cyfrowy kod';

  @override
  String get newPasswordLabel => 'Nowe hasło';

  @override
  String get newPasswordHint => 'Wprowadź nowe hasło';

  @override
  String get passwordResetSuccessfully =>
      'Hasło zostało pomyślnie zresetowane!';

  @override
  String get usernameIsRequired => 'Nazwa użytkownika jest wymagana.';

  @override
  String get codeAndPasswordRequired => 'Wymagany jest kod oraz nowe hasło.';

  @override
  String get failedToRequestReset =>
      'Nie udało się zażądać resetowania. Sprawdź adres URL serwera.';

  @override
  String get failedToResetPassword =>
      'Nie udało się zresetować hasła. Sprawdź kod.';

  @override
  String get pleaseEnterServerUrlFirst =>
      'Najpierw wprowadź adres URL serwera.';

  @override
  String get sendCode => 'Wyślij kod';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get sectionBackupSync => 'Kopia zapasowa i synchronizacja';

  @override
  String get sectionStorageCache => 'Pamięć i pamięć podręczna';

  @override
  String get sectionSecurityBehavior => 'Bezpieczeństwo i zachowanie';

  @override
  String get sectionAboutUpdates => 'O aplikacji i aktualizacje';

  @override
  String get sectionAppearance => 'Wygląd i personalizacja';

  @override
  String get noServersConfiguredSync => 'Brak skonfigurowanych serwerów';

  @override
  String get addServerBeforeSync =>
      'Dodaj serwer przed konfiguracją synchronizacji.';

  @override
  String get selectServerToConfigureSync =>
      'Wybierz serwer, aby skonfigurować jego ustawienia synchronizacji.';

  @override
  String get activeServerSuffix => '· aktywny';

  @override
  String get folderAndCategorySync => 'Synchronizacja folderów i kategorii';

  @override
  String get keepCategoriesSynced =>
      'Utrzymuj wybrane lokalne kategorie lub foldery zsynchronizowane z tym serwerem.';

  @override
  String get addServerBeforeSyncEnable =>
      'Dodaj serwer przed włączeniem synchronizacji.';

  @override
  String get onlyOnWifi => 'Tylko przez Wi-Fi';

  @override
  String get onlyWhileCharging => 'Tylko podczas ładowania';

  @override
  String get serverTargetDirectory => 'Folder docelowy na serwerze';

  @override
  String get serverTargetDirectoryHint => '/backup/mobile_phone';

  @override
  String get synchronizationFrequency => 'Częstotliwość synchronizacji';

  @override
  String get syncNow => 'Synchronizuj teraz';

  @override
  String get syncing => 'Synchronizowanie...';

  @override
  String get categoriesToSynchronize => 'Kategorie do synchronizacji';

  @override
  String get noCategoriesSelected => 'Nie wybrano żadnych kategorii.';

  @override
  String nCategoriesSelected(int count) {
    return 'Wybrano: $count';
  }

  @override
  String get foldersToSynchronize => 'Foldery do synchronizacji';

  @override
  String get noCustomFolders =>
      'Brak skonfigurowanych folderów niestandardowych.';

  @override
  String nFolders(int count) {
    return '$count folderów';
  }

  @override
  String get addFolder => 'Dodaj folder';

  @override
  String get removeFolder => 'Usuń folder';

  @override
  String get removeServer => 'Usuń serwer';

  @override
  String get syncFreqEvery15Min => 'Co 15 minut';

  @override
  String get syncFreqEvery30Min => 'Co 30 minut';

  @override
  String get syncFreqEvery1Hour => 'Co godzinę';

  @override
  String syncFreqEveryNHours(int hours) {
    return 'Co $hours godz.';
  }

  @override
  String syncFreqEveryNMin(int minutes) {
    return 'Co $minutes min';
  }

  @override
  String get syncFreqDaily => 'Codziennie';

  @override
  String get chooseSyncFrequencyTitle => 'Wybierz częstotliwość synchronizacji';

  @override
  String get cacheSize => 'Rozmiar pamięci podręcznej';

  @override
  String get refreshTooltip => 'Odśwież';

  @override
  String get cacheLimit => 'Limit pamięci podręcznej';

  @override
  String get downloadPath => 'Ścieżka pobierania';

  @override
  String get defaultDownloadFolder => 'Domyślny folder CrowleysCloud';

  @override
  String get clearCache => 'Wyczyść pamięć podręczną';

  @override
  String get clearCacheTitle => 'Wyczyścić pamięć podręczną?';

  @override
  String get clearCacheBody =>
      'Spowoduje to usunięcie lokalnych miniatur i zapisanych list serwera.';

  @override
  String get downloadPathDialogTitle => 'Ścieżka pobierania';

  @override
  String get downloadPathHint => '/storage/emulated/0/CrowleysCloud';

  @override
  String get useDefault => 'Użyj domyślnej';

  @override
  String get serverTargetDirDialogTitle => 'Folder docelowy na serwerze';

  @override
  String get requireLogin => 'Wymagaj logowania';

  @override
  String get biometricLogin => 'Logowanie biometryczne';

  @override
  String get biometricLoginSubtitle =>
      'Zezwalaj na logowanie zapisanymi danymi za pomocą biometrii.';

  @override
  String get biometricsNotAvailable =>
      'Biometria jest niedostępna na tym urządzeniu.';

  @override
  String get showHiddenFiles => 'Pokaż ukryte pliki';

  @override
  String get showHiddenFilesSubtitle =>
      'Wyświetlaj pliki i foldery z kropką na początku.';

  @override
  String get changePassword => 'Zmień hasło';

  @override
  String changePasswordSubtitle(String serverName) {
    return 'Zaktualizuj hasło dla $serverName.';
  }

  @override
  String get addServerBeforeChangePassword =>
      'Dodaj serwer przed zmianą hasła.';

  @override
  String get deleteUserAccount => 'Usuń konto użytkownika';

  @override
  String get deleteUserAccountSubtitle =>
      'Usuwa użytkownika oraz wszystkie prywatne pliki w chmurze.';

  @override
  String get deleteAccountTitle => 'Usunąć konto?';

  @override
  String deleteAccountBody(String serverName) {
    return 'Spowoduje to trwałe usunięcie Twojego konta na $serverName oraz usunięcie wszystkich plików przechowywanych w Twoim prywatnym folderze w chmurze. Tej operacji nie można cofnąć.';
  }

  @override
  String get deleteAccountButton => 'Usuń konto';

  @override
  String get changePasswordDialogTitle => 'Zmień hasło';

  @override
  String get newPasswordFieldLabel => 'Nowe hasło';

  @override
  String get confirmPasswordLabel => 'Potwierdź hasło';

  @override
  String get enterNewPassword => 'Wprowadź nowe hasło.';

  @override
  String get passwordUpdated => 'Hasło zostało zaktualizowane.';

  @override
  String passwordChangeFailed(String error) {
    return 'Zmiana hasła nie powiodła się: $error';
  }

  @override
  String get passwordChangeFailedGeneric => 'Zmiana hasła nie powiodła się.';

  @override
  String get accountDeleted => 'Konto zostało usunięte.';

  @override
  String accountDeletionFailed(String error) {
    return 'Usunięcie konta nie powiodło się: $error';
  }

  @override
  String get accountDeletionFailedGeneric =>
      'Usunięcie konta nie powiodło się.';

  @override
  String get checkForUpdates => 'Sprawdź dostępność aktualizacji';

  @override
  String get checkingForUpdates => 'Sprawdzanie wydań na GitHubie...';

  @override
  String versionLabel(String version) {
    return 'Wersja $version';
  }

  @override
  String appIsUpToDate(String version) {
    return 'Aplikacja Crowley\'s Cloud jest aktualna (v$version).';
  }

  @override
  String get updateCheckFailed =>
      'Nie udało się sprawdzić aktualizacji. Spróbuj ponownie później.';

  @override
  String get themeModeTitle => 'Tryb motywu';

  @override
  String get themeDark => 'Ciemny';

  @override
  String get themeLight => 'Jasny';

  @override
  String get themeCustom => 'Własny';

  @override
  String get themeDarkFull => 'Ciemny motyw';

  @override
  String get themeLightFull => 'Jasny motyw';

  @override
  String get themeCustomFull => 'Własny motyw';

  @override
  String get accentColor => 'Kolor akcentu';

  @override
  String get primaryAccentColor => 'Główny kolor akcentu';

  @override
  String get selectAccentColor => 'Wybierz kolor akcentu';

  @override
  String get backgroundColor => 'Kolor tła';

  @override
  String get surfaceColor => 'Kolor powierzchni';

  @override
  String get textColor => 'Kolor tekstu';

  @override
  String get subtextColor => 'Kolor tekstu podrzędnego';

  @override
  String get borderColor => 'Kolor obramowania';

  @override
  String get fontSizeScale => 'Skala rozmiaru czcionki';

  @override
  String selectColor(String title) {
    return 'Wybierz kolor: $title';
  }

  @override
  String get categoriesToSyncDialogTitle => 'Kategorie do synchronizacji';

  @override
  String get categoriesToSyncBody =>
      'Wybierz jedną lub więcej kategorii. Pozostawienie wszystkich niezaznaczonych jest dopuszczalne.';

  @override
  String get syncCategorySectionMedia => 'Multimedia';

  @override
  String get syncCategorySectionAudioDocs => 'Audio i dokumenty';

  @override
  String get syncCategorySectionOther => 'Inne';

  @override
  String get clearAll => 'Wyczyść wszystko';

  @override
  String get noSyncHasRunYet => 'Synchronizacja nie była jeszcze uruchamiana.';

  @override
  String lastRunAt(String date) {
    return 'Ostatnie uruchomienie: $date';
  }

  @override
  String syncResultSuccess(int uploaded, int skipped) {
    return 'Zsynchronizowano: $uploaded, pominięto: $skipped.';
  }

  @override
  String get syncResultNoFiles => 'Nie wybrano plików do synchronizacji.';

  @override
  String syncResultPartial(int uploaded, int failed) {
    return 'Zsynchronizowano: $uploaded, niepowodzenie: $failed.';
  }

  @override
  String get syncResultAuthRequired => 'Zaloguj się przed synchronizacją.';

  @override
  String get syncResultUnreachable =>
      'Serwer jest nieosiągalny. Utracono połączenie.';

  @override
  String get syncResultFailed => 'Synchronizacja nie powiodła się.';

  @override
  String get serverSetupAddServer => 'Dodaj serwer';

  @override
  String get serverSetupCardTitle => 'Połącz z serwerem';

  @override
  String get serverSetupCardSubtitle =>
      'Dodaj domowy serwer plików i zaloguj się.';

  @override
  String get serverSetupSubmitButton => 'Zapisz serwer';

  @override
  String get serverNameLabel => 'Nazwa serwera';

  @override
  String get serverNameHint => 'Domowy NAS';

  @override
  String get baseUrlLabel => 'Bazowy adres URL';

  @override
  String get baseUrlHint => 'https://cloud.example.com';

  @override
  String get allFieldsRequired => 'Wszystkie pola są wymagane.';

  @override
  String get localFilesTitle => 'Pliki lokalne';

  @override
  String get serverFilesTitle => 'Pliki serwera';

  @override
  String get restoreItemsTitle => 'Przywrócić elementy';

  @override
  String restoreItemsBody(int count) {
    return 'Czy na pewno chcesz przywrócić $count elementów?';
  }

  @override
  String get permanentlyDeleteTitle => 'Usunąć trwale';

  @override
  String permanentlyDeleteBody(int count) {
    return 'Czy na pewno chcesz trwale usunąć $count elementów? Tej operacji nie można cofnąć.';
  }

  @override
  String get trashIsEmpty => 'Kosz jest pusty.';

  @override
  String trashRetentionInfo(int days) {
    return 'Elementy w koszu są automatycznie usuwane po $days dniach.';
  }

  @override
  String get deletionDate => 'Data usunięcia';

  @override
  String get deletePermanentlyAction => 'Usuń trwale';

  @override
  String get conflictFileAlreadyExists => 'Plik już istnieje';

  @override
  String conflictNofM(int current, int total) {
    return 'Konflikt $current z $total';
  }

  @override
  String get conflictAFileNamed => 'Plik o nazwie ';

  @override
  String get conflictAlreadyExistsAt => ' już istnieje w ';

  @override
  String get conflictAlreadyExistsInFolder => ' już istnieje w tym folderze.';

  @override
  String get conflictInFolder => 'W folderze';

  @override
  String get conflictFromTrash => 'Z kosza';

  @override
  String get conflictExisting => 'Istniejący';

  @override
  String get conflictNewUpload => 'Nowy plik';

  @override
  String conflictSizeLabel(String size) {
    return 'Rozmiar: $size';
  }

  @override
  String conflictDateLabel(String date) {
    return 'Data: $date';
  }

  @override
  String conflictDeletedLabel(String date) {
    return 'Usunięto: $date';
  }

  @override
  String conflictApplyToRemaining(int count) {
    return 'Zastosuj do pozostałych $count konfliktów';
  }

  @override
  String get conflictKeepAllCopies => 'Zachowaj wszystkie kopie';

  @override
  String get conflictOverwriteAll => 'Zastąp wszystkie';

  @override
  String get conflictRestoreAllAsCopies => 'Przywróć wszystkie jako kopie';

  @override
  String get conflictRestoreAsCopy => 'Przywróć jako kopię';

  @override
  String get conflictOverwriteAllRemaining => 'Zastąp wszystkie pozostałe';

  @override
  String get conflictSkipAll => 'Pomiń wszystkie';

  @override
  String get conflictSkipAllRemaining => 'Pomiń wszystkie pozostałe';

  @override
  String get conflictSkip => 'Pomiń';

  @override
  String get conflictOverwrite => 'Zastąp';

  @override
  String get transfersTitle => 'Transfery';

  @override
  String get transferResume => 'Wznów';

  @override
  String get transferPause => 'Wstrzymaj';

  @override
  String get transferCancel => 'Anuluj';

  @override
  String get transferResumeAll => 'Wznów wszystkie';

  @override
  String get transferPauseAll => 'Wstrzymaj wszystkie';

  @override
  String get transferCancelAll => 'Anuluj wszystkie';

  @override
  String get transferCancelFile => 'Anuluj plik';

  @override
  String get noTransfers => 'Brak transferów.';

  @override
  String get transferStatusQueued => 'W kolejce';

  @override
  String get transferStatusRunning => 'Przesyłanie';

  @override
  String get transferStatusPaused => 'Wstrzymano';

  @override
  String get transferStatusCompleted => 'Ukończono';

  @override
  String get transferStatusFailed => 'Niepowodzenie';

  @override
  String get transferStatusCanceled => 'Anulowano';

  @override
  String get themePresetsSection => 'Gotowe szablony';

  @override
  String get themeCustomPaletteSection => 'Własna paleta';

  @override
  String get themeHexRgbLabel => 'Kod HEX RGB';

  @override
  String get themeHexRgbHint => '#FA5252';

  @override
  String get imageViewerNoFetchHandler =>
      'Nie skonfigurowano procedury pobierania';

  @override
  String get imageViewerFailedToLoad => 'Nie udało się załadować obrazu';

  @override
  String errorDeletingFile(String filename, String error) {
    return 'Błąd podczas usuwania $filename: $error';
  }

  @override
  String errorReadingFile(String error) {
    return 'Błąd odczytu pliku: $error';
  }

  @override
  String get syncChannelName => 'Synchronizacja w tle';

  @override
  String get syncChannelDescription =>
      'Pokazuje stan synchronizacji plików w tle.';

  @override
  String get storageStatsTitle => 'Statystyki pamięci';

  @override
  String get storageStatsUsedSpace => 'Wykorzystane miejsce';

  @override
  String get storageStatsTotalFiles => 'Wszystkich plików';

  @override
  String storageStatsNItems(int count) {
    return '$count elementów';
  }

  @override
  String userFallback(int userId) {
    return 'Użytkownik #$userId';
  }

  @override
  String get biometricUnlockReason =>
      'Odblokuj zapisane dane logowania dla Crowley\'s Cloud.';

  @override
  String get tokenLifetimeEveryOpen => 'Przy każdym otwarciu aplikacji';

  @override
  String get tokenLifetimeOneHour => 'Po 1 godzinie';

  @override
  String get tokenLifetime1Hour => 'Po 1 godzinie';

  @override
  String get tokenLifetimeOneDay => 'Po 1 dniu';

  @override
  String get tokenLifetime1Day => 'Po 1 dniu';

  @override
  String get tokenLifetimeOneWeek => 'Po 1 tygodniu';

  @override
  String get tokenLifetime1Week => 'Po 1 tygodniu';

  @override
  String get tokenLifetimeOneMonth => 'Po 1 miesiącu';

  @override
  String get tokenLifetime1Month => 'Po 1 miesiącu';

  @override
  String get tokenLifetimeThreeMonths => 'Po 3 miesiącach';

  @override
  String get tokenLifetime3Months => 'Po 3 miesiącach';

  @override
  String get tokenLifetimeNever => 'Nigdy na tym urządzeniu';

  @override
  String get cacheLimitUnlimited => 'Bez limitu';

  @override
  String get syncCategoryOtherFiles => 'Inne pliki';

  @override
  String get internalStorage => 'Pamięć wewnętrzna';

  @override
  String get localStorageRootName => 'Pamięć wewnętrzna';

  @override
  String syncNotificationSyncingWith(String serverName) {
    return 'Synchronizowanie z $serverName';
  }

  @override
  String syncNotificationPausedTitle(String serverName) {
    return 'Synchronizacja z $serverName wstrzymana';
  }

  @override
  String get syncNotificationUnreachableBody =>
      'Serwer jest nieosiągalny. Synchronizacja w tle wstrzymana do otwarcia aplikacji.';

  @override
  String get syncNotificationAuthRequiredBody =>
      'Wymagane uwierzytelnienie. Otwórz aplikację, aby się zalogować.';

  @override
  String syncNotificationFailedTitle(String serverName) {
    return 'Synchronizacja z $serverName nie powiodła się';
  }

  @override
  String get syncNotificationGenericErrorBody =>
      'Wystąpił błąd podczas synchronizacji.';

  @override
  String syncNotificationCompleteTitle(String serverName) {
    return 'Synchronizacja z $serverName ukończona';
  }

  @override
  String get syncNotificationCompleteBody => 'Synchronizacja ukończona.';

  @override
  String get syncStatusConnecting => 'Łączenie z serwerem...';

  @override
  String syncStatusConnectionLost(String serverName) {
    return 'Nie można połączyć się z $serverName. Utracono połączenie.';
  }

  @override
  String syncResultServerUnreachableWithServer(String serverName) {
    return 'Nie można połączyć się z $serverName. Utracono połączenie.';
  }

  @override
  String get syncStatusScanningFiles => 'Skanowanie plików na urządzeniu...';

  @override
  String get syncStatusNoFilesFound =>
      'Nie znaleziono plików do synchronizacji.';

  @override
  String get syncStatusNoFilesSelected =>
      'Nie wybrano plików do synchronizacji.';

  @override
  String syncStatusCalculatingChecksum(
    int current,
    int total,
    String filename,
  ) {
    return 'Obliczanie sumy kontrolnej ($current/$total): $filename';
  }

  @override
  String get syncStatusCheckingDuplicates =>
      'Sprawdzanie duplikatów na serwerze...';

  @override
  String syncStatusSyncingFile(int current, int total, String filename) {
    return 'Synchronizowanie ($current/$total): $filename';
  }

  @override
  String get syncStatusCompleting => 'Finalizowanie synchronizacji...';

  @override
  String get showingCachedFiles => 'Wyświetlanie plików z pamięci podręcznej.';

  @override
  String get showingCachedFilesRefreshFailed =>
      'Wyświetlanie plików z pamięci podręcznej. Odświeżanie nie powiodło się.';

  @override
  String get downloadCanceled => 'Pobieranie anulowane.';

  @override
  String downloadedNFilesToPath(int count, String path) {
    return 'Pobrano $count plików do $path';
  }

  @override
  String downloadedNFilesFailedM(int downloaded, int failed, String detail) {
    return 'Pobrano $downloaded plików, niepowodzenie: $failed: $detail';
  }

  @override
  String downloadedNFilesWithFailures(int count, int failed, String error) {
    return 'Pobrano $count plików, niepowodzenie: $failed: $error';
  }

  @override
  String createdNShareLinks(int count) {
    return 'Utworzono $count linków udostępniania.';
  }

  @override
  String get failedToCreateShareLinks =>
      'Nie udało się utworzyć linków udostępniania.';

  @override
  String get alreadyInSharedScope => 'Już w zakresie udostępnionych.';

  @override
  String sharedNItemsInServer(int count) {
    return 'Udostępniono $count elementów na serwerze.';
  }

  @override
  String sharedNItemsWithFailures(int count, int failed) {
    return 'Udostępniono $count elementów, niepowodzenie: $failed.';
  }

  @override
  String sharedNItemsFailedM(int shared, int failed) {
    return 'Udostępniono $shared elementów, niepowodzenie: $failed.';
  }

  @override
  String get folderNameCannotBeEmpty => 'Nazwa folderu nie może być pusta.';

  @override
  String get folderAlreadyExists => 'Folder już istnieje.';

  @override
  String get folderCreationOnlyInAllFiles =>
      'Tworzenie folderów jest dostępne tylko w sekcji Wszystkie pliki.';

  @override
  String get currentDirectoryUnavailable => 'Bieżący katalog jest niedostępny.';

  @override
  String get nothingSelected => 'Nic nie zaznaczono.';

  @override
  String get destinationFolderDoesNotExist => 'Folder docelowy nie istnieje.';

  @override
  String cannotMoveFolderIntoItself(String name) {
    return 'Nie można przenieść folderu \"$name\" do niego samego.';
  }

  @override
  String failedToMoveItem(String name, String error) {
    return 'Nie udało się przenieść $name: $error';
  }

  @override
  String movedNItems(int count) {
    return 'Przeniesiono $count elementów.';
  }

  @override
  String movedNItemsWithFailures(int count, int failed) {
    return 'Przeniesiono $count elementów, niepowodzenie: $failed.';
  }

  @override
  String movedNItemsFailedM(int moved, int failed) {
    return 'Przeniesiono $moved elementów, niepowodzenie: $failed.';
  }

  @override
  String get failedToMoveSelectedItems =>
      'Nie udało się przenieść zaznaczonych elementów.';

  @override
  String get noFilesWereMoved => 'Żadne pliki nie zostały przeniesione.';

  @override
  String renamedOldToNew(String oldName, String newName) {
    return 'Zmieniono nazwę \"$oldName\" na \"$newName\".';
  }

  @override
  String renamedFileFromTo(String oldName, String newName) {
    return 'Zmieniono nazwę \"$oldName\" na \"$newName\".';
  }

  @override
  String failedToRenameWithStatus(String name, int statusCode) {
    return 'Nie udało się zmienić nazwy \"$name\" ($statusCode).';
  }

  @override
  String failedToRenameFileWithCode(String name, int statusCode) {
    return 'Nie udało się zmienić nazwy \"$name\" ($statusCode).';
  }

  @override
  String failedToRenameWithError(String name, String error) {
    return 'Nie udało się zmienić nazwy \"$name\": $error';
  }

  @override
  String failedToRenameFile(String name, String error) {
    return 'Nie udało się zmienić nazwy \"$name\": $error';
  }

  @override
  String get renameConflictAlreadyExists =>
      'Nie udało się zmienić nazwy: plik lub folder o tej nazwie już istnieje.';

  @override
  String get renameFailedAlreadyExists =>
      'Nie udało się zmienić nazwy: plik lub folder o tej nazwie już istnieje.';

  @override
  String failedToCreateFolderWithCode(int statusCode) {
    return 'Nie udało się utworzyć folderu ($statusCode).';
  }

  @override
  String deletedNItemsFailedM(int deleted, int failed) {
    return 'Usunięto $deleted elementów, niepowodzenie: $failed.';
  }

  @override
  String transferSummaryFiles(int percent, int completed, int total) {
    return '$percent%  $completed/$total plików';
  }

  @override
  String transferSummaryProgress(int percent, int completed, int total) {
    return '$percent%  $completed/$total plików';
  }

  @override
  String get downloadFailedGeneric => 'Pobieranie nie powiodło się';

  @override
  String uploadedNItemsWithFailures(int uploaded, int failed) {
    return 'Przesłano $uploaded elementów, niepowodzenie: $failed';
  }

  @override
  String uploadedNItemsFailedM(int uploaded, int failed) {
    return 'Przesłano $uploaded elementów, niepowodzenie: $failed.';
  }

  @override
  String uploadSummaryFailedCount(int count) {
    return ', niepowodzenie: $count';
  }

  @override
  String uploadLocalPathEmpty(String name) {
    return '$name: lokalna ścieżka jest pusta';
  }

  @override
  String uploadErrorLocalPathEmpty(String name) {
    return '$name: lokalna ścieżka jest pusta';
  }

  @override
  String get directoryUploadFailed => 'Przesyłanie folderu nie powiodło się';

  @override
  String get uploadDirectoryFailed => 'Przesyłanie folderu nie powiodło się';

  @override
  String get localFileNotFound => 'Nie znaleziono pliku lokalnego';

  @override
  String get uploadErrorLocalFileNotFound => 'Nie znaleziono pliku lokalnego';

  @override
  String get noSessionToken => 'Brak aktywnego tokenu sesji';

  @override
  String get uploadErrorNoSessionToken => 'Brak aktywnego tokenu sesji';

  @override
  String get serverDisconnectedStatus => 'Rozłączono z serwerem';

  @override
  String get serverDisconnected => 'Rozłączono z serwerem';

  @override
  String get serverIsUnreachable => 'Serwer jest nieosiągalny.';

  @override
  String get serverUnreachable => 'Serwer jest nieosiągalny.';

  @override
  String get uploadErrorLocalDirectoryNotFound =>
      'Nie znaleziono folderu lokalnego';

  @override
  String get uploadErrorFailedToScanDirectory =>
      'Nie udało się przeskanować folderu';

  @override
  String uploadErrorFolderCreateHttp(int statusCode) {
    return 'Tworzenie folderu nie powiodło się (HTTP $statusCode)';
  }

  @override
  String get authErrorMissingAccessToken => 'Brak tokenu dostępu w odpowiedzi';

  @override
  String get authErrorMissingRefreshToken =>
      'Brak tokenu odświeżania w odpowiedzi';

  @override
  String get authErrorNoSavedCredentials => 'Brak zapisanych danych logowania';

  @override
  String get authErrorNoRefreshToken => 'Brak dostępnego tokenu odświeżania';

  @override
  String get authErrorNoActiveSession => 'Brak aktywnej sesji';

  @override
  String get authErrorNoSavedUsername => 'Brak zapisanej nazwy użytkownika';

  @override
  String get updateNoReleasesPublished =>
      'Nie opublikowano jeszcze żadnych wydań.';

  @override
  String get language => 'Język';
}
