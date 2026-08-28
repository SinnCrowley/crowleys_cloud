// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'Crowley\'s Cloud';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Скасувати';

  @override
  String get save => 'Зберегти';

  @override
  String get delete => 'Видалити';

  @override
  String get rename => 'Перейменувати';

  @override
  String get close => 'Закрити';

  @override
  String get retry => 'Повторити';

  @override
  String get loading => 'Завантаження...';

  @override
  String get confirm => 'Підтвердити';

  @override
  String get error => 'Помилка';

  @override
  String errorWithMessage(String message) {
    return 'Помилка: $message';
  }

  @override
  String get unknown => 'Невідомо';

  @override
  String get upload => 'Завантажити';

  @override
  String get download => 'Завантажити';

  @override
  String get share => 'Поділитися';

  @override
  String get copy => 'Копіювати';

  @override
  String get move => 'Перемістити';

  @override
  String get restore => 'Відновити';

  @override
  String get apply => 'Застосувати';

  @override
  String get create => 'Створити';

  @override
  String get clear => 'Очистити';

  @override
  String get add => 'Додати';

  @override
  String get remove => 'Видалити';

  @override
  String get edit => 'Редагувати';

  @override
  String get switchLabel => 'Перемкнути';

  @override
  String get search => 'Пошук';

  @override
  String get name => 'Назвою';

  @override
  String get date => 'Датою';

  @override
  String get size => 'Розміром';

  @override
  String get type => 'Типом';

  @override
  String get ascending => 'За зростанням';

  @override
  String get descending => 'За спаданням';

  @override
  String get allFiles => 'Усі';

  @override
  String get categoryImages => 'Зображення';

  @override
  String get categoryPhotos => 'Фотографії';

  @override
  String get categoryVideos => 'Відео';

  @override
  String get categoryAudio => 'Аудіо';

  @override
  String get categoryDocuments => 'Документи';

  @override
  String get categoryArchives => 'Архіви';

  @override
  String get categoryShared => 'Спільні';

  @override
  String get categoryOther => 'Інше';

  @override
  String get categoryOtherFiles => 'Інші файли';

  @override
  String get noFilesFound => 'Файлів не знайдено.';

  @override
  String get noFilesInFolder => 'У цій папці немає файлів.';

  @override
  String get thisActionCannotBeUndone => 'Цю дію неможливо скасувати.';

  @override
  String get passwordsDoNotMatch => 'Паролі не збігаються.';

  @override
  String get navLocalFiles => 'Локальні файли';

  @override
  String get navServerFiles => 'Файли сервера';

  @override
  String get navSettings => 'Налаштування';

  @override
  String get navTrash => 'Кошик';

  @override
  String get navLocal => 'Локальні';

  @override
  String get navServer => 'Сервер';

  @override
  String get addServer => 'Додати сервер';

  @override
  String get noServersConfigured => 'Сервери не налаштовано.';

  @override
  String get addAServerInSettings => 'Додайте сервер у налаштуваннях.';

  @override
  String get addFirstServerHint => 'Додайте перший сервер, щоб продовжити.';

  @override
  String get noServersConfiguredYet => 'Сервери ще не налаштовано.';

  @override
  String get crowleysCloudSetup => 'Налаштування Crowley\'s Cloud';

  @override
  String get connect => 'Підключити';

  @override
  String get connecting => 'Підключення...';

  @override
  String get connected => 'Підключено';

  @override
  String get disconnected => 'Відключено';

  @override
  String get switchServer => 'Змінити сервер';

  @override
  String get chooseOtherServer => 'Вибрати інший сервер';

  @override
  String get switchServerTitle => 'Змінити сервер?';

  @override
  String switchServerBody(String serverName) {
    return 'Змінити активний сервер на «$serverName»?';
  }

  @override
  String get chooseServer => 'Вибрати сервер';

  @override
  String get authenticationRequired => 'Потрібна автентифікація';

  @override
  String signInToAccess(String serverName) {
    return 'Увійдіть, щоб отримати доступ до файлів на $serverName';
  }

  @override
  String get signInWithPassword => 'Увійти за допомогою пароля';

  @override
  String get useBiometrics => 'Використати біометрію';

  @override
  String get openingSignIn => 'Відкриття входу...';

  @override
  String get serverConnectionFailed => 'Не вдалося підключитися до сервера';

  @override
  String get unableToConnectToServer =>
      'Не вдалося підключитися до активного сервера.';

  @override
  String unableToConnectTo(String serverName) {
    return 'Не вдалося підключитися до $serverName.';
  }

  @override
  String get searchHint => 'Пошук...';

  @override
  String get searchFilesHint => 'Пошук файлів...';

  @override
  String get searchServerFilesHint => 'Пошук файлів сервера...';

  @override
  String get searchTrashHint => 'Пошук у кошику...';

  @override
  String get storagePermissionRequired =>
      'Потрібен дозвіл на доступ до сховища';

  @override
  String get grantPermission => 'Надати дозвіл';

  @override
  String get permissionDeniedOpenSettings =>
      'Доступ заборонено. Надайте доступ до сховища в налаштуваннях.';

  @override
  String get manageStoragePermissionRequired =>
      'Для перегляду й вибору папок потрібен дозвіл на керування сховищем.';

  @override
  String get storagePermissionsRequired =>
      'Для синхронізації потрібні дозволи на доступ до сховища.';

  @override
  String updateAvailableTitle(String version) {
    return 'Доступне оновлення: v$version';
  }

  @override
  String get updateAvailableTapToSeeNew => 'Натисніть, щоб переглянути новинки';

  @override
  String get updateView => 'Переглянути';

  @override
  String get updateAvailableDialogTitle => 'Доступне оновлення';

  @override
  String updateVersionSubtitle(String version) {
    return 'Версія $version';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'Поточна: v$version';
  }

  @override
  String updateNewVersion(String version) {
    return 'Нова: v$version';
  }

  @override
  String get updateWhatsNew => 'Новинки:';

  @override
  String get updateGitHub => 'GitHub';

  @override
  String get updateNoReleaseNotes => 'Опис змін не надано.';

  @override
  String get updateLater => 'Пізніше';

  @override
  String get updateDownloadApk => 'Завантажити APK';

  @override
  String get updateInstall => 'Оновити';

  @override
  String get shareLinkTitle => 'Посилання для спільного доступу';

  @override
  String get shareViaLink => 'Поділитися посиланням';

  @override
  String get shareInServer => 'Поділитися на сервері';

  @override
  String get expiryDays => 'Термін дії (дні)';

  @override
  String get expiryNever => 'Ніколи';

  @override
  String get expiry1Day => '1 день';

  @override
  String get expiry7Days => '7 днів';

  @override
  String get expiry30Days => '30 днів';

  @override
  String get expiry90Days => '90 днів';

  @override
  String get expiry180Days => '180 днів';

  @override
  String get expiry365Days => '365 днів';

  @override
  String get createLink => 'Створити посилання';

  @override
  String get sharedLinkCopied =>
      'Посилання для спільного доступу скопійовано в буфер обміну!';

  @override
  String failedToCopySharedLink(String error) {
    return 'Не вдалося скопіювати посилання: $error';
  }

  @override
  String get cannotShareThisFileType =>
      'Не можна поділитися файлами цього типу.';

  @override
  String failedToCreateShare(String error) {
    return 'Не вдалося створити спільний доступ: $error';
  }

  @override
  String get newFolderTitle => 'Створити папку';

  @override
  String get newFolderHint => 'Назва папки';

  @override
  String get newFolder => 'Нова папка';

  @override
  String get folderCreated => 'Папку створено.';

  @override
  String failedToCreateFolder(String error) {
    return 'Не вдалося створити папку: $error';
  }

  @override
  String get creatingFolder => 'Створення папки...';

  @override
  String get renameDialogTitle => 'Перейменувати';

  @override
  String get renameHint => 'Нова назва';

  @override
  String get enterNewName => 'Введіть нову назву';

  @override
  String get renamedSuccessfully => 'Успішно перейменовано.';

  @override
  String renameFailed(String error) {
    return 'Не вдалося перейменувати: $error';
  }

  @override
  String get moveDialogTitle => 'Перемістити до';

  @override
  String moveTo(String path) {
    return 'Перемістити до: $path';
  }

  @override
  String get moveHere => 'Перемістити сюди';

  @override
  String moveFailed(String error) {
    return 'Не вдалося перемістити: $error';
  }

  @override
  String get movedToFolder => 'Переміщено до папки.';

  @override
  String copyFailed(String error) {
    return 'Не вдалося скопіювати: $error';
  }

  @override
  String get selectFolder => 'Вибрати папку';

  @override
  String get useThisFolder => 'Використати цю папку';

  @override
  String get storageRoot => 'Сховище';

  @override
  String get serverRoot => 'коренева папка';

  @override
  String deleteNItemsTitle(int count) {
    return 'Видалити $count елементів?';
  }

  @override
  String get deleteFilesTitle => 'Видалити файли?';

  @override
  String deleteFilesBody(int count) {
    return 'Ви впевнені, що хочете видалити вибрані елементи ($count)? Цю дію неможливо скасувати.';
  }

  @override
  String get deletePermanently => 'Видалити назавжди';

  @override
  String get deletePermanentlyTitle => 'Видалити назавжди?';

  @override
  String deletePermanentlyBody(String filename) {
    return '$filename буде видалено назавжди.';
  }

  @override
  String get deleteFileTitle => 'Видалити файл?';

  @override
  String deleteFileBody(String filename) {
    return 'Ви впевнені, що хочете видалити $filename? Цю дію неможливо скасувати.';
  }

  @override
  String get deleteServerFileTitle => 'Видалити назавжди';

  @override
  String deleteServerFileBody(String filename) {
    return 'Ви впевнені, що хочете назавжди видалити «$filename»? Цю дію неможливо скасувати.';
  }

  @override
  String get unshareItemsTitle => 'Скасувати спільний доступ до елементів?';

  @override
  String unshareItemsBody(int count) {
    return 'Ви впевнені, що хочете скасувати спільний доступ до вибраних елементів ($count)? Їх буде видалено з папки «Спільні». ';
  }

  @override
  String get unshare => 'Скасувати спільний доступ';

  @override
  String get moveToTrash => 'Перемістити до кошика';

  @override
  String get movedToTrash => 'Переміщено до кошика.';

  @override
  String movedNItemsToTrash(int count) {
    return '$count елементів переміщено до кошика.';
  }

  @override
  String failedToMoveToTrash(String error) {
    return 'Не вдалося перемістити до кошика: $error';
  }

  @override
  String deletedNItems(int count) {
    return 'Видалено елементів: $count.';
  }

  @override
  String failedToDelete(String error) {
    return 'Не вдалося видалити: $error';
  }

  @override
  String failedToDeleteItem(String error) {
    return 'Не вдалося видалити: $error';
  }

  @override
  String deletedFilename(String filename) {
    return 'Видалено $filename.';
  }

  @override
  String get failedToOpenFile => 'Не вдалося відкрити файл';

  @override
  String fileDownloadFailed(String error) {
    return 'Не вдалося завантажити файл: $error';
  }

  @override
  String get downloading => 'Завантаження...';

  @override
  String get downloadingFile => 'Завантаження файлу...';

  @override
  String downloadComplete(String filename) {
    return 'Завантаження завершено: $filename';
  }

  @override
  String downloadFailed(String error) {
    return 'Не вдалося завантажити: $error';
  }

  @override
  String get failedToDownloadPreview =>
      'Не вдалося завантажити попередній перегляд файлу';

  @override
  String uploadComplete(String filename) {
    return 'Завантаження завершено: $filename';
  }

  @override
  String uploadFailed(String error) {
    return 'Не вдалося завантажити: $error';
  }

  @override
  String get failedToPickFiles => 'Не вдалося вибрати файли';

  @override
  String uploadedNItems(int count) {
    return 'Завантажено елементів: $count';
  }

  @override
  String get copiedLinkToClipboard => 'Посилання скопійовано в буфер обміну.';

  @override
  String failedToCopyLink(String error) {
    return 'Не вдалося скопіювати посилання: $error';
  }

  @override
  String get selectingAll => 'Вибір усіх елементів...';

  @override
  String get allItemsSelected => 'Усі елементи вибрано.';

  @override
  String get failedToLoadSearchResults =>
      'Не вдалося завантажити результати пошуку';

  @override
  String get shareNotSupportedForType =>
      'Спільний доступ для цього типу файлів не підтримується.';

  @override
  String nSelected(int count) {
    return 'Вибрано: $count';
  }

  @override
  String get noServerSelected => 'Сервер не вибрано';

  @override
  String get pleaseConnectToServerFirst => 'Спочатку підключіться до сервера.';

  @override
  String get signInRequired => 'Потрібно увійти';

  @override
  String pleaseSignInToServer(String serverName) {
    return 'Спочатку увійдіть до $serverName.';
  }

  @override
  String get connectingToServer => 'Підключення до сервера...';

  @override
  String connectedToServer(String serverName) {
    return 'Підключено до $serverName.';
  }

  @override
  String connectionFailed(String error) {
    return 'Не вдалося підключитися: $error';
  }

  @override
  String failedToConnect(String error) {
    return 'Не вдалося підключитися: $error';
  }

  @override
  String authFailed(String error) {
    return 'Помилка автентифікації: $error';
  }

  @override
  String get authFailedGeneric => 'Помилка автентифікації. Спробуйте ще раз.';

  @override
  String biometricLoginFailed(String error) {
    return 'Помилка біометричного входу: $error';
  }

  @override
  String get biometricLoginFailedGeneric => 'Помилка біометричного входу.';

  @override
  String get noServerSessionToken =>
      'Немає токена сеансу сервера. Повторно автентифікуйте сервер.';

  @override
  String failedToSaveServer(String error) {
    return 'Не вдалося зберегти сервер: $error';
  }

  @override
  String get addToFolder => 'Додати до папки';

  @override
  String get loginTabLabel => 'Увійти';

  @override
  String get registerTabLabel => 'Зареєструватися';

  @override
  String get welcomeBack => 'З поверненням';

  @override
  String get signInToContinue => 'Увійдіть, щоб продовжити';

  @override
  String get createAccount => 'Створити обліковий запис';

  @override
  String get joinTheServer => 'Приєднатися до сервера';

  @override
  String get usernameLabel => 'Ім’я користувача';

  @override
  String get usernameHint => 'Введіть ім’я користувача';

  @override
  String get passwordLabel => 'Пароль';

  @override
  String get passwordHint => 'Введіть пароль';

  @override
  String get showPassword => 'Показати пароль';

  @override
  String get hidePassword => 'Приховати пароль';

  @override
  String get confirmPassword => 'Підтвердити пароль';

  @override
  String get logIn => 'Увійти';

  @override
  String get loggingIn => 'Вхід...';

  @override
  String get registering => 'Реєстрація...';

  @override
  String get forgotPassword => 'Забули пароль?';

  @override
  String get doNotHaveAccount =>
      'Немає облікового запису? Перейдіть до реєстрації.';

  @override
  String get alreadyHaveAccount =>
      'Вже маєте обліковий запис? Перейдіть до входу.';

  @override
  String get usernameCannotBeEmpty => 'Ім’я користувача не може бути порожнім.';

  @override
  String get passwordCannotBeEmpty => 'Пароль не може бути порожнім.';

  @override
  String get usernameInvalid =>
      'Ім’я користувача має містити 3–32 символи: літери, цифри, _ або -.';

  @override
  String get passwordTooShort => 'Пароль має містити щонайменше 8 символів.';

  @override
  String loginFailed(String error) {
    return 'Не вдалося увійти: $error';
  }

  @override
  String registrationFailed(String error) {
    return 'Не вдалося зареєструватися: $error';
  }

  @override
  String get resetPasswordTitle => 'Скинути пароль';

  @override
  String get enterResetCodeTitle => 'Введіть код скидання';

  @override
  String get resetPasswordStep1Body =>
      'Введіть ім’я користувача. 6-значний код підтвердження буде надруковано в журналах або консолі сервера.';

  @override
  String get resetPasswordStep2Body =>
      'Код підтвердження надруковано в консолі сервера. Введіть 6-значний код і новий пароль.';

  @override
  String get resetCodeLabel => 'Код скидання';

  @override
  String get resetCodeHint => 'Введіть 6-значний код';

  @override
  String get newPasswordLabel => 'Новий пароль';

  @override
  String get newPasswordHint => 'Введіть новий пароль';

  @override
  String get passwordResetSuccessfully => 'Пароль успішно скинуто!';

  @override
  String get usernameIsRequired => 'Потрібно вказати ім’я користувача.';

  @override
  String get codeAndPasswordRequired => 'Потрібні код і новий пароль.';

  @override
  String get failedToRequestReset =>
      'Не вдалося надіслати запит на скидання. Перевірте URL сервера.';

  @override
  String get failedToResetPassword =>
      'Не вдалося скинути пароль. Перевірте код.';

  @override
  String get pleaseEnterServerUrlFirst => 'Спочатку введіть URL сервера.';

  @override
  String get sendCode => 'Надіслати код';

  @override
  String get settingsTitle => 'Налаштування';

  @override
  String get sectionBackupSync => 'Резервне копіювання та синхронізація';

  @override
  String get sectionStorageCache => 'Сховище та кеш';

  @override
  String get sectionSecurityBehavior => 'Безпека та поведінка';

  @override
  String get sectionAboutUpdates => 'Про програму та оновлення';

  @override
  String get sectionAppearance => 'Вигляд і налаштування';

  @override
  String get noServersConfiguredSync => 'Сервери не налаштовано';

  @override
  String get addServerBeforeSync =>
      'Додайте сервер перед налаштуванням синхронізації.';

  @override
  String get selectServerToConfigureSync =>
      'Виберіть сервер, щоб налаштувати його синхронізацію.';

  @override
  String get activeServerSuffix => '· активний';

  @override
  String get folderAndCategorySync => 'Синхронізація папок і категорій';

  @override
  String get keepCategoriesSynced =>
      'Підтримувати вибрані локальні категорії або папки синхронізованими з цим сервером.';

  @override
  String get addServerBeforeSyncEnable =>
      'Додайте сервер перед увімкненням синхронізації.';

  @override
  String get onlyOnWifi => 'Лише через Wi-Fi';

  @override
  String get onlyWhileCharging => 'Лише під час заряджання';

  @override
  String get serverTargetDirectory => 'Цільова папка сервера';

  @override
  String get serverTargetDirectoryHint => '/backup/mobile_phone';

  @override
  String get synchronizationFrequency => 'Частота синхронізації';

  @override
  String get syncNow => 'Синхронізувати зараз';

  @override
  String get syncing => 'Синхронізація...';

  @override
  String get categoriesToSynchronize => 'Категорії для синхронізації';

  @override
  String get noCategoriesSelected => 'Категорії не вибрано.';

  @override
  String nCategoriesSelected(int count) {
    return 'Вибрано: $count';
  }

  @override
  String get foldersToSynchronize => 'Папки для синхронізації';

  @override
  String get noCustomFolders => 'Спеціальні папки не налаштовано.';

  @override
  String nFolders(int count) {
    return 'Папок: $count';
  }

  @override
  String get addFolder => 'Додати папку';

  @override
  String get removeFolder => 'Видалити папку';

  @override
  String get removeServer => 'Видалити сервер';

  @override
  String get syncFreqEvery15Min => 'Кожні 15 хвилин';

  @override
  String get syncFreqEvery30Min => 'Кожні 30 хвилин';

  @override
  String get syncFreqEvery1Hour => 'Щогодини';

  @override
  String syncFreqEveryNHours(int hours) {
    return 'Кожні $hours год.';
  }

  @override
  String syncFreqEveryNMin(int minutes) {
    return 'Кожні $minutes хв.';
  }

  @override
  String get syncFreqDaily => 'Щодня';

  @override
  String get chooseSyncFrequencyTitle => 'Виберіть частоту синхронізації';

  @override
  String get cacheSize => 'Розмір кешу';

  @override
  String get refreshTooltip => 'Оновити';

  @override
  String get cacheLimit => 'Обмеження кешу';

  @override
  String get downloadPath => 'Шлях завантаження';

  @override
  String get defaultDownloadFolder => 'Папка CrowleysCloud за замовчуванням';

  @override
  String get clearCache => 'Очистити кеш';

  @override
  String get clearCacheTitle => 'Очистити кеш?';

  @override
  String get clearCacheBody =>
      'Це видалить локальні мініатюри та кешовані списки серверів.';

  @override
  String get downloadPathDialogTitle => 'Шлях завантаження';

  @override
  String get downloadPathHint => '/storage/emulated/0/CrowleysCloud';

  @override
  String get useDefault => 'Використати типовий';

  @override
  String get serverTargetDirDialogTitle => 'Цільова папка сервера';

  @override
  String get requireLogin => 'Вимагати вхід';

  @override
  String get biometricLogin => 'Біометричний вхід';

  @override
  String get biometricLoginSubtitle =>
      'Дозволити вхід із збереженими обліковими даними за допомогою біометрії.';

  @override
  String get biometricsNotAvailable =>
      'Біометрія недоступна на цьому пристрої.';

  @override
  String get showHiddenFiles => 'Показувати приховані файли';

  @override
  String get showHiddenFilesSubtitle =>
      'Показувати файли й папки, назви яких починаються з крапки.';

  @override
  String get changePassword => 'Змінити пароль';

  @override
  String changePasswordSubtitle(String serverName) {
    return 'Оновити пароль для $serverName.';
  }

  @override
  String get addServerBeforeChangePassword =>
      'Додайте сервер перед зміною пароля.';

  @override
  String get deleteUserAccount => 'Видалити обліковий запис';

  @override
  String get deleteUserAccountSubtitle =>
      'Видаляє користувача та всі файли приватної хмари.';

  @override
  String get deleteAccountTitle => 'Видалити обліковий запис?';

  @override
  String deleteAccountBody(String serverName) {
    return 'Обліковий запис на $serverName буде видалено назавжди разом із файлами з приватної хмарної папки. Цю дію неможливо скасувати.';
  }

  @override
  String get deleteAccountButton => 'Видалити обліковий запис';

  @override
  String get changePasswordDialogTitle => 'Змінити пароль';

  @override
  String get newPasswordFieldLabel => 'Новий пароль';

  @override
  String get confirmPasswordLabel => 'Підтвердьте пароль';

  @override
  String get enterNewPassword => 'Введіть новий пароль.';

  @override
  String get passwordUpdated => 'Пароль оновлено.';

  @override
  String passwordChangeFailed(String error) {
    return 'Не вдалося змінити пароль: $error';
  }

  @override
  String get passwordChangeFailedGeneric => 'Не вдалося змінити пароль.';

  @override
  String get accountDeleted => 'Обліковий запис видалено.';

  @override
  String accountDeletionFailed(String error) {
    return 'Не вдалося видалити обліковий запис: $error';
  }

  @override
  String get accountDeletionFailedGeneric =>
      'Не вдалося видалити обліковий запис.';

  @override
  String get checkForUpdates => 'Перевірити оновлення';

  @override
  String get checkingForUpdates => 'Перевірка випусків GitHub...';

  @override
  String versionLabel(String version) {
    return 'Версія $version';
  }

  @override
  String appIsUpToDate(String version) {
    return 'Crowley\'s Cloud оновлено до останньої версії (v$version).';
  }

  @override
  String get updateCheckFailed =>
      'Не вдалося перевірити оновлення. Спробуйте пізніше.';

  @override
  String get themeModeTitle => 'Режим теми';

  @override
  String get themeDark => 'Темна';

  @override
  String get themeLight => 'Світла';

  @override
  String get themeCustom => 'Власна';

  @override
  String get themeDarkFull => 'Темна тема';

  @override
  String get themeLightFull => 'Світла тема';

  @override
  String get themeCustomFull => 'Власна тема';

  @override
  String get accentColor => 'Колір акценту';

  @override
  String get primaryAccentColor => 'Основний колір акценту';

  @override
  String get selectAccentColor => 'Виберіть колір акценту';

  @override
  String get backgroundColor => 'Колір тла';

  @override
  String get surfaceColor => 'Колір поверхні';

  @override
  String get textColor => 'Колір тексту';

  @override
  String get subtextColor => 'Колір додаткового тексту';

  @override
  String get borderColor => 'Колір межі';

  @override
  String get fontSizeScale => 'Масштаб шрифту';

  @override
  String selectColor(String title) {
    return 'Виберіть $title';
  }

  @override
  String get categoriesToSyncDialogTitle => 'Категорії для синхронізації';

  @override
  String get categoriesToSyncBody =>
      'Виберіть одну або кілька категорій. Можна залишити все невибраним.';

  @override
  String get syncCategorySectionMedia => 'Медіа';

  @override
  String get syncCategorySectionAudioDocs => 'Аудіо та документи';

  @override
  String get syncCategorySectionOther => 'Інше';

  @override
  String get clearAll => 'Очистити все';

  @override
  String get noSyncHasRunYet => 'Синхронізація ще не запускалася.';

  @override
  String lastRunAt(String date) {
    return 'Останній запуск: $date';
  }

  @override
  String syncResultSuccess(int uploaded, int skipped) {
    return 'Синхронізовано: $uploaded, пропущено: $skipped.';
  }

  @override
  String get syncResultNoFiles => 'Файли для синхронізації не вибрано.';

  @override
  String syncResultPartial(int uploaded, int failed) {
    return 'Синхронізовано: $uploaded, помилок: $failed.';
  }

  @override
  String get syncResultAuthRequired => 'Увійдіть перед синхронізацією.';

  @override
  String get syncResultUnreachable => 'Сервер недоступний. З’єднання втрачено.';

  @override
  String get syncResultFailed => 'Синхронізація не вдалася.';

  @override
  String get serverSetupAddServer => 'Додати сервер';

  @override
  String get serverSetupCardTitle => 'Підключити сервер';

  @override
  String get serverSetupCardSubtitle =>
      'Додайте домашній файловий сервер і увійдіть.';

  @override
  String get serverSetupSubmitButton => 'Зберегти сервер';

  @override
  String get serverNameLabel => 'Назва сервера';

  @override
  String get serverNameHint => 'Home NAS';

  @override
  String get baseUrlLabel => 'Базова URL-адреса';

  @override
  String get baseUrlHint => 'https://cloud.example.com';

  @override
  String get allFieldsRequired => 'Усі поля обов’язкові.';

  @override
  String get localFilesTitle => 'Локальні файли';

  @override
  String get serverFilesTitle => 'Файли сервера';

  @override
  String get restoreItemsTitle => 'Відновити елементи';

  @override
  String restoreItemsBody(int count) {
    return 'Ви впевнені, що хочете відновити елементи ($count)?';
  }

  @override
  String get permanentlyDeleteTitle => 'Видалити назавжди';

  @override
  String permanentlyDeleteBody(int count) {
    return 'Ви впевнені, що хочете назавжди видалити елементи ($count)? Цю дію неможливо скасувати.';
  }

  @override
  String get trashIsEmpty => 'Кошик порожній.';

  @override
  String trashRetentionInfo(int days) {
    return 'Елементи в кошику автоматично видаляються через $days днів.';
  }

  @override
  String get deletionDate => 'Дата видалення';

  @override
  String get deletePermanentlyAction => 'Видалити назавжди';

  @override
  String get conflictFileAlreadyExists => 'Файл уже існує';

  @override
  String conflictNofM(int current, int total) {
    return 'Конфлікт $current із $total';
  }

  @override
  String get conflictAFileNamed => 'Файл із назвою ';

  @override
  String get conflictAlreadyExistsAt => ' уже існує за адресою ';

  @override
  String get conflictAlreadyExistsInFolder => ' уже існує в цій папці.';

  @override
  String get conflictInFolder => 'У папці';

  @override
  String get conflictFromTrash => 'Із кошика';

  @override
  String get conflictExisting => 'Наявний';

  @override
  String get conflictNewUpload => 'Нове завантаження';

  @override
  String conflictSizeLabel(String size) {
    return 'Розмір: $size';
  }

  @override
  String conflictDateLabel(String date) {
    return 'Дата: $date';
  }

  @override
  String conflictDeletedLabel(String date) {
    return 'Видалено: $date';
  }

  @override
  String conflictApplyToRemaining(int count) {
    return 'Застосувати до решти конфліктів ($count)';
  }

  @override
  String get conflictKeepAllCopies => 'Зберегти всі копії';

  @override
  String get conflictOverwriteAll => 'Перезаписати все';

  @override
  String get conflictRestoreAllAsCopies => 'Відновити все як копії';

  @override
  String get conflictRestoreAsCopy => 'Відновити як копію';

  @override
  String get conflictOverwriteAllRemaining => 'Перезаписати решту';

  @override
  String get conflictSkipAll => 'Пропустити все';

  @override
  String get conflictSkipAllRemaining => 'Пропустити решту';

  @override
  String get conflictSkip => 'Пропустити';

  @override
  String get conflictOverwrite => 'Перезаписати';

  @override
  String get transfersTitle => 'Передачі';

  @override
  String get transferResume => 'Продовжити';

  @override
  String get transferPause => 'Призупинити';

  @override
  String get transferCancel => 'Скасувати';

  @override
  String get transferResumeAll => 'Продовжити все';

  @override
  String get transferPauseAll => 'Призупинити все';

  @override
  String get transferCancelAll => 'Скасувати все';

  @override
  String get transferCancelFile => 'Скасувати файл';

  @override
  String get noTransfers => 'Немає передач.';

  @override
  String get transferStatusQueued => 'У черзі';

  @override
  String get transferStatusRunning => 'Виконується';

  @override
  String get transferStatusPaused => 'Призупинено';

  @override
  String get transferStatusCompleted => 'Завершено';

  @override
  String get transferStatusFailed => 'Помилка';

  @override
  String get transferStatusCanceled => 'Скасовано';

  @override
  String get themePresetsSection => 'Попередні налаштування';

  @override
  String get themeCustomPaletteSection => 'Власна палітра';

  @override
  String get themeHexRgbLabel => 'Код HEX RGB';

  @override
  String get themeHexRgbHint => '#FA5252';

  @override
  String get imageViewerNoFetchHandler => 'Обробник отримання не налаштовано';

  @override
  String get imageViewerFailedToLoad => 'Не вдалося завантажити зображення';

  @override
  String errorDeletingFile(String filename, String error) {
    return 'Помилка видалення $filename: $error';
  }

  @override
  String errorReadingFile(String error) {
    return 'Помилка читання файлу: $error';
  }

  @override
  String get syncChannelName => 'Фонова синхронізація';

  @override
  String get syncChannelDescription =>
      'Показує стан фонової синхронізації файлів.';

  @override
  String get storageStatsTitle => 'Статистика сховища';

  @override
  String get storageStatsUsedSpace => 'Використаний простір';

  @override
  String get storageStatsTotalFiles => 'Усього файлів';

  @override
  String storageStatsNItems(int count) {
    return '$count елементів';
  }

  @override
  String userFallback(int userId) {
    return 'Користувач #$userId';
  }

  @override
  String get biometricUnlockReason =>
      'Розблокувати збережені облікові дані Crowley\'s Cloud.';

  @override
  String get tokenLifetimeEveryOpen => 'Під час кожного відкриття програми';

  @override
  String get tokenLifetimeOneHour => 'Через 1 годину';

  @override
  String get tokenLifetime1Hour => 'Через 1 годину';

  @override
  String get tokenLifetimeOneDay => 'Через 1 день';

  @override
  String get tokenLifetime1Day => 'Через 1 день';

  @override
  String get tokenLifetimeOneWeek => 'Через 1 тиждень';

  @override
  String get tokenLifetime1Week => 'Через 1 тиждень';

  @override
  String get tokenLifetimeOneMonth => 'Через 1 місяць';

  @override
  String get tokenLifetime1Month => 'Через 1 місяць';

  @override
  String get tokenLifetimeThreeMonths => 'Через 3 місяці';

  @override
  String get tokenLifetime3Months => 'Через 3 місяці';

  @override
  String get tokenLifetimeNever => 'Ніколи на цьому пристрої';

  @override
  String get cacheLimitUnlimited => 'Без обмежень';

  @override
  String get syncCategoryOtherFiles => 'Інші файли';

  @override
  String get internalStorage => 'Внутрішнє сховище';

  @override
  String get localStorageRootName => 'Внутрішнє сховище';

  @override
  String syncNotificationSyncingWith(String serverName) {
    return 'Синхронізація з $serverName';
  }

  @override
  String syncNotificationPausedTitle(String serverName) {
    return 'Синхронізацію з $serverName призупинено';
  }

  @override
  String get syncNotificationUnreachableBody =>
      'Сервер недоступний. Фонову синхронізацію призупинено до відкриття програми.';

  @override
  String get syncNotificationAuthRequiredBody =>
      'Потрібна автентифікація. Відкрийте програму, щоб увійти.';

  @override
  String syncNotificationFailedTitle(String serverName) {
    return 'Синхронізація з $serverName не вдалася';
  }

  @override
  String get syncNotificationGenericErrorBody =>
      'Під час синхронізації сталася помилка.';

  @override
  String syncNotificationCompleteTitle(String serverName) {
    return 'Синхронізацію з $serverName завершено';
  }

  @override
  String get syncNotificationCompleteBody => 'Синхронізацію завершено.';

  @override
  String get syncStatusConnecting => 'Підключення до сервера...';

  @override
  String syncStatusConnectionLost(String serverName) {
    return 'Не вдалося підключитися до $serverName. З’єднання втрачено.';
  }

  @override
  String syncResultServerUnreachableWithServer(String serverName) {
    return 'Не вдалося підключитися до $serverName. З’єднання втрачено.';
  }

  @override
  String get syncStatusScanningFiles => 'Сканування файлів на пристрої...';

  @override
  String get syncStatusNoFilesFound => 'Файлів для синхронізації не знайдено.';

  @override
  String get syncStatusNoFilesSelected => 'Файли для синхронізації не вибрано.';

  @override
  String syncStatusCalculatingChecksum(
    int current,
    int total,
    String filename,
  ) {
    return 'Обчислення контрольної суми ($current/$total): $filename';
  }

  @override
  String get syncStatusCheckingDuplicates => 'Пошук дублікатів на сервері...';

  @override
  String syncStatusSyncingFile(int current, int total, String filename) {
    return 'Синхронізація ($current/$total): $filename';
  }

  @override
  String get syncStatusCompleting => 'Завершення синхронізації...';

  @override
  String get showingCachedFiles => 'Показ кешованих файлів.';

  @override
  String get showingCachedFilesRefreshFailed =>
      'Показ кешованих файлів. Не вдалося оновити.';

  @override
  String get downloadCanceled => 'Завантаження скасовано.';

  @override
  String downloadedNFilesToPath(int count, String path) {
    return 'Завантажено файлів: $count, шлях: $path';
  }

  @override
  String downloadedNFilesFailedM(int downloaded, int failed, String detail) {
    return 'Завантажено: $downloaded, помилок: $failed: $detail';
  }

  @override
  String downloadedNFilesWithFailures(int count, int failed, String error) {
    return 'Завантажено: $count, помилок: $failed: $error';
  }

  @override
  String createdNShareLinks(int count) {
    return 'Створено посилань спільного доступу: $count.';
  }

  @override
  String get failedToCreateShareLinks =>
      'Не вдалося створити посилання спільного доступу.';

  @override
  String get alreadyInSharedScope => 'Уже має спільний доступ.';

  @override
  String sharedNItemsInServer(int count) {
    return 'На сервері надано спільний доступ до елементів: $count.';
  }

  @override
  String sharedNItemsWithFailures(int count, int failed) {
    return 'Надано спільний доступ до $count елементів, помилок: $failed.';
  }

  @override
  String sharedNItemsFailedM(int shared, int failed) {
    return 'Надано спільний доступ до $shared елементів, помилок: $failed.';
  }

  @override
  String get folderNameCannotBeEmpty => 'Назва папки не може бути порожньою.';

  @override
  String get folderAlreadyExists => 'Папка вже існує.';

  @override
  String get folderCreationOnlyInAllFiles =>
      'Створення папок доступне лише в розділі «Усі файли».';

  @override
  String get currentDirectoryUnavailable => 'Поточний каталог недоступний.';

  @override
  String get nothingSelected => 'Нічого не вибрано.';

  @override
  String get destinationFolderDoesNotExist => 'Папка призначення не існує.';

  @override
  String cannotMoveFolderIntoItself(String name) {
    return 'Неможливо перемістити папку «$name» у саму себе.';
  }

  @override
  String failedToMoveItem(String name, String error) {
    return 'Не вдалося перемістити $name: $error';
  }

  @override
  String movedNItems(int count) {
    return 'Переміщено елементів: $count.';
  }

  @override
  String movedNItemsWithFailures(int count, int failed) {
    return 'Переміщено: $count, помилок: $failed.';
  }

  @override
  String movedNItemsFailedM(int moved, int failed) {
    return 'Переміщено: $moved, помилок: $failed.';
  }

  @override
  String get failedToMoveSelectedItems =>
      'Не вдалося перемістити вибрані елементи.';

  @override
  String get noFilesWereMoved => 'Файли не переміщено.';

  @override
  String renamedOldToNew(String oldName, String newName) {
    return '«$oldName» перейменовано на «$newName».';
  }

  @override
  String renamedFileFromTo(String oldName, String newName) {
    return '«$oldName» перейменовано на «$newName».';
  }

  @override
  String failedToRenameWithStatus(String name, int statusCode) {
    return 'Не вдалося перейменувати «$name» ($statusCode).';
  }

  @override
  String failedToRenameFileWithCode(String name, int statusCode) {
    return 'Не вдалося перейменувати «$name» ($statusCode).';
  }

  @override
  String failedToRenameWithError(String name, String error) {
    return 'Не вдалося перейменувати «$name»: $error';
  }

  @override
  String failedToRenameFile(String name, String error) {
    return 'Не вдалося перейменувати «$name»: $error';
  }

  @override
  String get renameConflictAlreadyExists =>
      'Не вдалося перейменувати: файл або папка з такою назвою вже існує.';

  @override
  String get renameFailedAlreadyExists =>
      'Не вдалося перейменувати: файл або папка з такою назвою вже існує.';

  @override
  String failedToCreateFolderWithCode(int statusCode) {
    return 'Не вдалося створити папку ($statusCode).';
  }

  @override
  String deletedNItemsFailedM(int deleted, int failed) {
    return 'Видалено: $deleted, помилок: $failed.';
  }

  @override
  String transferSummaryFiles(int percent, int completed, int total) {
    return '$percent%  $completed/$total файлів';
  }

  @override
  String transferSummaryProgress(int percent, int completed, int total) {
    return '$percent%  $completed/$total файлів';
  }

  @override
  String get downloadFailedGeneric => 'Не вдалося завантажити';

  @override
  String uploadedNItemsWithFailures(int uploaded, int failed) {
    return 'Завантажено: $uploaded, помилок: $failed';
  }

  @override
  String uploadedNItemsFailedM(int uploaded, int failed) {
    return 'Завантажено: $uploaded, помилок: $failed.';
  }

  @override
  String uploadSummaryFailedCount(int count) {
    return ', помилок: $count';
  }

  @override
  String uploadLocalPathEmpty(String name) {
    return '$name: локальний шлях порожній';
  }

  @override
  String uploadErrorLocalPathEmpty(String name) {
    return '$name: локальний шлях порожній';
  }

  @override
  String get directoryUploadFailed => 'Не вдалося завантажити каталог';

  @override
  String get uploadDirectoryFailed => 'Не вдалося завантажити каталог';

  @override
  String get localFileNotFound => 'Локальний файл не знайдено';

  @override
  String get uploadErrorLocalFileNotFound => 'Локальний файл не знайдено';

  @override
  String get noSessionToken => 'Немає активного токена сесії';

  @override
  String get uploadErrorNoSessionToken => 'Немає активного токена сесії';

  @override
  String get serverDisconnectedStatus => 'Сервер від’єднано';

  @override
  String get serverDisconnected => 'Сервер від’єднано';

  @override
  String get serverIsUnreachable => 'Сервер недоступний.';

  @override
  String get serverUnreachable => 'Сервер недоступний.';

  @override
  String get uploadErrorLocalDirectoryNotFound =>
      'Локальний каталог не знайдено';

  @override
  String get uploadErrorFailedToScanDirectory =>
      'Не вдалося просканувати каталог';

  @override
  String uploadErrorFolderCreateHttp(int statusCode) {
    return 'Не вдалося створити папку (HTTP $statusCode)';
  }

  @override
  String get authErrorMissingAccessToken => 'У відповіді немає токена доступу';

  @override
  String get authErrorMissingRefreshToken =>
      'У відповіді немає токена оновлення';

  @override
  String get authErrorNoSavedCredentials => 'Збережені облікові дані відсутні';

  @override
  String get authErrorNoRefreshToken => 'Токен оновлення відсутній';

  @override
  String get authErrorNoActiveSession => 'Активна сесія відсутня';

  @override
  String get authErrorNoSavedUsername => 'Збережене ім’я користувача відсутнє';

  @override
  String get updateNoReleasesPublished => 'Випусків ще не опубліковано.';

  @override
  String get language => 'Мова';
}
