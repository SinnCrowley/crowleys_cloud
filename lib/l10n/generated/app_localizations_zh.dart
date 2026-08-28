// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Crowley\'s Cloud';

  @override
  String get ok => '確定';

  @override
  String get cancel => '取消';

  @override
  String get save => '儲存';

  @override
  String get delete => '刪除';

  @override
  String get rename => '重新命名';

  @override
  String get close => '關閉';

  @override
  String get retry => '重試';

  @override
  String get loading => '載入中...';

  @override
  String get confirm => '確認';

  @override
  String get error => '錯誤';

  @override
  String errorWithMessage(String message) {
    return '錯誤：$message';
  }

  @override
  String get unknown => '未知';

  @override
  String get upload => '上傳';

  @override
  String get download => '下載';

  @override
  String get share => '分享';

  @override
  String get copy => '複製';

  @override
  String get move => '移動';

  @override
  String get restore => '還原';

  @override
  String get apply => '套用';

  @override
  String get create => '建立';

  @override
  String get clear => '清除';

  @override
  String get add => '新增';

  @override
  String get remove => '移除';

  @override
  String get edit => '編輯';

  @override
  String get switchLabel => '切換';

  @override
  String get search => '搜尋';

  @override
  String get name => '名稱';

  @override
  String get date => '日期';

  @override
  String get size => '大小';

  @override
  String get type => '類型';

  @override
  String get ascending => '遞增';

  @override
  String get descending => '遞減';

  @override
  String get allFiles => '全部';

  @override
  String get categoryImages => '圖片';

  @override
  String get categoryPhotos => '相片';

  @override
  String get categoryVideos => '影片';

  @override
  String get categoryAudio => '音訊';

  @override
  String get categoryDocuments => '文件';

  @override
  String get categoryArchives => '壓縮檔';

  @override
  String get categoryShared => '已共用';

  @override
  String get categoryOther => '其他';

  @override
  String get categoryOtherFiles => '其他檔案';

  @override
  String get noFilesFound => '找不到檔案。';

  @override
  String get noFilesInFolder => '此資料夾中沒有檔案。';

  @override
  String get thisActionCannotBeUndone => '此操作無法復原。';

  @override
  String get passwordsDoNotMatch => '兩次輸入的密碼不一致。';

  @override
  String get navLocalFiles => '本機檔案';

  @override
  String get navServerFiles => '伺服器檔案';

  @override
  String get navSettings => '設定';

  @override
  String get navTrash => '垃圾桶';

  @override
  String get navLocal => '本機';

  @override
  String get navServer => '伺服器';

  @override
  String get addServer => '新增伺服器';

  @override
  String get noServersConfigured => '未設定伺服器。';

  @override
  String get addAServerInSettings => '請在「設定」中新增伺服器。';

  @override
  String get addFirstServerHint => '新增您的第一個伺服器以繼續。';

  @override
  String get noServersConfiguredYet => '尚未設定伺服器。';

  @override
  String get crowleysCloudSetup => 'Crowley\'s Cloud 設定';

  @override
  String get connect => '連線';

  @override
  String get connecting => '正在連線...';

  @override
  String get connected => '已連線';

  @override
  String get disconnected => '已中斷連線';

  @override
  String get switchServer => '切換伺服器';

  @override
  String get chooseOtherServer => '選擇其他伺服器';

  @override
  String get switchServerTitle => '切換伺服器？';

  @override
  String switchServerBody(String serverName) {
    return '將目前使用中的伺服器切換為「$serverName」？';
  }

  @override
  String get chooseServer => '選擇伺服器';

  @override
  String get authenticationRequired => '需要身分驗證';

  @override
  String signInToAccess(String serverName) {
    return '登入以存取 $serverName 上的檔案';
  }

  @override
  String get signInWithPassword => '使用密碼登入';

  @override
  String get useBiometrics => '使用生物辨識';

  @override
  String get openingSignIn => '正在開啟登入...';

  @override
  String get serverConnectionFailed => '伺服器連線失敗';

  @override
  String get unableToConnectToServer => '無法連線至目前使用中的伺服器。';

  @override
  String unableToConnectTo(String serverName) {
    return '無法連線至 $serverName。';
  }

  @override
  String get searchHint => '搜尋...';

  @override
  String get searchFilesHint => '搜尋檔案...';

  @override
  String get searchServerFilesHint => '搜尋伺服器檔案...';

  @override
  String get searchTrashHint => '搜尋垃圾桶...';

  @override
  String get storagePermissionRequired => '需要儲存空間權限';

  @override
  String get grantPermission => '授予權限';

  @override
  String get permissionDeniedOpenSettings => '權限已被拒絕。請在「設定」中授予儲存空間存取權限。';

  @override
  String get manageStoragePermissionRequired => '瀏覽與選取資料夾需要「所有檔案存取」管理權限。';

  @override
  String get storagePermissionsRequired => '執行同步需要儲存空間存取權限。';

  @override
  String updateAvailableTitle(String version) {
    return '可用更新：v$version';
  }

  @override
  String get updateAvailableTapToSeeNew => '輕點以查看更新內容';

  @override
  String get updateView => '檢視';

  @override
  String get updateAvailableDialogTitle => '發現新版本';

  @override
  String updateVersionSubtitle(String version) {
    return '版本 $version';
  }

  @override
  String updateCurrentVersion(String version) {
    return '目前版本：v$version';
  }

  @override
  String updateNewVersion(String version) {
    return '最新版本：v$version';
  }

  @override
  String get updateWhatsNew => '更新內容：';

  @override
  String get updateGitHub => 'GitHub';

  @override
  String get updateNoReleaseNotes => '未提供版本資訊。';

  @override
  String get updateLater => '稍後';

  @override
  String get updateDownloadApk => '下載 APK';

  @override
  String get updateInstall => '更新';

  @override
  String get shareLinkTitle => '共用連結';

  @override
  String get shareViaLink => '透過連結分享';

  @override
  String get shareInServer => '在伺服器中共用';

  @override
  String get expiryDays => '有效期限（天）';

  @override
  String get expiryNever => '永不過期';

  @override
  String get expiry1Day => '1 天';

  @override
  String get expiry7Days => '7 天';

  @override
  String get expiry30Days => '30 天';

  @override
  String get expiry90Days => '90 天';

  @override
  String get expiry180Days => '180 天';

  @override
  String get expiry365Days => '365 天';

  @override
  String get createLink => '建立連結';

  @override
  String get sharedLinkCopied => '共用連結已複製到剪貼簿！';

  @override
  String failedToCopySharedLink(String error) {
    return '複製共用連結失敗：$error';
  }

  @override
  String get cannotShareThisFileType => '無法分享此類檔案。';

  @override
  String failedToCreateShare(String error) {
    return '建立共用失敗：$error';
  }

  @override
  String get newFolderTitle => '建立資料夾';

  @override
  String get newFolderHint => '資料夾名稱';

  @override
  String get newFolder => '新資料夾';

  @override
  String get folderCreated => '資料夾已建立。';

  @override
  String failedToCreateFolder(String error) {
    return '建立資料夾失敗：$error';
  }

  @override
  String get creatingFolder => '正在建立資料夾...';

  @override
  String get renameDialogTitle => '重新命名';

  @override
  String get renameHint => '新名稱';

  @override
  String get enterNewName => '輸入新名稱';

  @override
  String get renamedSuccessfully => '重新命名成功。';

  @override
  String renameFailed(String error) {
    return '重新命名失敗：$error';
  }

  @override
  String get moveDialogTitle => '移動到';

  @override
  String moveTo(String path) {
    return '移動到：$path';
  }

  @override
  String get moveHere => '移至此處';

  @override
  String moveFailed(String error) {
    return '移動失敗：$error';
  }

  @override
  String get movedToFolder => '已移動到資料夾。';

  @override
  String copyFailed(String error) {
    return '複製失敗：$error';
  }

  @override
  String get selectFolder => '選取資料夾';

  @override
  String get useThisFolder => '使用此資料夾';

  @override
  String get storageRoot => '儲存空間';

  @override
  String get serverRoot => '根目錄';

  @override
  String deleteNItemsTitle(int count) {
    return '刪除 $count 個項目？';
  }

  @override
  String get deleteFilesTitle => '刪除檔案？';

  @override
  String deleteFilesBody(int count) {
    return '確定要刪除選取的 $count 個項目嗎？此操作無法復原。';
  }

  @override
  String get deletePermanently => '永久刪除';

  @override
  String get deletePermanentlyTitle => '永久刪除？';

  @override
  String deletePermanentlyBody(String filename) {
    return '「$filename」將被永久刪除。';
  }

  @override
  String get deleteFileTitle => '刪除檔案？';

  @override
  String deleteFileBody(String filename) {
    return '確定要刪除「$filename」嗎？此操作無法復原。';
  }

  @override
  String get deleteServerFileTitle => '永久刪除';

  @override
  String deleteServerFileBody(String filename) {
    return '確定要永久刪除「$filename」嗎？此操作無法復原。';
  }

  @override
  String get unshareItemsTitle => '取消共用項目？';

  @override
  String unshareItemsBody(int count) {
    return '確定要取消共用選取的 $count 個項目嗎？這將把它們從「已共用」資料夾中移除。';
  }

  @override
  String get unshare => '取消共用';

  @override
  String get moveToTrash => '移至垃圾桶';

  @override
  String get movedToTrash => '已移至垃圾桶。';

  @override
  String movedNItemsToTrash(int count) {
    return '已將 $count 個項目移至垃圾桶。';
  }

  @override
  String failedToMoveToTrash(String error) {
    return '移至垃圾桶失敗：$error';
  }

  @override
  String deletedNItems(int count) {
    return '已刪除 $count 個項目。';
  }

  @override
  String failedToDelete(String error) {
    return '刪除失敗：$error';
  }

  @override
  String failedToDeleteItem(String error) {
    return '刪除失敗：$error';
  }

  @override
  String deletedFilename(String filename) {
    return '已刪除「$filename」。';
  }

  @override
  String get failedToOpenFile => '無法開啟檔案';

  @override
  String fileDownloadFailed(String error) {
    return '下載失敗：$error';
  }

  @override
  String get downloading => '正在下載...';

  @override
  String get downloadingFile => '正在下載檔案...';

  @override
  String downloadComplete(String filename) {
    return '下載完成：$filename';
  }

  @override
  String downloadFailed(String error) {
    return '下載失敗：$error';
  }

  @override
  String get failedToDownloadPreview => '無法下載預覽';

  @override
  String uploadComplete(String filename) {
    return '上傳完成：$filename';
  }

  @override
  String uploadFailed(String error) {
    return '上傳失敗：$error';
  }

  @override
  String get failedToPickFiles => '無法選取檔案';

  @override
  String uploadedNItems(int count) {
    return '已上傳 $count 個檔案';
  }

  @override
  String get copiedLinkToClipboard => '連結已複製到剪貼簿。';

  @override
  String failedToCopyLink(String error) {
    return '複製連結失敗：$error';
  }

  @override
  String get selectingAll => '正在全選...';

  @override
  String get allItemsSelected => '已選取所有項目。';

  @override
  String get failedToLoadSearchResults => '載入搜尋結果失敗';

  @override
  String get shareNotSupportedForType => '此類檔案不支援共用。';

  @override
  String nSelected(int count) {
    return '已選取 $count 項';
  }

  @override
  String get noServerSelected => '未選擇伺服器';

  @override
  String get pleaseConnectToServerFirst => '請先連線至伺服器。';

  @override
  String get signInRequired => '需要登入';

  @override
  String pleaseSignInToServer(String serverName) {
    return '請先登入至 $serverName。';
  }

  @override
  String get connectingToServer => '正在連線至伺服器...';

  @override
  String connectedToServer(String serverName) {
    return '已連線至 $serverName。';
  }

  @override
  String connectionFailed(String error) {
    return '連線失敗：$error';
  }

  @override
  String failedToConnect(String error) {
    return '無法連線：$error';
  }

  @override
  String authFailed(String error) {
    return '身分驗證失敗：$error';
  }

  @override
  String get authFailedGeneric => '身分驗證失敗。請重試。';

  @override
  String biometricLoginFailed(String error) {
    return '生物辨識登入失敗：$error';
  }

  @override
  String get biometricLoginFailedGeneric => '生物辨識登入失敗。';

  @override
  String get noServerSessionToken => '無伺服器工作階段權杖。請重新驗證伺服器。';

  @override
  String failedToSaveServer(String error) {
    return '儲存伺服器失敗：$error';
  }

  @override
  String get addToFolder => '新增至資料夾';

  @override
  String get loginTabLabel => '登入';

  @override
  String get registerTabLabel => '註冊';

  @override
  String get welcomeBack => '歡迎回來';

  @override
  String get signInToContinue => '登入以繼續';

  @override
  String get createAccount => '建立帳號';

  @override
  String get joinTheServer => '加入伺服器';

  @override
  String get usernameLabel => '使用者名稱';

  @override
  String get usernameHint => '輸入您的使用者名稱';

  @override
  String get passwordLabel => '密碼';

  @override
  String get passwordHint => '輸入您的密碼';

  @override
  String get showPassword => '顯示密碼';

  @override
  String get hidePassword => '隱藏密碼';

  @override
  String get confirmPassword => '確認密碼';

  @override
  String get logIn => '登入';

  @override
  String get loggingIn => '正在登入...';

  @override
  String get registering => '正在註冊...';

  @override
  String get forgotPassword => '忘記密碼？';

  @override
  String get doNotHaveAccount => '還沒有帳號？切換至註冊。';

  @override
  String get alreadyHaveAccount => '已有帳號？切換至登入。';

  @override
  String get usernameCannotBeEmpty => '使用者名稱不能為空。';

  @override
  String get passwordCannotBeEmpty => '密碼不能為空。';

  @override
  String get usernameInvalid => '使用者名稱必須為 3–32 個字元，包含英文字母、數字、_ 或 -。';

  @override
  String get passwordTooShort => '密碼長度至少需 8 個字元。';

  @override
  String loginFailed(String error) {
    return '登入失敗：$error';
  }

  @override
  String registrationFailed(String error) {
    return '註冊失敗：$error';
  }

  @override
  String get resetPasswordTitle => '重設密碼';

  @override
  String get enterResetCodeTitle => '輸入重設碼';

  @override
  String get resetPasswordStep1Body => '輸入您的使用者名稱。6 位數確認碼將輸出到伺服器日誌/主控台。';

  @override
  String get resetPasswordStep2Body => '確認碼已發送到伺服器主控台。請輸入 6 位數代碼與您的新密碼。';

  @override
  String get resetCodeLabel => '重設驗證碼';

  @override
  String get resetCodeHint => '輸入 6 位數驗證碼';

  @override
  String get newPasswordLabel => '新密碼';

  @override
  String get newPasswordHint => '輸入新密碼';

  @override
  String get passwordResetSuccessfully => '密碼重設成功！';

  @override
  String get usernameIsRequired => '使用者名稱為必填項目。';

  @override
  String get codeAndPasswordRequired => '驗證碼與新密碼均為必填項目。';

  @override
  String get failedToRequestReset => '請求重設失敗。請檢查伺服器 URL。';

  @override
  String get failedToResetPassword => '重設密碼失敗。請檢查驗證碼。';

  @override
  String get pleaseEnterServerUrlFirst => '請先輸入伺服器 URL。';

  @override
  String get sendCode => '傳送驗證碼';

  @override
  String get settingsTitle => '設定';

  @override
  String get sectionBackupSync => '備份與同步';

  @override
  String get sectionStorageCache => '儲存與快取';

  @override
  String get sectionSecurityBehavior => '安全性與行為';

  @override
  String get sectionAboutUpdates => '關於與更新';

  @override
  String get sectionAppearance => '外觀與自訂';

  @override
  String get noServersConfiguredSync => '未設定伺服器';

  @override
  String get addServerBeforeSync => '請在設定同步前新增伺服器。';

  @override
  String get selectServerToConfigureSync => '選取要設定同步的伺服器。';

  @override
  String get activeServerSuffix => ' · 使用中';

  @override
  String get folderAndCategorySync => '資料夾與分類同步';

  @override
  String get keepCategoriesSynced => '使選取的本機分類或資料夾與此伺服器保持同步。';

  @override
  String get addServerBeforeSyncEnable => '請在啟用同步前新增伺服器。';

  @override
  String get onlyOnWifi => '僅限 Wi-Fi';

  @override
  String get onlyWhileCharging => '僅在充電時';

  @override
  String get serverTargetDirectory => '伺服器目標目錄';

  @override
  String get serverTargetDirectoryHint => '/backup/mobile_phone';

  @override
  String get synchronizationFrequency => '同步頻率';

  @override
  String get syncNow => '立即同步';

  @override
  String get syncing => '正在同步...';

  @override
  String get categoriesToSynchronize => '要同步的分類';

  @override
  String get noCategoriesSelected => '未選取分類。';

  @override
  String nCategoriesSelected(int count) {
    return '已選取 $count 個分類';
  }

  @override
  String get foldersToSynchronize => '要同步的資料夾';

  @override
  String get noCustomFolders => '未設定自訂資料夾。';

  @override
  String nFolders(int count) {
    return '$count 個資料夾';
  }

  @override
  String get addFolder => '新增資料夾';

  @override
  String get removeFolder => '移除資料夾';

  @override
  String get removeServer => '刪除伺服器';

  @override
  String get syncFreqEvery15Min => '每 15 分鐘';

  @override
  String get syncFreqEvery30Min => '每 30 分鐘';

  @override
  String get syncFreqEvery1Hour => '每小時';

  @override
  String syncFreqEveryNHours(int hours) {
    return '每 $hours 小時';
  }

  @override
  String syncFreqEveryNMin(int minutes) {
    return '每 $minutes 分鐘';
  }

  @override
  String get syncFreqDaily => '每天';

  @override
  String get chooseSyncFrequencyTitle => '選擇同步頻率';

  @override
  String get cacheSize => '快取大小';

  @override
  String get refreshTooltip => '重新整理';

  @override
  String get cacheLimit => '快取上限';

  @override
  String get downloadPath => '下載路徑';

  @override
  String get defaultDownloadFolder => '預設 CrowleysCloud 資料夾';

  @override
  String get clearCache => '清除快取';

  @override
  String get clearCacheTitle => '清除快取？';

  @override
  String get clearCacheBody => '這將移除本機縮圖與已快取的伺服器清單。';

  @override
  String get downloadPathDialogTitle => '下載路徑';

  @override
  String get downloadPathHint => '/storage/emulated/0/CrowleysCloud';

  @override
  String get useDefault => '使用預設值';

  @override
  String get serverTargetDirDialogTitle => '伺服器目標目錄';

  @override
  String get requireLogin => '需要登入';

  @override
  String get biometricLogin => '生物辨識登入';

  @override
  String get biometricLoginSubtitle => '允許使用生物辨識與已儲存的憑證登入。';

  @override
  String get biometricsNotAvailable => '此裝置上無法使用生物辨識。';

  @override
  String get showHiddenFiles => '顯示隱藏檔案';

  @override
  String get showHiddenFilesSubtitle => '顯示以「.」開頭的隱藏檔案與資料夾。';

  @override
  String get changePassword => '變更密碼';

  @override
  String changePasswordSubtitle(String serverName) {
    return '變更 $serverName 上的密碼。';
  }

  @override
  String get addServerBeforeChangePassword => '變更密碼前請先新增伺服器。';

  @override
  String get deleteUserAccount => '刪除使用者帳號';

  @override
  String get deleteUserAccountSubtitle => '刪除此使用者及其所有私有雲端檔案。';

  @override
  String get deleteAccountTitle => '刪除帳號？';

  @override
  String deleteAccountBody(String serverName) {
    return '這將永久刪除您在 $serverName 上的帳號，並移除儲存在您私有雲端資料夾中的所有檔案。此操作無法復原。';
  }

  @override
  String get deleteAccountButton => '刪除帳號';

  @override
  String get changePasswordDialogTitle => '變更密碼';

  @override
  String get newPasswordFieldLabel => '新密碼';

  @override
  String get confirmPasswordLabel => '確認密碼';

  @override
  String get enterNewPassword => '輸入新密碼。';

  @override
  String get passwordUpdated => '密碼已更新。';

  @override
  String passwordChangeFailed(String error) {
    return '變更密碼失敗：$error';
  }

  @override
  String get passwordChangeFailedGeneric => '變更密碼失敗。';

  @override
  String get accountDeleted => '帳號已刪除。';

  @override
  String accountDeletionFailed(String error) {
    return '刪除帳號失敗：$error';
  }

  @override
  String get accountDeletionFailedGeneric => '刪除帳號失敗。';

  @override
  String get checkForUpdates => '檢查更新';

  @override
  String get checkingForUpdates => '正在檢查 GitHub Releases...';

  @override
  String versionLabel(String version) {
    return '版本 $version';
  }

  @override
  String appIsUpToDate(String version) {
    return 'Crowley\'s Cloud 已是最新版本 (v$version)。';
  }

  @override
  String get updateCheckFailed => '檢查更新失敗。請稍後重試。';

  @override
  String get themeModeTitle => '主題模式';

  @override
  String get themeDark => '深色';

  @override
  String get themeLight => '淺色';

  @override
  String get themeCustom => '自訂';

  @override
  String get themeDarkFull => '深色主題';

  @override
  String get themeLightFull => '淺色主題';

  @override
  String get themeCustomFull => '自訂主題';

  @override
  String get accentColor => '強調顏色';

  @override
  String get primaryAccentColor => '主要強調顏色';

  @override
  String get selectAccentColor => '選取強調顏色';

  @override
  String get backgroundColor => '背景顏色';

  @override
  String get surfaceColor => '表面顏色';

  @override
  String get textColor => '文字顏色';

  @override
  String get subtextColor => '次要文字顏色';

  @override
  String get borderColor => '邊框顏色';

  @override
  String get fontSizeScale => '字型縮放比例';

  @override
  String selectColor(String title) {
    return '選取 $title';
  }

  @override
  String get categoriesToSyncDialogTitle => '要同步的分類';

  @override
  String get categoriesToSyncBody => '選取一個或多個分類。您可以全部不選。';

  @override
  String get syncCategorySectionMedia => '媒體';

  @override
  String get syncCategorySectionAudioDocs => '音訊與文件';

  @override
  String get syncCategorySectionOther => '其他';

  @override
  String get clearAll => '全部清除';

  @override
  String get noSyncHasRunYet => '尚未執行過同步。';

  @override
  String lastRunAt(String date) {
    return '上次執行於 $date';
  }

  @override
  String syncResultSuccess(int uploaded, int skipped) {
    return '已同步 $uploaded 項，略過 $skipped 項。';
  }

  @override
  String get syncResultNoFiles => '未選取要同步的檔案。';

  @override
  String syncResultPartial(int uploaded, int failed) {
    return '已同步 $uploaded 項，失敗 $failed 項。';
  }

  @override
  String get syncResultAuthRequired => '同步前請先登入。';

  @override
  String get syncResultUnreachable => '伺服器無法連線。連線已中斷。';

  @override
  String get syncResultFailed => '同步失敗。';

  @override
  String get serverSetupAddServer => '新增伺服器';

  @override
  String get serverSetupCardTitle => '連線至伺服器';

  @override
  String get serverSetupCardSubtitle => '新增您的家用檔案伺服器並登入。';

  @override
  String get serverSetupSubmitButton => '儲存伺服器';

  @override
  String get serverNameLabel => '伺服器名稱';

  @override
  String get serverNameHint => '家用 NAS';

  @override
  String get baseUrlLabel => '基本 URL';

  @override
  String get baseUrlHint => 'https://cloud.example.com';

  @override
  String get allFieldsRequired => '所有欄位均為必填項目。';

  @override
  String get localFilesTitle => '本機檔案';

  @override
  String get serverFilesTitle => '伺服器檔案';

  @override
  String get restoreItemsTitle => '還原項目';

  @override
  String restoreItemsBody(int count) {
    return '確定要還原 $count 個項目嗎？';
  }

  @override
  String get permanentlyDeleteTitle => '永久刪除';

  @override
  String permanentlyDeleteBody(int count) {
    return '確定要永久刪除 $count 個項目嗎？此操作無法復原。';
  }

  @override
  String get trashIsEmpty => '垃圾桶為空。';

  @override
  String trashRetentionInfo(int days) {
    return '垃圾桶中的項目會在 $days 天後自動刪除。';
  }

  @override
  String get deletionDate => '刪除日期';

  @override
  String get deletePermanentlyAction => '永久刪除';

  @override
  String get conflictFileAlreadyExists => '檔案已存在';

  @override
  String conflictNofM(int current, int total) {
    return '衝突 $current / $total';
  }

  @override
  String get conflictAFileNamed => '名為「';

  @override
  String get conflictAlreadyExistsAt => '」的檔案已存在於 ';

  @override
  String get conflictAlreadyExistsInFolder => '」的檔案已存在於此資料夾中。';

  @override
  String get conflictInFolder => '在資料夾中';

  @override
  String get conflictFromTrash => '來自垃圾桶';

  @override
  String get conflictExisting => '現有檔案';

  @override
  String get conflictNewUpload => '新上傳';

  @override
  String conflictSizeLabel(String size) {
    return '大小：$size';
  }

  @override
  String conflictDateLabel(String date) {
    return '日期：$date';
  }

  @override
  String conflictDeletedLabel(String date) {
    return '刪除時間：$date';
  }

  @override
  String conflictApplyToRemaining(int count) {
    return '套用至剩餘 $count 個衝突';
  }

  @override
  String get conflictKeepAllCopies => '保留所有複本';

  @override
  String get conflictOverwriteAll => '全部覆蓋';

  @override
  String get conflictRestoreAllAsCopies => '全部還原為複本';

  @override
  String get conflictRestoreAsCopy => '還原為複本';

  @override
  String get conflictOverwriteAllRemaining => '覆蓋所有剩餘檔案';

  @override
  String get conflictSkipAll => '全部略過';

  @override
  String get conflictSkipAllRemaining => '略過所有剩餘檔案';

  @override
  String get conflictSkip => '略過';

  @override
  String get conflictOverwrite => '覆蓋';

  @override
  String get transfersTitle => '傳輸';

  @override
  String get transferResume => '繼續';

  @override
  String get transferPause => '暫停';

  @override
  String get transferCancel => '取消';

  @override
  String get transferResumeAll => '全部繼續';

  @override
  String get transferPauseAll => '全部暫停';

  @override
  String get transferCancelAll => '全部取消';

  @override
  String get transferCancelFile => '取消檔案';

  @override
  String get noTransfers => '沒有進行中的傳輸。';

  @override
  String get transferStatusQueued => '佇列中';

  @override
  String get transferStatusRunning => '進行中';

  @override
  String get transferStatusPaused => '已暫停';

  @override
  String get transferStatusCompleted => '已完成';

  @override
  String get transferStatusFailed => '失敗';

  @override
  String get transferStatusCanceled => '已取消';

  @override
  String get themePresetsSection => '預設主題';

  @override
  String get themeCustomPaletteSection => '自訂調色盤';

  @override
  String get themeHexRgbLabel => 'HEX RGB 代碼';

  @override
  String get themeHexRgbHint => '#FA5252';

  @override
  String get imageViewerNoFetchHandler => '未設定影像擷取處理常式';

  @override
  String get imageViewerFailedToLoad => '無法載入影像';

  @override
  String errorDeletingFile(String filename, String error) {
    return '刪除「$filename」失敗：$error';
  }

  @override
  String errorReadingFile(String error) {
    return '讀取檔案失敗：$error';
  }

  @override
  String get syncChannelName => '背景同步';

  @override
  String get syncChannelDescription => '顯示背景檔案同步的狀態。';

  @override
  String get storageStatsTitle => '儲存空間統計';

  @override
  String get storageStatsUsedSpace => '已用空間';

  @override
  String get storageStatsTotalFiles => '檔案總數';

  @override
  String storageStatsNItems(int count) {
    return '$count 個項目';
  }

  @override
  String userFallback(int userId) {
    return '使用者 #$userId';
  }

  @override
  String get biometricUnlockReason => '請驗證身分以解鎖 Crowley\'s Cloud 儲存的憑證。';

  @override
  String get tokenLifetimeEveryOpen => '每次開啟應用程式';

  @override
  String get tokenLifetimeOneHour => '1 小時後';

  @override
  String get tokenLifetime1Hour => '1 小時後';

  @override
  String get tokenLifetimeOneDay => '1 天後';

  @override
  String get tokenLifetime1Day => '1 天後';

  @override
  String get tokenLifetimeOneWeek => '1 週後';

  @override
  String get tokenLifetime1Week => '1 週後';

  @override
  String get tokenLifetimeOneMonth => '1 個月後';

  @override
  String get tokenLifetime1Month => '1 個月後';

  @override
  String get tokenLifetimeThreeMonths => '3 個月後';

  @override
  String get tokenLifetime3Months => '3 個月後';

  @override
  String get tokenLifetimeNever => '在此裝置上永不過期';

  @override
  String get cacheLimitUnlimited => '無限制';

  @override
  String get syncCategoryOtherFiles => '其他檔案';

  @override
  String get internalStorage => '內部儲存空間';

  @override
  String get localStorageRootName => '內部儲存空間';

  @override
  String syncNotificationSyncingWith(String serverName) {
    return '正在與 $serverName 同步';
  }

  @override
  String syncNotificationPausedTitle(String serverName) {
    return '與 $serverName 的同步已暫停';
  }

  @override
  String get syncNotificationUnreachableBody => '伺服器無法連線。背景同步已暫停，直到開啟應用程式。';

  @override
  String get syncNotificationAuthRequiredBody => '需要身分驗證。請開啟應用程式以登入。';

  @override
  String syncNotificationFailedTitle(String serverName) {
    return '與 $serverName 的同步失敗';
  }

  @override
  String get syncNotificationGenericErrorBody => '同步過程中發生錯誤。';

  @override
  String syncNotificationCompleteTitle(String serverName) {
    return '與 $serverName 的同步已完成';
  }

  @override
  String get syncNotificationCompleteBody => '同步完成。';

  @override
  String get syncStatusConnecting => '正在連線至伺服器...';

  @override
  String syncStatusConnectionLost(String serverName) {
    return '無法連線至 $serverName。連線已中斷。';
  }

  @override
  String syncResultServerUnreachableWithServer(String serverName) {
    return '無法連線至 $serverName。連線已中斷。';
  }

  @override
  String get syncStatusScanningFiles => '正在掃描裝置上的檔案...';

  @override
  String get syncStatusNoFilesFound => '未找到要同步的檔案。';

  @override
  String get syncStatusNoFilesSelected => '未選取要同步的檔案。';

  @override
  String syncStatusCalculatingChecksum(
    int current,
    int total,
    String filename,
  ) {
    return '正在計算校驗和 ($current/$total)：$filename';
  }

  @override
  String get syncStatusCheckingDuplicates => '正在檢查伺服器上的重複檔案...';

  @override
  String syncStatusSyncingFile(int current, int total, String filename) {
    return '正在同步 ($current/$total)：$filename';
  }

  @override
  String get syncStatusCompleting => '正在完成同步...';

  @override
  String get showingCachedFiles => '正在顯示快取的檔案。';

  @override
  String get showingCachedFilesRefreshFailed => '正在顯示快取的檔案。重新整理失敗。';

  @override
  String get downloadCanceled => '下載已取消。';

  @override
  String downloadedNFilesToPath(int count, String path) {
    return '已將 $count 個檔案下載到 $path';
  }

  @override
  String downloadedNFilesFailedM(int downloaded, int failed, String detail) {
    return '已下載 $downloaded 個檔案，失敗 $failed 個：$detail';
  }

  @override
  String downloadedNFilesWithFailures(int count, int failed, String error) {
    return '已下載 $count 個檔案，失敗 $failed 個：$error';
  }

  @override
  String createdNShareLinks(int count) {
    return '已建立 $count 個共用連結。';
  }

  @override
  String get failedToCreateShareLinks => '無法建立共用連結。';

  @override
  String get alreadyInSharedScope => '已在共用範圍內。';

  @override
  String sharedNItemsInServer(int count) {
    return '已在伺服器中共用 $count 個項目。';
  }

  @override
  String sharedNItemsWithFailures(int count, int failed) {
    return '已共用 $count 個項目，失敗 $failed 個。';
  }

  @override
  String sharedNItemsFailedM(int shared, int failed) {
    return '已共用 $shared 個項目，失敗 $failed 個。';
  }

  @override
  String get folderNameCannotBeEmpty => '資料夾名稱不能為空。';

  @override
  String get folderAlreadyExists => '同名資料夾已存在。';

  @override
  String get folderCreationOnlyInAllFiles => '只能在「所有檔案」中建立資料夾。';

  @override
  String get currentDirectoryUnavailable => '目前目錄不可用。';

  @override
  String get nothingSelected => '未選取任何項目。';

  @override
  String get destinationFolderDoesNotExist => '目標資料夾不存在。';

  @override
  String cannotMoveFolderIntoItself(String name) {
    return '無法將資料夾「$name」移動到其自身內部。';
  }

  @override
  String failedToMoveItem(String name, String error) {
    return '移動「$name」失敗：$error';
  }

  @override
  String movedNItems(int count) {
    return '已移動 $count 個項目。';
  }

  @override
  String movedNItemsWithFailures(int count, int failed) {
    return '已移動 $count 個項目，失敗 $failed 個。';
  }

  @override
  String movedNItemsFailedM(int moved, int failed) {
    return '已移動 $moved 個項目，失敗 $failed 個。';
  }

  @override
  String get failedToMoveSelectedItems => '移動所選項目失敗。';

  @override
  String get noFilesWereMoved => '未移動任何檔案。';

  @override
  String renamedOldToNew(String oldName, String newName) {
    return '已將「$oldName」重新命名為「$newName」。';
  }

  @override
  String renamedFileFromTo(String oldName, String newName) {
    return '已將「$oldName」重新命名為「$newName」。';
  }

  @override
  String failedToRenameWithStatus(String name, int statusCode) {
    return '重新命名「$name」失敗 ($statusCode)。';
  }

  @override
  String failedToRenameFileWithCode(String name, int statusCode) {
    return '重新命名「$name」失敗 ($statusCode)。';
  }

  @override
  String failedToRenameWithError(String name, String error) {
    return '重新命名「$name」失敗：$error';
  }

  @override
  String failedToRenameFile(String name, String error) {
    return '重新命名「$name」失敗：$error';
  }

  @override
  String get renameConflictAlreadyExists => '重新命名失敗：同名檔案或資料夾已存在。';

  @override
  String get renameFailedAlreadyExists => '重新命名失敗：同名檔案或資料夾已存在。';

  @override
  String failedToCreateFolderWithCode(int statusCode) {
    return '建立資料夾失敗 (代碼 $statusCode)。';
  }

  @override
  String deletedNItemsFailedM(int deleted, int failed) {
    return '已刪除 $deleted 個項目，失敗 $failed 個。';
  }

  @override
  String transferSummaryFiles(int percent, int completed, int total) {
    return '$percent%  $completed/$total 個檔案';
  }

  @override
  String transferSummaryProgress(int percent, int completed, int total) {
    return '$percent%  $completed/$total 個檔案';
  }

  @override
  String get downloadFailedGeneric => '下載失敗';

  @override
  String uploadedNItemsWithFailures(int uploaded, int failed) {
    return '已上傳 $uploaded 個項目，失敗 $failed 個';
  }

  @override
  String uploadedNItemsFailedM(int uploaded, int failed) {
    return '已上傳 $uploaded 個項目，失敗 $failed 個。';
  }

  @override
  String uploadSummaryFailedCount(int count) {
    return '，失敗 $count 個';
  }

  @override
  String uploadLocalPathEmpty(String name) {
    return '$name：本機路徑為空';
  }

  @override
  String uploadErrorLocalPathEmpty(String name) {
    return '$name：本機路徑為空';
  }

  @override
  String get directoryUploadFailed => '資料夾上傳失敗';

  @override
  String get uploadDirectoryFailed => '資料夾上傳失敗';

  @override
  String get localFileNotFound => '找不到本機檔案';

  @override
  String get uploadErrorLocalFileNotFound => '找不到本機檔案';

  @override
  String get noSessionToken => '沒有作用中的工作階段權杖';

  @override
  String get uploadErrorNoSessionToken => '沒有作用中的工作階段權杖';

  @override
  String get serverDisconnectedStatus => '伺服器已中斷連線';

  @override
  String get serverDisconnected => '伺服器已中斷連線';

  @override
  String get serverIsUnreachable => '伺服器無法連線。';

  @override
  String get serverUnreachable => '伺服器無法連線。';

  @override
  String get uploadErrorLocalDirectoryNotFound => '找不到本機資料夾';

  @override
  String get uploadErrorFailedToScanDirectory => '掃描資料夾失敗';

  @override
  String uploadErrorFolderCreateHttp(int statusCode) {
    return '建立資料夾失敗 (HTTP $statusCode)';
  }

  @override
  String get authErrorMissingAccessToken => '回應中缺少存取權杖';

  @override
  String get authErrorMissingRefreshToken => '回應中缺少更新權杖';

  @override
  String get authErrorNoSavedCredentials => '沒有可用的已儲存憑證';

  @override
  String get authErrorNoRefreshToken => '沒有可用的更新權杖';

  @override
  String get authErrorNoActiveSession => '沒有可用的作用中工作階段';

  @override
  String get authErrorNoSavedUsername => '沒有可用的已儲存使用者名稱';

  @override
  String get updateNoReleasesPublished => '尚未發佈任何版本。';

  @override
  String get language => '語言';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get appTitle => 'Crowley\'s Cloud';

  @override
  String get ok => '确定';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get rename => '重命名';

  @override
  String get close => '关闭';

  @override
  String get retry => '重试';

  @override
  String get loading => '加载中...';

  @override
  String get confirm => '确认';

  @override
  String get error => '错误';

  @override
  String errorWithMessage(String message) {
    return '错误：$message';
  }

  @override
  String get unknown => '未知';

  @override
  String get upload => '上传';

  @override
  String get download => '下载';

  @override
  String get share => '分享';

  @override
  String get copy => '复制';

  @override
  String get move => '移动';

  @override
  String get restore => '还原';

  @override
  String get apply => '应用';

  @override
  String get create => '创建';

  @override
  String get clear => '清除';

  @override
  String get add => '添加';

  @override
  String get remove => '移除';

  @override
  String get edit => '编辑';

  @override
  String get switchLabel => '切换';

  @override
  String get search => '搜索';

  @override
  String get name => '名称';

  @override
  String get date => '日期';

  @override
  String get size => '大小';

  @override
  String get type => '类型';

  @override
  String get ascending => '升序';

  @override
  String get descending => '降序';

  @override
  String get allFiles => '全部';

  @override
  String get categoryImages => '图片';

  @override
  String get categoryPhotos => '照片';

  @override
  String get categoryVideos => '视频';

  @override
  String get categoryAudio => '音频';

  @override
  String get categoryDocuments => '文档';

  @override
  String get categoryArchives => '压缩包';

  @override
  String get categoryShared => '已共享';

  @override
  String get categoryOther => '其他';

  @override
  String get categoryOtherFiles => '其他文件';

  @override
  String get noFilesFound => '未找到文件。';

  @override
  String get noFilesInFolder => '此文件夹中没有文件。';

  @override
  String get thisActionCannotBeUndone => '此操作无法撤销。';

  @override
  String get passwordsDoNotMatch => '两次输入的密码不一致。';

  @override
  String get navLocalFiles => '本地文件';

  @override
  String get navServerFiles => '服务器文件';

  @override
  String get navSettings => '设置';

  @override
  String get navTrash => '回收站';

  @override
  String get navLocal => '本地';

  @override
  String get navServer => '服务器';

  @override
  String get addServer => '添加服务器';

  @override
  String get noServersConfigured => '未配置服务器。';

  @override
  String get addAServerInSettings => '请在设置中添加服务器。';

  @override
  String get addFirstServerHint => '添加您的第一个服务器以继续。';

  @override
  String get noServersConfiguredYet => '尚未配置服务器。';

  @override
  String get crowleysCloudSetup => 'Crowley\'s Cloud 设置';

  @override
  String get connect => '连接';

  @override
  String get connecting => '正在连接...';

  @override
  String get connected => '已连接';

  @override
  String get disconnected => '已断开连接';

  @override
  String get switchServer => '切换服务器';

  @override
  String get chooseOtherServer => '选择其他服务器';

  @override
  String get switchServerTitle => '切换服务器？';

  @override
  String switchServerBody(String serverName) {
    return '将活动服务器切换为 \"$serverName\"？';
  }

  @override
  String get chooseServer => '选择服务器';

  @override
  String get authenticationRequired => '需要身份验证';

  @override
  String signInToAccess(String serverName) {
    return '登录以访问 $serverName 上的文件';
  }

  @override
  String get signInWithPassword => '使用密码登录';

  @override
  String get useBiometrics => '使用生物识别';

  @override
  String get openingSignIn => '正在打开登录...';

  @override
  String get serverConnectionFailed => '服务器连接失败';

  @override
  String get unableToConnectToServer => '无法连接到活动服务器。';

  @override
  String unableToConnectTo(String serverName) {
    return '无法连接到 $serverName。';
  }

  @override
  String get searchHint => '搜索...';

  @override
  String get searchFilesHint => '搜索文件...';

  @override
  String get searchServerFilesHint => '搜索服务器文件...';

  @override
  String get searchTrashHint => '搜索回收站...';

  @override
  String get storagePermissionRequired => '需要存储权限';

  @override
  String get grantPermission => '授予权限';

  @override
  String get permissionDeniedOpenSettings => '权限已被拒绝。请在设置中授予存储访问权限。';

  @override
  String get manageStoragePermissionRequired => '浏览和选择文件夹需要“所有文件访问”管理权限。';

  @override
  String get storagePermissionsRequired => '执行同步需要存储访问权限。';

  @override
  String updateAvailableTitle(String version) {
    return '可用更新：v$version';
  }

  @override
  String get updateAvailableTapToSeeNew => '点击查看更新内容';

  @override
  String get updateView => '查看';

  @override
  String get updateAvailableDialogTitle => '发现新版本';

  @override
  String updateVersionSubtitle(String version) {
    return '版本 $version';
  }

  @override
  String updateCurrentVersion(String version) {
    return '当前：v$version';
  }

  @override
  String updateNewVersion(String version) {
    return '最新：v$version';
  }

  @override
  String get updateWhatsNew => '更新内容：';

  @override
  String get updateGitHub => 'GitHub';

  @override
  String get updateNoReleaseNotes => '未提供更新说明。';

  @override
  String get updateLater => '稍后';

  @override
  String get updateDownloadApk => '下载 APK';

  @override
  String get updateInstall => '更新';

  @override
  String get shareLinkTitle => '共享链接';

  @override
  String get shareViaLink => '通过链接分享';

  @override
  String get shareInServer => '在服务器中共享';

  @override
  String get expiryDays => '有效期（天）';

  @override
  String get expiryNever => '永久有效';

  @override
  String get expiry1Day => '1 天';

  @override
  String get expiry7Days => '7 天';

  @override
  String get expiry30Days => '30 天';

  @override
  String get expiry90Days => '90 天';

  @override
  String get expiry180Days => '180 天';

  @override
  String get expiry365Days => '365 天';

  @override
  String get createLink => '创建链接';

  @override
  String get sharedLinkCopied => '共享链接已复制到剪贴板！';

  @override
  String failedToCopySharedLink(String error) {
    return '复制共享链接失败：$error';
  }

  @override
  String get cannotShareThisFileType => '无法分享此类文件。';

  @override
  String failedToCreateShare(String error) {
    return '创建共享失败：$error';
  }

  @override
  String get newFolderTitle => '新建文件夹';

  @override
  String get newFolderHint => '文件夹名称';

  @override
  String get newFolder => '新建文件夹';

  @override
  String get folderCreated => '文件夹已创建。';

  @override
  String failedToCreateFolder(String error) {
    return '创建文件夹失败：$error';
  }

  @override
  String get creatingFolder => '正在创建文件夹...';

  @override
  String get renameDialogTitle => '重命名';

  @override
  String get renameHint => '新名称';

  @override
  String get enterNewName => '输入新名称';

  @override
  String get renamedSuccessfully => '重命名成功。';

  @override
  String renameFailed(String error) {
    return '重命名失败：$error';
  }

  @override
  String get moveDialogTitle => '移动到';

  @override
  String moveTo(String path) {
    return '移动到：$path';
  }

  @override
  String get moveHere => '移至此处';

  @override
  String moveFailed(String error) {
    return '移动失败：$error';
  }

  @override
  String get movedToFolder => '已移动到文件夹。';

  @override
  String copyFailed(String error) {
    return '复制失败：$error';
  }

  @override
  String get selectFolder => '选择文件夹';

  @override
  String get useThisFolder => '使用此文件夹';

  @override
  String get storageRoot => '存储';

  @override
  String get serverRoot => '根目录';

  @override
  String deleteNItemsTitle(int count) {
    return '删除 $count 个项目？';
  }

  @override
  String get deleteFilesTitle => '删除文件？';

  @override
  String deleteFilesBody(int count) {
    return '确定要删除选中的 $count 个项目吗？此操作无法撤销。';
  }

  @override
  String get deletePermanently => '永久删除';

  @override
  String get deletePermanentlyTitle => '永久删除？';

  @override
  String deletePermanentlyBody(String filename) {
    return '$filename 将被永久删除。';
  }

  @override
  String get deleteFileTitle => '删除文件？';

  @override
  String deleteFileBody(String filename) {
    return '确定要删除 $filename 吗？此操作无法撤销。';
  }

  @override
  String get deleteServerFileTitle => '永久删除';

  @override
  String deleteServerFileBody(String filename) {
    return '确定要永久删除 \"$filename\" 吗？此操作无法撤销。';
  }

  @override
  String get unshareItemsTitle => '取消共享项目？';

  @override
  String unshareItemsBody(int count) {
    return '确定要取消共享选中的 $count 个项目吗？这将把它们从“已共享”文件夹中移除。';
  }

  @override
  String get unshare => '取消共享';

  @override
  String get moveToTrash => '移至回收站';

  @override
  String get movedToTrash => '已移至回收站。';

  @override
  String movedNItemsToTrash(int count) {
    return '已将 $count 个项目移至回收站。';
  }

  @override
  String failedToMoveToTrash(String error) {
    return '移至回收站失败：$error';
  }

  @override
  String deletedNItems(int count) {
    return '已删除 $count 个项目。';
  }

  @override
  String failedToDelete(String error) {
    return '删除失败：$error';
  }

  @override
  String failedToDeleteItem(String error) {
    return '删除失败：$error';
  }

  @override
  String deletedFilename(String filename) {
    return '已删除 $filename。';
  }

  @override
  String get failedToOpenFile => '无法打开文件';

  @override
  String fileDownloadFailed(String error) {
    return '下载失败：$error';
  }

  @override
  String get downloading => '正在下载...';

  @override
  String get downloadingFile => '正在下载文件...';

  @override
  String downloadComplete(String filename) {
    return '下载完成：$filename';
  }

  @override
  String downloadFailed(String error) {
    return '下载失败：$error';
  }

  @override
  String get failedToDownloadPreview => '无法下载预览';

  @override
  String uploadComplete(String filename) {
    return '上传完成：$filename';
  }

  @override
  String uploadFailed(String error) {
    return '上传失败：$error';
  }

  @override
  String get failedToPickFiles => '无法选择文件';

  @override
  String uploadedNItems(int count) {
    return '已上传 $count 个文件';
  }

  @override
  String get copiedLinkToClipboard => '链接已复制到剪贴板。';

  @override
  String failedToCopyLink(String error) {
    return '复制链接失败：$error';
  }

  @override
  String get selectingAll => '正在全选...';

  @override
  String get allItemsSelected => '已选中所有项目。';

  @override
  String get failedToLoadSearchResults => '加载搜索结果失败';

  @override
  String get shareNotSupportedForType => '此类文件不支持共享。';

  @override
  String nSelected(int count) {
    return '已选择 $count 项';
  }

  @override
  String get noServerSelected => '未选择服务器';

  @override
  String get pleaseConnectToServerFirst => '请先连接到服务器。';

  @override
  String get signInRequired => '需要登录';

  @override
  String pleaseSignInToServer(String serverName) {
    return '请先登录到 $serverName。';
  }

  @override
  String get connectingToServer => '正在连接到服务器...';

  @override
  String connectedToServer(String serverName) {
    return '已连接到 $serverName。';
  }

  @override
  String connectionFailed(String error) {
    return '连接失败：$error';
  }

  @override
  String failedToConnect(String error) {
    return '无法连接：$error';
  }

  @override
  String authFailed(String error) {
    return '身份验证失败：$error';
  }

  @override
  String get authFailedGeneric => '身份验证失败。请重试。';

  @override
  String biometricLoginFailed(String error) {
    return '生物识别登录失败：$error';
  }

  @override
  String get biometricLoginFailedGeneric => '生物识别登录失败。';

  @override
  String get noServerSessionToken => '无服务器会话令牌。请重新进行服务器验证。';

  @override
  String failedToSaveServer(String error) {
    return '保存服务器失败：$error';
  }

  @override
  String get addToFolder => '添加到文件夹';

  @override
  String get loginTabLabel => '登录';

  @override
  String get registerTabLabel => '注册';

  @override
  String get welcomeBack => '欢迎回来';

  @override
  String get signInToContinue => '登录以继续';

  @override
  String get createAccount => '创建账户';

  @override
  String get joinTheServer => '加入服务器';

  @override
  String get usernameLabel => '用户名';

  @override
  String get usernameHint => '输入您的用户名';

  @override
  String get passwordLabel => '密码';

  @override
  String get passwordHint => '输入您的密码';

  @override
  String get showPassword => '显示密码';

  @override
  String get hidePassword => '隐藏密码';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get logIn => '登录';

  @override
  String get loggingIn => '正在登录...';

  @override
  String get registering => '正在注册...';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get doNotHaveAccount => '没有账户？切换到注册。';

  @override
  String get alreadyHaveAccount => '已有账户？切换到登录。';

  @override
  String get usernameCannotBeEmpty => '用户名不能为空。';

  @override
  String get passwordCannotBeEmpty => '密码不能为空。';

  @override
  String get usernameInvalid => '用户名须为 3–32 个字符，包含字母、数字、_ 或 -。';

  @override
  String get passwordTooShort => '密码长度至少为 8 个字符。';

  @override
  String loginFailed(String error) {
    return '登录失败：$error';
  }

  @override
  String registrationFailed(String error) {
    return '注册失败：$error';
  }

  @override
  String get resetPasswordTitle => '重置密码';

  @override
  String get enterResetCodeTitle => '输入重置码';

  @override
  String get resetPasswordStep1Body => '输入您的用户名。6 位确认码将输出到服务器日志/控制台。';

  @override
  String get resetPasswordStep2Body => '确认码已发送到服务器控制台。请输入 6 位代码和您的新密码。';

  @override
  String get resetCodeLabel => '重置验证码';

  @override
  String get resetCodeHint => '输入 6 位验证码';

  @override
  String get newPasswordLabel => '新密码';

  @override
  String get newPasswordHint => '输入新密码';

  @override
  String get passwordResetSuccessfully => '密码重置成功！';

  @override
  String get usernameIsRequired => '用户名是必填项。';

  @override
  String get codeAndPasswordRequired => '验证码和新密码均为必填项。';

  @override
  String get failedToRequestReset => '请求重置失败。请检查服务器 URL。';

  @override
  String get failedToResetPassword => '重置密码失败。请检查验证码。';

  @override
  String get pleaseEnterServerUrlFirst => '请先输入服务器 URL。';

  @override
  String get sendCode => '发送验证码';

  @override
  String get settingsTitle => '设置';

  @override
  String get sectionBackupSync => '备份与同步';

  @override
  String get sectionStorageCache => '存储与缓存';

  @override
  String get sectionSecurityBehavior => '安全与行为';

  @override
  String get sectionAboutUpdates => '关于与更新';

  @override
  String get sectionAppearance => '外观与自定义';

  @override
  String get noServersConfiguredSync => '未配置服务器';

  @override
  String get addServerBeforeSync => '请在配置同步前添加服务器。';

  @override
  String get selectServerToConfigureSync => '选择要配置同步的服务器。';

  @override
  String get activeServerSuffix => ' · 当前活动';

  @override
  String get folderAndCategorySync => '文件夹与分类同步';

  @override
  String get keepCategoriesSynced => '使选定的本地分类或文件夹与此服务器保持同步。';

  @override
  String get addServerBeforeSyncEnable => '请在启用同步前添加服务器。';

  @override
  String get onlyOnWifi => '仅在 Wi-Fi 下';

  @override
  String get onlyWhileCharging => '仅在充电时';

  @override
  String get serverTargetDirectory => '服务器目标目录';

  @override
  String get serverTargetDirectoryHint => '/backup/mobile_phone';

  @override
  String get synchronizationFrequency => '同步频率';

  @override
  String get syncNow => '立即同步';

  @override
  String get syncing => '正在同步...';

  @override
  String get categoriesToSynchronize => '要同步的分类';

  @override
  String get noCategoriesSelected => '未选择分类。';

  @override
  String nCategoriesSelected(int count) {
    return '已选择 $count 个分类';
  }

  @override
  String get foldersToSynchronize => '要同步的文件夹';

  @override
  String get noCustomFolders => '未配置自定义文件夹。';

  @override
  String nFolders(int count) {
    return '$count 个文件夹';
  }

  @override
  String get addFolder => '添加文件夹';

  @override
  String get removeFolder => '移除文件夹';

  @override
  String get removeServer => '删除服务器';

  @override
  String get syncFreqEvery15Min => '每 15 分钟';

  @override
  String get syncFreqEvery30Min => '每 30 分钟';

  @override
  String get syncFreqEvery1Hour => '每小时';

  @override
  String syncFreqEveryNHours(int hours) {
    return '每 $hours 小时';
  }

  @override
  String syncFreqEveryNMin(int minutes) {
    return '每 $minutes 分钟';
  }

  @override
  String get syncFreqDaily => '每天';

  @override
  String get chooseSyncFrequencyTitle => '选择同步频率';

  @override
  String get cacheSize => '缓存大小';

  @override
  String get refreshTooltip => '刷新';

  @override
  String get cacheLimit => '缓存限制';

  @override
  String get downloadPath => '下载路径';

  @override
  String get defaultDownloadFolder => '默认 CrowleysCloud 文件夹';

  @override
  String get clearCache => '清除缓存';

  @override
  String get clearCacheTitle => '清除缓存？';

  @override
  String get clearCacheBody => '这将移除本地缩略图和已缓存的服务器目录列表。';

  @override
  String get downloadPathDialogTitle => '下载路径';

  @override
  String get downloadPathHint => '/storage/emulated/0/CrowleysCloud';

  @override
  String get useDefault => '使用默认';

  @override
  String get serverTargetDirDialogTitle => '服务器目标目录';

  @override
  String get requireLogin => '需要登录';

  @override
  String get biometricLogin => '生物识别登录';

  @override
  String get biometricLoginSubtitle => '允许使用生物识别和已保存的凭据登录。';

  @override
  String get biometricsNotAvailable => '此设备上无法使用生物识别。';

  @override
  String get showHiddenFiles => '显示隐藏文件';

  @override
  String get showHiddenFilesSubtitle => '显示以点开头的文件和文件夹。';

  @override
  String get changePassword => '修改密码';

  @override
  String changePasswordSubtitle(String serverName) {
    return '修改 $serverName 上的密码。';
  }

  @override
  String get addServerBeforeChangePassword => '修改密码前请先添加服务器。';

  @override
  String get deleteUserAccount => '删除用户账户';

  @override
  String get deleteUserAccountSubtitle => '删除该用户及其所有私有云文件。';

  @override
  String get deleteAccountTitle => '删除账户？';

  @override
  String deleteAccountBody(String serverName) {
    return '这将永久删除您在 $serverName 上的账户，并移除您私有云文件夹中存储的所有文件。此操作无法撤销。';
  }

  @override
  String get deleteAccountButton => '删除账户';

  @override
  String get changePasswordDialogTitle => '修改密码';

  @override
  String get newPasswordFieldLabel => '新密码';

  @override
  String get confirmPasswordLabel => '确认密码';

  @override
  String get enterNewPassword => '输入新密码。';

  @override
  String get passwordUpdated => '密码已更新。';

  @override
  String passwordChangeFailed(String error) {
    return '修改密码失败：$error';
  }

  @override
  String get passwordChangeFailedGeneric => '修改密码失败。';

  @override
  String get accountDeleted => '账户已删除。';

  @override
  String accountDeletionFailed(String error) {
    return '删除账户失败：$error';
  }

  @override
  String get accountDeletionFailedGeneric => '删除账户失败。';

  @override
  String get checkForUpdates => '检查更新';

  @override
  String get checkingForUpdates => '正在检查 GitHub Releases...';

  @override
  String versionLabel(String version) {
    return '版本 $version';
  }

  @override
  String appIsUpToDate(String version) {
    return 'Crowley\'s Cloud 已是最新版本 (v$version)。';
  }

  @override
  String get updateCheckFailed => '检查更新失败。请稍后重试。';

  @override
  String get themeModeTitle => '主题模式';

  @override
  String get themeDark => '深色';

  @override
  String get themeLight => '浅色';

  @override
  String get themeCustom => '自定义';

  @override
  String get themeDarkFull => '深色主题';

  @override
  String get themeLightFull => '浅色主题';

  @override
  String get themeCustomFull => '自定义主题';

  @override
  String get accentColor => '强调色';

  @override
  String get primaryAccentColor => '主要强调色';

  @override
  String get selectAccentColor => '选择强调色';

  @override
  String get backgroundColor => '背景颜色';

  @override
  String get surfaceColor => '表面颜色';

  @override
  String get textColor => '文字颜色';

  @override
  String get subtextColor => '副文本颜色';

  @override
  String get borderColor => '边框颜色';

  @override
  String get fontSizeScale => '字体缩放比例';

  @override
  String selectColor(String title) {
    return '选择 $title';
  }

  @override
  String get categoriesToSyncDialogTitle => '要同步的分类';

  @override
  String get categoriesToSyncBody => '选择一个或多个分类。您可以全部不选。';

  @override
  String get syncCategorySectionMedia => '媒体';

  @override
  String get syncCategorySectionAudioDocs => '音频与文档';

  @override
  String get syncCategorySectionOther => '其他';

  @override
  String get clearAll => '全部清除';

  @override
  String get noSyncHasRunYet => '尚未运行过同步。';

  @override
  String lastRunAt(String date) {
    return '上次运行于 $date';
  }

  @override
  String syncResultSuccess(int uploaded, int skipped) {
    return '已同步 $uploaded 项，跳过 $skipped 项。';
  }

  @override
  String get syncResultNoFiles => '未选择要同步的文件。';

  @override
  String syncResultPartial(int uploaded, int failed) {
    return '已同步 $uploaded 项，失败 $failed 项。';
  }

  @override
  String get syncResultAuthRequired => '同步前请先登录。';

  @override
  String get syncResultUnreachable => '服务器不可达。连接已断开。';

  @override
  String get syncResultFailed => '同步失败。';

  @override
  String get serverSetupAddServer => '添加服务器';

  @override
  String get serverSetupCardTitle => '连接服务器';

  @override
  String get serverSetupCardSubtitle => '添加您的家庭文件服务器并登录。';

  @override
  String get serverSetupSubmitButton => '保存服务器';

  @override
  String get serverNameLabel => '服务器名称';

  @override
  String get serverNameHint => '家庭 NAS';

  @override
  String get baseUrlLabel => '基本 URL';

  @override
  String get baseUrlHint => 'https://cloud.example.com';

  @override
  String get allFieldsRequired => '所有字段均为必填项。';

  @override
  String get localFilesTitle => '本地文件';

  @override
  String get serverFilesTitle => '服务器文件';

  @override
  String get restoreItemsTitle => '还原项目';

  @override
  String restoreItemsBody(int count) {
    return '确定要还原 $count 个项目吗？';
  }

  @override
  String get permanentlyDeleteTitle => '永久删除';

  @override
  String permanentlyDeleteBody(int count) {
    return '确定要永久删除 $count 个项目吗？此操作无法撤销。';
  }

  @override
  String get trashIsEmpty => '回收站为空。';

  @override
  String trashRetentionInfo(int days) {
    return '回收站中的项目会在 $days 天后自动删除。';
  }

  @override
  String get deletionDate => '删除日期';

  @override
  String get deletePermanentlyAction => '永久删除';

  @override
  String get conflictFileAlreadyExists => '文件已存在';

  @override
  String conflictNofM(int current, int total) {
    return '冲突 $current / $total';
  }

  @override
  String get conflictAFileNamed => '名为 ';

  @override
  String get conflictAlreadyExistsAt => ' 的文件已存在于 ';

  @override
  String get conflictAlreadyExistsInFolder => ' 的文件已存在于此文件夹中。';

  @override
  String get conflictInFolder => '在文件夹中';

  @override
  String get conflictFromTrash => '来自回收站';

  @override
  String get conflictExisting => '现有文件';

  @override
  String get conflictNewUpload => '新上传';

  @override
  String conflictSizeLabel(String size) {
    return '大小：$size';
  }

  @override
  String conflictDateLabel(String date) {
    return '日期：$date';
  }

  @override
  String conflictDeletedLabel(String date) {
    return '删除时间：$date';
  }

  @override
  String conflictApplyToRemaining(int count) {
    return '应用到剩余 $count 个冲突';
  }

  @override
  String get conflictKeepAllCopies => '保留所有副本';

  @override
  String get conflictOverwriteAll => '全部覆盖';

  @override
  String get conflictRestoreAllAsCopies => '全部恢复为副本';

  @override
  String get conflictRestoreAsCopy => '恢复为副本';

  @override
  String get conflictOverwriteAllRemaining => '覆盖所有剩余文件';

  @override
  String get conflictSkipAll => '全部跳过';

  @override
  String get conflictSkipAllRemaining => '跳过所有剩余文件';

  @override
  String get conflictSkip => '跳过';

  @override
  String get conflictOverwrite => '覆盖';

  @override
  String get transfersTitle => '传输';

  @override
  String get transferResume => '继续';

  @override
  String get transferPause => '暂停';

  @override
  String get transferCancel => '取消';

  @override
  String get transferResumeAll => '全部继续';

  @override
  String get transferPauseAll => '全部暂停';

  @override
  String get transferCancelAll => '全部取消';

  @override
  String get transferCancelFile => '取消文件';

  @override
  String get noTransfers => '没有进行中的传输。';

  @override
  String get transferStatusQueued => '排队中';

  @override
  String get transferStatusRunning => '进行中';

  @override
  String get transferStatusPaused => '已暂停';

  @override
  String get transferStatusCompleted => '已完成';

  @override
  String get transferStatusFailed => '失败';

  @override
  String get transferStatusCanceled => '已取消';

  @override
  String get themePresetsSection => '预设主题';

  @override
  String get themeCustomPaletteSection => '自定义调色板';

  @override
  String get themeHexRgbLabel => 'HEX RGB 代码';

  @override
  String get themeHexRgbHint => '#FA5252';

  @override
  String get imageViewerNoFetchHandler => '未配置图像获取处理程序';

  @override
  String get imageViewerFailedToLoad => '无法加载图像';

  @override
  String errorDeletingFile(String filename, String error) {
    return '删除 $filename 失败：$error';
  }

  @override
  String errorReadingFile(String error) {
    return '读取文件失败：$error';
  }

  @override
  String get syncChannelName => '后台同步';

  @override
  String get syncChannelDescription => '显示后台文件同步的状态。';

  @override
  String get storageStatsTitle => '存储统计';

  @override
  String get storageStatsUsedSpace => '已用空间';

  @override
  String get storageStatsTotalFiles => '文件总数';

  @override
  String storageStatsNItems(int count) {
    return '$count 个项目';
  }

  @override
  String userFallback(int userId) {
    return '用户 #$userId';
  }

  @override
  String get biometricUnlockReason => '请验证身份以解锁 Crowley\'s Cloud 保存的凭据。';

  @override
  String get tokenLifetimeEveryOpen => '每次打开应用';

  @override
  String get tokenLifetimeOneHour => '1 小时后';

  @override
  String get tokenLifetime1Hour => '1 小时后';

  @override
  String get tokenLifetimeOneDay => '1 天后';

  @override
  String get tokenLifetime1Day => '1 天后';

  @override
  String get tokenLifetimeOneWeek => '1 周后';

  @override
  String get tokenLifetime1Week => '1 周后';

  @override
  String get tokenLifetimeOneMonth => '1 个月后';

  @override
  String get tokenLifetime1Month => '1 个月后';

  @override
  String get tokenLifetimeThreeMonths => '3 个月后';

  @override
  String get tokenLifetime3Months => '3 个月后';

  @override
  String get tokenLifetimeNever => '在此设备上从不';

  @override
  String get cacheLimitUnlimited => '无限制';

  @override
  String get syncCategoryOtherFiles => '其他文件';

  @override
  String get internalStorage => '内部存储';

  @override
  String get localStorageRootName => '内部存储';

  @override
  String syncNotificationSyncingWith(String serverName) {
    return '正在与 $serverName 同步';
  }

  @override
  String syncNotificationPausedTitle(String serverName) {
    return '与 $serverName 的同步已暂停';
  }

  @override
  String get syncNotificationUnreachableBody => '服务器不可达。后台同步已暂停，直到打开应用程序。';

  @override
  String get syncNotificationAuthRequiredBody => '需要身份验证。请打开应用程序以登录。';

  @override
  String syncNotificationFailedTitle(String serverName) {
    return '与 $serverName 的同步失败';
  }

  @override
  String get syncNotificationGenericErrorBody => '同步过程中发生错误。';

  @override
  String syncNotificationCompleteTitle(String serverName) {
    return '与 $serverName 的同步已完成';
  }

  @override
  String get syncNotificationCompleteBody => '同步完成。';

  @override
  String get syncStatusConnecting => '正在连接到服务器...';

  @override
  String syncStatusConnectionLost(String serverName) {
    return '无法连接到 $serverName。连接已断开。';
  }

  @override
  String syncResultServerUnreachableWithServer(String serverName) {
    return '无法连接到 $serverName。连接已断开。';
  }

  @override
  String get syncStatusScanningFiles => '正在扫描设备上的文件...';

  @override
  String get syncStatusNoFilesFound => '未找到要同步的文件。';

  @override
  String get syncStatusNoFilesSelected => '未选择要同步的文件。';

  @override
  String syncStatusCalculatingChecksum(
    int current,
    int total,
    String filename,
  ) {
    return '正在计算校验和 ($current/$total)：$filename';
  }

  @override
  String get syncStatusCheckingDuplicates => '正在检查服务器上的重复文件...';

  @override
  String syncStatusSyncingFile(int current, int total, String filename) {
    return '正在同步 ($current/$total)：$filename';
  }

  @override
  String get syncStatusCompleting => '正在完成同步...';

  @override
  String get showingCachedFiles => '正在显示缓存的文件。';

  @override
  String get showingCachedFilesRefreshFailed => '正在显示缓存的文件。刷新失败。';

  @override
  String get downloadCanceled => '下载已取消。';

  @override
  String downloadedNFilesToPath(int count, String path) {
    return '已将 $count 个文件下载到 $path';
  }

  @override
  String downloadedNFilesFailedM(int downloaded, int failed, String detail) {
    return '已下载 $downloaded 个文件，失败 $failed 个：$detail';
  }

  @override
  String downloadedNFilesWithFailures(int count, int failed, String error) {
    return '已下载 $count 个文件，失败 $failed 个：$error';
  }

  @override
  String createdNShareLinks(int count) {
    return '已创建 $count 个共享链接。';
  }

  @override
  String get failedToCreateShareLinks => '无法创建共享链接。';

  @override
  String get alreadyInSharedScope => '已在共享范围内。';

  @override
  String sharedNItemsInServer(int count) {
    return '已在服务器中共享 $count 个项目。';
  }

  @override
  String sharedNItemsWithFailures(int count, int failed) {
    return '已共享 $count 个项目，失败 $failed 个。';
  }

  @override
  String sharedNItemsFailedM(int shared, int failed) {
    return '已共享 $shared 个项目，失败 $failed 个。';
  }

  @override
  String get folderNameCannotBeEmpty => '文件夹名称不能为空。';

  @override
  String get folderAlreadyExists => '同名文件夹已存在。';

  @override
  String get folderCreationOnlyInAllFiles => '只能在“全部文件”中创建文件夹。';

  @override
  String get currentDirectoryUnavailable => '当前目录不可用。';

  @override
  String get nothingSelected => '未选择任何项目。';

  @override
  String get destinationFolderDoesNotExist => '目标文件夹不存在。';

  @override
  String cannotMoveFolderIntoItself(String name) {
    return '无法将文件夹 \"$name\" 移动到其自身内部。';
  }

  @override
  String failedToMoveItem(String name, String error) {
    return '移动 $name 失败：$error';
  }

  @override
  String movedNItems(int count) {
    return '已移动 $count 个项目。';
  }

  @override
  String movedNItemsWithFailures(int count, int failed) {
    return '已移动 $count 个项目，失败 $failed 个。';
  }

  @override
  String movedNItemsFailedM(int moved, int failed) {
    return '已移动 $moved 个项目，失败 $failed 个。';
  }

  @override
  String get failedToMoveSelectedItems => '移动所选项目失败。';

  @override
  String get noFilesWereMoved => '未移动任何文件。';

  @override
  String renamedOldToNew(String oldName, String newName) {
    return '已将 \"$oldName\" 重命名为 \"$newName\"。';
  }

  @override
  String renamedFileFromTo(String oldName, String newName) {
    return '已将 \"$oldName\" 重命名为 \"$newName\"。';
  }

  @override
  String failedToRenameWithStatus(String name, int statusCode) {
    return '重命名 \"$name\" 失败 ($statusCode)。';
  }

  @override
  String failedToRenameFileWithCode(String name, int statusCode) {
    return '重命名 \"$name\" 失败 ($statusCode)。';
  }

  @override
  String failedToRenameWithError(String name, String error) {
    return '重命名 \"$name\" 失败：$error';
  }

  @override
  String failedToRenameFile(String name, String error) {
    return '重命名 \"$name\" 失败：$error';
  }

  @override
  String get renameConflictAlreadyExists => '重命名失败：同名文件或文件夹已存在。';

  @override
  String get renameFailedAlreadyExists => '重命名失败：同名文件或文件夹已存在。';

  @override
  String failedToCreateFolderWithCode(int statusCode) {
    return '创建文件夹失败 (代码 $statusCode)。';
  }

  @override
  String deletedNItemsFailedM(int deleted, int failed) {
    return '已删除 $deleted 个项目，失败 $failed 个。';
  }

  @override
  String transferSummaryFiles(int percent, int completed, int total) {
    return '$percent%  $completed/$total 个文件';
  }

  @override
  String transferSummaryProgress(int percent, int completed, int total) {
    return '$percent%  $completed/$total 个文件';
  }

  @override
  String get downloadFailedGeneric => '下载失败';

  @override
  String uploadedNItemsWithFailures(int uploaded, int failed) {
    return '已上传 $uploaded 个项目，失败 $failed 个';
  }

  @override
  String uploadedNItemsFailedM(int uploaded, int failed) {
    return '已上传 $uploaded 个项目，失败 $failed 个。';
  }

  @override
  String uploadSummaryFailedCount(int count) {
    return '，失败 $count 个';
  }

  @override
  String uploadLocalPathEmpty(String name) {
    return '$name：本地路径为空';
  }

  @override
  String uploadErrorLocalPathEmpty(String name) {
    return '$name：本地路径为空';
  }

  @override
  String get directoryUploadFailed => '文件夹上传失败';

  @override
  String get uploadDirectoryFailed => '文件夹上传失败';

  @override
  String get localFileNotFound => '未找到本地文件';

  @override
  String get uploadErrorLocalFileNotFound => '未找到本地文件';

  @override
  String get noSessionToken => '没有活动的会话令牌';

  @override
  String get uploadErrorNoSessionToken => '没有活动的会话令牌';

  @override
  String get serverDisconnectedStatus => '服务器已断开连接';

  @override
  String get serverDisconnected => '服务器已断开连接';

  @override
  String get serverIsUnreachable => '服务器不可达。';

  @override
  String get serverUnreachable => '服务器不可达。';

  @override
  String get uploadErrorLocalDirectoryNotFound => '未找到本地文件夹';

  @override
  String get uploadErrorFailedToScanDirectory => '扫描文件夹失败';

  @override
  String uploadErrorFolderCreateHttp(int statusCode) {
    return '创建文件夹失败 (HTTP $statusCode)';
  }

  @override
  String get authErrorMissingAccessToken => '响应中缺少访问令牌';

  @override
  String get authErrorMissingRefreshToken => '响应中缺少刷新令牌';

  @override
  String get authErrorNoSavedCredentials => '没有可用的已保存凭据';

  @override
  String get authErrorNoRefreshToken => '没有可用的刷新令牌';

  @override
  String get authErrorNoActiveSession => '没有可用的活动会话';

  @override
  String get authErrorNoSavedUsername => '没有可用的已保存用户名';

  @override
  String get updateNoReleasesPublished => '尚未发布任何版本。';

  @override
  String get language => '语言';
}
