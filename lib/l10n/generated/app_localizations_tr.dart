// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Crowley\'s Cloud';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'İptal';

  @override
  String get save => 'Kaydet';

  @override
  String get delete => 'Sil';

  @override
  String get rename => 'Yeniden adlandır';

  @override
  String get close => 'Kapat';

  @override
  String get retry => 'Yeniden dene';

  @override
  String get loading => 'Yükleniyor...';

  @override
  String get confirm => 'Onayla';

  @override
  String get error => 'Hata';

  @override
  String errorWithMessage(String message) {
    return 'Hata: $message';
  }

  @override
  String get unknown => 'Bilinmiyor';

  @override
  String get upload => 'Karşıya yükle';

  @override
  String get download => 'İndir';

  @override
  String get share => 'Paylaş';

  @override
  String get copy => 'Kopyala';

  @override
  String get move => 'Taşı';

  @override
  String get restore => 'Geri yükle';

  @override
  String get apply => 'Uygula';

  @override
  String get create => 'Oluştur';

  @override
  String get clear => 'Temizle';

  @override
  String get add => 'Ekle';

  @override
  String get remove => 'Kaldır';

  @override
  String get edit => 'Düzenle';

  @override
  String get switchLabel => 'Değiştir';

  @override
  String get search => 'Ara';

  @override
  String get name => 'Ad';

  @override
  String get date => 'Tarih';

  @override
  String get size => 'Boyut';

  @override
  String get type => 'Tür';

  @override
  String get ascending => 'Artan';

  @override
  String get descending => 'Azalan';

  @override
  String get allFiles => 'Tümü';

  @override
  String get categoryImages => 'Görseller';

  @override
  String get categoryPhotos => 'Fotoğraflar';

  @override
  String get categoryVideos => 'Videolar';

  @override
  String get categoryAudio => 'Ses';

  @override
  String get categoryDocuments => 'Belgeler';

  @override
  String get categoryArchives => 'Arşivler';

  @override
  String get categoryShared => 'Paylaşılanlar';

  @override
  String get categoryOther => 'Diğer';

  @override
  String get categoryOtherFiles => 'Diğer dosyalar';

  @override
  String get noFilesFound => 'Dosya bulunamadı.';

  @override
  String get noFilesInFolder => 'Bu klasörde dosya yok.';

  @override
  String get thisActionCannotBeUndone => 'Bu işlem geri alınamaz.';

  @override
  String get passwordsDoNotMatch => 'Şifreler eşleşmiyor.';

  @override
  String get navLocalFiles => 'Yerel Dosyalar';

  @override
  String get navServerFiles => 'Sunucu Dosyaları';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get navTrash => 'Çöp Kutusu';

  @override
  String get navLocal => 'Yerel';

  @override
  String get navServer => 'Sunucu';

  @override
  String get addServer => 'Sunucu Ekle';

  @override
  String get noServersConfigured => 'Yapılandırılmış sunucu yok.';

  @override
  String get addAServerInSettings => 'Ayarlar bölümünden bir sunucu ekleyin.';

  @override
  String get addFirstServerHint => 'Devam etmek için ilk sunucunuzu ekleyin.';

  @override
  String get noServersConfiguredYet => 'Henüz yapılandırılmış bir sunucu yok.';

  @override
  String get crowleysCloudSetup => 'Crowley\'s Cloud kurulumu';

  @override
  String get connect => 'Bağlan';

  @override
  String get connecting => 'Bağlanıyor...';

  @override
  String get connected => 'Bağlandı';

  @override
  String get disconnected => 'Bağlantı kesildi';

  @override
  String get switchServer => 'Sunucu Değiştir';

  @override
  String get chooseOtherServer => 'Başka bir sunucu seç';

  @override
  String get switchServerTitle => 'Sunucu değiştirilsin mi?';

  @override
  String switchServerBody(String serverName) {
    return 'Etkin sunucu \"$serverName\" olarak değiştirilsin mi?';
  }

  @override
  String get chooseServer => 'Sunucu seçin';

  @override
  String get authenticationRequired => 'Kimlik doğrulaması gerekli';

  @override
  String signInToAccess(String serverName) {
    return '$serverName üzerindeki dosyalara erişmek için oturum açın';
  }

  @override
  String get signInWithPassword => 'Şifre ile Oturum Aç';

  @override
  String get useBiometrics => 'Biyometriyi Kullan';

  @override
  String get openingSignIn => 'Giriş açılıyor...';

  @override
  String get serverConnectionFailed => 'Sunucu bağlantısı başarısız';

  @override
  String get unableToConnectToServer => 'Etkin sunucuya bağlanılamıyor.';

  @override
  String unableToConnectTo(String serverName) {
    return '$serverName sunucusuna bağlanılamıyor.';
  }

  @override
  String get searchHint => 'Ara...';

  @override
  String get searchFilesHint => 'Dosyaları ara...';

  @override
  String get searchServerFilesHint => 'Sunucu dosyalarını ara...';

  @override
  String get searchTrashHint => 'Çöp kutusunda ara...';

  @override
  String get storagePermissionRequired => 'Depolama izni gerekli';

  @override
  String get grantPermission => 'İzin Ver';

  @override
  String get permissionDeniedOpenSettings =>
      'İzin reddedildi. Lütfen Ayarlar\'dan depolama erişimine izin verin.';

  @override
  String get manageStoragePermissionRequired =>
      'Klasörlere göz atmak ve seçmek için Depolamayı Yönet izni gereklidir.';

  @override
  String get storagePermissionsRequired =>
      'Eşitleme yapabilmek için depolama izinleri gereklidir.';

  @override
  String updateAvailableTitle(String version) {
    return 'Güncelleme mevcut: v$version';
  }

  @override
  String get updateAvailableTapToSeeNew => 'Yenilikleri görmek için dokunun';

  @override
  String get updateView => 'Görüntüle';

  @override
  String get updateAvailableDialogTitle => 'Güncelleme Mevcut';

  @override
  String updateVersionSubtitle(String version) {
    return 'Sürüm $version';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'Geçerli: v$version';
  }

  @override
  String updateNewVersion(String version) {
    return 'Yeni: v$version';
  }

  @override
  String get updateWhatsNew => 'Yenilikler:';

  @override
  String get updateGitHub => 'GitHub';

  @override
  String get updateNoReleaseNotes => 'Sürüm notu bulunmuyor.';

  @override
  String get updateLater => 'Daha Sonra';

  @override
  String get updateDownloadApk => 'APK İndir';

  @override
  String get updateInstall => 'Güncelle';

  @override
  String get shareLinkTitle => 'Bağlantıyı Paylaş';

  @override
  String get shareViaLink => 'Bağlantı ile paylaş';

  @override
  String get shareInServer => 'Sunucuda paylaş';

  @override
  String get expiryDays => 'Geçerlilik (gün)';

  @override
  String get expiryNever => 'Asla';

  @override
  String get expiry1Day => '1 gün';

  @override
  String get expiry7Days => '7 gün';

  @override
  String get expiry30Days => '30 gün';

  @override
  String get expiry90Days => '90 gün';

  @override
  String get expiry180Days => '180 gün';

  @override
  String get expiry365Days => '365 gün';

  @override
  String get createLink => 'Bağlantı Oluştur';

  @override
  String get sharedLinkCopied => 'Paylaşım bağlantısı panoya kopyalandı!';

  @override
  String failedToCopySharedLink(String error) {
    return 'Paylaşım bağlantısı kopyalanamadı: $error';
  }

  @override
  String get cannotShareThisFileType => 'Bu dosya türü paylaşılamaz.';

  @override
  String failedToCreateShare(String error) {
    return 'Paylaşım oluşturulamadı: $error';
  }

  @override
  String get newFolderTitle => 'Klasör Oluştur';

  @override
  String get newFolderHint => 'Klasör adı';

  @override
  String get newFolder => 'Yeni klasör';

  @override
  String get folderCreated => 'Klasör oluşturuldu.';

  @override
  String failedToCreateFolder(String error) {
    return 'Klasör oluşturulamadı: $error';
  }

  @override
  String get creatingFolder => 'Klasör oluşturuluyor...';

  @override
  String get renameDialogTitle => 'Yeniden Adlandır';

  @override
  String get renameHint => 'Yeni ad';

  @override
  String get enterNewName => 'Yeni adı girin';

  @override
  String get renamedSuccessfully => 'Başarıyla yeniden adlandırıldı.';

  @override
  String renameFailed(String error) {
    return 'Yeniden adlandırma başarısız: $error';
  }

  @override
  String get moveDialogTitle => 'Şuraya taşı';

  @override
  String moveTo(String path) {
    return 'Şuraya taşı: $path';
  }

  @override
  String get moveHere => 'Buraya Taşı';

  @override
  String moveFailed(String error) {
    return 'Taşıma başarısız: $error';
  }

  @override
  String get movedToFolder => 'Klasöre taşındı.';

  @override
  String copyFailed(String error) {
    return 'Kopyalama başarısız: $error';
  }

  @override
  String get selectFolder => 'Klasör Seç';

  @override
  String get useThisFolder => 'Bu klasörü kullan';

  @override
  String get storageRoot => 'Depolama';

  @override
  String get serverRoot => 'kök';

  @override
  String deleteNItemsTitle(int count) {
    return '$count öğe silinsin mi?';
  }

  @override
  String get deleteFilesTitle => 'Dosyalar Silinsin mi?';

  @override
  String deleteFilesBody(int count) {
    return '$count seçili öğeyi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.';
  }

  @override
  String get deletePermanently => 'Kalıcı Olarak Sil';

  @override
  String get deletePermanentlyTitle => 'Kalıcı Olarak Silinsin mi?';

  @override
  String deletePermanentlyBody(String filename) {
    return '$filename kalıcı olarak silinecek.';
  }

  @override
  String get deleteFileTitle => 'Dosya Silinsin mi?';

  @override
  String deleteFileBody(String filename) {
    return '$filename dosyasını silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.';
  }

  @override
  String get deleteServerFileTitle => 'Kalıcı Olarak Sil';

  @override
  String deleteServerFileBody(String filename) {
    return '\"$filename\" dosyasını kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.';
  }

  @override
  String get unshareItemsTitle => 'Öğelerin Paylaşımı Kaldırılsın mı?';

  @override
  String unshareItemsBody(int count) {
    return '$count seçili öğenin paylaşımını kaldırmak istediğinizden emin misiniz? Bu işlem onları Paylaşılanlar klasöründen kaldıracaktır.';
  }

  @override
  String get unshare => 'Paylaşımı Kaldır';

  @override
  String get moveToTrash => 'Çöp Kutusuna Taşı';

  @override
  String get movedToTrash => 'Çöp kutusuna taşındı.';

  @override
  String movedNItemsToTrash(int count) {
    return '$count öğe çöp kutusuna taşındı.';
  }

  @override
  String failedToMoveToTrash(String error) {
    return 'Çöp kutusuna taşınamadı: $error';
  }

  @override
  String deletedNItems(int count) {
    return '$count öğe silindi.';
  }

  @override
  String failedToDelete(String error) {
    return 'Silinemedi: $error';
  }

  @override
  String failedToDeleteItem(String error) {
    return 'Silme başarısız: $error';
  }

  @override
  String deletedFilename(String filename) {
    return '$filename silindi.';
  }

  @override
  String get failedToOpenFile => 'Dosya açılamadı';

  @override
  String fileDownloadFailed(String error) {
    return 'Dosya indirme başarısız: $error';
  }

  @override
  String get downloading => 'İndiriliyor...';

  @override
  String get downloadingFile => 'Dosya indiriliyor...';

  @override
  String downloadComplete(String filename) {
    return 'İndirme tamamlandı: $filename';
  }

  @override
  String downloadFailed(String error) {
    return 'İndirme başarısız: $error';
  }

  @override
  String get failedToDownloadPreview => 'Dosya önizlemesi indirilemedi';

  @override
  String uploadComplete(String filename) {
    return 'Yükleme tamamlandı: $filename';
  }

  @override
  String uploadFailed(String error) {
    return 'Yükleme başarısız: $error';
  }

  @override
  String get failedToPickFiles => 'Dosyalar seçilemedi';

  @override
  String uploadedNItems(int count) {
    return '$count öğe yüklendi';
  }

  @override
  String get copiedLinkToClipboard => 'Bağlantı panoya kopyalandı.';

  @override
  String failedToCopyLink(String error) {
    return 'Bağlantı kopyalanamadı: $error';
  }

  @override
  String get selectingAll => 'Tümü seçiliyor...';

  @override
  String get allItemsSelected => 'Tüm öğeler seçildi.';

  @override
  String get failedToLoadSearchResults => 'Arama sonuçları yüklenemedi';

  @override
  String get shareNotSupportedForType =>
      'Bu dosya türü için paylaşım desteklenmiyor.';

  @override
  String nSelected(int count) {
    return '$count seçildi';
  }

  @override
  String get noServerSelected => 'Sunucu seçilmedi';

  @override
  String get pleaseConnectToServerFirst => 'Lütfen önce bir sunucuya bağlanın.';

  @override
  String get signInRequired => 'Oturum açılması gerekli';

  @override
  String pleaseSignInToServer(String serverName) {
    return 'Lütfen önce \"$serverName\" sunucusunda oturum açın.';
  }

  @override
  String get connectingToServer => 'Sunucuya bağlanılıyor...';

  @override
  String connectedToServer(String serverName) {
    return '$serverName sunucusuna bağlandı.';
  }

  @override
  String connectionFailed(String error) {
    return 'Bağlantı başarısız: $error';
  }

  @override
  String failedToConnect(String error) {
    return 'Bağlanılamadı: $error';
  }

  @override
  String authFailed(String error) {
    return 'Kimlik doğrulama başarısız: $error';
  }

  @override
  String get authFailedGeneric =>
      'Kimlik doğrulama başarısız oldu. Lütfen tekrar deneyin.';

  @override
  String biometricLoginFailed(String error) {
    return 'Biyometrik giriş başarısız: $error';
  }

  @override
  String get biometricLoginFailedGeneric => 'Biyometrik giriş başarısız.';

  @override
  String get noServerSessionToken =>
      'Sunucu oturum belirteci yok. Sunucuyu yeniden doğrulayın.';

  @override
  String failedToSaveServer(String error) {
    return 'Sunucu kaydedilemedi: $error';
  }

  @override
  String get addToFolder => 'Klasöre ekle';

  @override
  String get loginTabLabel => 'Giriş Yap';

  @override
  String get registerTabLabel => 'Kayıt Ol';

  @override
  String get welcomeBack => 'Tekrar Hoş Geldiniz';

  @override
  String get signInToContinue => 'Devam etmek için oturum açın';

  @override
  String get createAccount => 'Hesap Oluştur';

  @override
  String get joinTheServer => 'Sunucuya katılın';

  @override
  String get usernameLabel => 'Kullanıcı adı';

  @override
  String get usernameHint => 'Kullanıcı adınızı girin';

  @override
  String get passwordLabel => 'Şifre';

  @override
  String get passwordHint => 'Şifrenizi girin';

  @override
  String get showPassword => 'Şifreyi göster';

  @override
  String get hidePassword => 'Şifreyi gizle';

  @override
  String get confirmPassword => 'Şifreyi Onayla';

  @override
  String get logIn => 'Giriş Yap';

  @override
  String get loggingIn => 'Giriş yapılıyor...';

  @override
  String get registering => 'Kayıt olunuyor...';

  @override
  String get forgotPassword => 'Şifrenizi mi unuttunuz?';

  @override
  String get doNotHaveAccount => 'Hesabınız yok mu? Kayıt Ol sekmesine geçin.';

  @override
  String get alreadyHaveAccount =>
      'Zaten bir hesabınız var mı? Giriş Yap sekmesine geçin.';

  @override
  String get usernameCannotBeEmpty => 'Kullanıcı adı boş bırakılamaz.';

  @override
  String get passwordCannotBeEmpty => 'Şifre boş bırakılamaz.';

  @override
  String get usernameInvalid =>
      'Kullanıcı adı 3–32 karakter olmalı; harf, rakam, _ veya - içerebilir.';

  @override
  String get passwordTooShort => 'Şifre en az 8 karakter olmalıdır.';

  @override
  String loginFailed(String error) {
    return 'Giriş başarısız: $error';
  }

  @override
  String registrationFailed(String error) {
    return 'Kayıt başarısız: $error';
  }

  @override
  String get resetPasswordTitle => 'Şifreyi Sıfırla';

  @override
  String get enterResetCodeTitle => 'Sıfırlama Kodunu Girin';

  @override
  String get resetPasswordStep1Body =>
      'Kullanıcı adınızı girin. 6 haneli doğrulama kodu sunucu günlüklerine/konsoluna yazdırılacaktır.';

  @override
  String get resetPasswordStep2Body =>
      'Doğrulama kodu sunucu konsoluna yazdırıldı. 6 haneli kodu ve yeni şifrenizi girin.';

  @override
  String get resetCodeLabel => 'Sıfırlama Kodu';

  @override
  String get resetCodeHint => '6 haneli kodu girin';

  @override
  String get newPasswordLabel => 'Yeni Şifre';

  @override
  String get newPasswordHint => 'Yeni şifrenizi girin';

  @override
  String get passwordResetSuccessfully => 'Şifre başarıyla sıfırlandı!';

  @override
  String get usernameIsRequired => 'Kullanıcı adı gereklidir.';

  @override
  String get codeAndPasswordRequired => 'Kod ve yeni şifre gereklidir.';

  @override
  String get failedToRequestReset =>
      'Sıfırlama isteği başarısız oldu. Sunucu URL\'sini kontrol edin.';

  @override
  String get failedToResetPassword =>
      'Şifre sıfırlanamadı. Lütfen kodu kontrol edin.';

  @override
  String get pleaseEnterServerUrlFirst =>
      'Lütfen önce bir sunucu URL\'si girin.';

  @override
  String get sendCode => 'Kodu Gönder';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get sectionBackupSync => 'Yedekleme ve Eşitleme';

  @override
  String get sectionStorageCache => 'Depolama ve Önbellek';

  @override
  String get sectionSecurityBehavior => 'Güvenlik ve Davranış';

  @override
  String get sectionAboutUpdates => 'Hakkında ve Güncellemeler';

  @override
  String get sectionAppearance => 'Görünüm ve Özelleştirme';

  @override
  String get noServersConfiguredSync => 'Yapılandırılmış sunucu yok';

  @override
  String get addServerBeforeSync =>
      'Eşitlemeyi yapılandırmadan önce bir sunucu ekleyin.';

  @override
  String get selectServerToConfigureSync =>
      'Eşitleme ayarlarını yapılandırmak için bir sunucu seçin.';

  @override
  String get activeServerSuffix => '· etkin';

  @override
  String get folderAndCategorySync => 'Klasör ve kategori eşitleme';

  @override
  String get keepCategoriesSynced =>
      'Seçili yerel kategorileri veya klasörleri bu sunucuyla eşit tutun.';

  @override
  String get addServerBeforeSyncEnable =>
      'Eşitlemeyi etkinleştirmeden önce bir sunucu ekleyin.';

  @override
  String get onlyOnWifi => 'Yalnızca Wi-Fi üzerinden';

  @override
  String get onlyWhileCharging => 'Yalnızca şarj olurken';

  @override
  String get serverTargetDirectory => 'Sunucu hedef dizini';

  @override
  String get serverTargetDirectoryHint => '/backup/mobile_phone';

  @override
  String get synchronizationFrequency => 'Eşitleme sıklığı';

  @override
  String get syncNow => 'Şimdi eşitle';

  @override
  String get syncing => 'Eşitleniyor...';

  @override
  String get categoriesToSynchronize => 'Eşitlenecek kategoriler';

  @override
  String get noCategoriesSelected => 'Hiçbir kategori seçilmedi.';

  @override
  String nCategoriesSelected(int count) {
    return '$count seçildi';
  }

  @override
  String get foldersToSynchronize => 'Eşitlenecek klasörler';

  @override
  String get noCustomFolders => 'Yapılandırılmış özel klasör yok.';

  @override
  String nFolders(int count) {
    return '$count klasör';
  }

  @override
  String get addFolder => 'Klasör ekle';

  @override
  String get removeFolder => 'Klasörü kaldır';

  @override
  String get removeServer => 'Sunucuyu kaldır';

  @override
  String get syncFreqEvery15Min => 'Her 15 dakikada bir';

  @override
  String get syncFreqEvery30Min => 'Her 30 dakikada bir';

  @override
  String get syncFreqEvery1Hour => 'Her saat';

  @override
  String syncFreqEveryNHours(int hours) {
    return 'Her $hours saatte bir';
  }

  @override
  String syncFreqEveryNMin(int minutes) {
    return 'Her $minutes dakikada bir';
  }

  @override
  String get syncFreqDaily => 'Günlük';

  @override
  String get chooseSyncFrequencyTitle => 'Eşitleme Sıklığını Seçin';

  @override
  String get cacheSize => 'Önbellek boyutu';

  @override
  String get refreshTooltip => 'Yenile';

  @override
  String get cacheLimit => 'Önbellek sınırı';

  @override
  String get downloadPath => 'İndirme yolu';

  @override
  String get defaultDownloadFolder => 'Varsayılan CrowleysCloud klasörü';

  @override
  String get clearCache => 'Önbelleği temizle';

  @override
  String get clearCacheTitle => 'Önbellek temizlensin mi?';

  @override
  String get clearCacheBody =>
      'Bu işlem yerel küçük resimleri ve önbelleğe alınan sunucu listelerini kaldırır.';

  @override
  String get downloadPathDialogTitle => 'İndirme yolu';

  @override
  String get downloadPathHint => '/storage/emulated/0/CrowleysCloud';

  @override
  String get useDefault => 'Varsayılanı kullan';

  @override
  String get serverTargetDirDialogTitle => 'Sunucu hedef dizini';

  @override
  String get requireLogin => 'Oturum açmayı zorunlu kıl';

  @override
  String get biometricLogin => 'Biyometrik giriş';

  @override
  String get biometricLoginSubtitle =>
      'Kayıtlı kimlik bilgileriyle biyometrik girişe izin verin.';

  @override
  String get biometricsNotAvailable => 'Biyometri bu cihazda kullanılamıyor.';

  @override
  String get showHiddenFiles => 'Gizli dosyaları göster';

  @override
  String get showHiddenFilesSubtitle =>
      'Nokta ile başlayan dosya ve klasörleri görüntüleyin.';

  @override
  String get changePassword => 'Şifre değiştir';

  @override
  String changePasswordSubtitle(String serverName) {
    return '$serverName için şifreyi güncelleyin.';
  }

  @override
  String get addServerBeforeChangePassword =>
      'Şifreyi değiştirmeden önce bir sunucu ekleyin.';

  @override
  String get deleteUserAccount => 'Kullanıcı hesabını sil';

  @override
  String get deleteUserAccountSubtitle =>
      'Kullanıcıyı ve tüm özel bulut dosyalarını siler.';

  @override
  String get deleteAccountTitle => 'Hesap silinsin mi?';

  @override
  String deleteAccountBody(String serverName) {
    return 'Bu işlem $serverName üzerindeki hesabınızı kalıcı olarak siler ve özel bulut klasörünüzdeki tüm dosyaları kaldırır. Bu işlem geri alınamaz.';
  }

  @override
  String get deleteAccountButton => 'Hesabı sil';

  @override
  String get changePasswordDialogTitle => 'Şifre değiştir';

  @override
  String get newPasswordFieldLabel => 'Yeni şifre';

  @override
  String get confirmPasswordLabel => 'Şifreyi onayla';

  @override
  String get enterNewPassword => 'Yeni bir şifre girin.';

  @override
  String get passwordUpdated => 'Şifre güncellendi.';

  @override
  String passwordChangeFailed(String error) {
    return 'Şifre değiştirilemedi: $error';
  }

  @override
  String get passwordChangeFailedGeneric => 'Şifre değiştirilemedi.';

  @override
  String get accountDeleted => 'Hesap silindi.';

  @override
  String accountDeletionFailed(String error) {
    return 'Hesap silme başarısız: $error';
  }

  @override
  String get accountDeletionFailedGeneric => 'Hesap silme başarısız.';

  @override
  String get checkForUpdates => 'Güncellemeleri kontrol et';

  @override
  String get checkingForUpdates => 'GitHub Releases kontrol ediliyor...';

  @override
  String versionLabel(String version) {
    return 'Sürüm $version';
  }

  @override
  String appIsUpToDate(String version) {
    return 'Crowley\'s Cloud güncel (v$version).';
  }

  @override
  String get updateCheckFailed =>
      'Güncellemeler kontrol edilemedi. Lütfen daha sonra tekrar deneyin.';

  @override
  String get themeModeTitle => 'Tema Modu';

  @override
  String get themeDark => 'Koyu';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeCustom => 'Özel';

  @override
  String get themeDarkFull => 'Koyu Tema';

  @override
  String get themeLightFull => 'Açık Tema';

  @override
  String get themeCustomFull => 'Özel Tema';

  @override
  String get accentColor => 'Vurgu Rengi';

  @override
  String get primaryAccentColor => 'Birincil vurgu rengi';

  @override
  String get selectAccentColor => 'Vurgu Rengi Seçin';

  @override
  String get backgroundColor => 'Arka Plan Rengi';

  @override
  String get surfaceColor => 'Yüzey Rengi';

  @override
  String get textColor => 'Metin Rengi';

  @override
  String get subtextColor => 'Alt Metin Rengi';

  @override
  String get borderColor => 'Kenarlık Rengi';

  @override
  String get fontSizeScale => 'Yazı Tipi Boyutu Ölçeği';

  @override
  String selectColor(String title) {
    return '$title Seçin';
  }

  @override
  String get categoriesToSyncDialogTitle => 'Eşitlenecek kategoriler';

  @override
  String get categoriesToSyncBody =>
      'Bir veya daha fazla kategori seçin. Hiçbirini seçmemek de geçerlidir.';

  @override
  String get syncCategorySectionMedia => 'Medya';

  @override
  String get syncCategorySectionAudioDocs => 'Ses ve belgeler';

  @override
  String get syncCategorySectionOther => 'Diğer';

  @override
  String get clearAll => 'Tümünü temizle';

  @override
  String get noSyncHasRunYet => 'Henüz bir eşitleme çalıştırılmadı.';

  @override
  String lastRunAt(String date) {
    return 'Son çalışma $date';
  }

  @override
  String syncResultSuccess(int uploaded, int skipped) {
    return '$uploaded eşitlendi, $skipped atlandı.';
  }

  @override
  String get syncResultNoFiles => 'Eşitleme için dosya seçilmedi.';

  @override
  String syncResultPartial(int uploaded, int failed) {
    return '$uploaded eşitlendi, $failed başarısız oldu.';
  }

  @override
  String get syncResultAuthRequired => 'Eşitlemeden önce oturum açın.';

  @override
  String get syncResultUnreachable =>
      'Sunucuya ulaşılamıyor. Bağlantı kesildi.';

  @override
  String get syncResultFailed => 'Eşitleme başarısız oldu.';

  @override
  String get serverSetupAddServer => 'Sunucu ekle';

  @override
  String get serverSetupCardTitle => 'Sunucuya Bağlan';

  @override
  String get serverSetupCardSubtitle =>
      'Ev dosya sunucunuzu ekleyin ve oturum açın.';

  @override
  String get serverSetupSubmitButton => 'Sunucuyu Kaydet';

  @override
  String get serverNameLabel => 'Sunucu adı';

  @override
  String get serverNameHint => 'Home NAS';

  @override
  String get baseUrlLabel => 'Temel URL';

  @override
  String get baseUrlHint => 'https://cloud.example.com';

  @override
  String get allFieldsRequired => 'Tüm alanlar zorunludur.';

  @override
  String get localFilesTitle => 'Yerel Dosyalar';

  @override
  String get serverFilesTitle => 'Sunucu Dosyaları';

  @override
  String get restoreItemsTitle => 'Öğeleri geri yükle';

  @override
  String restoreItemsBody(int count) {
    return '$count öğeyi geri yüklemek istediğinizden emin misiniz?';
  }

  @override
  String get permanentlyDeleteTitle => 'Kalıcı olarak sil';

  @override
  String permanentlyDeleteBody(int count) {
    return '$count öğeyi kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.';
  }

  @override
  String get trashIsEmpty => 'Çöp kutusu boş.';

  @override
  String trashRetentionInfo(int days) {
    return 'Çöp kutusundaki öğeler $days gün sonra otomatik olarak silinir.';
  }

  @override
  String get deletionDate => 'Silinme Tarihi';

  @override
  String get deletePermanentlyAction => 'Kalıcı Olarak Sil';

  @override
  String get conflictFileAlreadyExists => 'Dosya zaten var';

  @override
  String conflictNofM(int current, int total) {
    return 'Çakışma $current / $total';
  }

  @override
  String get conflictAFileNamed => 'Şu adlı bir dosya ';

  @override
  String get conflictAlreadyExistsAt => ' zaten burada mevcut: ';

  @override
  String get conflictAlreadyExistsInFolder => ' bu klasörde zaten mevcut.';

  @override
  String get conflictInFolder => 'Klasörde';

  @override
  String get conflictFromTrash => 'Çöp Kutusundan';

  @override
  String get conflictExisting => 'Mevcut';

  @override
  String get conflictNewUpload => 'Yeni Yükleme';

  @override
  String conflictSizeLabel(String size) {
    return 'Boyut: $size';
  }

  @override
  String conflictDateLabel(String date) {
    return 'Tarih: $date';
  }

  @override
  String conflictDeletedLabel(String date) {
    return 'Silinme: $date';
  }

  @override
  String conflictApplyToRemaining(int count) {
    return 'Kalan çakışmalara uygula ($count)';
  }

  @override
  String get conflictKeepAllCopies => 'Tüm Kopyaları Koru';

  @override
  String get conflictOverwriteAll => 'Tümünün Üzerine Yaz';

  @override
  String get conflictRestoreAllAsCopies => 'Tümünü Kopya Olarak Geri Yükle';

  @override
  String get conflictRestoreAsCopy => 'Kopya Olarak Geri Yükle';

  @override
  String get conflictOverwriteAllRemaining => 'Kalan Tümünün Üzerine Yaz';

  @override
  String get conflictSkipAll => 'Tümünü Atla';

  @override
  String get conflictSkipAllRemaining => 'Kalan Tümünü Atla';

  @override
  String get conflictSkip => 'Atla';

  @override
  String get conflictOverwrite => 'Üzerine Yaz';

  @override
  String get transfersTitle => 'Aktarımlar';

  @override
  String get transferResume => 'Devam ettir';

  @override
  String get transferPause => 'Duraklat';

  @override
  String get transferCancel => 'İptal et';

  @override
  String get transferResumeAll => 'Tümünü devam ettir';

  @override
  String get transferPauseAll => 'Tümünü duraklat';

  @override
  String get transferCancelAll => 'Tümünü iptal et';

  @override
  String get transferCancelFile => 'Dosyayı iptal et';

  @override
  String get noTransfers => 'Aktarım yok.';

  @override
  String get transferStatusQueued => 'Kuyrukta';

  @override
  String get transferStatusRunning => 'Çalışıyor';

  @override
  String get transferStatusPaused => 'Duraklatıldı';

  @override
  String get transferStatusCompleted => 'Tamamlandı';

  @override
  String get transferStatusFailed => 'Başarısız';

  @override
  String get transferStatusCanceled => 'İptal edildi';

  @override
  String get themePresetsSection => 'Hazır Ayarlar';

  @override
  String get themeCustomPaletteSection => 'Özel Palet';

  @override
  String get themeHexRgbLabel => 'HEX RGB Kodu';

  @override
  String get themeHexRgbHint => '#FA5252';

  @override
  String get imageViewerNoFetchHandler =>
      'Yapılandırılmış getirme işleyicisi yok';

  @override
  String get imageViewerFailedToLoad => 'Görsel yüklenemedi';

  @override
  String errorDeletingFile(String filename, String error) {
    return '$filename silinirken hata: $error';
  }

  @override
  String errorReadingFile(String error) {
    return 'Dosya okunurken hata: $error';
  }

  @override
  String get syncChannelName => 'Arka Planda Eşitleme';

  @override
  String get syncChannelDescription =>
      'Arka planda eşitlenen dosyaların durumunu gösterir.';

  @override
  String get storageStatsTitle => 'Depolama İstatistikleri';

  @override
  String get storageStatsUsedSpace => 'Kullanılan Alan';

  @override
  String get storageStatsTotalFiles => 'Toplam Dosya';

  @override
  String storageStatsNItems(int count) {
    return '$count öğe';
  }

  @override
  String userFallback(int userId) {
    return 'Kullanıcı #$userId';
  }

  @override
  String get biometricUnlockReason =>
      'Crowley\'s Cloud için kayıtlı kimlik bilgilerinin kilidini açın.';

  @override
  String get tokenLifetimeEveryOpen => 'Her uygulama açılışında';

  @override
  String get tokenLifetimeOneHour => '1 saat sonra';

  @override
  String get tokenLifetime1Hour => '1 saat sonra';

  @override
  String get tokenLifetimeOneDay => '1 gün sonra';

  @override
  String get tokenLifetime1Day => '1 gün sonra';

  @override
  String get tokenLifetimeOneWeek => '1 hafta sonra';

  @override
  String get tokenLifetime1Week => '1 hafta sonra';

  @override
  String get tokenLifetimeOneMonth => '1 ay sonra';

  @override
  String get tokenLifetime1Month => '1 ay sonra';

  @override
  String get tokenLifetimeThreeMonths => '3 ay sonra';

  @override
  String get tokenLifetime3Months => '3 ay sonra';

  @override
  String get tokenLifetimeNever => 'Bu cihazda hiçbir zaman';

  @override
  String get cacheLimitUnlimited => 'Sınırsız';

  @override
  String get syncCategoryOtherFiles => 'Diğer dosyalar';

  @override
  String get internalStorage => 'Dahili Depolama';

  @override
  String get localStorageRootName => 'Dahili Depolama';

  @override
  String syncNotificationSyncingWith(String serverName) {
    return '$serverName ile eşitleniyor';
  }

  @override
  String syncNotificationPausedTitle(String serverName) {
    return '$serverName ile eşitleme duraklatıldı';
  }

  @override
  String get syncNotificationUnreachableBody =>
      'Sunucuya ulaşılamıyor. Uygulama açılana kadar arka planda eşitleme duraklatıldı.';

  @override
  String get syncNotificationAuthRequiredBody =>
      'Kimlik doğrulaması gerekli. Giriş yapmak için uygulamayı açın.';

  @override
  String syncNotificationFailedTitle(String serverName) {
    return '$serverName ile eşitleme başarısız oldu';
  }

  @override
  String get syncNotificationGenericErrorBody =>
      'Eşitleme sırasında bir hata oluştu.';

  @override
  String syncNotificationCompleteTitle(String serverName) {
    return '$serverName ile eşitleme tamamlandı';
  }

  @override
  String get syncNotificationCompleteBody => 'Eşitleme tamamlandı.';

  @override
  String get syncStatusConnecting => 'Sunucuya bağlanılıyor...';

  @override
  String syncStatusConnectionLost(String serverName) {
    return '$serverName sunucusuna bağlanılamadı. Bağlantı kesildi.';
  }

  @override
  String syncResultServerUnreachableWithServer(String serverName) {
    return '$serverName sunucusuna bağlanılamadı. Bağlantı kesildi.';
  }

  @override
  String get syncStatusScanningFiles => 'Cihazdaki dosyalar taranıyor...';

  @override
  String get syncStatusNoFilesFound => 'Eşitlenecek dosya bulunamadı.';

  @override
  String get syncStatusNoFilesSelected => 'Eşitleme için dosya seçilmedi.';

  @override
  String syncStatusCalculatingChecksum(
    int current,
    int total,
    String filename,
  ) {
    return 'Sağlama toplamı hesaplanıyor ($current/$total): $filename';
  }

  @override
  String get syncStatusCheckingDuplicates =>
      'Sunucudaki kopyalar kontrol ediliyor...';

  @override
  String syncStatusSyncingFile(int current, int total, String filename) {
    return 'Eşitleniyor ($current/$total): $filename';
  }

  @override
  String get syncStatusCompleting => 'Eşitleme tamamlanıyor...';

  @override
  String get showingCachedFiles => 'Önbelleğe alınan dosyalar gösteriliyor.';

  @override
  String get showingCachedFilesRefreshFailed =>
      'Önbelleğe alınan dosyalar gösteriliyor. Yenileme başarısız oldu.';

  @override
  String get downloadCanceled => 'İndirme iptal edildi.';

  @override
  String downloadedNFilesToPath(int count, String path) {
    return '$count dosya $path konumuna indirildi';
  }

  @override
  String downloadedNFilesFailedM(int downloaded, int failed, String detail) {
    return '$downloaded dosya indirildi, $failed dosya başarısız oldu: $detail';
  }

  @override
  String downloadedNFilesWithFailures(int count, int failed, String error) {
    return '$count dosya indirildi, $failed dosya başarısız oldu: $error';
  }

  @override
  String createdNShareLinks(int count) {
    return '$count paylaşım bağlantısı oluşturuldu.';
  }

  @override
  String get failedToCreateShareLinks => 'Paylaşım bağlantısı oluşturulamadı.';

  @override
  String get alreadyInSharedScope => 'Zaten paylaşılan kapsamda.';

  @override
  String sharedNItemsInServer(int count) {
    return 'Sunucuda $count öğe paylaşıldı.';
  }

  @override
  String sharedNItemsWithFailures(int count, int failed) {
    return 'Sunucuda $count öğe paylaşıldı, $failed öğe başarısız oldu.';
  }

  @override
  String sharedNItemsFailedM(int shared, int failed) {
    return 'Sunucuda $shared öğe paylaşıldı, $failed öğe başarısız oldu.';
  }

  @override
  String get folderNameCannotBeEmpty => 'Klasör adı boş olamaz.';

  @override
  String get folderAlreadyExists => 'Klasör zaten mevcut.';

  @override
  String get folderCreationOnlyInAllFiles =>
      'Klasör oluşturma yalnızca Tüm Dosyalar bölümünde kullanılabilir.';

  @override
  String get currentDirectoryUnavailable => 'Geçerli dizin kullanılamıyor.';

  @override
  String get nothingSelected => 'Hiçbir şey seçilmedi.';

  @override
  String get destinationFolderDoesNotExist => 'Hedef klasör mevcut değil.';

  @override
  String cannotMoveFolderIntoItself(String name) {
    return '\"$name\" klasörü kendi içine taşınamaz.';
  }

  @override
  String failedToMoveItem(String name, String error) {
    return '\"$name\" taşınamadı: $error';
  }

  @override
  String movedNItems(int count) {
    return '$count öğe taşındı.';
  }

  @override
  String movedNItemsWithFailures(int count, int failed) {
    return '$count öğe taşındı, $failed öğe başarısız oldu.';
  }

  @override
  String movedNItemsFailedM(int moved, int failed) {
    return '$moved öğe taşındı, $failed öğe başarısız oldu.';
  }

  @override
  String get failedToMoveSelectedItems => 'Seçili öğeler taşınamadı.';

  @override
  String get noFilesWereMoved => 'Hiçbir dosya taşınmadı.';

  @override
  String renamedOldToNew(String oldName, String newName) {
    return '\"$oldName\", \"$newName\" olarak yeniden adlandırıldı.';
  }

  @override
  String renamedFileFromTo(String oldName, String newName) {
    return '\"$oldName\", \"$newName\" olarak yeniden adlandırıldı.';
  }

  @override
  String failedToRenameWithStatus(String name, int statusCode) {
    return '\"$name\" yeniden adlandırılamadı ($statusCode).';
  }

  @override
  String failedToRenameFileWithCode(String name, int statusCode) {
    return '\"$name\" yeniden adlandırılamadı ($statusCode).';
  }

  @override
  String failedToRenameWithError(String name, String error) {
    return '\"$name\" yeniden adlandırılamadı: $error';
  }

  @override
  String failedToRenameFile(String name, String error) {
    return '\"$name\" yeniden adlandırılamadı: $error';
  }

  @override
  String get renameConflictAlreadyExists =>
      'Yeniden adlandırılamadı: Bu adda bir dosya veya klasör zaten var.';

  @override
  String get renameFailedAlreadyExists =>
      'Yeniden adlandırılamadı: Bu adda bir dosya veya klasör zaten var.';

  @override
  String failedToCreateFolderWithCode(int statusCode) {
    return 'Klasör oluşturulamadı ($statusCode).';
  }

  @override
  String deletedNItemsFailedM(int deleted, int failed) {
    return '$deleted öğe silindi, $failed öğe başarısız oldu.';
  }

  @override
  String transferSummaryFiles(int percent, int completed, int total) {
    return '%$percent  $completed/$total dosya';
  }

  @override
  String transferSummaryProgress(int percent, int completed, int total) {
    return '%$percent  $completed/$total';
  }

  @override
  String get downloadFailedGeneric => 'İndirme başarısız';

  @override
  String uploadedNItemsWithFailures(int uploaded, int failed) {
    return '$uploaded öğe yüklendi, $failed öğe başarısız oldu';
  }

  @override
  String uploadedNItemsFailedM(int uploaded, int failed) {
    return '$uploaded öğe yüklendi, $failed öğe başarısız oldu.';
  }

  @override
  String uploadSummaryFailedCount(int count) {
    return ', $count başarısız';
  }

  @override
  String uploadLocalPathEmpty(String name) {
    return '$name: yerel yol boş';
  }

  @override
  String uploadErrorLocalPathEmpty(String name) {
    return '$name: yerel yol boş';
  }

  @override
  String get directoryUploadFailed => 'Dizin yüklemesi başarısız oldu';

  @override
  String get uploadDirectoryFailed => 'Dizin yüklemesi başarısız oldu';

  @override
  String get localFileNotFound => 'Yerel dosya bulunamadı';

  @override
  String get uploadErrorLocalFileNotFound => 'Yerel dosya bulunamadı';

  @override
  String get noSessionToken => 'Etkin oturum belirteci yok';

  @override
  String get uploadErrorNoSessionToken => 'Etkin oturum belirteci yok';

  @override
  String get serverDisconnectedStatus => 'Sunucu bağlantısı kesildi';

  @override
  String get serverDisconnected => 'Sunucu bağlantısı kesildi';

  @override
  String get serverIsUnreachable => 'Sunucuya ulaşılamıyor.';

  @override
  String get serverUnreachable => 'Sunucuya ulaşılamıyor.';

  @override
  String get uploadErrorLocalDirectoryNotFound => 'Yerel dizin bulunamadı';

  @override
  String get uploadErrorFailedToScanDirectory => 'Dizin taranamadı';

  @override
  String uploadErrorFolderCreateHttp(int statusCode) {
    return 'Klasör oluşturulamadı (HTTP $statusCode)';
  }

  @override
  String get authErrorMissingAccessToken => 'Yanıtta erişim belirteci eksik';

  @override
  String get authErrorMissingRefreshToken => 'Yanıtta yenileme belirteci eksik';

  @override
  String get authErrorNoSavedCredentials => 'Kayıtlı kimlik bilgisi yok';

  @override
  String get authErrorNoRefreshToken => 'Yenileme belirteci yok';

  @override
  String get authErrorNoActiveSession => 'Etkin oturum yok';

  @override
  String get authErrorNoSavedUsername => 'Kayıtlı kullanıcı adı yok';

  @override
  String get updateNoReleasesPublished => 'Henüz yayınlanmış bir sürüm yok.';

  @override
  String get language => 'Dil';
}
