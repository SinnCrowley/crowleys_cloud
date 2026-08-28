// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'Crowley\'s Cloud';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'لغو';

  @override
  String get save => 'ذخیره';

  @override
  String get delete => 'حذف';

  @override
  String get rename => 'تغییر نام';

  @override
  String get close => 'بستن';

  @override
  String get retry => 'تلاش مجدد';

  @override
  String get loading => 'در حال بارگذاری...';

  @override
  String get confirm => 'تأیید';

  @override
  String get error => 'خطا';

  @override
  String errorWithMessage(String message) {
    return 'خطا: $message';
  }

  @override
  String get unknown => 'نامشخص';

  @override
  String get upload => 'بارگذاری';

  @override
  String get download => 'دانلود';

  @override
  String get share => 'اشتراک‌گذاری';

  @override
  String get copy => 'کپی';

  @override
  String get move => 'انتقال';

  @override
  String get restore => 'بازیابی';

  @override
  String get apply => 'اعمال';

  @override
  String get create => 'ایجاد';

  @override
  String get clear => 'پاک کردن';

  @override
  String get add => 'افزودن';

  @override
  String get remove => 'حذف';

  @override
  String get edit => 'ویرایش';

  @override
  String get switchLabel => 'تغییر';

  @override
  String get search => 'جستجو';

  @override
  String get name => 'نام';

  @override
  String get date => 'تاریخ';

  @override
  String get size => 'اندازه';

  @override
  String get type => 'نوع';

  @override
  String get ascending => 'صعودی';

  @override
  String get descending => 'نزولی';

  @override
  String get allFiles => 'همه';

  @override
  String get categoryImages => 'تصاویر';

  @override
  String get categoryPhotos => 'عکس‌ها';

  @override
  String get categoryVideos => 'ویدئوها';

  @override
  String get categoryAudio => 'صوتی';

  @override
  String get categoryDocuments => 'اسناد';

  @override
  String get categoryArchives => 'بایگانی‌ها';

  @override
  String get categoryShared => 'اشتراک‌گذاری‌شده';

  @override
  String get categoryOther => 'سایر';

  @override
  String get categoryOtherFiles => 'سایر فایل‌ها';

  @override
  String get noFilesFound => 'هیچ فایلی یافت نشد.';

  @override
  String get noFilesInFolder => 'هیچ فایلی در این پوشه وجود ندارد.';

  @override
  String get thisActionCannotBeUndone => 'این عملیات غیرقابل بازگشت است.';

  @override
  String get passwordsDoNotMatch => 'گذرواژه‌ها مطابقت ندارند.';

  @override
  String get navLocalFiles => 'فایل‌های محلی';

  @override
  String get navServerFiles => 'فایل‌های سرور';

  @override
  String get navSettings => 'تنظیمات';

  @override
  String get navTrash => 'سطل زباله';

  @override
  String get navLocal => 'محلی';

  @override
  String get navServer => 'سرور';

  @override
  String get addServer => 'افزودن سرور';

  @override
  String get noServersConfigured => 'هیچ سروری پیکربندی نشده است.';

  @override
  String get addAServerInSettings => 'یک سرور در تنظیمات اضافه کنید.';

  @override
  String get addFirstServerHint => 'برای ادامه، اولین سرور خود را اضافه کنید.';

  @override
  String get noServersConfiguredYet => 'هنوز سروری پیکربندی نشده است.';

  @override
  String get crowleysCloudSetup => 'راه‌اندازی Crowley\'s Cloud';

  @override
  String get connect => 'اتصال';

  @override
  String get connecting => 'در حال اتصال...';

  @override
  String get connected => 'متصل شد';

  @override
  String get disconnected => 'قطع شد';

  @override
  String get switchServer => 'تغییر سرور';

  @override
  String get chooseOtherServer => 'انتخاب سرور دیگر';

  @override
  String get switchServerTitle => 'تغییر سرور؟';

  @override
  String switchServerBody(String serverName) {
    return 'سرور فعال به \"$serverName\" تغییر یابد؟';
  }

  @override
  String get chooseServer => 'انتخاب سرور';

  @override
  String get authenticationRequired => 'احراز هویت لازم است';

  @override
  String signInToAccess(String serverName) {
    return 'برای دسترسی به فایل‌ها در $serverName وارد شوید';
  }

  @override
  String get signInWithPassword => 'ورود با گذرواژه';

  @override
  String get useBiometrics => 'استفاده از بیومتریک';

  @override
  String get openingSignIn => 'در حال باز کردن ورود...';

  @override
  String get serverConnectionFailed => 'اتصال به سرور ناموفق بود';

  @override
  String get unableToConnectToServer => 'امکان اتصال به سرور فعال وجود ندارد.';

  @override
  String unableToConnectTo(String serverName) {
    return 'اتصال به $serverName برقرار نشد.';
  }

  @override
  String get searchHint => 'جستجو...';

  @override
  String get searchFilesHint => 'جستجوی فایل‌ها...';

  @override
  String get searchServerFilesHint => 'جستجوی فایل‌های سرور...';

  @override
  String get searchTrashHint => 'جستجو در سطل زباله...';

  @override
  String get storagePermissionRequired => 'مجوز دسترسی به حافظه لازم است';

  @override
  String get grantPermission => 'اعطای مجوز';

  @override
  String get permissionDeniedOpenSettings =>
      'مجوز رد شد. لطفاً در تنظیمات دسترسی به حافظه را فعال کنید.';

  @override
  String get manageStoragePermissionRequired =>
      'برای مرور و انتخاب پوشه‌ها مجوز مدیریت حافظه لازم است.';

  @override
  String get storagePermissionsRequired =>
      'برای انجام همگام‌سازی مجوزهای حافظه لازم است.';

  @override
  String updateAvailableTitle(String version) {
    return 'به‌روزرسانی موجود است: v$version';
  }

  @override
  String get updateAvailableTapToSeeNew => 'برای مشاهده موارد جدید ضربه بزنید';

  @override
  String get updateView => 'مشاهده';

  @override
  String get updateAvailableDialogTitle => 'به‌روزرسانی موجود است';

  @override
  String updateVersionSubtitle(String version) {
    return 'نسخهٔ $version';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'فعلی: v$version';
  }

  @override
  String updateNewVersion(String version) {
    return 'جدید: v$version';
  }

  @override
  String get updateWhatsNew => 'موارد جدید:';

  @override
  String get updateGitHub => 'گیت‌هاب';

  @override
  String get updateNoReleaseNotes => 'یادداشت انتشاری ارائه نشده است.';

  @override
  String get updateLater => 'بعداً';

  @override
  String get updateDownloadApk => 'دانلود APK';

  @override
  String get updateInstall => 'به‌روزرسانی';

  @override
  String get shareLinkTitle => 'پیوند اشتراک‌گذاری';

  @override
  String get shareViaLink => 'اشتراک‌گذاری با پیوند';

  @override
  String get shareInServer => 'اشتراک‌گذاری در سرور';

  @override
  String get expiryDays => 'انقضا (روز)';

  @override
  String get expiryNever => 'هرگز';

  @override
  String get expiry1Day => '۱ روز';

  @override
  String get expiry7Days => '۷ روز';

  @override
  String get expiry30Days => '۳۰ روز';

  @override
  String get expiry90Days => '۹۰ روز';

  @override
  String get expiry180Days => '۱۸۰ روز';

  @override
  String get expiry365Days => '۳۶۵ روز';

  @override
  String get createLink => 'ایجاد پیوند';

  @override
  String get sharedLinkCopied => 'پیوند اشتراک‌گذاری در کلیپ‌بورد کپی شد!';

  @override
  String failedToCopySharedLink(String error) {
    return 'کپی کردن پیوند اشتراک‌گذاری ناموفق بود: $error';
  }

  @override
  String get cannotShareThisFileType =>
      'امکان اشتراک‌گذاری این نوع فایل وجود ندارد.';

  @override
  String failedToCreateShare(String error) {
    return 'ایجاد اشتراک ناموفق بود: $error';
  }

  @override
  String get newFolderTitle => 'ایجاد پوشه';

  @override
  String get newFolderHint => 'نام پوشه';

  @override
  String get newFolder => 'پوشه جدید';

  @override
  String get folderCreated => 'پوشه ایجاد شد.';

  @override
  String failedToCreateFolder(String error) {
    return 'ایجاد پوشه ناموفق بود: $error';
  }

  @override
  String get creatingFolder => 'در حال ایجاد پوشه...';

  @override
  String get renameDialogTitle => 'تغییر نام';

  @override
  String get renameHint => 'نام جدید';

  @override
  String get enterNewName => 'نام جدید را وارد کنید';

  @override
  String get renamedSuccessfully => 'نام با موفقیت تغییر کرد.';

  @override
  String renameFailed(String error) {
    return 'تغییر نام ناموفق بود: $error';
  }

  @override
  String get moveDialogTitle => 'انتقال به';

  @override
  String moveTo(String path) {
    return 'انتقال به: $path';
  }

  @override
  String get moveHere => 'انتقال به اینجا';

  @override
  String moveFailed(String error) {
    return 'انتقال ناموفق بود: $error';
  }

  @override
  String get movedToFolder => 'به پوشه منتقل شد.';

  @override
  String copyFailed(String error) {
    return 'کپی ناموفق بود: $error';
  }

  @override
  String get selectFolder => 'انتخاب پوشه';

  @override
  String get useThisFolder => 'استفاده از این پوشه';

  @override
  String get storageRoot => 'حافظه';

  @override
  String get serverRoot => 'ریشه';

  @override
  String deleteNItemsTitle(int count) {
    return '$count مورد حذف شود؟';
  }

  @override
  String get deleteFilesTitle => 'حذف فایل‌ها؟';

  @override
  String deleteFilesBody(int count) {
    return 'آیا مطمئن هستید که می‌خواهید $count مورد انتخاب‌شده را حذف کنید؟ این عملیات غیرقابل بازگشت است.';
  }

  @override
  String get deletePermanently => 'حذف دائمی';

  @override
  String get deletePermanentlyTitle => 'حذف دائمی؟';

  @override
  String deletePermanentlyBody(String filename) {
    return '$filename برای همیشه حذف خواهد شد.';
  }

  @override
  String get deleteFileTitle => 'حذف فایل؟';

  @override
  String deleteFileBody(String filename) {
    return 'آیا مطمئن هستید که می‌خواهید $filename را حذف کنید؟ این عملیات غیرقابل بازگشت است.';
  }

  @override
  String get deleteServerFileTitle => 'حذف دائمی';

  @override
  String deleteServerFileBody(String filename) {
    return 'آیا مطمئن هستید که می‌خواهید \"$filename\" را برای همیشه حذف کنید؟ این عملیات غیرقابل بازگشت است.';
  }

  @override
  String get unshareItemsTitle => 'لغو اشتراک‌گذاری موارد؟';

  @override
  String unshareItemsBody(int count) {
    return 'آیا مطمئن هستید که می‌خواهید اشتراک‌گذاری $count مورد انتخاب‌شده را لغو کنید؟ این کار آن‌ها را از پوشه اشتراک‌گذاری‌شده حذف می‌کند.';
  }

  @override
  String get unshare => 'لغو اشتراک‌گذاری';

  @override
  String get moveToTrash => 'انتقال به سطل زباله';

  @override
  String get movedToTrash => 'به سطل زباله منتقل شد.';

  @override
  String movedNItemsToTrash(int count) {
    return '$count مورد به سطل زباله منتقل شد.';
  }

  @override
  String failedToMoveToTrash(String error) {
    return 'انتقال به سطل زباله ناموفق بود: $error';
  }

  @override
  String deletedNItems(int count) {
    return '$count مورد حذف شد.';
  }

  @override
  String failedToDelete(String error) {
    return 'حذف ناموفق بود: $error';
  }

  @override
  String failedToDeleteItem(String error) {
    return 'حذف ناموفق بود: $error';
  }

  @override
  String deletedFilename(String filename) {
    return '$filename حذف شد.';
  }

  @override
  String get failedToOpenFile => 'باز کردن فایل ناموفق بود';

  @override
  String fileDownloadFailed(String error) {
    return 'دانلود فایل ناموفق بود: $error';
  }

  @override
  String get downloading => 'در حال دانلود...';

  @override
  String get downloadingFile => 'در حال دانلود فایل...';

  @override
  String downloadComplete(String filename) {
    return 'دانلود کامل شد: $filename';
  }

  @override
  String downloadFailed(String error) {
    return 'دانلود ناموفق بود: $error';
  }

  @override
  String get failedToDownloadPreview => 'دانلود پیش‌نمایش فایل ناموفق بود';

  @override
  String uploadComplete(String filename) {
    return 'بارگذاری کامل شد: $filename';
  }

  @override
  String uploadFailed(String error) {
    return 'بارگذاری ناموفق بود: $error';
  }

  @override
  String get failedToPickFiles => 'انتخاب فایل‌ها ناموفق بود';

  @override
  String uploadedNItems(int count) {
    return '$count مورد بارگذاری شد';
  }

  @override
  String get copiedLinkToClipboard => 'پیوند در کلیپ‌بورد کپی شد.';

  @override
  String failedToCopyLink(String error) {
    return 'کپی پیوند ناموفق بود: $error';
  }

  @override
  String get selectingAll => 'در حال انتخاب همه...';

  @override
  String get allItemsSelected => 'همه موارد انتخاب شدند.';

  @override
  String get failedToLoadSearchResults => 'بارگذاری نتایج جستجو ناموفق بود';

  @override
  String get shareNotSupportedForType =>
      'اشتراک‌گذاری برای این نوع فایل پشتیبانی نمی‌شود.';

  @override
  String nSelected(int count) {
    return '$count انتخاب شد';
  }

  @override
  String get noServerSelected => 'هیچ سروری انتخاب نشده است';

  @override
  String get pleaseConnectToServerFirst => 'لطفاً ابتدا به یک سرور متصل شوید.';

  @override
  String get signInRequired => 'ورود به سیستم لازم است';

  @override
  String pleaseSignInToServer(String serverName) {
    return 'لطفاً ابتدا وارد $serverName شوید.';
  }

  @override
  String get connectingToServer => 'در حال اتصال به سرور...';

  @override
  String connectedToServer(String serverName) {
    return 'به $serverName متصل شد.';
  }

  @override
  String connectionFailed(String error) {
    return 'اتصال ناموفق بود: $error';
  }

  @override
  String failedToConnect(String error) {
    return 'اتصال برقرار نشد: $error';
  }

  @override
  String authFailed(String error) {
    return 'احراز هویت ناموفق بود: $error';
  }

  @override
  String get authFailedGeneric =>
      'احراز هویت ناموفق بود. لطفاً دوباره امتحان کنید.';

  @override
  String biometricLoginFailed(String error) {
    return 'ورود با بیومتریک ناموفق بود: $error';
  }

  @override
  String get biometricLoginFailedGeneric => 'ورود با بیومتریک ناموفق بود.';

  @override
  String get noServerSessionToken =>
      'توکن جلسه سرور وجود ندارد. دوباره احراز هویت کنید.';

  @override
  String failedToSaveServer(String error) {
    return 'ذخیرهٔ سرور ناموفق بود: $error';
  }

  @override
  String get addToFolder => 'افزودن به پوشه';

  @override
  String get loginTabLabel => 'ورود';

  @override
  String get registerTabLabel => 'ثبت‌نام';

  @override
  String get welcomeBack => 'خوش آمدید';

  @override
  String get signInToContinue => 'برای ادامه وارد شوید';

  @override
  String get createAccount => 'ایجاد حساب کاربری';

  @override
  String get joinTheServer => 'به سرور بپیوندید';

  @override
  String get usernameLabel => 'نام کاربری';

  @override
  String get usernameHint => 'نام کاربری خود را وارد کنید';

  @override
  String get passwordLabel => 'گذرواژه';

  @override
  String get passwordHint => 'گذرواژه خود را وارد کنید';

  @override
  String get showPassword => 'نمایش گذرواژه';

  @override
  String get hidePassword => 'مخفی کردن گذرواژه';

  @override
  String get confirmPassword => 'تأیید گذرواژه';

  @override
  String get logIn => 'ورود';

  @override
  String get loggingIn => 'در حال ورود...';

  @override
  String get registering => 'در حال ثبت‌نام...';

  @override
  String get forgotPassword => 'گذرواژه را فراموش کرده‌اید؟';

  @override
  String get doNotHaveAccount => 'حساب کاربری ندارید؟ به ثبت‌نام بروید.';

  @override
  String get alreadyHaveAccount => 'قبلاً ثبت‌نام کرده‌اید؟ به ورود بروید.';

  @override
  String get usernameCannotBeEmpty => 'نام کاربری نمی‌تواند خالی باشد.';

  @override
  String get passwordCannotBeEmpty => 'گذرواژه نمی‌تواند خالی باشد.';

  @override
  String get usernameInvalid =>
      'نام کاربری باید ۳ تا ۳۲ کاراکتر شامل حروف، اعداد، _ یا - باشد.';

  @override
  String get passwordTooShort => 'گذرواژه باید حداقل ۸ کاراکتر باشد.';

  @override
  String loginFailed(String error) {
    return 'ورود ناموفق بود: $error';
  }

  @override
  String registrationFailed(String error) {
    return 'ثبت‌نام ناموفق بود: $error';
  }

  @override
  String get resetPasswordTitle => 'بازنشانی گذرواژه';

  @override
  String get enterResetCodeTitle => 'کد بازنشانی را وارد کنید';

  @override
  String get resetPasswordStep1Body =>
      'نام کاربری خود را وارد کنید. کد تأیید ۶ رقمی در لاگ‌ها/کنسول سرور چاپ خواهد شد.';

  @override
  String get resetPasswordStep2Body =>
      'کد تأیید در کنسول سرور چاپ شده است. کد ۶ رقمی و گذرواژه جدید خود را وارد کنید.';

  @override
  String get resetCodeLabel => 'کد بازنشانی';

  @override
  String get resetCodeHint => 'کد ۶ رقمی را وارد کنید';

  @override
  String get newPasswordLabel => 'گذرواژه جدید';

  @override
  String get newPasswordHint => 'گذرواژه جدید را وارد کنید';

  @override
  String get passwordResetSuccessfully => 'گذرواژه با موفقیت بازنشانی شد!';

  @override
  String get usernameIsRequired => 'نام کاربری الزامی است.';

  @override
  String get codeAndPasswordRequired => 'کد و گذرواژه جدید الزامی هستند.';

  @override
  String get failedToRequestReset =>
      'درخواست بازنشانی ناموفق بود. آدرس سرور را بررسی کنید.';

  @override
  String get failedToResetPassword =>
      'بازنشانی گذرواژه ناموفق بود. لطفاً کد را بررسی کنید.';

  @override
  String get pleaseEnterServerUrlFirst => 'لطفاً ابتدا آدرس سرور را وارد کنید.';

  @override
  String get sendCode => 'ارسال کد';

  @override
  String get settingsTitle => 'تنظیمات';

  @override
  String get sectionBackupSync => 'پشتیبان‌گیری و همگام‌سازی';

  @override
  String get sectionStorageCache => 'حافظه و حافظه پنهان';

  @override
  String get sectionSecurityBehavior => 'امنیت و رفتار';

  @override
  String get sectionAboutUpdates => 'درباره و به‌روزرسانی‌ها';

  @override
  String get sectionAppearance => 'ظاهر و شخصی‌سازی';

  @override
  String get noServersConfiguredSync => 'هیچ سروری پیکربندی نشده است';

  @override
  String get addServerBeforeSync =>
      'قبل از پیکربندی همگام‌سازی یک سرور اضافه کنید.';

  @override
  String get selectServerToConfigureSync =>
      'سروری را برای پیکربندی تنظیمات همگام‌سازی آن انتخاب کنید.';

  @override
  String get activeServerSuffix => '· فعال';

  @override
  String get folderAndCategorySync => 'همگام‌سازی پوشه‌ها و دسته‌ها';

  @override
  String get keepCategoriesSynced =>
      'همگام نگه داشتن دسته‌ها یا پوشه‌های محلی انتخاب‌شده با این سرور.';

  @override
  String get addServerBeforeSyncEnable =>
      'قبل از فعال کردن همگام‌سازی یک سرور اضافه کنید.';

  @override
  String get onlyOnWifi => 'فقط از طریق Wi-Fi';

  @override
  String get onlyWhileCharging => 'فقط هنگام شارژ';

  @override
  String get serverTargetDirectory => 'پوشه مقصد در سرور';

  @override
  String get serverTargetDirectoryHint => '/backup/mobile_phone';

  @override
  String get synchronizationFrequency => 'دوره تکرار همگام‌سازی';

  @override
  String get syncNow => 'همگام‌سازی اکنون';

  @override
  String get syncing => 'در حال همگام‌سازی...';

  @override
  String get categoriesToSynchronize => 'دسته‌ها برای همگام‌سازی';

  @override
  String get noCategoriesSelected => 'هیچ دسته‌ای انتخاب نشده است.';

  @override
  String nCategoriesSelected(int count) {
    return '$count انتخاب شد';
  }

  @override
  String get foldersToSynchronize => 'پوشه‌ها برای همگام‌سازی';

  @override
  String get noCustomFolders => 'هیچ پوشه سفارشی پیکربندی نشده است.';

  @override
  String nFolders(int count) {
    return '$count پوشه';
  }

  @override
  String get addFolder => 'افزودن پوشه';

  @override
  String get removeFolder => 'حذف پوشه';

  @override
  String get removeServer => 'حذف سرور';

  @override
  String get syncFreqEvery15Min => 'هر ۱۵ دقیقه';

  @override
  String get syncFreqEvery30Min => 'هر ۳۰ دقیقه';

  @override
  String get syncFreqEvery1Hour => 'هر ۱ ساعت';

  @override
  String syncFreqEveryNHours(int hours) {
    return 'هر $hours ساعت';
  }

  @override
  String syncFreqEveryNMin(int minutes) {
    return 'هر $minutes دقیقه';
  }

  @override
  String get syncFreqDaily => 'روزانه';

  @override
  String get chooseSyncFrequencyTitle => 'انتخاب دوره همگام‌سازی';

  @override
  String get cacheSize => 'اندازه حافظه پنهان';

  @override
  String get refreshTooltip => 'تازه‌سازی';

  @override
  String get cacheLimit => 'محدودیت حافظه پنهان';

  @override
  String get downloadPath => 'مسیر دانلود';

  @override
  String get defaultDownloadFolder => 'پوشه پیش‌فرض CrowleysCloud';

  @override
  String get clearCache => 'پاک کردن حافظه پنهان';

  @override
  String get clearCacheTitle => 'حافظه پنهان پاک شود؟';

  @override
  String get clearCacheBody =>
      'این کار تصاویر کوچک محلی و فهرست‌های کش‌شده سرور را حذف می‌کند.';

  @override
  String get downloadPathDialogTitle => 'مسیر دانلود';

  @override
  String get downloadPathHint => '/storage/emulated/0/CrowleysCloud';

  @override
  String get useDefault => 'استفاده از پیش‌فرض';

  @override
  String get serverTargetDirDialogTitle => 'پوشه مقصد در سرور';

  @override
  String get requireLogin => 'الزام ورود به سیستم';

  @override
  String get biometricLogin => 'ورود با بیومتریک';

  @override
  String get biometricLoginSubtitle =>
      'اجازه ورود با بیومتریک با استفاده از اطلاعات ذخیره‌شده.';

  @override
  String get biometricsNotAvailable => 'بیومتریک در این دستگاه در دسترس نیست.';

  @override
  String get showHiddenFiles => 'نمایش فایل‌های مخفی';

  @override
  String get showHiddenFilesSubtitle =>
      'نمایش فایل‌ها و پوشه‌هایی که با نقطه شروع می‌شوند.';

  @override
  String get changePassword => 'تغییر گذرواژه';

  @override
  String changePasswordSubtitle(String serverName) {
    return 'به‌روزرسانی گذرواژه برای $serverName.';
  }

  @override
  String get addServerBeforeChangePassword =>
      'قبل از تغییر گذرواژه یک سرور اضافه کنید.';

  @override
  String get deleteUserAccount => 'حذف حساب کاربری';

  @override
  String get deleteUserAccountSubtitle =>
      'کاربر و تمام فایل‌های ابری خصوصی حذف می‌شوند.';

  @override
  String get deleteAccountTitle => 'حساب کاربری حذف شود؟';

  @override
  String deleteAccountBody(String serverName) {
    return 'این کار حساب شما در $serverName را برای همیشه حذف کرده و تمام فایل‌های ذخیره‌شده در پوشه ابری خصوصی شما را پاک می‌کند. این عملیات غیرقابل بازگشت است.';
  }

  @override
  String get deleteAccountButton => 'حذف حساب';

  @override
  String get changePasswordDialogTitle => 'تغییر گذرواژه';

  @override
  String get newPasswordFieldLabel => 'گذرواژه جدید';

  @override
  String get confirmPasswordLabel => 'تأیید گذرواژه';

  @override
  String get enterNewPassword => 'یک گذرواژه جدید وارد کنید.';

  @override
  String get passwordUpdated => 'گذرواژه به‌روزرسانی شد.';

  @override
  String passwordChangeFailed(String error) {
    return 'تغییر گذرواژه ناموفق بود: $error';
  }

  @override
  String get passwordChangeFailedGeneric => 'تغییر گذرواژه ناموفق بود.';

  @override
  String get accountDeleted => 'حساب کاربری حذف شد.';

  @override
  String accountDeletionFailed(String error) {
    return 'حذف حساب ناموفق بود: $error';
  }

  @override
  String get accountDeletionFailedGeneric => 'حذف حساب ناموفق بود.';

  @override
  String get checkForUpdates => 'بررسی برای به‌روزرسانی';

  @override
  String get checkingForUpdates => 'در حال بررسی انتشارها در گیت‌هاب...';

  @override
  String versionLabel(String version) {
    return 'نسخه $version';
  }

  @override
  String appIsUpToDate(String version) {
    return 'برنامهٔ Crowley\'s Cloud به‌روز است (v$version).';
  }

  @override
  String get updateCheckFailed =>
      'بررسی به‌روزرسانی ناموفق بود. لطفاً بعداً دوباره امتحان کنید.';

  @override
  String get themeModeTitle => 'حالت تم';

  @override
  String get themeDark => 'تیره';

  @override
  String get themeLight => 'روشن';

  @override
  String get themeCustom => 'سفارشی';

  @override
  String get themeDarkFull => 'تم تیره';

  @override
  String get themeLightFull => 'تم روشن';

  @override
  String get themeCustomFull => 'تم سفارشی';

  @override
  String get accentColor => 'رنگ تأکیدی';

  @override
  String get primaryAccentColor => 'رنگ تأکیدی اصلی';

  @override
  String get selectAccentColor => 'انتخاب رنگ تأکیدی';

  @override
  String get backgroundColor => 'رنگ پس‌زمینه';

  @override
  String get surfaceColor => 'رنگ سطح';

  @override
  String get textColor => 'رنگ متن';

  @override
  String get subtextColor => 'رنگ متن فرعی';

  @override
  String get borderColor => 'رنگ حاشیه';

  @override
  String get fontSizeScale => 'مقیاس اندازه قلم';

  @override
  String selectColor(String title) {
    return 'انتخاب $title';
  }

  @override
  String get categoriesToSyncDialogTitle => 'دسته‌ها برای همگام‌سازی';

  @override
  String get categoriesToSyncBody =>
      'یک یا چند دسته را انتخاب کنید. خالی گذاشتن همه موارد نیز مجاز است.';

  @override
  String get syncCategorySectionMedia => 'رسانه';

  @override
  String get syncCategorySectionAudioDocs => 'صوتی و اسناد';

  @override
  String get syncCategorySectionOther => 'سایر';

  @override
  String get clearAll => 'پاک کردن همه';

  @override
  String get noSyncHasRunYet => 'هنوز همگام‌سازی انجام نشده است.';

  @override
  String lastRunAt(String date) {
    return 'آخرین اجرا $date';
  }

  @override
  String syncResultSuccess(int uploaded, int skipped) {
    return '$uploaded مورد همگام‌سازی شد، $skipped مورد نادیده گرفته شد.';
  }

  @override
  String get syncResultNoFiles => 'هیچ فایلی برای همگام‌سازی انتخاب نشده است.';

  @override
  String syncResultPartial(int uploaded, int failed) {
    return '$uploaded مورد همگام‌سازی شد، $failed مورد ناموفق بود.';
  }

  @override
  String get syncResultAuthRequired => 'قبل از همگام‌سازی وارد شوید.';

  @override
  String get syncResultUnreachable => 'سرور غیرقابل دسترس است. اتصال قطع شد.';

  @override
  String get syncResultFailed => 'همگام‌سازی ناموفق بود.';

  @override
  String get serverSetupAddServer => 'افزودن سرور';

  @override
  String get serverSetupCardTitle => 'اتصال سرور';

  @override
  String get serverSetupCardSubtitle =>
      'سرور فایل خانگی خود را اضافه کرده و وارد شوید.';

  @override
  String get serverSetupSubmitButton => 'ذخیره سرور';

  @override
  String get serverNameLabel => 'نام سرور';

  @override
  String get serverNameHint => 'Home NAS';

  @override
  String get baseUrlLabel => 'آدرس پایه';

  @override
  String get baseUrlHint => 'https://cloud.example.com';

  @override
  String get allFieldsRequired => 'تمام فیلدها الزامی هستند.';

  @override
  String get localFilesTitle => 'فایل‌های محلی';

  @override
  String get serverFilesTitle => 'فایل‌های سرور';

  @override
  String get restoreItemsTitle => 'بازیابی موارد';

  @override
  String restoreItemsBody(int count) {
    return 'آیا مطمئن هستید که می‌خواهید $count مورد را بازیابی کنید؟';
  }

  @override
  String get permanentlyDeleteTitle => 'حذف دائمی';

  @override
  String permanentlyDeleteBody(int count) {
    return 'آیا مطمئن هستید که می‌خواهید $count مورد را برای همیشه حذف کنید؟ این عملیات غیرقابل بازگشت است.';
  }

  @override
  String get trashIsEmpty => 'سطل زباله خالی است.';

  @override
  String trashRetentionInfo(int days) {
    return 'موارد موجود در سطل زباله پس از $days روز به‌طور خودکار حذف می‌شوند.';
  }

  @override
  String get deletionDate => 'تاریخ حذف';

  @override
  String get deletePermanentlyAction => 'حذف دائمی';

  @override
  String get conflictFileAlreadyExists => 'فایل از قبل وجود دارد';

  @override
  String conflictNofM(int current, int total) {
    return 'تداخل $current از $total';
  }

  @override
  String get conflictAFileNamed => 'فایلی با نام ';

  @override
  String get conflictAlreadyExistsAt => ' از قبل وجود دارد در ';

  @override
  String get conflictAlreadyExistsInFolder => ' از قبل در این پوشه وجود دارد.';

  @override
  String get conflictInFolder => 'در پوشه';

  @override
  String get conflictFromTrash => 'از سطل زباله';

  @override
  String get conflictExisting => 'موجود';

  @override
  String get conflictNewUpload => 'بارگذاری جدید';

  @override
  String conflictSizeLabel(String size) {
    return 'اندازه: $size';
  }

  @override
  String conflictDateLabel(String date) {
    return 'تاریخ: $date';
  }

  @override
  String conflictDeletedLabel(String date) {
    return 'حذف‌شده: $date';
  }

  @override
  String conflictApplyToRemaining(int count) {
    return 'اعمال برای تداخل‌های باقی‌مانده ($count)';
  }

  @override
  String get conflictKeepAllCopies => 'نگه‌داشتن تمام کپی‌ها';

  @override
  String get conflictOverwriteAll => 'جایگزینی همه';

  @override
  String get conflictRestoreAllAsCopies => 'بازیابی همه به عنوان کپی';

  @override
  String get conflictRestoreAsCopy => 'بازیابی به عنوان کپی';

  @override
  String get conflictOverwriteAllRemaining => 'جایگزینی تمام موارد باقی‌مانده';

  @override
  String get conflictSkipAll => 'رد شدن از همه';

  @override
  String get conflictSkipAllRemaining => 'رد شدن از تمام موارد باقی‌مانده';

  @override
  String get conflictSkip => 'رد شدن';

  @override
  String get conflictOverwrite => 'جایگزینی';

  @override
  String get transfersTitle => 'انتقال‌ها';

  @override
  String get transferResume => 'ادامه';

  @override
  String get transferPause => 'توقف موقت';

  @override
  String get transferCancel => 'لغو';

  @override
  String get transferResumeAll => 'ادامه همه';

  @override
  String get transferPauseAll => 'توقف موقت همه';

  @override
  String get transferCancelAll => 'لغو همه';

  @override
  String get transferCancelFile => 'لغو فایل';

  @override
  String get noTransfers => 'هیچ انتقالی وجود ندارد.';

  @override
  String get transferStatusQueued => 'در صف';

  @override
  String get transferStatusRunning => 'در حال اجرا';

  @override
  String get transferStatusPaused => 'متوقف‌شده';

  @override
  String get transferStatusCompleted => 'تکمیل‌شده';

  @override
  String get transferStatusFailed => 'ناموفق';

  @override
  String get transferStatusCanceled => 'لغوشده';

  @override
  String get themePresetsSection => 'پیش‌تنظیم‌ها';

  @override
  String get themeCustomPaletteSection => 'پالت سفارشی';

  @override
  String get themeHexRgbLabel => 'کد HEX RGB';

  @override
  String get themeHexRgbHint => '#FA5252';

  @override
  String get imageViewerNoFetchHandler =>
      'هیچ کنترل‌کننده دریافتی پیکربندی نشده است';

  @override
  String get imageViewerFailedToLoad => 'بارگذاری تصویر ناموفق بود';

  @override
  String errorDeletingFile(String filename, String error) {
    return 'خطا در حذف $filename: $error';
  }

  @override
  String errorReadingFile(String error) {
    return 'خطا در خواندن فایل: $error';
  }

  @override
  String get syncChannelName => 'همگام‌سازی در پس‌زمینه';

  @override
  String get syncChannelDescription =>
      'وضعیت فایل‌های در حال همگام‌سازی در پس‌زمینه را نشان می‌دهد.';

  @override
  String get storageStatsTitle => 'آمار حافظه';

  @override
  String get storageStatsUsedSpace => 'فضای استفاده‌شده';

  @override
  String get storageStatsTotalFiles => 'کل فایل‌ها';

  @override
  String storageStatsNItems(int count) {
    return '$count مورد';
  }

  @override
  String userFallback(int userId) {
    return 'کاربر #$userId';
  }

  @override
  String get biometricUnlockReason =>
      'باز کردن اطلاعات ذخیره‌شده برای Crowley\'s Cloud.';

  @override
  String get tokenLifetimeEveryOpen => 'هر بار باز کردن برنامه';

  @override
  String get tokenLifetimeOneHour => 'پس از ۱ ساعت';

  @override
  String get tokenLifetime1Hour => 'پس از ۱ ساعت';

  @override
  String get tokenLifetimeOneDay => 'پس از ۱ روز';

  @override
  String get tokenLifetime1Day => 'پس از ۱ روز';

  @override
  String get tokenLifetimeOneWeek => 'پس از ۱ هفته';

  @override
  String get tokenLifetime1Week => 'پس از ۱ هفته';

  @override
  String get tokenLifetimeOneMonth => 'پس از ۱ ماه';

  @override
  String get tokenLifetime1Month => 'پس از ۱ ماه';

  @override
  String get tokenLifetimeThreeMonths => 'پس از ۳ ماه';

  @override
  String get tokenLifetime3Months => 'پس از ۳ ماه';

  @override
  String get tokenLifetimeNever => 'هرگز در این دستگاه';

  @override
  String get cacheLimitUnlimited => 'نامحدود';

  @override
  String get syncCategoryOtherFiles => 'سایر فایل‌ها';

  @override
  String get internalStorage => 'حافظه داخلی';

  @override
  String get localStorageRootName => 'حافظه داخلی';

  @override
  String syncNotificationSyncingWith(String serverName) {
    return 'در حال همگام‌سازی با $serverName';
  }

  @override
  String syncNotificationPausedTitle(String serverName) {
    return 'همگام‌سازی با $serverName متوقف شد';
  }

  @override
  String get syncNotificationUnreachableBody =>
      'سرور غیرقابل دسترس است. همگام‌سازی پس‌زمینه تا باز شدن برنامه متوقف شد.';

  @override
  String get syncNotificationAuthRequiredBody =>
      'احراز هویت لازم است. برای ورود برنامه را باز کنید.';

  @override
  String syncNotificationFailedTitle(String serverName) {
    return 'همگام‌سازی با $serverName ناموفق بود';
  }

  @override
  String get syncNotificationGenericErrorBody =>
      'در حین همگام‌سازی خطایی رخ داد.';

  @override
  String syncNotificationCompleteTitle(String serverName) {
    return 'همگام‌سازی با $serverName کامل شد';
  }

  @override
  String get syncNotificationCompleteBody => 'همگام‌سازی کامل شد.';

  @override
  String get syncStatusConnecting => 'در حال اتصال به سرور...';

  @override
  String syncStatusConnectionLost(String serverName) {
    return 'امکان اتصال به $serverName وجود نداشت. اتصال قطع شد.';
  }

  @override
  String syncResultServerUnreachableWithServer(String serverName) {
    return 'امکان اتصال به $serverName وجود نداشت. اتصال قطع شد.';
  }

  @override
  String get syncStatusScanningFiles => 'در حال بررسی فایل‌ها در دستگاه...';

  @override
  String get syncStatusNoFilesFound => 'هیچ فایلی برای همگام‌سازی یافت نشد.';

  @override
  String get syncStatusNoFilesSelected =>
      'هیچ فایلی برای همگام‌سازی انتخاب نشده است.';

  @override
  String syncStatusCalculatingChecksum(
    int current,
    int total,
    String filename,
  ) {
    return 'محاسبه چکسام ($current/$total): $filename';
  }

  @override
  String get syncStatusCheckingDuplicates =>
      'در حال بررسی موارد تکراری در سرور...';

  @override
  String syncStatusSyncingFile(int current, int total, String filename) {
    return 'در حال همگام‌سازی ($current/$total): $filename';
  }

  @override
  String get syncStatusCompleting => 'در حال تکمیل همگام‌سازی...';

  @override
  String get showingCachedFiles => 'نمایش فایل‌های ذخیره‌شده در حافظه پنهان.';

  @override
  String get showingCachedFilesRefreshFailed =>
      'نمایش فایل‌های ذخیره‌شده در حافظه پنهان. تازه‌سازی ناموفق بود.';

  @override
  String get downloadCanceled => 'دانلود لغو شد.';

  @override
  String downloadedNFilesToPath(int count, String path) {
    return '$count فایل در $path دانلود شد';
  }

  @override
  String downloadedNFilesFailedM(int downloaded, int failed, String detail) {
    return '$downloaded فایل دانلود شد، $failed مورد ناموفق: $detail';
  }

  @override
  String downloadedNFilesWithFailures(int count, int failed, String error) {
    return '$count فایل دانلود شد، $failed مورد ناموفق: $error';
  }

  @override
  String createdNShareLinks(int count) {
    return '$count پیوند اشتراک‌گذاری ایجاد شد.';
  }

  @override
  String get failedToCreateShareLinks =>
      'ایجاد پیوند(های) اشتراک‌گذاری ناموفق بود.';

  @override
  String get alreadyInSharedScope => 'قبلاً در محدوده مشترک قرار گرفته است.';

  @override
  String sharedNItemsInServer(int count) {
    return '$count مورد در سرور به اشتراک گذاشته شد.';
  }

  @override
  String sharedNItemsWithFailures(int count, int failed) {
    return '$count مورد به اشتراک گذاشته شد، $failed مورد ناموفق بود.';
  }

  @override
  String sharedNItemsFailedM(int shared, int failed) {
    return '$shared مورد به اشتراک گذاشته شد، $failed مورد ناموفق بود.';
  }

  @override
  String get folderNameCannotBeEmpty => 'نام پوشه نمی‌تواند خالی باشد.';

  @override
  String get folderAlreadyExists => 'پوشه از قبل وجود دارد.';

  @override
  String get folderCreationOnlyInAllFiles =>
      'ایجاد پوشه فقط در بخش همه فایل‌ها امکان‌پذیر است.';

  @override
  String get currentDirectoryUnavailable => 'پوشه فعلی در دسترس نیست.';

  @override
  String get nothingSelected => 'هیچ موردی انتخاب نشده است.';

  @override
  String get destinationFolderDoesNotExist => 'پوشه مقصد وجود ندارد.';

  @override
  String cannotMoveFolderIntoItself(String name) {
    return 'نمی‌توان پوشه \"$name\" را به داخل خودش منتقل کرد.';
  }

  @override
  String failedToMoveItem(String name, String error) {
    return 'انتقال $name ناموفق بود: $error';
  }

  @override
  String movedNItems(int count) {
    return '$count مورد منتقل شد.';
  }

  @override
  String movedNItemsWithFailures(int count, int failed) {
    return '$count مورد منتقل شد، $failed مورد ناموفق بود.';
  }

  @override
  String movedNItemsFailedM(int moved, int failed) {
    return '$moved مورد منتقل شد، $failed مورد ناموفق بود.';
  }

  @override
  String get failedToMoveSelectedItems => 'انتقال موارد انتخاب‌شده ناموفق بود.';

  @override
  String get noFilesWereMoved => 'هیچ فایلی منتقل نشد.';

  @override
  String renamedOldToNew(String oldName, String newName) {
    return 'نام \"$oldName\" به \"$newName\" تغییر یافت.';
  }

  @override
  String renamedFileFromTo(String oldName, String newName) {
    return 'نام \"$oldName\" به \"$newName\" تغییر یافت.';
  }

  @override
  String failedToRenameWithStatus(String name, int statusCode) {
    return 'تغییر نام \"$name\" ناموفق بود ($statusCode).';
  }

  @override
  String failedToRenameFileWithCode(String name, int statusCode) {
    return 'تغییر نام \"$name\" ناموفق بود ($statusCode).';
  }

  @override
  String failedToRenameWithError(String name, String error) {
    return 'تغییر نام \"$name\" ناموفق بود: $error';
  }

  @override
  String failedToRenameFile(String name, String error) {
    return 'تغییر نام \"$name\" ناموفق بود: $error';
  }

  @override
  String get renameConflictAlreadyExists =>
      'تغییر نام ناموفق بود: فایل یا پوشه‌ای با این نام از قبل وجود دارد.';

  @override
  String get renameFailedAlreadyExists =>
      'تغییر نام ناموفق بود: فایل یا پوشه‌ای با این نام از قبل وجود دارد.';

  @override
  String failedToCreateFolderWithCode(int statusCode) {
    return 'ایجاد پوشه ناموفق بود ($statusCode).';
  }

  @override
  String deletedNItemsFailedM(int deleted, int failed) {
    return '$deleted مورد حذف شد، $failed مورد ناموفق بود.';
  }

  @override
  String transferSummaryFiles(int percent, int completed, int total) {
    return '$percent٪  $completed/$total فایل';
  }

  @override
  String transferSummaryProgress(int percent, int completed, int total) {
    return '$percent٪  $completed/$total';
  }

  @override
  String get downloadFailedGeneric => 'دانلود ناموفق بود';

  @override
  String uploadedNItemsWithFailures(int uploaded, int failed) {
    return '$uploaded مورد بارگذاری شد، $failed مورد ناموفق بود';
  }

  @override
  String uploadedNItemsFailedM(int uploaded, int failed) {
    return '$uploaded مورد بارگذاری شد، $failed مورد ناموفق بود.';
  }

  @override
  String uploadSummaryFailedCount(int count) {
    return '، $count مورد ناموفق';
  }

  @override
  String uploadLocalPathEmpty(String name) {
    return '$name: مسیر محلی خالی است';
  }

  @override
  String uploadErrorLocalPathEmpty(String name) {
    return '$name: مسیر محلی خالی است';
  }

  @override
  String get directoryUploadFailed => 'بارگذاری پوشه ناموفق بود';

  @override
  String get uploadDirectoryFailed => 'بارگذاری پوشه ناموفق بود';

  @override
  String get localFileNotFound => 'فایل محلی یافت نشد';

  @override
  String get uploadErrorLocalFileNotFound => 'فایل محلی یافت نشد';

  @override
  String get noSessionToken => 'هیچ توکن جلسه فعالی وجود ندارد';

  @override
  String get uploadErrorNoSessionToken => 'هیچ توکن جلسه فعالی وجود ندارد';

  @override
  String get serverDisconnectedStatus => 'ارتباط با سرور قطع شد';

  @override
  String get serverDisconnected => 'ارتباط با سرور قطع شد';

  @override
  String get serverIsUnreachable => 'سرور غیرقابل دسترس است.';

  @override
  String get serverUnreachable => 'سرور غیرقابل دسترس است.';

  @override
  String get uploadErrorLocalDirectoryNotFound => 'پوشه محلی یافت نشد';

  @override
  String get uploadErrorFailedToScanDirectory => 'بررسی پوشه ناموفق بود';

  @override
  String uploadErrorFolderCreateHttp(int statusCode) {
    return 'ایجاد پوشه ناموفق بود (HTTP $statusCode)';
  }

  @override
  String get authErrorMissingAccessToken => 'توکن دسترسی در پاسخ وجود ندارد';

  @override
  String get authErrorMissingRefreshToken =>
      'توکن تازه‌سازی در پاسخ وجود ندارد';

  @override
  String get authErrorNoSavedCredentials =>
      'هیچ اطلاعات ذخیره‌شده‌ای موجود نیست';

  @override
  String get authErrorNoRefreshToken => 'هیچ توکن تازه‌سازی موجود نیست';

  @override
  String get authErrorNoActiveSession => 'هیچ جلسه فعالی در دسترس نیست';

  @override
  String get authErrorNoSavedUsername =>
      'هیچ نام کاربری ذخیره‌شده‌ای موجود نیست';

  @override
  String get updateNoReleasesPublished => 'هنوز هیچ نسخه‌ای منتشر نشده است.';

  @override
  String get language => 'زبان';
}
