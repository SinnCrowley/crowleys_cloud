// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Crowley\'s Cloud';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सहेजें';

  @override
  String get delete => 'हटाएं';

  @override
  String get rename => 'नाम बदलें';

  @override
  String get close => 'बंद करें';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String get error => 'त्रुटि';

  @override
  String errorWithMessage(String message) {
    return 'त्रुटि: $message';
  }

  @override
  String get unknown => 'अज्ञात';

  @override
  String get upload => 'अपलोड';

  @override
  String get download => 'डाउनलोड';

  @override
  String get share => 'साझा करें';

  @override
  String get copy => 'कॉपी करें';

  @override
  String get move => 'स्थानांतरित करें';

  @override
  String get restore => 'पुनर्स्थापित करें';

  @override
  String get apply => 'लागू करें';

  @override
  String get create => 'बनाएँ';

  @override
  String get clear => 'साफ़ करें';

  @override
  String get add => 'जोड़ें';

  @override
  String get remove => 'हटाएं';

  @override
  String get edit => 'संपादित करें';

  @override
  String get switchLabel => 'बदलें';

  @override
  String get search => 'खोजें';

  @override
  String get name => 'नाम';

  @override
  String get date => 'तारीख';

  @override
  String get size => 'आकार';

  @override
  String get type => 'प्रकार';

  @override
  String get ascending => 'आरोही';

  @override
  String get descending => 'अवरोही';

  @override
  String get allFiles => 'सभी';

  @override
  String get categoryImages => 'छवियां';

  @override
  String get categoryPhotos => 'फ़ोटो';

  @override
  String get categoryVideos => 'वीडियो';

  @override
  String get categoryAudio => 'ऑडियो';

  @override
  String get categoryDocuments => 'दस्तावेज़';

  @override
  String get categoryArchives => 'अभिलेखागार';

  @override
  String get categoryShared => 'साझा किए गए';

  @override
  String get categoryOther => 'अन्य';

  @override
  String get categoryOtherFiles => 'अन्य फ़ाइलें';

  @override
  String get noFilesFound => 'कोई फ़ाइल नहीं मिली।';

  @override
  String get noFilesInFolder => 'इस फ़ोल्डर में कोई फ़ाइल नहीं है।';

  @override
  String get thisActionCannotBeUndone => 'यह क्रिया पूर्ववत नहीं की जा सकती।';

  @override
  String get passwordsDoNotMatch => 'पासवर्ड मेल नहीं खाते।';

  @override
  String get navLocalFiles => 'स्थानीय फ़ाइलें';

  @override
  String get navServerFiles => 'सर्वर फ़ाइलें';

  @override
  String get navSettings => 'सेटिंग्स';

  @override
  String get navTrash => 'ट्रैश';

  @override
  String get navLocal => 'स्थानीय';

  @override
  String get navServer => 'सर्वर';

  @override
  String get addServer => 'सर्वर जोड़ें';

  @override
  String get noServersConfigured => 'कोई सर्वर कॉन्फ़िगर नहीं किया गया है।';

  @override
  String get addAServerInSettings => 'सेटिंग्स में एक सर्वर जोड़ें।';

  @override
  String get addFirstServerHint => 'जारी रखने के लिए अपना पहला सर्वर जोड़ें।';

  @override
  String get noServersConfiguredYet =>
      'अभी तक कोई सर्वर कॉन्फ़िगर नहीं किया गया है।';

  @override
  String get crowleysCloudSetup => 'Crowley\'s Cloud सेटअप';

  @override
  String get connect => 'कनेक्ट करें';

  @override
  String get connecting => 'कनेक्ट हो रहा है...';

  @override
  String get connected => 'कनेक्ट हो गया';

  @override
  String get disconnected => 'डिस्कनेक्ट हो गया';

  @override
  String get switchServer => 'सर्वर बदलें';

  @override
  String get chooseOtherServer => 'दूसरा सर्वर चुनें';

  @override
  String get switchServerTitle => 'सर्वर बदलें?';

  @override
  String switchServerBody(String serverName) {
    return 'क्या सक्रिय सर्वर को \"$serverName\" पर बदलना चाहते हैं?';
  }

  @override
  String get chooseServer => 'सर्वर चुनें';

  @override
  String get authenticationRequired => 'प्रमाणीकरण आवश्यक है';

  @override
  String signInToAccess(String serverName) {
    return '$serverName पर फ़ाइलों तक पहुँचने के लिए साइन इन करें';
  }

  @override
  String get signInWithPassword => 'पासवर्ड से साइन इन करें';

  @override
  String get useBiometrics => 'बायोमेट्रिक्स का उपयोग करें';

  @override
  String get openingSignIn => 'साइन इन खोला जा रहा है...';

  @override
  String get serverConnectionFailed => 'सर्वर कनेक्शन विफल';

  @override
  String get unableToConnectToServer =>
      'सक्रिय सर्वर से कनेक्ट करने में असमर्थ।';

  @override
  String unableToConnectTo(String serverName) {
    return '$serverName से कनेक्ट करने में असमर्थ।';
  }

  @override
  String get searchHint => 'खोजें...';

  @override
  String get searchFilesHint => 'फ़ाइलें खोजें...';

  @override
  String get searchServerFilesHint => 'सर्वर फ़ाइलें खोजें...';

  @override
  String get searchTrashHint => 'ट्रैश में खोजें...';

  @override
  String get storagePermissionRequired => 'स्टोरेज अनुमति आवश्यक है';

  @override
  String get grantPermission => 'अनुमति दें';

  @override
  String get permissionDeniedOpenSettings =>
      'अनुमति अस्वीकार कर दी गई। कृपया सेटिंग्स में स्टोरेज एक्सेस दें।';

  @override
  String get manageStoragePermissionRequired =>
      'फ़ोल्डरों को ब्राउज़ करने और चुनने के लिए मैनेज स्टोरेज अनुमति आवश्यक है।';

  @override
  String get storagePermissionsRequired =>
      'सिंक्रनाइज़ेशन करने के लिए स्टोरेज अनुमतियाँ आवश्यक हैं।';

  @override
  String updateAvailableTitle(String version) {
    return 'अपडेट उपलब्ध है: v$version';
  }

  @override
  String get updateAvailableTapToSeeNew => 'नया क्या है देखने के लिए टैप करें';

  @override
  String get updateView => 'देखें';

  @override
  String get updateAvailableDialogTitle => 'अपडेट उपलब्ध है';

  @override
  String updateVersionSubtitle(String version) {
    return 'संस्करण $version';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'वर्तमान: v$version';
  }

  @override
  String updateNewVersion(String version) {
    return 'नया: v$version';
  }

  @override
  String get updateWhatsNew => 'नया क्या है:';

  @override
  String get updateGitHub => 'GitHub';

  @override
  String get updateNoReleaseNotes => 'कोई रिलीज़ नोट उपलब्ध नहीं है।';

  @override
  String get updateLater => 'बाद में';

  @override
  String get updateDownloadApk => 'APK डाउनलोड करें';

  @override
  String get updateInstall => 'अपडेट करें';

  @override
  String get shareLinkTitle => 'साझा लिंक';

  @override
  String get shareViaLink => 'लिंक के माध्यम से साझा करें';

  @override
  String get shareInServer => 'सर्वर में साझा करें';

  @override
  String get expiryDays => 'समाप्ति (दिन)';

  @override
  String get expiryNever => 'कभी नहीं';

  @override
  String get expiry1Day => '1 दिन';

  @override
  String get expiry7Days => '7 दिन';

  @override
  String get expiry30Days => '30 दिन';

  @override
  String get expiry90Days => '90 दिन';

  @override
  String get expiry180Days => '180 दिन';

  @override
  String get expiry365Days => '365 दिन';

  @override
  String get createLink => 'लिंक बनाएं';

  @override
  String get sharedLinkCopied => 'साझा लिंक क्लिपबोर्ड पर कॉपी हो गया!';

  @override
  String failedToCopySharedLink(String error) {
    return 'साझा लिंक कॉपी करने में विफल: $error';
  }

  @override
  String get cannotShareThisFileType =>
      'इस प्रकार की फ़ाइल साझा नहीं की जा सकती।';

  @override
  String failedToCreateShare(String error) {
    return 'शेयर बनाने में विफल: $error';
  }

  @override
  String get newFolderTitle => 'फ़ोल्डर बनाएं';

  @override
  String get newFolderHint => 'फ़ोल्डर का नाम';

  @override
  String get newFolder => 'नया फ़ोल्डर';

  @override
  String get folderCreated => 'फ़ोल्डर बन गया।';

  @override
  String failedToCreateFolder(String error) {
    return 'फ़ोल्डर बनाने में विफल: $error';
  }

  @override
  String get creatingFolder => 'फ़ोल्डर बनाया जा रहा है...';

  @override
  String get renameDialogTitle => 'नाम बदलें';

  @override
  String get renameHint => 'नया नाम';

  @override
  String get enterNewName => 'नया नाम दर्ज करें';

  @override
  String get renamedSuccessfully => 'सफलतापूर्वक नाम बदल दिया गया।';

  @override
  String renameFailed(String error) {
    return 'नाम बदलना विफल रहा: $error';
  }

  @override
  String get moveDialogTitle => 'यहाँ ले जाएँ';

  @override
  String moveTo(String path) {
    return 'यहाँ स्थानांतरित करें: $path';
  }

  @override
  String get moveHere => 'यहाँ ले जाएँ';

  @override
  String moveFailed(String error) {
    return 'स्थानांतरण विफल: $error';
  }

  @override
  String get movedToFolder => 'फ़ोल्डर में स्थानांतरित किया गया।';

  @override
  String copyFailed(String error) {
    return 'कॉपी करना विफल: $error';
  }

  @override
  String get selectFolder => 'फ़ोल्डर चुनें';

  @override
  String get useThisFolder => 'इस फ़ोल्डर का उपयोग करें';

  @override
  String get storageRoot => 'स्टोरेज';

  @override
  String get serverRoot => 'रूट';

  @override
  String deleteNItemsTitle(int count) {
    return 'क्या $count आइटम हटाना चाहते हैं?';
  }

  @override
  String get deleteFilesTitle => 'फ़ाइलें हटाएं?';

  @override
  String deleteFilesBody(int count) {
    return 'क्या आप वाकई $count चयनित आइटम हटाना चाहते हैं? इसे पूर्ववत नहीं किया जा सकता है।';
  }

  @override
  String get deletePermanently => 'हमेशा के लिए हटाएं';

  @override
  String get deletePermanentlyTitle => 'हमेशा के लिए हटाएं?';

  @override
  String deletePermanentlyBody(String filename) {
    return '$filename को हमेशा के लिए हटा दिया जाएगा।';
  }

  @override
  String get deleteFileTitle => 'फ़ाइल हटाएं?';

  @override
  String deleteFileBody(String filename) {
    return 'क्या आप वाकई $filename को हटाना चाहते हैं? इसे पूर्ववत नहीं किया जा सकता है।';
  }

  @override
  String get deleteServerFileTitle => 'हमेशा के लिए हटाएं';

  @override
  String deleteServerFileBody(String filename) {
    return 'क्या आप वाकई \"$filename\" को हमेशा के लिए हटाना चाहते हैं? इसे पूर्ववत नहीं किया जा सकता है।';
  }

  @override
  String get unshareItemsTitle => 'आइटम का साझाकरण हटाएं?';

  @override
  String unshareItemsBody(int count) {
    return 'क्या आप वाकई $count चयनित आइटम का साझाकरण हटाना चाहते हैं? यह उन्हें साझा किए गए फ़ोल्डर से हटा देगा।';
  }

  @override
  String get unshare => 'साझाकरण हटाएं';

  @override
  String get moveToTrash => 'ट्रैश में ले जाएँ';

  @override
  String get movedToTrash => 'ट्रैश में ले जाया गया।';

  @override
  String movedNItemsToTrash(int count) {
    return '$count आइटम ट्रैश में ले जाए गए।';
  }

  @override
  String failedToMoveToTrash(String error) {
    return 'ट्रैश में ले जाने में विफल: $error';
  }

  @override
  String deletedNItems(int count) {
    return '$count आइटम हटा दिए गए।';
  }

  @override
  String failedToDelete(String error) {
    return 'हटाने में विफल: $error';
  }

  @override
  String failedToDeleteItem(String error) {
    return 'हटाना विफल रहा: $error';
  }

  @override
  String deletedFilename(String filename) {
    return '$filename हटा दिया गया।';
  }

  @override
  String get failedToOpenFile => 'फ़ाइल खोलने में विफल';

  @override
  String fileDownloadFailed(String error) {
    return 'फ़ाइल डाउनलोड विफल: $error';
  }

  @override
  String get downloading => 'डाउनलोड हो रहा है...';

  @override
  String get downloadingFile => 'फ़ाइल डाउनलोड हो रही है...';

  @override
  String downloadComplete(String filename) {
    return 'डाउनलोड पूर्ण: $filename';
  }

  @override
  String downloadFailed(String error) {
    return 'डाउनलोड विफल: $error';
  }

  @override
  String get failedToDownloadPreview =>
      'फ़ाइल पूर्वावलोकन डाउनलोड करने में विफल';

  @override
  String uploadComplete(String filename) {
    return 'अपलोड पूर्ण: $filename';
  }

  @override
  String uploadFailed(String error) {
    return 'अपलोड विफल: $error';
  }

  @override
  String get failedToPickFiles => 'फ़ाइलें चुनने में विफल';

  @override
  String uploadedNItems(int count) {
    return '$count आइटम अपलोड किए गए';
  }

  @override
  String get copiedLinkToClipboard => 'लिंक क्लिपबोर्ड पर कॉपी किया गया।';

  @override
  String failedToCopyLink(String error) {
    return 'लिंक कॉपी करने में विफल: $error';
  }

  @override
  String get selectingAll => 'सभी का चयन किया जा रहा है...';

  @override
  String get allItemsSelected => 'सभी आइटम चुने गए।';

  @override
  String get failedToLoadSearchResults => 'खोज परिणाम लोड करने में विफल';

  @override
  String get shareNotSupportedForType =>
      'इस फ़ाइल प्रकार के लिए शेयर समर्थित नहीं है।';

  @override
  String nSelected(int count) {
    return '$count चयनित';
  }

  @override
  String get noServerSelected => 'कोई सर्वर चयनित नहीं है';

  @override
  String get pleaseConnectToServerFirst => 'कृपया पहले सर्वर से कनेक्ट करें।';

  @override
  String get signInRequired => 'साइन इन आवश्यक है';

  @override
  String pleaseSignInToServer(String serverName) {
    return 'कृपया पहले \"$serverName\" में साइन इन करें।';
  }

  @override
  String get connectingToServer => 'सर्वर से कनेक्ट हो रहा है...';

  @override
  String connectedToServer(String serverName) {
    return '$serverName से कनेक्ट हो गया।';
  }

  @override
  String connectionFailed(String error) {
    return 'कनेक्शन विफल: $error';
  }

  @override
  String failedToConnect(String error) {
    return 'कनेक्ट करने में विफल: $error';
  }

  @override
  String authFailed(String error) {
    return 'प्रमाणीकरण विफल: $error';
  }

  @override
  String get authFailedGeneric =>
      'प्रमाणीकरण विफल रहा। कृपया पुनः प्रयास करें।';

  @override
  String biometricLoginFailed(String error) {
    return 'बायोमेट्रिक लॉगिन विफल: $error';
  }

  @override
  String get biometricLoginFailedGeneric => 'बायोमेट्रिक लॉगिन विफल रहा।';

  @override
  String get noServerSessionToken =>
      'कोई सर्वर सत्र टोकन नहीं है। सर्वर को पुनः प्रमाणित करें।';

  @override
  String failedToSaveServer(String error) {
    return 'सर्वर सहेजने में विफल: $error';
  }

  @override
  String get addToFolder => 'फ़ोल्डर में जोड़ें';

  @override
  String get loginTabLabel => 'लॉगिन';

  @override
  String get registerTabLabel => 'पंजीकरण';

  @override
  String get welcomeBack => 'वापसी पर स्वागत है';

  @override
  String get signInToContinue => 'जारी रखने के लिए साइन इन करें';

  @override
  String get createAccount => 'खाता बनाएं';

  @override
  String get joinTheServer => 'सर्वर से जुड़ें';

  @override
  String get usernameLabel => 'उपयोगकर्ता नाम';

  @override
  String get usernameHint => 'अपना उपयोगकर्ता नाम दर्ज करें';

  @override
  String get passwordLabel => 'पासवर्ड';

  @override
  String get passwordHint => 'अपना पासवर्ड दर्ज करें';

  @override
  String get showPassword => 'पासवर्ड दिखाएं';

  @override
  String get hidePassword => 'पासवर्ड छुपाएं';

  @override
  String get confirmPassword => 'पासवर्ड की पुष्टि करें';

  @override
  String get logIn => 'लॉग इन करें';

  @override
  String get loggingIn => 'लॉग इन हो रहा है...';

  @override
  String get registering => 'पंजीकरण हो रहा है...';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get doNotHaveAccount => 'खाता नहीं है? पंजीकरण पर स्विच करें।';

  @override
  String get alreadyHaveAccount => 'पहले से खाता है? लॉगिन पर स्विच करें।';

  @override
  String get usernameCannotBeEmpty => 'उपयोगकर्ता नाम खाली नहीं हो सकता।';

  @override
  String get passwordCannotBeEmpty => 'पासवर्ड खाली नहीं हो सकता।';

  @override
  String get usernameInvalid =>
      'उपयोगकर्ता नाम 3–32 वर्ण, अक्षर, संख्या, _ या - होना चाहिए।';

  @override
  String get passwordTooShort => 'पासवर्ड कम से कम 8 वर्णों का होना चाहिए।';

  @override
  String loginFailed(String error) {
    return 'लॉगिन विफल: $error';
  }

  @override
  String registrationFailed(String error) {
    return 'पंजीकरण विफल: $error';
  }

  @override
  String get resetPasswordTitle => 'पासवर्ड रीसेट करें';

  @override
  String get enterResetCodeTitle => 'रीसेट कोड दर्ज करें';

  @override
  String get resetPasswordStep1Body =>
      'अपना उपयोगकर्ता नाम दर्ज करें। 6-अंकीय सत्यापन कोड सर्वर लॉग/कंसोल में मुद्रित होगा।';

  @override
  String get resetPasswordStep2Body =>
      'सत्यापन कोड सर्वर कंसोल पर मुद्रित किया गया है। 6-अंकीय कोड और अपना नया पासवर्ड दर्ज करें।';

  @override
  String get resetCodeLabel => 'रीसेट कोड';

  @override
  String get resetCodeHint => '6 अंकों का कोड दर्ज करें';

  @override
  String get newPasswordLabel => 'नया पासवर्ड';

  @override
  String get newPasswordHint => 'नया पासवर्ड दर्ज करें';

  @override
  String get passwordResetSuccessfully => 'पासवर्ड सफलतापूर्वक रीसेट हो गया!';

  @override
  String get usernameIsRequired => 'उपयोगकर्ता नाम आवश्यक है।';

  @override
  String get codeAndPasswordRequired => 'कोड और नया पासवर्ड आवश्यक हैं।';

  @override
  String get failedToRequestReset =>
      'रीसेट अनुरोध विफल रहा। सर्वर URL सत्यापित करें।';

  @override
  String get failedToResetPassword =>
      'पासवर्ड रीसेट करने में विफल। कृपया कोड जांचें।';

  @override
  String get pleaseEnterServerUrlFirst => 'कृपया पहले सर्वर URL दर्ज करें।';

  @override
  String get sendCode => 'कोड भेजें';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get sectionBackupSync => 'बैकअप और सिंक';

  @override
  String get sectionStorageCache => 'स्टोरेज और कैश';

  @override
  String get sectionSecurityBehavior => 'सुरक्षा और व्यवहार';

  @override
  String get sectionAboutUpdates => 'ऐप के बारे में और अपडेट';

  @override
  String get sectionAppearance => 'दिखावट और अनुकूलन';

  @override
  String get noServersConfiguredSync => 'कोई सर्वर कॉन्फ़िगर नहीं है';

  @override
  String get addServerBeforeSync =>
      'सिंक कॉन्फ़िगर करने से पहले एक सर्वर जोड़ें।';

  @override
  String get selectServerToConfigureSync =>
      'इसकी सिंक सेटिंग्स कॉन्फ़िगर करने के लिए एक सर्वर चुनें।';

  @override
  String get activeServerSuffix => '· सक्रिय';

  @override
  String get folderAndCategorySync => 'फ़ोल्डर और श्रेणी सिंक';

  @override
  String get keepCategoriesSynced =>
      'चयनित स्थानीय श्रेणियों या फ़ोल्डरों को इस सर्वर के साथ सिंक रखें।';

  @override
  String get addServerBeforeSyncEnable =>
      'सिंक्रनाइज़ेशन सक्षम करने से पहले एक सर्वर जोड़ें।';

  @override
  String get onlyOnWifi => 'केवल वाई-फ़ाई पर';

  @override
  String get onlyWhileCharging => 'केवल चार्ज करते समय';

  @override
  String get serverTargetDirectory => 'सर्वर लक्ष्य निर्देशिका';

  @override
  String get serverTargetDirectoryHint => '/backup/mobile_phone';

  @override
  String get synchronizationFrequency => 'सिंक्रनाइज़ेशन आवृत्ति';

  @override
  String get syncNow => 'अभी सिंक करें';

  @override
  String get syncing => 'सिंक हो रहा है...';

  @override
  String get categoriesToSynchronize => 'सिंक करने के लिए श्रेणियां';

  @override
  String get noCategoriesSelected => 'कोई श्रेणी नहीं चुनी गई।';

  @override
  String nCategoriesSelected(int count) {
    return '$count चयनित';
  }

  @override
  String get foldersToSynchronize => 'सिंक करने के लिए फ़ोल्डर';

  @override
  String get noCustomFolders => 'कोई कस्टम फ़ोल्डर कॉन्फ़िगर नहीं किया गया है।';

  @override
  String nFolders(int count) {
    return '$count फ़ोल्डर';
  }

  @override
  String get addFolder => 'फ़ोल्डर जोड़ें';

  @override
  String get removeFolder => 'फ़ोल्डर हटाएं';

  @override
  String get removeServer => 'सर्वर हटाएं';

  @override
  String get syncFreqEvery15Min => 'हर 15 मिनट';

  @override
  String get syncFreqEvery30Min => 'हर 30 मिनट';

  @override
  String get syncFreqEvery1Hour => 'हर घंटे';

  @override
  String syncFreqEveryNHours(int hours) {
    return 'हर $hours घंटे';
  }

  @override
  String syncFreqEveryNMin(int minutes) {
    return 'हर $minutes मिनट';
  }

  @override
  String get syncFreqDaily => 'दैनिक';

  @override
  String get chooseSyncFrequencyTitle => 'सिंक आवृत्ति चुनें';

  @override
  String get cacheSize => 'कैश आकार';

  @override
  String get refreshTooltip => 'रिफ्रेश करें';

  @override
  String get cacheLimit => 'कैश सीमा';

  @override
  String get downloadPath => 'डाउनलोड पथ';

  @override
  String get defaultDownloadFolder => 'डिफ़ॉल्ट CrowleysCloud फ़ोल्डर';

  @override
  String get clearCache => 'कैश साफ़ करें';

  @override
  String get clearCacheTitle => 'कैश साफ़ करें?';

  @override
  String get clearCacheBody =>
      'यह स्थानीय थंबनेल और कैश्ड सर्वर सूचियों को हटा देगा।';

  @override
  String get downloadPathDialogTitle => 'डाउनलोड पथ';

  @override
  String get downloadPathHint => '/storage/emulated/0/CrowleysCloud';

  @override
  String get useDefault => 'डिफ़ॉल्ट का उपयोग करें';

  @override
  String get serverTargetDirDialogTitle => 'सर्वर लक्ष्य निर्देशिका';

  @override
  String get requireLogin => 'लॉगिन आवश्यक करें';

  @override
  String get biometricLogin => 'बायोमेट्रिक लॉगिन';

  @override
  String get biometricLoginSubtitle =>
      'बायोमेट्रिक्स के साथ सहेजे गए क्रेडेंशियल से लॉगिन की अनुमति दें।';

  @override
  String get biometricsNotAvailable =>
      'इस डिवाइस पर बायोमेट्रिक्स उपलब्ध नहीं हैं।';

  @override
  String get showHiddenFiles => 'छिपी हुई फ़ाइलें दिखाएं';

  @override
  String get showHiddenFilesSubtitle =>
      'डॉट-फ़ाइलें और डॉट-फ़ोल्डर प्रदर्शित करें।';

  @override
  String get changePassword => 'पासवर्ड बदलें';

  @override
  String changePasswordSubtitle(String serverName) {
    return '$serverName के लिए पासवर्ड अपडेट करें।';
  }

  @override
  String get addServerBeforeChangePassword =>
      'पासवर्ड बदलने से पहले एक सर्वर जोड़ें।';

  @override
  String get deleteUserAccount => 'उपयोगकर्ता खाता हटाएं';

  @override
  String get deleteUserAccountSubtitle =>
      'उपयोगकर्ता और सभी निजी क्लाउड फ़ाइलों को हटा देता है।';

  @override
  String get deleteAccountTitle => 'खाता हटाएं?';

  @override
  String deleteAccountBody(String serverName) {
    return 'यह स्थायी रूप से $serverName पर आपका खाता हटा देगा और आपके निजी क्लाउड फ़ोल्डर में संग्रहीत सभी फ़ाइलों को मिटा देगा। इसे पूर्ववत नहीं किया जा सकता है।';
  }

  @override
  String get deleteAccountButton => 'खाता हटाएं';

  @override
  String get changePasswordDialogTitle => 'पासवर्ड बदलें';

  @override
  String get newPasswordFieldLabel => 'नया पासवर्ड';

  @override
  String get confirmPasswordLabel => 'पासवर्ड की पुष्टि करें';

  @override
  String get enterNewPassword => 'एक नया पासवर्ड दर्ज करें।';

  @override
  String get passwordUpdated => 'पासवर्ड अपडेट हो गया।';

  @override
  String passwordChangeFailed(String error) {
    return 'पासवर्ड बदलना विफल रहा: $error';
  }

  @override
  String get passwordChangeFailedGeneric => 'पासवर्ड बदलना विफल रहा।';

  @override
  String get accountDeleted => 'खाता हटा दिया गया।';

  @override
  String accountDeletionFailed(String error) {
    return 'खाता हटाना विफल रहा: $error';
  }

  @override
  String get accountDeletionFailedGeneric => 'खाता हटाना विफल रहा।';

  @override
  String get checkForUpdates => 'अपडेट के लिए जांचें';

  @override
  String get checkingForUpdates => 'GitHub Releases की जांच की जा रही है...';

  @override
  String versionLabel(String version) {
    return 'संस्करण $version';
  }

  @override
  String appIsUpToDate(String version) {
    return 'Crowley\'s Cloud अप-टू-डेट है (v$version)।';
  }

  @override
  String get updateCheckFailed =>
      'अपडेट की जांच करने में विफल। कृपया बाद में पुनः प्रयास करें।';

  @override
  String get themeModeTitle => 'थीम मोड';

  @override
  String get themeDark => 'गहरा';

  @override
  String get themeLight => 'हल्का';

  @override
  String get themeCustom => 'कस्टम';

  @override
  String get themeDarkFull => 'डार्क थीम';

  @override
  String get themeLightFull => 'लाइट थीम';

  @override
  String get themeCustomFull => 'कस्टम थीम';

  @override
  String get accentColor => 'एक्सेंट रंग';

  @override
  String get primaryAccentColor => 'प्राथमिक एक्सेंट रंग';

  @override
  String get selectAccentColor => 'एक्सेंट रंग चुनें';

  @override
  String get backgroundColor => 'पृष्ठभूमि का रंग';

  @override
  String get surfaceColor => 'सतह का रंग';

  @override
  String get textColor => 'टेक्स्ट का रंग';

  @override
  String get subtextColor => 'सबटेक्स्ट का रंग';

  @override
  String get borderColor => 'बॉर्डर का रंग';

  @override
  String get fontSizeScale => 'फ़ॉन्ट का आकार';

  @override
  String selectColor(String title) {
    return '$title चुनें';
  }

  @override
  String get categoriesToSyncDialogTitle => 'सिंक करने के लिए श्रेणियां';

  @override
  String get categoriesToSyncBody =>
      'एक या अधिक श्रेणियां चुनें। सब कुछ अनचेक छोड़ना भी मान्य है।';

  @override
  String get syncCategorySectionMedia => 'मीडिया';

  @override
  String get syncCategorySectionAudioDocs => 'ऑडियो और दस्तावेज़';

  @override
  String get syncCategorySectionOther => 'अन्य';

  @override
  String get clearAll => 'सभी साफ़ करें';

  @override
  String get noSyncHasRunYet => 'अभी तक कोई सिंक नहीं चला है।';

  @override
  String lastRunAt(String date) {
    return 'अंतिम बार $date को चला';
  }

  @override
  String syncResultSuccess(int uploaded, int skipped) {
    return '$uploaded सिंक किए गए, $skipped छोड़े गए।';
  }

  @override
  String get syncResultNoFiles => 'सिंक के लिए कोई फ़ाइल नहीं चुनी गई।';

  @override
  String syncResultPartial(int uploaded, int failed) {
    return '$uploaded सिंक किए गए, $failed विफल रहे।';
  }

  @override
  String get syncResultAuthRequired => 'सिंक करने से पहले साइन इन करें।';

  @override
  String get syncResultUnreachable =>
      'सर्वर तक पहुँचने में असमर्थ। कनेक्शन टूट गया।';

  @override
  String get syncResultFailed => 'सिंक विफल रहा।';

  @override
  String get serverSetupAddServer => 'सर्वर जोड़ें';

  @override
  String get serverSetupCardTitle => 'सर्वर कनेक्ट करें';

  @override
  String get serverSetupCardSubtitle =>
      'अपना होम फ़ाइल सर्वर जोड़ें और साइन इन करें।';

  @override
  String get serverSetupSubmitButton => 'सर्वर सहेजें';

  @override
  String get serverNameLabel => 'सर्वर का नाम';

  @override
  String get serverNameHint => 'Home NAS';

  @override
  String get baseUrlLabel => 'बेस URL';

  @override
  String get baseUrlHint => 'https://cloud.example.com';

  @override
  String get allFieldsRequired => 'सभी फ़ील्ड आवश्यक हैं।';

  @override
  String get localFilesTitle => 'स्थानीय फ़ाइलें';

  @override
  String get serverFilesTitle => 'सर्वर फ़ाइलें';

  @override
  String get restoreItemsTitle => 'आइटम पुनर्स्थापित करें';

  @override
  String restoreItemsBody(int count) {
    return 'क्या आप वाकई $count आइटम पुनर्स्थापित करना चाहते हैं?';
  }

  @override
  String get permanentlyDeleteTitle => 'हमेशा के लिए हटाएं';

  @override
  String permanentlyDeleteBody(int count) {
    return 'क्या आप वाकई $count आइटम हमेशा के लिए हटाना चाहते हैं? इसे पूर्ववत नहीं किया जा सकता है।';
  }

  @override
  String get trashIsEmpty => 'ट्रैश खाली है।';

  @override
  String trashRetentionInfo(int days) {
    return 'ट्रैश में मौजूद आइटम $days दिनों के बाद स्वचालित रूप से हटा दिए जाते हैं।';
  }

  @override
  String get deletionDate => 'हटाने की तारीख';

  @override
  String get deletePermanentlyAction => 'हमेशा के लिए हटाएं';

  @override
  String get conflictFileAlreadyExists => 'फ़ाइल पहले से मौजूद है';

  @override
  String conflictNofM(int current, int total) {
    return 'विरोध $current / $total';
  }

  @override
  String get conflictAFileNamed => 'एक फ़ाइल जिसका नाम ';

  @override
  String get conflictAlreadyExistsAt => ' पहले से मौजूद है यहाँ: ';

  @override
  String get conflictAlreadyExistsInFolder =>
      ' इस फ़ोल्डर में पहले से मौजूद है।';

  @override
  String get conflictInFolder => 'फ़ोल्डर में';

  @override
  String get conflictFromTrash => 'ट्रैश से';

  @override
  String get conflictExisting => 'मौजूदा';

  @override
  String get conflictNewUpload => 'नया अपलोड';

  @override
  String conflictSizeLabel(String size) {
    return 'आकार: $size';
  }

  @override
  String conflictDateLabel(String date) {
    return 'तारीख: $date';
  }

  @override
  String conflictDeletedLabel(String date) {
    return 'हटाया गया: $date';
  }

  @override
  String conflictApplyToRemaining(int count) {
    return 'शेष विरोधों ($count) पर लागू करें';
  }

  @override
  String get conflictKeepAllCopies => 'सभी प्रतियां रखें';

  @override
  String get conflictOverwriteAll => 'सभी ओवरराइट करें';

  @override
  String get conflictRestoreAllAsCopies =>
      'सभी को प्रतियों के रूप में पुनर्स्थापित करें';

  @override
  String get conflictRestoreAsCopy => 'प्रति के रूप में पुनर्स्थापित करें';

  @override
  String get conflictOverwriteAllRemaining => 'शेष सभी को ओवरराइट करें';

  @override
  String get conflictSkipAll => 'सभी छोड़ें';

  @override
  String get conflictSkipAllRemaining => 'शेष सभी को छोड़ें';

  @override
  String get conflictSkip => 'छोड़ें';

  @override
  String get conflictOverwrite => 'ओवरराइट करें';

  @override
  String get transfersTitle => 'स्थानांतरण';

  @override
  String get transferResume => 'फिर से शुरू करें';

  @override
  String get transferPause => 'रोकें';

  @override
  String get transferCancel => 'रद्द करें';

  @override
  String get transferResumeAll => 'सभी फिर से शुरू करें';

  @override
  String get transferPauseAll => 'सभी रोकें';

  @override
  String get transferCancelAll => 'सभी रद्द करें';

  @override
  String get transferCancelFile => 'फ़ाइल रद्द करें';

  @override
  String get noTransfers => 'कोई स्थानांतरण नहीं।';

  @override
  String get transferStatusQueued => 'कतारबद्ध';

  @override
  String get transferStatusRunning => 'चल रहा है';

  @override
  String get transferStatusPaused => 'रोका गया';

  @override
  String get transferStatusCompleted => 'पूर्ण';

  @override
  String get transferStatusFailed => 'विफल';

  @override
  String get transferStatusCanceled => 'रद्द किया गया';

  @override
  String get themePresetsSection => 'प्रीसेट';

  @override
  String get themeCustomPaletteSection => 'कस्टम पैलेट';

  @override
  String get themeHexRgbLabel => 'HEX RGB कोड';

  @override
  String get themeHexRgbHint => '#FA5252';

  @override
  String get imageViewerNoFetchHandler => 'कोई फ़ेच हैंडलर कॉन्फ़िगर नहीं है';

  @override
  String get imageViewerFailedToLoad => 'छवि लोड करने में विफल';

  @override
  String errorDeletingFile(String filename, String error) {
    return '$filename को हटाने में त्रुटि: $error';
  }

  @override
  String errorReadingFile(String error) {
    return 'फ़ाइल पढ़ने में त्रुटि: $error';
  }

  @override
  String get syncChannelName => 'बैकग्राउंड सिंक्रनाइज़ेशन';

  @override
  String get syncChannelDescription =>
      'बैकग्राउंड में फ़ाइल सिंक की स्थिति दिखाता है।';

  @override
  String get storageStatsTitle => 'स्टोरेज सांख्यिकी';

  @override
  String get storageStatsUsedSpace => 'उपयोग की गई जगह';

  @override
  String get storageStatsTotalFiles => 'कुल फ़ाइलें';

  @override
  String storageStatsNItems(int count) {
    return '$count आइटम';
  }

  @override
  String userFallback(int userId) {
    return 'उपयोगकर्ता #$userId';
  }

  @override
  String get biometricUnlockReason =>
      'Crowley\'s Cloud के लिए सहेजे गए क्रेडेंशियल अनलॉक करें।';

  @override
  String get tokenLifetimeEveryOpen => 'हर बार ऐप खोलने पर';

  @override
  String get tokenLifetimeOneHour => '1 घंटे बाद';

  @override
  String get tokenLifetime1Hour => '1 घंटे बाद';

  @override
  String get tokenLifetimeOneDay => '1 दिन बाद';

  @override
  String get tokenLifetime1Day => '1 दिन बाद';

  @override
  String get tokenLifetimeOneWeek => '1 सप्ताह बाद';

  @override
  String get tokenLifetime1Week => '1 सप्ताह बाद';

  @override
  String get tokenLifetimeOneMonth => '1 महीने बाद';

  @override
  String get tokenLifetime1Month => '1 महीने बाद';

  @override
  String get tokenLifetimeThreeMonths => '3 महीने बाद';

  @override
  String get tokenLifetime3Months => '3 महीने बाद';

  @override
  String get tokenLifetimeNever => 'इस डिवाइस पर कभी नहीं';

  @override
  String get cacheLimitUnlimited => 'असीमित';

  @override
  String get syncCategoryOtherFiles => 'अन्य फ़ाइलें';

  @override
  String get internalStorage => 'आंतरिक स्टोरेज';

  @override
  String get localStorageRootName => 'आंतरिक स्टोरेज';

  @override
  String syncNotificationSyncingWith(String serverName) {
    return '$serverName के साथ सिंक हो रहा है';
  }

  @override
  String syncNotificationPausedTitle(String serverName) {
    return '$serverName के साथ सिंक रुका हुआ है';
  }

  @override
  String get syncNotificationUnreachableBody =>
      'सर्वर तक पहुँचने में असमर्थ। ऐप खोले जाने तक बैकग्राउंड सिंक रुका रहेगा।';

  @override
  String get syncNotificationAuthRequiredBody =>
      'प्रमाणीकरण आवश्यक है। लॉग इन करने के लिए ऐप खोलें।';

  @override
  String syncNotificationFailedTitle(String serverName) {
    return '$serverName के साथ सिंक विफल';
  }

  @override
  String get syncNotificationGenericErrorBody =>
      'सिंक्रनाइज़ेशन के दौरान एक त्रुटि हुई।';

  @override
  String syncNotificationCompleteTitle(String serverName) {
    return '$serverName के साथ सिंक पूर्ण';
  }

  @override
  String get syncNotificationCompleteBody => 'सिंक पूर्ण।';

  @override
  String get syncStatusConnecting => 'सर्वर से कनेक्ट हो रहा है...';

  @override
  String syncStatusConnectionLost(String serverName) {
    return '$serverName से कनेक्ट नहीं किया जा सका। कनेक्शन टूट गया।';
  }

  @override
  String syncResultServerUnreachableWithServer(String serverName) {
    return '$serverName से कनेक्ट नहीं किया जा सका। कनेक्शन टूट गया।';
  }

  @override
  String get syncStatusScanningFiles =>
      'डिवाइस पर फ़ाइलों को स्कैन किया जा रहा है...';

  @override
  String get syncStatusNoFilesFound => 'सिंक करने के लिए कोई फ़ाइल नहीं मिली।';

  @override
  String get syncStatusNoFilesSelected =>
      'सिंक्रनाइज़ेशन के लिए कोई फ़ाइल नहीं चुनी गई।';

  @override
  String syncStatusCalculatingChecksum(
    int current,
    int total,
    String filename,
  ) {
    return 'चेकसम की गणना की जा रही है ($current/$total): $filename';
  }

  @override
  String get syncStatusCheckingDuplicates =>
      'सर्वर पर डुप्लिकेट की जांच की जा रही है...';

  @override
  String syncStatusSyncingFile(int current, int total, String filename) {
    return 'सिंक हो रहा है ($current/$total): $filename';
  }

  @override
  String get syncStatusCompleting => 'सिंक्रनाइज़ेशन पूरा किया जा रहा है...';

  @override
  String get showingCachedFiles => 'कैश की गई फ़ाइलें दिखाई जा रही हैं।';

  @override
  String get showingCachedFilesRefreshFailed =>
      'कैश की गई फ़ाइलें दिखाई जा रही हैं। रिफ्रेश विफल रहा।';

  @override
  String get downloadCanceled => 'डाउनलोड रद्द किया गया।';

  @override
  String downloadedNFilesToPath(int count, String path) {
    return '$count फ़ाइलें $path पर डाउनलोड की गईं';
  }

  @override
  String downloadedNFilesFailedM(int downloaded, int failed, String detail) {
    return '$downloaded फ़ाइलें डाउनलोड की गईं, $failed विफल रहीं: $detail';
  }

  @override
  String downloadedNFilesWithFailures(int count, int failed, String error) {
    return '$count फ़ाइलें डाउनलोड की गईं, $failed विफल रहीं: $error';
  }

  @override
  String createdNShareLinks(int count) {
    return '$count साझा लिंक बनाए गए।';
  }

  @override
  String get failedToCreateShareLinks => 'साझा लिंक बनाने में विफल।';

  @override
  String get alreadyInSharedScope => 'पहले से साझा दायरे में है।';

  @override
  String sharedNItemsInServer(int count) {
    return 'सर्वर में $count आइटम साझा किए गए।';
  }

  @override
  String sharedNItemsWithFailures(int count, int failed) {
    return 'सर्वर में $count आइटम साझा किए गए, $failed विफल रहे।';
  }

  @override
  String sharedNItemsFailedM(int shared, int failed) {
    return 'सर्वर में $shared आइटम साझा किए गए, $failed विफल रहे।';
  }

  @override
  String get folderNameCannotBeEmpty => 'फ़ोल्डर का नाम खाली नहीं हो सकता।';

  @override
  String get folderAlreadyExists => 'फ़ोल्डर पहले से मौजूद है।';

  @override
  String get folderCreationOnlyInAllFiles =>
      'फ़ोल्डर बनाना केवल सभी फ़ाइलें में उपलब्ध है।';

  @override
  String get currentDirectoryUnavailable => 'वर्तमान निर्देशिका अनुपलब्ध है।';

  @override
  String get nothingSelected => 'कुछ भी नहीं चुना गया।';

  @override
  String get destinationFolderDoesNotExist => 'गंतव्य फ़ोल्डर मौजूद नहीं है।';

  @override
  String cannotMoveFolderIntoItself(String name) {
    return 'फ़ोल्डर \"$name\" को उसी के अंदर स्थानांतरित नहीं किया जा सकता।';
  }

  @override
  String failedToMoveItem(String name, String error) {
    return '\"$name\" को स्थानांतरित करने में विफल: $error';
  }

  @override
  String movedNItems(int count) {
    return '$count आइटम स्थानांतरित किए गए।';
  }

  @override
  String movedNItemsWithFailures(int count, int failed) {
    return '$count आइटम स्थानांतरित किए गए, $failed विफल रहे।';
  }

  @override
  String movedNItemsFailedM(int moved, int failed) {
    return '$moved आइटम स्थानांतरित किए गए, $failed विफल रहे।';
  }

  @override
  String get failedToMoveSelectedItems =>
      'चयनित आइटम को स्थानांतरित करने में विफल।';

  @override
  String get noFilesWereMoved => 'कोई फ़ाइल स्थानांतरित नहीं की गई।';

  @override
  String renamedOldToNew(String oldName, String newName) {
    return '\"$oldName\" का नाम बदलकर \"$newName\" कर दिया गया।';
  }

  @override
  String renamedFileFromTo(String oldName, String newName) {
    return '\"$oldName\" का नाम बदलकर \"$newName\" कर दिया गया।';
  }

  @override
  String failedToRenameWithStatus(String name, int statusCode) {
    return '\"$name\" का नाम बदलने में विफल ($statusCode)।';
  }

  @override
  String failedToRenameFileWithCode(String name, int statusCode) {
    return '\"$name\" का नाम बदलने में विफल ($statusCode)।';
  }

  @override
  String failedToRenameWithError(String name, String error) {
    return '\"$name\" का नाम बदलने में विफल: $error';
  }

  @override
  String failedToRenameFile(String name, String error) {
    return '\"$name\" का नाम बदलने में विफल: $error';
  }

  @override
  String get renameConflictAlreadyExists =>
      'नाम बदलने में विफल: उस नाम की फ़ाइल या फ़ोल्डर पहले से मौजूद है।';

  @override
  String get renameFailedAlreadyExists =>
      'नाम बदलने में विफल: उस नाम की फ़ाइल या फ़ोल्डर पहले से मौजूद है।';

  @override
  String failedToCreateFolderWithCode(int statusCode) {
    return 'फ़ोल्डर बनाने में विफल ($statusCode)।';
  }

  @override
  String deletedNItemsFailedM(int deleted, int failed) {
    return '$deleted आइटम हटाए गए, $failed विफल रहे।';
  }

  @override
  String transferSummaryFiles(int percent, int completed, int total) {
    return '$percent%  $completed/$total फ़ाइलें';
  }

  @override
  String transferSummaryProgress(int percent, int completed, int total) {
    return '$percent%  $completed/$total';
  }

  @override
  String get downloadFailedGeneric => 'डाउनलोड विफल';

  @override
  String uploadedNItemsWithFailures(int uploaded, int failed) {
    return '$uploaded आइटम अपलोड किए गए, $failed विफल रहे';
  }

  @override
  String uploadedNItemsFailedM(int uploaded, int failed) {
    return '$uploaded आइटम अपलोड किए गए, $failed विफल रहे।';
  }

  @override
  String uploadSummaryFailedCount(int count) {
    return ', $count विफल';
  }

  @override
  String uploadLocalPathEmpty(String name) {
    return '$name: स्थानीय पथ खाली है';
  }

  @override
  String uploadErrorLocalPathEmpty(String name) {
    return '$name: स्थानीय पथ खाली है';
  }

  @override
  String get directoryUploadFailed => 'निर्देशिका अपलोड विफल रहा';

  @override
  String get uploadDirectoryFailed => 'निर्देशिका अपलोड विफल रहा';

  @override
  String get localFileNotFound => 'स्थानीय फ़ाइल नहीं मिली';

  @override
  String get uploadErrorLocalFileNotFound => 'स्थानीय फ़ाइल नहीं मिली';

  @override
  String get noSessionToken => 'कोई सक्रिय सत्र टोकन नहीं है';

  @override
  String get uploadErrorNoSessionToken => 'कोई सक्रिय सत्र टोकन नहीं है';

  @override
  String get serverDisconnectedStatus => 'सर्वर डिस्कनेक्ट हो गया';

  @override
  String get serverDisconnected => 'सर्वर डिस्कनेक्ट हो गया';

  @override
  String get serverIsUnreachable => 'सर्वर तक पहुँचने में असमर्थ।';

  @override
  String get serverUnreachable => 'सर्वर तक पहुँचने में असमर्थ।';

  @override
  String get uploadErrorLocalDirectoryNotFound =>
      'स्थानीय निर्देशिका नहीं मिली';

  @override
  String get uploadErrorFailedToScanDirectory =>
      'निर्देशिका को स्कैन करने में विफल';

  @override
  String uploadErrorFolderCreateHttp(int statusCode) {
    return 'फ़ोल्डर बनाना विफल (HTTP $statusCode)';
  }

  @override
  String get authErrorMissingAccessToken =>
      'प्रतिक्रिया में एक्सेस टोकन गायब है';

  @override
  String get authErrorMissingRefreshToken =>
      'प्रतिक्रिया में रिफ्रेश टोकन गायब है';

  @override
  String get authErrorNoSavedCredentials =>
      'कोई सहेजे गए क्रेडेंशियल उपलब्ध नहीं हैं';

  @override
  String get authErrorNoRefreshToken => 'कोई रिफ्रेश टोकन उपलब्ध नहीं है';

  @override
  String get authErrorNoActiveSession => 'कोई सक्रिय सत्र उपलब्ध नहीं है';

  @override
  String get authErrorNoSavedUsername =>
      'कोई सहेजा गया उपयोगकर्ता नाम उपलब्ध नहीं है';

  @override
  String get updateNoReleasesPublished =>
      'अभी तक कोई रिलीज़ प्रकाशित नहीं हुई है।';

  @override
  String get language => 'भाषा';
}
