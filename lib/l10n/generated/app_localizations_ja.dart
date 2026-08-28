// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Crowley\'s Cloud';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'キャンセル';

  @override
  String get save => '保存';

  @override
  String get delete => '削除';

  @override
  String get rename => '名前を変更';

  @override
  String get close => '閉じる';

  @override
  String get retry => '再試行';

  @override
  String get loading => '読み込み中...';

  @override
  String get confirm => '確認';

  @override
  String get error => 'エラー';

  @override
  String errorWithMessage(String message) {
    return 'エラー: $message';
  }

  @override
  String get unknown => '不明';

  @override
  String get upload => 'アップロード';

  @override
  String get download => 'ダウンロード';

  @override
  String get share => '共有';

  @override
  String get copy => 'コピー';

  @override
  String get move => '移動';

  @override
  String get restore => '復元';

  @override
  String get apply => '適用';

  @override
  String get create => '作成';

  @override
  String get clear => 'クリア';

  @override
  String get add => '追加';

  @override
  String get remove => '削除';

  @override
  String get edit => '編集';

  @override
  String get switchLabel => '切り替え';

  @override
  String get search => '検索';

  @override
  String get name => '名前';

  @override
  String get date => '日付';

  @override
  String get size => 'サイズ';

  @override
  String get type => '種類';

  @override
  String get ascending => '昇順';

  @override
  String get descending => '降順';

  @override
  String get allFiles => 'すべて';

  @override
  String get categoryImages => '画像';

  @override
  String get categoryPhotos => '写真';

  @override
  String get categoryVideos => '動画';

  @override
  String get categoryAudio => '音声';

  @override
  String get categoryDocuments => 'ドキュメント';

  @override
  String get categoryArchives => 'アーカイブ';

  @override
  String get categoryShared => '共有済み';

  @override
  String get categoryOther => 'その他';

  @override
  String get categoryOtherFiles => 'その他のファイル';

  @override
  String get noFilesFound => 'ファイルが見つかりません。';

  @override
  String get noFilesInFolder => 'このフォルダーにはファイルがありません。';

  @override
  String get thisActionCannotBeUndone => 'この操作は元に戻せません。';

  @override
  String get passwordsDoNotMatch => 'パスワードが一致しません。';

  @override
  String get navLocalFiles => 'ローカル';

  @override
  String get navServerFiles => 'サーバー';

  @override
  String get navSettings => '設定';

  @override
  String get navTrash => 'ごみ箱';

  @override
  String get navLocal => 'ローカル';

  @override
  String get navServer => 'サーバー';

  @override
  String get addServer => 'サーバーを追加';

  @override
  String get noServersConfigured => 'サーバーが設定されていません。';

  @override
  String get addAServerInSettings => '設定でサーバーを追加してください。';

  @override
  String get addFirstServerHint => '続行するには最初のサーバーを追加してください。';

  @override
  String get noServersConfiguredYet => 'サーバーはまだ設定されていません。';

  @override
  String get crowleysCloudSetup => 'Crowley\'s Cloud セットアップ';

  @override
  String get connect => '接続';

  @override
  String get connecting => '接続中...';

  @override
  String get connected => '接続済み';

  @override
  String get disconnected => '切断';

  @override
  String get switchServer => 'サーバーを切り替え';

  @override
  String get chooseOtherServer => '他のサーバーを選択';

  @override
  String get switchServerTitle => 'サーバーを切り替えますか？';

  @override
  String switchServerBody(String serverName) {
    return 'アクティブなサーバーを「$serverName」に切り替えますか？';
  }

  @override
  String get chooseServer => 'サーバーを選択';

  @override
  String get authenticationRequired => '認証が必要です';

  @override
  String signInToAccess(String serverName) {
    return '$serverName のファイルにアクセスするにはサインインしてください';
  }

  @override
  String get signInWithPassword => 'パスワードでサインイン';

  @override
  String get useBiometrics => '生体認証を使用';

  @override
  String get openingSignIn => 'サインインを開いています...';

  @override
  String get serverConnectionFailed => 'サーバーへの接続に失敗しました';

  @override
  String get unableToConnectToServer => 'アクティブなサーバーに接続できません。';

  @override
  String unableToConnectTo(String serverName) {
    return '$serverName に接続できません。';
  }

  @override
  String get searchHint => '検索...';

  @override
  String get searchFilesHint => 'ファイルを検索...';

  @override
  String get searchServerFilesHint => 'サーバーのファイルを検索...';

  @override
  String get searchTrashHint => 'ごみ箱を検索...';

  @override
  String get storagePermissionRequired => 'ストレージの権限が必要です';

  @override
  String get grantPermission => '権限を許可';

  @override
  String get permissionDeniedOpenSettings =>
      '権限が拒否されました。設定でストレージへのアクセスを許可してください。';

  @override
  String get manageStoragePermissionRequired =>
      'フォルダーを参照および選択するには、すべてのファイルの管理権限が必要です。';

  @override
  String get storagePermissionsRequired => '同期を実行するにはストレージの権限が必要です。';

  @override
  String updateAvailableTitle(String version) {
    return 'アップデートがあります: v$version';
  }

  @override
  String get updateAvailableTapToSeeNew => 'タップして更新内容を確認';

  @override
  String get updateView => '表示';

  @override
  String get updateAvailableDialogTitle => 'アップデートがあります';

  @override
  String updateVersionSubtitle(String version) {
    return 'バージョン $version';
  }

  @override
  String updateCurrentVersion(String version) {
    return '現在: v$version';
  }

  @override
  String updateNewVersion(String version) {
    return '最新: v$version';
  }

  @override
  String get updateWhatsNew => '更新内容:';

  @override
  String get updateGitHub => 'GitHub';

  @override
  String get updateNoReleaseNotes => 'リリースノートはありません。';

  @override
  String get updateLater => '後で';

  @override
  String get updateDownloadApk => 'APK をダウンロード';

  @override
  String get updateInstall => '更新';

  @override
  String get shareLinkTitle => '共有リンク';

  @override
  String get shareViaLink => 'リンクで共有';

  @override
  String get shareInServer => 'サーバーで共有';

  @override
  String get expiryDays => '有効期間 (日数)';

  @override
  String get expiryNever => 'なし';

  @override
  String get expiry1Day => '1日';

  @override
  String get expiry7Days => '7日';

  @override
  String get expiry30Days => '30日';

  @override
  String get expiry90Days => '90日';

  @override
  String get expiry180Days => '180日';

  @override
  String get expiry365Days => '365日';

  @override
  String get createLink => 'リンクを作成';

  @override
  String get sharedLinkCopied => '共有リンクをクリップボードにコピーしました！';

  @override
  String failedToCopySharedLink(String error) {
    return '共有リンクのコピーに失敗しました: $error';
  }

  @override
  String get cannotShareThisFileType => 'この種類のファイルは共有できません。';

  @override
  String failedToCreateShare(String error) {
    return '共有の作成に失敗しました: $error';
  }

  @override
  String get newFolderTitle => 'フォルダーを作成';

  @override
  String get newFolderHint => 'フォルダー名';

  @override
  String get newFolder => '新しいフォルダー';

  @override
  String get folderCreated => 'フォルダーを作成しました。';

  @override
  String failedToCreateFolder(String error) {
    return 'フォルダーの作成に失敗しました: $error';
  }

  @override
  String get creatingFolder => 'フォルダーを作成中...';

  @override
  String get renameDialogTitle => '名前を変更';

  @override
  String get renameHint => '新しい名前';

  @override
  String get enterNewName => '新しい名前を入力';

  @override
  String get renamedSuccessfully => '名前を変更しました。';

  @override
  String renameFailed(String error) {
    return '名前の変更に失敗しました: $error';
  }

  @override
  String get moveDialogTitle => '移動先';

  @override
  String moveTo(String path) {
    return '移動先: $path';
  }

  @override
  String get moveHere => 'ここに移動';

  @override
  String moveFailed(String error) {
    return '移動に失敗しました: $error';
  }

  @override
  String get movedToFolder => 'フォルダーに移動しました。';

  @override
  String copyFailed(String error) {
    return 'コピーに失敗しました: $error';
  }

  @override
  String get selectFolder => 'フォルダーを選択';

  @override
  String get useThisFolder => 'このフォルダーを使用';

  @override
  String get storageRoot => 'ストレージ';

  @override
  String get serverRoot => 'ルート';

  @override
  String deleteNItemsTitle(int count) {
    return '$count 件の項目を削除しますか？';
  }

  @override
  String get deleteFilesTitle => 'ファイルを削除しますか？';

  @override
  String deleteFilesBody(int count) {
    return '選択した $count 件の項目を削除してもよろしいですか？この操作は元に戻せません。';
  }

  @override
  String get deletePermanently => '完全に削除';

  @override
  String get deletePermanentlyTitle => '完全に削除しますか？';

  @override
  String deletePermanentlyBody(String filename) {
    return '「$filename」は完全に削除されます。';
  }

  @override
  String get deleteFileTitle => 'ファイルを削除しますか？';

  @override
  String deleteFileBody(String filename) {
    return '「$filename」を削除してもよろしいですか？この操作は元に戻せません。';
  }

  @override
  String get deleteServerFileTitle => '完全に削除';

  @override
  String deleteServerFileBody(String filename) {
    return '「$filename」を完全に削除してもよろしいですか？この操作は元に戻せません。';
  }

  @override
  String get unshareItemsTitle => '項目の共有を解除しますか？';

  @override
  String unshareItemsBody(int count) {
    return '選択した $count 件の項目の共有を解除してもよろしいですか？共有フォルダーから削除されます。';
  }

  @override
  String get unshare => '共有を解除';

  @override
  String get moveToTrash => 'ごみ箱に移動';

  @override
  String get movedToTrash => 'ごみ箱に移動しました。';

  @override
  String movedNItemsToTrash(int count) {
    return '$count 件の項目をごみ箱に移動しました。';
  }

  @override
  String failedToMoveToTrash(String error) {
    return 'ごみ箱への移動に失敗しました: $error';
  }

  @override
  String deletedNItems(int count) {
    return '$count 件の項目を削除しました。';
  }

  @override
  String failedToDelete(String error) {
    return '削除に失敗しました: $error';
  }

  @override
  String failedToDeleteItem(String error) {
    return '削除に失敗しました: $error';
  }

  @override
  String deletedFilename(String filename) {
    return '「$filename」を削除しました。';
  }

  @override
  String get failedToOpenFile => 'ファイルを開けませんでした';

  @override
  String fileDownloadFailed(String error) {
    return 'ダウンロードに失敗しました: $error';
  }

  @override
  String get downloading => 'ダウンロード中...';

  @override
  String get downloadingFile => 'ファイルをダウンロード中...';

  @override
  String downloadComplete(String filename) {
    return 'ダウンロードが完了しました: $filename';
  }

  @override
  String downloadFailed(String error) {
    return 'ダウンロードに失敗しました: $error';
  }

  @override
  String get failedToDownloadPreview => 'プレビューをダウンロードできませんでした';

  @override
  String uploadComplete(String filename) {
    return 'アップロードが完了しました: $filename';
  }

  @override
  String uploadFailed(String error) {
    return 'アップロードに失敗しました: $error';
  }

  @override
  String get failedToPickFiles => 'ファイルを選択できませんでした';

  @override
  String uploadedNItems(int count) {
    return '$count 件のファイルをアップロードしました';
  }

  @override
  String get copiedLinkToClipboard => 'リンクをクリップボードにコピーしました。';

  @override
  String failedToCopyLink(String error) {
    return 'リンクのコピーに失敗しました: $error';
  }

  @override
  String get selectingAll => 'すべて選択中...';

  @override
  String get allItemsSelected => 'すべての項目を選択しました。';

  @override
  String get failedToLoadSearchResults => '検索結果の読み込みに失敗しました';

  @override
  String get shareNotSupportedForType => 'この種類のファイルは共有に対応していません。';

  @override
  String nSelected(int count) {
    return '$count 件選択中';
  }

  @override
  String get noServerSelected => 'サーバーが選択されていません';

  @override
  String get pleaseConnectToServerFirst => '最初にサーバーへ接続してください。';

  @override
  String get signInRequired => 'サインインが必要です';

  @override
  String pleaseSignInToServer(String serverName) {
    return '最初に $serverName へサインインしてください。';
  }

  @override
  String get connectingToServer => 'サーバーに接続中...';

  @override
  String connectedToServer(String serverName) {
    return '$serverName に接続しました。';
  }

  @override
  String connectionFailed(String error) {
    return '接続に失敗しました: $error';
  }

  @override
  String failedToConnect(String error) {
    return '接続できませんでした: $error';
  }

  @override
  String authFailed(String error) {
    return '認証に失敗しました: $error';
  }

  @override
  String get authFailedGeneric => '認証に失敗しました。もう一度お試しください。';

  @override
  String biometricLoginFailed(String error) {
    return '生体認証ログインに失敗しました: $error';
  }

  @override
  String get biometricLoginFailedGeneric => '生体認証ログインに失敗しました。';

  @override
  String get noServerSessionToken => 'セッショントークンがありません。サーバーで再認証してください。';

  @override
  String failedToSaveServer(String error) {
    return 'サーバーの保存に失敗しました: $error';
  }

  @override
  String get addToFolder => 'フォルダーに追加';

  @override
  String get loginTabLabel => 'ログイン';

  @override
  String get registerTabLabel => 'アカウント登録';

  @override
  String get welcomeBack => 'おかえりなさい';

  @override
  String get signInToContinue => '続行するにはログインしてください';

  @override
  String get createAccount => 'アカウントを作成';

  @override
  String get joinTheServer => 'サーバーに参加';

  @override
  String get usernameLabel => 'ユーザー名';

  @override
  String get usernameHint => 'ユーザー名を入力';

  @override
  String get passwordLabel => 'パスワード';

  @override
  String get passwordHint => 'パスワードを入力';

  @override
  String get showPassword => 'パスワードを表示';

  @override
  String get hidePassword => 'パスワードを非表示';

  @override
  String get confirmPassword => 'パスワードを確認';

  @override
  String get logIn => 'ログイン';

  @override
  String get loggingIn => 'ログイン中...';

  @override
  String get registering => '登録中...';

  @override
  String get forgotPassword => 'パスワードをお忘れですか？';

  @override
  String get doNotHaveAccount => 'アカウントをお持ちでないですか？登録に切り替え。';

  @override
  String get alreadyHaveAccount => '既にアカウントをお持ちですか？ログインに切り替え。';

  @override
  String get usernameCannotBeEmpty => 'ユーザー名を入力してください。';

  @override
  String get passwordCannotBeEmpty => 'パスワードを入力してください。';

  @override
  String get usernameInvalid => 'ユーザー名は3〜32文字の英数字、_、-で指定してください。';

  @override
  String get passwordTooShort => 'パスワードは8文字以上である必要があります。';

  @override
  String loginFailed(String error) {
    return 'ログインに失敗しました: $error';
  }

  @override
  String registrationFailed(String error) {
    return 'アカウント登録に失敗しました: $error';
  }

  @override
  String get resetPasswordTitle => 'パスワードを再設定';

  @override
  String get enterResetCodeTitle => '再設定コードを入力';

  @override
  String get resetPasswordStep1Body =>
      'ユーザー名を入力してください。6桁の確認コードがサーバーログ/コンソールに出力されます。';

  @override
  String get resetPasswordStep2Body =>
      '確認コードがサーバーコンソールに出力されました。6桁のコードと新しいパスワードを入力してください。';

  @override
  String get resetCodeLabel => '再設定コード';

  @override
  String get resetCodeHint => '6桁のコードを入力';

  @override
  String get newPasswordLabel => '新しいパスワード';

  @override
  String get newPasswordHint => '新しいパスワードを入力';

  @override
  String get passwordResetSuccessfully => 'パスワードを再設定しました！';

  @override
  String get usernameIsRequired => 'ユーザー名は必須です。';

  @override
  String get codeAndPasswordRequired => 'コードと新しいパスワードの両方が必要です。';

  @override
  String get failedToRequestReset => '再設定の要求に失敗しました。サーバー URL を確認してください。';

  @override
  String get failedToResetPassword => 'パスワードの再設定に失敗しました。コードを確認してください。';

  @override
  String get pleaseEnterServerUrlFirst => '最初にサーバー URL を入力してください。';

  @override
  String get sendCode => 'コードを送信';

  @override
  String get settingsTitle => '設定';

  @override
  String get sectionBackupSync => 'バックアップと同期';

  @override
  String get sectionStorageCache => 'ストレージとキャッシュ';

  @override
  String get sectionSecurityBehavior => 'セキュリティと動作';

  @override
  String get sectionAboutUpdates => '情報とアップデート';

  @override
  String get sectionAppearance => '外観とカスタマイズ';

  @override
  String get noServersConfiguredSync => 'サーバーが設定されていません';

  @override
  String get addServerBeforeSync => '同期を設定する前にサーバーを追加してください。';

  @override
  String get selectServerToConfigureSync => '同期を設定するサーバーを選択してください。';

  @override
  String get activeServerSuffix => ' · アクティブ';

  @override
  String get folderAndCategorySync => 'フォルダーとカテゴリーの同期';

  @override
  String get keepCategoriesSynced => '選択したローカルカテゴリーまたはフォルダーをこのサーバーと同期させます。';

  @override
  String get addServerBeforeSyncEnable => '同期を有効にする前にサーバーを追加してください。';

  @override
  String get onlyOnWifi => 'Wi-Fi 接続時のみ';

  @override
  String get onlyWhileCharging => '充電中のみ';

  @override
  String get serverTargetDirectory => 'サーバーの保存先ディレクトリ';

  @override
  String get serverTargetDirectoryHint => '/backup/mobile_phone';

  @override
  String get synchronizationFrequency => '同期頻度';

  @override
  String get syncNow => '今すぐ同期';

  @override
  String get syncing => '同期中...';

  @override
  String get categoriesToSynchronize => '同期するカテゴリー';

  @override
  String get noCategoriesSelected => 'カテゴリーが選択されていません。';

  @override
  String nCategoriesSelected(int count) {
    return '$count 件を選択';
  }

  @override
  String get foldersToSynchronize => '同期するフォルダー';

  @override
  String get noCustomFolders => 'カスタムフォルダーが設定されていません。';

  @override
  String nFolders(int count) {
    return '$count 個のフォルダー';
  }

  @override
  String get addFolder => 'フォルダーを追加';

  @override
  String get removeFolder => 'フォルダーを削除';

  @override
  String get removeServer => 'サーバーを削除';

  @override
  String get syncFreqEvery15Min => '15分ごと';

  @override
  String get syncFreqEvery30Min => '30分ごと';

  @override
  String get syncFreqEvery1Hour => '1時間ごと';

  @override
  String syncFreqEveryNHours(int hours) {
    return '$hours 時間ごと';
  }

  @override
  String syncFreqEveryNMin(int minutes) {
    return '$minutes 分ごと';
  }

  @override
  String get syncFreqDaily => '毎日';

  @override
  String get chooseSyncFrequencyTitle => '同期頻度を選択';

  @override
  String get cacheSize => 'キャッシュサイズ';

  @override
  String get refreshTooltip => '更新';

  @override
  String get cacheLimit => 'キャッシュ上限';

  @override
  String get downloadPath => 'ダウンロード保存先';

  @override
  String get defaultDownloadFolder => '既定の CrowleysCloud フォルダー';

  @override
  String get clearCache => 'キャッシュを消去';

  @override
  String get clearCacheTitle => 'キャッシュを消去しますか？';

  @override
  String get clearCacheBody => 'ローカルのサムネイルとキャッシュされたサーバー一覧を削除します。';

  @override
  String get downloadPathDialogTitle => 'ダウンロード保存先';

  @override
  String get downloadPathHint => '/storage/emulated/0/CrowleysCloud';

  @override
  String get useDefault => '既定値を使用';

  @override
  String get serverTargetDirDialogTitle => 'サーバーの保存先ディレクトリ';

  @override
  String get requireLogin => 'ログインを要求';

  @override
  String get biometricLogin => '生体認証ログイン';

  @override
  String get biometricLoginSubtitle => '生体認証による保存された認証情報でのログインを許可します。';

  @override
  String get biometricsNotAvailable => 'このデバイスでは生体認証を利用できません。';

  @override
  String get showHiddenFiles => '隠しファイルを表示';

  @override
  String get showHiddenFilesSubtitle => 'ドットで始まるファイルやフォルダーを表示します。';

  @override
  String get changePassword => 'パスワードを変更';

  @override
  String changePasswordSubtitle(String serverName) {
    return '$serverName のパスワードを変更します。';
  }

  @override
  String get addServerBeforeChangePassword => 'パスワードを変更する前にサーバーを追加してください。';

  @override
  String get deleteUserAccount => 'ユーザーアカウントを削除';

  @override
  String get deleteUserAccountSubtitle => 'ユーザーとすべてのプライベートクラウドファイルを削除します。';

  @override
  String get deleteAccountTitle => 'アカウントを削除しますか？';

  @override
  String deleteAccountBody(String serverName) {
    return '$serverName 上のアカウントを完全に削除し、プライベートクラウドフォルダーに保存されているすべてのファイルを削除します。この操作は元に戻せません。';
  }

  @override
  String get deleteAccountButton => 'アカウントを削除';

  @override
  String get changePasswordDialogTitle => 'パスワードを変更';

  @override
  String get newPasswordFieldLabel => '新しいパスワード';

  @override
  String get confirmPasswordLabel => 'パスワードの確認';

  @override
  String get enterNewPassword => '新しいパスワードを入力してください。';

  @override
  String get passwordUpdated => 'パスワードを更新しました。';

  @override
  String passwordChangeFailed(String error) {
    return 'パスワードの変更に失敗しました: $error';
  }

  @override
  String get passwordChangeFailedGeneric => 'パスワードの変更に失敗しました。';

  @override
  String get accountDeleted => 'アカウントを削除しました。';

  @override
  String accountDeletionFailed(String error) {
    return 'アカウントの削除に失敗しました: $error';
  }

  @override
  String get accountDeletionFailedGeneric => 'アカウントの削除に失敗しました。';

  @override
  String get checkForUpdates => 'アップデートを確認';

  @override
  String get checkingForUpdates => 'GitHub リリースを確認中...';

  @override
  String versionLabel(String version) {
    return 'バージョン $version';
  }

  @override
  String appIsUpToDate(String version) {
    return 'Crowley\'s Cloud は最新です (v$version)。';
  }

  @override
  String get updateCheckFailed => 'アップデートの確認に失敗しました。後でもう一度お試しください。';

  @override
  String get themeModeTitle => 'テーマモード';

  @override
  String get themeDark => 'ダーク';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeCustom => 'カスタム';

  @override
  String get themeDarkFull => 'ダークテーマ';

  @override
  String get themeLightFull => 'ライトテーマ';

  @override
  String get themeCustomFull => 'カスタムテーマ';

  @override
  String get accentColor => 'アクセントカラー';

  @override
  String get primaryAccentColor => 'メインアクセントカラー';

  @override
  String get selectAccentColor => 'アクセントカラーを選択';

  @override
  String get backgroundColor => '背景色';

  @override
  String get surfaceColor => 'サーフェス色';

  @override
  String get textColor => 'テキスト色';

  @override
  String get subtextColor => 'サブテキスト色';

  @override
  String get borderColor => 'ボーダー色';

  @override
  String get fontSizeScale => 'フォントサイズ倍率';

  @override
  String selectColor(String title) {
    return '$title を選択';
  }

  @override
  String get categoriesToSyncDialogTitle => '同期するカテゴリー';

  @override
  String get categoriesToSyncBody => '1つ以上のカテゴリーを選択してください。すべて解除することもできます。';

  @override
  String get syncCategorySectionMedia => 'メディア';

  @override
  String get syncCategorySectionAudioDocs => '音声とドキュメント';

  @override
  String get syncCategorySectionOther => 'その他';

  @override
  String get clearAll => 'すべてクリア';

  @override
  String get noSyncHasRunYet => '同期はまだ実行されていません。';

  @override
  String lastRunAt(String date) {
    return '最終実行日時: $date';
  }

  @override
  String syncResultSuccess(int uploaded, int skipped) {
    return '$uploaded 件を同期し、$skipped 件をスキップしました。';
  }

  @override
  String get syncResultNoFiles => '同期するファイルが選択されていません。';

  @override
  String syncResultPartial(int uploaded, int failed) {
    return '$uploaded 件を同期し、$failed 件が失敗しました。';
  }

  @override
  String get syncResultAuthRequired => '同期する前にサインインしてください。';

  @override
  String get syncResultUnreachable => 'サーバーに接続できません。接続が切断されました。';

  @override
  String get syncResultFailed => '同期に失敗しました。';

  @override
  String get serverSetupAddServer => 'サーバーを追加';

  @override
  String get serverSetupCardTitle => 'サーバーに接続';

  @override
  String get serverSetupCardSubtitle => '自宅のファイルサーバーを追加してサインインしてください。';

  @override
  String get serverSetupSubmitButton => 'サーバーを保存';

  @override
  String get serverNameLabel => 'サーバー名';

  @override
  String get serverNameHint => '自宅の NAS';

  @override
  String get baseUrlLabel => 'ベース URL';

  @override
  String get baseUrlHint => 'https://cloud.example.com';

  @override
  String get allFieldsRequired => 'すべての項目を入力してください。';

  @override
  String get localFilesTitle => 'ローカルファイル';

  @override
  String get serverFilesTitle => 'サーバーファイル';

  @override
  String get restoreItemsTitle => '項目を復元';

  @override
  String restoreItemsBody(int count) {
    return '$count 件の項目を復元してもよろしいですか？';
  }

  @override
  String get permanentlyDeleteTitle => '完全に削除';

  @override
  String permanentlyDeleteBody(int count) {
    return '$count 件の項目を完全に削除してもよろしいですか？この操作は元に戻せません。';
  }

  @override
  String get trashIsEmpty => 'ごみ箱は空です。';

  @override
  String trashRetentionInfo(int days) {
    return 'ごみ箱内の項目は $days 日後に自動的に削除されます。';
  }

  @override
  String get deletionDate => '削除日';

  @override
  String get deletePermanentlyAction => '完全に削除';

  @override
  String get conflictFileAlreadyExists => 'ファイルが既に存在します';

  @override
  String conflictNofM(int current, int total) {
    return '競合 $current / $total';
  }

  @override
  String get conflictAFileNamed => '「';

  @override
  String get conflictAlreadyExistsAt => '」というファイルは既に次の場所に存在します: ';

  @override
  String get conflictAlreadyExistsInFolder => '」というファイルはこのフォルダーに既に存在します。';

  @override
  String get conflictInFolder => 'フォルダー内';

  @override
  String get conflictFromTrash => 'ごみ箱から';

  @override
  String get conflictExisting => '既存のファイル';

  @override
  String get conflictNewUpload => '新規アップロード';

  @override
  String conflictSizeLabel(String size) {
    return 'サイズ: $size';
  }

  @override
  String conflictDateLabel(String date) {
    return '日付: $date';
  }

  @override
  String conflictDeletedLabel(String date) {
    return '削除日時: $date';
  }

  @override
  String conflictApplyToRemaining(int count) {
    return '残りの $count 件の競合に適用';
  }

  @override
  String get conflictKeepAllCopies => 'すべてのコピーを保持';

  @override
  String get conflictOverwriteAll => 'すべて上書き';

  @override
  String get conflictRestoreAllAsCopies => 'すべてコピーとして復元';

  @override
  String get conflictRestoreAsCopy => 'コピーとして復元';

  @override
  String get conflictOverwriteAllRemaining => '残りをすべて上書き';

  @override
  String get conflictSkipAll => 'すべてスキップ';

  @override
  String get conflictSkipAllRemaining => '残りをすべてスキップ';

  @override
  String get conflictSkip => 'スキップ';

  @override
  String get conflictOverwrite => '上書き';

  @override
  String get transfersTitle => '転送';

  @override
  String get transferResume => '再開';

  @override
  String get transferPause => '一時停止';

  @override
  String get transferCancel => 'キャンセル';

  @override
  String get transferResumeAll => 'すべて再開';

  @override
  String get transferPauseAll => 'すべて一時停止';

  @override
  String get transferCancelAll => 'すべてキャンセル';

  @override
  String get transferCancelFile => 'ファイルをキャンセル';

  @override
  String get noTransfers => '転送はありません。';

  @override
  String get transferStatusQueued => '待機中';

  @override
  String get transferStatusRunning => '実行中';

  @override
  String get transferStatusPaused => '一時停止中';

  @override
  String get transferStatusCompleted => '完了';

  @override
  String get transferStatusFailed => '失敗';

  @override
  String get transferStatusCanceled => 'キャンセル済み';

  @override
  String get themePresetsSection => 'プリセット';

  @override
  String get themeCustomPaletteSection => 'カスタムパレット';

  @override
  String get themeHexRgbLabel => 'HEX RGB コード';

  @override
  String get themeHexRgbHint => '#FA5252';

  @override
  String get imageViewerNoFetchHandler => '画像取得ハンドラーが設定されていません';

  @override
  String get imageViewerFailedToLoad => '画像の読み込みに失敗しました';

  @override
  String errorDeletingFile(String filename, String error) {
    return '「$filename」の削除に失敗しました: $error';
  }

  @override
  String errorReadingFile(String error) {
    return 'ファイルの読み取りに失敗しました: $error';
  }

  @override
  String get syncChannelName => 'バックグラウンド同期';

  @override
  String get syncChannelDescription => 'バックグラウンドでのファイル同期状態を表示します。';

  @override
  String get storageStatsTitle => 'ストレージ統計';

  @override
  String get storageStatsUsedSpace => '使用容量';

  @override
  String get storageStatsTotalFiles => '総ファイル数';

  @override
  String storageStatsNItems(int count) {
    return '$count 件の項目';
  }

  @override
  String userFallback(int userId) {
    return 'ユーザー #$userId';
  }

  @override
  String get biometricUnlockReason =>
      'Crowley\'s Cloud に保存された認証情報を解除するには生体認証を行ってください。';

  @override
  String get tokenLifetimeEveryOpen => 'アプリを開くたび';

  @override
  String get tokenLifetimeOneHour => '1時間後';

  @override
  String get tokenLifetime1Hour => '1時間後';

  @override
  String get tokenLifetimeOneDay => '1日後';

  @override
  String get tokenLifetime1Day => '1日後';

  @override
  String get tokenLifetimeOneWeek => '1週間後';

  @override
  String get tokenLifetime1Week => '1週間後';

  @override
  String get tokenLifetimeOneMonth => '1か月後';

  @override
  String get tokenLifetime1Month => '1か月後';

  @override
  String get tokenLifetimeThreeMonths => '3か月後';

  @override
  String get tokenLifetime3Months => '3か月後';

  @override
  String get tokenLifetimeNever => 'このデバイスでは無期限';

  @override
  String get cacheLimitUnlimited => '無制限';

  @override
  String get syncCategoryOtherFiles => 'その他のファイル';

  @override
  String get internalStorage => '内部ストレージ';

  @override
  String get localStorageRootName => '内部ストレージ';

  @override
  String syncNotificationSyncingWith(String serverName) {
    return '$serverName と同期中';
  }

  @override
  String syncNotificationPausedTitle(String serverName) {
    return '$serverName との同期を一時停止しました';
  }

  @override
  String get syncNotificationUnreachableBody =>
      'サーバーに接続できません。アプリを開くまでバックグラウンド同期を一時停止します。';

  @override
  String get syncNotificationAuthRequiredBody => '認証が必要です。アプリを開いてサインインしてください。';

  @override
  String syncNotificationFailedTitle(String serverName) {
    return '$serverName との同期に失敗しました';
  }

  @override
  String get syncNotificationGenericErrorBody => '同期中にエラーが発生しました。';

  @override
  String syncNotificationCompleteTitle(String serverName) {
    return '$serverName との同期が完了しました';
  }

  @override
  String get syncNotificationCompleteBody => '同期が完了しました。';

  @override
  String get syncStatusConnecting => 'サーバーに接続中...';

  @override
  String syncStatusConnectionLost(String serverName) {
    return '$serverName に接続できませんでした。接続が切断されました。';
  }

  @override
  String syncResultServerUnreachableWithServer(String serverName) {
    return '$serverName に接続できませんでした。接続が切断されました。';
  }

  @override
  String get syncStatusScanningFiles => 'デバイス上のファイルをスキャン中...';

  @override
  String get syncStatusNoFilesFound => '同期するファイルが見つかりませんでした。';

  @override
  String get syncStatusNoFilesSelected => '同期するファイルが選択されていません。';

  @override
  String syncStatusCalculatingChecksum(
    int current,
    int total,
    String filename,
  ) {
    return 'チェックサムを計算中 ($current/$total): $filename';
  }

  @override
  String get syncStatusCheckingDuplicates => 'サーバー上の重複ファイルを確認中...';

  @override
  String syncStatusSyncingFile(int current, int total, String filename) {
    return '同期中 ($current/$total): $filename';
  }

  @override
  String get syncStatusCompleting => '同期を完了しています...';

  @override
  String get showingCachedFiles => 'キャッシュされたファイルを表示しています。';

  @override
  String get showingCachedFilesRefreshFailed =>
      'キャッシュされたファイルを表示しています。更新に失敗しました。';

  @override
  String get downloadCanceled => 'ダウンロードをキャンセルしました。';

  @override
  String downloadedNFilesToPath(int count, String path) {
    return '$path に $count 件のファイルをダウンロードしました';
  }

  @override
  String downloadedNFilesFailedM(int downloaded, int failed, String detail) {
    return '$downloaded 件のファイルをダウンロードしました（$failed 件失敗: $detail）';
  }

  @override
  String downloadedNFilesWithFailures(int count, int failed, String error) {
    return '$count 件のファイルをダウンロードしました（$failed 件失敗: $error）';
  }

  @override
  String createdNShareLinks(int count) {
    return '$count 件の共有リンクを作成しました。';
  }

  @override
  String get failedToCreateShareLinks => '共有リンクを作成できませんでした。';

  @override
  String get alreadyInSharedScope => '既に共有スコープ内です。';

  @override
  String sharedNItemsInServer(int count) {
    return 'サーバー上で $count 件の項目を共有しました。';
  }

  @override
  String sharedNItemsWithFailures(int count, int failed) {
    return '$count 件の項目を共有しました（$failed 件失敗）。';
  }

  @override
  String sharedNItemsFailedM(int shared, int failed) {
    return '$shared 件の項目を共有しました（$failed 件失敗）。';
  }

  @override
  String get folderNameCannotBeEmpty => 'フォルダー名を入力してください。';

  @override
  String get folderAlreadyExists => '同じ名前のフォルダーが既に存在します。';

  @override
  String get folderCreationOnlyInAllFiles => 'フォルダーの作成は「すべてのファイル」でのみ可能です。';

  @override
  String get currentDirectoryUnavailable => '現在のディレクトリは利用できません。';

  @override
  String get nothingSelected => '何も選択されていません。';

  @override
  String get destinationFolderDoesNotExist => '移動先フォルダーが存在しません。';

  @override
  String cannotMoveFolderIntoItself(String name) {
    return 'フォルダー「$name」を自分自身の中に移動することはできません。';
  }

  @override
  String failedToMoveItem(String name, String error) {
    return '「$name」の移動に失敗しました: $error';
  }

  @override
  String movedNItems(int count) {
    return '$count 件の項目を移動しました。';
  }

  @override
  String movedNItemsWithFailures(int count, int failed) {
    return '$count 件の項目を移動しました（$failed 件失敗）。';
  }

  @override
  String movedNItemsFailedM(int moved, int failed) {
    return '$moved 件の項目を移動しました（$failed 件失敗）。';
  }

  @override
  String get failedToMoveSelectedItems => '選択した項目の移動に失敗しました。';

  @override
  String get noFilesWereMoved => 'ファイルは移動されませんでした。';

  @override
  String renamedOldToNew(String oldName, String newName) {
    return '「$oldName」の名前を「$newName」に変更しました。';
  }

  @override
  String renamedFileFromTo(String oldName, String newName) {
    return '「$oldName」の名前を「$newName」に変更しました。';
  }

  @override
  String failedToRenameWithStatus(String name, int statusCode) {
    return '「$name」の名前変更に失敗しました ($statusCode)。';
  }

  @override
  String failedToRenameFileWithCode(String name, int statusCode) {
    return '「$name」の名前変更に失敗しました ($statusCode)。';
  }

  @override
  String failedToRenameWithError(String name, String error) {
    return '「$name」の名前変更に失敗しました: $error';
  }

  @override
  String failedToRenameFile(String name, String error) {
    return '「$name」の名前変更に失敗しました: $error';
  }

  @override
  String get renameConflictAlreadyExists =>
      '名前を変更できませんでした: 同じ名前のファイルまたはフォルダーが既に存在します。';

  @override
  String get renameFailedAlreadyExists =>
      '名前を変更できませんでした: 同じ名前のファイルまたはフォルダーが既に存在します。';

  @override
  String failedToCreateFolderWithCode(int statusCode) {
    return 'フォルダーの作成に失敗しました (コード $statusCode)。';
  }

  @override
  String deletedNItemsFailedM(int deleted, int failed) {
    return '$deleted 件の項目を削除しました（$failed 件失敗）。';
  }

  @override
  String transferSummaryFiles(int percent, int completed, int total) {
    return '$percent%  $completed/$total ファイル';
  }

  @override
  String transferSummaryProgress(int percent, int completed, int total) {
    return '$percent%  $completed/$total ファイル';
  }

  @override
  String get downloadFailedGeneric => 'ダウンロードに失敗しました';

  @override
  String uploadedNItemsWithFailures(int uploaded, int failed) {
    return '$uploaded 件の項目をアップロードしました（$failed 件失敗）';
  }

  @override
  String uploadedNItemsFailedM(int uploaded, int failed) {
    return '$uploaded 件の項目をアップロードしました（$failed 件失敗）。';
  }

  @override
  String uploadSummaryFailedCount(int count) {
    return '、$count 件失敗';
  }

  @override
  String uploadLocalPathEmpty(String name) {
    return '$name: ローカルパスが空です';
  }

  @override
  String uploadErrorLocalPathEmpty(String name) {
    return '$name: ローカルパスが空です';
  }

  @override
  String get directoryUploadFailed => 'ディレクトリのアップロードに失敗しました';

  @override
  String get uploadDirectoryFailed => 'ディレクトリのアップロードに失敗しました';

  @override
  String get localFileNotFound => 'ローカルファイルが見つかりません';

  @override
  String get uploadErrorLocalFileNotFound => 'ローカルファイルが見つかりません';

  @override
  String get noSessionToken => 'アクティブなセッショントークンがありません';

  @override
  String get uploadErrorNoSessionToken => 'アクティブなセッショントークンがありません';

  @override
  String get serverDisconnectedStatus => 'サーバーが切断されました';

  @override
  String get serverDisconnected => 'サーバーが切断されました';

  @override
  String get serverIsUnreachable => 'サーバーに接続できません。';

  @override
  String get serverUnreachable => 'サーバーに接続できません。';

  @override
  String get uploadErrorLocalDirectoryNotFound => 'ローカルディレクトリが見つかりません';

  @override
  String get uploadErrorFailedToScanDirectory => 'ディレクトリのスキャンに失敗しました';

  @override
  String uploadErrorFolderCreateHttp(int statusCode) {
    return 'フォルダーの作成に失敗しました (HTTP $statusCode)';
  }

  @override
  String get authErrorMissingAccessToken => '応答にアクセストークンがありません';

  @override
  String get authErrorMissingRefreshToken => '応答にリフレッシュトークンがありません';

  @override
  String get authErrorNoSavedCredentials => '保存された認証情報がありません';

  @override
  String get authErrorNoRefreshToken => '利用可能なリフレッシュトークンがありません';

  @override
  String get authErrorNoActiveSession => 'アクティブなセッションがありません';

  @override
  String get authErrorNoSavedUsername => '保存されたユーザー名がありません';

  @override
  String get updateNoReleasesPublished => '公開されているリリースはまだありません。';

  @override
  String get language => '言語';
}
