// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Crowley\'s Cloud';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Hủy';

  @override
  String get save => 'Lưu';

  @override
  String get delete => 'Xóa';

  @override
  String get rename => 'Đổi tên';

  @override
  String get close => 'Đóng';

  @override
  String get retry => 'Thử lại';

  @override
  String get loading => 'Đang tải...';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get error => 'Lỗi';

  @override
  String errorWithMessage(String message) {
    return 'Lỗi: $message';
  }

  @override
  String get unknown => 'Không xác định';

  @override
  String get upload => 'Tải lên';

  @override
  String get download => 'Tải xuống';

  @override
  String get share => 'Chia sẻ';

  @override
  String get copy => 'Sao chép';

  @override
  String get move => 'Di chuyển';

  @override
  String get restore => 'Khôi phục';

  @override
  String get apply => 'Áp dụng';

  @override
  String get create => 'Tạo';

  @override
  String get clear => 'Xóa';

  @override
  String get add => 'Thêm';

  @override
  String get remove => 'Gỡ bỏ';

  @override
  String get edit => 'Chỉnh sửa';

  @override
  String get switchLabel => 'Chuyển đổi';

  @override
  String get search => 'Tìm kiếm';

  @override
  String get name => 'Tên';

  @override
  String get date => 'Ngày';

  @override
  String get size => 'Kích thước';

  @override
  String get type => 'Loại';

  @override
  String get ascending => 'Tăng dần';

  @override
  String get descending => 'Giảm dần';

  @override
  String get allFiles => 'Tất cả';

  @override
  String get categoryImages => 'Hình ảnh';

  @override
  String get categoryPhotos => 'Ảnh';

  @override
  String get categoryVideos => 'Video';

  @override
  String get categoryAudio => 'Âm thanh';

  @override
  String get categoryDocuments => 'Tài liệu';

  @override
  String get categoryArchives => 'Tệp nén';

  @override
  String get categoryShared => 'Đã chia sẻ';

  @override
  String get categoryOther => 'Khác';

  @override
  String get categoryOtherFiles => 'Tệp khác';

  @override
  String get noFilesFound => 'Không tìm thấy tệp nào.';

  @override
  String get noFilesInFolder => 'Không có tệp nào trong thư mục này.';

  @override
  String get thisActionCannotBeUndone => 'Hành động này không thể hoàn tác.';

  @override
  String get passwordsDoNotMatch => 'Mật khẩu không khớp.';

  @override
  String get navLocalFiles => 'Tệp cục bộ';

  @override
  String get navServerFiles => 'Tệp máy chủ';

  @override
  String get navSettings => 'Cài đặt';

  @override
  String get navTrash => 'Thùng rác';

  @override
  String get navLocal => 'Cục bộ';

  @override
  String get navServer => 'Máy chủ';

  @override
  String get addServer => 'Thêm máy chủ';

  @override
  String get noServersConfigured => 'Chưa định cấu hình máy chủ nào.';

  @override
  String get addAServerInSettings => 'Thêm máy chủ trong Cài đặt.';

  @override
  String get addFirstServerHint => 'Thêm máy chủ đầu tiên của bạn để tiếp tục.';

  @override
  String get noServersConfiguredYet =>
      'Chưa có máy chủ nào được định cấu hình.';

  @override
  String get crowleysCloudSetup => 'Thiết lập Crowley\'s Cloud';

  @override
  String get connect => 'Kết nối';

  @override
  String get connecting => 'Đang kết nối...';

  @override
  String get connected => 'Đã kết nối';

  @override
  String get disconnected => 'Đã ngắt kết nối';

  @override
  String get switchServer => 'Chuyển máy chủ';

  @override
  String get chooseOtherServer => 'Chọn máy chủ khác';

  @override
  String get switchServerTitle => 'Chuyển máy chủ?';

  @override
  String switchServerBody(String serverName) {
    return 'Chuyển máy chủ đang hoạt động sang \"$serverName\"?';
  }

  @override
  String get chooseServer => 'Chọn máy chủ';

  @override
  String get authenticationRequired => 'Yêu cầu xác thực';

  @override
  String signInToAccess(String serverName) {
    return 'Đăng nhập để truy cập tệp trên $serverName';
  }

  @override
  String get signInWithPassword => 'Đăng nhập bằng mật khẩu';

  @override
  String get useBiometrics => 'Sử dụng sinh trắc học';

  @override
  String get openingSignIn => 'Đang mở đăng nhập...';

  @override
  String get serverConnectionFailed => 'Kết nối máy chủ thất bại';

  @override
  String get unableToConnectToServer =>
      'Không thể kết nối đến máy chủ đang hoạt động.';

  @override
  String unableToConnectTo(String serverName) {
    return 'Không thể kết nối đến $serverName.';
  }

  @override
  String get searchHint => 'Tìm kiếm...';

  @override
  String get searchFilesHint => 'Tìm kiếm tệp...';

  @override
  String get searchServerFilesHint => 'Tìm kiếm tệp máy chủ...';

  @override
  String get searchTrashHint => 'Tìm kiếm trong thùng rác...';

  @override
  String get storagePermissionRequired => 'Yêu cầu quyền truy cập bộ nhớ';

  @override
  String get grantPermission => 'Cấp quyền';

  @override
  String get permissionDeniedOpenSettings =>
      'Quyền bị từ chối. Vui lòng cấp quyền truy cập bộ nhớ trong Cài đặt.';

  @override
  String get manageStoragePermissionRequired =>
      'Cần có quyền Quản lý bộ nhớ để duyệt và chọn thư mục.';

  @override
  String get storagePermissionsRequired =>
      'Cần có quyền truy cập bộ nhớ để thực hiện đồng bộ hóa.';

  @override
  String updateAvailableTitle(String version) {
    return 'Bản cập nhật có sẵn: v$version';
  }

  @override
  String get updateAvailableTapToSeeNew => 'Nhấn để xem tính năng mới';

  @override
  String get updateView => 'Xem';

  @override
  String get updateAvailableDialogTitle => 'Có bản cập nhật mới';

  @override
  String updateVersionSubtitle(String version) {
    return 'Phiên bản $version';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'Hiện tại: v$version';
  }

  @override
  String updateNewVersion(String version) {
    return 'Mới: v$version';
  }

  @override
  String get updateWhatsNew => 'Tính năng mới:';

  @override
  String get updateGitHub => 'GitHub';

  @override
  String get updateNoReleaseNotes => 'Không có ghi chú phát hành.';

  @override
  String get updateLater => 'Để sau';

  @override
  String get updateDownloadApk => 'Tải APK';

  @override
  String get updateInstall => 'Cập nhật';

  @override
  String get shareLinkTitle => 'Chia sẻ liên kết';

  @override
  String get shareViaLink => 'Chia sẻ qua liên kết';

  @override
  String get shareInServer => 'Chia sẻ trong máy chủ';

  @override
  String get expiryDays => 'Hạn sử dụng (ngày)';

  @override
  String get expiryNever => 'Không bao giờ';

  @override
  String get expiry1Day => '1 ngày';

  @override
  String get expiry7Days => '7 ngày';

  @override
  String get expiry30Days => '30 ngày';

  @override
  String get expiry90Days => '90 ngày';

  @override
  String get expiry180Days => '180 ngày';

  @override
  String get expiry365Days => '365 ngày';

  @override
  String get createLink => 'Tạo liên kết';

  @override
  String get sharedLinkCopied =>
      'Đã sao chép liên kết chia sẻ vào khay nhớ tạm!';

  @override
  String failedToCopySharedLink(String error) {
    return 'Sao chép liên kết chia sẻ thất bại: $error';
  }

  @override
  String get cannotShareThisFileType => 'Không thể chia sẻ loại tệp này.';

  @override
  String failedToCreateShare(String error) {
    return 'Tạo chia sẻ thất bại: $error';
  }

  @override
  String get newFolderTitle => 'Tạo thư mục';

  @override
  String get newFolderHint => 'Tên thư mục';

  @override
  String get newFolder => 'Thư mục mới';

  @override
  String get folderCreated => 'Đã tạo thư mục.';

  @override
  String failedToCreateFolder(String error) {
    return 'Tạo thư mục thất bại: $error';
  }

  @override
  String get creatingFolder => 'Đang tạo thư mục...';

  @override
  String get renameDialogTitle => 'Đổi tên';

  @override
  String get renameHint => 'Tên mới';

  @override
  String get enterNewName => 'Nhập tên mới';

  @override
  String get renamedSuccessfully => 'Đổi tên thành công.';

  @override
  String renameFailed(String error) {
    return 'Đổi tên thất bại: $error';
  }

  @override
  String get moveDialogTitle => 'Di chuyển đến';

  @override
  String moveTo(String path) {
    return 'Di chuyển đến: $path';
  }

  @override
  String get moveHere => 'Di chuyển đến đây';

  @override
  String moveFailed(String error) {
    return 'Di chuyển thất bại: $error';
  }

  @override
  String get movedToFolder => 'Đã di chuyển vào thư mục.';

  @override
  String copyFailed(String error) {
    return 'Sao chép thất bại: $error';
  }

  @override
  String get selectFolder => 'Chọn thư mục';

  @override
  String get useThisFolder => 'Sử dụng thư mục này';

  @override
  String get storageRoot => 'Bộ nhớ';

  @override
  String get serverRoot => 'gốc';

  @override
  String deleteNItemsTitle(int count) {
    return 'Xóa $count mục?';
  }

  @override
  String get deleteFilesTitle => 'Xóa tệp?';

  @override
  String deleteFilesBody(int count) {
    return 'Bạn có chắc chắn muốn xóa $count mục đã chọn không? Hành động này không thể hoàn tác.';
  }

  @override
  String get deletePermanently => 'Xóa vĩnh viễn';

  @override
  String get deletePermanentlyTitle => 'Xóa vĩnh viễn?';

  @override
  String deletePermanentlyBody(String filename) {
    return '$filename sẽ bị xóa vĩnh viễn.';
  }

  @override
  String get deleteFileTitle => 'Xóa tệp?';

  @override
  String deleteFileBody(String filename) {
    return 'Bạn có chắc chắn muốn xóa $filename không? Hành động này không thể hoàn tác.';
  }

  @override
  String get deleteServerFileTitle => 'Xóa vĩnh viễn';

  @override
  String deleteServerFileBody(String filename) {
    return 'Bạn có chắc chắn muốn xóa vĩnh viễn \"$filename\" không? Hành động này không thể hoàn tác.';
  }

  @override
  String get unshareItemsTitle => 'Hủy chia sẻ các mục?';

  @override
  String unshareItemsBody(int count) {
    return 'Bạn có chắc chắn muốn hủy chia sẻ $count mục đã chọn không? Chúng sẽ bị xóa khỏi thư mục Đã chia sẻ.';
  }

  @override
  String get unshare => 'Hủy chia sẻ';

  @override
  String get moveToTrash => 'Chuyển vào thùng rác';

  @override
  String get movedToTrash => 'Đã chuyển vào thùng rác.';

  @override
  String movedNItemsToTrash(int count) {
    return 'Đã chuyển $count mục vào thùng rác.';
  }

  @override
  String failedToMoveToTrash(String error) {
    return 'Chuyển vào thùng rác thất bại: $error';
  }

  @override
  String deletedNItems(int count) {
    return 'Đã xóa $count mục.';
  }

  @override
  String failedToDelete(String error) {
    return 'Xóa thất bại: $error';
  }

  @override
  String failedToDeleteItem(String error) {
    return 'Xóa thất bại: $error';
  }

  @override
  String deletedFilename(String filename) {
    return 'Đã xóa $filename.';
  }

  @override
  String get failedToOpenFile => 'Không thể mở tệp';

  @override
  String fileDownloadFailed(String error) {
    return 'Tải tệp xuống thất bại: $error';
  }

  @override
  String get downloading => 'Đang tải xuống...';

  @override
  String get downloadingFile => 'Đang tải tệp xuống...';

  @override
  String downloadComplete(String filename) {
    return 'Tải xuống hoàn tất: $filename';
  }

  @override
  String downloadFailed(String error) {
    return 'Tải xuống thất bại: $error';
  }

  @override
  String get failedToDownloadPreview => 'Không thể tải bản xem trước';

  @override
  String uploadComplete(String filename) {
    return 'Tải lên hoàn tất: $filename';
  }

  @override
  String uploadFailed(String error) {
    return 'Tải lên thất bại: $error';
  }

  @override
  String get failedToPickFiles => 'Không thể chọn tệp';

  @override
  String uploadedNItems(int count) {
    return 'Đã tải lên $count tệp';
  }

  @override
  String get copiedLinkToClipboard => 'Đã sao chép liên kết vào khay nhớ tạm.';

  @override
  String failedToCopyLink(String error) {
    return 'Sao chép liên kết thất bại: $error';
  }

  @override
  String get selectingAll => 'Đang chọn tất cả...';

  @override
  String get allItemsSelected => 'Đã chọn tất cả các mục.';

  @override
  String get failedToLoadSearchResults => 'Không thể tải kết quả tìm kiếm';

  @override
  String get shareNotSupportedForType => 'Loại tệp này không hỗ trợ chia sẻ.';

  @override
  String nSelected(int count) {
    return 'Đã chọn $count mục';
  }

  @override
  String get noServerSelected => 'Chưa chọn máy chủ';

  @override
  String get pleaseConnectToServerFirst =>
      'Vui lòng kết nối với máy chủ trước.';

  @override
  String get signInRequired => 'Yêu cầu đăng nhập';

  @override
  String pleaseSignInToServer(String serverName) {
    return 'Vui lòng đăng nhập vào $serverName trước.';
  }

  @override
  String get connectingToServer => 'Đang kết nối đến máy chủ...';

  @override
  String connectedToServer(String serverName) {
    return 'Đã kết nối với $serverName.';
  }

  @override
  String connectionFailed(String error) {
    return 'Kết nối thất bại: $error';
  }

  @override
  String failedToConnect(String error) {
    return 'Không thể kết nối: $error';
  }

  @override
  String authFailed(String error) {
    return 'Xác thực thất bại: $error';
  }

  @override
  String get authFailedGeneric => 'Xác thực thất bại. Vui lòng thử lại.';

  @override
  String biometricLoginFailed(String error) {
    return 'Đăng nhập sinh trắc học thất bại: $error';
  }

  @override
  String get biometricLoginFailedGeneric => 'Đăng nhập sinh trắc học thất bại.';

  @override
  String get noServerSessionToken =>
      'Không có mã phiên máy chủ. Vui lòng xác thực lại với máy chủ.';

  @override
  String failedToSaveServer(String error) {
    return 'Lưu máy chủ thất bại: $error';
  }

  @override
  String get addToFolder => 'Thêm vào thư mục';

  @override
  String get loginTabLabel => 'Đăng nhập';

  @override
  String get registerTabLabel => 'Đăng ký';

  @override
  String get welcomeBack => 'Chào mừng trở lại';

  @override
  String get signInToContinue => 'Đăng nhập để tiếp tục';

  @override
  String get createAccount => 'Tạo tài khoản';

  @override
  String get joinTheServer => 'Tham gia máy chủ';

  @override
  String get usernameLabel => 'Tên người dùng';

  @override
  String get usernameHint => 'Nhập tên người dùng của bạn';

  @override
  String get passwordLabel => 'Mật khẩu';

  @override
  String get passwordHint => 'Nhập mật khẩu của bạn';

  @override
  String get showPassword => 'Hiện mật khẩu';

  @override
  String get hidePassword => 'Ẩn mật khẩu';

  @override
  String get confirmPassword => 'Xác nhận mật khẩu';

  @override
  String get logIn => 'Đăng nhập';

  @override
  String get loggingIn => 'Đang đăng nhập...';

  @override
  String get registering => 'Đang đăng ký...';

  @override
  String get forgotPassword => 'Quên mật khẩu?';

  @override
  String get doNotHaveAccount => 'Chưa có tài khoản? Chuyển sang Đăng ký.';

  @override
  String get alreadyHaveAccount => 'Đã có tài khoản? Chuyển sang Đăng nhập.';

  @override
  String get usernameCannotBeEmpty => 'Tên người dùng không được để trống.';

  @override
  String get passwordCannotBeEmpty => 'Mật khẩu không được để trống.';

  @override
  String get usernameInvalid =>
      'Tên người dùng phải từ 3–32 ký tự, gồm chữ cái, số, _ hoặc -.';

  @override
  String get passwordTooShort => 'Mật khẩu phải có ít nhất 8 ký tự.';

  @override
  String loginFailed(String error) {
    return 'Đăng nhập thất bại: $error';
  }

  @override
  String registrationFailed(String error) {
    return 'Đăng ký thất bại: $error';
  }

  @override
  String get resetPasswordTitle => 'Đặt lại mật khẩu';

  @override
  String get enterResetCodeTitle => 'Nhập mã đặt lại';

  @override
  String get resetPasswordStep1Body =>
      'Nhập tên người dùng của bạn. Mã xác nhận gồm 6 chữ số sẽ được xuất ra nhật ký/bảng điều khiển máy chủ.';

  @override
  String get resetPasswordStep2Body =>
      'Mã xác nhận đã được gửi đến bảng điều khiển máy chủ. Nhập mã gồm 6 chữ số và mật khẩu mới của bạn.';

  @override
  String get resetCodeLabel => 'Mã đặt lại';

  @override
  String get resetCodeHint => 'Nhập mã 6 chữ số';

  @override
  String get newPasswordLabel => 'Mật khẩu mới';

  @override
  String get newPasswordHint => 'Nhập mật khẩu mới';

  @override
  String get passwordResetSuccessfully => 'Đặt lại mật khẩu thành công!';

  @override
  String get usernameIsRequired => 'Tên người dùng là bắt buộc.';

  @override
  String get codeAndPasswordRequired =>
      'Cần có cả mã xác nhận và mật khẩu mới.';

  @override
  String get failedToRequestReset =>
      'Yêu cầu đặt lại thất bại. Vui lòng kiểm tra URL máy chủ.';

  @override
  String get failedToResetPassword =>
      'Đặt lại mật khẩu thất bại. Vui lòng kiểm tra mã xác nhận.';

  @override
  String get pleaseEnterServerUrlFirst => 'Vui lòng nhập URL máy chủ trước.';

  @override
  String get sendCode => 'Gửi mã';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get sectionBackupSync => 'Sao lưu & Đồng bộ';

  @override
  String get sectionStorageCache => 'Bộ nhớ & Bộ đệm';

  @override
  String get sectionSecurityBehavior => 'Bảo mật & Hành vi';

  @override
  String get sectionAboutUpdates => 'Thông tin & Bản cập nhật';

  @override
  String get sectionAppearance => 'Giao diện & Tùy chỉnh';

  @override
  String get noServersConfiguredSync => 'Chưa định cấu hình máy chủ';

  @override
  String get addServerBeforeSync =>
      'Vui lòng thêm máy chủ trước khi định cấu hình đồng bộ.';

  @override
  String get selectServerToConfigureSync =>
      'Chọn một máy chủ để định cấu hình đồng bộ.';

  @override
  String get activeServerSuffix => ' · đang hoạt động';

  @override
  String get folderAndCategorySync => 'Đồng bộ thư mục và danh mục';

  @override
  String get keepCategoriesSynced =>
      'Duy trì đồng bộ các danh mục hoặc thư mục cục bộ đã chọn với máy chủ này.';

  @override
  String get addServerBeforeSyncEnable =>
      'Vui lòng thêm máy chủ trước khi bật đồng bộ hóa.';

  @override
  String get onlyOnWifi => 'Chỉ qua Wi-Fi';

  @override
  String get onlyWhileCharging => 'Chỉ khi đang sạc';

  @override
  String get serverTargetDirectory => 'Thư mục đích trên máy chủ';

  @override
  String get serverTargetDirectoryHint => '/backup/mobile_phone';

  @override
  String get synchronizationFrequency => 'Tần suất đồng bộ hóa';

  @override
  String get syncNow => 'Đồng bộ ngay';

  @override
  String get syncing => 'Đang đồng bộ hóa...';

  @override
  String get categoriesToSynchronize => 'Danh mục cần đồng bộ';

  @override
  String get noCategoriesSelected => 'Chưa chọn danh mục nào.';

  @override
  String nCategoriesSelected(int count) {
    return 'Đã chọn $count danh mục';
  }

  @override
  String get foldersToSynchronize => 'Thư mục cần đồng bộ';

  @override
  String get noCustomFolders => 'Chưa định cấu hình thư mục tùy chỉnh nào.';

  @override
  String nFolders(int count) {
    return '$count thư mục';
  }

  @override
  String get addFolder => 'Thêm thư mục';

  @override
  String get removeFolder => 'Gỡ bỏ thư mục';

  @override
  String get removeServer => 'Xóa máy chủ';

  @override
  String get syncFreqEvery15Min => 'Mỗi 15 phút';

  @override
  String get syncFreqEvery30Min => 'Mỗi 30 phút';

  @override
  String get syncFreqEvery1Hour => 'Mỗi giờ';

  @override
  String syncFreqEveryNHours(int hours) {
    return 'Mỗi $hours giờ';
  }

  @override
  String syncFreqEveryNMin(int minutes) {
    return 'Mỗi $minutes phút';
  }

  @override
  String get syncFreqDaily => 'Hàng ngày';

  @override
  String get chooseSyncFrequencyTitle => 'Chọn tần suất đồng bộ';

  @override
  String get cacheSize => 'Kích thước bộ nhớ đệm';

  @override
  String get refreshTooltip => 'Làm mới';

  @override
  String get cacheLimit => 'Giới hạn bộ đệm';

  @override
  String get downloadPath => 'Đường dẫn tải xuống';

  @override
  String get defaultDownloadFolder => 'Thư mục CrowleysCloud mặc định';

  @override
  String get clearCache => 'Xóa bộ nhớ đệm';

  @override
  String get clearCacheTitle => 'Xóa bộ nhớ đệm?';

  @override
  String get clearCacheBody =>
      'Thao tác này sẽ xóa hình thu nhỏ cục bộ và danh sách máy chủ được lưu trong bộ nhớ đệm.';

  @override
  String get downloadPathDialogTitle => 'Đường dẫn tải xuống';

  @override
  String get downloadPathHint => '/storage/emulated/0/CrowleysCloud';

  @override
  String get useDefault => 'Dùng mặc định';

  @override
  String get serverTargetDirDialogTitle => 'Thư mục đích trên máy chủ';

  @override
  String get requireLogin => 'Yêu cầu đăng nhập';

  @override
  String get biometricLogin => 'Đăng nhập bằng sinh trắc học';

  @override
  String get biometricLoginSubtitle =>
      'Cho phép đăng nhập bằng thông tin xác thực đã lưu cùng sinh trắc học.';

  @override
  String get biometricsNotAvailable =>
      'Sinh trắc học không khả dụng trên thiết bị này.';

  @override
  String get showHiddenFiles => 'Hiện tệp ẩn';

  @override
  String get showHiddenFilesSubtitle =>
      'Hiển thị các tệp và thư mục bắt đầu bằng dấu chấm.';

  @override
  String get changePassword => 'Đổi mật khẩu';

  @override
  String changePasswordSubtitle(String serverName) {
    return 'Đổi mật khẩu cho $serverName.';
  }

  @override
  String get addServerBeforeChangePassword =>
      'Vui lòng thêm máy chủ trước khi đổi mật khẩu.';

  @override
  String get deleteUserAccount => 'Xóa tài khoản người dùng';

  @override
  String get deleteUserAccountSubtitle =>
      'Xóa người dùng và tất cả các tệp đám mây riêng tư.';

  @override
  String get deleteAccountTitle => 'Xóa tài khoản?';

  @override
  String deleteAccountBody(String serverName) {
    return 'Thao tác này sẽ xóa vĩnh viễn tài khoản của bạn trên $serverName và xóa tất cả các tệp được lưu trữ trong thư mục đám mây riêng tư của bạn. Hành động này không thể hoàn tác.';
  }

  @override
  String get deleteAccountButton => 'Xóa tài khoản';

  @override
  String get changePasswordDialogTitle => 'Đổi mật khẩu';

  @override
  String get newPasswordFieldLabel => 'Mật khẩu mới';

  @override
  String get confirmPasswordLabel => 'Xác nhận mật khẩu';

  @override
  String get enterNewPassword => 'Nhập mật khẩu mới.';

  @override
  String get passwordUpdated => 'Đã cập nhật mật khẩu.';

  @override
  String passwordChangeFailed(String error) {
    return 'Đổi mật khẩu thất bại: $error';
  }

  @override
  String get passwordChangeFailedGeneric => 'Đổi mật khẩu thất bại.';

  @override
  String get accountDeleted => 'Đã xóa tài khoản.';

  @override
  String accountDeletionFailed(String error) {
    return 'Xóa tài khoản thất bại: $error';
  }

  @override
  String get accountDeletionFailedGeneric => 'Xóa tài khoản thất bại.';

  @override
  String get checkForUpdates => 'Kiểm tra bản cập nhật';

  @override
  String get checkingForUpdates => 'Đang kiểm tra GitHub Releases...';

  @override
  String versionLabel(String version) {
    return 'Phiên bản $version';
  }

  @override
  String appIsUpToDate(String version) {
    return 'Crowley\'s Cloud đã là phiên bản mới nhất (v$version).';
  }

  @override
  String get updateCheckFailed =>
      'Kiểm tra bản cập nhật thất bại. Vui lòng thử lại sau.';

  @override
  String get themeModeTitle => 'Chế độ giao diện';

  @override
  String get themeDark => 'Tối';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeCustom => 'Tùy chỉnh';

  @override
  String get themeDarkFull => 'Chế độ tối';

  @override
  String get themeLightFull => 'Chế độ sáng';

  @override
  String get themeCustomFull => 'Chế độ tùy chỉnh';

  @override
  String get accentColor => 'Màu nhấn';

  @override
  String get primaryAccentColor => 'Màu nhấn chính';

  @override
  String get selectAccentColor => 'Chọn màu nhấn';

  @override
  String get backgroundColor => 'Màu nền';

  @override
  String get surfaceColor => 'Màu bề mặt';

  @override
  String get textColor => 'Màu chữ';

  @override
  String get subtextColor => 'Màu chữ phụ';

  @override
  String get borderColor => 'Màu viền';

  @override
  String get fontSizeScale => 'Tỷ lệ cỡ chữ';

  @override
  String selectColor(String title) {
    return 'Chọn $title';
  }

  @override
  String get categoriesToSyncDialogTitle => 'Danh mục cần đồng bộ';

  @override
  String get categoriesToSyncBody =>
      'Chọn một hoặc nhiều danh mục. Bạn có thể bỏ chọn tất cả.';

  @override
  String get syncCategorySectionMedia => 'Phương tiện';

  @override
  String get syncCategorySectionAudioDocs => 'Âm thanh & Tài liệu';

  @override
  String get syncCategorySectionOther => 'Khác';

  @override
  String get clearAll => 'Xóa tất cả';

  @override
  String get noSyncHasRunYet => 'Chưa có lần đồng bộ nào chạy.';

  @override
  String lastRunAt(String date) {
    return 'Chạy lần cuối $date';
  }

  @override
  String syncResultSuccess(int uploaded, int skipped) {
    return 'Đã đồng bộ $uploaded, đã bỏ qua $skipped.';
  }

  @override
  String get syncResultNoFiles => 'Không có tệp nào được chọn để đồng bộ.';

  @override
  String syncResultPartial(int uploaded, int failed) {
    return 'Đã đồng bộ $uploaded, thất bại $failed.';
  }

  @override
  String get syncResultAuthRequired => 'Đăng nhập trước khi đồng bộ.';

  @override
  String get syncResultUnreachable => 'Không thể kết nối máy chủ. Mất kết nối.';

  @override
  String get syncResultFailed => 'Đồng bộ thất bại.';

  @override
  String get serverSetupAddServer => 'Thêm máy chủ';

  @override
  String get serverSetupCardTitle => 'Kết nối máy chủ';

  @override
  String get serverSetupCardSubtitle =>
      'Thêm máy chủ tệp gia đình của bạn và đăng nhập.';

  @override
  String get serverSetupSubmitButton => 'Lưu máy chủ';

  @override
  String get serverNameLabel => 'Tên máy chủ';

  @override
  String get serverNameHint => 'NAS Gia đình';

  @override
  String get baseUrlLabel => 'URL cơ sở';

  @override
  String get baseUrlHint => 'https://cloud.example.com';

  @override
  String get allFieldsRequired => 'Tất cả các trường đều là bắt buộc.';

  @override
  String get localFilesTitle => 'Tệp cục bộ';

  @override
  String get serverFilesTitle => 'Tệp máy chủ';

  @override
  String get restoreItemsTitle => 'Khôi phục mục';

  @override
  String restoreItemsBody(int count) {
    return 'Bạn có chắc chắn muốn khôi phục $count mục không?';
  }

  @override
  String get permanentlyDeleteTitle => 'Xóa vĩnh viễn';

  @override
  String permanentlyDeleteBody(int count) {
    return 'Bạn có chắc chắn muốn xóa vĩnh viễn $count mục không? Hành động này không thể hoàn tác.';
  }

  @override
  String get trashIsEmpty => 'Thùng rác trống.';

  @override
  String trashRetentionInfo(int days) {
    return 'Các mục trong thùng rác sẽ tự động bị xóa sau $days ngày.';
  }

  @override
  String get deletionDate => 'Ngày xóa';

  @override
  String get deletePermanentlyAction => 'Xóa vĩnh viễn';

  @override
  String get conflictFileAlreadyExists => 'Tệp đã tồn tại';

  @override
  String conflictNofM(int current, int total) {
    return 'Xung đột $current / $total';
  }

  @override
  String get conflictAFileNamed => 'Một tệp có tên ';

  @override
  String get conflictAlreadyExistsAt => ' đã tồn tại tại ';

  @override
  String get conflictAlreadyExistsInFolder => ' đã tồn tại trong thư mục này.';

  @override
  String get conflictInFolder => 'Trong thư mục';

  @override
  String get conflictFromTrash => 'Từ thùng rác';

  @override
  String get conflictExisting => 'Hiện có';

  @override
  String get conflictNewUpload => 'Tải lên mới';

  @override
  String conflictSizeLabel(String size) {
    return 'Kích thước: $size';
  }

  @override
  String conflictDateLabel(String date) {
    return 'Ngày: $date';
  }

  @override
  String conflictDeletedLabel(String date) {
    return 'Ngày xóa: $date';
  }

  @override
  String conflictApplyToRemaining(int count) {
    return 'Áp dụng cho $count xung đột còn lại';
  }

  @override
  String get conflictKeepAllCopies => 'Giữ lại tất cả bản sao';

  @override
  String get conflictOverwriteAll => 'Ghi đè tất cả';

  @override
  String get conflictRestoreAllAsCopies => 'Khôi phục tất cả dưới dạng bản sao';

  @override
  String get conflictRestoreAsCopy => 'Khôi phục dưới dạng bản sao';

  @override
  String get conflictOverwriteAllRemaining => 'Ghi đè tất cả phần còn lại';

  @override
  String get conflictSkipAll => 'Bỏ qua tất cả';

  @override
  String get conflictSkipAllRemaining => 'Bỏ qua tất cả phần còn lại';

  @override
  String get conflictSkip => 'Bỏ qua';

  @override
  String get conflictOverwrite => 'Ghi đè';

  @override
  String get transfersTitle => 'Truyền tệp';

  @override
  String get transferResume => 'Tiếp tục';

  @override
  String get transferPause => 'Tạm dừng';

  @override
  String get transferCancel => 'Hủy';

  @override
  String get transferResumeAll => 'Tiếp tục tất cả';

  @override
  String get transferPauseAll => 'Tạm dừng tất cả';

  @override
  String get transferCancelAll => 'Hủy tất cả';

  @override
  String get transferCancelFile => 'Hủy tệp';

  @override
  String get noTransfers => 'Không có truyền tệp nào.';

  @override
  String get transferStatusQueued => 'Đang chờ';

  @override
  String get transferStatusRunning => 'Đang chạy';

  @override
  String get transferStatusPaused => 'Đã tạm dừng';

  @override
  String get transferStatusCompleted => 'Đã hoàn thành';

  @override
  String get transferStatusFailed => 'Thất bại';

  @override
  String get transferStatusCanceled => 'Đã hủy';

  @override
  String get themePresetsSection => 'Cài đặt sẵn';

  @override
  String get themeCustomPaletteSection => 'Bảng màu tùy chỉnh';

  @override
  String get themeHexRgbLabel => 'Mã HEX RGB';

  @override
  String get themeHexRgbHint => '#FA5252';

  @override
  String get imageViewerNoFetchHandler =>
      'Chưa định cấu hình trình xử lý tìm nạp hình ảnh';

  @override
  String get imageViewerFailedToLoad => 'Không thể tải hình ảnh';

  @override
  String errorDeletingFile(String filename, String error) {
    return 'Lỗi khi xóa $filename: $error';
  }

  @override
  String errorReadingFile(String error) {
    return 'Lỗi khi đọc tệp: $error';
  }

  @override
  String get syncChannelName => 'Đồng bộ nền';

  @override
  String get syncChannelDescription =>
      'Hiển thị trạng thái đồng bộ hóa tệp trong nền.';

  @override
  String get storageStatsTitle => 'Thống kê bộ nhớ';

  @override
  String get storageStatsUsedSpace => 'Dung lượng đã dùng';

  @override
  String get storageStatsTotalFiles => 'Tổng số tệp';

  @override
  String storageStatsNItems(int count) {
    return '$count mục';
  }

  @override
  String userFallback(int userId) {
    return 'Người dùng #$userId';
  }

  @override
  String get biometricUnlockReason =>
      'Mở khóa thông tin xác thực đã lưu cho Crowley\'s Cloud.';

  @override
  String get tokenLifetimeEveryOpen => 'Mỗi lần mở ứng dụng';

  @override
  String get tokenLifetimeOneHour => 'Sau 1 giờ';

  @override
  String get tokenLifetime1Hour => 'Sau 1 giờ';

  @override
  String get tokenLifetimeOneDay => 'Sau 1 ngày';

  @override
  String get tokenLifetime1Day => 'Sau 1 ngày';

  @override
  String get tokenLifetimeOneWeek => 'Sau 1 tuần';

  @override
  String get tokenLifetime1Week => 'Sau 1 tuần';

  @override
  String get tokenLifetimeOneMonth => 'Sau 1 tháng';

  @override
  String get tokenLifetime1Month => 'Sau 1 tháng';

  @override
  String get tokenLifetimeThreeMonths => 'Sau 3 tháng';

  @override
  String get tokenLifetime3Months => 'Sau 3 tháng';

  @override
  String get tokenLifetimeNever => 'Không bao giờ trên thiết bị này';

  @override
  String get cacheLimitUnlimited => 'Không giới hạn';

  @override
  String get syncCategoryOtherFiles => 'Tệp khác';

  @override
  String get internalStorage => 'Bộ nhớ trong';

  @override
  String get localStorageRootName => 'Bộ nhớ trong';

  @override
  String syncNotificationSyncingWith(String serverName) {
    return 'Đang đồng bộ với $serverName';
  }

  @override
  String syncNotificationPausedTitle(String serverName) {
    return 'Đã tạm dừng đồng bộ với $serverName';
  }

  @override
  String get syncNotificationUnreachableBody =>
      'Không thể truy cập máy chủ. Tạm dừng đồng bộ nền cho đến khi mở ứng dụng.';

  @override
  String get syncNotificationAuthRequiredBody =>
      'Yêu cầu xác thực. Hãy mở ứng dụng để đăng nhập.';

  @override
  String syncNotificationFailedTitle(String serverName) {
    return 'Đồng bộ với $serverName thất bại';
  }

  @override
  String get syncNotificationGenericErrorBody =>
      'Đã xảy ra lỗi trong quá trình đồng bộ hóa.';

  @override
  String syncNotificationCompleteTitle(String serverName) {
    return 'Đồng bộ với $serverName hoàn tất';
  }

  @override
  String get syncNotificationCompleteBody => 'Đồng bộ hoàn tất.';

  @override
  String get syncStatusConnecting => 'Đang kết nối đến máy chủ...';

  @override
  String syncStatusConnectionLost(String serverName) {
    return 'Không thể kết nối đến $serverName. Mất kết nối.';
  }

  @override
  String syncResultServerUnreachableWithServer(String serverName) {
    return 'Không thể kết nối đến $serverName. Mất kết nối.';
  }

  @override
  String get syncStatusScanningFiles => 'Đang quét tệp trên thiết bị...';

  @override
  String get syncStatusNoFilesFound => 'Không tìm thấy tệp nào để đồng bộ.';

  @override
  String get syncStatusNoFilesSelected => 'Chưa chọn tệp nào để đồng bộ.';

  @override
  String syncStatusCalculatingChecksum(
    int current,
    int total,
    String filename,
  ) {
    return 'Đang tính toán checksum ($current/$total): $filename';
  }

  @override
  String get syncStatusCheckingDuplicates =>
      'Đang kiểm tra tệp trùng lặp trên máy chủ...';

  @override
  String syncStatusSyncingFile(int current, int total, String filename) {
    return 'Đang đồng bộ ($current/$total): $filename';
  }

  @override
  String get syncStatusCompleting => 'Đang hoàn tất đồng bộ hóa...';

  @override
  String get showingCachedFiles => 'Đang hiển thị các tệp trong bộ nhớ đệm.';

  @override
  String get showingCachedFilesRefreshFailed =>
      'Đang hiển thị các tệp trong bộ nhớ đệm. Làm mới thất bại.';

  @override
  String get downloadCanceled => 'Đã hủy tải xuống.';

  @override
  String downloadedNFilesToPath(int count, String path) {
    return 'Đã tải xuống $count tệp vào $path';
  }

  @override
  String downloadedNFilesFailedM(int downloaded, int failed, String detail) {
    return 'Đã tải xuống $downloaded tệp, thất bại $failed: $detail';
  }

  @override
  String downloadedNFilesWithFailures(int count, int failed, String error) {
    return 'Đã tải xuống $count tệp, thất bại $failed: $error';
  }

  @override
  String createdNShareLinks(int count) {
    return 'Đã tạo $count liên kết chia sẻ.';
  }

  @override
  String get failedToCreateShareLinks => 'Không thể tạo liên kết chia sẻ.';

  @override
  String get alreadyInSharedScope => 'Đã nằm trong phạm vi chia sẻ.';

  @override
  String sharedNItemsInServer(int count) {
    return 'Đã chia sẻ $count mục trên máy chủ.';
  }

  @override
  String sharedNItemsWithFailures(int count, int failed) {
    return 'Đã chia sẻ $count mục, thất bại $failed mục.';
  }

  @override
  String sharedNItemsFailedM(int shared, int failed) {
    return 'Đã chia sẻ $shared mục, thất bại $failed mục.';
  }

  @override
  String get folderNameCannotBeEmpty => 'Tên thư mục không được để trống.';

  @override
  String get folderAlreadyExists => 'Thư mục có tên này đã tồn tại.';

  @override
  String get folderCreationOnlyInAllFiles =>
      'Chỉ có thể tạo thư mục trong mục \'Tất cả tệp\'.';

  @override
  String get currentDirectoryUnavailable => 'Thư mục hiện tại không khả dụng.';

  @override
  String get nothingSelected => 'Chưa chọn mục nào.';

  @override
  String get destinationFolderDoesNotExist => 'Thư mục đích không tồn tại.';

  @override
  String cannotMoveFolderIntoItself(String name) {
    return 'Không thể di chuyển thư mục \"$name\" vào chính nó.';
  }

  @override
  String failedToMoveItem(String name, String error) {
    return 'Di chuyển $name thất bại: $error';
  }

  @override
  String movedNItems(int count) {
    return 'Đã di chuyển $count mục.';
  }

  @override
  String movedNItemsWithFailures(int count, int failed) {
    return 'Đã di chuyển $count mục, thất bại $failed mục.';
  }

  @override
  String movedNItemsFailedM(int moved, int failed) {
    return 'Đã di chuyển $moved mục, thất bại $failed mục.';
  }

  @override
  String get failedToMoveSelectedItems => 'Di chuyển các mục đã chọn thất bại.';

  @override
  String get noFilesWereMoved => 'Không có tệp nào được di chuyển.';

  @override
  String renamedOldToNew(String oldName, String newName) {
    return 'Đã đổi tên \"$oldName\" thành \"$newName\".';
  }

  @override
  String renamedFileFromTo(String oldName, String newName) {
    return 'Đã đổi tên \"$oldName\" thành \"$newName\".';
  }

  @override
  String failedToRenameWithStatus(String name, int statusCode) {
    return 'Đổi tên \"$name\" thất bại ($statusCode).';
  }

  @override
  String failedToRenameFileWithCode(String name, int statusCode) {
    return 'Đổi tên \"$name\" thất bại ($statusCode).';
  }

  @override
  String failedToRenameWithError(String name, String error) {
    return 'Đổi tên \"$name\" thất bại: $error';
  }

  @override
  String failedToRenameFile(String name, String error) {
    return 'Đổi tên \"$name\" thất bại: $error';
  }

  @override
  String get renameConflictAlreadyExists =>
      'Đổi tên thất bại: tệp hoặc thư mục có tên này đã tồn tại.';

  @override
  String get renameFailedAlreadyExists =>
      'Đổi tên thất bại: tệp hoặc thư mục có tên này đã tồn tại.';

  @override
  String failedToCreateFolderWithCode(int statusCode) {
    return 'Tạo thư mục thất bại (Mã $statusCode).';
  }

  @override
  String deletedNItemsFailedM(int deleted, int failed) {
    return 'Đã xóa $deleted mục, thất bại $failed mục.';
  }

  @override
  String transferSummaryFiles(int percent, int completed, int total) {
    return '$percent%  $completed/$total tệp';
  }

  @override
  String transferSummaryProgress(int percent, int completed, int total) {
    return '$percent%  $completed/$total tệp';
  }

  @override
  String get downloadFailedGeneric => 'Tải xuống thất bại';

  @override
  String uploadedNItemsWithFailures(int uploaded, int failed) {
    return 'Đã tải lên $uploaded mục, thất bại $failed mục';
  }

  @override
  String uploadedNItemsFailedM(int uploaded, int failed) {
    return 'Đã tải lên $uploaded mục, thất bại $failed mục.';
  }

  @override
  String uploadSummaryFailedCount(int count) {
    return ', thất bại $count';
  }

  @override
  String uploadLocalPathEmpty(String name) {
    return '$name: đường dẫn cục bộ trống';
  }

  @override
  String uploadErrorLocalPathEmpty(String name) {
    return '$name: đường dẫn cục bộ trống';
  }

  @override
  String get directoryUploadFailed => 'Tải thư mục lên thất bại';

  @override
  String get uploadDirectoryFailed => 'Tải thư mục lên thất bại';

  @override
  String get localFileNotFound => 'Không tìm thấy tệp cục bộ';

  @override
  String get uploadErrorLocalFileNotFound => 'Không tìm thấy tệp cục bộ';

  @override
  String get noSessionToken => 'Không có mã phiên hoạt động';

  @override
  String get uploadErrorNoSessionToken => 'Không có mã phiên hoạt động';

  @override
  String get serverDisconnectedStatus => 'Đã ngắt kết nối máy chủ';

  @override
  String get serverDisconnected => 'Đã ngắt kết nối máy chủ';

  @override
  String get serverIsUnreachable => 'Không thể kết nối máy chủ.';

  @override
  String get serverUnreachable => 'Không thể kết nối máy chủ.';

  @override
  String get uploadErrorLocalDirectoryNotFound =>
      'Không tìm thấy thư mục cục bộ';

  @override
  String get uploadErrorFailedToScanDirectory => 'Quét thư mục thất bại';

  @override
  String uploadErrorFolderCreateHttp(int statusCode) {
    return 'Tạo thư mục thất bại (HTTP $statusCode)';
  }

  @override
  String get authErrorMissingAccessToken => 'Thiếu mã truy cập trong phản hồi';

  @override
  String get authErrorMissingRefreshToken => 'Thiếu mã làm mới trong phản hồi';

  @override
  String get authErrorNoSavedCredentials =>
      'Không có thông tin đăng nhập đã lưu';

  @override
  String get authErrorNoRefreshToken => 'Không có sẵn mã làm mới';

  @override
  String get authErrorNoActiveSession => 'Không có phiên hoạt động nào';

  @override
  String get authErrorNoSavedUsername => 'Không có sẵn tên người dùng đã lưu';

  @override
  String get updateNoReleasesPublished =>
      'Chưa có bản phát hành nào được công bố.';

  @override
  String get language => 'Ngôn ngữ';
}
