// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Crowley\'s Cloud';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Batal';

  @override
  String get save => 'Simpan';

  @override
  String get delete => 'Hapus';

  @override
  String get rename => 'Ganti Nama';

  @override
  String get close => 'Tutup';

  @override
  String get retry => 'Coba Lagi';

  @override
  String get loading => 'Memuat...';

  @override
  String get confirm => 'Konfirmasi';

  @override
  String get error => 'Kesalahan';

  @override
  String errorWithMessage(String message) {
    return 'Kesalahan: $message';
  }

  @override
  String get unknown => 'Tidak diketahui';

  @override
  String get upload => 'Unggah';

  @override
  String get download => 'Unduh';

  @override
  String get share => 'Bagikan';

  @override
  String get copy => 'Salin';

  @override
  String get move => 'Pindahkan';

  @override
  String get restore => 'Pulihkan';

  @override
  String get apply => 'Terapkan';

  @override
  String get create => 'Buat';

  @override
  String get clear => 'Bersihkan';

  @override
  String get add => 'Tambah';

  @override
  String get remove => 'Hapus';

  @override
  String get edit => 'Edit';

  @override
  String get switchLabel => 'Beralih';

  @override
  String get search => 'Cari';

  @override
  String get name => 'Nama';

  @override
  String get date => 'Tanggal';

  @override
  String get size => 'Ukuran';

  @override
  String get type => 'Jenis';

  @override
  String get ascending => 'Naik';

  @override
  String get descending => 'Turun';

  @override
  String get allFiles => 'Semua';

  @override
  String get categoryImages => 'Gambar';

  @override
  String get categoryPhotos => 'Foto';

  @override
  String get categoryVideos => 'Video';

  @override
  String get categoryAudio => 'Audio';

  @override
  String get categoryDocuments => 'Dokumen';

  @override
  String get categoryArchives => 'Arsip';

  @override
  String get categoryShared => 'Dibagikan';

  @override
  String get categoryOther => 'Lainnya';

  @override
  String get categoryOtherFiles => 'Berkas Lainnya';

  @override
  String get noFilesFound => 'Berkas tidak ditemukan.';

  @override
  String get noFilesInFolder => 'Tidak ada berkas di folder ini.';

  @override
  String get thisActionCannotBeUndone => 'Tindakan ini tidak dapat dibatalkan.';

  @override
  String get passwordsDoNotMatch => 'Kata sandi tidak cocok.';

  @override
  String get navLocalFiles => 'Lokal';

  @override
  String get navServerFiles => 'Server';

  @override
  String get navSettings => 'Pengaturan';

  @override
  String get navTrash => 'Sampah';

  @override
  String get navLocal => 'Lokal';

  @override
  String get navServer => 'Server';

  @override
  String get addServer => 'Tambah Server';

  @override
  String get noServersConfigured => 'Belum ada server yang dikonfigurasi.';

  @override
  String get addAServerInSettings => 'Tambahkan server di Pengaturan.';

  @override
  String get addFirstServerHint =>
      'Tambahkan server pertama Anda untuk melanjutkan.';

  @override
  String get noServersConfiguredYet => 'Belum ada server yang dikonfigurasi.';

  @override
  String get crowleysCloudSetup => 'Penyiapan Crowley\'s Cloud';

  @override
  String get connect => 'Hubungkan';

  @override
  String get connecting => 'Menghubungkan...';

  @override
  String get connected => 'Terhubung';

  @override
  String get disconnected => 'Terputus';

  @override
  String get switchServer => 'Beralih Server';

  @override
  String get chooseOtherServer => 'Pilih Server Lain';

  @override
  String get switchServerTitle => 'Beralih Server?';

  @override
  String switchServerBody(String serverName) {
    return 'Beralih server aktif ke \"$serverName\"?';
  }

  @override
  String get chooseServer => 'Pilih Server';

  @override
  String get authenticationRequired => 'Autentikasi Diperlukan';

  @override
  String signInToAccess(String serverName) {
    return 'Masuk untuk mengakses berkas di $serverName';
  }

  @override
  String get signInWithPassword => 'Masuk dengan Kata Sandi';

  @override
  String get useBiometrics => 'Gunakan Biometrik';

  @override
  String get openingSignIn => 'Membuka proses masuk...';

  @override
  String get serverConnectionFailed => 'Koneksi Server Gagal';

  @override
  String get unableToConnectToServer =>
      'Tidak dapat terhubung ke server aktif.';

  @override
  String unableToConnectTo(String serverName) {
    return 'Tidak dapat terhubung ke $serverName.';
  }

  @override
  String get searchHint => 'Cari...';

  @override
  String get searchFilesHint => 'Cari berkas...';

  @override
  String get searchServerFilesHint => 'Cari berkas server...';

  @override
  String get searchTrashHint => 'Cari di sampah...';

  @override
  String get storagePermissionRequired => 'Izin Penyimpanan Diperlukan';

  @override
  String get grantPermission => 'Beri Izin';

  @override
  String get permissionDeniedOpenSettings =>
      'Izin ditolak. Silakan berikan izin akses penyimpanan di Pengaturan.';

  @override
  String get manageStoragePermissionRequired =>
      'Izin Kelola Penyimpanan diperlukan untuk menelusuri dan memilih folder.';

  @override
  String get storagePermissionsRequired =>
      'Izin penyimpanan diperlukan untuk melakukan sinkronisasi.';

  @override
  String updateAvailableTitle(String version) {
    return 'Pembaruan Tersedia: v$version';
  }

  @override
  String get updateAvailableTapToSeeNew => 'Ketuk untuk melihat yang baru';

  @override
  String get updateView => 'Lihat';

  @override
  String get updateAvailableDialogTitle => 'Pembaruan Tersedia';

  @override
  String updateVersionSubtitle(String version) {
    return 'Versi $version';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'Saat ini: v$version';
  }

  @override
  String updateNewVersion(String version) {
    return 'Terbaru: v$version';
  }

  @override
  String get updateWhatsNew => 'Yang baru:';

  @override
  String get updateGitHub => 'GitHub';

  @override
  String get updateNoReleaseNotes => 'Tidak ada catatan rilis yang disediakan.';

  @override
  String get updateLater => 'Nanti';

  @override
  String get updateDownloadApk => 'Unduh APK';

  @override
  String get updateInstall => 'Perbarui';

  @override
  String get shareLinkTitle => 'Tautan Berbagi';

  @override
  String get shareViaLink => 'Bagikan lewat Tautan';

  @override
  String get shareInServer => 'Bagikan di Server';

  @override
  String get expiryDays => 'Kedaluwarsa (hari)';

  @override
  String get expiryNever => 'Tidak pernah';

  @override
  String get expiry1Day => '1 hari';

  @override
  String get expiry7Days => '7 hari';

  @override
  String get expiry30Days => '30 hari';

  @override
  String get expiry90Days => '90 hari';

  @override
  String get expiry180Days => '180 hari';

  @override
  String get expiry365Days => '365 hari';

  @override
  String get createLink => 'Buat Tautan';

  @override
  String get sharedLinkCopied => 'Tautan berbagi disalin ke papan klip!';

  @override
  String failedToCopySharedLink(String error) {
    return 'Gagal menyalin tautan berbagi: $error';
  }

  @override
  String get cannotShareThisFileType =>
      'Jenis berkas ini tidak dapat dibagikan.';

  @override
  String failedToCreateShare(String error) {
    return 'Gagal membuat berbagi: $error';
  }

  @override
  String get newFolderTitle => 'Buat Folder';

  @override
  String get newFolderHint => 'Nama folder';

  @override
  String get newFolder => 'Folder Baru';

  @override
  String get folderCreated => 'Folder dibuat.';

  @override
  String failedToCreateFolder(String error) {
    return 'Gagal membuat folder: $error';
  }

  @override
  String get creatingFolder => 'Membuat folder...';

  @override
  String get renameDialogTitle => 'Ganti Nama';

  @override
  String get renameHint => 'Nama baru';

  @override
  String get enterNewName => 'Masukkan nama baru';

  @override
  String get renamedSuccessfully => 'Berhasil diganti nama.';

  @override
  String renameFailed(String error) {
    return 'Gagal mengganti nama: $error';
  }

  @override
  String get moveDialogTitle => 'Pindahkan ke';

  @override
  String moveTo(String path) {
    return 'Pindahkan ke: $path';
  }

  @override
  String get moveHere => 'Pindahkan ke Sini';

  @override
  String moveFailed(String error) {
    return 'Gagal memindahkan: $error';
  }

  @override
  String get movedToFolder => 'Dipindahkan ke folder.';

  @override
  String copyFailed(String error) {
    return 'Gagal menyalin: $error';
  }

  @override
  String get selectFolder => 'Pilih Folder';

  @override
  String get useThisFolder => 'Gunakan Folder Ini';

  @override
  String get storageRoot => 'Penyimpanan';

  @override
  String get serverRoot => 'root';

  @override
  String deleteNItemsTitle(int count) {
    return 'Hapus $count item?';
  }

  @override
  String get deleteFilesTitle => 'Hapus berkas?';

  @override
  String deleteFilesBody(int count) {
    return 'Apakah Anda yakin ingin menghapus $count item yang dipilih? Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get deletePermanently => 'Hapus Permanen';

  @override
  String get deletePermanentlyTitle => 'Hapus Permanen?';

  @override
  String deletePermanentlyBody(String filename) {
    return '$filename akan dihapus secara permanen.';
  }

  @override
  String get deleteFileTitle => 'Hapus berkas?';

  @override
  String deleteFileBody(String filename) {
    return 'Apakah Anda yakin ingin menghapus $filename? Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get deleteServerFileTitle => 'Hapus Permanen';

  @override
  String deleteServerFileBody(String filename) {
    return 'Apakah Anda yakin ingin menghapus \"$filename\" secara permanen? Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get unshareItemsTitle => 'Batalkan Berbagi Item?';

  @override
  String unshareItemsBody(int count) {
    return 'Apakah Anda yakin ingin membatalkan berbagi $count item yang dipilih? Item tersebut akan dihapus dari folder Dibagikan.';
  }

  @override
  String get unshare => 'Batal Berbagi';

  @override
  String get moveToTrash => 'Pindahkan ke Sampah';

  @override
  String get movedToTrash => 'Dipindahkan ke sampah.';

  @override
  String movedNItemsToTrash(int count) {
    return 'Memindahkan $count item ke sampah.';
  }

  @override
  String failedToMoveToTrash(String error) {
    return 'Gagal memindahkan ke sampah: $error';
  }

  @override
  String deletedNItems(int count) {
    return 'Menghapus $count item.';
  }

  @override
  String failedToDelete(String error) {
    return 'Gagal menghapus: $error';
  }

  @override
  String failedToDeleteItem(String error) {
    return 'Gagal menghapus item: $error';
  }

  @override
  String deletedFilename(String filename) {
    return 'Menghapus $filename.';
  }

  @override
  String get failedToOpenFile => 'Tidak dapat membuka berkas';

  @override
  String fileDownloadFailed(String error) {
    return 'Unduhan berkas gagal: $error';
  }

  @override
  String get downloading => 'Mengunduh...';

  @override
  String get downloadingFile => 'Mengunduh berkas...';

  @override
  String downloadComplete(String filename) {
    return 'Unduhan selesai: $filename';
  }

  @override
  String downloadFailed(String error) {
    return 'Unduhan gagal: $error';
  }

  @override
  String get failedToDownloadPreview => 'Tidak dapat mengunduh pratinjau';

  @override
  String uploadComplete(String filename) {
    return 'Unggahan selesai: $filename';
  }

  @override
  String uploadFailed(String error) {
    return 'Unggahan gagal: $error';
  }

  @override
  String get failedToPickFiles => 'Tidak dapat memilih berkas';

  @override
  String uploadedNItems(int count) {
    return 'Mengunggah $count berkas';
  }

  @override
  String get copiedLinkToClipboard => 'Tautan disalin ke papan klip.';

  @override
  String failedToCopyLink(String error) {
    return 'Gagal menyalin tautan: $error';
  }

  @override
  String get selectingAll => 'Memilih semua...';

  @override
  String get allItemsSelected => 'Semua item dipilih.';

  @override
  String get failedToLoadSearchResults => 'Gagal memuat hasil pencarian';

  @override
  String get shareNotSupportedForType =>
      'Berbagi tidak didukung untuk jenis berkas ini.';

  @override
  String nSelected(int count) {
    return '$count dipilih';
  }

  @override
  String get noServerSelected => 'Tidak ada server yang dipilih';

  @override
  String get pleaseConnectToServerFirst =>
      'Harap hubungkan ke server terlebih dahulu.';

  @override
  String get signInRequired => 'Masuk Diperlukan';

  @override
  String pleaseSignInToServer(String serverName) {
    return 'Harap masuk ke $serverName terlebih dahulu.';
  }

  @override
  String get connectingToServer => 'Menghubungkan ke server...';

  @override
  String connectedToServer(String serverName) {
    return 'Terhubung ke $serverName.';
  }

  @override
  String connectionFailed(String error) {
    return 'Koneksi gagal: $error';
  }

  @override
  String failedToConnect(String error) {
    return 'Tidak dapat terhubung: $error';
  }

  @override
  String authFailed(String error) {
    return 'Autentikasi gagal: $error';
  }

  @override
  String get authFailedGeneric => 'Autentikasi gagal. Silakan coba lagi.';

  @override
  String biometricLoginFailed(String error) {
    return 'Masuk dengan biometrik gagal: $error';
  }

  @override
  String get biometricLoginFailedGeneric => 'Masuk dengan biometrik gagal.';

  @override
  String get noServerSessionToken =>
      'Tidak ada token sesi server. Silakan autentikasi ulang dengan server.';

  @override
  String failedToSaveServer(String error) {
    return 'Gagal menyimpan server: $error';
  }

  @override
  String get addToFolder => 'Tambah ke Folder';

  @override
  String get loginTabLabel => 'Masuk';

  @override
  String get registerTabLabel => 'Daftar';

  @override
  String get welcomeBack => 'Selamat Datang Kembali';

  @override
  String get signInToContinue => 'Masuk untuk melanjutkan';

  @override
  String get createAccount => 'Buat Akun';

  @override
  String get joinTheServer => 'Bergabung dengan server';

  @override
  String get usernameLabel => 'Nama Pengguna';

  @override
  String get usernameHint => 'Masukkan nama pengguna Anda';

  @override
  String get passwordLabel => 'Kata Sandi';

  @override
  String get passwordHint => 'Masukkan kata sandi Anda';

  @override
  String get showPassword => 'Tampilkan kata sandi';

  @override
  String get hidePassword => 'Sembunyikan kata sandi';

  @override
  String get confirmPassword => 'Konfirmasi Kata Sandi';

  @override
  String get logIn => 'Masuk';

  @override
  String get loggingIn => 'Sedang masuk...';

  @override
  String get registering => 'Mendaftar...';

  @override
  String get forgotPassword => 'Lupa Kata Sandi?';

  @override
  String get doNotHaveAccount => 'Belum punya akun? Beralih ke Daftar.';

  @override
  String get alreadyHaveAccount => 'Sudah punya akun? Beralih ke Masuk.';

  @override
  String get usernameCannotBeEmpty => 'Nama pengguna tidak boleh kosong.';

  @override
  String get passwordCannotBeEmpty => 'Kata sandi tidak boleh kosong.';

  @override
  String get usernameInvalid =>
      'Nama pengguna harus berupa 3-32 huruf, angka, _, atau -.';

  @override
  String get passwordTooShort => 'Kata sandi harus minimal 8 karakter.';

  @override
  String loginFailed(String error) {
    return 'Gagal masuk: $error';
  }

  @override
  String registrationFailed(String error) {
    return 'Pendaftaran gagal: $error';
  }

  @override
  String get resetPasswordTitle => 'Atur Ulang Kata Sandi';

  @override
  String get enterResetCodeTitle => 'Masukkan Kode Atur Ulang';

  @override
  String get resetPasswordStep1Body =>
      'Masukkan nama pengguna Anda. Kode verifikasi 6 digit akan dicetak ke log/konsol server.';

  @override
  String get resetPasswordStep2Body =>
      'Kode verifikasi telah dicetak ke konsol server. Masukkan kode 6 digit dan kata sandi baru Anda.';

  @override
  String get resetCodeLabel => 'Kode Atur Ulang';

  @override
  String get resetCodeHint => 'Masukkan kode 6 digit';

  @override
  String get newPasswordLabel => 'Kata Sandi Baru';

  @override
  String get newPasswordHint => 'Masukkan kata sandi baru';

  @override
  String get passwordResetSuccessfully => 'Kata sandi berhasil diatur ulang!';

  @override
  String get usernameIsRequired => 'Nama pengguna wajib diisi.';

  @override
  String get codeAndPasswordRequired => 'Kode dan kata sandi baru diperlukan.';

  @override
  String get failedToRequestReset =>
      'Gagal meminta atur ulang. Periksa URL server Anda.';

  @override
  String get failedToResetPassword =>
      'Gagal mengatur ulang kata sandi. Periksa kode Anda.';

  @override
  String get pleaseEnterServerUrlFirst =>
      'Harap masukkan URL server terlebih dahulu.';

  @override
  String get sendCode => 'Kirim Kode';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get sectionBackupSync => 'Cadangkan & Sinkronkan';

  @override
  String get sectionStorageCache => 'Penyimpanan & Cache';

  @override
  String get sectionSecurityBehavior => 'Keamanan & Perilaku';

  @override
  String get sectionAboutUpdates => 'Tentang & Pembaruan';

  @override
  String get sectionAppearance => 'Tampilan & Kustomisasi';

  @override
  String get noServersConfiguredSync => 'Belum ada server yang dikonfigurasi';

  @override
  String get addServerBeforeSync =>
      'Tambahkan server sebelum mengonfigurasi sinkronisasi.';

  @override
  String get selectServerToConfigureSync =>
      'Pilih server untuk mengonfigurasi sinkronisasi.';

  @override
  String get activeServerSuffix => ' · aktif';

  @override
  String get folderAndCategorySync => 'Sinkronisasi Folder & Kategori';

  @override
  String get keepCategoriesSynced =>
      'Jaga agar kategori atau folder lokal yang dipilih tetap tersinkronisasi dengan server ini.';

  @override
  String get addServerBeforeSyncEnable =>
      'Tambahkan server sebelum mengaktifkan sinkronisasi.';

  @override
  String get onlyOnWifi => 'Hanya di Wi-Fi';

  @override
  String get onlyWhileCharging => 'Hanya Saat Mengisi Daya';

  @override
  String get serverTargetDirectory => 'Direktori Target Server';

  @override
  String get serverTargetDirectoryHint => '/backup/mobile_phone';

  @override
  String get synchronizationFrequency => 'Frekuensi Sinkronisasi';

  @override
  String get syncNow => 'Sinkronkan Sekarang';

  @override
  String get syncing => 'Menyinkronkan...';

  @override
  String get categoriesToSynchronize => 'Kategori untuk Disinkronkan';

  @override
  String get noCategoriesSelected => 'Tidak ada kategori yang dipilih.';

  @override
  String nCategoriesSelected(int count) {
    return '$count dipilih';
  }

  @override
  String get foldersToSynchronize => 'Folder untuk Disinkronkan';

  @override
  String get noCustomFolders => 'Belum ada folder kustom yang dikonfigurasi.';

  @override
  String nFolders(int count) {
    return '$count folder';
  }

  @override
  String get addFolder => 'Tambah Folder';

  @override
  String get removeFolder => 'Hapus Folder';

  @override
  String get removeServer => 'Hapus Server';

  @override
  String get syncFreqEvery15Min => 'Setiap 15 menit';

  @override
  String get syncFreqEvery30Min => 'Setiap 30 menit';

  @override
  String get syncFreqEvery1Hour => 'Setiap jam';

  @override
  String syncFreqEveryNHours(int hours) {
    return 'Setiap $hours jam';
  }

  @override
  String syncFreqEveryNMin(int minutes) {
    return 'Setiap $minutes menit';
  }

  @override
  String get syncFreqDaily => 'Setiap hari';

  @override
  String get chooseSyncFrequencyTitle => 'Pilih Frekuensi Sinkronisasi';

  @override
  String get cacheSize => 'Ukuran Cache';

  @override
  String get refreshTooltip => 'Segarkan';

  @override
  String get cacheLimit => 'Batas Cache';

  @override
  String get downloadPath => 'Jalur Unduhan';

  @override
  String get defaultDownloadFolder => 'Folder CrowleysCloud default';

  @override
  String get clearCache => 'Bersihkan Cache';

  @override
  String get clearCacheTitle => 'Bersihkan Cache?';

  @override
  String get clearCacheBody =>
      'Tindakan ini akan menghapus gambar mini lokal dan daftar server yang di-cache.';

  @override
  String get downloadPathDialogTitle => 'Jalur Unduhan';

  @override
  String get downloadPathHint => '/storage/emulated/0/CrowleysCloud';

  @override
  String get useDefault => 'Gunakan Default';

  @override
  String get serverTargetDirDialogTitle => 'Direktori Target Server';

  @override
  String get requireLogin => 'Wajibkan Masuk';

  @override
  String get biometricLogin => 'Masuk dengan Biometrik';

  @override
  String get biometricLoginSubtitle =>
      'Izinkan masuk dengan kredensial tersimpan menggunakan biometrik.';

  @override
  String get biometricsNotAvailable =>
      'Biometrik tidak tersedia di perangkat ini.';

  @override
  String get showHiddenFiles => 'Tampilkan Berkas Tersembunyi';

  @override
  String get showHiddenFilesSubtitle =>
      'Tampilkan berkas dan folder yang diawali dengan titik.';

  @override
  String get changePassword => 'Ubah Kata Sandi';

  @override
  String changePasswordSubtitle(String serverName) {
    return 'Ubah kata sandi untuk $serverName.';
  }

  @override
  String get addServerBeforeChangePassword =>
      'Tambahkan server sebelum mengubah kata sandi.';

  @override
  String get deleteUserAccount => 'Hapus Akun Pengguna';

  @override
  String get deleteUserAccountSubtitle =>
      'Hapus pengguna dan semua berkas cloud pribadi.';

  @override
  String get deleteAccountTitle => 'Hapus Akun?';

  @override
  String deleteAccountBody(String serverName) {
    return 'Tindakan ini akan menghapus akun Anda di $serverName secara permanen dan menghapus semua berkas yang disimpan di folder cloud pribadi Anda. Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get deleteAccountButton => 'Hapus Akun';

  @override
  String get changePasswordDialogTitle => 'Ubah Kata Sandi';

  @override
  String get newPasswordFieldLabel => 'Kata Sandi Baru';

  @override
  String get confirmPasswordLabel => 'Konfirmasi Kata Sandi';

  @override
  String get enterNewPassword => 'Masukkan kata sandi baru Anda.';

  @override
  String get passwordUpdated => 'Kata sandi diperbarui.';

  @override
  String passwordChangeFailed(String error) {
    return 'Gagal mengubah kata sandi: $error';
  }

  @override
  String get passwordChangeFailedGeneric => 'Gagal mengubah kata sandi.';

  @override
  String get accountDeleted => 'Akun dihapus.';

  @override
  String accountDeletionFailed(String error) {
    return 'Gagal menghapus akun: $error';
  }

  @override
  String get accountDeletionFailedGeneric => 'Gagal menghapus akun.';

  @override
  String get checkForUpdates => 'Periksa Pembaruan';

  @override
  String get checkingForUpdates => 'Memeriksa GitHub Releases...';

  @override
  String versionLabel(String version) {
    return 'Versi $version';
  }

  @override
  String appIsUpToDate(String version) {
    return 'Crowley\'s Cloud sudah merupakan versi terbaru (v$version).';
  }

  @override
  String get updateCheckFailed =>
      'Gagal memeriksa pembaruan. Silakan coba lagi nanti.';

  @override
  String get themeModeTitle => 'Mode Tema';

  @override
  String get themeDark => 'Gelap';

  @override
  String get themeLight => 'Terang';

  @override
  String get themeCustom => 'Kustom';

  @override
  String get themeDarkFull => 'Tema Gelap';

  @override
  String get themeLightFull => 'Tema Terang';

  @override
  String get themeCustomFull => 'Tema Kustom';

  @override
  String get accentColor => 'Warna Aksen';

  @override
  String get primaryAccentColor => 'Warna Aksen Utama';

  @override
  String get selectAccentColor => 'Pilih Warna Aksen';

  @override
  String get backgroundColor => 'Warna Latar Belakang';

  @override
  String get surfaceColor => 'Warna Permukaan';

  @override
  String get textColor => 'Warna Teks';

  @override
  String get subtextColor => 'Warna Subteks';

  @override
  String get borderColor => 'Warna Batas';

  @override
  String get fontSizeScale => 'Skala Ukuran Font';

  @override
  String selectColor(String title) {
    return 'Pilih $title';
  }

  @override
  String get categoriesToSyncDialogTitle => 'Kategori untuk Disinkronkan';

  @override
  String get categoriesToSyncBody =>
      'Pilih satu atau beberapa kategori. Anda juga dapat membatalkan pilihan semua.';

  @override
  String get syncCategorySectionMedia => 'Media';

  @override
  String get syncCategorySectionAudioDocs => 'Audio & Dokumen';

  @override
  String get syncCategorySectionOther => 'Lainnya';

  @override
  String get clearAll => 'Bersihkan Semua';

  @override
  String get noSyncHasRunYet => 'Belum ada sinkronisasi yang berjalan.';

  @override
  String lastRunAt(String date) {
    return 'Terakhir berjalan $date';
  }

  @override
  String syncResultSuccess(int uploaded, int skipped) {
    return 'Menyinkronkan $uploaded, melewati $skipped.';
  }

  @override
  String get syncResultNoFiles =>
      'Tidak ada berkas yang dipilih untuk disinkronkan.';

  @override
  String syncResultPartial(int uploaded, int failed) {
    return 'Menyinkronkan $uploaded, gagal $failed.';
  }

  @override
  String get syncResultAuthRequired => 'Masuk sebelum menyinkronkan.';

  @override
  String get syncResultUnreachable =>
      'Tidak dapat menjangkau server. Sambungan terputus.';

  @override
  String get syncResultFailed => 'Sinkronisasi gagal.';

  @override
  String get serverSetupAddServer => 'Tambah Server';

  @override
  String get serverSetupCardTitle => 'Hubungkan Server';

  @override
  String get serverSetupCardSubtitle =>
      'Tambahkan server berkas rumah Anda dan masuk.';

  @override
  String get serverSetupSubmitButton => 'Simpan Server';

  @override
  String get serverNameLabel => 'Nama Server';

  @override
  String get serverNameHint => 'NAS Rumah';

  @override
  String get baseUrlLabel => 'URL Dasar';

  @override
  String get baseUrlHint => 'https://cloud.example.com';

  @override
  String get allFieldsRequired => 'Semua bidang wajib diisi.';

  @override
  String get localFilesTitle => 'Berkas Lokal';

  @override
  String get serverFilesTitle => 'Berkas Server';

  @override
  String get restoreItemsTitle => 'Pulihkan Item';

  @override
  String restoreItemsBody(int count) {
    return 'Apakah Anda yakin ingin memulihkan $count item?';
  }

  @override
  String get permanentlyDeleteTitle => 'Hapus Permanen';

  @override
  String permanentlyDeleteBody(int count) {
    return 'Apakah Anda yakin ingin menghapus $count item secara permanen? Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get trashIsEmpty => 'Sampah kosong.';

  @override
  String trashRetentionInfo(int days) {
    return 'Item di sampah akan dihapus secara otomatis setelah $days hari.';
  }

  @override
  String get deletionDate => 'Tanggal Penghapusan';

  @override
  String get deletePermanentlyAction => 'Hapus Secara Permanen';

  @override
  String get conflictFileAlreadyExists => 'Berkas Sudah Ada';

  @override
  String conflictNofM(int current, int total) {
    return 'Konflik $current / $total';
  }

  @override
  String get conflictAFileNamed => 'Berkas bernama ';

  @override
  String get conflictAlreadyExistsAt => ' sudah ada di ';

  @override
  String get conflictAlreadyExistsInFolder => ' sudah ada di folder ini.';

  @override
  String get conflictInFolder => 'Di Dalam Folder';

  @override
  String get conflictFromTrash => 'Dari Sampah';

  @override
  String get conflictExisting => 'Yang Ada';

  @override
  String get conflictNewUpload => 'Unggahan Baru';

  @override
  String conflictSizeLabel(String size) {
    return 'Ukuran: $size';
  }

  @override
  String conflictDateLabel(String date) {
    return 'Tanggal: $date';
  }

  @override
  String conflictDeletedLabel(String date) {
    return 'Dihapus: $date';
  }

  @override
  String conflictApplyToRemaining(int count) {
    return 'Terapkan ke $count konflik yang tersisa';
  }

  @override
  String get conflictKeepAllCopies => 'Simpan Semua Salinan';

  @override
  String get conflictOverwriteAll => 'Timpa Semua';

  @override
  String get conflictRestoreAllAsCopies => 'Pulihkan Semua sebagai Salinan';

  @override
  String get conflictRestoreAsCopy => 'Pulihkan sebagai Salinan';

  @override
  String get conflictOverwriteAllRemaining => 'Timpa Semua yang Tersisa';

  @override
  String get conflictSkipAll => 'Lewati Semua';

  @override
  String get conflictSkipAllRemaining => 'Lewati Semua yang Tersisa';

  @override
  String get conflictSkip => 'Lewati';

  @override
  String get conflictOverwrite => 'Timpa';

  @override
  String get transfersTitle => 'Transfer';

  @override
  String get transferResume => 'Lanjutkan';

  @override
  String get transferPause => 'Jeda';

  @override
  String get transferCancel => 'Batal';

  @override
  String get transferResumeAll => 'Lanjutkan Semua';

  @override
  String get transferPauseAll => 'Jeda Semua';

  @override
  String get transferCancelAll => 'Batalkan Semua';

  @override
  String get transferCancelFile => 'Batalkan Berkas';

  @override
  String get noTransfers => 'Tidak ada transfer.';

  @override
  String get transferStatusQueued => 'Dalam antrean';

  @override
  String get transferStatusRunning => 'Berjalan';

  @override
  String get transferStatusPaused => 'Dijeda';

  @override
  String get transferStatusCompleted => 'Selesai';

  @override
  String get transferStatusFailed => 'Gagal';

  @override
  String get transferStatusCanceled => 'Dibatalkan';

  @override
  String get themePresetsSection => 'Preset';

  @override
  String get themeCustomPaletteSection => 'Palet Kustom';

  @override
  String get themeHexRgbLabel => 'Kode HEX RGB';

  @override
  String get themeHexRgbHint => '#FA5252';

  @override
  String get imageViewerNoFetchHandler =>
      'Pengendali pengambilan gambar tidak dikonfigurasi';

  @override
  String get imageViewerFailedToLoad => 'Gagal memuat gambar';

  @override
  String errorDeletingFile(String filename, String error) {
    return 'Gagal menghapus $filename: $error';
  }

  @override
  String errorReadingFile(String error) {
    return 'Gagal membaca berkas: $error';
  }

  @override
  String get syncChannelName => 'Sinkronisasi Latar Belakang';

  @override
  String get syncChannelDescription =>
      'Menampilkan status sinkronisasi berkas latar belakang.';

  @override
  String get storageStatsTitle => 'Statistik Penyimpanan';

  @override
  String get storageStatsUsedSpace => 'Ruang Digunakan';

  @override
  String get storageStatsTotalFiles => 'Total Berkas';

  @override
  String storageStatsNItems(int count) {
    return '$count item';
  }

  @override
  String userFallback(int userId) {
    return 'Pengguna #$userId';
  }

  @override
  String get biometricUnlockReason =>
      'Buka kunci kredensial tersimpan untuk Crowley\'s Cloud.';

  @override
  String get tokenLifetimeEveryOpen => 'Setiap buka aplikasi';

  @override
  String get tokenLifetimeOneHour => 'Setelah 1 jam';

  @override
  String get tokenLifetime1Hour => 'Setelah 1 jam';

  @override
  String get tokenLifetimeOneDay => 'Setelah 1 hari';

  @override
  String get tokenLifetime1Day => 'Setelah 1 hari';

  @override
  String get tokenLifetimeOneWeek => 'Setelah 1 minggu';

  @override
  String get tokenLifetime1Week => 'Setelah 1 minggu';

  @override
  String get tokenLifetimeOneMonth => 'Setelah 1 bulan';

  @override
  String get tokenLifetime1Month => 'Setelah 1 bulan';

  @override
  String get tokenLifetimeThreeMonths => 'Setelah 3 bulan';

  @override
  String get tokenLifetime3Months => 'Setelah 3 bulan';

  @override
  String get tokenLifetimeNever => 'Tidak pernah di perangkat ini';

  @override
  String get cacheLimitUnlimited => 'Tak terbatas';

  @override
  String get syncCategoryOtherFiles => 'Berkas Lainnya';

  @override
  String get internalStorage => 'Penyimpanan Internal';

  @override
  String get localStorageRootName => 'Penyimpanan Internal';

  @override
  String syncNotificationSyncingWith(String serverName) {
    return 'Menyinkronkan dengan $serverName';
  }

  @override
  String syncNotificationPausedTitle(String serverName) {
    return 'Sinkronisasi dengan $serverName dijeda';
  }

  @override
  String get syncNotificationUnreachableBody =>
      'Tidak dapat menjangkau server. Sinkronisasi latar belakang dijeda hingga Anda membuka aplikasi.';

  @override
  String get syncNotificationAuthRequiredBody =>
      'Autentikasi diperlukan. Buka aplikasi untuk masuk.';

  @override
  String syncNotificationFailedTitle(String serverName) {
    return 'Sinkronisasi dengan $serverName gagal';
  }

  @override
  String get syncNotificationGenericErrorBody =>
      'Terjadi kesalahan selama sinkronisasi.';

  @override
  String syncNotificationCompleteTitle(String serverName) {
    return 'Sinkronisasi dengan $serverName selesai';
  }

  @override
  String get syncNotificationCompleteBody => 'Sinkronisasi selesai.';

  @override
  String get syncStatusConnecting => 'Menghubungkan ke server...';

  @override
  String syncStatusConnectionLost(String serverName) {
    return 'Tidak dapat terhubung ke $serverName. Sambungan terputus.';
  }

  @override
  String syncResultServerUnreachableWithServer(String serverName) {
    return 'Tidak dapat terhubung ke $serverName. Sambungan terputus.';
  }

  @override
  String get syncStatusScanningFiles => 'Memindai berkas di perangkat...';

  @override
  String get syncStatusNoFilesFound =>
      'Tidak ada berkas yang ditemukan untuk disinkronkan.';

  @override
  String get syncStatusNoFilesSelected =>
      'Tidak ada berkas yang dipilih untuk disinkronkan.';

  @override
  String syncStatusCalculatingChecksum(
    int current,
    int total,
    String filename,
  ) {
    return 'Menghitung checksum ($current/$total): $filename';
  }

  @override
  String get syncStatusCheckingDuplicates => 'Memeriksa duplikat di server...';

  @override
  String syncStatusSyncingFile(int current, int total, String filename) {
    return 'Menyinkronkan ($current/$total): $filename';
  }

  @override
  String get syncStatusCompleting => 'Menyelesaikan sinkronisasi...';

  @override
  String get showingCachedFiles => 'Menampilkan berkas yang di-cache.';

  @override
  String get showingCachedFilesRefreshFailed =>
      'Menampilkan berkas yang di-cache. Gagal menyegarkan.';

  @override
  String get downloadCanceled => 'Unduhan dibatalkan.';

  @override
  String downloadedNFilesToPath(int count, String path) {
    return 'Mengunduh $count berkas ke $path';
  }

  @override
  String downloadedNFilesFailedM(int downloaded, int failed, String detail) {
    return 'Mengunduh $downloaded berkas, $failed gagal: $detail';
  }

  @override
  String downloadedNFilesWithFailures(int count, int failed, String error) {
    return 'Mengunduh $count berkas, $failed gagal: $error';
  }

  @override
  String createdNShareLinks(int count) {
    return 'Membuat $count tautan berbagi.';
  }

  @override
  String get failedToCreateShareLinks => 'Tidak dapat membuat tautan berbagi.';

  @override
  String get alreadyInSharedScope => 'Sudah berada dalam cakupan bersama.';

  @override
  String sharedNItemsInServer(int count) {
    return 'Membagikan $count item di server.';
  }

  @override
  String sharedNItemsWithFailures(int count, int failed) {
    return 'Membagikan $count item, $failed gagal.';
  }

  @override
  String sharedNItemsFailedM(int shared, int failed) {
    return 'Membagikan $shared item, $failed gagal.';
  }

  @override
  String get folderNameCannotBeEmpty => 'Nama folder tidak boleh kosong.';

  @override
  String get folderAlreadyExists => 'Folder dengan nama tersebut sudah ada.';

  @override
  String get folderCreationOnlyInAllFiles =>
      'Pembuatan folder hanya tersedia di \'Semua Berkas\'.';

  @override
  String get currentDirectoryUnavailable =>
      'Direktori saat ini tidak tersedia.';

  @override
  String get nothingSelected => 'Tidak ada yang dipilih.';

  @override
  String get destinationFolderDoesNotExist => 'Folder tujuan tidak ada.';

  @override
  String cannotMoveFolderIntoItself(String name) {
    return 'Tidak dapat memindahkan folder \"$name\" ke dalam dirinya sendiri.';
  }

  @override
  String failedToMoveItem(String name, String error) {
    return 'Gagal memindahkan $name: $error';
  }

  @override
  String movedNItems(int count) {
    return 'Memindahkan $count item.';
  }

  @override
  String movedNItemsWithFailures(int count, int failed) {
    return 'Memindahkan $count item, $failed gagal.';
  }

  @override
  String movedNItemsFailedM(int moved, int failed) {
    return 'Memindahkan $moved item, $failed gagal.';
  }

  @override
  String get failedToMoveSelectedItems =>
      'Gagal memindahkan item yang dipilih.';

  @override
  String get noFilesWereMoved => 'Tidak ada berkas yang dipindahkan.';

  @override
  String renamedOldToNew(String oldName, String newName) {
    return 'Mengganti nama \"$oldName\" menjadi \"$newName\".';
  }

  @override
  String renamedFileFromTo(String oldName, String newName) {
    return 'Mengganti nama \"$oldName\" menjadi \"$newName\".';
  }

  @override
  String failedToRenameWithStatus(String name, int statusCode) {
    return 'Gagal mengganti nama \"$name\" ($statusCode).';
  }

  @override
  String failedToRenameFileWithCode(String name, int statusCode) {
    return 'Gagal mengganti nama \"$name\" ($statusCode).';
  }

  @override
  String failedToRenameWithError(String name, String error) {
    return 'Gagal mengganti nama \"$name\": $error';
  }

  @override
  String failedToRenameFile(String name, String error) {
    return 'Gagal mengganti nama \"$name\": $error';
  }

  @override
  String get renameConflictAlreadyExists =>
      'Gagal mengganti nama: berkas atau folder dengan nama tersebut sudah ada.';

  @override
  String get renameFailedAlreadyExists =>
      'Gagal mengganti nama: berkas atau folder dengan nama tersebut sudah ada.';

  @override
  String failedToCreateFolderWithCode(int statusCode) {
    return 'Gagal membuat folder (Kode $statusCode).';
  }

  @override
  String deletedNItemsFailedM(int deleted, int failed) {
    return 'Menghapus $deleted item, $failed gagal.';
  }

  @override
  String transferSummaryFiles(int percent, int completed, int total) {
    return '$percent%  $completed/$total berkas';
  }

  @override
  String transferSummaryProgress(int percent, int completed, int total) {
    return '$percent%  $completed/$total berkas';
  }

  @override
  String get downloadFailedGeneric => 'Unduhan gagal';

  @override
  String uploadedNItemsWithFailures(int uploaded, int failed) {
    return 'Mengunggah $uploaded item, $failed gagal';
  }

  @override
  String uploadedNItemsFailedM(int uploaded, int failed) {
    return 'Mengunggah $uploaded item, $failed gagal.';
  }

  @override
  String uploadSummaryFailedCount(int count) {
    return ', $count gagal';
  }

  @override
  String uploadLocalPathEmpty(String name) {
    return '$name: jalur lokal kosong';
  }

  @override
  String uploadErrorLocalPathEmpty(String name) {
    return '$name: jalur lokal kosong';
  }

  @override
  String get directoryUploadFailed => 'Unggahan direktori gagal';

  @override
  String get uploadDirectoryFailed => 'Unggahan direktori gagal';

  @override
  String get localFileNotFound => 'Berkas lokal tidak ditemukan';

  @override
  String get uploadErrorLocalFileNotFound => 'Berkas lokal tidak ditemukan';

  @override
  String get noSessionToken => 'Tidak ada token sesi aktif';

  @override
  String get uploadErrorNoSessionToken => 'Tidak ada token sesi aktif';

  @override
  String get serverDisconnectedStatus => 'Server terputus';

  @override
  String get serverDisconnected => 'Server terputus';

  @override
  String get serverIsUnreachable => 'Tidak dapat menjangkau server.';

  @override
  String get serverUnreachable => 'Tidak dapat menjangkau server.';

  @override
  String get uploadErrorLocalDirectoryNotFound =>
      'Direktori lokal tidak ditemukan';

  @override
  String get uploadErrorFailedToScanDirectory => 'Gagal memindai direktori';

  @override
  String uploadErrorFolderCreateHttp(int statusCode) {
    return 'Gagal membuat folder (HTTP $statusCode)';
  }

  @override
  String get authErrorMissingAccessToken =>
      'Token akses tidak ditemukan dalam respons';

  @override
  String get authErrorMissingRefreshToken =>
      'Token penyegaran tidak ditemukan dalam respons';

  @override
  String get authErrorNoSavedCredentials =>
      'Tidak ada kredensial tersimpan yang tersedia';

  @override
  String get authErrorNoRefreshToken =>
      'Tidak ada token penyegaran yang tersedia';

  @override
  String get authErrorNoActiveSession => 'Tidak ada sesi aktif yang tersedia';

  @override
  String get authErrorNoSavedUsername =>
      'Tidak ada nama pengguna tersimpan yang tersedia';

  @override
  String get updateNoReleasesPublished =>
      'Belum ada rilis yang dipublikasikan.';

  @override
  String get language => 'Bahasa';
}
