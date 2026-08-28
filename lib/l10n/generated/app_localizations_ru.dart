// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Crowley\'s Cloud';

  @override
  String get ok => 'ОК';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get rename => 'Переименовать';

  @override
  String get close => 'Закрыть';

  @override
  String get retry => 'Повторить';

  @override
  String get loading => 'Загрузка...';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get error => 'Ошибка';

  @override
  String errorWithMessage(String message) {
    return 'Ошибка: $message';
  }

  @override
  String get unknown => 'Неизвестно';

  @override
  String get upload => 'Загрузить';

  @override
  String get download => 'Скачать';

  @override
  String get share => 'Поделиться';

  @override
  String get copy => 'Копировать';

  @override
  String get move => 'Переместить';

  @override
  String get restore => 'Восстановить';

  @override
  String get apply => 'Применить';

  @override
  String get create => 'Создать';

  @override
  String get clear => 'Очистить';

  @override
  String get add => 'Добавить';

  @override
  String get remove => 'Удалить';

  @override
  String get edit => 'Редактировать';

  @override
  String get switchLabel => 'Переключить';

  @override
  String get search => 'Поиск';

  @override
  String get name => 'Имя';

  @override
  String get date => 'Дата';

  @override
  String get size => 'Размер';

  @override
  String get type => 'Тип';

  @override
  String get ascending => 'По возрастанию';

  @override
  String get descending => 'По убыванию';

  @override
  String get allFiles => 'Все';

  @override
  String get categoryImages => 'Изображения';

  @override
  String get categoryPhotos => 'Фото';

  @override
  String get categoryVideos => 'Видео';

  @override
  String get categoryAudio => 'Аудио';

  @override
  String get categoryDocuments => 'Документы';

  @override
  String get categoryArchives => 'Архивы';

  @override
  String get categoryShared => 'Общие';

  @override
  String get categoryOther => 'Другое';

  @override
  String get categoryOtherFiles => 'Другие файлы';

  @override
  String get noFilesFound => 'Файлы не найдены.';

  @override
  String get noFilesInFolder => 'В этой папке нет файлов.';

  @override
  String get thisActionCannotBeUndone => 'Это действие нельзя отменить.';

  @override
  String get passwordsDoNotMatch => 'Пароли не совпадают.';

  @override
  String get navLocalFiles => 'Локальные';

  @override
  String get navServerFiles => 'Сервер';

  @override
  String get navSettings => 'Настройки';

  @override
  String get navTrash => 'Корзина';

  @override
  String get navLocal => 'Локальные';

  @override
  String get navServer => 'Сервер';

  @override
  String get addServer => 'Добавить сервер';

  @override
  String get noServersConfigured => 'Серверы не настроены.';

  @override
  String get addAServerInSettings => 'Добавьте сервер в настройках.';

  @override
  String get addFirstServerHint => 'Добавьте первый сервер, чтобы продолжить.';

  @override
  String get noServersConfiguredYet => 'Серверы ещё не настроены.';

  @override
  String get crowleysCloudSetup => 'Настройка Crowley\'s Cloud';

  @override
  String get connect => 'Подключить';

  @override
  String get connecting => 'Подключение...';

  @override
  String get connected => 'Подключён';

  @override
  String get disconnected => 'Отключён';

  @override
  String get switchServer => 'Сменить сервер';

  @override
  String get chooseOtherServer => 'Выбрать другой сервер';

  @override
  String get switchServerTitle => 'Сменить сервер?';

  @override
  String switchServerBody(String serverName) {
    return 'Переключить активный сервер на \"$serverName\"?';
  }

  @override
  String get chooseServer => 'Выбрать сервер';

  @override
  String get authenticationRequired => 'Требуется аутентификация';

  @override
  String signInToAccess(String serverName) {
    return 'Войдите для доступа к файлам на $serverName';
  }

  @override
  String get signInWithPassword => 'Войти с паролем';

  @override
  String get useBiometrics => 'Использовать биометрию';

  @override
  String get openingSignIn => 'Открываем вход...';

  @override
  String get serverConnectionFailed => 'Ошибка подключения к серверу';

  @override
  String get unableToConnectToServer =>
      'Не удаётся подключиться к активному серверу.';

  @override
  String unableToConnectTo(String serverName) {
    return 'Не удаётся подключиться к $serverName.';
  }

  @override
  String get searchHint => 'Поиск...';

  @override
  String get searchFilesHint => 'Поиск файлов...';

  @override
  String get searchServerFilesHint => 'Поиск файлов на сервере...';

  @override
  String get searchTrashHint => 'Поиск в корзине...';

  @override
  String get storagePermissionRequired => 'Требуется разрешение на хранилище';

  @override
  String get grantPermission => 'Разрешить';

  @override
  String get permissionDeniedOpenSettings =>
      'Разрешение отклонено. Пожалуйста, предоставьте доступ к хранилищу в настройках.';

  @override
  String get manageStoragePermissionRequired =>
      'Для просмотра и выбора папок требуется разрешение «Управление хранилищем».';

  @override
  String get storagePermissionsRequired =>
      'Для выполнения синхронизации необходимы разрешения на хранилище.';

  @override
  String updateAvailableTitle(String version) {
    return 'Доступно обновление: v$version';
  }

  @override
  String get updateAvailableTapToSeeNew => 'Нажмите, чтобы увидеть новое';

  @override
  String get updateView => 'Посмотреть';

  @override
  String get updateAvailableDialogTitle => 'Доступно обновление';

  @override
  String updateVersionSubtitle(String version) {
    return 'Версия $version';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'Текущая: v$version';
  }

  @override
  String updateNewVersion(String version) {
    return 'Новая: v$version';
  }

  @override
  String get updateWhatsNew => 'Что нового:';

  @override
  String get updateGitHub => 'GitHub';

  @override
  String get updateNoReleaseNotes => 'Примечания к выпуску не предоставлены.';

  @override
  String get updateLater => 'Позже';

  @override
  String get updateDownloadApk => 'Скачать APK';

  @override
  String get updateInstall => 'Обновить';

  @override
  String get shareLinkTitle => 'Ссылка для общего доступа';

  @override
  String get shareViaLink => 'Поделиться ссылкой';

  @override
  String get shareInServer => 'Поделиться на сервере';

  @override
  String get expiryDays => 'Срок (дни)';

  @override
  String get expiryNever => 'Никогда';

  @override
  String get expiry1Day => '1 день';

  @override
  String get expiry7Days => '7 дней';

  @override
  String get expiry30Days => '30 дней';

  @override
  String get expiry90Days => '90 дней';

  @override
  String get expiry180Days => '180 дней';

  @override
  String get expiry365Days => '365 дней';

  @override
  String get createLink => 'Создать ссылку';

  @override
  String get sharedLinkCopied => 'Ссылка скопирована в буфер обмена!';

  @override
  String failedToCopySharedLink(String error) {
    return 'Не удалось скопировать ссылку: $error';
  }

  @override
  String get cannotShareThisFileType =>
      'Этот тип файла нельзя открыть для общего доступа.';

  @override
  String failedToCreateShare(String error) {
    return 'Не удалось создать ссылку: $error';
  }

  @override
  String get newFolderTitle => 'Создать папку';

  @override
  String get newFolderHint => 'Имя папки';

  @override
  String get newFolder => 'Новая папка';

  @override
  String get folderCreated => 'Папка создана.';

  @override
  String failedToCreateFolder(String error) {
    return 'Не удалось создать папку: $error';
  }

  @override
  String get creatingFolder => 'Создание папки...';

  @override
  String get renameDialogTitle => 'Переименовать';

  @override
  String get renameHint => 'Новое имя';

  @override
  String get enterNewName => 'Введите новое имя';

  @override
  String get renamedSuccessfully => 'Успешно переименовано.';

  @override
  String renameFailed(String error) {
    return 'Ошибка переименования: $error';
  }

  @override
  String get moveDialogTitle => 'Переместить в';

  @override
  String moveTo(String path) {
    return 'Переместить в: $path';
  }

  @override
  String get moveHere => 'Переместить сюда';

  @override
  String moveFailed(String error) {
    return 'Ошибка перемещения: $error';
  }

  @override
  String get movedToFolder => 'Перемещено в папку.';

  @override
  String copyFailed(String error) {
    return 'Ошибка копирования: $error';
  }

  @override
  String get selectFolder => 'Выбрать папку';

  @override
  String get useThisFolder => 'Использовать эту папку';

  @override
  String get storageRoot => 'Хранилище';

  @override
  String get serverRoot => 'корень';

  @override
  String deleteNItemsTitle(int count) {
    return 'Удалить $count элемент(ов)?';
  }

  @override
  String get deleteFilesTitle => 'Удалить файлы?';

  @override
  String deleteFilesBody(int count) {
    return 'Удалить $count выбранных элементов? Это действие нельзя отменить.';
  }

  @override
  String get deletePermanently => 'Удалить навсегда';

  @override
  String get deletePermanentlyTitle => 'Удалить навсегда?';

  @override
  String deletePermanentlyBody(String filename) {
    return '$filename будет удалён навсегда.';
  }

  @override
  String get deleteFileTitle => 'Удалить файл?';

  @override
  String deleteFileBody(String filename) {
    return 'Удалить файл $filename? Это действие нельзя отменить.';
  }

  @override
  String get deleteServerFileTitle => 'Удалить навсегда';

  @override
  String deleteServerFileBody(String filename) {
    return 'Удалить «$filename» навсегда? Это действие нельзя отменить.';
  }

  @override
  String get unshareItemsTitle => 'Отменить доступ?';

  @override
  String unshareItemsBody(int count) {
    return 'Отменить доступ для $count выбранных элементов? Они будут удалены из папки «Общие».';
  }

  @override
  String get unshare => 'Отменить доступ';

  @override
  String get moveToTrash => 'В корзину';

  @override
  String get movedToTrash => 'Перемещено в корзину.';

  @override
  String movedNItemsToTrash(int count) {
    return '$count элемент(ов) перемещено в корзину.';
  }

  @override
  String failedToMoveToTrash(String error) {
    return 'Не удалось переместить в корзину: $error';
  }

  @override
  String deletedNItems(int count) {
    return 'Удалено $count элемент(ов).';
  }

  @override
  String failedToDelete(String error) {
    return 'Ошибка удаления: $error';
  }

  @override
  String failedToDeleteItem(String error) {
    return 'Ошибка удаления: $error';
  }

  @override
  String deletedFilename(String filename) {
    return 'Удалён $filename.';
  }

  @override
  String get failedToOpenFile => 'Не удалось открыть файл';

  @override
  String fileDownloadFailed(String error) {
    return 'Ошибка скачивания: $error';
  }

  @override
  String get downloading => 'Скачивание...';

  @override
  String get downloadingFile => 'Скачивание файла...';

  @override
  String downloadComplete(String filename) {
    return 'Скачивание завершено: $filename';
  }

  @override
  String downloadFailed(String error) {
    return 'Ошибка скачивания: $error';
  }

  @override
  String get failedToDownloadPreview => 'Не удалось загрузить превью';

  @override
  String uploadComplete(String filename) {
    return 'Загружено: $filename';
  }

  @override
  String uploadFailed(String error) {
    return 'Ошибка загрузки: $error';
  }

  @override
  String get failedToPickFiles => 'Не удалось выбрать файлы';

  @override
  String uploadedNItems(int count) {
    return 'Загружено $count файл(ов)';
  }

  @override
  String get copiedLinkToClipboard => 'Ссылка скопирована.';

  @override
  String failedToCopyLink(String error) {
    return 'Не удалось скопировать ссылку: $error';
  }

  @override
  String get selectingAll => 'Выбираем всё...';

  @override
  String get allItemsSelected => 'Все элементы выбраны.';

  @override
  String get failedToLoadSearchResults =>
      'Не удалось загрузить результаты поиска';

  @override
  String get shareNotSupportedForType =>
      'Этот тип файла не поддерживает общий доступ.';

  @override
  String nSelected(int count) {
    return '$count выбрано';
  }

  @override
  String get noServerSelected => 'Сервер не выбран';

  @override
  String get pleaseConnectToServerFirst =>
      'Пожалуйста, сначала подключитесь к серверу.';

  @override
  String get signInRequired => 'Требуется вход';

  @override
  String pleaseSignInToServer(String serverName) {
    return 'Пожалуйста, сначала войдите на $serverName.';
  }

  @override
  String get connectingToServer => 'Подключение к серверу...';

  @override
  String connectedToServer(String serverName) {
    return 'Подключён к $serverName.';
  }

  @override
  String connectionFailed(String error) {
    return 'Ошибка подключения: $error';
  }

  @override
  String failedToConnect(String error) {
    return 'Не удалось подключиться: $error';
  }

  @override
  String authFailed(String error) {
    return 'Ошибка аутентификации: $error';
  }

  @override
  String get authFailedGeneric =>
      'Ошибка аутентификации. Пожалуйста, попробуйте снова.';

  @override
  String biometricLoginFailed(String error) {
    return 'Ошибка биометрического входа: $error';
  }

  @override
  String get biometricLoginFailedGeneric => 'Ошибка биометрического входа.';

  @override
  String get noServerSessionToken =>
      'Нет токена сессии. Повторите аутентификацию сервера.';

  @override
  String failedToSaveServer(String error) {
    return 'Не удалось сохранить сервер: $error';
  }

  @override
  String get addToFolder => 'Добавить в папку';

  @override
  String get loginTabLabel => 'Вход';

  @override
  String get registerTabLabel => 'Регистрация';

  @override
  String get welcomeBack => 'С возвращением';

  @override
  String get signInToContinue => 'Войдите, чтобы продолжить';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get joinTheServer => 'Присоединиться к серверу';

  @override
  String get usernameLabel => 'Имя пользователя';

  @override
  String get usernameHint => 'Введите имя пользователя';

  @override
  String get passwordLabel => 'Пароль';

  @override
  String get passwordHint => 'Введите пароль';

  @override
  String get showPassword => 'Показать пароль';

  @override
  String get hidePassword => 'Скрыть пароль';

  @override
  String get confirmPassword => 'Подтвердите пароль';

  @override
  String get logIn => 'Войти';

  @override
  String get loggingIn => 'Вход...';

  @override
  String get registering => 'Регистрация...';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get doNotHaveAccount => 'Нет аккаунта? Перейти к регистрации.';

  @override
  String get alreadyHaveAccount => 'Уже есть аккаунт? Перейти ко входу.';

  @override
  String get usernameCannotBeEmpty => 'Имя пользователя не может быть пустым.';

  @override
  String get passwordCannotBeEmpty => 'Пароль не может быть пустым.';

  @override
  String get usernameInvalid =>
      'Имя пользователя: 3–32 символа, буквы, цифры, _ или -.';

  @override
  String get passwordTooShort => 'Пароль должен содержать не менее 8 символов.';

  @override
  String loginFailed(String error) {
    return 'Ошибка входа: $error';
  }

  @override
  String registrationFailed(String error) {
    return 'Ошибка регистрации: $error';
  }

  @override
  String get resetPasswordTitle => 'Сброс пароля';

  @override
  String get enterResetCodeTitle => 'Введите код сброса';

  @override
  String get resetPasswordStep1Body =>
      'Введите имя пользователя. 6-значный код подтверждения будет выведен в логи/консоль сервера.';

  @override
  String get resetPasswordStep2Body =>
      'Код подтверждения выведен в консоль сервера. Введите 6-значный код и новый пароль.';

  @override
  String get resetCodeLabel => 'Код сброса';

  @override
  String get resetCodeHint => 'Введите 6-значный код';

  @override
  String get newPasswordLabel => 'Новый пароль';

  @override
  String get newPasswordHint => 'Введите новый пароль';

  @override
  String get passwordResetSuccessfully => 'Пароль успешно сброшен!';

  @override
  String get usernameIsRequired => 'Требуется имя пользователя.';

  @override
  String get codeAndPasswordRequired => 'Необходимо ввести код и новый пароль.';

  @override
  String get failedToRequestReset =>
      'Не удалось запросить сброс. Проверьте URL сервера.';

  @override
  String get failedToResetPassword =>
      'Не удалось сбросить пароль. Проверьте код.';

  @override
  String get pleaseEnterServerUrlFirst => 'Сначала введите URL сервера.';

  @override
  String get sendCode => 'Отправить код';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get sectionBackupSync => 'Резервное копирование и синхронизация';

  @override
  String get sectionStorageCache => 'Хранилище и кеш';

  @override
  String get sectionSecurityBehavior => 'Безопасность и поведение';

  @override
  String get sectionAboutUpdates => 'О приложении и обновления';

  @override
  String get sectionAppearance => 'Внешний вид и оформление';

  @override
  String get noServersConfiguredSync => 'Серверы не настроены';

  @override
  String get addServerBeforeSync =>
      'Добавьте сервер перед настройкой синхронизации.';

  @override
  String get selectServerToConfigureSync =>
      'Выберите сервер для настройки синхронизации.';

  @override
  String get activeServerSuffix => '· активный';

  @override
  String get folderAndCategorySync => 'Синхронизация папок и категорий';

  @override
  String get keepCategoriesSynced =>
      'Синхронизировать выбранные категории или папки с этим сервером.';

  @override
  String get addServerBeforeSyncEnable =>
      'Добавьте сервер перед включением синхронизации.';

  @override
  String get onlyOnWifi => 'Только по Wi-Fi';

  @override
  String get onlyWhileCharging => 'Только при зарядке';

  @override
  String get serverTargetDirectory => 'Целевая директория на сервере';

  @override
  String get serverTargetDirectoryHint => '/backup/mobile_phone';

  @override
  String get synchronizationFrequency => 'Частота синхронизации';

  @override
  String get syncNow => 'Синхронизировать сейчас';

  @override
  String get syncing => 'Синхронизация...';

  @override
  String get categoriesToSynchronize => 'Категории для синхронизации';

  @override
  String get noCategoriesSelected => 'Категории не выбраны.';

  @override
  String nCategoriesSelected(int count) {
    return '$count выбрано';
  }

  @override
  String get foldersToSynchronize => 'Папки для синхронизации';

  @override
  String get noCustomFolders => 'Папки не настроены.';

  @override
  String nFolders(int count) {
    return '$count папка(-ок)';
  }

  @override
  String get addFolder => 'Добавить папку';

  @override
  String get removeFolder => 'Удалить папку';

  @override
  String get removeServer => 'Удалить сервер';

  @override
  String get syncFreqEvery15Min => 'Каждые 15 минут';

  @override
  String get syncFreqEvery30Min => 'Каждые 30 минут';

  @override
  String get syncFreqEvery1Hour => 'Каждый час';

  @override
  String syncFreqEveryNHours(int hours) {
    return 'Каждые $hours ч';
  }

  @override
  String syncFreqEveryNMin(int minutes) {
    return 'Каждые $minutes мин';
  }

  @override
  String get syncFreqDaily => 'Ежедневно';

  @override
  String get chooseSyncFrequencyTitle => 'Выберите частоту синхронизации';

  @override
  String get cacheSize => 'Размер кеша';

  @override
  String get refreshTooltip => 'Обновить';

  @override
  String get cacheLimit => 'Лимит кеша';

  @override
  String get downloadPath => 'Путь загрузки';

  @override
  String get defaultDownloadFolder => 'Папка CrowleysCloud по умолчанию';

  @override
  String get clearCache => 'Очистить кеш';

  @override
  String get clearCacheTitle => 'Очистить кеш?';

  @override
  String get clearCacheBody =>
      'Это удалит локальные миниатюры и кешированные данные сервера.';

  @override
  String get downloadPathDialogTitle => 'Путь загрузки';

  @override
  String get downloadPathHint => '/storage/emulated/0/CrowleysCloud';

  @override
  String get useDefault => 'По умолчанию';

  @override
  String get serverTargetDirDialogTitle => 'Целевая директория на сервере';

  @override
  String get requireLogin => 'Требовать вход';

  @override
  String get biometricLogin => 'Биометрический вход';

  @override
  String get biometricLoginSubtitle =>
      'Разрешить вход по сохранённым учётным данным с биометрией.';

  @override
  String get biometricsNotAvailable =>
      'Биометрия недоступна на этом устройстве.';

  @override
  String get showHiddenFiles => 'Показывать скрытые файлы';

  @override
  String get showHiddenFilesSubtitle =>
      'Отображать файлы и папки, начинающиеся с точки.';

  @override
  String get changePassword => 'Изменить пароль';

  @override
  String changePasswordSubtitle(String serverName) {
    return 'Изменить пароль для $serverName.';
  }

  @override
  String get addServerBeforeChangePassword =>
      'Добавьте сервер перед изменением пароля.';

  @override
  String get deleteUserAccount => 'Удалить аккаунт';

  @override
  String get deleteUserAccountSubtitle =>
      'Удаляет пользователя и все файлы в личном облаке.';

  @override
  String get deleteAccountTitle => 'Удалить аккаунт?';

  @override
  String deleteAccountBody(String serverName) {
    return 'Это навсегда удалит ваш аккаунт на $serverName и все файлы в личном облаке. Это действие нельзя отменить.';
  }

  @override
  String get deleteAccountButton => 'Удалить аккаунт';

  @override
  String get changePasswordDialogTitle => 'Изменить пароль';

  @override
  String get newPasswordFieldLabel => 'Новый пароль';

  @override
  String get confirmPasswordLabel => 'Подтвердите пароль';

  @override
  String get enterNewPassword => 'Введите новый пароль.';

  @override
  String get passwordUpdated => 'Пароль обновлён.';

  @override
  String passwordChangeFailed(String error) {
    return 'Ошибка смены пароля: $error';
  }

  @override
  String get passwordChangeFailedGeneric => 'Ошибка смены пароля.';

  @override
  String get accountDeleted => 'Аккаунт удалён.';

  @override
  String accountDeletionFailed(String error) {
    return 'Ошибка удаления аккаунта: $error';
  }

  @override
  String get accountDeletionFailedGeneric => 'Ошибка удаления аккаунта.';

  @override
  String get checkForUpdates => 'Проверить обновления';

  @override
  String get checkingForUpdates => 'Проверка GitHub Releases...';

  @override
  String versionLabel(String version) {
    return 'Версия $version';
  }

  @override
  String appIsUpToDate(String version) {
    return 'Crowley\'s Cloud обновлён (v$version).';
  }

  @override
  String get updateCheckFailed =>
      'Не удалось проверить обновления. Попробуйте позже.';

  @override
  String get themeModeTitle => 'Тема оформления';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeCustom => 'Своя';

  @override
  String get themeDarkFull => 'Тёмная тема';

  @override
  String get themeLightFull => 'Светлая тема';

  @override
  String get themeCustomFull => 'Своя тема';

  @override
  String get accentColor => 'Акцентный цвет';

  @override
  String get primaryAccentColor => 'Основной акцентный цвет';

  @override
  String get selectAccentColor => 'Выбрать акцентный цвет';

  @override
  String get backgroundColor => 'Цвет фона';

  @override
  String get surfaceColor => 'Цвет поверхности';

  @override
  String get textColor => 'Цвет текста';

  @override
  String get subtextColor => 'Цвет вторичного текста';

  @override
  String get borderColor => 'Цвет рамки';

  @override
  String get fontSizeScale => 'Масштаб шрифта';

  @override
  String selectColor(String title) {
    return 'Выбрать $title';
  }

  @override
  String get categoriesToSyncDialogTitle => 'Категории для синхронизации';

  @override
  String get categoriesToSyncBody =>
      'Выберите одну или несколько категорий. Можно не выбирать ни одной.';

  @override
  String get syncCategorySectionMedia => 'Медиа';

  @override
  String get syncCategorySectionAudioDocs => 'Аудио и документы';

  @override
  String get syncCategorySectionOther => 'Другое';

  @override
  String get clearAll => 'Сбросить всё';

  @override
  String get noSyncHasRunYet => 'Синхронизация ещё не выполнялась.';

  @override
  String lastRunAt(String date) {
    return 'Последний запуск $date';
  }

  @override
  String syncResultSuccess(int uploaded, int skipped) {
    return 'Синхронизировано $uploaded, пропущено $skipped.';
  }

  @override
  String get syncResultNoFiles => 'Файлы для синхронизации не выбраны.';

  @override
  String syncResultPartial(int uploaded, int failed) {
    return 'Синхронизировано $uploaded, ошибок $failed.';
  }

  @override
  String get syncResultAuthRequired => 'Войдите перед синхронизацией.';

  @override
  String get syncResultUnreachable => 'Сервер недоступен. Соединение потеряно.';

  @override
  String get syncResultFailed => 'Ошибка синхронизации.';

  @override
  String get serverSetupAddServer => 'Добавить сервер';

  @override
  String get serverSetupCardTitle => 'Подключить сервер';

  @override
  String get serverSetupCardSubtitle =>
      'Добавьте домашний файловый сервер и войдите.';

  @override
  String get serverSetupSubmitButton => 'Сохранить сервер';

  @override
  String get serverNameLabel => 'Имя сервера';

  @override
  String get serverNameHint => 'Домашний NAS';

  @override
  String get baseUrlLabel => 'Базовый URL';

  @override
  String get baseUrlHint => 'https://cloud.example.com';

  @override
  String get allFieldsRequired => 'Все поля обязательны.';

  @override
  String get localFilesTitle => 'Локальные файлы';

  @override
  String get serverFilesTitle => 'Файлы сервера';

  @override
  String get restoreItemsTitle => 'Восстановить элементы';

  @override
  String restoreItemsBody(int count) {
    return 'Восстановить $count элемент(ов)?';
  }

  @override
  String get permanentlyDeleteTitle => 'Удалить навсегда';

  @override
  String permanentlyDeleteBody(int count) {
    return 'Удалить $count элемент(ов) навсегда? Это действие нельзя отменить.';
  }

  @override
  String get trashIsEmpty => 'Корзина пуста.';

  @override
  String trashRetentionInfo(int days) {
    return 'Элементы в корзине автоматически удаляются через $days дней.';
  }

  @override
  String get deletionDate => 'Дата удаления';

  @override
  String get deletePermanentlyAction => 'Удалить навсегда';

  @override
  String get conflictFileAlreadyExists => 'Файл уже существует';

  @override
  String conflictNofM(int current, int total) {
    return 'Конфликт $current из $total';
  }

  @override
  String get conflictAFileNamed => 'Файл с именем ';

  @override
  String get conflictAlreadyExistsAt => ' уже существует в ';

  @override
  String get conflictAlreadyExistsInFolder => ' уже существует в этой папке.';

  @override
  String get conflictInFolder => 'В папке';

  @override
  String get conflictFromTrash => 'Из корзины';

  @override
  String get conflictExisting => 'Существующий';

  @override
  String get conflictNewUpload => 'Новая загрузка';

  @override
  String conflictSizeLabel(String size) {
    return 'Размер: $size';
  }

  @override
  String conflictDateLabel(String date) {
    return 'Дата: $date';
  }

  @override
  String conflictDeletedLabel(String date) {
    return 'Удалён: $date';
  }

  @override
  String conflictApplyToRemaining(int count) {
    return 'Применить к $count оставшимся конфликтам';
  }

  @override
  String get conflictKeepAllCopies => 'Оставить все копии';

  @override
  String get conflictOverwriteAll => 'Перезаписать все';

  @override
  String get conflictRestoreAllAsCopies => 'Восстановить все как копии';

  @override
  String get conflictRestoreAsCopy => 'Восстановить как копию';

  @override
  String get conflictOverwriteAllRemaining => 'Перезаписать все оставшиеся';

  @override
  String get conflictSkipAll => 'Пропустить все';

  @override
  String get conflictSkipAllRemaining => 'Пропустить все оставшиеся';

  @override
  String get conflictSkip => 'Пропустить';

  @override
  String get conflictOverwrite => 'Перезаписать';

  @override
  String get transfersTitle => 'Передачи';

  @override
  String get transferResume => 'Возобновить';

  @override
  String get transferPause => 'Пауза';

  @override
  String get transferCancel => 'Отмена';

  @override
  String get transferResumeAll => 'Возобновить все';

  @override
  String get transferPauseAll => 'Пауза всех';

  @override
  String get transferCancelAll => 'Отменить все';

  @override
  String get transferCancelFile => 'Отменить файл';

  @override
  String get noTransfers => 'Нет передач.';

  @override
  String get transferStatusQueued => 'В очереди';

  @override
  String get transferStatusRunning => 'Выполняется';

  @override
  String get transferStatusPaused => 'Приостановлено';

  @override
  String get transferStatusCompleted => 'Завершено';

  @override
  String get transferStatusFailed => 'Ошибка';

  @override
  String get transferStatusCanceled => 'Отменено';

  @override
  String get themePresetsSection => 'Пресеты';

  @override
  String get themeCustomPaletteSection => 'Пользовательская палитра';

  @override
  String get themeHexRgbLabel => 'HEX RGB код';

  @override
  String get themeHexRgbHint => '#FA5252';

  @override
  String get imageViewerNoFetchHandler => 'Обработчик загрузки не настроен';

  @override
  String get imageViewerFailedToLoad => 'Не удалось загрузить изображение';

  @override
  String errorDeletingFile(String filename, String error) {
    return 'Ошибка удаления $filename: $error';
  }

  @override
  String errorReadingFile(String error) {
    return 'Ошибка чтения файла: $error';
  }

  @override
  String get syncChannelName => 'Фоновая синхронизация';

  @override
  String get syncChannelDescription =>
      'Показывает статус синхронизации файлов в фоне.';

  @override
  String get storageStatsTitle => 'Статистика хранилища';

  @override
  String get storageStatsUsedSpace => 'Использовано';

  @override
  String get storageStatsTotalFiles => 'Всего файлов';

  @override
  String storageStatsNItems(int count) {
    return '$count элементов';
  }

  @override
  String userFallback(int userId) {
    return 'Пользователь #$userId';
  }

  @override
  String get biometricUnlockReason =>
      'Разблокируйте сохранённые учётные данные для Crowley\'s Cloud.';

  @override
  String get tokenLifetimeEveryOpen => 'При каждом открытии приложения';

  @override
  String get tokenLifetimeOneHour => 'Через 1 час';

  @override
  String get tokenLifetime1Hour => 'Через 1 час';

  @override
  String get tokenLifetimeOneDay => 'Через 1 день';

  @override
  String get tokenLifetime1Day => 'Через 1 день';

  @override
  String get tokenLifetimeOneWeek => 'Через 1 неделю';

  @override
  String get tokenLifetime1Week => 'Через 1 неделю';

  @override
  String get tokenLifetimeOneMonth => 'Через 1 месяц';

  @override
  String get tokenLifetime1Month => 'Через 1 месяц';

  @override
  String get tokenLifetimeThreeMonths => 'Через 3 месяца';

  @override
  String get tokenLifetime3Months => 'Через 3 месяца';

  @override
  String get tokenLifetimeNever => 'Никогда на этом устройстве';

  @override
  String get cacheLimitUnlimited => 'Без ограничений';

  @override
  String get syncCategoryOtherFiles => 'Другие файлы';

  @override
  String get internalStorage => 'Внутренняя память';

  @override
  String get localStorageRootName => 'Внутренняя память';

  @override
  String syncNotificationSyncingWith(String serverName) {
    return 'Синхронизация с $serverName';
  }

  @override
  String syncNotificationPausedTitle(String serverName) {
    return 'Синхронизация с $serverName приостановлена';
  }

  @override
  String get syncNotificationUnreachableBody =>
      'Сервер недоступен. Фоновая синхронизация приостановлена до открытия приложения.';

  @override
  String get syncNotificationAuthRequiredBody =>
      'Требуется авторизация. Откройте приложение для входа.';

  @override
  String syncNotificationFailedTitle(String serverName) {
    return 'Синхронизация с $serverName не удалась';
  }

  @override
  String get syncNotificationGenericErrorBody =>
      'Произошла ошибка во время синхронизации.';

  @override
  String syncNotificationCompleteTitle(String serverName) {
    return 'Синхронизация с $serverName завершена';
  }

  @override
  String get syncNotificationCompleteBody => 'Синхронизация завершена.';

  @override
  String get syncStatusConnecting => 'Подключение к серверу...';

  @override
  String syncStatusConnectionLost(String serverName) {
    return 'Не удалось подключиться к $serverName. Соединение потеряно.';
  }

  @override
  String syncResultServerUnreachableWithServer(String serverName) {
    return 'Не удалось подключиться к $serverName. Соединение потеряно.';
  }

  @override
  String get syncStatusScanningFiles => 'Сканирование файлов на устройстве...';

  @override
  String get syncStatusNoFilesFound => 'Файлы для синхронизации не найдены.';

  @override
  String get syncStatusNoFilesSelected => 'Не выбраны файлы для синхронизации.';

  @override
  String syncStatusCalculatingChecksum(
    int current,
    int total,
    String filename,
  ) {
    return 'Вычисление контрольной суммы ($current/$total): $filename';
  }

  @override
  String get syncStatusCheckingDuplicates =>
      'Проверка дубликатов на сервере...';

  @override
  String syncStatusSyncingFile(int current, int total, String filename) {
    return 'Синхронизация ($current/$total): $filename';
  }

  @override
  String get syncStatusCompleting => 'Завершение синхронизации...';

  @override
  String get showingCachedFiles => 'Отображаются кэшированные файлы.';

  @override
  String get showingCachedFilesRefreshFailed =>
      'Отображаются кэшированные файлы. Не удалось обновить.';

  @override
  String get downloadCanceled => 'Скачивание отменено.';

  @override
  String downloadedNFilesToPath(int count, String path) {
    return 'Скачано файлов: $count в $path';
  }

  @override
  String downloadedNFilesFailedM(int downloaded, int failed, String detail) {
    return 'Скачано файлов: $downloaded, ошибок $failed: $detail';
  }

  @override
  String downloadedNFilesWithFailures(int count, int failed, String error) {
    return 'Скачано файлов: $count, ошибок $failed: $error';
  }

  @override
  String createdNShareLinks(int count) {
    return 'Создано ссылок: $count.';
  }

  @override
  String get failedToCreateShareLinks =>
      'Не удалось создать ссылки общего доступа.';

  @override
  String get alreadyInSharedScope => 'Уже в общем доступе.';

  @override
  String sharedNItemsInServer(int count) {
    return 'Открыт доступ к $count элементу(-ам) на сервере.';
  }

  @override
  String sharedNItemsWithFailures(int count, int failed) {
    return 'Открыт доступ к $count элементу(-ам), ошибок: $failed.';
  }

  @override
  String sharedNItemsFailedM(int shared, int failed) {
    return 'Открыт доступ к $shared элементу(-ам), ошибок: $failed.';
  }

  @override
  String get folderNameCannotBeEmpty => 'Имя папки не может быть пустым.';

  @override
  String get folderAlreadyExists => 'Папка с таким именем уже существует.';

  @override
  String get folderCreationOnlyInAllFiles =>
      'Создание папок доступно только в разделе «Все файлы».';

  @override
  String get currentDirectoryUnavailable => 'Текущая папка недоступна.';

  @override
  String get nothingSelected => 'Ничего не выбрано.';

  @override
  String get destinationFolderDoesNotExist => 'Папка назначения не существует.';

  @override
  String cannotMoveFolderIntoItself(String name) {
    return 'Нельзя переместить папку «$name» саму в себя.';
  }

  @override
  String failedToMoveItem(String name, String error) {
    return 'Не удалось переместить $name: $error';
  }

  @override
  String movedNItems(int count) {
    return 'Перемещено элементов: $count.';
  }

  @override
  String movedNItemsWithFailures(int count, int failed) {
    return 'Перемещено элементов: $count, ошибок: $failed.';
  }

  @override
  String movedNItemsFailedM(int moved, int failed) {
    return 'Перемещено элементов: $moved, ошибок: $failed.';
  }

  @override
  String get failedToMoveSelectedItems =>
      'Не удалось переместить выбранные объекты.';

  @override
  String get noFilesWereMoved => 'Файлы не были перемещены.';

  @override
  String renamedOldToNew(String oldName, String newName) {
    return '«$oldName» переименован в «$newName».';
  }

  @override
  String renamedFileFromTo(String oldName, String newName) {
    return '«$oldName» переименован в «$newName».';
  }

  @override
  String failedToRenameWithStatus(String name, int statusCode) {
    return 'Не удалось переименовать «$name» ($statusCode).';
  }

  @override
  String failedToRenameFileWithCode(String name, int statusCode) {
    return 'Не удалось переименовать «$name» ($statusCode).';
  }

  @override
  String failedToRenameWithError(String name, String error) {
    return 'Не удалось переименовать «$name»: $error';
  }

  @override
  String failedToRenameFile(String name, String error) {
    return 'Не удалось переименовать «$name»: $error';
  }

  @override
  String get renameConflictAlreadyExists =>
      'Не удалось переименовать: файл или папка с таким именем уже существует.';

  @override
  String get renameFailedAlreadyExists =>
      'Не удалось переименовать: файл или папка с таким именем уже существует.';

  @override
  String failedToCreateFolderWithCode(int statusCode) {
    return 'Не удалось создать папку (код $statusCode).';
  }

  @override
  String deletedNItemsFailedM(int deleted, int failed) {
    return 'Удалено объектов: $deleted, ошибок: $failed.';
  }

  @override
  String transferSummaryFiles(int percent, int completed, int total) {
    return '$percent%  $completed/$total файлов';
  }

  @override
  String transferSummaryProgress(int percent, int completed, int total) {
    return '$percent%  $completed/$total файлов';
  }

  @override
  String get downloadFailedGeneric => 'Ошибка скачивания';

  @override
  String uploadedNItemsWithFailures(int uploaded, int failed) {
    return 'Загружено элементов: $uploaded, ошибок: $failed';
  }

  @override
  String uploadedNItemsFailedM(int uploaded, int failed) {
    return 'Загружено объектов: $uploaded, с ошибкой: $failed.';
  }

  @override
  String uploadSummaryFailedCount(int count) {
    return ', с ошибкой $count';
  }

  @override
  String uploadLocalPathEmpty(String name) {
    return '$name: локальный путь пуст';
  }

  @override
  String uploadErrorLocalPathEmpty(String name) {
    return '$name: локальный путь пуст';
  }

  @override
  String get directoryUploadFailed => 'Не удалось загрузить папку';

  @override
  String get uploadDirectoryFailed => 'Не удалось загрузить папку';

  @override
  String get localFileNotFound => 'Локальный файл не найден';

  @override
  String get uploadErrorLocalFileNotFound => 'Локальный файл не найден';

  @override
  String get noSessionToken => 'Нет активного токена сессии';

  @override
  String get uploadErrorNoSessionToken => 'Нет активного токена сессии';

  @override
  String get serverDisconnectedStatus => 'Сервер отключён';

  @override
  String get serverDisconnected => 'Сервер отключён';

  @override
  String get serverIsUnreachable => 'Сервер недоступен.';

  @override
  String get serverUnreachable => 'Сервер недоступен.';

  @override
  String get uploadErrorLocalDirectoryNotFound => 'Локальная папка не найдена';

  @override
  String get uploadErrorFailedToScanDirectory =>
      'Не удалось просканировать папку';

  @override
  String uploadErrorFolderCreateHttp(int statusCode) {
    return 'Не удалось создать папку (HTTP $statusCode)';
  }

  @override
  String get authErrorMissingAccessToken =>
      'В ответе отсутствует токен доступа';

  @override
  String get authErrorMissingRefreshToken =>
      'В ответе отсутствует токен обновления';

  @override
  String get authErrorNoSavedCredentials => 'Нет сохранённых учётных данных';

  @override
  String get authErrorNoRefreshToken => 'Нет доступного токена обновления';

  @override
  String get authErrorNoActiveSession => 'Нет активной сессии';

  @override
  String get authErrorNoSavedUsername => 'Нет сохранённого имени пользователя';

  @override
  String get updateNoReleasesPublished => 'Выпуски пока не опубликованы.';

  @override
  String get language => 'Язык';
}
