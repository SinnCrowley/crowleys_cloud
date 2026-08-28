// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'Crowley\'s Cloud';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'বাতিল';

  @override
  String get save => 'সংরক্ষণ';

  @override
  String get delete => 'মুছুন';

  @override
  String get rename => 'নাম পরিবর্তন';

  @override
  String get close => 'বন্ধ করুন';

  @override
  String get retry => 'পুনরায় চেষ্টা করুন';

  @override
  String get loading => 'লোড হচ্ছে...';

  @override
  String get confirm => 'নিশ্চিত করুন';

  @override
  String get error => 'ত্রুটি';

  @override
  String errorWithMessage(String message) {
    return 'ত্রুটি: $message';
  }

  @override
  String get unknown => 'অজানা';

  @override
  String get upload => 'আপলোড';

  @override
  String get download => 'ডাউনলোড';

  @override
  String get share => 'শেয়ার';

  @override
  String get copy => 'কপি';

  @override
  String get move => 'স্থানান্তর';

  @override
  String get restore => 'পুনরুদ্ধার';

  @override
  String get apply => 'প্রয়োগ করুন';

  @override
  String get create => 'তৈরি করুন';

  @override
  String get clear => 'মুছুন';

  @override
  String get add => 'যোগ করুন';

  @override
  String get remove => 'সরান';

  @override
  String get edit => 'সম্পাদনা করুন';

  @override
  String get switchLabel => 'পরিবর্তন';

  @override
  String get search => 'অনুসন্ধান';

  @override
  String get name => 'নাম';

  @override
  String get date => 'তারিখ';

  @override
  String get size => 'আকার';

  @override
  String get type => 'ধরন';

  @override
  String get ascending => 'ঊর্ধ্বক্রম';

  @override
  String get descending => 'নিম্নক্রম';

  @override
  String get allFiles => 'সব';

  @override
  String get categoryImages => 'ছবি';

  @override
  String get categoryPhotos => 'ছবি';

  @override
  String get categoryVideos => 'ভিডিও';

  @override
  String get categoryAudio => 'অডিও';

  @override
  String get categoryDocuments => 'নথি';

  @override
  String get categoryArchives => 'আর্কাইভ';

  @override
  String get categoryShared => 'শেয়ার করা';

  @override
  String get categoryOther => 'অন্যান্য';

  @override
  String get categoryOtherFiles => 'অন্যান্য ফাইল';

  @override
  String get noFilesFound => 'কোনো ফাইল পাওয়া যায়নি।';

  @override
  String get noFilesInFolder => 'এই ফোল্ডারে কোনো ফাইল নেই।';

  @override
  String get thisActionCannotBeUndone => 'এই কাজটি আর ফিরিয়ে আনা যাবে না।';

  @override
  String get passwordsDoNotMatch => 'পাসওয়ার্ড দুটি মেলেনি।';

  @override
  String get navLocalFiles => 'স্থানীয় ফাইল';

  @override
  String get navServerFiles => 'সার্ভার ফাইল';

  @override
  String get navSettings => 'সেটিংস';

  @override
  String get navTrash => 'ট্র্যাশ';

  @override
  String get navLocal => 'স্থানীয়';

  @override
  String get navServer => 'সার্ভার';

  @override
  String get addServer => 'সার্ভার যোগ করুন';

  @override
  String get noServersConfigured => 'কোনো সার্ভার কনফিগার করা হয়নি।';

  @override
  String get addAServerInSettings => 'সেটিংস থেকে একটি সার্ভার যোগ করুন।';

  @override
  String get addFirstServerHint =>
      'চালিয়ে যেতে আপনার প্রথম সার্ভারটি যোগ করুন।';

  @override
  String get noServersConfiguredYet => 'এখনও কোনো সার্ভার কনফিগার করা হয়নি।';

  @override
  String get crowleysCloudSetup => 'Crowley\'s Cloud সেটআপ';

  @override
  String get connect => 'সংযোগ করুন';

  @override
  String get connecting => 'সংযোগ করা হচ্ছে...';

  @override
  String get connected => 'সংযুক্ত';

  @override
  String get disconnected => 'বিচ্ছিন্ন';

  @override
  String get switchServer => 'সার্ভার পরিবর্তন করুন';

  @override
  String get chooseOtherServer => 'অন্য সার্ভার বেছে নিন';

  @override
  String get switchServerTitle => 'সার্ভার পরিবর্তন করবেন?';

  @override
  String switchServerBody(String serverName) {
    return 'সক্রিয় সার্ভার কি \"$serverName\"-এ পরিবর্তন করবেন?';
  }

  @override
  String get chooseServer => 'সার্ভার নির্বাচন করুন';

  @override
  String get authenticationRequired => 'প্রমাণীকরণ প্রয়োজন';

  @override
  String signInToAccess(String serverName) {
    return '$serverName-এ ফাইল দেখতে সাইন ইন করুন';
  }

  @override
  String get signInWithPassword => 'পাসওয়ার্ড দিয়ে সাইন ইন করুন';

  @override
  String get useBiometrics => 'বায়োমেট্রিক ব্যবহার করুন';

  @override
  String get openingSignIn => 'সাইন ইন খোলা হচ্ছে...';

  @override
  String get serverConnectionFailed => 'সার্ভার সংযোগ ব্যর্থ হয়েছে';

  @override
  String get unableToConnectToServer =>
      'সক্রিয় সার্ভারের সাথে সংযোগ স্থাপন করা যায়নি।';

  @override
  String unableToConnectTo(String serverName) {
    return '$serverName-এর সাথে সংযোগ স্থাপন করা যায়নি।';
  }

  @override
  String get searchHint => 'অনুসন্ধান...';

  @override
  String get searchFilesHint => 'ফাইল অনুসন্ধান করুন...';

  @override
  String get searchServerFilesHint => 'সার্ভার ফাইল অনুসন্ধান করুন...';

  @override
  String get searchTrashHint => 'ট্র্যাশে অনুসন্ধান করুন...';

  @override
  String get storagePermissionRequired => 'স্টোরেজের অনুমতি প্রয়োজন';

  @override
  String get grantPermission => 'অনুমতি দিন';

  @override
  String get permissionDeniedOpenSettings =>
      'অনুমতি প্রত্যাখ্যান করা হয়েছে। অনুগ্রহ করে সেটিংসে গিয়ে স্টোরেজের অনুমতি দিন।';

  @override
  String get manageStoragePermissionRequired =>
      'ফোল্ডার ব্রাউজ এবং নির্বাচন করতে স্টোরেজ পরিচালনার অনুমতি প্রয়োজন।';

  @override
  String get storagePermissionsRequired =>
      'সিঙ্ক করার জন্য স্টোরেজ অনুমতি প্রয়োজন।';

  @override
  String updateAvailableTitle(String version) {
    return 'আপডেট উপলভ্য: v$version';
  }

  @override
  String get updateAvailableTapToSeeNew => 'নতুন কী আছে দেখতে ট্যাপ করুন';

  @override
  String get updateView => 'দেখুন';

  @override
  String get updateAvailableDialogTitle => 'আপডেট উপলভ্য';

  @override
  String updateVersionSubtitle(String version) {
    return 'সংস্করণ $version';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'বর্তমান: v$version';
  }

  @override
  String updateNewVersion(String version) {
    return 'নতুন: v$version';
  }

  @override
  String get updateWhatsNew => 'নতুন কী আছে:';

  @override
  String get updateGitHub => 'GitHub';

  @override
  String get updateNoReleaseNotes => 'কোনো রিলিজ নোট দেওয়া হয়নি।';

  @override
  String get updateLater => 'পরে';

  @override
  String get updateDownloadApk => 'APK ডাউনলোড করুন';

  @override
  String get updateInstall => 'আপডেট করুন';

  @override
  String get shareLinkTitle => 'শেয়ার লিঙ্ক';

  @override
  String get shareViaLink => 'লিঙ্কের মাধ্যমে শেয়ার করুন';

  @override
  String get shareInServer => 'সার্ভারে শেয়ার করুন';

  @override
  String get expiryDays => 'মেয়াদ (দিন)';

  @override
  String get expiryNever => 'কখনও নয়';

  @override
  String get expiry1Day => '১ দিন';

  @override
  String get expiry7Days => '৭ দিন';

  @override
  String get expiry30Days => '৩০ দিন';

  @override
  String get expiry90Days => '৯০ দিন';

  @override
  String get expiry180Days => '১৮০ দিন';

  @override
  String get expiry365Days => '৩৬৫ দিন';

  @override
  String get createLink => 'লিঙ্ক তৈরি করুন';

  @override
  String get sharedLinkCopied => 'শেয়ার লিঙ্ক ক্লিপবোর্ডে কপি করা হয়েছে!';

  @override
  String failedToCopySharedLink(String error) {
    return 'শেয়ার লিঙ্ক কপি করতে ব্যর্থ হয়েছে: $error';
  }

  @override
  String get cannotShareThisFileType => 'এই ধরনের ফাইল শেয়ার করা যায় না।';

  @override
  String failedToCreateShare(String error) {
    return 'শেয়ার তৈরি করতে ব্যর্থ হয়েছে: $error';
  }

  @override
  String get newFolderTitle => 'ফোল্ডার তৈরি করুন';

  @override
  String get newFolderHint => 'ফোল্ডারের নাম';

  @override
  String get newFolder => 'নতুন ফোল্ডার';

  @override
  String get folderCreated => 'ফোল্ডার তৈরি হয়েছে।';

  @override
  String failedToCreateFolder(String error) {
    return 'ফোল্ডার তৈরি করতে ব্যর্থ হয়েছে: $error';
  }

  @override
  String get creatingFolder => 'ফোল্ডার তৈরি হচ্ছে...';

  @override
  String get renameDialogTitle => 'নাম পরিবর্তন';

  @override
  String get renameHint => 'নতুন নাম';

  @override
  String get enterNewName => 'নতুন নাম লিখুন';

  @override
  String get renamedSuccessfully => 'নাম সফলভাবে পরিবর্তন করা হয়েছে।';

  @override
  String renameFailed(String error) {
    return 'নাম পরিবর্তন ব্যর্থ হয়েছে: $error';
  }

  @override
  String get moveDialogTitle => 'এখানে স্থানান্তর করুন';

  @override
  String moveTo(String path) {
    return 'স্থানান্তর: $path';
  }

  @override
  String get moveHere => 'এখানে আনুন';

  @override
  String moveFailed(String error) {
    return 'স্থানান্তর ব্যর্থ হয়েছে: $error';
  }

  @override
  String get movedToFolder => 'ফোল্ডারে স্থানান্তর করা হয়েছে।';

  @override
  String copyFailed(String error) {
    return 'কপি করতে ব্যর্থ হয়েছে: $error';
  }

  @override
  String get selectFolder => 'ফোল্ডার নির্বাচন করুন';

  @override
  String get useThisFolder => 'এই ফোল্ডার ব্যবহার করুন';

  @override
  String get storageRoot => 'স্টোরেজ';

  @override
  String get serverRoot => 'মূল';

  @override
  String deleteNItemsTitle(int count) {
    return '$countটি আইটেম মুছবেন?';
  }

  @override
  String get deleteFilesTitle => 'ফাইলগুলো মুছবেন?';

  @override
  String deleteFilesBody(int count) {
    return 'আপনি কি নিশ্চিতভাবে $countটি নির্বাচিত আইটেম মুছতে চান? এটি আর ফিরিয়ে আনা যাবে না।';
  }

  @override
  String get deletePermanently => 'স্থায়ীভাবে মুছুন';

  @override
  String get deletePermanentlyTitle => 'স্থায়ীভাবে মুছবেন?';

  @override
  String deletePermanentlyBody(String filename) {
    return '$filename স্থায়ীভাবে মুছে ফেলা হবে।';
  }

  @override
  String get deleteFileTitle => 'ফাইল মুছবেন?';

  @override
  String deleteFileBody(String filename) {
    return 'আপনি কি নিশ্চিতভাবে $filename মুছতে চান? এটি আর ফিরিয়ে আনা যাবে না।';
  }

  @override
  String get deleteServerFileTitle => 'স্থায়ীভাবে মুছুন';

  @override
  String deleteServerFileBody(String filename) {
    return 'আপনি কি নিশ্চিতভাবে \"$filename\" স্থায়ীভাবে মুছতে চান? এটি আর ফিরিয়ে আনা যাবে না।';
  }

  @override
  String get unshareItemsTitle => 'আইটেমের শেয়ার বাতিল করবেন?';

  @override
  String unshareItemsBody(int count) {
    return 'আপনি কি নিশ্চিতভাবে $countটি নির্বাচিত আইটেমের শেয়ার বাতিল করতে চান? এটি সেগুলো শেয়ার করা ফোল্ডার থেকে সরিয়ে দেবে।';
  }

  @override
  String get unshare => 'শেয়ার বাতিল করুন';

  @override
  String get moveToTrash => 'ট্র্যাশে সরান';

  @override
  String get movedToTrash => 'ট্র্যাশে সরানো হয়েছে।';

  @override
  String movedNItemsToTrash(int count) {
    return '$countটি আইটেম ট্র্যাশে সরানো হয়েছে।';
  }

  @override
  String failedToMoveToTrash(String error) {
    return 'ট্র্যাশে সরাতে ব্যর্থ হয়েছে: $error';
  }

  @override
  String deletedNItems(int count) {
    return '$countটি আইটেম মুছে ফেলা হয়েছে।';
  }

  @override
  String failedToDelete(String error) {
    return 'মুছতে ব্যর্থ হয়েছে: $error';
  }

  @override
  String failedToDeleteItem(String error) {
    return 'মুছে ফেলা ব্যর্থ হয়েছে: $error';
  }

  @override
  String deletedFilename(String filename) {
    return '$filename মুছে ফেলা হয়েছে।';
  }

  @override
  String get failedToOpenFile => 'ফাইল খুলতে ব্যর্থ হয়েছে';

  @override
  String fileDownloadFailed(String error) {
    return 'ফাইল ডাউনলোড ব্যর্থ হয়েছে: $error';
  }

  @override
  String get downloading => 'ডাউনলোড হচ্ছে...';

  @override
  String get downloadingFile => 'ফাইল ডাউনলোড হচ্ছে...';

  @override
  String downloadComplete(String filename) {
    return 'ডাউনলোড সম্পূর্ণ: $filename';
  }

  @override
  String downloadFailed(String error) {
    return 'ডাউনলোড ব্যর্থ হয়েছে: $error';
  }

  @override
  String get failedToDownloadPreview =>
      'ফাইলের পূর্বরূপ ডাউনলোড করতে ব্যর্থ হয়েছে';

  @override
  String uploadComplete(String filename) {
    return 'আপলোড সম্পূর্ণ: $filename';
  }

  @override
  String uploadFailed(String error) {
    return 'আপলোড ব্যর্থ হয়েছে: $error';
  }

  @override
  String get failedToPickFiles => 'ফাইল নির্বাচন করতে ব্যর্থ হয়েছে';

  @override
  String uploadedNItems(int count) {
    return '$countটি আইটেম আপলোড করা হয়েছে';
  }

  @override
  String get copiedLinkToClipboard => 'লিঙ্ক ক্লিপবোর্ডে কপি করা হয়েছে।';

  @override
  String failedToCopyLink(String error) {
    return 'লিঙ্ক কপি করতে ব্যর্থ হয়েছে: $error';
  }

  @override
  String get selectingAll => 'সব নির্বাচন করা হচ্ছে...';

  @override
  String get allItemsSelected => 'সব আইটেম নির্বাচিত হয়েছে।';

  @override
  String get failedToLoadSearchResults =>
      'অনুসন্ধানের ফলাফল লোড করতে ব্যর্থ হয়েছে';

  @override
  String get shareNotSupportedForType =>
      'এই ধরনের ফাইলের জন্য শেয়ার সমর্থিত নয়।';

  @override
  String nSelected(int count) {
    return '$countটি নির্বাচিত';
  }

  @override
  String get noServerSelected => 'কোনো সার্ভার নির্বাচিত নেই';

  @override
  String get pleaseConnectToServerFirst =>
      'অনুগ্রহ করে প্রথমে একটি সার্ভারের সাথে সংযোগ করুন।';

  @override
  String get signInRequired => 'সাইন ইন প্রয়োজন';

  @override
  String pleaseSignInToServer(String serverName) {
    return 'অনুগ্রহ করে প্রথমে \"$serverName\"-এ সাইন ইন করুন।';
  }

  @override
  String get connectingToServer => 'সার্ভারের সাথে সংযোগ করা হচ্ছে...';

  @override
  String connectedToServer(String serverName) {
    return '$serverName-এর সাথে সংযুক্ত হয়েছে।';
  }

  @override
  String connectionFailed(String error) {
    return 'সংযোগ ব্যর্থ হয়েছে: $error';
  }

  @override
  String failedToConnect(String error) {
    return 'সংযুক্ত হতে ব্যর্থ হয়েছে: $error';
  }

  @override
  String authFailed(String error) {
    return 'প্রমাণীকরণ ব্যর্থ হয়েছে: $error';
  }

  @override
  String get authFailedGeneric =>
      'প্রমাণীকরণ ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।';

  @override
  String biometricLoginFailed(String error) {
    return 'বায়োমেট্রিক লগইন ব্যর্থ হয়েছে: $error';
  }

  @override
  String get biometricLoginFailedGeneric => 'বায়োমেট্রিক লগইন ব্যর্থ হয়েছে।';

  @override
  String get noServerSessionToken =>
      'কোনো সার্ভার সেশন টোকেন নেই। সার্ভার পুনরায় প্রমাণীকরণ করুন।';

  @override
  String failedToSaveServer(String error) {
    return 'সার্ভার সংরক্ষণ করতে ব্যর্থ হয়েছে: $error';
  }

  @override
  String get addToFolder => 'ফোল্ডারে যোগ করুন';

  @override
  String get loginTabLabel => 'লগইন';

  @override
  String get registerTabLabel => 'নিবন্ধন';

  @override
  String get welcomeBack => 'স্বাগতম';

  @override
  String get signInToContinue => 'চালিয়ে যেতে সাইন ইন করুন';

  @override
  String get createAccount => 'অ্যাকাউন্ট তৈরি করুন';

  @override
  String get joinTheServer => 'সার্ভারে যোগ দিন';

  @override
  String get usernameLabel => 'ব্যবহারকারীর নাম';

  @override
  String get usernameHint => 'আপনার ব্যবহারকারীর নাম লিখুন';

  @override
  String get passwordLabel => 'পাসওয়ার্ড';

  @override
  String get passwordHint => 'আপনার পাসওয়ার্ড লিখুন';

  @override
  String get showPassword => 'পাসওয়ার্ড দেখান';

  @override
  String get hidePassword => 'পাসওয়ার্ড লুকান';

  @override
  String get confirmPassword => 'পাসওয়ার্ড নিশ্চিত করুন';

  @override
  String get logIn => 'লগ ইন করুন';

  @override
  String get loggingIn => 'লগ ইন হচ্ছে...';

  @override
  String get registering => 'নিবন্ধন করা হচ্ছে...';

  @override
  String get forgotPassword => 'পাসওয়ার্ড ভুলে গেছেন?';

  @override
  String get doNotHaveAccount => 'অ্যাকাউন্ট নেই? নিবন্ধনে যান।';

  @override
  String get alreadyHaveAccount => 'ইতিমধ্যে একটি অ্যাকাউন্ট আছে? লগইনে যান।';

  @override
  String get usernameCannotBeEmpty => 'ব্যবহারকারীর নাম খালি হতে পারে না।';

  @override
  String get passwordCannotBeEmpty => 'পাসওয়ার্ড খালি হতে পারে না।';

  @override
  String get usernameInvalid =>
      'ব্যবহারকারীর নাম ৩-৩২ অক্ষরের হতে হবে (বর্ণ, সংখ্যা, _ বা -)।';

  @override
  String get passwordTooShort => 'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে।';

  @override
  String loginFailed(String error) {
    return 'লগইন ব্যর্থ হয়েছে: $error';
  }

  @override
  String registrationFailed(String error) {
    return 'নিবন্ধন ব্যর্থ হয়েছে: $error';
  }

  @override
  String get resetPasswordTitle => 'পাসওয়ার্ড রিসেট করুন';

  @override
  String get enterResetCodeTitle => 'রিসেট কোড লিখুন';

  @override
  String get resetPasswordStep1Body =>
      'আপনার ব্যবহারকারীর নাম লিখুন। ৬-সংখ্যার যাচাইকরণ কোডটি সার্ভার লগ/কনসোলে মুদ্রিত হবে।';

  @override
  String get resetPasswordStep2Body =>
      'যাচাইকরণ কোডটি সার্ভার কনসোলে মুদ্রিত হয়েছে। ৬-সংখ্যার কোড এবং আপনার নতুন পাসওয়ার্ড লিখুন।';

  @override
  String get resetCodeLabel => 'রিসেট কোড';

  @override
  String get resetCodeHint => '৬-সংখ্যার কোড লিখুন';

  @override
  String get newPasswordLabel => 'নতুন পাসওয়ার্ড';

  @override
  String get newPasswordHint => 'নতুন পাসওয়ার্ড লিখুন';

  @override
  String get passwordResetSuccessfully => 'পাসওয়ার্ড সফলভাবে রিসেট হয়েছে!';

  @override
  String get usernameIsRequired => 'ব্যবহারকারীর নাম আবশ্যক।';

  @override
  String get codeAndPasswordRequired => 'কোড এবং নতুন পাসওয়ার্ড আবশ্যক।';

  @override
  String get failedToRequestReset =>
      'রিসেট অনুরোধ ব্যর্থ হয়েছে। সার্ভার URL যাচাই করুন।';

  @override
  String get failedToResetPassword =>
      'পাসওয়ার্ড রিসেট করতে ব্যর্থ হয়েছে। অনুগ্রহ করে কোডটি পরীক্ষা করুন।';

  @override
  String get pleaseEnterServerUrlFirst =>
      'অনুগ্রহ করে প্রথমে সার্ভার URL লিখুন।';

  @override
  String get sendCode => 'কোড পাঠান';

  @override
  String get settingsTitle => 'সেটিংস';

  @override
  String get sectionBackupSync => 'ব্যাকআপ ও সিঙ্ক';

  @override
  String get sectionStorageCache => 'স্টোরেজ ও ক্যাশে';

  @override
  String get sectionSecurityBehavior => 'নিরাপত্তা ও আচরণ';

  @override
  String get sectionAboutUpdates => 'সম্পর্কে ও আপডেট';

  @override
  String get sectionAppearance => 'উপস্থিতি ও কাস্টমাইজেশন';

  @override
  String get noServersConfiguredSync => 'কোনো সার্ভার কনফিগার নেই';

  @override
  String get addServerBeforeSync =>
      'সিঙ্ক কনফিগার করার আগে একটি সার্ভার যোগ করুন।';

  @override
  String get selectServerToConfigureSync =>
      'সিঙ্ক সেটিংস কনফিগার করতে একটি সার্ভার নির্বাচন করুন।';

  @override
  String get activeServerSuffix => '· সক্রিয়';

  @override
  String get folderAndCategorySync => 'ফোল্ডার ও বিভাগ সিঙ্ক';

  @override
  String get keepCategoriesSynced =>
      'নির্বাচিত স্থানীয় বিভাগ বা ফোল্ডারগুলো এই সার্ভারের সাথে সিঙ্ক রাখুন।';

  @override
  String get addServerBeforeSyncEnable =>
      'সিঙ্ক সক্ষম করার আগে একটি সার্ভার যোগ করুন।';

  @override
  String get onlyOnWifi => 'কেবলমাত্র ওয়াই-ফাই-এ';

  @override
  String get onlyWhileCharging => 'কেবল চার্জ করার সময়';

  @override
  String get serverTargetDirectory => 'সার্ভারের টার্গেট ডিরেক্টরি';

  @override
  String get serverTargetDirectoryHint => '/backup/mobile_phone';

  @override
  String get synchronizationFrequency => 'সিঙ্কের পুনরাবৃত্তি';

  @override
  String get syncNow => 'এখনই সিঙ্ক করুন';

  @override
  String get syncing => 'সিঙ্ক হচ্ছে...';

  @override
  String get categoriesToSynchronize => 'সিঙ্ক করার বিভাগসমূহ';

  @override
  String get noCategoriesSelected => 'কোনো বিভাগ নির্বাচিত হয়নি।';

  @override
  String nCategoriesSelected(int count) {
    return '$countটি নির্বাচিত';
  }

  @override
  String get foldersToSynchronize => 'সিঙ্ক করার ফোল্ডারসমূহ';

  @override
  String get noCustomFolders => 'কোনো কাস্টম ফোল্ডার কনফিগার করা হয়নি।';

  @override
  String nFolders(int count) {
    return '$countটি ফোল্ডার';
  }

  @override
  String get addFolder => 'ফোল্ডার যোগ করুন';

  @override
  String get removeFolder => 'ফোল্ডার সরান';

  @override
  String get removeServer => 'সার্ভার সরান';

  @override
  String get syncFreqEvery15Min => 'প্রতি ১৫ মিনিট';

  @override
  String get syncFreqEvery30Min => 'প্রতি ৩০ মিনিট';

  @override
  String get syncFreqEvery1Hour => 'প্রতি ঘণ্টা';

  @override
  String syncFreqEveryNHours(int hours) {
    return 'প্রতি $hours ঘণ্টা';
  }

  @override
  String syncFreqEveryNMin(int minutes) {
    return 'প্রতি $minutes মিনিট';
  }

  @override
  String get syncFreqDaily => 'প্রতিদিন';

  @override
  String get chooseSyncFrequencyTitle => 'সিঙ্কের সময়কাল বেছে নিন';

  @override
  String get cacheSize => 'ক্যাশের আকার';

  @override
  String get refreshTooltip => 'রিফ্রেশ';

  @override
  String get cacheLimit => 'ক্যাশ সীমা';

  @override
  String get downloadPath => 'ডাউনলোড পাথ';

  @override
  String get defaultDownloadFolder => 'ডিফল্ট CrowleysCloud ফোল্ডার';

  @override
  String get clearCache => 'ক্যাশে মুছুন';

  @override
  String get clearCacheTitle => 'ক্যাশে মুছবেন?';

  @override
  String get clearCacheBody =>
      'এটি স্থানীয় থাম্বনেইল এবং ক্যাশ করা সার্ভার তালিকা সরিয়ে ফেলবে।';

  @override
  String get downloadPathDialogTitle => 'ডাউনলোড পাথ';

  @override
  String get downloadPathHint => '/storage/emulated/0/CrowleysCloud';

  @override
  String get useDefault => 'ডিফল্ট ব্যবহার করুন';

  @override
  String get serverTargetDirDialogTitle => 'সার্ভারের টার্গেট ডিরেক্টরি';

  @override
  String get requireLogin => 'লগইন বাধ্যতামূলক করুন';

  @override
  String get biometricLogin => 'বায়োমেট্রিক লগইন';

  @override
  String get biometricLoginSubtitle =>
      'সংরক্ষিত তথ্যের মাধ্যমে বায়োমেট্রিক লগইনের অনুমতি দিন।';

  @override
  String get biometricsNotAvailable => 'এই ডিভাইসে বায়োমেট্রিক সুবিধা নেই।';

  @override
  String get showHiddenFiles => 'লুকানো ফাইল দেখান';

  @override
  String get showHiddenFilesSubtitle =>
      'ডট দিয়ে শুরু হওয়া ফাইল ও ফোল্ডার প্রদর্শন করুন।';

  @override
  String get changePassword => 'পাসওয়ার্ড পরিবর্তন করুন';

  @override
  String changePasswordSubtitle(String serverName) {
    return '$serverName-এর পাসওয়ার্ড আপডেট করুন।';
  }

  @override
  String get addServerBeforeChangePassword =>
      'পাসওয়ার্ড পরিবর্তন করার আগে একটি সার্ভার যোগ করুন।';

  @override
  String get deleteUserAccount => 'ব্যবহারকারী অ্যাকাউন্ট মুছুন';

  @override
  String get deleteUserAccountSubtitle =>
      'ব্যবহারকারী এবং সমস্ত ব্যক্তিগত ক্লাউড ফাইল মুছে ফেলে।';

  @override
  String get deleteAccountTitle => 'অ্যাকাউন্ট মুছবেন?';

  @override
  String deleteAccountBody(String serverName) {
    return 'এটি স্থায়ীভাবে $serverName-এ আপনার অ্যাকাউন্ট মুছে ফেলবে এবং আপনার ব্যক্তিগত ক্লাউড ফোল্ডারে সংরক্ষিত সব ফাইল সরিয়ে দেবে। এটি আর ফিরিয়ে আনা যাবে না।';
  }

  @override
  String get deleteAccountButton => 'অ্যাকাউন্ট মুছুন';

  @override
  String get changePasswordDialogTitle => 'পাসওয়ার্ড পরিবর্তন';

  @override
  String get newPasswordFieldLabel => 'নতুন পাসওয়ার্ড';

  @override
  String get confirmPasswordLabel => 'পাসওয়ার্ড নিশ্চিত করুন';

  @override
  String get enterNewPassword => 'একটি নতুন পাসওয়ার্ড লিখুন।';

  @override
  String get passwordUpdated => 'পাসওয়ার্ড আপডেট করা হয়েছে।';

  @override
  String passwordChangeFailed(String error) {
    return 'পাসওয়ার্ড পরিবর্তন ব্যর্থ হয়েছে: $error';
  }

  @override
  String get passwordChangeFailedGeneric =>
      'পাসওয়ার্ড পরিবর্তন ব্যর্থ হয়েছে।';

  @override
  String get accountDeleted => 'অ্যাকাউন্ট মুছে ফেলা হয়েছে।';

  @override
  String accountDeletionFailed(String error) {
    return 'অ্যাকাউন্ট মুছে ফেলা ব্যর্থ হয়েছে: $error';
  }

  @override
  String get accountDeletionFailedGeneric =>
      'অ্যাকাউন্ট মুছে ফেলা ব্যর্থ হয়েছে।';

  @override
  String get checkForUpdates => 'আপডেটের জন্য পরীক্ষা করুন';

  @override
  String get checkingForUpdates => 'GitHub Releases পরীক্ষা করা হচ্ছে...';

  @override
  String versionLabel(String version) {
    return 'সংস্করণ $version';
  }

  @override
  String appIsUpToDate(String version) {
    return 'Crowley\'s Cloud আপ-টু-ডেট আছে (v$version)।';
  }

  @override
  String get updateCheckFailed =>
      'আপডেট পরীক্ষা করতে ব্যর্থ হয়েছে। অনুগ্রহ করে পরে আবার চেষ্টা করুন।';

  @override
  String get themeModeTitle => 'থিম মোড';

  @override
  String get themeDark => 'গাঢ়';

  @override
  String get themeLight => 'হালকা';

  @override
  String get themeCustom => 'কাস্টম';

  @override
  String get themeDarkFull => 'গাঢ় থিম';

  @override
  String get themeLightFull => 'হালকা থিম';

  @override
  String get themeCustomFull => 'কাস্টম থিম';

  @override
  String get accentColor => 'অ্যাকসেন্ট রঙ';

  @override
  String get primaryAccentColor => 'প্রাথমিক অ্যাকসেন্ট রঙ';

  @override
  String get selectAccentColor => 'অ্যাকসেন্ট রঙ নির্বাচন করুন';

  @override
  String get backgroundColor => 'পটভূমির রঙ';

  @override
  String get surfaceColor => 'পৃষ্ঠতলের রঙ';

  @override
  String get textColor => 'লেখার রঙ';

  @override
  String get subtextColor => 'উপ-লেখার রঙ';

  @override
  String get borderColor => 'সীমানার রঙ';

  @override
  String get fontSizeScale => 'ফন্টের আকার';

  @override
  String selectColor(String title) {
    return '$title নির্বাচন করুন';
  }

  @override
  String get categoriesToSyncDialogTitle => 'সিঙ্ক করার বিভাগসমূহ';

  @override
  String get categoriesToSyncBody =>
      'এক বা একাধিক বিভাগ বেছে নিন। সব আনচেক রাখাও বৈধ।';

  @override
  String get syncCategorySectionMedia => 'মিডিয়া';

  @override
  String get syncCategorySectionAudioDocs => 'অডিও ও নথি';

  @override
  String get syncCategorySectionOther => 'অন্যান্য';

  @override
  String get clearAll => 'সব মুছুন';

  @override
  String get noSyncHasRunYet => 'এখনও কোনো সিঙ্ক চালানো হয়নি।';

  @override
  String lastRunAt(String date) {
    return 'সর্বশেষ চালনা $date';
  }

  @override
  String syncResultSuccess(int uploaded, int skipped) {
    return '$uploadedটি সিঙ্ক হয়েছে, $skippedটি এড়িয়ে গেছে।';
  }

  @override
  String get syncResultNoFiles => 'সিঙ্কের জন্য কোনো ফাইল নির্বাচিত হয়নি।';

  @override
  String syncResultPartial(int uploaded, int failed) {
    return '$uploadedটি সিঙ্ক হয়েছে, $failedটি ব্যর্থ হয়েছে।';
  }

  @override
  String get syncResultAuthRequired => 'সিঙ্ক করার আগে সাইন ইন করুন।';

  @override
  String get syncResultUnreachable =>
      'সার্ভারে পৌঁছানো যায়নি। সংযোগ বিচ্ছিন্ন হয়েছে।';

  @override
  String get syncResultFailed => 'সিঙ্ক ব্যর্থ হয়েছে।';

  @override
  String get serverSetupAddServer => 'সার্ভার যোগ করুন';

  @override
  String get serverSetupCardTitle => 'সার্ভার সংযোগ করুন';

  @override
  String get serverSetupCardSubtitle =>
      'আপনার হোম ফাইল সার্ভার যোগ করুন এবং সাইন ইন করুন।';

  @override
  String get serverSetupSubmitButton => 'সার্ভার সংরক্ষণ করুন';

  @override
  String get serverNameLabel => 'সার্ভারের নাম';

  @override
  String get serverNameHint => 'Home NAS';

  @override
  String get baseUrlLabel => 'বেস URL';

  @override
  String get baseUrlHint => 'https://cloud.example.com';

  @override
  String get allFieldsRequired => 'সবগুলো ক্ষেত্র পূরণ করা আবশ্যক।';

  @override
  String get localFilesTitle => 'স্থানীয় ফাইল';

  @override
  String get serverFilesTitle => 'সার্ভার ফাইল';

  @override
  String get restoreItemsTitle => 'আইটেম পুনরুদ্ধার করুন';

  @override
  String restoreItemsBody(int count) {
    return 'আপনি কি নিশ্চিতভাবে $countটি আইটেম পুনরুদ্ধার করতে চান?';
  }

  @override
  String get permanentlyDeleteTitle => 'স্থায়ীভাবে মুছুন';

  @override
  String permanentlyDeleteBody(int count) {
    return 'আপনি কি নিশ্চিতভাবে $countটি আইটেম স্থায়ীভাবে মুছতে চান? এটি আর ফিরিয়ে আনা যাবে না।';
  }

  @override
  String get trashIsEmpty => 'ট্র্যাশ খালি।';

  @override
  String trashRetentionInfo(int days) {
    return 'ট্র্যাশের আইটেমগুলো $days দিন পর স্বয়ংক্রিয়ভাবে মুছে ফেলা হয়।';
  }

  @override
  String get deletionDate => 'মুছে ফেলার তারিখ';

  @override
  String get deletePermanentlyAction => 'স্থায়ীভাবে মুছুন';

  @override
  String get conflictFileAlreadyExists => 'ফাইলটি ইতিমধ্যে বিদ্যমান';

  @override
  String conflictNofM(int current, int total) {
    return 'দ্বন্দ্ব $current / $total';
  }

  @override
  String get conflictAFileNamed => 'একটি ফাইল যার নাম ';

  @override
  String get conflictAlreadyExistsAt => ' ইতিমধ্যে বিদ্যমান আছে এখানে: ';

  @override
  String get conflictAlreadyExistsInFolder => ' এই ফোল্ডারে ইতিমধ্যে বিদ্যমান।';

  @override
  String get conflictInFolder => 'ফোল্ডারে';

  @override
  String get conflictFromTrash => 'ট্র্যাশ থেকে';

  @override
  String get conflictExisting => 'বিদ্যমান';

  @override
  String get conflictNewUpload => 'নতুন আপলোড';

  @override
  String conflictSizeLabel(String size) {
    return 'আকার: $size';
  }

  @override
  String conflictDateLabel(String date) {
    return 'তারিখ: $date';
  }

  @override
  String conflictDeletedLabel(String date) {
    return 'মুছে ফেলার তারিখ: $date';
  }

  @override
  String conflictApplyToRemaining(int count) {
    return 'বাকি দ্বন্দ্বগুলোতে প্রয়োগ করুন ($count)';
  }

  @override
  String get conflictKeepAllCopies => 'সব কপি রাখুন';

  @override
  String get conflictOverwriteAll => 'সব প্রতিস্থাপন করুন';

  @override
  String get conflictRestoreAllAsCopies => 'সব কপি হিসেবে পুনরুদ্ধার করুন';

  @override
  String get conflictRestoreAsCopy => 'কপি হিসেবে পুনরুদ্ধার করুন';

  @override
  String get conflictOverwriteAllRemaining => 'বাকি সব প্রতিস্থাপন করুন';

  @override
  String get conflictSkipAll => 'সব এড়িয়ে যান';

  @override
  String get conflictSkipAllRemaining => 'বাকি সব এড়িয়ে যান';

  @override
  String get conflictSkip => 'এড়িয়ে যান';

  @override
  String get conflictOverwrite => 'প্রতিস্থাপন করুন';

  @override
  String get transfersTitle => 'স্থানান্তর';

  @override
  String get transferResume => 'পুনরায় শুরু করুন';

  @override
  String get transferPause => 'বিরতি দিন';

  @override
  String get transferCancel => 'বাতিল করুন';

  @override
  String get transferResumeAll => 'সব পুনরায় শুরু করুন';

  @override
  String get transferPauseAll => 'সব বিরতি দিন';

  @override
  String get transferCancelAll => 'সব বাতিল করুন';

  @override
  String get transferCancelFile => 'ফাইল বাতিল করুন';

  @override
  String get noTransfers => 'কোনো স্থানান্তর নেই।';

  @override
  String get transferStatusQueued => 'সারিবদ্ধ';

  @override
  String get transferStatusRunning => 'চলছে';

  @override
  String get transferStatusPaused => 'স্থগিত';

  @override
  String get transferStatusCompleted => 'সম্পন্ন';

  @override
  String get transferStatusFailed => 'ব্যর্থ';

  @override
  String get transferStatusCanceled => 'বাতিল';

  @override
  String get themePresetsSection => 'প্রিসেট';

  @override
  String get themeCustomPaletteSection => 'কাস্টম প্যালেট';

  @override
  String get themeHexRgbLabel => 'HEX RGB কোড';

  @override
  String get themeHexRgbHint => '#FA5252';

  @override
  String get imageViewerNoFetchHandler => 'কোনো ফেচ হ্যান্ডলার কনফিগার নেই';

  @override
  String get imageViewerFailedToLoad => 'ছবি লোড করতে ব্যর্থ হয়েছে';

  @override
  String errorDeletingFile(String filename, String error) {
    return '$filename মুছতে ত্রুটি: $error';
  }

  @override
  String errorReadingFile(String error) {
    return 'ফাইল পড়তে ত্রুটি: $error';
  }

  @override
  String get syncChannelName => 'ব্যাকগ্রাউন্ড সিনক্রোনাইজেশন';

  @override
  String get syncChannelDescription =>
      'ব্যাকগ্রাউন্ডে ফাইল সিঙ্ক হওয়ার স্থিতি দেখায়।';

  @override
  String get storageStatsTitle => 'স্টোরেজের পরিসংখ্যান';

  @override
  String get storageStatsUsedSpace => 'ব্যবহৃত স্থান';

  @override
  String get storageStatsTotalFiles => 'মোট ফাইল';

  @override
  String storageStatsNItems(int count) {
    return '$countটি আইটেম';
  }

  @override
  String userFallback(int userId) {
    return 'ব্যবহারকারী #$userId';
  }

  @override
  String get biometricUnlockReason =>
      'Crowley\'s Cloud-এর সংরক্ষিত তথ্য আনলক করুন।';

  @override
  String get tokenLifetimeEveryOpen => 'প্রতিবার অ্যাপ খোলার সময়';

  @override
  String get tokenLifetimeOneHour => '১ ঘণ্টা পর';

  @override
  String get tokenLifetime1Hour => '১ ঘণ্টা পর';

  @override
  String get tokenLifetimeOneDay => '১ দিন পর';

  @override
  String get tokenLifetime1Day => '১ দিন পর';

  @override
  String get tokenLifetimeOneWeek => '১ সপ্তাহ পর';

  @override
  String get tokenLifetime1Week => '১ সপ্তাহ পর';

  @override
  String get tokenLifetimeOneMonth => '১ মাস পর';

  @override
  String get tokenLifetime1Month => '১ মাস পর';

  @override
  String get tokenLifetimeThreeMonths => '৩ মাস পর';

  @override
  String get tokenLifetime3Months => '৩ মাস পর';

  @override
  String get tokenLifetimeNever => 'এই ডিভাইসে কখনও নয়';

  @override
  String get cacheLimitUnlimited => 'সীমাহীন';

  @override
  String get syncCategoryOtherFiles => 'অন্যান্য ফাইল';

  @override
  String get internalStorage => 'অভ্যন্তরীণ স্টোরেজ';

  @override
  String get localStorageRootName => 'অভ্যন্তরীণ স্টোরেজ';

  @override
  String syncNotificationSyncingWith(String serverName) {
    return '$serverName-এর সাথে সিঙ্ক হচ্ছে';
  }

  @override
  String syncNotificationPausedTitle(String serverName) {
    return '$serverName-এর সাথে সিঙ্ক স্থগিত';
  }

  @override
  String get syncNotificationUnreachableBody =>
      'সার্ভারে পৌঁছানো যায়নি। অ্যাপ খোলার আগ পর্যন্ত ব্যাকগ্রাউন্ড সিঙ্ক স্থগিত থাকবে।';

  @override
  String get syncNotificationAuthRequiredBody =>
      'প্রমাণীকরণ প্রয়োজন। লগ ইন করতে অ্যাপটি খুলুন।';

  @override
  String syncNotificationFailedTitle(String serverName) {
    return '$serverName-এর সাথে সিঙ্ক ব্যর্থ হয়েছে';
  }

  @override
  String get syncNotificationGenericErrorBody =>
      'সিঙ্ক করার সময় একটি ত্রুটি ঘটেছে।';

  @override
  String syncNotificationCompleteTitle(String serverName) {
    return '$serverName-এর সাথে সিঙ্ক সম্পূর্ণ';
  }

  @override
  String get syncNotificationCompleteBody => 'সিঙ্ক সম্পূর্ণ।';

  @override
  String get syncStatusConnecting => 'সার্ভারের সাথে সংযোগ করা হচ্ছে...';

  @override
  String syncStatusConnectionLost(String serverName) {
    return '$serverName-এর সাথে সংযোগ করা যায়নি। সংযোগ বিচ্ছিন্ন হয়েছে।';
  }

  @override
  String syncResultServerUnreachableWithServer(String serverName) {
    return '$serverName-এর সাথে সংযোগ করা যায়নি। সংযোগ বিচ্ছিন্ন হয়েছে।';
  }

  @override
  String get syncStatusScanningFiles =>
      'ডিভাইসের ফাইলগুলো স্ক্যান করা হচ্ছে...';

  @override
  String get syncStatusNoFilesFound =>
      'সিঙ্ক করার মতো কোনো ফাইল পাওয়া যায়নি।';

  @override
  String get syncStatusNoFilesSelected =>
      'সিঙ্কের জন্য কোনো ফাইল নির্বাচিত হয়নি।';

  @override
  String syncStatusCalculatingChecksum(
    int current,
    int total,
    String filename,
  ) {
    return 'চেকসাম গণনা করা হচ্ছে ($current/$total): $filename';
  }

  @override
  String get syncStatusCheckingDuplicates =>
      'সার্ভারে ডুপ্লিকেট পরীক্ষা করা হচ্ছে...';

  @override
  String syncStatusSyncingFile(int current, int total, String filename) {
    return 'সিঙ্ক হচ্ছে ($current/$total): $filename';
  }

  @override
  String get syncStatusCompleting => 'সিঙ্ক সম্পূর্ণ করা হচ্ছে...';

  @override
  String get showingCachedFiles => 'ক্যাশ করা ফাইলগুলো দেখানো হচ্ছে।';

  @override
  String get showingCachedFilesRefreshFailed =>
      'ক্যাশ করা ফাইল দেখানো হচ্ছে। রিফ্রেশ ব্যর্থ হয়েছে।';

  @override
  String get downloadCanceled => 'ডাউনলোড বাতিল করা হয়েছে।';

  @override
  String downloadedNFilesToPath(int count, String path) {
    return '$countটি ফাইল $path-এ ডাউনলোড করা হয়েছে';
  }

  @override
  String downloadedNFilesFailedM(int downloaded, int failed, String detail) {
    return '$downloadedটি ফাইল ডাউনলোড করা হয়েছে, $failedটি ব্যর্থ হয়েছে: $detail';
  }

  @override
  String downloadedNFilesWithFailures(int count, int failed, String error) {
    return '$countটি ফাইল ডাউনলোড করা হয়েছে, $failedটি ব্যর্থ হয়েছে: $error';
  }

  @override
  String createdNShareLinks(int count) {
    return '$countটি শেয়ার লিঙ্ক তৈরি করা হয়েছে।';
  }

  @override
  String get failedToCreateShareLinks =>
      'শেয়ার লিঙ্ক তৈরি করতে ব্যর্থ হয়েছে।';

  @override
  String get alreadyInSharedScope => 'ইতিমধ্যে শেয়ার করা স্কোপে রয়েছে।';

  @override
  String sharedNItemsInServer(int count) {
    return 'সার্ভারে $countটি আইটেম শেয়ার করা হয়েছে।';
  }

  @override
  String sharedNItemsWithFailures(int count, int failed) {
    return 'সার্ভারে $countটি আইটেম শেয়ার করা হয়েছে, $failedটি ব্যর্থ হয়েছে।';
  }

  @override
  String sharedNItemsFailedM(int shared, int failed) {
    return 'সার্ভারে $sharedটি আইটেম শেয়ার করা হয়েছে, $failedটি ব্যর্থ হয়েছে।';
  }

  @override
  String get folderNameCannotBeEmpty => 'ফোল্ডারের নাম খালি হতে পারে না।';

  @override
  String get folderAlreadyExists => 'ফোল্ডারটি ইতিমধ্যে বিদ্যমান।';

  @override
  String get folderCreationOnlyInAllFiles =>
      'ফোল্ডার তৈরি শুধুমাত্র সমস্ত ফাইল বিভাগে উপলব্ধ।';

  @override
  String get currentDirectoryUnavailable => 'বর্তমান ডিরেক্টরি অনুপলব্ধ।';

  @override
  String get nothingSelected => 'কিছুই নির্বাচিত হয়নি।';

  @override
  String get destinationFolderDoesNotExist => 'টার্গেট ফোল্ডারটি বিদ্যমান নেই।';

  @override
  String cannotMoveFolderIntoItself(String name) {
    return 'ফোল্ডার \"$name\"-কে নিজের মধ্যে স্থানান্তর করা যাবে না।';
  }

  @override
  String failedToMoveItem(String name, String error) {
    return '\"$name\" স্থানান্তর করতে ব্যর্থ হয়েছে: $error';
  }

  @override
  String movedNItems(int count) {
    return '$countটি আইটেম স্থানান্তর করা হয়েছে।';
  }

  @override
  String movedNItemsWithFailures(int count, int failed) {
    return '$countটি আইটেম স্থানান্তর করা হয়েছে, $failedটি ব্যর্থ হয়েছে।';
  }

  @override
  String movedNItemsFailedM(int moved, int failed) {
    return '$movedটি আইটেম স্থানান্তর করা হয়েছে, $failedটি ব্যর্থ হয়েছে।';
  }

  @override
  String get failedToMoveSelectedItems =>
      'নির্বাচিত আইটেম স্থানান্তর করতে ব্যর্থ হয়েছে।';

  @override
  String get noFilesWereMoved => 'কোনো ফাইল স্থানান্তর করা হয়নি।';

  @override
  String renamedOldToNew(String oldName, String newName) {
    return '\"$oldName\"-এর নাম পরিবর্তন করে \"$newName\" রাখা হয়েছে।';
  }

  @override
  String renamedFileFromTo(String oldName, String newName) {
    return '\"$oldName\"-এর নাম পরিবর্তন করে \"$newName\" রাখা হয়েছে।';
  }

  @override
  String failedToRenameWithStatus(String name, int statusCode) {
    return '\"$name\"-এর নাম পরিবর্তন করতে ব্যর্থ হয়েছে ($statusCode)।';
  }

  @override
  String failedToRenameFileWithCode(String name, int statusCode) {
    return '\"$name\"-এর নাম পরিবর্তন করতে ব্যর্থ হয়েছে ($statusCode)।';
  }

  @override
  String failedToRenameWithError(String name, String error) {
    return '\"$name\"-এর নাম পরিবর্তন করতে ব্যর্থ হয়েছে: $error';
  }

  @override
  String failedToRenameFile(String name, String error) {
    return '\"$name\"-এর নাম পরিবর্তন করতে ব্যর্থ হয়েছে: $error';
  }

  @override
  String get renameConflictAlreadyExists =>
      'নাম পরিবর্তন ব্যর্থ হয়েছে: ওই নামের একটি ফাইল বা ফোল্ডার ইতিমধ্যে বিদ্যমান।';

  @override
  String get renameFailedAlreadyExists =>
      'নাম পরিবর্তন ব্যর্থ হয়েছে: ওই নামের একটি ফাইল বা ফোল্ডার ইতিমধ্যে বিদ্যমান।';

  @override
  String failedToCreateFolderWithCode(int statusCode) {
    return 'ফোল্ডার তৈরি করতে ব্যর্থ হয়েছে ($statusCode)।';
  }

  @override
  String deletedNItemsFailedM(int deleted, int failed) {
    return '$deletedটি আইটেম মুছে ফেলা হয়েছে, $failedটি ব্যর্থ হয়েছে।';
  }

  @override
  String transferSummaryFiles(int percent, int completed, int total) {
    return '$percent%  $completed/$total ফাইল';
  }

  @override
  String transferSummaryProgress(int percent, int completed, int total) {
    return '$percent%  $completed/$total';
  }

  @override
  String get downloadFailedGeneric => 'ডাউনলোড ব্যর্থ হয়েছে';

  @override
  String uploadedNItemsWithFailures(int uploaded, int failed) {
    return '$uploadedটি আইটেম আপলোড করা হয়েছে, $failedটি ব্যর্থ হয়েছে';
  }

  @override
  String uploadedNItemsFailedM(int uploaded, int failed) {
    return '$uploadedটি আইটেম আপলোড করা হয়েছে, $failedটি ব্যর্থ হয়েছে।';
  }

  @override
  String uploadSummaryFailedCount(int count) {
    return ', $countটি ব্যর্থ';
  }

  @override
  String uploadLocalPathEmpty(String name) {
    return '$name: স্থানীয় পাথ খালি';
  }

  @override
  String uploadErrorLocalPathEmpty(String name) {
    return '$name: স্থানীয় পাথ খালি';
  }

  @override
  String get directoryUploadFailed => 'ডিরেক্টরি আপলোড ব্যর্থ হয়েছে';

  @override
  String get uploadDirectoryFailed => 'ডিরেক্টরি আপলোড ব্যর্থ হয়েছে';

  @override
  String get localFileNotFound => 'স্থানীয় ফাইল পাওয়া যায়নি';

  @override
  String get uploadErrorLocalFileNotFound => 'স্থানীয় ফাইল পাওয়া যায়নি';

  @override
  String get noSessionToken => 'কোনো সক্রিয় সেশন টোকেন নেই';

  @override
  String get uploadErrorNoSessionToken => 'কোনো সক্রিয় সেশন টোকেন নেই';

  @override
  String get serverDisconnectedStatus => 'সার্ভার সংযোগ বিচ্ছিন্ন হয়েছে';

  @override
  String get serverDisconnected => 'সার্ভার সংযোগ বিচ্ছিন্ন হয়েছে';

  @override
  String get serverIsUnreachable => 'সার্ভারে পৌঁছানো যায়নি।';

  @override
  String get serverUnreachable => 'সার্ভারে পৌঁছানো যায়নি।';

  @override
  String get uploadErrorLocalDirectoryNotFound =>
      'স্থানীয় ডিরেক্টরি পাওয়া যায়নি';

  @override
  String get uploadErrorFailedToScanDirectory =>
      'ডিরেক্টরি স্ক্যান করতে ব্যর্থ হয়েছে';

  @override
  String uploadErrorFolderCreateHttp(int statusCode) {
    return 'ফোল্ডার তৈরি ব্যর্থ হয়েছে (HTTP $statusCode)';
  }

  @override
  String get authErrorMissingAccessToken =>
      'প্রতিক্রিয়ায় অ্যাক্সেস টোকেন অনুপস্থিত';

  @override
  String get authErrorMissingRefreshToken =>
      'প্রতিক্রিয়ায় রিফ্রেশ টোকেন অনুপস্থিত';

  @override
  String get authErrorNoSavedCredentials => 'কোনো সংরক্ষিত তথ্য উপলব্ধ নেই';

  @override
  String get authErrorNoRefreshToken => 'কোনো রিফ্রেশ টোকেন উপলব্ধ নেই';

  @override
  String get authErrorNoActiveSession => 'কোনো সক্রিয় সেশন উপলব্ধ নেই';

  @override
  String get authErrorNoSavedUsername => 'কোনো সংরক্ষিত ব্যবহারকারীর নাম নেই';

  @override
  String get updateNoReleasesPublished => 'এখনও কোনো রিলিজ প্রকাশিত হয়নি।';

  @override
  String get language => 'ভাষা';
}
