// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Crowley\'s Cloud';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get rename => 'Rename';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading...';

  @override
  String get confirm => 'Confirm';

  @override
  String get error => 'Error';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get unknown => 'Unknown';

  @override
  String get upload => 'Upload';

  @override
  String get download => 'Download';

  @override
  String get share => 'Share';

  @override
  String get copy => 'Copy';

  @override
  String get move => 'Move';

  @override
  String get restore => 'Restore';

  @override
  String get apply => 'Apply';

  @override
  String get create => 'Create';

  @override
  String get clear => 'Clear';

  @override
  String get add => 'Add';

  @override
  String get remove => 'Remove';

  @override
  String get edit => 'Edit';

  @override
  String get switchLabel => 'Switch';

  @override
  String get search => 'Search';

  @override
  String get name => 'Name';

  @override
  String get date => 'Date';

  @override
  String get size => 'Size';

  @override
  String get type => 'Type';

  @override
  String get ascending => 'Ascending';

  @override
  String get descending => 'Descending';

  @override
  String get allFiles => 'All';

  @override
  String get categoryImages => 'Images';

  @override
  String get categoryPhotos => 'Photos';

  @override
  String get categoryVideos => 'Videos';

  @override
  String get categoryAudio => 'Audio';

  @override
  String get categoryDocuments => 'Documents';

  @override
  String get categoryArchives => 'Archives';

  @override
  String get categoryShared => 'Shared';

  @override
  String get categoryOther => 'Other';

  @override
  String get categoryOtherFiles => 'Other files';

  @override
  String get noFilesFound => 'No files found.';

  @override
  String get noFilesInFolder => 'No files in this folder.';

  @override
  String get thisActionCannotBeUndone => 'This action cannot be undone.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get navLocalFiles => 'Local Files';

  @override
  String get navServerFiles => 'Server Files';

  @override
  String get navSettings => 'Settings';

  @override
  String get navTrash => 'Trash';

  @override
  String get navLocal => 'Local';

  @override
  String get navServer => 'Server';

  @override
  String get addServer => 'Add Server';

  @override
  String get noServersConfigured => 'No servers configured.';

  @override
  String get addAServerInSettings => 'Add a server in Settings.';

  @override
  String get addFirstServerHint => 'Add your first server to continue.';

  @override
  String get noServersConfiguredYet => 'No servers configured yet.';

  @override
  String get crowleysCloudSetup => 'Crowley\'s Cloud setup';

  @override
  String get connect => 'Connect';

  @override
  String get connecting => 'Connecting...';

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get switchServer => 'Switch Server';

  @override
  String get chooseOtherServer => 'Choose other server';

  @override
  String get switchServerTitle => 'Switch server?';

  @override
  String switchServerBody(String serverName) {
    return 'Switch active server to \"$serverName\"?';
  }

  @override
  String get chooseServer => 'Choose server';

  @override
  String get authenticationRequired => 'Authentication required';

  @override
  String signInToAccess(String serverName) {
    return 'Sign in to access files on $serverName';
  }

  @override
  String get signInWithPassword => 'Sign In with Password';

  @override
  String get useBiometrics => 'Use Biometrics';

  @override
  String get openingSignIn => 'Opening sign in...';

  @override
  String get serverConnectionFailed => 'Server connection failed';

  @override
  String get unableToConnectToServer =>
      'Unable to connect to the active server.';

  @override
  String unableToConnectTo(String serverName) {
    return 'Unable to connect to $serverName.';
  }

  @override
  String get searchHint => 'Search...';

  @override
  String get searchFilesHint => 'Search files...';

  @override
  String get searchServerFilesHint => 'Search server files...';

  @override
  String get searchTrashHint => 'Search trash...';

  @override
  String get storagePermissionRequired => 'Storage permission required';

  @override
  String get grantPermission => 'Grant Permission';

  @override
  String get permissionDeniedOpenSettings =>
      'Permission denied. Please grant storage access in Settings.';

  @override
  String get manageStoragePermissionRequired =>
      'Manage Storage permission is required to browse and select folders.';

  @override
  String get storagePermissionsRequired =>
      'Storage permissions are required to perform synchronization.';

  @override
  String updateAvailableTitle(String version) {
    return 'Update available: v$version';
  }

  @override
  String get updateAvailableTapToSeeNew => 'Tap to see what\'s new';

  @override
  String get updateView => 'View';

  @override
  String get updateAvailableDialogTitle => 'Update Available';

  @override
  String updateVersionSubtitle(String version) {
    return 'Version $version';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'Current: v$version';
  }

  @override
  String updateNewVersion(String version) {
    return 'New: v$version';
  }

  @override
  String get updateWhatsNew => 'What\'s New:';

  @override
  String get updateGitHub => 'GitHub';

  @override
  String get updateNoReleaseNotes => 'No release notes provided.';

  @override
  String get updateLater => 'Later';

  @override
  String get updateDownloadApk => 'Download APK';

  @override
  String get updateInstall => 'Update';

  @override
  String get shareLinkTitle => 'Share Link';

  @override
  String get shareViaLink => 'Share via link';

  @override
  String get shareInServer => 'Share in server';

  @override
  String get expiryDays => 'Expiry (days)';

  @override
  String get expiryNever => 'Never';

  @override
  String get expiry1Day => '1 day';

  @override
  String get expiry7Days => '7 days';

  @override
  String get expiry30Days => '30 days';

  @override
  String get expiry90Days => '90 days';

  @override
  String get expiry180Days => '180 days';

  @override
  String get expiry365Days => '365 days';

  @override
  String get createLink => 'Create Link';

  @override
  String get sharedLinkCopied => 'Shared link copied to clipboard!';

  @override
  String failedToCopySharedLink(String error) {
    return 'Failed to copy shared link: $error';
  }

  @override
  String get cannotShareThisFileType => 'Cannot share this type of file.';

  @override
  String failedToCreateShare(String error) {
    return 'Failed to create share: $error';
  }

  @override
  String get newFolderTitle => 'Create Folder';

  @override
  String get newFolderHint => 'Folder name';

  @override
  String get newFolder => 'New folder';

  @override
  String get folderCreated => 'Folder created.';

  @override
  String failedToCreateFolder(String error) {
    return 'Failed to create folder: $error';
  }

  @override
  String get creatingFolder => 'Creating folder...';

  @override
  String get renameDialogTitle => 'Rename';

  @override
  String get renameHint => 'New name';

  @override
  String get enterNewName => 'Enter new name';

  @override
  String get renamedSuccessfully => 'Renamed successfully.';

  @override
  String renameFailed(String error) {
    return 'Rename failed: $error';
  }

  @override
  String get moveDialogTitle => 'Move to';

  @override
  String moveTo(String path) {
    return 'Move to: $path';
  }

  @override
  String get moveHere => 'Move Here';

  @override
  String moveFailed(String error) {
    return 'Move failed: $error';
  }

  @override
  String get movedToFolder => 'Moved to folder.';

  @override
  String copyFailed(String error) {
    return 'Copy failed: $error';
  }

  @override
  String get selectFolder => 'Select Folder';

  @override
  String get useThisFolder => 'Use this folder';

  @override
  String get storageRoot => 'Storage';

  @override
  String get serverRoot => 'root';

  @override
  String deleteNItemsTitle(int count) {
    return 'Delete $count items?';
  }

  @override
  String get deleteFilesTitle => 'Delete Files?';

  @override
  String deleteFilesBody(int count) {
    return 'Are you sure you want to delete $count selected items? This action cannot be undone.';
  }

  @override
  String get deletePermanently => 'Delete Permanently';

  @override
  String get deletePermanentlyTitle => 'Delete Permanently?';

  @override
  String deletePermanentlyBody(String filename) {
    return '$filename will be permanently deleted.';
  }

  @override
  String get deleteFileTitle => 'Delete File?';

  @override
  String deleteFileBody(String filename) {
    return 'Are you sure you want to delete $filename? This action cannot be undone.';
  }

  @override
  String get deleteServerFileTitle => 'Delete Permanently';

  @override
  String deleteServerFileBody(String filename) {
    return 'Are you sure you want to permanently delete \"$filename\"? This action cannot be undone.';
  }

  @override
  String get unshareItemsTitle => 'Unshare Items?';

  @override
  String unshareItemsBody(int count) {
    return 'Are you sure you want to unshare $count selected items? This will remove them from the Shared folder.';
  }

  @override
  String get unshare => 'Unshare';

  @override
  String get moveToTrash => 'Move to Trash';

  @override
  String get movedToTrash => 'Moved to trash.';

  @override
  String movedNItemsToTrash(int count) {
    return 'Moved $count items to trash.';
  }

  @override
  String failedToMoveToTrash(String error) {
    return 'Failed to move to trash: $error';
  }

  @override
  String deletedNItems(int count) {
    return 'Deleted $count items.';
  }

  @override
  String failedToDelete(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String failedToDeleteItem(String error) {
    return 'Delete failed: $error';
  }

  @override
  String deletedFilename(String filename) {
    return 'Deleted $filename.';
  }

  @override
  String get failedToOpenFile => 'Failed to open file';

  @override
  String fileDownloadFailed(String error) {
    return 'File download failed: $error';
  }

  @override
  String get downloading => 'Downloading...';

  @override
  String get downloadingFile => 'Downloading file...';

  @override
  String downloadComplete(String filename) {
    return 'Download complete: $filename';
  }

  @override
  String downloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String get failedToDownloadPreview => 'Failed to download file preview';

  @override
  String uploadComplete(String filename) {
    return 'Upload complete: $filename';
  }

  @override
  String uploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get failedToPickFiles => 'Failed to pick files';

  @override
  String uploadedNItems(int count) {
    return 'Uploaded $count item(s)';
  }

  @override
  String get copiedLinkToClipboard => 'Copied link to clipboard.';

  @override
  String failedToCopyLink(String error) {
    return 'Failed to copy link: $error';
  }

  @override
  String get selectingAll => 'Selecting all...';

  @override
  String get allItemsSelected => 'All items selected.';

  @override
  String get failedToLoadSearchResults => 'Failed to load search results';

  @override
  String get shareNotSupportedForType =>
      'Share not supported for this file type.';

  @override
  String nSelected(int count) {
    return '$count selected';
  }

  @override
  String get noServerSelected => 'No server selected';

  @override
  String get pleaseConnectToServerFirst => 'Please connect to a server first.';

  @override
  String get signInRequired => 'Sign in required';

  @override
  String pleaseSignInToServer(String serverName) {
    return 'Please sign in to $serverName first.';
  }

  @override
  String get connectingToServer => 'Connecting to server...';

  @override
  String connectedToServer(String serverName) {
    return 'Connected to $serverName.';
  }

  @override
  String connectionFailed(String error) {
    return 'Connection failed: $error';
  }

  @override
  String failedToConnect(String error) {
    return 'Failed to connect: $error';
  }

  @override
  String authFailed(String error) {
    return 'Authentication failed: $error';
  }

  @override
  String get authFailedGeneric => 'Authentication failed. Please try again.';

  @override
  String biometricLoginFailed(String error) {
    return 'Biometric login failed: $error';
  }

  @override
  String get biometricLoginFailedGeneric => 'Biometric login failed.';

  @override
  String get noServerSessionToken =>
      'No server session token. Re-authenticate server.';

  @override
  String failedToSaveServer(String error) {
    return 'Failed to save server: $error';
  }

  @override
  String get addToFolder => 'Add to folder';

  @override
  String get loginTabLabel => 'Log In';

  @override
  String get registerTabLabel => 'Register';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get createAccount => 'Create Account';

  @override
  String get joinTheServer => 'Join the server';

  @override
  String get usernameLabel => 'Username';

  @override
  String get usernameHint => 'Enter your username';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get logIn => 'Log In';

  @override
  String get loggingIn => 'Logging in...';

  @override
  String get registering => 'Registering...';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get doNotHaveAccount => 'Do not have an account? Switch to Register.';

  @override
  String get alreadyHaveAccount => 'Already have an account? Switch to Log In.';

  @override
  String get usernameCannotBeEmpty => 'Username cannot be empty.';

  @override
  String get passwordCannotBeEmpty => 'Password cannot be empty.';

  @override
  String get usernameInvalid =>
      'Username must be 3–32 chars, letters, numbers, _ or -.';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters.';

  @override
  String loginFailed(String error) {
    return 'Login failed: $error';
  }

  @override
  String registrationFailed(String error) {
    return 'Registration failed: $error';
  }

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get enterResetCodeTitle => 'Enter Reset Code';

  @override
  String get resetPasswordStep1Body =>
      'Enter your username. The 6-digit verification code will be printed to the server logs/console.';

  @override
  String get resetPasswordStep2Body =>
      'Verification code has been printed to the server console. Enter the 6-digit code and your new password.';

  @override
  String get resetCodeLabel => 'Reset Code';

  @override
  String get resetCodeHint => 'Enter 6-digit code';

  @override
  String get newPasswordLabel => 'New Password';

  @override
  String get newPasswordHint => 'Enter new password';

  @override
  String get passwordResetSuccessfully => 'Password reset successfully!';

  @override
  String get usernameIsRequired => 'Username is required.';

  @override
  String get codeAndPasswordRequired => 'Code and new password are required.';

  @override
  String get failedToRequestReset =>
      'Failed to request reset. Verify the server URL.';

  @override
  String get failedToResetPassword =>
      'Failed to reset password. Please check the code.';

  @override
  String get pleaseEnterServerUrlFirst => 'Please enter a server URL first.';

  @override
  String get sendCode => 'Send Code';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionBackupSync => 'Backup & Sync';

  @override
  String get sectionStorageCache => 'Storage & Cache';

  @override
  String get sectionSecurityBehavior => 'Security & Behavior';

  @override
  String get sectionAboutUpdates => 'About & Updates';

  @override
  String get sectionAppearance => 'Appearance & Customization';

  @override
  String get noServersConfiguredSync => 'No servers configured';

  @override
  String get addServerBeforeSync => 'Add a server before configuring sync.';

  @override
  String get selectServerToConfigureSync =>
      'Select a server to configure its sync settings.';

  @override
  String get activeServerSuffix => '· active';

  @override
  String get folderAndCategorySync => 'Folder and category sync';

  @override
  String get keepCategoriesSynced =>
      'Keep selected local categories or folders synced with this server.';

  @override
  String get addServerBeforeSyncEnable =>
      'Add a server before enabling synchronization.';

  @override
  String get onlyOnWifi => 'Only on Wi-Fi';

  @override
  String get onlyWhileCharging => 'Only while charging';

  @override
  String get serverTargetDirectory => 'Server target directory';

  @override
  String get serverTargetDirectoryHint => '/backup/mobile_phone';

  @override
  String get synchronizationFrequency => 'Synchronization frequency';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncing => 'Syncing...';

  @override
  String get categoriesToSynchronize => 'Categories to synchronize';

  @override
  String get noCategoriesSelected => 'No categories selected.';

  @override
  String nCategoriesSelected(int count) {
    return '$count selected';
  }

  @override
  String get foldersToSynchronize => 'Folders to synchronize';

  @override
  String get noCustomFolders => 'No custom folders configured.';

  @override
  String nFolders(int count) {
    return '$count folder(s)';
  }

  @override
  String get addFolder => 'Add folder';

  @override
  String get removeFolder => 'Remove folder';

  @override
  String get removeServer => 'Remove server';

  @override
  String get syncFreqEvery15Min => 'Every 15 minutes';

  @override
  String get syncFreqEvery30Min => 'Every 30 minutes';

  @override
  String get syncFreqEvery1Hour => 'Every hour';

  @override
  String syncFreqEveryNHours(int hours) {
    return 'Every $hours hours';
  }

  @override
  String syncFreqEveryNMin(int minutes) {
    return 'Every $minutes minutes';
  }

  @override
  String get syncFreqDaily => 'Daily';

  @override
  String get chooseSyncFrequencyTitle => 'Choose Sync Frequency';

  @override
  String get cacheSize => 'Cache size';

  @override
  String get refreshTooltip => 'Refresh';

  @override
  String get cacheLimit => 'Cache limit';

  @override
  String get downloadPath => 'Download path';

  @override
  String get defaultDownloadFolder => 'Default CrowleysCloud folder';

  @override
  String get clearCache => 'Clear cache';

  @override
  String get clearCacheTitle => 'Clear cache?';

  @override
  String get clearCacheBody =>
      'This removes local thumbnails and cached server listings.';

  @override
  String get downloadPathDialogTitle => 'Download path';

  @override
  String get downloadPathHint => '/storage/emulated/0/CrowleysCloud';

  @override
  String get useDefault => 'Use default';

  @override
  String get serverTargetDirDialogTitle => 'Server target directory';

  @override
  String get requireLogin => 'Require login';

  @override
  String get biometricLogin => 'Biometric login';

  @override
  String get biometricLoginSubtitle =>
      'Allow saved-credential login with biometrics.';

  @override
  String get biometricsNotAvailable =>
      'Biometrics are not available on this device.';

  @override
  String get showHiddenFiles => 'Show hidden files';

  @override
  String get showHiddenFilesSubtitle => 'Display dot-files and dot-folders.';

  @override
  String get changePassword => 'Change password';

  @override
  String changePasswordSubtitle(String serverName) {
    return 'Update password for $serverName.';
  }

  @override
  String get addServerBeforeChangePassword =>
      'Add a server before changing password.';

  @override
  String get deleteUserAccount => 'Delete user account';

  @override
  String get deleteUserAccountSubtitle =>
      'Deletes the user and all private cloud files.';

  @override
  String get deleteAccountTitle => 'Delete account?';

  @override
  String deleteAccountBody(String serverName) {
    return 'This permanently deletes your account on $serverName and removes all files stored in your private cloud folder. This cannot be undone.';
  }

  @override
  String get deleteAccountButton => 'Delete account';

  @override
  String get changePasswordDialogTitle => 'Change password';

  @override
  String get newPasswordFieldLabel => 'New password';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get enterNewPassword => 'Enter a new password.';

  @override
  String get passwordUpdated => 'Password updated.';

  @override
  String passwordChangeFailed(String error) {
    return 'Password change failed: $error';
  }

  @override
  String get passwordChangeFailedGeneric => 'Password change failed.';

  @override
  String get accountDeleted => 'Account deleted.';

  @override
  String accountDeletionFailed(String error) {
    return 'Account deletion failed: $error';
  }

  @override
  String get accountDeletionFailedGeneric => 'Account deletion failed.';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get checkingForUpdates => 'Checking GitHub Releases...';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String appIsUpToDate(String version) {
    return 'Crowley\'s Cloud is up to date (v$version).';
  }

  @override
  String get updateCheckFailed =>
      'Failed to check for updates. Please try again later.';

  @override
  String get themeModeTitle => 'Theme Mode';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeCustom => 'Custom';

  @override
  String get themeDarkFull => 'Dark Theme';

  @override
  String get themeLightFull => 'Light Theme';

  @override
  String get themeCustomFull => 'Custom Theme';

  @override
  String get accentColor => 'Accent Color';

  @override
  String get primaryAccentColor => 'Primary accent color';

  @override
  String get selectAccentColor => 'Select Accent Color';

  @override
  String get backgroundColor => 'Background Color';

  @override
  String get surfaceColor => 'Surface Color';

  @override
  String get textColor => 'Text Color';

  @override
  String get subtextColor => 'Subtext Color';

  @override
  String get borderColor => 'Border Color';

  @override
  String get fontSizeScale => 'Font Size Scale';

  @override
  String selectColor(String title) {
    return 'Select $title';
  }

  @override
  String get categoriesToSyncDialogTitle => 'Categories to synchronize';

  @override
  String get categoriesToSyncBody =>
      'Choose one or more categories. Leaving everything unchecked is valid.';

  @override
  String get syncCategorySectionMedia => 'Media';

  @override
  String get syncCategorySectionAudioDocs => 'Audio and documents';

  @override
  String get syncCategorySectionOther => 'Other';

  @override
  String get clearAll => 'Clear all';

  @override
  String get noSyncHasRunYet => 'No sync has run yet.';

  @override
  String lastRunAt(String date) {
    return 'Last run $date';
  }

  @override
  String syncResultSuccess(int uploaded, int skipped) {
    return 'Synced $uploaded, skipped $skipped.';
  }

  @override
  String get syncResultNoFiles => 'No files selected for sync.';

  @override
  String syncResultPartial(int uploaded, int failed) {
    return 'Synced $uploaded, failed $failed.';
  }

  @override
  String get syncResultAuthRequired => 'Sign in before syncing.';

  @override
  String get syncResultUnreachable => 'Server unreachable. Connection lost.';

  @override
  String get syncResultFailed => 'Sync failed.';

  @override
  String get serverSetupAddServer => 'Add server';

  @override
  String get serverSetupCardTitle => 'Connect Server';

  @override
  String get serverSetupCardSubtitle =>
      'Add your home file server and sign in.';

  @override
  String get serverSetupSubmitButton => 'Save Server';

  @override
  String get serverNameLabel => 'Server name';

  @override
  String get serverNameHint => 'Home NAS';

  @override
  String get baseUrlLabel => 'Base URL';

  @override
  String get baseUrlHint => 'https://cloud.example.com';

  @override
  String get allFieldsRequired => 'All fields are required.';

  @override
  String get localFilesTitle => 'Local Files';

  @override
  String get serverFilesTitle => 'Server Files';

  @override
  String get restoreItemsTitle => 'Restore items';

  @override
  String restoreItemsBody(int count) {
    return 'Are you sure you want to restore $count item(s)?';
  }

  @override
  String get permanentlyDeleteTitle => 'Permanently delete';

  @override
  String permanentlyDeleteBody(int count) {
    return 'Are you sure you want to permanently delete $count item(s)? This action cannot be undone.';
  }

  @override
  String get trashIsEmpty => 'Trash is empty.';

  @override
  String trashRetentionInfo(int days) {
    return 'Items in trash are automatically deleted after $days days.';
  }

  @override
  String get deletionDate => 'Deletion Date';

  @override
  String get deletePermanentlyAction => 'Delete Permanently';

  @override
  String get conflictFileAlreadyExists => 'File already exists';

  @override
  String conflictNofM(int current, int total) {
    return 'Conflict $current of $total';
  }

  @override
  String get conflictAFileNamed => 'A file named ';

  @override
  String get conflictAlreadyExistsAt => ' already exists at ';

  @override
  String get conflictAlreadyExistsInFolder => ' already exists in this folder.';

  @override
  String get conflictInFolder => 'In Folder';

  @override
  String get conflictFromTrash => 'From Trash';

  @override
  String get conflictExisting => 'Existing';

  @override
  String get conflictNewUpload => 'New Upload';

  @override
  String conflictSizeLabel(String size) {
    return 'Size: $size';
  }

  @override
  String conflictDateLabel(String date) {
    return 'Date: $date';
  }

  @override
  String conflictDeletedLabel(String date) {
    return 'Deleted: $date';
  }

  @override
  String conflictApplyToRemaining(int count) {
    return 'Apply to remaining $count conflict(s)';
  }

  @override
  String get conflictKeepAllCopies => 'Keep All Copies';

  @override
  String get conflictOverwriteAll => 'Overwrite All';

  @override
  String get conflictRestoreAllAsCopies => 'Restore All as Copies';

  @override
  String get conflictRestoreAsCopy => 'Restore as Copy';

  @override
  String get conflictOverwriteAllRemaining => 'Overwrite All Remaining';

  @override
  String get conflictSkipAll => 'Skip All';

  @override
  String get conflictSkipAllRemaining => 'Skip All Remaining';

  @override
  String get conflictSkip => 'Skip';

  @override
  String get conflictOverwrite => 'Overwrite';

  @override
  String get transfersTitle => 'Transfers';

  @override
  String get transferResume => 'Resume';

  @override
  String get transferPause => 'Pause';

  @override
  String get transferCancel => 'Cancel';

  @override
  String get transferResumeAll => 'Resume all';

  @override
  String get transferPauseAll => 'Pause all';

  @override
  String get transferCancelAll => 'Cancel all';

  @override
  String get transferCancelFile => 'Cancel file';

  @override
  String get noTransfers => 'No transfers.';

  @override
  String get transferStatusQueued => 'Queued';

  @override
  String get transferStatusRunning => 'Running';

  @override
  String get transferStatusPaused => 'Paused';

  @override
  String get transferStatusCompleted => 'Completed';

  @override
  String get transferStatusFailed => 'Failed';

  @override
  String get transferStatusCanceled => 'Canceled';

  @override
  String get themePresetsSection => 'Presets';

  @override
  String get themeCustomPaletteSection => 'Custom Palette';

  @override
  String get themeHexRgbLabel => 'HEX RGB Code';

  @override
  String get themeHexRgbHint => '#FA5252';

  @override
  String get imageViewerNoFetchHandler => 'No fetch handler configured';

  @override
  String get imageViewerFailedToLoad => 'Failed to load image';

  @override
  String errorDeletingFile(String filename, String error) {
    return 'Error deleting $filename: $error';
  }

  @override
  String errorReadingFile(String error) {
    return 'Error reading file: $error';
  }

  @override
  String get syncChannelName => 'Background Synchronization';

  @override
  String get syncChannelDescription =>
      'Shows status of files syncing in the background.';

  @override
  String get storageStatsTitle => 'Storage Statistics';

  @override
  String get storageStatsUsedSpace => 'Used Space';

  @override
  String get storageStatsTotalFiles => 'Total Files';

  @override
  String storageStatsNItems(int count) {
    return '$count items';
  }

  @override
  String userFallback(int userId) {
    return 'User #$userId';
  }

  @override
  String get biometricUnlockReason =>
      'Unlock saved credentials for Crowley\'s Cloud.';

  @override
  String get tokenLifetimeEveryOpen => 'Every app open';

  @override
  String get tokenLifetimeOneHour => 'After 1 hour';

  @override
  String get tokenLifetime1Hour => 'After 1 hour';

  @override
  String get tokenLifetimeOneDay => 'After 1 day';

  @override
  String get tokenLifetime1Day => 'After 1 day';

  @override
  String get tokenLifetimeOneWeek => 'After 1 week';

  @override
  String get tokenLifetime1Week => 'After 1 week';

  @override
  String get tokenLifetimeOneMonth => 'After 1 month';

  @override
  String get tokenLifetime1Month => 'After 1 month';

  @override
  String get tokenLifetimeThreeMonths => 'After 3 months';

  @override
  String get tokenLifetime3Months => 'After 3 months';

  @override
  String get tokenLifetimeNever => 'Never on this device';

  @override
  String get cacheLimitUnlimited => 'Unlimited';

  @override
  String get syncCategoryOtherFiles => 'Other files';

  @override
  String get internalStorage => 'Internal Storage';

  @override
  String get localStorageRootName => 'Internal Storage';

  @override
  String syncNotificationSyncingWith(String serverName) {
    return 'Syncing with $serverName';
  }

  @override
  String syncNotificationPausedTitle(String serverName) {
    return 'Sync with $serverName paused';
  }

  @override
  String get syncNotificationUnreachableBody =>
      'Server is unreachable. Background sync paused until app is opened.';

  @override
  String get syncNotificationAuthRequiredBody =>
      'Authentication required. Open app to log in.';

  @override
  String syncNotificationFailedTitle(String serverName) {
    return 'Sync with $serverName failed';
  }

  @override
  String get syncNotificationGenericErrorBody =>
      'An error occurred during synchronization.';

  @override
  String syncNotificationCompleteTitle(String serverName) {
    return 'Sync with $serverName complete';
  }

  @override
  String get syncNotificationCompleteBody => 'Sync complete.';

  @override
  String get syncStatusConnecting => 'Connecting to server...';

  @override
  String syncStatusConnectionLost(String serverName) {
    return 'Could not connect to $serverName. Connection lost.';
  }

  @override
  String syncResultServerUnreachableWithServer(String serverName) {
    return 'Could not connect to $serverName. Connection lost.';
  }

  @override
  String get syncStatusScanningFiles => 'Scanning files on device...';

  @override
  String get syncStatusNoFilesFound => 'No files found to synchronize.';

  @override
  String get syncStatusNoFilesSelected =>
      'No files selected for synchronization.';

  @override
  String syncStatusCalculatingChecksum(
    int current,
    int total,
    String filename,
  ) {
    return 'Calculating checksum ($current/$total): $filename';
  }

  @override
  String get syncStatusCheckingDuplicates =>
      'Checking for duplicates on server...';

  @override
  String syncStatusSyncingFile(int current, int total, String filename) {
    return 'Syncing ($current/$total): $filename';
  }

  @override
  String get syncStatusCompleting => 'Completing synchronization...';

  @override
  String get showingCachedFiles => 'Showing cached files.';

  @override
  String get showingCachedFilesRefreshFailed =>
      'Showing cached files. Refresh failed.';

  @override
  String get downloadCanceled => 'Download canceled.';

  @override
  String downloadedNFilesToPath(int count, String path) {
    return 'Downloaded $count file(s) to $path';
  }

  @override
  String downloadedNFilesFailedM(int downloaded, int failed, String detail) {
    return 'Downloaded $downloaded file(s), failed $failed: $detail';
  }

  @override
  String downloadedNFilesWithFailures(int count, int failed, String error) {
    return 'Downloaded $count file(s), failed $failed: $error';
  }

  @override
  String createdNShareLinks(int count) {
    return 'Created $count share link(s).';
  }

  @override
  String get failedToCreateShareLinks => 'Failed to create share link(s).';

  @override
  String get alreadyInSharedScope => 'Already in shared scope.';

  @override
  String sharedNItemsInServer(int count) {
    return 'Shared $count item(s) in server.';
  }

  @override
  String sharedNItemsWithFailures(int count, int failed) {
    return 'Shared $count item(s), failed $failed.';
  }

  @override
  String sharedNItemsFailedM(int shared, int failed) {
    return 'Shared $shared item(s), failed $failed.';
  }

  @override
  String get folderNameCannotBeEmpty => 'Folder name cannot be empty.';

  @override
  String get folderAlreadyExists => 'Folder already exists.';

  @override
  String get folderCreationOnlyInAllFiles =>
      'Folder creation is only available in All files.';

  @override
  String get currentDirectoryUnavailable => 'Current directory is unavailable.';

  @override
  String get nothingSelected => 'Nothing selected.';

  @override
  String get destinationFolderDoesNotExist =>
      'Destination folder does not exist.';

  @override
  String cannotMoveFolderIntoItself(String name) {
    return 'Cannot move folder \"$name\" into itself.';
  }

  @override
  String failedToMoveItem(String name, String error) {
    return 'Failed to move $name: $error';
  }

  @override
  String movedNItems(int count) {
    return 'Moved $count item(s).';
  }

  @override
  String movedNItemsWithFailures(int count, int failed) {
    return 'Moved $count item(s), failed $failed.';
  }

  @override
  String movedNItemsFailedM(int moved, int failed) {
    return 'Moved $moved item(s), failed $failed.';
  }

  @override
  String get failedToMoveSelectedItems => 'Failed to move selected items.';

  @override
  String get noFilesWereMoved => 'No files were moved.';

  @override
  String renamedOldToNew(String oldName, String newName) {
    return 'Renamed \"$oldName\" to \"$newName\".';
  }

  @override
  String renamedFileFromTo(String oldName, String newName) {
    return 'Renamed \"$oldName\" to \"$newName\".';
  }

  @override
  String failedToRenameWithStatus(String name, int statusCode) {
    return 'Failed to rename \"$name\" ($statusCode).';
  }

  @override
  String failedToRenameFileWithCode(String name, int statusCode) {
    return 'Failed to rename \"$name\" ($statusCode).';
  }

  @override
  String failedToRenameWithError(String name, String error) {
    return 'Failed to rename \"$name\": $error';
  }

  @override
  String failedToRenameFile(String name, String error) {
    return 'Failed to rename \"$name\": $error';
  }

  @override
  String get renameConflictAlreadyExists =>
      'Failed to rename: A file or folder with that name already exists.';

  @override
  String get renameFailedAlreadyExists =>
      'Failed to rename: A file or folder with that name already exists.';

  @override
  String failedToCreateFolderWithCode(int statusCode) {
    return 'Failed to create folder ($statusCode).';
  }

  @override
  String deletedNItemsFailedM(int deleted, int failed) {
    return 'Deleted $deleted item(s), failed $failed.';
  }

  @override
  String transferSummaryFiles(int percent, int completed, int total) {
    return '$percent%  $completed/$total files';
  }

  @override
  String transferSummaryProgress(int percent, int completed, int total) {
    return '$percent%  $completed/$total files';
  }

  @override
  String get downloadFailedGeneric => 'Download failed';

  @override
  String uploadedNItemsWithFailures(int uploaded, int failed) {
    return 'Uploaded $uploaded item(s), failed $failed';
  }

  @override
  String uploadedNItemsFailedM(int uploaded, int failed) {
    return 'Uploaded $uploaded item(s), failed $failed.';
  }

  @override
  String uploadSummaryFailedCount(int count) {
    return ', failed $count';
  }

  @override
  String uploadLocalPathEmpty(String name) {
    return '$name: local path is empty';
  }

  @override
  String uploadErrorLocalPathEmpty(String name) {
    return '$name: local path is empty';
  }

  @override
  String get directoryUploadFailed => 'Directory upload failed';

  @override
  String get uploadDirectoryFailed => 'Directory upload failed';

  @override
  String get localFileNotFound => 'Local file not found';

  @override
  String get uploadErrorLocalFileNotFound => 'Local file not found';

  @override
  String get noSessionToken => 'No active session token';

  @override
  String get uploadErrorNoSessionToken => 'No active session token';

  @override
  String get serverDisconnectedStatus => 'Server disconnected';

  @override
  String get serverDisconnected => 'Server disconnected';

  @override
  String get serverIsUnreachable => 'Server is unreachable.';

  @override
  String get serverUnreachable => 'Server is unreachable.';

  @override
  String get uploadErrorLocalDirectoryNotFound => 'Local directory not found';

  @override
  String get uploadErrorFailedToScanDirectory => 'Failed to scan directory';

  @override
  String uploadErrorFolderCreateHttp(int statusCode) {
    return 'Folder creation failed (HTTP $statusCode)';
  }

  @override
  String get authErrorMissingAccessToken => 'Missing access token in response';

  @override
  String get authErrorMissingRefreshToken =>
      'Missing refresh token in response';

  @override
  String get authErrorNoSavedCredentials => 'No saved credentials available';

  @override
  String get authErrorNoRefreshToken => 'No refresh token available';

  @override
  String get authErrorNoActiveSession => 'No active session available';

  @override
  String get authErrorNoSavedUsername => 'No saved username available';

  @override
  String get updateNoReleasesPublished => 'No releases published yet.';

  @override
  String get language => 'Language';
}
