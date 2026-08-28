// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Crowley\'s Cloud';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get rename => 'إعادة تسمية';

  @override
  String get close => 'إغلاق';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get loading => 'جارٍ التحميل...';

  @override
  String get confirm => 'تأكيد';

  @override
  String get error => 'خطأ';

  @override
  String errorWithMessage(String message) {
    return 'خطأ: $message';
  }

  @override
  String get unknown => 'غير معروف';

  @override
  String get upload => 'رفع';

  @override
  String get download => 'تنزيل';

  @override
  String get share => 'مشاركة';

  @override
  String get copy => 'نسخ';

  @override
  String get move => 'نقل';

  @override
  String get restore => 'استعادة';

  @override
  String get apply => 'تطبيق';

  @override
  String get create => 'إنشاء';

  @override
  String get clear => 'مسح';

  @override
  String get add => 'إضافة';

  @override
  String get remove => 'إزالة';

  @override
  String get edit => 'تعديل';

  @override
  String get switchLabel => 'تبديل';

  @override
  String get search => 'بحث';

  @override
  String get name => 'الاسم';

  @override
  String get date => 'التاريخ';

  @override
  String get size => 'الحجم';

  @override
  String get type => 'النوع';

  @override
  String get ascending => 'تصاعدي';

  @override
  String get descending => 'تنازلي';

  @override
  String get allFiles => 'الكل';

  @override
  String get categoryImages => 'الصور';

  @override
  String get categoryPhotos => 'الصور';

  @override
  String get categoryVideos => 'الفيديوهات';

  @override
  String get categoryAudio => 'الصوتيات';

  @override
  String get categoryDocuments => 'المستندات';

  @override
  String get categoryArchives => 'الأرشيفات';

  @override
  String get categoryShared => 'مشتركة';

  @override
  String get categoryOther => 'أخرى';

  @override
  String get categoryOtherFiles => 'ملفات أخرى';

  @override
  String get noFilesFound => 'لم يتم العثور على أي ملفات.';

  @override
  String get noFilesInFolder => 'لا توجد ملفات في هذا المجلد.';

  @override
  String get thisActionCannotBeUndone => 'لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get navLocalFiles => 'الملفات المحلية';

  @override
  String get navServerFiles => 'ملفات الخادم';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get navTrash => 'سلة المهملات';

  @override
  String get navLocal => 'محلي';

  @override
  String get navServer => 'الخادم';

  @override
  String get addServer => 'إضافة خادم';

  @override
  String get noServersConfigured => 'لم يتم تكوين أي خوادم.';

  @override
  String get addAServerInSettings => 'أضف خادمًا في الإعدادات.';

  @override
  String get addFirstServerHint => 'أضف خادمك الأول للمتابعة.';

  @override
  String get noServersConfiguredYet => 'لم يتم تكوين أي خوادم بعد.';

  @override
  String get crowleysCloudSetup => 'إعداد Crowley\'s Cloud';

  @override
  String get connect => 'اتصال';

  @override
  String get connecting => 'جارٍ الاتصال...';

  @override
  String get connected => 'متصل';

  @override
  String get disconnected => 'غير متصل';

  @override
  String get switchServer => 'تبديل الخادم';

  @override
  String get chooseOtherServer => 'اختيار خادم آخر';

  @override
  String get switchServerTitle => 'تبديل الخادم؟';

  @override
  String switchServerBody(String serverName) {
    return 'تبديل الخادم النشط إلى \"$serverName\"؟';
  }

  @override
  String get chooseServer => 'اختيار خادم';

  @override
  String get authenticationRequired => 'المصادقة مطلوبة';

  @override
  String signInToAccess(String serverName) {
    return 'سجّل الدخول للوصول إلى الملفات على $serverName';
  }

  @override
  String get signInWithPassword => 'تسجيل الدخول بكلمة المرور';

  @override
  String get useBiometrics => 'استخدام البصمة';

  @override
  String get openingSignIn => 'جارٍ فتح تسجيل الدخول...';

  @override
  String get serverConnectionFailed => 'فشل الاتصال بالخادم';

  @override
  String get unableToConnectToServer => 'تعذر الاتصال بالخادم النشط.';

  @override
  String unableToConnectTo(String serverName) {
    return 'تعذر الاتصال بـ $serverName.';
  }

  @override
  String get searchHint => 'بحث...';

  @override
  String get searchFilesHint => 'بحث في الملفات...';

  @override
  String get searchServerFilesHint => 'بحث في ملفات الخادم...';

  @override
  String get searchTrashHint => 'بحث في سلة المهملات...';

  @override
  String get storagePermissionRequired => 'إذن التخزين مطلوب';

  @override
  String get grantPermission => 'منح الإذن';

  @override
  String get permissionDeniedOpenSettings =>
      'تم رفض الإذن. يرجى منح إذن الوصول إلى التخزين في الإعدادات.';

  @override
  String get manageStoragePermissionRequired =>
      'مطلوب إذن إدارة التخزين لتصفح المجلدات واختيارها.';

  @override
  String get storagePermissionsRequired =>
      'مطلوب أذونات التخزين لإجراء المزامنة.';

  @override
  String updateAvailableTitle(String version) {
    return 'يتوفر تحديث: v$version';
  }

  @override
  String get updateAvailableTapToSeeNew => 'انقر لمعرفة الجديد';

  @override
  String get updateView => 'عرض';

  @override
  String get updateAvailableDialogTitle => 'يتوفر تحديث';

  @override
  String updateVersionSubtitle(String version) {
    return 'الإصدار $version';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'الحالي: v$version';
  }

  @override
  String updateNewVersion(String version) {
    return 'الجديد: v$version';
  }

  @override
  String get updateWhatsNew => 'ما الجديد:';

  @override
  String get updateGitHub => 'GitHub';

  @override
  String get updateNoReleaseNotes => 'لا تتوفر ملاحظات الإصدار.';

  @override
  String get updateLater => 'لاحقًا';

  @override
  String get updateDownloadApk => 'تنزيل APK';

  @override
  String get updateInstall => 'تحديث';

  @override
  String get shareLinkTitle => 'مشاركة الرابط';

  @override
  String get shareViaLink => 'مشاركة عبر رابط';

  @override
  String get shareInServer => 'مشاركة على الخادم';

  @override
  String get expiryDays => 'الصلاحية (أيام)';

  @override
  String get expiryNever => 'أبدًا';

  @override
  String get expiry1Day => 'يوم واحد';

  @override
  String get expiry7Days => '7 أيام';

  @override
  String get expiry30Days => '30 يومًا';

  @override
  String get expiry90Days => '90 يومًا';

  @override
  String get expiry180Days => '180 يومًا';

  @override
  String get expiry365Days => '365 يومًا';

  @override
  String get createLink => 'إنشاء رابط';

  @override
  String get sharedLinkCopied => 'تم نسخ رابط المشاركة إلى الحافظة!';

  @override
  String failedToCopySharedLink(String error) {
    return 'فشل نسخ رابط المشاركة: $error';
  }

  @override
  String get cannotShareThisFileType => 'لا يمكن مشاركة هذا النوع من الملفات.';

  @override
  String failedToCreateShare(String error) {
    return 'فشل إنشاء المشاركة: $error';
  }

  @override
  String get newFolderTitle => 'إنشاء مجلد';

  @override
  String get newFolderHint => 'اسم المجلد';

  @override
  String get newFolder => 'مجلد جديد';

  @override
  String get folderCreated => 'تم إنشاء المجلد.';

  @override
  String failedToCreateFolder(String error) {
    return 'فشل إنشاء المجلد: $error';
  }

  @override
  String get creatingFolder => 'جارٍ إنشاء المجلد...';

  @override
  String get renameDialogTitle => 'إعادة تسمية';

  @override
  String get renameHint => 'الاسم الجديد';

  @override
  String get enterNewName => 'أدخل الاسم الجديد';

  @override
  String get renamedSuccessfully => 'تمت إعادة التسمية بنجاح.';

  @override
  String renameFailed(String error) {
    return 'فشلت إعادة التسمية: $error';
  }

  @override
  String get moveDialogTitle => 'نقل إلى';

  @override
  String moveTo(String path) {
    return 'نقل إلى: $path';
  }

  @override
  String get moveHere => 'نقل إلى هنا';

  @override
  String moveFailed(String error) {
    return 'فشل النقل: $error';
  }

  @override
  String get movedToFolder => 'تم النقل إلى المجلد.';

  @override
  String copyFailed(String error) {
    return 'فشل النسخ: $error';
  }

  @override
  String get selectFolder => 'تحديد مجلد';

  @override
  String get useThisFolder => 'استخدام هذا المجلد';

  @override
  String get storageRoot => 'وحدة التخزين';

  @override
  String get serverRoot => 'الجذر';

  @override
  String deleteNItemsTitle(int count) {
    return 'حذف $count عنصر؟';
  }

  @override
  String get deleteFilesTitle => 'حذف الملفات؟';

  @override
  String deleteFilesBody(int count) {
    return 'هل أنت متأكد من رغبتك في حذف $count عنصر محدد؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get deletePermanently => 'حذف نهائي';

  @override
  String get deletePermanentlyTitle => 'حذف نهائي؟';

  @override
  String deletePermanentlyBody(String filename) {
    return 'سيتم حذف $filename نهائيًا.';
  }

  @override
  String get deleteFileTitle => 'حذف الملف؟';

  @override
  String deleteFileBody(String filename) {
    return 'هل أنت متأكد من رغبتك في حذف $filename؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get deleteServerFileTitle => 'حذف نهائي';

  @override
  String deleteServerFileBody(String filename) {
    return 'هل أنت متأكد من رغبتك في حذف \"$filename\" نهائيًا؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get unshareItemsTitle => 'إلغاء مشاركة العناصر؟';

  @override
  String unshareItemsBody(int count) {
    return 'هل أنت متأكد من رغبتك في إلغاء مشاركة $count عنصر محدد؟ سيؤدي هذا إلى إزالتها من مجلد المشتركة.';
  }

  @override
  String get unshare => 'إلغاء المشاركة';

  @override
  String get moveToTrash => 'نقل إلى سلة المهملات';

  @override
  String get movedToTrash => 'تم النقل إلى سلة المهملات.';

  @override
  String movedNItemsToTrash(int count) {
    return 'تم نقل $count عنصر إلى سلة المهملات.';
  }

  @override
  String failedToMoveToTrash(String error) {
    return 'فشل النقل إلى سلة المهملات: $error';
  }

  @override
  String deletedNItems(int count) {
    return 'تم حذف $count عنصر.';
  }

  @override
  String failedToDelete(String error) {
    return 'فشل الحذف: $error';
  }

  @override
  String failedToDeleteItem(String error) {
    return 'فشل الحذف: $error';
  }

  @override
  String deletedFilename(String filename) {
    return 'تم حذف $filename.';
  }

  @override
  String get failedToOpenFile => 'تعذر فتح الملف';

  @override
  String fileDownloadFailed(String error) {
    return 'فشل تنزيل الملف: $error';
  }

  @override
  String get downloading => 'جارٍ التنزيل...';

  @override
  String get downloadingFile => 'جارٍ تنزيل الملف...';

  @override
  String downloadComplete(String filename) {
    return 'اكتمل التنزيل: $filename';
  }

  @override
  String downloadFailed(String error) {
    return 'فشل التنزيل: $error';
  }

  @override
  String get failedToDownloadPreview => 'فشل تنزيل معاينة الملف';

  @override
  String uploadComplete(String filename) {
    return 'اكتمل الرفع: $filename';
  }

  @override
  String uploadFailed(String error) {
    return 'فشل الرفع: $error';
  }

  @override
  String get failedToPickFiles => 'فشل اختيار الملفات';

  @override
  String uploadedNItems(int count) {
    return 'تم رفع $count عنصر';
  }

  @override
  String get copiedLinkToClipboard => 'تم نسخ الرابط إلى الحافظة.';

  @override
  String failedToCopyLink(String error) {
    return 'فشل نسخ الرابط: $error';
  }

  @override
  String get selectingAll => 'جارٍ تحديد الكل...';

  @override
  String get allItemsSelected => 'تم تحديد جميع العناصر.';

  @override
  String get failedToLoadSearchResults => 'فشل تحميل نتائج البحث';

  @override
  String get shareNotSupportedForType =>
      'المشاركة غير مدعومة لهذا النوع من الملفات.';

  @override
  String nSelected(int count) {
    return 'تم تحديد $count';
  }

  @override
  String get noServerSelected => 'لم يتم تحديد أي خادم';

  @override
  String get pleaseConnectToServerFirst => 'يرجى الاتصال بالخادم أولاً.';

  @override
  String get signInRequired => 'تسجيل الدخول مطلوب';

  @override
  String pleaseSignInToServer(String serverName) {
    return 'يرجى تسجيل الدخول إلى $serverName أولاً.';
  }

  @override
  String get connectingToServer => 'جارٍ الاتصال بالخادم...';

  @override
  String connectedToServer(String serverName) {
    return 'تم الاتصال بـ $serverName.';
  }

  @override
  String connectionFailed(String error) {
    return 'فشل الاتصال: $error';
  }

  @override
  String failedToConnect(String error) {
    return 'فشل الاتصال: $error';
  }

  @override
  String authFailed(String error) {
    return 'فشلت المصادقة: $error';
  }

  @override
  String get authFailedGeneric => 'فشلت المصادقة. يرجى المحاولة مرة أخرى.';

  @override
  String biometricLoginFailed(String error) {
    return 'فشل تسجيل الدخول بالبصمة: $error';
  }

  @override
  String get biometricLoginFailedGeneric => 'فشل تسجيل الدخول بالبصمة.';

  @override
  String get noServerSessionToken =>
      'لا يوجد رمز جلسة للخادم. أعد مصادقة الخادم.';

  @override
  String failedToSaveServer(String error) {
    return 'فشل حفظ الخادم: $error';
  }

  @override
  String get addToFolder => 'إضافة إلى المجلد';

  @override
  String get loginTabLabel => 'تسجيل الدخول';

  @override
  String get registerTabLabel => 'إنشاء حساب';

  @override
  String get welcomeBack => 'مرحبًا بعودتك';

  @override
  String get signInToContinue => 'سجّل الدخول للمتابعة';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get joinTheServer => 'الانضمام إلى الخادم';

  @override
  String get usernameLabel => 'اسم المستخدم';

  @override
  String get usernameHint => 'أدخل اسم المستخدم';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get passwordHint => 'أدخل كلمة المرور';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get logIn => 'تسجيل الدخول';

  @override
  String get loggingIn => 'جارٍ تسجيل الدخول...';

  @override
  String get registering => 'جارٍ إنشاء الحساب...';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get doNotHaveAccount => 'ليس لديك حساب؟ انتقل إلى إنشاء حساب.';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟ انتقل إلى تسجيل الدخول.';

  @override
  String get usernameCannotBeEmpty => 'لا يمكن أن يكون اسم المستخدم فارغًا.';

  @override
  String get passwordCannotBeEmpty => 'لا يمكن أن تكون كلمة المرور فارغة.';

  @override
  String get usernameInvalid =>
      'يجب أن يتراوح اسم المستخدم بين 3 و32 حرفًا أو رقمًا أو _ أو -.';

  @override
  String get passwordTooShort => 'يجب ألا تقل كلمة المرور عن 8 أحرف.';

  @override
  String loginFailed(String error) {
    return 'فشل تسجيل الدخول: $error';
  }

  @override
  String registrationFailed(String error) {
    return 'فشل إنشاء الحساب: $error';
  }

  @override
  String get resetPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get enterResetCodeTitle => 'أدخل رمز إعادة التعيين';

  @override
  String get resetPasswordStep1Body =>
      'أدخل اسم المستخدم الخاص بك. ستتم طباعة رمز التحقق المكون من 6 أرقام في سجلات/وحدة تحكم الخادم.';

  @override
  String get resetPasswordStep2Body =>
      'تمت طباعة رمز التحقق في وحدة تحكم الخادم. أدخل الرمز المكون من 6 أرقام وكلمة المرور الجديدة.';

  @override
  String get resetCodeLabel => 'رمز إعادة التعيين';

  @override
  String get resetCodeHint => 'أدخل الرمز المكون من 6 أرقام';

  @override
  String get newPasswordLabel => 'كلمة المرور الجديدة';

  @override
  String get newPasswordHint => 'أدخل كلمة المرور الجديدة';

  @override
  String get passwordResetSuccessfully => 'تمت إعادة تعيين كلمة المرور بنجاح!';

  @override
  String get usernameIsRequired => 'اسم المستخدم مطلوب.';

  @override
  String get codeAndPasswordRequired => 'الرمز وكلمة المرور الجديدة مطلوبان.';

  @override
  String get failedToRequestReset =>
      'فشل طلب إعادة التعيين. تحقق من عنوان URL للخادم.';

  @override
  String get failedToResetPassword =>
      'فشلت إعادة تعيين كلمة المرور. يرجى التحقق من الرمز.';

  @override
  String get pleaseEnterServerUrlFirst => 'يرجى إدخال عنوان URL للخادم أولاً.';

  @override
  String get sendCode => 'إرسال الرمز';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get sectionBackupSync => 'النسخ الاحتياطي والمزامنة';

  @override
  String get sectionStorageCache => 'التخزين وذاكرة التخزين المؤقت';

  @override
  String get sectionSecurityBehavior => 'الأمان والسلوك';

  @override
  String get sectionAboutUpdates => 'حول التطبيق والتحديثات';

  @override
  String get sectionAppearance => 'المظهر والتخصيص';

  @override
  String get noServersConfiguredSync => 'لم يتم تكوين أي خوادم';

  @override
  String get addServerBeforeSync => 'أضف خادمًا قبل تكوين المزامنة.';

  @override
  String get selectServerToConfigureSync =>
      'حدد خادمًا لتكوين إعدادات المزامنة الخاصة به.';

  @override
  String get activeServerSuffix => '· نشط';

  @override
  String get folderAndCategorySync => 'مزامنة المجلدات والفئات';

  @override
  String get keepCategoriesSynced =>
      'إبقاء الفئات أو المجلدات المحلية المحددة متزامنة مع هذا الخادم.';

  @override
  String get addServerBeforeSyncEnable => 'أضف خادمًا قبل تمكين المزامنة.';

  @override
  String get onlyOnWifi => 'عبر Wi-Fi فقط';

  @override
  String get onlyWhileCharging => 'أثناء الشحن فقط';

  @override
  String get serverTargetDirectory => 'دليل الخادم المستهدف';

  @override
  String get serverTargetDirectoryHint => '/backup/mobile_phone';

  @override
  String get synchronizationFrequency => 'تكرار المزامنة';

  @override
  String get syncNow => 'مزامنة الآن';

  @override
  String get syncing => 'جارٍ المزامنة...';

  @override
  String get categoriesToSynchronize => 'الفئات المراد مزامنتها';

  @override
  String get noCategoriesSelected => 'لم يتم تحديد أي فئات.';

  @override
  String nCategoriesSelected(int count) {
    return 'تم تحديد $count';
  }

  @override
  String get foldersToSynchronize => 'المجلدات المراد مزامنتها';

  @override
  String get noCustomFolders => 'لم يتم تكوين أي مجلدات مخصصة.';

  @override
  String nFolders(int count) {
    return '$count مجلد';
  }

  @override
  String get addFolder => 'إضافة مجلد';

  @override
  String get removeFolder => 'إزالة مجلد';

  @override
  String get removeServer => 'إزالة الخادم';

  @override
  String get syncFreqEvery15Min => 'كل 15 دقيقة';

  @override
  String get syncFreqEvery30Min => 'كل 30 دقيقة';

  @override
  String get syncFreqEvery1Hour => 'كل ساعة';

  @override
  String syncFreqEveryNHours(int hours) {
    return 'كل $hours ساعات';
  }

  @override
  String syncFreqEveryNMin(int minutes) {
    return 'كل $minutes دقيقة';
  }

  @override
  String get syncFreqDaily => 'يوميًا';

  @override
  String get chooseSyncFrequencyTitle => 'اختيار تكرار المزامنة';

  @override
  String get cacheSize => 'حجم ذاكرة التخزين المؤقت';

  @override
  String get refreshTooltip => 'تحديث';

  @override
  String get cacheLimit => 'حد ذاكرة التخزين المؤقت';

  @override
  String get downloadPath => 'مسار التنزيل';

  @override
  String get defaultDownloadFolder => 'مجلد CrowleysCloud الافتراضي';

  @override
  String get clearCache => 'مسح الذاكرة المؤقتة';

  @override
  String get clearCacheTitle => 'مسح ذاكرة التخزين المؤقت؟';

  @override
  String get clearCacheBody =>
      'سيؤدي هذا إلى إزالة الصور المصغرة المحلية وقوائم الخادم المخزنة مؤقتًا.';

  @override
  String get downloadPathDialogTitle => 'مسار التنزيل';

  @override
  String get downloadPathHint => '/storage/emulated/0/CrowleysCloud';

  @override
  String get useDefault => 'استخدام الافتراضي';

  @override
  String get serverTargetDirDialogTitle => 'دليل الخادم المستهدف';

  @override
  String get requireLogin => 'طلب تسجيل الدخول';

  @override
  String get biometricLogin => 'تسجيل الدخول بالبصمة';

  @override
  String get biometricLoginSubtitle =>
      'السماح بتسجيل الدخول باستخدام بيانات الاعتماد المحفوظة عبر البصمة.';

  @override
  String get biometricsNotAvailable =>
      'القياسات الحيوية غير متوفرة على هذا الجهاز.';

  @override
  String get showHiddenFiles => 'إظهار الملفات المخفية';

  @override
  String get showHiddenFilesSubtitle =>
      'عرض الملفات والمجلدات التي تبدأ بنقطة.';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String changePasswordSubtitle(String serverName) {
    return 'تحديث كلمة المرور لـ $serverName.';
  }

  @override
  String get addServerBeforeChangePassword =>
      'أضف خادمًا قبل تغيير كلمة المرور.';

  @override
  String get deleteUserAccount => 'حذف حساب المستخدم';

  @override
  String get deleteUserAccountSubtitle =>
      'يحذف المستخدم وجميع الملفات السحابية الخاصة.';

  @override
  String get deleteAccountTitle => 'حذف الحساب؟';

  @override
  String deleteAccountBody(String serverName) {
    return 'سيؤدي هذا إلى حذف حسابك نهائيًا على $serverName وإزالة جميع الملفات المخزنة في مجلدك السحابي الخاص. لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get deleteAccountButton => 'حذف الحساب';

  @override
  String get changePasswordDialogTitle => 'تغيير كلمة المرور';

  @override
  String get newPasswordFieldLabel => 'كلمة المرور الجديدة';

  @override
  String get confirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get enterNewPassword => 'أدخل كلمة مرور جديدة.';

  @override
  String get passwordUpdated => 'تم تحديث كلمة المرور.';

  @override
  String passwordChangeFailed(String error) {
    return 'فشل تغيير كلمة المرور: $error';
  }

  @override
  String get passwordChangeFailedGeneric => 'فشل تغيير كلمة المرور.';

  @override
  String get accountDeleted => 'تم حذف الحساب.';

  @override
  String accountDeletionFailed(String error) {
    return 'فشل حذف الحساب: $error';
  }

  @override
  String get accountDeletionFailedGeneric => 'فشل حذف الحساب.';

  @override
  String get checkForUpdates => 'التحقق من وجود تحديثات';

  @override
  String get checkingForUpdates => 'جارٍ التحقق من إصدارات GitHub...';

  @override
  String versionLabel(String version) {
    return 'الإصدار $version';
  }

  @override
  String appIsUpToDate(String version) {
    return 'تطبيق Crowley\'s Cloud محدث إلى آخر إصدار (v$version).';
  }

  @override
  String get updateCheckFailed =>
      'فشل التحقق من وجود تحديثات. يرجى المحاولة مرة أخرى لاحقًا.';

  @override
  String get themeModeTitle => 'وضع المظهر';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeCustom => 'مخصص';

  @override
  String get themeDarkFull => 'المظهر الداكن';

  @override
  String get themeLightFull => 'المظهر الفاتح';

  @override
  String get themeCustomFull => 'مظهر مخصص';

  @override
  String get accentColor => 'لون التمييز';

  @override
  String get primaryAccentColor => 'لون التمييز الأساسي';

  @override
  String get selectAccentColor => 'اختيار لون التمييز';

  @override
  String get backgroundColor => 'لون الخلفية';

  @override
  String get surfaceColor => 'لون السطح';

  @override
  String get textColor => 'لون النص';

  @override
  String get subtextColor => 'لون النص الفرعي';

  @override
  String get borderColor => 'لون الحدود';

  @override
  String get fontSizeScale => 'تغيير حجم الخط';

  @override
  String selectColor(String title) {
    return 'تحديد $title';
  }

  @override
  String get categoriesToSyncDialogTitle => 'الفئات المراد مزامنتها';

  @override
  String get categoriesToSyncBody =>
      'اختر فئة واحدة أو أكثر. ترك الكل دون تحديد يعد خيارًا صحيحًا.';

  @override
  String get syncCategorySectionMedia => 'الوسائط';

  @override
  String get syncCategorySectionAudioDocs => 'الصوتيات والمستندات';

  @override
  String get syncCategorySectionOther => 'أخرى';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get noSyncHasRunYet => 'لم يتم تشغيل أي مزامنة بعد.';

  @override
  String lastRunAt(String date) {
    return 'آخر تشغيل $date';
  }

  @override
  String syncResultSuccess(int uploaded, int skipped) {
    return 'تمت مزامنة $uploaded، وتخطي $skipped.';
  }

  @override
  String get syncResultNoFiles => 'لم يتم تحديد أي ملفات للمزامنة.';

  @override
  String syncResultPartial(int uploaded, int failed) {
    return 'تمت مزامنة $uploaded، وفشل $failed.';
  }

  @override
  String get syncResultAuthRequired => 'سجّل الدخول قبل إجراء المزامنة.';

  @override
  String get syncResultUnreachable => 'تعذر الوصول إلى الخادم. فُقد الاتصال.';

  @override
  String get syncResultFailed => 'فشلت المزامنة.';

  @override
  String get serverSetupAddServer => 'إضافة خادم';

  @override
  String get serverSetupCardTitle => 'اتصال بالخادم';

  @override
  String get serverSetupCardSubtitle =>
      'أضف خادم الملفات المنزلي وسجّل الدخول.';

  @override
  String get serverSetupSubmitButton => 'حفظ الخادم';

  @override
  String get serverNameLabel => 'اسم الخادم';

  @override
  String get serverNameHint => 'Home NAS';

  @override
  String get baseUrlLabel => 'عنوان URL الأساسي';

  @override
  String get baseUrlHint => 'https://cloud.example.com';

  @override
  String get allFieldsRequired => 'جميع الحقول مطلوبة.';

  @override
  String get localFilesTitle => 'الملفات المحلية';

  @override
  String get serverFilesTitle => 'ملفات الخادم';

  @override
  String get restoreItemsTitle => 'استعادة العناصر';

  @override
  String restoreItemsBody(int count) {
    return 'هل أنت متأكد من رغبتك في استعادة $count عنصر؟';
  }

  @override
  String get permanentlyDeleteTitle => 'حذف نهائي';

  @override
  String permanentlyDeleteBody(int count) {
    return 'هل أنت متأكد من رغبتك في حذف $count عنصر نهائيًا؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get trashIsEmpty => 'سلة المهملات فارغة.';

  @override
  String trashRetentionInfo(int days) {
    return 'يتم حذف العناصر الموجودة في سلة المهملات تلقائيًا بعد $days يومًا.';
  }

  @override
  String get deletionDate => 'تاريخ الحذف';

  @override
  String get deletePermanentlyAction => 'حذف نهائي';

  @override
  String get conflictFileAlreadyExists => 'الملف موجود بالفعل';

  @override
  String conflictNofM(int current, int total) {
    return 'تعارض $current من $total';
  }

  @override
  String get conflictAFileNamed => 'ملف باسم ';

  @override
  String get conflictAlreadyExistsAt => ' موجود بالفعل في ';

  @override
  String get conflictAlreadyExistsInFolder => ' موجود بالفعل في هذا المجلد.';

  @override
  String get conflictInFolder => 'في المجلد';

  @override
  String get conflictFromTrash => 'من سلة المهملات';

  @override
  String get conflictExisting => 'الحالي';

  @override
  String get conflictNewUpload => 'الرفع الجديد';

  @override
  String conflictSizeLabel(String size) {
    return 'الحجم: $size';
  }

  @override
  String conflictDateLabel(String date) {
    return 'التاريخ: $date';
  }

  @override
  String conflictDeletedLabel(String date) {
    return 'تاريخ الحذف: $date';
  }

  @override
  String conflictApplyToRemaining(int count) {
    return 'تطبيق على التعارضات المتبقية ($count)';
  }

  @override
  String get conflictKeepAllCopies => 'الاحتفاظ بجميع النسخ';

  @override
  String get conflictOverwriteAll => 'استبدال الكل';

  @override
  String get conflictRestoreAllAsCopies => 'استعادة الكل كنسخ';

  @override
  String get conflictRestoreAsCopy => 'استعادة كنسخة';

  @override
  String get conflictOverwriteAllRemaining => 'استبدال جميع العناصر المتبقية';

  @override
  String get conflictSkipAll => 'تخطي الكل';

  @override
  String get conflictSkipAllRemaining => 'تخطي جميع العناصر المتبقية';

  @override
  String get conflictSkip => 'تخطي';

  @override
  String get conflictOverwrite => 'استبدال';

  @override
  String get transfersTitle => 'عمليات النقل';

  @override
  String get transferResume => 'استئناف';

  @override
  String get transferPause => 'إيقاف مؤقت';

  @override
  String get transferCancel => 'إلغاء';

  @override
  String get transferResumeAll => 'استئناف الكل';

  @override
  String get transferPauseAll => 'إيقاف الكل مؤقتًا';

  @override
  String get transferCancelAll => 'إلغاء الكل';

  @override
  String get transferCancelFile => 'إلغاء الملف';

  @override
  String get noTransfers => 'لا توجد عمليات نقل.';

  @override
  String get transferStatusQueued => 'في قائمة الانتظار';

  @override
  String get transferStatusRunning => 'قيد التشغيل';

  @override
  String get transferStatusPaused => 'متوقف مؤقتًا';

  @override
  String get transferStatusCompleted => 'مكتمل';

  @override
  String get transferStatusFailed => 'فشل';

  @override
  String get transferStatusCanceled => 'ملغى';

  @override
  String get themePresetsSection => 'الإعدادات المسبقة';

  @override
  String get themeCustomPaletteSection => 'لوحة ألوان مخصصة';

  @override
  String get themeHexRgbLabel => 'رمز HEX RGB';

  @override
  String get themeHexRgbHint => '#FA5252';

  @override
  String get imageViewerNoFetchHandler => 'لم يتم تكوين معالج الجلب';

  @override
  String get imageViewerFailedToLoad => 'فشل تحميل الصورة';

  @override
  String errorDeletingFile(String filename, String error) {
    return 'خطأ أثناء حذف $filename: $error';
  }

  @override
  String errorReadingFile(String error) {
    return 'خطأ أثناء قراءة الملف: $error';
  }

  @override
  String get syncChannelName => 'المزامنة في الخلفية';

  @override
  String get syncChannelDescription => 'يعرض حالة مزامنة الملفات في الخلفية.';

  @override
  String get storageStatsTitle => 'إحصائيات التخزين';

  @override
  String get storageStatsUsedSpace => 'المساحة المستخدمة';

  @override
  String get storageStatsTotalFiles => 'إجمالي الملفات';

  @override
  String storageStatsNItems(int count) {
    return '$count عنصر';
  }

  @override
  String userFallback(int userId) {
    return 'المستخدم #$userId';
  }

  @override
  String get biometricUnlockReason =>
      'إلغاء قفل بيانات الاعتماد المحفوظة لـ Crowley\'s Cloud.';

  @override
  String get tokenLifetimeEveryOpen => 'عند كل فتح للتطبيق';

  @override
  String get tokenLifetimeOneHour => 'بعد ساعة واحدة';

  @override
  String get tokenLifetime1Hour => 'بعد ساعة واحدة';

  @override
  String get tokenLifetimeOneDay => 'بعد يوم واحد';

  @override
  String get tokenLifetime1Day => 'بعد يوم واحد';

  @override
  String get tokenLifetimeOneWeek => 'بعد أسبوع واحد';

  @override
  String get tokenLifetime1Week => 'بعد أسبوع واحد';

  @override
  String get tokenLifetimeOneMonth => 'بعد شهر واحد';

  @override
  String get tokenLifetime1Month => 'بعد شهر واحد';

  @override
  String get tokenLifetimeThreeMonths => 'بعد 3 أشهر';

  @override
  String get tokenLifetime3Months => 'بعد 3 أشهر';

  @override
  String get tokenLifetimeNever => 'أبدًا على هذا الجهاز';

  @override
  String get cacheLimitUnlimited => 'غير محدود';

  @override
  String get syncCategoryOtherFiles => 'ملفات أخرى';

  @override
  String get internalStorage => 'وحدة التخزين الداخلية';

  @override
  String get localStorageRootName => 'وحدة التخزين الداخلية';

  @override
  String syncNotificationSyncingWith(String serverName) {
    return 'جارٍ المزامنة مع $serverName';
  }

  @override
  String syncNotificationPausedTitle(String serverName) {
    return 'تم إيقاف المزامنة مع $serverName مؤقتًا';
  }

  @override
  String get syncNotificationUnreachableBody =>
      'تعذر الوصول إلى الخادم. تم إيقاف المزامنة في الخلفية مؤقتًا حتى فتح التطبيق.';

  @override
  String get syncNotificationAuthRequiredBody =>
      'المصادقة مطلوبة. افتح التطبيق لتسجيل الدخول.';

  @override
  String syncNotificationFailedTitle(String serverName) {
    return 'فشلت المزامنة مع $serverName';
  }

  @override
  String get syncNotificationGenericErrorBody => 'حدث خطأ أثناء المزامنة.';

  @override
  String syncNotificationCompleteTitle(String serverName) {
    return 'اكتملت المزامنة مع $serverName';
  }

  @override
  String get syncNotificationCompleteBody => 'اكتملت المزامنة.';

  @override
  String get syncStatusConnecting => 'جارٍ الاتصال بالخادم...';

  @override
  String syncStatusConnectionLost(String serverName) {
    return 'تعذر الاتصال بـ $serverName. فُقد الاتصال.';
  }

  @override
  String syncResultServerUnreachableWithServer(String serverName) {
    return 'تعذر الاتصال بـ $serverName. فُقد الاتصال.';
  }

  @override
  String get syncStatusScanningFiles => 'جارٍ فحص الملفات على الجهاز...';

  @override
  String get syncStatusNoFilesFound => 'لم يتم العثور على أي ملفات للمزامنة.';

  @override
  String get syncStatusNoFilesSelected => 'لم يتم تحديد أي ملفات للمزامنة.';

  @override
  String syncStatusCalculatingChecksum(
    int current,
    int total,
    String filename,
  ) {
    return 'جارٍ حساب المجموع الاختباري ($current/$total): $filename';
  }

  @override
  String get syncStatusCheckingDuplicates =>
      'جارٍ التحقق من التكرارات على الخادم...';

  @override
  String syncStatusSyncingFile(int current, int total, String filename) {
    return 'جارٍ المزامنة ($current/$total): $filename';
  }

  @override
  String get syncStatusCompleting => 'جارٍ إكمال المزامنة...';

  @override
  String get showingCachedFiles => 'جارٍ عرض الملفات المخزنة مؤقتًا.';

  @override
  String get showingCachedFilesRefreshFailed =>
      'جارٍ عرض الملفات المخزنة مؤقتًا. فشل التحديث.';

  @override
  String get downloadCanceled => 'تم إلغاء التنزيل.';

  @override
  String downloadedNFilesToPath(int count, String path) {
    return 'تم تنزيل $count ملف إلى $path';
  }

  @override
  String downloadedNFilesFailedM(int downloaded, int failed, String detail) {
    return 'تم تنزيل $downloaded ملف، وفشل $failed: $detail';
  }

  @override
  String downloadedNFilesWithFailures(int count, int failed, String error) {
    return 'تم تنزيل $count ملف، وفشل $failed: $error';
  }

  @override
  String createdNShareLinks(int count) {
    return 'تم إنشاء $count رابط مشاركة.';
  }

  @override
  String get failedToCreateShareLinks => 'فشل إنشاء رابط/روابط المشاركة.';

  @override
  String get alreadyInSharedScope => 'موجود بالفعل في النطاق المشترك.';

  @override
  String sharedNItemsInServer(int count) {
    return 'تمت مشاركة $count عنصر على الخادم.';
  }

  @override
  String sharedNItemsWithFailures(int count, int failed) {
    return 'تمت مشاركة $count عنصر، وفشل $failed.';
  }

  @override
  String sharedNItemsFailedM(int shared, int failed) {
    return 'تمت مشاركة $shared عنصر، وفشل $failed.';
  }

  @override
  String get folderNameCannotBeEmpty => 'لا يمكن أن يكون اسم المجلد فارغًا.';

  @override
  String get folderAlreadyExists => 'المجلد موجود بالفعل.';

  @override
  String get folderCreationOnlyInAllFiles =>
      'إنشاء المجلدات متاح فقط في قسم كل الملفات.';

  @override
  String get currentDirectoryUnavailable => 'الدليل الحالي غير متاح.';

  @override
  String get nothingSelected => 'لم يتم تحديد أي شيء.';

  @override
  String get destinationFolderDoesNotExist => 'مجلد الوجهة غير موجود.';

  @override
  String cannotMoveFolderIntoItself(String name) {
    return 'لا يمكن نقل المجلد \"$name\" إلى داخل نفسه.';
  }

  @override
  String failedToMoveItem(String name, String error) {
    return 'فشل نقل $name: $error';
  }

  @override
  String movedNItems(int count) {
    return 'تم نقل $count عنصر.';
  }

  @override
  String movedNItemsWithFailures(int count, int failed) {
    return 'تم نقل $count عنصر، وفشل $failed.';
  }

  @override
  String movedNItemsFailedM(int moved, int failed) {
    return 'تم نقل $moved عنصر، وفشل $failed.';
  }

  @override
  String get failedToMoveSelectedItems => 'فشل نقل العناصر المحددة.';

  @override
  String get noFilesWereMoved => 'لم يتم نقل أي ملفات.';

  @override
  String renamedOldToNew(String oldName, String newName) {
    return 'تمت إعادة تسمية \"$oldName\" إلى \"$newName\".';
  }

  @override
  String renamedFileFromTo(String oldName, String newName) {
    return 'تمت إعادة تسمية \"$oldName\" إلى \"$newName\".';
  }

  @override
  String failedToRenameWithStatus(String name, int statusCode) {
    return 'فشلت إعادة تسمية \"$name\" ($statusCode).';
  }

  @override
  String failedToRenameFileWithCode(String name, int statusCode) {
    return 'فشلت إعادة تسمية \"$name\" ($statusCode).';
  }

  @override
  String failedToRenameWithError(String name, String error) {
    return 'فشلت إعادة تسمية \"$name\": $error';
  }

  @override
  String failedToRenameFile(String name, String error) {
    return 'فشلت إعادة تسمية \"$name\": $error';
  }

  @override
  String get renameConflictAlreadyExists =>
      'فشلت إعادة التسمية: يوجد ملف أو مجلد بهذا الاسم بالفعل.';

  @override
  String get renameFailedAlreadyExists =>
      'فشلت إعادة التسمية: يوجد ملف أو مجلد بهذا الاسم بالفعل.';

  @override
  String failedToCreateFolderWithCode(int statusCode) {
    return 'فشل إنشاء المجلد ($statusCode).';
  }

  @override
  String deletedNItemsFailedM(int deleted, int failed) {
    return 'تم حذف $deleted عنصر، وفشل $failed.';
  }

  @override
  String transferSummaryFiles(int percent, int completed, int total) {
    return '$percent٪  $completed/$total ملفات';
  }

  @override
  String transferSummaryProgress(int percent, int completed, int total) {
    return '$percent٪  $completed/$total';
  }

  @override
  String get downloadFailedGeneric => 'فشل التنزيل';

  @override
  String uploadedNItemsWithFailures(int uploaded, int failed) {
    return 'تم رفع $uploaded عنصر، وفشل $failed';
  }

  @override
  String uploadedNItemsFailedM(int uploaded, int failed) {
    return 'تم رفع $uploaded عنصر، وفشل $failed.';
  }

  @override
  String uploadSummaryFailedCount(int count) {
    return '، وفشل $count';
  }

  @override
  String uploadLocalPathEmpty(String name) {
    return '$name: المسار المحلي فارغ';
  }

  @override
  String uploadErrorLocalPathEmpty(String name) {
    return '$name: المسار المحلي فارغ';
  }

  @override
  String get directoryUploadFailed => 'فشل رفع الدليل';

  @override
  String get uploadDirectoryFailed => 'فشل رفع الدليل';

  @override
  String get localFileNotFound => 'الملف المحلي غير موجود';

  @override
  String get uploadErrorLocalFileNotFound => 'الملف المحلي غير موجود';

  @override
  String get noSessionToken => 'لا يوجد رمز جلسة نشط';

  @override
  String get uploadErrorNoSessionToken => 'لا يوجد رمز جلسة نشط';

  @override
  String get serverDisconnectedStatus => 'الخادم غير متصل';

  @override
  String get serverDisconnected => 'الخادم غير متصل';

  @override
  String get serverIsUnreachable => 'تعذر الوصول إلى الخادم.';

  @override
  String get serverUnreachable => 'تعذر الوصول إلى الخادم.';

  @override
  String get uploadErrorLocalDirectoryNotFound => 'الدليل المحلي غير موجود';

  @override
  String get uploadErrorFailedToScanDirectory => 'فشل فحص الدليل';

  @override
  String uploadErrorFolderCreateHttp(int statusCode) {
    return 'فشل إنشاء المجلد (HTTP $statusCode)';
  }

  @override
  String get authErrorMissingAccessToken => 'رمز الوصول مفقود في الاستجابة';

  @override
  String get authErrorMissingRefreshToken => 'رمز التحديث مفقود في الاستجابة';

  @override
  String get authErrorNoSavedCredentials =>
      'لا توجد بيانات اعتماد محفوظة متاحة';

  @override
  String get authErrorNoRefreshToken => 'لا يوجد رمز تحديث متاح';

  @override
  String get authErrorNoActiveSession => 'لا توجد جلسة نشطة متاحة';

  @override
  String get authErrorNoSavedUsername => 'لا يوجد اسم مستخدم محفوظ متاح';

  @override
  String get updateNoReleasesPublished => 'لم يتم نشر أي إصدارات بعد.';

  @override
  String get language => 'اللغة';
}
