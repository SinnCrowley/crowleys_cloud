// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Crowley\'s Cloud';

  @override
  String get ok => '확인';

  @override
  String get cancel => '취소';

  @override
  String get save => '저장';

  @override
  String get delete => '삭제';

  @override
  String get rename => '이름 변경';

  @override
  String get close => '닫기';

  @override
  String get retry => '다시 시도';

  @override
  String get loading => '로드 중...';

  @override
  String get confirm => '확인';

  @override
  String get error => '오류';

  @override
  String errorWithMessage(String message) {
    return '오류: $message';
  }

  @override
  String get unknown => '알 수 없음';

  @override
  String get upload => '업로드';

  @override
  String get download => '다운로드';

  @override
  String get share => '공유';

  @override
  String get copy => '복사';

  @override
  String get move => '이동';

  @override
  String get restore => '복원';

  @override
  String get apply => '적용';

  @override
  String get create => '만들기';

  @override
  String get clear => '지우기';

  @override
  String get add => '추가';

  @override
  String get remove => '제거';

  @override
  String get edit => '수정';

  @override
  String get switchLabel => '전환';

  @override
  String get search => '검색';

  @override
  String get name => '이름';

  @override
  String get date => '날짜';

  @override
  String get size => '크기';

  @override
  String get type => '유형';

  @override
  String get ascending => '오름차순';

  @override
  String get descending => '내림차순';

  @override
  String get allFiles => '모두';

  @override
  String get categoryImages => '이미지';

  @override
  String get categoryPhotos => '사진';

  @override
  String get categoryVideos => '동영상';

  @override
  String get categoryAudio => '오디오';

  @override
  String get categoryDocuments => '문서';

  @override
  String get categoryArchives => '압축 파일';

  @override
  String get categoryShared => '공유됨';

  @override
  String get categoryOther => '기타';

  @override
  String get categoryOtherFiles => '기타 파일';

  @override
  String get noFilesFound => '파일을 찾을 수 없습니다.';

  @override
  String get noFilesInFolder => '이 폴더에 파일이 없습니다.';

  @override
  String get thisActionCannotBeUndone => '이 작업은 되돌릴 수 없습니다.';

  @override
  String get passwordsDoNotMatch => '비밀번호가 일치하지 않습니다.';

  @override
  String get navLocalFiles => '로컬';

  @override
  String get navServerFiles => '서버';

  @override
  String get navSettings => '설정';

  @override
  String get navTrash => '휴지통';

  @override
  String get navLocal => '로컬';

  @override
  String get navServer => '서버';

  @override
  String get addServer => '서버 추가';

  @override
  String get noServersConfigured => '구성된 서버가 없습니다.';

  @override
  String get addAServerInSettings => '설정에서 서버를 추가하세요.';

  @override
  String get addFirstServerHint => '계속하려면 첫 번째 서버를 추가하세요.';

  @override
  String get noServersConfiguredYet => '아직 구성된 서버가 없습니다.';

  @override
  String get crowleysCloudSetup => 'Crowley\'s Cloud 설정';

  @override
  String get connect => '연결';

  @override
  String get connecting => '연결 중...';

  @override
  String get connected => '연결됨';

  @override
  String get disconnected => '연결 끊김';

  @override
  String get switchServer => '서버 전환';

  @override
  String get chooseOtherServer => '다른 서버 선택';

  @override
  String get switchServerTitle => '서버를 전환할까요?';

  @override
  String switchServerBody(String serverName) {
    return '활성 서버를 \"$serverName\"(으)로 전환할까요?';
  }

  @override
  String get chooseServer => '서버 선택';

  @override
  String get authenticationRequired => '인증 필요';

  @override
  String signInToAccess(String serverName) {
    return '$serverName의 파일에 액세스하려면 로그인하세요';
  }

  @override
  String get signInWithPassword => '비밀번호로 로그인';

  @override
  String get useBiometrics => '생체 인증 사용';

  @override
  String get openingSignIn => '로그인 여는 중...';

  @override
  String get serverConnectionFailed => '서버 연결 실패';

  @override
  String get unableToConnectToServer => '활성 서버에 연결할 수 없습니다.';

  @override
  String unableToConnectTo(String serverName) {
    return '$serverName에 연결할 수 없습니다.';
  }

  @override
  String get searchHint => '검색...';

  @override
  String get searchFilesHint => '파일 검색...';

  @override
  String get searchServerFilesHint => '서버 파일 검색...';

  @override
  String get searchTrashHint => '휴지통 검색...';

  @override
  String get storagePermissionRequired => '저장소 권한 필요';

  @override
  String get grantPermission => '권한 허용';

  @override
  String get permissionDeniedOpenSettings =>
      '권한이 거부되었습니다. 설정에서 저장소 액세스 권한을 허용해 주세요.';

  @override
  String get manageStoragePermissionRequired =>
      '폴더를 탐색하고 선택하려면 저장소 관리 권한이 필요합니다.';

  @override
  String get storagePermissionsRequired => '동기화를 수행하려면 저장소 권한이 필요합니다.';

  @override
  String updateAvailableTitle(String version) {
    return '업데이트 사용 가능: v$version';
  }

  @override
  String get updateAvailableTapToSeeNew => '새로운 기능을 보려면 탭하세요';

  @override
  String get updateView => '보기';

  @override
  String get updateAvailableDialogTitle => '업데이트 사용 가능';

  @override
  String updateVersionSubtitle(String version) {
    return '버전 $version';
  }

  @override
  String updateCurrentVersion(String version) {
    return '현재: v$version';
  }

  @override
  String updateNewVersion(String version) {
    return '최신: v$version';
  }

  @override
  String get updateWhatsNew => '새로운 기능:';

  @override
  String get updateGitHub => 'GitHub';

  @override
  String get updateNoReleaseNotes => '제공된 릴리스 노트가 없습니다.';

  @override
  String get updateLater => '나중에';

  @override
  String get updateDownloadApk => 'APK 다운로드';

  @override
  String get updateInstall => '업데이트';

  @override
  String get shareLinkTitle => '공유 링크';

  @override
  String get shareViaLink => '링크로 공유';

  @override
  String get shareInServer => '서버에서 공유';

  @override
  String get expiryDays => '만료 기간 (일)';

  @override
  String get expiryNever => '없음';

  @override
  String get expiry1Day => '1일';

  @override
  String get expiry7Days => '7일';

  @override
  String get expiry30Days => '30일';

  @override
  String get expiry90Days => '90일';

  @override
  String get expiry180Days => '180일';

  @override
  String get expiry365Days => '365일';

  @override
  String get createLink => '링크 만들기';

  @override
  String get sharedLinkCopied => '공유 링크를 클립보드에 복사했습니다!';

  @override
  String failedToCopySharedLink(String error) {
    return '공유 링크를 복사하지 못했습니다: $error';
  }

  @override
  String get cannotShareThisFileType => '이 파일 형식은 공유할 수 없습니다.';

  @override
  String failedToCreateShare(String error) {
    return '공유를 생성하지 못했습니다: $error';
  }

  @override
  String get newFolderTitle => '폴더 만들기';

  @override
  String get newFolderHint => '폴더 이름';

  @override
  String get newFolder => '새 폴더';

  @override
  String get folderCreated => '폴더를 만들었습니다.';

  @override
  String failedToCreateFolder(String error) {
    return '폴더를 만들지 못했습니다: $error';
  }

  @override
  String get creatingFolder => '폴더 만드는 중...';

  @override
  String get renameDialogTitle => '이름 변경';

  @override
  String get renameHint => '새 이름';

  @override
  String get enterNewName => '새 이름 입력';

  @override
  String get renamedSuccessfully => '이름을 변경했습니다.';

  @override
  String renameFailed(String error) {
    return '이름 변경 실패: $error';
  }

  @override
  String get moveDialogTitle => '이동 위치';

  @override
  String moveTo(String path) {
    return '이동 위치: $path';
  }

  @override
  String get moveHere => '여기로 이동';

  @override
  String moveFailed(String error) {
    return '이동 실패: $error';
  }

  @override
  String get movedToFolder => '폴더로 이동했습니다.';

  @override
  String copyFailed(String error) {
    return '복사 실패: $error';
  }

  @override
  String get selectFolder => '폴더 선택';

  @override
  String get useThisFolder => '이 폴더 사용';

  @override
  String get storageRoot => '저장소';

  @override
  String get serverRoot => '루트';

  @override
  String deleteNItemsTitle(int count) {
    return '$count개 항목을 삭제할까요?';
  }

  @override
  String get deleteFilesTitle => '파일을 삭제할까요?';

  @override
  String deleteFilesBody(int count) {
    return '선택한 $count개 항목을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get deletePermanently => '영구 삭제';

  @override
  String get deletePermanentlyTitle => '영구 삭제할까요?';

  @override
  String deletePermanentlyBody(String filename) {
    return '\"$filename\"이(가) 영구적으로 삭제됩니다.';
  }

  @override
  String get deleteFileTitle => '파일을 삭제할까요?';

  @override
  String deleteFileBody(String filename) {
    return '\"$filename\"을(를) 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get deleteServerFileTitle => '영구 삭제';

  @override
  String deleteServerFileBody(String filename) {
    return '\"$filename\"을(를) 영구 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get unshareItemsTitle => '항목 공유를 해제할까요?';

  @override
  String unshareItemsBody(int count) {
    return '선택한 $count개 항목의 공유를 해제하시겠습니까? 공유 폴더에서 제거됩니다.';
  }

  @override
  String get unshare => '공유 해제';

  @override
  String get moveToTrash => '휴지통으로 이동';

  @override
  String get movedToTrash => '휴지통으로 이동했습니다.';

  @override
  String movedNItemsToTrash(int count) {
    return '$count개 항목을 휴지통으로 이동했습니다.';
  }

  @override
  String failedToMoveToTrash(String error) {
    return '휴지통으로 이동하지 못했습니다: $error';
  }

  @override
  String deletedNItems(int count) {
    return '$count개 항목을 삭제했습니다.';
  }

  @override
  String failedToDelete(String error) {
    return '삭제 실패: $error';
  }

  @override
  String failedToDeleteItem(String error) {
    return '삭제 실패: $error';
  }

  @override
  String deletedFilename(String filename) {
    return '\"$filename\"을(를) 삭제했습니다.';
  }

  @override
  String get failedToOpenFile => '파일을 열 수 없습니다';

  @override
  String fileDownloadFailed(String error) {
    return '파일 다운로드 실패: $error';
  }

  @override
  String get downloading => '다운로드 중...';

  @override
  String get downloadingFile => '파일 다운로드 중...';

  @override
  String downloadComplete(String filename) {
    return '다운로드 완료: $filename';
  }

  @override
  String downloadFailed(String error) {
    return '다운로드 실패: $error';
  }

  @override
  String get failedToDownloadPreview => '미리보기를 다운로드하지 못했습니다';

  @override
  String uploadComplete(String filename) {
    return '업로드 완료: $filename';
  }

  @override
  String uploadFailed(String error) {
    return '업로드 실패: $error';
  }

  @override
  String get failedToPickFiles => '파일을 선택하지 못했습니다';

  @override
  String uploadedNItems(int count) {
    return '파일 $count개를 업로드했습니다';
  }

  @override
  String get copiedLinkToClipboard => '링크를 클립보드에 복사했습니다.';

  @override
  String failedToCopyLink(String error) {
    return '링크 복사 실패: $error';
  }

  @override
  String get selectingAll => '모두 선택 중...';

  @override
  String get allItemsSelected => '모든 항목이 선택되었습니다.';

  @override
  String get failedToLoadSearchResults => '검색 결과를 로드하지 못했습니다';

  @override
  String get shareNotSupportedForType => '이 파일 형식은 공유를 지원하지 않습니다.';

  @override
  String nSelected(int count) {
    return '$count개 선택됨';
  }

  @override
  String get noServerSelected => '서버가 선택되지 않았습니다';

  @override
  String get pleaseConnectToServerFirst => '먼저 서버에 연결해 주세요.';

  @override
  String get signInRequired => '로그인 필요';

  @override
  String pleaseSignInToServer(String serverName) {
    return '먼저 $serverName에 로그인해 주세요.';
  }

  @override
  String get connectingToServer => '서버에 연결하는 중...';

  @override
  String connectedToServer(String serverName) {
    return '$serverName에 연결되었습니다.';
  }

  @override
  String connectionFailed(String error) {
    return '연결 실패: $error';
  }

  @override
  String failedToConnect(String error) {
    return '연결할 수 없습니다: $error';
  }

  @override
  String authFailed(String error) {
    return '인증 실패: $error';
  }

  @override
  String get authFailedGeneric => '인증에 실패했습니다. 다시 시도해 주세요.';

  @override
  String biometricLoginFailed(String error) {
    return '생체 인증 로그인 실패: $error';
  }

  @override
  String get biometricLoginFailedGeneric => '생체 인증 로그인 실패.';

  @override
  String get noServerSessionToken => '서버 세션 토큰이 없습니다. 서버 인증을 다시 시도해 주세요.';

  @override
  String failedToSaveServer(String error) {
    return '서버를 저장하지 못했습니다: $error';
  }

  @override
  String get addToFolder => '폴더에 추가';

  @override
  String get loginTabLabel => '로그인';

  @override
  String get registerTabLabel => '회원가입';

  @override
  String get welcomeBack => '다시 오신 것을 환영합니다';

  @override
  String get signInToContinue => '계속하려면 로그인하세요';

  @override
  String get createAccount => '계정 만들기';

  @override
  String get joinTheServer => '서버 가입하기';

  @override
  String get usernameLabel => '사용자 이름';

  @override
  String get usernameHint => '사용자 이름을 입력하세요';

  @override
  String get passwordLabel => '비밀번호';

  @override
  String get passwordHint => '비밀번호를 입력하세요';

  @override
  String get showPassword => '비밀번호 표시';

  @override
  String get hidePassword => '비밀번호 숨기기';

  @override
  String get confirmPassword => '비밀번호 확인';

  @override
  String get logIn => '로그인';

  @override
  String get loggingIn => '로그인 중...';

  @override
  String get registering => '가입 처리 중...';

  @override
  String get forgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get doNotHaveAccount => '계정이 없으신가요? 회원가입으로 전환.';

  @override
  String get alreadyHaveAccount => '이미 계정이 있으신가요? 로그인으로 전환.';

  @override
  String get usernameCannotBeEmpty => '사용자 이름을 입력해 주세요.';

  @override
  String get passwordCannotBeEmpty => '비밀번호를 입력해 주세요.';

  @override
  String get usernameInvalid => '사용자 이름은 3~32자의 영문, 숫자, _, -이어야 합니다.';

  @override
  String get passwordTooShort => '비밀번호는 최소 8자 이상이어야 합니다.';

  @override
  String loginFailed(String error) {
    return '로그인 실패: $error';
  }

  @override
  String registrationFailed(String error) {
    return '회원가입 실패: $error';
  }

  @override
  String get resetPasswordTitle => '비밀번호 재설정';

  @override
  String get enterResetCodeTitle => '재설정 코드 입력';

  @override
  String get resetPasswordStep1Body =>
      '사용자 이름을 입력하세요. 6자리 확인 코드가 서버 로그/콘솔에 출력됩니다.';

  @override
  String get resetPasswordStep2Body =>
      '확인 코드가 서버 콘솔에 출력되었습니다. 6자리 코드와 새 비밀번호를 입력하세요.';

  @override
  String get resetCodeLabel => '재설정 코드';

  @override
  String get resetCodeHint => '6자리 코드 입력';

  @override
  String get newPasswordLabel => '새 비밀번호';

  @override
  String get newPasswordHint => '새 비밀번호 입력';

  @override
  String get passwordResetSuccessfully => '비밀번호가 성공적으로 재설정되었습니다!';

  @override
  String get usernameIsRequired => '사용자 이름은 필수입니다.';

  @override
  String get codeAndPasswordRequired => '코드와 새 비밀번호를 모두 입력해야 합니다.';

  @override
  String get failedToRequestReset => '재설정 요청 실패. 서버 URL을 확인하세요.';

  @override
  String get failedToResetPassword => '비밀번호 재설정 실패. 코드를 확인하세요.';

  @override
  String get pleaseEnterServerUrlFirst => '먼저 서버 URL을 입력하세요.';

  @override
  String get sendCode => '코드 전송';

  @override
  String get settingsTitle => '설정';

  @override
  String get sectionBackupSync => '백업 및 동기화';

  @override
  String get sectionStorageCache => '저장소 및 캐시';

  @override
  String get sectionSecurityBehavior => '보안 및 동작';

  @override
  String get sectionAboutUpdates => '정보 및 업데이트';

  @override
  String get sectionAppearance => '모양 및 사용자 지정';

  @override
  String get noServersConfiguredSync => '구성된 서버 없음';

  @override
  String get addServerBeforeSync => '동기화를 구성하기 전에 서버를 추가하세요.';

  @override
  String get selectServerToConfigureSync => '동기화를 구성할 서버를 선택하세요.';

  @override
  String get activeServerSuffix => ' · 활성';

  @override
  String get folderAndCategorySync => '폴더 및 카테고리 동기화';

  @override
  String get keepCategoriesSynced => '선택한 로컬 카테고리 또는 폴더를 이 서버와 동기화된 상태로 유지합니다.';

  @override
  String get addServerBeforeSyncEnable => '동기화를 활성화하기 전에 서버를 추가하세요.';

  @override
  String get onlyOnWifi => 'Wi-Fi에서만';

  @override
  String get onlyWhileCharging => '충전 중에만';

  @override
  String get serverTargetDirectory => '서버 대상 디렉터리';

  @override
  String get serverTargetDirectoryHint => '/backup/mobile_phone';

  @override
  String get synchronizationFrequency => '동기화 주기';

  @override
  String get syncNow => '지금 동기화';

  @override
  String get syncing => '동기화 중...';

  @override
  String get categoriesToSynchronize => '동기화할 카테고리';

  @override
  String get noCategoriesSelected => '선택된 카테고리가 없습니다.';

  @override
  String nCategoriesSelected(int count) {
    return '$count개 선택됨';
  }

  @override
  String get foldersToSynchronize => '동기화할 폴더';

  @override
  String get noCustomFolders => '구성된 사용자 지정 폴더가 없습니다.';

  @override
  String nFolders(int count) {
    return '$count개 폴더';
  }

  @override
  String get addFolder => '폴더 추가';

  @override
  String get removeFolder => '폴더 제거';

  @override
  String get removeServer => '서버 삭제';

  @override
  String get syncFreqEvery15Min => '15분마다';

  @override
  String get syncFreqEvery30Min => '30분마다';

  @override
  String get syncFreqEvery1Hour => '1시간마다';

  @override
  String syncFreqEveryNHours(int hours) {
    return '$hours시간마다';
  }

  @override
  String syncFreqEveryNMin(int minutes) {
    return '$minutes분마다';
  }

  @override
  String get syncFreqDaily => '매일';

  @override
  String get chooseSyncFrequencyTitle => '동기화 주기 선택';

  @override
  String get cacheSize => '캐시 크기';

  @override
  String get refreshTooltip => '새로고침';

  @override
  String get cacheLimit => '캐시 한도';

  @override
  String get downloadPath => '다운로드 경로';

  @override
  String get defaultDownloadFolder => '기본 CrowleysCloud 폴더';

  @override
  String get clearCache => '캐시 지우기';

  @override
  String get clearCacheTitle => '캐시를 지울까요?';

  @override
  String get clearCacheBody => '로컬 미리보기 이미지와 캐시된 서버 목록을 삭제합니다.';

  @override
  String get downloadPathDialogTitle => '다운로드 경로';

  @override
  String get downloadPathHint => '/storage/emulated/0/CrowleysCloud';

  @override
  String get useDefault => '기본값 사용';

  @override
  String get serverTargetDirDialogTitle => '서버 대상 디렉터리';

  @override
  String get requireLogin => '로그인 요구';

  @override
  String get biometricLogin => '생체 인증 로그인';

  @override
  String get biometricLoginSubtitle => '생체 인증을 사용한 저장된 자격 증명 로그인을 허용합니다.';

  @override
  String get biometricsNotAvailable => '이 기기에서는 생체 인증을 사용할 수 없습니다.';

  @override
  String get showHiddenFiles => '숨김 파일 표시';

  @override
  String get showHiddenFilesSubtitle => '점(.)으로 시작하는 파일 및 폴더를 표시합니다.';

  @override
  String get changePassword => '비밀번호 변경';

  @override
  String changePasswordSubtitle(String serverName) {
    return '$serverName의 비밀번호를 변경합니다.';
  }

  @override
  String get addServerBeforeChangePassword => '비밀번호를 변경하기 전에 서버를 추가하세요.';

  @override
  String get deleteUserAccount => '사용자 계정 삭제';

  @override
  String get deleteUserAccountSubtitle => '사용자 및 모든 비공개 클라우드 파일을 삭제합니다.';

  @override
  String get deleteAccountTitle => '계정을 삭제하시겠습니까?';

  @override
  String deleteAccountBody(String serverName) {
    return '이 작업은 $serverName의 계정을 영구적으로 삭제하고 비공개 클라우드 폴더에 저장된 모든 파일을 제거합니다. 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get deleteAccountButton => '계정 삭제';

  @override
  String get changePasswordDialogTitle => '비밀번호 변경';

  @override
  String get newPasswordFieldLabel => '새 비밀번호';

  @override
  String get confirmPasswordLabel => '비밀번호 확인';

  @override
  String get enterNewPassword => '새 비밀번호를 입력하세요.';

  @override
  String get passwordUpdated => '비밀번호가 변경되었습니다.';

  @override
  String passwordChangeFailed(String error) {
    return '비밀번호 변경 실패: $error';
  }

  @override
  String get passwordChangeFailedGeneric => '비밀번호 변경에 실패했습니다.';

  @override
  String get accountDeleted => '계정이 삭제되었습니다.';

  @override
  String accountDeletionFailed(String error) {
    return '계정 삭제 실패: $error';
  }

  @override
  String get accountDeletionFailedGeneric => '계정 삭제에 실패했습니다.';

  @override
  String get checkForUpdates => '업데이트 확인';

  @override
  String get checkingForUpdates => 'GitHub 릴리스 확인 중...';

  @override
  String versionLabel(String version) {
    return '버전 $version';
  }

  @override
  String appIsUpToDate(String version) {
    return 'Crowley\'s Cloud가 최신 버전입니다 (v$version).';
  }

  @override
  String get updateCheckFailed => '업데이트 확인에 실패했습니다. 나중에 다시 시도해 주세요.';

  @override
  String get themeModeTitle => '테마 모드';

  @override
  String get themeDark => '다크';

  @override
  String get themeLight => '라이트';

  @override
  String get themeCustom => '사용자 지정';

  @override
  String get themeDarkFull => '다크 테마';

  @override
  String get themeLightFull => '라이트 테마';

  @override
  String get themeCustomFull => '사용자 지정 테마';

  @override
  String get accentColor => '강조 색상';

  @override
  String get primaryAccentColor => '기본 강조 색상';

  @override
  String get selectAccentColor => '강조 색상 선택';

  @override
  String get backgroundColor => '배경 색상';

  @override
  String get surfaceColor => '표면 색상';

  @override
  String get textColor => '텍스트 색상';

  @override
  String get subtextColor => '보조 텍스트 색상';

  @override
  String get borderColor => '테두리 색상';

  @override
  String get fontSizeScale => '글꼴 크기 배율';

  @override
  String selectColor(String title) {
    return '$title 선택';
  }

  @override
  String get categoriesToSyncDialogTitle => '동기화할 카테고리';

  @override
  String get categoriesToSyncBody => '하나 이상의 카테고리를 선택하세요. 모두 선택 해제할 수도 있습니다.';

  @override
  String get syncCategorySectionMedia => '미디어';

  @override
  String get syncCategorySectionAudioDocs => '오디오 및 문서';

  @override
  String get syncCategorySectionOther => '기타';

  @override
  String get clearAll => '모두 지우기';

  @override
  String get noSyncHasRunYet => '아직 실행된 동기화가 없습니다.';

  @override
  String lastRunAt(String date) {
    return '마지막 실행: $date';
  }

  @override
  String syncResultSuccess(int uploaded, int skipped) {
    return '$uploaded개 항목 동기화됨, $skipped개 건너뜀.';
  }

  @override
  String get syncResultNoFiles => '동기화할 파일이 선택되지 않았습니다.';

  @override
  String syncResultPartial(int uploaded, int failed) {
    return '$uploaded개 동기화됨, $failed개 실패.';
  }

  @override
  String get syncResultAuthRequired => '동기화 전에 로그인하세요.';

  @override
  String get syncResultUnreachable => '서버에 연결할 수 없습니다. 연결이 끊어졌습니다.';

  @override
  String get syncResultFailed => '동기화 실패.';

  @override
  String get serverSetupAddServer => '서버 추가';

  @override
  String get serverSetupCardTitle => '서버 연결';

  @override
  String get serverSetupCardSubtitle => '홈 파일 서버를 추가하고 로그인하세요.';

  @override
  String get serverSetupSubmitButton => '서버 저장';

  @override
  String get serverNameLabel => '서버 이름';

  @override
  String get serverNameHint => '홈 NAS';

  @override
  String get baseUrlLabel => '기본 URL';

  @override
  String get baseUrlHint => 'https://cloud.example.com';

  @override
  String get allFieldsRequired => '모든 필드는 필수 항목입니다.';

  @override
  String get localFilesTitle => '로컬 파일';

  @override
  String get serverFilesTitle => '서버 파일';

  @override
  String get restoreItemsTitle => '항목 복원';

  @override
  String restoreItemsBody(int count) {
    return '$count개 항목을 복원하시겠습니까?';
  }

  @override
  String get permanentlyDeleteTitle => '영구 삭제';

  @override
  String permanentlyDeleteBody(int count) {
    return '$count개 항목을 영구 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get trashIsEmpty => '휴지통이 비어 있습니다.';

  @override
  String trashRetentionInfo(int days) {
    return '휴지통의 항목은 $days일 후 자동으로 삭제됩니다.';
  }

  @override
  String get deletionDate => '삭제 날짜';

  @override
  String get deletePermanentlyAction => '영구 삭제';

  @override
  String get conflictFileAlreadyExists => '파일이 이미 존재합니다';

  @override
  String conflictNofM(int current, int total) {
    return '충돌 $current / $total';
  }

  @override
  String get conflictAFileNamed => '이름이 \"';

  @override
  String get conflictAlreadyExistsAt => '\"인 파일이 이미 다음 위치에 있습니다: ';

  @override
  String get conflictAlreadyExistsInFolder => '\"인 파일이 이 폴더에 이미 존재합니다.';

  @override
  String get conflictInFolder => '폴더 내부';

  @override
  String get conflictFromTrash => '휴지통에서';

  @override
  String get conflictExisting => '기존 파일';

  @override
  String get conflictNewUpload => '새 업로드';

  @override
  String conflictSizeLabel(String size) {
    return '크기: $size';
  }

  @override
  String conflictDateLabel(String date) {
    return '날짜: $date';
  }

  @override
  String conflictDeletedLabel(String date) {
    return '삭제 날짜: $date';
  }

  @override
  String conflictApplyToRemaining(int count) {
    return '남은 충돌 $count개에 적용';
  }

  @override
  String get conflictKeepAllCopies => '모든 사본 유지';

  @override
  String get conflictOverwriteAll => '모두 덮어쓰기';

  @override
  String get conflictRestoreAllAsCopies => '모두 사본으로 복원';

  @override
  String get conflictRestoreAsCopy => '사본으로 복원';

  @override
  String get conflictOverwriteAllRemaining => '남은 항목 모두 덮어쓰기';

  @override
  String get conflictSkipAll => '모두 건너뛰기';

  @override
  String get conflictSkipAllRemaining => '남은 항목 모두 건너뛰기';

  @override
  String get conflictSkip => '건너뛰기';

  @override
  String get conflictOverwrite => '덮어쓰기';

  @override
  String get transfersTitle => '전송';

  @override
  String get transferResume => '재개';

  @override
  String get transferPause => '일시 중지';

  @override
  String get transferCancel => '취소';

  @override
  String get transferResumeAll => '모두 재개';

  @override
  String get transferPauseAll => '모두 일시 중지';

  @override
  String get transferCancelAll => '모두 취소';

  @override
  String get transferCancelFile => '파일 취소';

  @override
  String get noTransfers => '전송 항목이 없습니다.';

  @override
  String get transferStatusQueued => '대기 중';

  @override
  String get transferStatusRunning => '진행 중';

  @override
  String get transferStatusPaused => '일시 중지됨';

  @override
  String get transferStatusCompleted => '완료됨';

  @override
  String get transferStatusFailed => '실패';

  @override
  String get transferStatusCanceled => '취소됨';

  @override
  String get themePresetsSection => '프리셋';

  @override
  String get themeCustomPaletteSection => '사용자 지정 팔레트';

  @override
  String get themeHexRgbLabel => 'HEX RGB 코드';

  @override
  String get themeHexRgbHint => '#FA5252';

  @override
  String get imageViewerNoFetchHandler => '이미지 가져오기 핸들러가 설정되지 않았습니다';

  @override
  String get imageViewerFailedToLoad => '이미지를 로드하지 못했습니다';

  @override
  String errorDeletingFile(String filename, String error) {
    return '\"$filename\" 삭제 실패: $error';
  }

  @override
  String errorReadingFile(String error) {
    return '파일 읽기 실패: $error';
  }

  @override
  String get syncChannelName => '백그라운드 동기화';

  @override
  String get syncChannelDescription => '백그라운드 파일 동기화 상태를 표시합니다.';

  @override
  String get storageStatsTitle => '저장소 통계';

  @override
  String get storageStatsUsedSpace => '사용된 공간';

  @override
  String get storageStatsTotalFiles => '총 파일 수';

  @override
  String storageStatsNItems(int count) {
    return '$count개 항목';
  }

  @override
  String userFallback(int userId) {
    return '사용자 #$userId';
  }

  @override
  String get biometricUnlockReason =>
      'Crowley\'s Cloud에 저장된 자격 증명을 잠금 해제하려면 인증하세요.';

  @override
  String get tokenLifetimeEveryOpen => '앱을 열 때마다';

  @override
  String get tokenLifetimeOneHour => '1시간 후';

  @override
  String get tokenLifetime1Hour => '1시간 후';

  @override
  String get tokenLifetimeOneDay => '1일 후';

  @override
  String get tokenLifetime1Day => '1일 후';

  @override
  String get tokenLifetimeOneWeek => '1주일 후';

  @override
  String get tokenLifetime1Week => '1주일 후';

  @override
  String get tokenLifetimeOneMonth => '1개월 후';

  @override
  String get tokenLifetime1Month => '1개월 후';

  @override
  String get tokenLifetimeThreeMonths => '3개월 후';

  @override
  String get tokenLifetime3Months => '3개월 후';

  @override
  String get tokenLifetimeNever => '이 기기에서는 만료 없음';

  @override
  String get cacheLimitUnlimited => '무제한';

  @override
  String get syncCategoryOtherFiles => '기타 파일';

  @override
  String get internalStorage => '내부 저장소';

  @override
  String get localStorageRootName => '내부 저장소';

  @override
  String syncNotificationSyncingWith(String serverName) {
    return '$serverName와(과) 동기화 중';
  }

  @override
  String syncNotificationPausedTitle(String serverName) {
    return '$serverName와의 동기화 일시 중지됨';
  }

  @override
  String get syncNotificationUnreachableBody =>
      '서버에 연결할 수 없습니다. 앱을 열 때까지 백그라운드 동기화가 일시 중지됩니다.';

  @override
  String get syncNotificationAuthRequiredBody => '인증이 필요합니다. 앱을 열어 로그인하세요.';

  @override
  String syncNotificationFailedTitle(String serverName) {
    return '$serverName와의 동기화 실패';
  }

  @override
  String get syncNotificationGenericErrorBody => '동기화 중 오류가 발생했습니다.';

  @override
  String syncNotificationCompleteTitle(String serverName) {
    return '$serverName와의 동기화 완료';
  }

  @override
  String get syncNotificationCompleteBody => '동기화가 완료되었습니다.';

  @override
  String get syncStatusConnecting => '서버에 연결하는 중...';

  @override
  String syncStatusConnectionLost(String serverName) {
    return '$serverName에 연결할 수 없습니다. 연결이 끊어졌습니다.';
  }

  @override
  String syncResultServerUnreachableWithServer(String serverName) {
    return '$serverName에 연결할 수 없습니다. 연결이 끊어졌습니다.';
  }

  @override
  String get syncStatusScanningFiles => '기기의 파일 검색 중...';

  @override
  String get syncStatusNoFilesFound => '동기화할 파일을 찾을 수 없습니다.';

  @override
  String get syncStatusNoFilesSelected => '동기화할 파일이 선택되지 않았습니다.';

  @override
  String syncStatusCalculatingChecksum(
    int current,
    int total,
    String filename,
  ) {
    return '체크섬 계산 중 ($current/$total): $filename';
  }

  @override
  String get syncStatusCheckingDuplicates => '서버의 중복 파일 확인 중...';

  @override
  String syncStatusSyncingFile(int current, int total, String filename) {
    return '동기화 중 ($current/$total): $filename';
  }

  @override
  String get syncStatusCompleting => '동기화 완료 중...';

  @override
  String get showingCachedFiles => '캐시된 파일을 표시하고 있습니다.';

  @override
  String get showingCachedFilesRefreshFailed => '캐시된 파일을 표시하고 있습니다. 새로고침 실패.';

  @override
  String get downloadCanceled => '다운로드가 취소되었습니다.';

  @override
  String downloadedNFilesToPath(int count, String path) {
    return '$path(으)로 파일 $count개를 다운로드했습니다';
  }

  @override
  String downloadedNFilesFailedM(int downloaded, int failed, String detail) {
    return '파일 $downloaded개를 다운로드했습니다($failed개 실패: $detail)';
  }

  @override
  String downloadedNFilesWithFailures(int count, int failed, String error) {
    return '파일 $count개를 다운로드했습니다($failed개 실패: $error)';
  }

  @override
  String createdNShareLinks(int count) {
    return '공유 링크 $count개를 만들었습니다.';
  }

  @override
  String get failedToCreateShareLinks => '공유 링크를 만들지 못했습니다.';

  @override
  String get alreadyInSharedScope => '이미 공유 범위에 있습니다.';

  @override
  String sharedNItemsInServer(int count) {
    return '서버에서 항목 $count개를 공유했습니다.';
  }

  @override
  String sharedNItemsWithFailures(int count, int failed) {
    return '항목 $count개를 공유했습니다($failed개 실패).';
  }

  @override
  String sharedNItemsFailedM(int shared, int failed) {
    return '항목 $shared개를 공유했습니다($failed개 실패).';
  }

  @override
  String get folderNameCannotBeEmpty => '폴더 이름은 비워둘 수 없습니다.';

  @override
  String get folderAlreadyExists => '같은 이름의 폴더가 이미 존재합니다.';

  @override
  String get folderCreationOnlyInAllFiles => '폴더 생성은 \'모든 파일\'에서만 가능합니다.';

  @override
  String get currentDirectoryUnavailable => '현재 디렉터리를 사용할 수 없습니다.';

  @override
  String get nothingSelected => '선택된 항목이 없습니다.';

  @override
  String get destinationFolderDoesNotExist => '대상 폴더가 존재하지 않습니다.';

  @override
  String cannotMoveFolderIntoItself(String name) {
    return '폴더 \"$name\"을(를) 자기 자신 내부로 이동할 수 없습니다.';
  }

  @override
  String failedToMoveItem(String name, String error) {
    return '\"$name\" 이동 실패: $error';
  }

  @override
  String movedNItems(int count) {
    return '$count개 항목을 이동했습니다.';
  }

  @override
  String movedNItemsWithFailures(int count, int failed) {
    return '$count개 항목을 이동했습니다($failed개 실패).';
  }

  @override
  String movedNItemsFailedM(int moved, int failed) {
    return '$moved개 항목을 이동했습니다($failed개 실패).';
  }

  @override
  String get failedToMoveSelectedItems => '선택한 항목을 이동하지 못했습니다.';

  @override
  String get noFilesWereMoved => '이동된 파일이 없습니다.';

  @override
  String renamedOldToNew(String oldName, String newName) {
    return '\"$oldName\"의 이름을 \"$newName\"(으)로 변경했습니다.';
  }

  @override
  String renamedFileFromTo(String oldName, String newName) {
    return '\"$oldName\"의 이름을 \"$newName\"(으)로 변경했습니다.';
  }

  @override
  String failedToRenameWithStatus(String name, int statusCode) {
    return '\"$name\" 이름 변경 실패 ($statusCode).';
  }

  @override
  String failedToRenameFileWithCode(String name, int statusCode) {
    return '\"$name\" 이름 변경 실패 ($statusCode).';
  }

  @override
  String failedToRenameWithError(String name, String error) {
    return '\"$name\" 이름 변경 실패: $error';
  }

  @override
  String failedToRenameFile(String name, String error) {
    return '\"$name\" 이름 변경 실패: $error';
  }

  @override
  String get renameConflictAlreadyExists =>
      '이름 변경 실패: 동일한 이름의 파일 또는 폴더가 이미 존재합니다.';

  @override
  String get renameFailedAlreadyExists =>
      '이름 변경 실패: 동일한 이름의 파일 또는 폴더가 이미 존재합니다.';

  @override
  String failedToCreateFolderWithCode(int statusCode) {
    return '폴더 생성 실패 (코드 $statusCode).';
  }

  @override
  String deletedNItemsFailedM(int deleted, int failed) {
    return '$deleted개 항목을 삭제했습니다($failed개 실패).';
  }

  @override
  String transferSummaryFiles(int percent, int completed, int total) {
    return '$percent%  $completed/$total개 파일';
  }

  @override
  String transferSummaryProgress(int percent, int completed, int total) {
    return '$percent%  $completed/$total개 파일';
  }

  @override
  String get downloadFailedGeneric => '다운로드 실패';

  @override
  String uploadedNItemsWithFailures(int uploaded, int failed) {
    return '$uploaded개 항목을 업로드했습니다($failed개 실패)';
  }

  @override
  String uploadedNItemsFailedM(int uploaded, int failed) {
    return '$uploaded개 항목을 업로드했습니다($failed개 실패).';
  }

  @override
  String uploadSummaryFailedCount(int count) {
    return ', $count개 실패';
  }

  @override
  String uploadLocalPathEmpty(String name) {
    return '$name: 로컬 경로가 비어 있습니다';
  }

  @override
  String uploadErrorLocalPathEmpty(String name) {
    return '$name: 로컬 경로가 비어 있습니다';
  }

  @override
  String get directoryUploadFailed => '디렉터리 업로드 실패';

  @override
  String get uploadDirectoryFailed => '디렉터리 업로드 실패';

  @override
  String get localFileNotFound => '로컬 파일을 찾을 수 없습니다';

  @override
  String get uploadErrorLocalFileNotFound => '로컬 파일을 찾을 수 없습니다';

  @override
  String get noSessionToken => '활성 세션 토큰이 없습니다';

  @override
  String get uploadErrorNoSessionToken => '활성 세션 토큰이 없습니다';

  @override
  String get serverDisconnectedStatus => '서버 연결 끊김';

  @override
  String get serverDisconnected => '서버 연결 끊김';

  @override
  String get serverIsUnreachable => '서버에 연결할 수 없습니다.';

  @override
  String get serverUnreachable => '서버에 연결할 수 없습니다.';

  @override
  String get uploadErrorLocalDirectoryNotFound => '로컬 디렉터리를 찾을 수 없습니다';

  @override
  String get uploadErrorFailedToScanDirectory => '디렉터리 검색 실패';

  @override
  String uploadErrorFolderCreateHttp(int statusCode) {
    return '폴더 생성 실패 (HTTP $statusCode)';
  }

  @override
  String get authErrorMissingAccessToken => '응답에 액세스 토큰이 없습니다';

  @override
  String get authErrorMissingRefreshToken => '응답에 리프레시 토큰이 없습니다';

  @override
  String get authErrorNoSavedCredentials => '사용 가능한 저장된 자격 증명이 없습니다';

  @override
  String get authErrorNoRefreshToken => '사용 가능한 리프레시 토큰이 없습니다';

  @override
  String get authErrorNoActiveSession => '사용 가능한 활성 세션이 없습니다';

  @override
  String get authErrorNoSavedUsername => '저장된 사용자 이름이 없습니다';

  @override
  String get updateNoReleasesPublished => '아직 게시된 릴리스가 없습니다.';

  @override
  String get language => '언어';
}
