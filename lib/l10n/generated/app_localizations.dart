import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_cs.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bn'),
    Locale('cs'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fa'),
    Locale('fr'),
    Locale('hi'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('pl'),
    Locale('pt'),
    Locale('pt', 'BR'),
    Locale('ru'),
    Locale('tr'),
    Locale('uk'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ];

  /// The application name shown in the title bar and AppBar
  ///
  /// In en, this message translates to:
  /// **'Crowley\'s Cloud'**
  String get appTitle;

  /// Generic OK button label
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Generic Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Generic Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Generic Rename button label
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// Generic Close button label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Generic Retry button label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Generic loading placeholder
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Generic Confirm button label
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Generic error label
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Error message with detail
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(String message);

  /// Fallback when a value is unknown
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Upload action label
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// Download action label
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// Share action label
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Copy action label
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Move action label
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// Restore action label
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// Apply button label
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// Create button label
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Clear button label
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Add button label
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Remove button label
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Edit button label
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Switch action button label
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switchLabel;

  /// Search label
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Name sort / column option
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Date sort / column option
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// Size sort / column option
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// Type sort / column option
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// Sort direction ascending
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// Sort direction descending
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// Category filter: all files
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFiles;

  /// Category: images
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get categoryImages;

  /// Category: photos (gallery)
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get categoryPhotos;

  /// Category: videos
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get categoryVideos;

  /// Category: audio files
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get categoryAudio;

  /// Category: documents
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get categoryDocuments;

  /// Category: archives/zip files
  ///
  /// In en, this message translates to:
  /// **'Archives'**
  String get categoryArchives;

  /// Category: shared files
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get categoryShared;

  /// Category: other files
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// Category option: other files (long form)
  ///
  /// In en, this message translates to:
  /// **'Other files'**
  String get categoryOtherFiles;

  /// Empty state when no files exist
  ///
  /// In en, this message translates to:
  /// **'No files found.'**
  String get noFilesFound;

  /// Empty state: folder is empty
  ///
  /// In en, this message translates to:
  /// **'No files in this folder.'**
  String get noFilesInFolder;

  /// Warning that an action is irreversible
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get thisActionCannotBeUndone;

  /// Validation error when passwords don't match
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// Bottom nav label for local file browser
  ///
  /// In en, this message translates to:
  /// **'Local Files'**
  String get navLocalFiles;

  /// Bottom nav label for server file browser
  ///
  /// In en, this message translates to:
  /// **'Server Files'**
  String get navServerFiles;

  /// Bottom nav label for settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Drawer nav label for trash screen
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get navTrash;

  /// Drawer nav label for local browser
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get navLocal;

  /// Drawer nav label for server browser
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get navServer;

  /// Button label to add a new server
  ///
  /// In en, this message translates to:
  /// **'Add Server'**
  String get addServer;

  /// Empty state when no servers are added
  ///
  /// In en, this message translates to:
  /// **'No servers configured.'**
  String get noServersConfigured;

  /// Hint below no-servers message
  ///
  /// In en, this message translates to:
  /// **'Add a server in Settings.'**
  String get addAServerInSettings;

  /// Setup screen hint
  ///
  /// In en, this message translates to:
  /// **'Add your first server to continue.'**
  String get addFirstServerHint;

  /// Setup screen title when no servers
  ///
  /// In en, this message translates to:
  /// **'No servers configured yet.'**
  String get noServersConfiguredYet;

  /// AppBar title on setup screen
  ///
  /// In en, this message translates to:
  /// **'Crowley\'s Cloud setup'**
  String get crowleysCloudSetup;

  /// Connect button label
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// Loading state on connect button
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// Server connection status label
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// Server disconnected status label
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// Button to switch to another server
  ///
  /// In en, this message translates to:
  /// **'Switch Server'**
  String get switchServer;

  /// Button to pick another server from list
  ///
  /// In en, this message translates to:
  /// **'Choose other server'**
  String get chooseOtherServer;

  /// Confirm dialog title for switching server
  ///
  /// In en, this message translates to:
  /// **'Switch server?'**
  String get switchServerTitle;

  /// Confirm dialog body for switching server
  ///
  /// In en, this message translates to:
  /// **'Switch active server to \"{serverName}\"?'**
  String switchServerBody(String serverName);

  /// Dialog title for server picker
  ///
  /// In en, this message translates to:
  /// **'Choose server'**
  String get chooseServer;

  /// Screen title when sign-in is needed
  ///
  /// In en, this message translates to:
  /// **'Authentication required'**
  String get authenticationRequired;

  /// Auth screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in to access files on {serverName}'**
  String signInToAccess(String serverName);

  /// Button to open password sign-in
  ///
  /// In en, this message translates to:
  /// **'Sign In with Password'**
  String get signInWithPassword;

  /// Button to use biometric authentication
  ///
  /// In en, this message translates to:
  /// **'Use Biometrics'**
  String get useBiometrics;

  /// Status while launching sign-in
  ///
  /// In en, this message translates to:
  /// **'Opening sign in...'**
  String get openingSignIn;

  /// Error screen title
  ///
  /// In en, this message translates to:
  /// **'Server connection failed'**
  String get serverConnectionFailed;

  /// Generic connection error message
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to the active server.'**
  String get unableToConnectToServer;

  /// Connection error with server name
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to {serverName}.'**
  String unableToConnectTo(String serverName);

  /// Generic search field hint
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// File search field hint
  ///
  /// In en, this message translates to:
  /// **'Search files...'**
  String get searchFilesHint;

  /// Server file search field hint
  ///
  /// In en, this message translates to:
  /// **'Search server files...'**
  String get searchServerFilesHint;

  /// Trash search field hint
  ///
  /// In en, this message translates to:
  /// **'Search trash...'**
  String get searchTrashHint;

  /// Permission prompt title
  ///
  /// In en, this message translates to:
  /// **'Storage permission required'**
  String get storagePermissionRequired;

  /// Button to open permission dialog
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// Storage permission denied message
  ///
  /// In en, this message translates to:
  /// **'Permission denied. Please grant storage access in Settings.'**
  String get permissionDeniedOpenSettings;

  /// Manage storage permission prompt
  ///
  /// In en, this message translates to:
  /// **'Manage Storage permission is required to browse and select folders.'**
  String get manageStoragePermissionRequired;

  /// Sync storage permission prompt
  ///
  /// In en, this message translates to:
  /// **'Storage permissions are required to perform synchronization.'**
  String get storagePermissionsRequired;

  /// Update banner title
  ///
  /// In en, this message translates to:
  /// **'Update available: v{version}'**
  String updateAvailableTitle(String version);

  /// Update banner subtitle
  ///
  /// In en, this message translates to:
  /// **'Tap to see what\'s new'**
  String get updateAvailableTapToSeeNew;

  /// Update banner action button
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get updateView;

  /// Update dialog title
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailableDialogTitle;

  /// Fallback subtitle showing version number
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String updateVersionSubtitle(String version);

  /// Update dialog current version label
  ///
  /// In en, this message translates to:
  /// **'Current: v{version}'**
  String updateCurrentVersion(String version);

  /// Update dialog new version label
  ///
  /// In en, this message translates to:
  /// **'New: v{version}'**
  String updateNewVersion(String version);

  /// Update dialog section header
  ///
  /// In en, this message translates to:
  /// **'What\'s New:'**
  String get updateWhatsNew;

  /// Link label to GitHub release page
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get updateGitHub;

  /// Fallback when no release notes available
  ///
  /// In en, this message translates to:
  /// **'No release notes provided.'**
  String get updateNoReleaseNotes;

  /// Dismiss update dialog button
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// Download APK button in update dialog
  ///
  /// In en, this message translates to:
  /// **'Download APK'**
  String get updateDownloadApk;

  /// Open update page button in update dialog
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateInstall;

  /// Share link dialog title and action tile
  ///
  /// In en, this message translates to:
  /// **'Share Link'**
  String get shareLinkTitle;

  /// Context menu action: share via link
  ///
  /// In en, this message translates to:
  /// **'Share via link'**
  String get shareViaLink;

  /// Context menu action: share in server
  ///
  /// In en, this message translates to:
  /// **'Share in server'**
  String get shareInServer;

  /// Expiry label in share link dialog
  ///
  /// In en, this message translates to:
  /// **'Expiry (days)'**
  String get expiryDays;

  /// Token never expires option
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get expiryNever;

  /// Token expires in 1 day
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get expiry1Day;

  /// Token expires in 7 days
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get expiry7Days;

  /// Token expires in 30 days
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get expiry30Days;

  /// Token expires in 90 days
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get expiry90Days;

  /// Token expires in 180 days
  ///
  /// In en, this message translates to:
  /// **'180 days'**
  String get expiry180Days;

  /// Token expires in 365 days
  ///
  /// In en, this message translates to:
  /// **'365 days'**
  String get expiry365Days;

  /// Create share link button label
  ///
  /// In en, this message translates to:
  /// **'Create Link'**
  String get createLink;

  /// Snackbar when share link is copied
  ///
  /// In en, this message translates to:
  /// **'Shared link copied to clipboard!'**
  String get sharedLinkCopied;

  /// Snackbar when share link copy fails
  ///
  /// In en, this message translates to:
  /// **'Failed to copy shared link: {error}'**
  String failedToCopySharedLink(String error);

  /// Snackbar for unsupported share type
  ///
  /// In en, this message translates to:
  /// **'Cannot share this type of file.'**
  String get cannotShareThisFileType;

  /// Snackbar when share creation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create share: {error}'**
  String failedToCreateShare(String error);

  /// Create folder dialog title
  ///
  /// In en, this message translates to:
  /// **'Create Folder'**
  String get newFolderTitle;

  /// Create folder dialog hint text
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get newFolderHint;

  /// New folder button label
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get newFolder;

  /// Snackbar on folder creation success
  ///
  /// In en, this message translates to:
  /// **'Folder created.'**
  String get folderCreated;

  /// Snackbar when folder creation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create folder: {error}'**
  String failedToCreateFolder(String error);

  /// Snackbar while folder is being created
  ///
  /// In en, this message translates to:
  /// **'Creating folder...'**
  String get creatingFolder;

  /// Rename dialog title
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameDialogTitle;

  /// Rename text field hint
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get renameHint;

  /// Rename text field hint (file browser)
  ///
  /// In en, this message translates to:
  /// **'Enter new name'**
  String get enterNewName;

  /// Snackbar on rename success
  ///
  /// In en, this message translates to:
  /// **'Renamed successfully.'**
  String get renamedSuccessfully;

  /// Snackbar on rename failure
  ///
  /// In en, this message translates to:
  /// **'Rename failed: {error}'**
  String renameFailed(String error);

  /// Move dialog title prefix
  ///
  /// In en, this message translates to:
  /// **'Move to'**
  String get moveDialogTitle;

  /// Move dialog title with path
  ///
  /// In en, this message translates to:
  /// **'Move to: {path}'**
  String moveTo(String path);

  /// Move to current folder button
  ///
  /// In en, this message translates to:
  /// **'Move Here'**
  String get moveHere;

  /// Snackbar on move failure
  ///
  /// In en, this message translates to:
  /// **'Move failed: {error}'**
  String moveFailed(String error);

  /// Snackbar on successful move
  ///
  /// In en, this message translates to:
  /// **'Moved to folder.'**
  String get movedToFolder;

  /// Snackbar on copy failure
  ///
  /// In en, this message translates to:
  /// **'Copy failed: {error}'**
  String copyFailed(String error);

  /// Folder picker AppBar title
  ///
  /// In en, this message translates to:
  /// **'Select Folder'**
  String get selectFolder;

  /// FAB label to confirm folder selection
  ///
  /// In en, this message translates to:
  /// **'Use this folder'**
  String get useThisFolder;

  /// Root label in local file breadcrumb
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storageRoot;

  /// Root label in server file breadcrumb
  ///
  /// In en, this message translates to:
  /// **'root'**
  String get serverRoot;

  /// Bulk delete dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete {count} items?'**
  String deleteNItemsTitle(int count);

  /// Delete files confirm dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Files?'**
  String get deleteFilesTitle;

  /// Delete files confirm dialog body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} selected items? This action cannot be undone.'**
  String deleteFilesBody(int count);

  /// Permanent delete action/button label
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deletePermanently;

  /// Permanent delete confirm dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently?'**
  String get deletePermanentlyTitle;

  /// Permanent delete confirm dialog body
  ///
  /// In en, this message translates to:
  /// **'{filename} will be permanently deleted.'**
  String deletePermanentlyBody(String filename);

  /// Single file delete confirm dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete File?'**
  String get deleteFileTitle;

  /// Single file delete confirm dialog body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {filename}? This action cannot be undone.'**
  String deleteFileBody(String filename);

  /// Server permanent delete confirm dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deleteServerFileTitle;

  /// Server permanent delete confirm dialog body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete \"{filename}\"? This action cannot be undone.'**
  String deleteServerFileBody(String filename);

  /// Unshare confirm dialog title
  ///
  /// In en, this message translates to:
  /// **'Unshare Items?'**
  String get unshareItemsTitle;

  /// Unshare confirm dialog body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unshare {count} selected items? This will remove them from the Shared folder.'**
  String unshareItemsBody(int count);

  /// Unshare button label
  ///
  /// In en, this message translates to:
  /// **'Unshare'**
  String get unshare;

  /// Move to trash action label
  ///
  /// In en, this message translates to:
  /// **'Move to Trash'**
  String get moveToTrash;

  /// Snackbar on single item moved to trash
  ///
  /// In en, this message translates to:
  /// **'Moved to trash.'**
  String get movedToTrash;

  /// Snackbar on multiple items moved to trash
  ///
  /// In en, this message translates to:
  /// **'Moved {count} items to trash.'**
  String movedNItemsToTrash(int count);

  /// Snackbar on move-to-trash failure
  ///
  /// In en, this message translates to:
  /// **'Failed to move to trash: {error}'**
  String failedToMoveToTrash(String error);

  /// Snackbar on bulk delete success
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} items.'**
  String deletedNItems(int count);

  /// Snackbar on delete failure
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: {error}'**
  String failedToDelete(String error);

  /// Snackbar on server delete failure
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String failedToDeleteItem(String error);

  /// Snackbar on single file delete success
  ///
  /// In en, this message translates to:
  /// **'Deleted {filename}.'**
  String deletedFilename(String filename);

  /// Snackbar when file can't be opened
  ///
  /// In en, this message translates to:
  /// **'Failed to open file'**
  String get failedToOpenFile;

  /// Snackbar on file download failure
  ///
  /// In en, this message translates to:
  /// **'File download failed: {error}'**
  String fileDownloadFailed(String error);

  /// Snackbar while downloading
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get downloading;

  /// Loading text while downloading a file for preview
  ///
  /// In en, this message translates to:
  /// **'Downloading file...'**
  String get downloadingFile;

  /// Snackbar on download success
  ///
  /// In en, this message translates to:
  /// **'Download complete: {filename}'**
  String downloadComplete(String filename);

  /// Snackbar on download failure
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String downloadFailed(String error);

  /// Snackbar when preview download fails
  ///
  /// In en, this message translates to:
  /// **'Failed to download file preview'**
  String get failedToDownloadPreview;

  /// Snackbar on upload success
  ///
  /// In en, this message translates to:
  /// **'Upload complete: {filename}'**
  String uploadComplete(String filename);

  /// Snackbar on upload failure
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String uploadFailed(String error);

  /// Snackbar when file picker fails
  ///
  /// In en, this message translates to:
  /// **'Failed to pick files'**
  String get failedToPickFiles;

  /// Snackbar on batch upload success
  ///
  /// In en, this message translates to:
  /// **'Uploaded {count} item(s)'**
  String uploadedNItems(int count);

  /// Snackbar on link copy
  ///
  /// In en, this message translates to:
  /// **'Copied link to clipboard.'**
  String get copiedLinkToClipboard;

  /// Snackbar on link copy failure
  ///
  /// In en, this message translates to:
  /// **'Failed to copy link: {error}'**
  String failedToCopyLink(String error);

  /// Snackbar while selecting all items
  ///
  /// In en, this message translates to:
  /// **'Selecting all...'**
  String get selectingAll;

  /// Snackbar when all items are selected
  ///
  /// In en, this message translates to:
  /// **'All items selected.'**
  String get allItemsSelected;

  /// Snackbar on search failure
  ///
  /// In en, this message translates to:
  /// **'Failed to load search results'**
  String get failedToLoadSearchResults;

  /// Snackbar for unsupported share
  ///
  /// In en, this message translates to:
  /// **'Share not supported for this file type.'**
  String get shareNotSupportedForType;

  /// Selection header: N items selected
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String nSelected(int count);

  /// Snackbar when no server is active
  ///
  /// In en, this message translates to:
  /// **'No server selected'**
  String get noServerSelected;

  /// Snackbar prompt to connect
  ///
  /// In en, this message translates to:
  /// **'Please connect to a server first.'**
  String get pleaseConnectToServerFirst;

  /// Snackbar when sign-in is needed
  ///
  /// In en, this message translates to:
  /// **'Sign in required'**
  String get signInRequired;

  /// Snackbar prompting to sign in
  ///
  /// In en, this message translates to:
  /// **'Please sign in to {serverName} first.'**
  String pleaseSignInToServer(String serverName);

  /// Snackbar while connecting
  ///
  /// In en, this message translates to:
  /// **'Connecting to server...'**
  String get connectingToServer;

  /// Snackbar on successful connection
  ///
  /// In en, this message translates to:
  /// **'Connected to {serverName}.'**
  String connectedToServer(String serverName);

  /// Snackbar on connection failure
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String connectionFailed(String error);

  /// Snackbar on connect failure (alt)
  ///
  /// In en, this message translates to:
  /// **'Failed to connect: {error}'**
  String failedToConnect(String error);

  /// Snackbar on authentication failure
  ///
  /// In en, this message translates to:
  /// **'Authentication failed: {error}'**
  String authFailed(String error);

  /// Generic auth failure snackbar
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again.'**
  String get authFailedGeneric;

  /// Snackbar on biometric login failure
  ///
  /// In en, this message translates to:
  /// **'Biometric login failed: {error}'**
  String biometricLoginFailed(String error);

  /// Generic biometric failure snackbar
  ///
  /// In en, this message translates to:
  /// **'Biometric login failed.'**
  String get biometricLoginFailedGeneric;

  /// Snackbar when session token is missing
  ///
  /// In en, this message translates to:
  /// **'No server session token. Re-authenticate server.'**
  String get noServerSessionToken;

  /// Snackbar on server save failure
  ///
  /// In en, this message translates to:
  /// **'Failed to save server: {error}'**
  String failedToSaveServer(String error);

  /// Context menu action: add to folder
  ///
  /// In en, this message translates to:
  /// **'Add to folder'**
  String get addToFolder;

  /// Auth tab: log in
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginTabLabel;

  /// Auth tab: register
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerTabLabel;

  /// Auth login card title
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// Auth login card subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// Auth register card title
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Auth register card subtitle
  ///
  /// In en, this message translates to:
  /// **'Join the server'**
  String get joinTheServer;

  /// Username text field label
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// Username text field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get usernameHint;

  /// Password text field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Password text field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// Tooltip for show password button
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// Tooltip for hide password button
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Login button label
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// Login loading state
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get loggingIn;

  /// Register loading state
  ///
  /// In en, this message translates to:
  /// **'Registering...'**
  String get registering;

  /// Forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// Auth footer for login mode
  ///
  /// In en, this message translates to:
  /// **'Do not have an account? Switch to Register.'**
  String get doNotHaveAccount;

  /// Auth footer for register mode
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Switch to Log In.'**
  String get alreadyHaveAccount;

  /// Validation: empty username
  ///
  /// In en, this message translates to:
  /// **'Username cannot be empty.'**
  String get usernameCannotBeEmpty;

  /// Validation: empty password
  ///
  /// In en, this message translates to:
  /// **'Password cannot be empty.'**
  String get passwordCannotBeEmpty;

  /// Validation: invalid username format
  ///
  /// In en, this message translates to:
  /// **'Username must be 3–32 chars, letters, numbers, _ or -.'**
  String get usernameInvalid;

  /// Validation: password too short
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get passwordTooShort;

  /// Snackbar on login failure
  ///
  /// In en, this message translates to:
  /// **'Login failed: {error}'**
  String loginFailed(String error);

  /// Snackbar on registration failure
  ///
  /// In en, this message translates to:
  /// **'Registration failed: {error}'**
  String registrationFailed(String error);

  /// Forgot password dialog title step 1
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// Forgot password dialog title step 2
  ///
  /// In en, this message translates to:
  /// **'Enter Reset Code'**
  String get enterResetCodeTitle;

  /// Forgot password step 1 instruction
  ///
  /// In en, this message translates to:
  /// **'Enter your username. The 6-digit verification code will be printed to the server logs/console.'**
  String get resetPasswordStep1Body;

  /// Forgot password step 2 instruction
  ///
  /// In en, this message translates to:
  /// **'Verification code has been printed to the server console. Enter the 6-digit code and your new password.'**
  String get resetPasswordStep2Body;

  /// Reset code field label
  ///
  /// In en, this message translates to:
  /// **'Reset Code'**
  String get resetCodeLabel;

  /// Reset code field hint
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit code'**
  String get resetCodeHint;

  /// New password field label
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordLabel;

  /// New password field hint
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get newPasswordHint;

  /// Snackbar on password reset success
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully!'**
  String get passwordResetSuccessfully;

  /// Validation: username required for reset
  ///
  /// In en, this message translates to:
  /// **'Username is required.'**
  String get usernameIsRequired;

  /// Validation: code and password required
  ///
  /// In en, this message translates to:
  /// **'Code and new password are required.'**
  String get codeAndPasswordRequired;

  /// Snackbar on reset request failure
  ///
  /// In en, this message translates to:
  /// **'Failed to request reset. Verify the server URL.'**
  String get failedToRequestReset;

  /// Snackbar on reset failure
  ///
  /// In en, this message translates to:
  /// **'Failed to reset password. Please check the code.'**
  String get failedToResetPassword;

  /// Snackbar when server URL is missing
  ///
  /// In en, this message translates to:
  /// **'Please enter a server URL first.'**
  String get pleaseEnterServerUrlFirst;

  /// Send reset code button label
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// Settings screen AppBar title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings section header: backup & sync
  ///
  /// In en, this message translates to:
  /// **'Backup & Sync'**
  String get sectionBackupSync;

  /// Settings section header: storage & cache
  ///
  /// In en, this message translates to:
  /// **'Storage & Cache'**
  String get sectionStorageCache;

  /// Settings section header: security & behavior
  ///
  /// In en, this message translates to:
  /// **'Security & Behavior'**
  String get sectionSecurityBehavior;

  /// Settings section header: about & updates
  ///
  /// In en, this message translates to:
  /// **'About & Updates'**
  String get sectionAboutUpdates;

  /// Settings section header: appearance
  ///
  /// In en, this message translates to:
  /// **'Appearance & Customization'**
  String get sectionAppearance;

  /// Sync section tile title when no servers
  ///
  /// In en, this message translates to:
  /// **'No servers configured'**
  String get noServersConfiguredSync;

  /// Sync section hint when no servers
  ///
  /// In en, this message translates to:
  /// **'Add a server before configuring sync.'**
  String get addServerBeforeSync;

  /// Sync section instruction
  ///
  /// In en, this message translates to:
  /// **'Select a server to configure its sync settings.'**
  String get selectServerToConfigureSync;

  /// Suffix label for active server in list
  ///
  /// In en, this message translates to:
  /// **'· active'**
  String get activeServerSuffix;

  /// Sync toggle title
  ///
  /// In en, this message translates to:
  /// **'Folder and category sync'**
  String get folderAndCategorySync;

  /// Sync toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Keep selected local categories or folders synced with this server.'**
  String get keepCategoriesSynced;

  /// Sync toggle disabled subtitle
  ///
  /// In en, this message translates to:
  /// **'Add a server before enabling synchronization.'**
  String get addServerBeforeSyncEnable;

  /// Sync preference: only on Wi-Fi
  ///
  /// In en, this message translates to:
  /// **'Only on Wi-Fi'**
  String get onlyOnWifi;

  /// Sync preference: only while charging
  ///
  /// In en, this message translates to:
  /// **'Only while charging'**
  String get onlyWhileCharging;

  /// Sync target directory setting title
  ///
  /// In en, this message translates to:
  /// **'Server target directory'**
  String get serverTargetDirectory;

  /// Hint text for server target directory
  ///
  /// In en, this message translates to:
  /// **'/backup/mobile_phone'**
  String get serverTargetDirectoryHint;

  /// Sync frequency setting title
  ///
  /// In en, this message translates to:
  /// **'Synchronization frequency'**
  String get synchronizationFrequency;

  /// Manual sync button label
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// Loading state for sync button
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// Sync categories tile title
  ///
  /// In en, this message translates to:
  /// **'Categories to synchronize'**
  String get categoriesToSynchronize;

  /// Sync categories empty state
  ///
  /// In en, this message translates to:
  /// **'No categories selected.'**
  String get noCategoriesSelected;

  /// N categories selected label
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String nCategoriesSelected(int count);

  /// Sync folders tile title
  ///
  /// In en, this message translates to:
  /// **'Folders to synchronize'**
  String get foldersToSynchronize;

  /// Sync folders empty state
  ///
  /// In en, this message translates to:
  /// **'No custom folders configured.'**
  String get noCustomFolders;

  /// N folders selected label
  ///
  /// In en, this message translates to:
  /// **'{count} folder(s)'**
  String nFolders(int count);

  /// Tooltip for add folder button
  ///
  /// In en, this message translates to:
  /// **'Add folder'**
  String get addFolder;

  /// Tooltip for remove folder button
  ///
  /// In en, this message translates to:
  /// **'Remove folder'**
  String get removeFolder;

  /// Tooltip for remove server button
  ///
  /// In en, this message translates to:
  /// **'Remove server'**
  String get removeServer;

  /// Sync frequency option: every 15 min
  ///
  /// In en, this message translates to:
  /// **'Every 15 minutes'**
  String get syncFreqEvery15Min;

  /// Sync frequency option: every 30 min
  ///
  /// In en, this message translates to:
  /// **'Every 30 minutes'**
  String get syncFreqEvery30Min;

  /// Sync frequency option: every hour
  ///
  /// In en, this message translates to:
  /// **'Every hour'**
  String get syncFreqEvery1Hour;

  /// Sync frequency: every N hours
  ///
  /// In en, this message translates to:
  /// **'Every {hours} hours'**
  String syncFreqEveryNHours(int hours);

  /// Sync frequency: every N minutes
  ///
  /// In en, this message translates to:
  /// **'Every {minutes} minutes'**
  String syncFreqEveryNMin(int minutes);

  /// Sync frequency option: daily
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get syncFreqDaily;

  /// Sync frequency picker dialog title
  ///
  /// In en, this message translates to:
  /// **'Choose Sync Frequency'**
  String get chooseSyncFrequencyTitle;

  /// Cache size setting tile title
  ///
  /// In en, this message translates to:
  /// **'Cache size'**
  String get cacheSize;

  /// Tooltip for refresh button
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTooltip;

  /// Cache limit dropdown label
  ///
  /// In en, this message translates to:
  /// **'Cache limit'**
  String get cacheLimit;

  /// Download path setting title
  ///
  /// In en, this message translates to:
  /// **'Download path'**
  String get downloadPath;

  /// Fallback label for default download folder
  ///
  /// In en, this message translates to:
  /// **'Default CrowleysCloud folder'**
  String get defaultDownloadFolder;

  /// Clear cache button label
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get clearCache;

  /// Clear cache confirm dialog title
  ///
  /// In en, this message translates to:
  /// **'Clear cache?'**
  String get clearCacheTitle;

  /// Clear cache confirm dialog body
  ///
  /// In en, this message translates to:
  /// **'This removes local thumbnails and cached server listings.'**
  String get clearCacheBody;

  /// Download path dialog title
  ///
  /// In en, this message translates to:
  /// **'Download path'**
  String get downloadPathDialogTitle;

  /// Download path hint text
  ///
  /// In en, this message translates to:
  /// **'/storage/emulated/0/CrowleysCloud'**
  String get downloadPathHint;

  /// Use default path button in download path dialog
  ///
  /// In en, this message translates to:
  /// **'Use default'**
  String get useDefault;

  /// Server target directory dialog title
  ///
  /// In en, this message translates to:
  /// **'Server target directory'**
  String get serverTargetDirDialogTitle;

  /// Require login dropdown label
  ///
  /// In en, this message translates to:
  /// **'Require login'**
  String get requireLogin;

  /// Biometric login toggle title
  ///
  /// In en, this message translates to:
  /// **'Biometric login'**
  String get biometricLogin;

  /// Biometric login toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Allow saved-credential login with biometrics.'**
  String get biometricLoginSubtitle;

  /// Subtitle when biometrics unavailable
  ///
  /// In en, this message translates to:
  /// **'Biometrics are not available on this device.'**
  String get biometricsNotAvailable;

  /// Show hidden files toggle title
  ///
  /// In en, this message translates to:
  /// **'Show hidden files'**
  String get showHiddenFiles;

  /// Show hidden files toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Display dot-files and dot-folders.'**
  String get showHiddenFilesSubtitle;

  /// Change password tile title
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// Change password tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Update password for {serverName}.'**
  String changePasswordSubtitle(String serverName);

  /// Subtitle when no server for password change
  ///
  /// In en, this message translates to:
  /// **'Add a server before changing password.'**
  String get addServerBeforeChangePassword;

  /// Delete account tile title
  ///
  /// In en, this message translates to:
  /// **'Delete user account'**
  String get deleteUserAccount;

  /// Delete account tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Deletes the user and all private cloud files.'**
  String get deleteUserAccountSubtitle;

  /// Delete account confirm dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountTitle;

  /// Delete account confirm dialog body
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account on {serverName} and removes all files stored in your private cloud folder. This cannot be undone.'**
  String deleteAccountBody(String serverName);

  /// Delete account confirm button
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountButton;

  /// Change password dialog title
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordDialogTitle;

  /// New password field label in change dialog
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordFieldLabel;

  /// Confirm password field label in change dialog
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// Validation: new password is required
  ///
  /// In en, this message translates to:
  /// **'Enter a new password.'**
  String get enterNewPassword;

  /// Snackbar on password change success
  ///
  /// In en, this message translates to:
  /// **'Password updated.'**
  String get passwordUpdated;

  /// Snackbar on password change failure
  ///
  /// In en, this message translates to:
  /// **'Password change failed: {error}'**
  String passwordChangeFailed(String error);

  /// Generic password change failure snackbar
  ///
  /// In en, this message translates to:
  /// **'Password change failed.'**
  String get passwordChangeFailedGeneric;

  /// Snackbar on account deletion success
  ///
  /// In en, this message translates to:
  /// **'Account deleted.'**
  String get accountDeleted;

  /// Snackbar on account deletion failure
  ///
  /// In en, this message translates to:
  /// **'Account deletion failed: {error}'**
  String accountDeletionFailed(String error);

  /// Generic account deletion failure snackbar
  ///
  /// In en, this message translates to:
  /// **'Account deletion failed.'**
  String get accountDeletionFailedGeneric;

  /// Update check tile title
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// Update check loading state
  ///
  /// In en, this message translates to:
  /// **'Checking GitHub Releases...'**
  String get checkingForUpdates;

  /// Version label in settings
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// Snackbar when app is up to date
  ///
  /// In en, this message translates to:
  /// **'Crowley\'s Cloud is up to date (v{version}).'**
  String appIsUpToDate(String version);

  /// Snackbar on update check failure
  ///
  /// In en, this message translates to:
  /// **'Failed to check for updates. Please try again later.'**
  String get updateCheckFailed;

  /// Theme mode tile title
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeModeTitle;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Custom theme option
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get themeCustom;

  /// Dark theme option (full label)
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get themeDarkFull;

  /// Light theme option (full label)
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get themeLightFull;

  /// Custom theme option (full label)
  ///
  /// In en, this message translates to:
  /// **'Custom Theme'**
  String get themeCustomFull;

  /// Accent color tile title
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColor;

  /// Accent color tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Primary accent color'**
  String get primaryAccentColor;

  /// Accent color picker dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Accent Color'**
  String get selectAccentColor;

  /// Background color tile
  ///
  /// In en, this message translates to:
  /// **'Background Color'**
  String get backgroundColor;

  /// Surface color tile
  ///
  /// In en, this message translates to:
  /// **'Surface Color'**
  String get surfaceColor;

  /// Text color tile
  ///
  /// In en, this message translates to:
  /// **'Text Color'**
  String get textColor;

  /// Subtext color tile
  ///
  /// In en, this message translates to:
  /// **'Subtext Color'**
  String get subtextColor;

  /// Border color tile
  ///
  /// In en, this message translates to:
  /// **'Border Color'**
  String get borderColor;

  /// Font size scale tile title
  ///
  /// In en, this message translates to:
  /// **'Font Size Scale'**
  String get fontSizeScale;

  /// Color picker dialog title (dynamic)
  ///
  /// In en, this message translates to:
  /// **'Select {title}'**
  String selectColor(String title);

  /// Sync categories dialog title
  ///
  /// In en, this message translates to:
  /// **'Categories to synchronize'**
  String get categoriesToSyncDialogTitle;

  /// Sync categories dialog body
  ///
  /// In en, this message translates to:
  /// **'Choose one or more categories. Leaving everything unchecked is valid.'**
  String get categoriesToSyncBody;

  /// Sync categories section: media
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get syncCategorySectionMedia;

  /// Sync categories section: audio & docs
  ///
  /// In en, this message translates to:
  /// **'Audio and documents'**
  String get syncCategorySectionAudioDocs;

  /// Sync categories section: other
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get syncCategorySectionOther;

  /// Clear all button in categories dialog
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// Label when no sync has executed
  ///
  /// In en, this message translates to:
  /// **'No sync has run yet.'**
  String get noSyncHasRunYet;

  /// Last sync run timestamp label
  ///
  /// In en, this message translates to:
  /// **'Last run {date}'**
  String lastRunAt(String date);

  /// Sync result snackbar: success
  ///
  /// In en, this message translates to:
  /// **'Synced {uploaded}, skipped {skipped}.'**
  String syncResultSuccess(int uploaded, int skipped);

  /// Sync result: no files
  ///
  /// In en, this message translates to:
  /// **'No files selected for sync.'**
  String get syncResultNoFiles;

  /// Sync result snackbar: partial failure
  ///
  /// In en, this message translates to:
  /// **'Synced {uploaded}, failed {failed}.'**
  String syncResultPartial(int uploaded, int failed);

  /// Sync result: auth required
  ///
  /// In en, this message translates to:
  /// **'Sign in before syncing.'**
  String get syncResultAuthRequired;

  /// Sync result: server unreachable
  ///
  /// In en, this message translates to:
  /// **'Server unreachable. Connection lost.'**
  String get syncResultUnreachable;

  /// Sync result: generic failure
  ///
  /// In en, this message translates to:
  /// **'Sync failed.'**
  String get syncResultFailed;

  /// Server setup screen AppBar title
  ///
  /// In en, this message translates to:
  /// **'Add server'**
  String get serverSetupAddServer;

  /// Server setup auth card title
  ///
  /// In en, this message translates to:
  /// **'Connect Server'**
  String get serverSetupCardTitle;

  /// Server setup auth card subtitle
  ///
  /// In en, this message translates to:
  /// **'Add your home file server and sign in.'**
  String get serverSetupCardSubtitle;

  /// Server setup auth card submit button
  ///
  /// In en, this message translates to:
  /// **'Save Server'**
  String get serverSetupSubmitButton;

  /// Server name field label
  ///
  /// In en, this message translates to:
  /// **'Server name'**
  String get serverNameLabel;

  /// Server name field hint
  ///
  /// In en, this message translates to:
  /// **'Home NAS'**
  String get serverNameHint;

  /// Base URL field label
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get baseUrlLabel;

  /// Base URL field hint
  ///
  /// In en, this message translates to:
  /// **'https://cloud.example.com'**
  String get baseUrlHint;

  /// Validation: all fields required
  ///
  /// In en, this message translates to:
  /// **'All fields are required.'**
  String get allFieldsRequired;

  /// Local file browser AppBar title
  ///
  /// In en, this message translates to:
  /// **'Local Files'**
  String get localFilesTitle;

  /// Server file browser AppBar title
  ///
  /// In en, this message translates to:
  /// **'Server Files'**
  String get serverFilesTitle;

  /// Trash restore confirm dialog title
  ///
  /// In en, this message translates to:
  /// **'Restore items'**
  String get restoreItemsTitle;

  /// Trash restore confirm dialog body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restore {count} item(s)?'**
  String restoreItemsBody(int count);

  /// Trash permanent delete confirm dialog title
  ///
  /// In en, this message translates to:
  /// **'Permanently delete'**
  String get permanentlyDeleteTitle;

  /// Trash permanent delete confirm dialog body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete {count} item(s)? This action cannot be undone.'**
  String permanentlyDeleteBody(int count);

  /// Trash empty state message
  ///
  /// In en, this message translates to:
  /// **'Trash is empty.'**
  String get trashIsEmpty;

  /// Trash retention info banner
  ///
  /// In en, this message translates to:
  /// **'Items in trash are automatically deleted after {days} days.'**
  String trashRetentionInfo(int days);

  /// Sort option: deletion date (trash)
  ///
  /// In en, this message translates to:
  /// **'Deletion Date'**
  String get deletionDate;

  /// Action bar label for permanent delete in trash
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deletePermanentlyAction;

  /// Conflict dialog title
  ///
  /// In en, this message translates to:
  /// **'File already exists'**
  String get conflictFileAlreadyExists;

  /// Conflict dialog subtitle
  ///
  /// In en, this message translates to:
  /// **'Conflict {current} of {total}'**
  String conflictNofM(int current, int total);

  /// Conflict dialog body text span prefix
  ///
  /// In en, this message translates to:
  /// **'A file named '**
  String get conflictAFileNamed;

  /// Conflict dialog body text span (restore)
  ///
  /// In en, this message translates to:
  /// **' already exists at '**
  String get conflictAlreadyExistsAt;

  /// Conflict dialog body text span (upload)
  ///
  /// In en, this message translates to:
  /// **' already exists in this folder.'**
  String get conflictAlreadyExistsInFolder;

  /// Conflict dialog column header: existing file in folder
  ///
  /// In en, this message translates to:
  /// **'In Folder'**
  String get conflictInFolder;

  /// Conflict dialog column header: file from trash
  ///
  /// In en, this message translates to:
  /// **'From Trash'**
  String get conflictFromTrash;

  /// Conflict dialog column header: existing upload file
  ///
  /// In en, this message translates to:
  /// **'Existing'**
  String get conflictExisting;

  /// Conflict dialog column header: new uploaded file
  ///
  /// In en, this message translates to:
  /// **'New Upload'**
  String get conflictNewUpload;

  /// Conflict dialog size data label
  ///
  /// In en, this message translates to:
  /// **'Size: {size}'**
  String conflictSizeLabel(String size);

  /// Conflict dialog date data label
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String conflictDateLabel(String date);

  /// Conflict dialog deleted-at label
  ///
  /// In en, this message translates to:
  /// **'Deleted: {date}'**
  String conflictDeletedLabel(String date);

  /// Conflict dialog apply-to-all checkbox label
  ///
  /// In en, this message translates to:
  /// **'Apply to remaining {count} conflict(s)'**
  String conflictApplyToRemaining(int count);

  /// Conflict action: keep all copies
  ///
  /// In en, this message translates to:
  /// **'Keep All Copies'**
  String get conflictKeepAllCopies;

  /// Conflict action: overwrite all
  ///
  /// In en, this message translates to:
  /// **'Overwrite All'**
  String get conflictOverwriteAll;

  /// Restore conflict action: restore all as copies
  ///
  /// In en, this message translates to:
  /// **'Restore All as Copies'**
  String get conflictRestoreAllAsCopies;

  /// Restore conflict action: restore as copy
  ///
  /// In en, this message translates to:
  /// **'Restore as Copy'**
  String get conflictRestoreAsCopy;

  /// Conflict action: overwrite all remaining
  ///
  /// In en, this message translates to:
  /// **'Overwrite All Remaining'**
  String get conflictOverwriteAllRemaining;

  /// Upload conflict action: skip all
  ///
  /// In en, this message translates to:
  /// **'Skip All'**
  String get conflictSkipAll;

  /// Upload conflict action: skip all remaining
  ///
  /// In en, this message translates to:
  /// **'Skip All Remaining'**
  String get conflictSkipAllRemaining;

  /// Upload conflict action: skip
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get conflictSkip;

  /// Conflict action: overwrite single
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get conflictOverwrite;

  /// Transfers page AppBar title
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get transfersTitle;

  /// Transfer resume button tooltip
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get transferResume;

  /// Transfer pause button tooltip
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get transferPause;

  /// Transfer cancel button tooltip
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get transferCancel;

  /// Resume all transfers button tooltip
  ///
  /// In en, this message translates to:
  /// **'Resume all'**
  String get transferResumeAll;

  /// Pause all transfers button tooltip
  ///
  /// In en, this message translates to:
  /// **'Pause all'**
  String get transferPauseAll;

  /// Cancel all transfers button tooltip
  ///
  /// In en, this message translates to:
  /// **'Cancel all'**
  String get transferCancelAll;

  /// Cancel individual transfer button tooltip
  ///
  /// In en, this message translates to:
  /// **'Cancel file'**
  String get transferCancelFile;

  /// Empty state in transfers page
  ///
  /// In en, this message translates to:
  /// **'No transfers.'**
  String get noTransfers;

  /// Transfer status: queued
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get transferStatusQueued;

  /// Transfer status: running
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get transferStatusRunning;

  /// Transfer status: paused
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get transferStatusPaused;

  /// Transfer status: completed
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get transferStatusCompleted;

  /// Transfer status: failed
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get transferStatusFailed;

  /// Transfer status: canceled
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get transferStatusCanceled;

  /// Theme customizer section header: presets
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get themePresetsSection;

  /// Theme customizer section header: custom palette
  ///
  /// In en, this message translates to:
  /// **'Custom Palette'**
  String get themeCustomPaletteSection;

  /// Theme customizer hex input label
  ///
  /// In en, this message translates to:
  /// **'HEX RGB Code'**
  String get themeHexRgbLabel;

  /// Theme customizer hex input hint
  ///
  /// In en, this message translates to:
  /// **'#FA5252'**
  String get themeHexRgbHint;

  /// Image viewer internal error text
  ///
  /// In en, this message translates to:
  /// **'No fetch handler configured'**
  String get imageViewerNoFetchHandler;

  /// Image viewer image load error text
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get imageViewerFailedToLoad;

  /// Snackbar on file delete error in image viewer
  ///
  /// In en, this message translates to:
  /// **'Error deleting {filename}: {error}'**
  String errorDeletingFile(String filename, String error);

  /// Error text when file cannot be read in text viewer
  ///
  /// In en, this message translates to:
  /// **'Error reading file: {error}'**
  String errorReadingFile(String error);

  /// Android notification channel name
  ///
  /// In en, this message translates to:
  /// **'Background Synchronization'**
  String get syncChannelName;

  /// Android notification channel description
  ///
  /// In en, this message translates to:
  /// **'Shows status of files syncing in the background.'**
  String get syncChannelDescription;

  /// Storage statistics sheet title / tooltip
  ///
  /// In en, this message translates to:
  /// **'Storage Statistics'**
  String get storageStatsTitle;

  /// Storage stats: used space label
  ///
  /// In en, this message translates to:
  /// **'Used Space'**
  String get storageStatsUsedSpace;

  /// Storage stats: total files label
  ///
  /// In en, this message translates to:
  /// **'Total Files'**
  String get storageStatsTotalFiles;

  /// Storage stats: item count label
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String storageStatsNItems(int count);

  /// Fallback label for unknown user
  ///
  /// In en, this message translates to:
  /// **'User #{userId}'**
  String userFallback(int userId);

  /// Biometric authentication prompt reason
  ///
  /// In en, this message translates to:
  /// **'Unlock saved credentials for Crowley\'s Cloud.'**
  String get biometricUnlockReason;

  /// Token lifetime option: every app launch
  ///
  /// In en, this message translates to:
  /// **'Every app open'**
  String get tokenLifetimeEveryOpen;

  /// Token lifetime option: 1 hour
  ///
  /// In en, this message translates to:
  /// **'After 1 hour'**
  String get tokenLifetimeOneHour;

  /// Token lifetime option: 1 hour (alias)
  ///
  /// In en, this message translates to:
  /// **'After 1 hour'**
  String get tokenLifetime1Hour;

  /// Token lifetime option: 1 day
  ///
  /// In en, this message translates to:
  /// **'After 1 day'**
  String get tokenLifetimeOneDay;

  /// Token lifetime option: 1 day (alias)
  ///
  /// In en, this message translates to:
  /// **'After 1 day'**
  String get tokenLifetime1Day;

  /// Token lifetime option: 1 week
  ///
  /// In en, this message translates to:
  /// **'After 1 week'**
  String get tokenLifetimeOneWeek;

  /// Token lifetime option: 1 week (alias)
  ///
  /// In en, this message translates to:
  /// **'After 1 week'**
  String get tokenLifetime1Week;

  /// Token lifetime option: 1 month
  ///
  /// In en, this message translates to:
  /// **'After 1 month'**
  String get tokenLifetimeOneMonth;

  /// Token lifetime option: 1 month (alias)
  ///
  /// In en, this message translates to:
  /// **'After 1 month'**
  String get tokenLifetime1Month;

  /// Token lifetime option: 3 months
  ///
  /// In en, this message translates to:
  /// **'After 3 months'**
  String get tokenLifetimeThreeMonths;

  /// Token lifetime option: 3 months (alias)
  ///
  /// In en, this message translates to:
  /// **'After 3 months'**
  String get tokenLifetime3Months;

  /// Token lifetime option: never expires on device
  ///
  /// In en, this message translates to:
  /// **'Never on this device'**
  String get tokenLifetimeNever;

  /// Cache limit option: unlimited
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get cacheLimitUnlimited;

  /// Label for other files category in sync settings
  ///
  /// In en, this message translates to:
  /// **'Other files'**
  String get syncCategoryOtherFiles;

  /// Label for device internal storage root in display path
  ///
  /// In en, this message translates to:
  /// **'Internal Storage'**
  String get internalStorage;

  /// Display name for root internal storage directory
  ///
  /// In en, this message translates to:
  /// **'Internal Storage'**
  String get localStorageRootName;

  /// Background sync notification title when syncing starts
  ///
  /// In en, this message translates to:
  /// **'Syncing with {serverName}'**
  String syncNotificationSyncingWith(String serverName);

  /// Background sync notification title when sync is paused
  ///
  /// In en, this message translates to:
  /// **'Sync with {serverName} paused'**
  String syncNotificationPausedTitle(String serverName);

  /// Background sync notification body when server is unreachable
  ///
  /// In en, this message translates to:
  /// **'Server is unreachable. Background sync paused until app is opened.'**
  String get syncNotificationUnreachableBody;

  /// Background sync notification body when authentication fails
  ///
  /// In en, this message translates to:
  /// **'Authentication required. Open app to log in.'**
  String get syncNotificationAuthRequiredBody;

  /// Background sync notification title on error
  ///
  /// In en, this message translates to:
  /// **'Sync with {serverName} failed'**
  String syncNotificationFailedTitle(String serverName);

  /// Background sync notification body generic error fallback
  ///
  /// In en, this message translates to:
  /// **'An error occurred during synchronization.'**
  String get syncNotificationGenericErrorBody;

  /// Background sync notification title when sync completes successfully
  ///
  /// In en, this message translates to:
  /// **'Sync with {serverName} complete'**
  String syncNotificationCompleteTitle(String serverName);

  /// Background sync notification body on completion
  ///
  /// In en, this message translates to:
  /// **'Sync complete.'**
  String get syncNotificationCompleteBody;

  /// Sync progress status message when connecting
  ///
  /// In en, this message translates to:
  /// **'Connecting to server...'**
  String get syncStatusConnecting;

  /// Sync error message when connection is lost
  ///
  /// In en, this message translates to:
  /// **'Could not connect to {serverName}. Connection lost.'**
  String syncStatusConnectionLost(String serverName);

  /// Sync error when connection to specific server is lost
  ///
  /// In en, this message translates to:
  /// **'Could not connect to {serverName}. Connection lost.'**
  String syncResultServerUnreachableWithServer(String serverName);

  /// Sync progress status message when scanning device files
  ///
  /// In en, this message translates to:
  /// **'Scanning files on device...'**
  String get syncStatusScanningFiles;

  /// Sync progress status message when no files matched criteria
  ///
  /// In en, this message translates to:
  /// **'No files found to synchronize.'**
  String get syncStatusNoFilesFound;

  /// Sync error message when no sync categories or folders are configured
  ///
  /// In en, this message translates to:
  /// **'No files selected for synchronization.'**
  String get syncStatusNoFilesSelected;

  /// Sync progress status message while hashing candidates
  ///
  /// In en, this message translates to:
  /// **'Calculating checksum ({current}/{total}): {filename}'**
  String syncStatusCalculatingChecksum(int current, int total, String filename);

  /// Sync progress status message while querying server duplicates
  ///
  /// In en, this message translates to:
  /// **'Checking for duplicates on server...'**
  String get syncStatusCheckingDuplicates;

  /// Sync progress status message while uploading files
  ///
  /// In en, this message translates to:
  /// **'Syncing ({current}/{total}): {filename}'**
  String syncStatusSyncingFile(int current, int total, String filename);

  /// Sync progress status message on finalizing sync run
  ///
  /// In en, this message translates to:
  /// **'Completing synchronization...'**
  String get syncStatusCompleting;

  /// Banner message when displaying offline cached files
  ///
  /// In en, this message translates to:
  /// **'Showing cached files.'**
  String get showingCachedFiles;

  /// Banner message when cache is shown and network refresh failed
  ///
  /// In en, this message translates to:
  /// **'Showing cached files. Refresh failed.'**
  String get showingCachedFilesRefreshFailed;

  /// Snackbar on download cancellation
  ///
  /// In en, this message translates to:
  /// **'Download canceled.'**
  String get downloadCanceled;

  /// Snackbar on successful file download to specific folder
  ///
  /// In en, this message translates to:
  /// **'Downloaded {count} file(s) to {path}'**
  String downloadedNFilesToPath(int count, String path);

  /// Snackbar on partial download failure
  ///
  /// In en, this message translates to:
  /// **'Downloaded {downloaded} file(s), failed {failed}: {detail}'**
  String downloadedNFilesFailedM(int downloaded, int failed, String detail);

  /// Snackbar on partial download failure with error
  ///
  /// In en, this message translates to:
  /// **'Downloaded {count} file(s), failed {failed}: {error}'**
  String downloadedNFilesWithFailures(int count, int failed, String error);

  /// Snackbar on successful share links creation
  ///
  /// In en, this message translates to:
  /// **'Created {count} share link(s).'**
  String createdNShareLinks(int count);

  /// Snackbar when share link creation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create share link(s).'**
  String get failedToCreateShareLinks;

  /// Snackbar warning when file is already shared
  ///
  /// In en, this message translates to:
  /// **'Already in shared scope.'**
  String get alreadyInSharedScope;

  /// Snackbar on sharing items in server
  ///
  /// In en, this message translates to:
  /// **'Shared {count} item(s) in server.'**
  String sharedNItemsInServer(int count);

  /// Snackbar on partial server share failure
  ///
  /// In en, this message translates to:
  /// **'Shared {count} item(s), failed {failed}.'**
  String sharedNItemsWithFailures(int count, int failed);

  /// Snackbar on partial server share failure
  ///
  /// In en, this message translates to:
  /// **'Shared {shared} item(s), failed {failed}.'**
  String sharedNItemsFailedM(int shared, int failed);

  /// Validation error when folder name is empty
  ///
  /// In en, this message translates to:
  /// **'Folder name cannot be empty.'**
  String get folderNameCannotBeEmpty;

  /// Error when created folder name already exists
  ///
  /// In en, this message translates to:
  /// **'Folder already exists.'**
  String get folderAlreadyExists;

  /// Snackbar when folder creation is attempted outside All Files
  ///
  /// In en, this message translates to:
  /// **'Folder creation is only available in All files.'**
  String get folderCreationOnlyInAllFiles;

  /// Error when current browsing directory is not available
  ///
  /// In en, this message translates to:
  /// **'Current directory is unavailable.'**
  String get currentDirectoryUnavailable;

  /// Notice when batch operation is invoked with no selection
  ///
  /// In en, this message translates to:
  /// **'Nothing selected.'**
  String get nothingSelected;

  /// Error when move destination directory is missing
  ///
  /// In en, this message translates to:
  /// **'Destination folder does not exist.'**
  String get destinationFolderDoesNotExist;

  /// Error when moving a folder into its own subtree
  ///
  /// In en, this message translates to:
  /// **'Cannot move folder \"{name}\" into itself.'**
  String cannotMoveFolderIntoItself(String name);

  /// Error message when moving a single item fails
  ///
  /// In en, this message translates to:
  /// **'Failed to move {name}: {error}'**
  String failedToMoveItem(String name, String error);

  /// Snackbar on moving multiple items
  ///
  /// In en, this message translates to:
  /// **'Moved {count} item(s).'**
  String movedNItems(int count);

  /// Snackbar on partial move failure
  ///
  /// In en, this message translates to:
  /// **'Moved {count} item(s), failed {failed}.'**
  String movedNItemsWithFailures(int count, int failed);

  /// Snackbar on partial move failure
  ///
  /// In en, this message translates to:
  /// **'Moved {moved} item(s), failed {failed}.'**
  String movedNItemsFailedM(int moved, int failed);

  /// Generic failure message when moving selected items fails
  ///
  /// In en, this message translates to:
  /// **'Failed to move selected items.'**
  String get failedToMoveSelectedItems;

  /// Notice when all files in a move operation were skipped
  ///
  /// In en, this message translates to:
  /// **'No files were moved.'**
  String get noFilesWereMoved;

  /// Snackbar on successful rename with old and new names
  ///
  /// In en, this message translates to:
  /// **'Renamed \"{oldName}\" to \"{newName}\".'**
  String renamedOldToNew(String oldName, String newName);

  /// Snackbar on successful rename with old and new names
  ///
  /// In en, this message translates to:
  /// **'Renamed \"{oldName}\" to \"{newName}\".'**
  String renamedFileFromTo(String oldName, String newName);

  /// Snackbar on rename failure with HTTP status
  ///
  /// In en, this message translates to:
  /// **'Failed to rename \"{name}\" ({statusCode}).'**
  String failedToRenameWithStatus(String name, int statusCode);

  /// Snackbar on rename failure with HTTP status
  ///
  /// In en, this message translates to:
  /// **'Failed to rename \"{name}\" ({statusCode}).'**
  String failedToRenameFileWithCode(String name, int statusCode);

  /// Snackbar on rename failure with error message
  ///
  /// In en, this message translates to:
  /// **'Failed to rename \"{name}\": {error}'**
  String failedToRenameWithError(String name, String error);

  /// Snackbar on rename failure with error message
  ///
  /// In en, this message translates to:
  /// **'Failed to rename \"{name}\": {error}'**
  String failedToRenameFile(String name, String error);

  /// Validation error when target filename already exists
  ///
  /// In en, this message translates to:
  /// **'Failed to rename: A file or folder with that name already exists.'**
  String get renameConflictAlreadyExists;

  /// Validation error when target filename already exists
  ///
  /// In en, this message translates to:
  /// **'Failed to rename: A file or folder with that name already exists.'**
  String get renameFailedAlreadyExists;

  /// Error message when server folder creation fails with status code
  ///
  /// In en, this message translates to:
  /// **'Failed to create folder ({statusCode}).'**
  String failedToCreateFolderWithCode(int statusCode);

  /// Notice on partial batch delete failure
  ///
  /// In en, this message translates to:
  /// **'Deleted {deleted} item(s), failed {failed}.'**
  String deletedNItemsFailedM(int deleted, int failed);

  /// Summary progress label in transfer bottom bar
  ///
  /// In en, this message translates to:
  /// **'{percent}%  {completed}/{total} files'**
  String transferSummaryFiles(int percent, int completed, int total);

  /// Summary progress label in transfer bottom bar
  ///
  /// In en, this message translates to:
  /// **'{percent}%  {completed}/{total} files'**
  String transferSummaryProgress(int percent, int completed, int total);

  /// Generic download failed text
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadFailedGeneric;

  /// Upload summary with failed item count
  ///
  /// In en, this message translates to:
  /// **'Uploaded {uploaded} item(s), failed {failed}'**
  String uploadedNItemsWithFailures(int uploaded, int failed);

  /// Notice on batch upload with partial failure
  ///
  /// In en, this message translates to:
  /// **'Uploaded {uploaded} item(s), failed {failed}.'**
  String uploadedNItemsFailedM(int uploaded, int failed);

  /// Suffix for upload summary message indicating failure count
  ///
  /// In en, this message translates to:
  /// **', failed {count}'**
  String uploadSummaryFailedCount(int count);

  /// Error when local file has empty path during upload
  ///
  /// In en, this message translates to:
  /// **'{name}: local path is empty'**
  String uploadLocalPathEmpty(String name);

  /// Error when local file has empty path during upload
  ///
  /// In en, this message translates to:
  /// **'{name}: local path is empty'**
  String uploadErrorLocalPathEmpty(String name);

  /// Error message when directory upload fails
  ///
  /// In en, this message translates to:
  /// **'Directory upload failed'**
  String get directoryUploadFailed;

  /// Error message when directory upload fails
  ///
  /// In en, this message translates to:
  /// **'Directory upload failed'**
  String get uploadDirectoryFailed;

  /// Error when local file does not exist on disk
  ///
  /// In en, this message translates to:
  /// **'Local file not found'**
  String get localFileNotFound;

  /// Error when local file does not exist on disk
  ///
  /// In en, this message translates to:
  /// **'Local file not found'**
  String get uploadErrorLocalFileNotFound;

  /// Error when auth session token is missing
  ///
  /// In en, this message translates to:
  /// **'No active session token'**
  String get noSessionToken;

  /// Error when auth session token is missing
  ///
  /// In en, this message translates to:
  /// **'No active session token'**
  String get uploadErrorNoSessionToken;

  /// Transfer status error when server is disconnected
  ///
  /// In en, this message translates to:
  /// **'Server disconnected'**
  String get serverDisconnectedStatus;

  /// Transfer status error when server is disconnected
  ///
  /// In en, this message translates to:
  /// **'Server disconnected'**
  String get serverDisconnected;

  /// Notification when network connection to server fails
  ///
  /// In en, this message translates to:
  /// **'Server is unreachable.'**
  String get serverIsUnreachable;

  /// Notification when network connection to server fails
  ///
  /// In en, this message translates to:
  /// **'Server is unreachable.'**
  String get serverUnreachable;

  /// Error when local directory to upload does not exist
  ///
  /// In en, this message translates to:
  /// **'Local directory not found'**
  String get uploadErrorLocalDirectoryNotFound;

  /// Error when directory traversal fails
  ///
  /// In en, this message translates to:
  /// **'Failed to scan directory'**
  String get uploadErrorFailedToScanDirectory;

  /// Error when creating a folder on the server fails during upload
  ///
  /// In en, this message translates to:
  /// **'Folder creation failed (HTTP {statusCode})'**
  String uploadErrorFolderCreateHttp(int statusCode);

  /// Error when access token is missing from auth response
  ///
  /// In en, this message translates to:
  /// **'Missing access token in response'**
  String get authErrorMissingAccessToken;

  /// Error when refresh token is missing from auth response
  ///
  /// In en, this message translates to:
  /// **'Missing refresh token in response'**
  String get authErrorMissingRefreshToken;

  /// Error when trying to authenticate with saved credentials but none exist
  ///
  /// In en, this message translates to:
  /// **'No saved credentials available'**
  String get authErrorNoSavedCredentials;

  /// Error when trying to refresh session without a refresh token
  ///
  /// In en, this message translates to:
  /// **'No refresh token available'**
  String get authErrorNoRefreshToken;

  /// Error when performing authenticated action without active session
  ///
  /// In en, this message translates to:
  /// **'No active session available'**
  String get authErrorNoActiveSession;

  /// Error when saved username is missing
  ///
  /// In en, this message translates to:
  /// **'No saved username available'**
  String get authErrorNoSavedUsername;

  /// Message when GitHub releases API returns no releases
  ///
  /// In en, this message translates to:
  /// **'No releases published yet.'**
  String get updateNoReleasesPublished;

  /// Label for the application language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'bn',
    'cs',
    'de',
    'en',
    'es',
    'fa',
    'fr',
    'hi',
    'id',
    'it',
    'ja',
    'ko',
    'pl',
    'pt',
    'ru',
    'tr',
    'uk',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
        }
        break;
      }
  }

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'cs':
      return AppLocalizationsCs();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fa':
      return AppLocalizationsFa();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
