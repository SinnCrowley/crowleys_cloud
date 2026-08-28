// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Crowley\'s Cloud';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get rename => 'Renombrar';

  @override
  String get close => 'Cerrar';

  @override
  String get retry => 'Reintentar';

  @override
  String get loading => 'Cargando...';

  @override
  String get confirm => 'Confirmar';

  @override
  String get error => 'Error';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get unknown => 'Desconocido';

  @override
  String get upload => 'Subir';

  @override
  String get download => 'Descargar';

  @override
  String get share => 'Compartir';

  @override
  String get copy => 'Copiar';

  @override
  String get move => 'Mover';

  @override
  String get restore => 'Restaurar';

  @override
  String get apply => 'Aplicar';

  @override
  String get create => 'Crear';

  @override
  String get clear => 'Limpiar';

  @override
  String get add => 'Añadir';

  @override
  String get remove => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get switchLabel => 'Cambiar';

  @override
  String get search => 'Buscar';

  @override
  String get name => 'Nombre';

  @override
  String get date => 'Fecha';

  @override
  String get size => 'Tamaño';

  @override
  String get type => 'Tipo';

  @override
  String get ascending => 'Ascendente';

  @override
  String get descending => 'Descendente';

  @override
  String get allFiles => 'Todos';

  @override
  String get categoryImages => 'Imágenes';

  @override
  String get categoryPhotos => 'Fotos';

  @override
  String get categoryVideos => 'Vídeos';

  @override
  String get categoryAudio => 'Audio';

  @override
  String get categoryDocuments => 'Documentos';

  @override
  String get categoryArchives => 'Archivos';

  @override
  String get categoryShared => 'Compartido';

  @override
  String get categoryOther => 'Otros';

  @override
  String get categoryOtherFiles => 'Otros archivos';

  @override
  String get noFilesFound => 'No se encontraron archivos.';

  @override
  String get noFilesInFolder => 'No hay archivos en esta carpeta.';

  @override
  String get thisActionCannotBeUndone => 'Esta acción no se puede deshacer.';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden.';

  @override
  String get navLocalFiles => 'Archivos locales';

  @override
  String get navServerFiles => 'Archivos del servidor';

  @override
  String get navSettings => 'Configuración';

  @override
  String get navTrash => 'Papelera';

  @override
  String get navLocal => 'Local';

  @override
  String get navServer => 'Servidor';

  @override
  String get addServer => 'Añadir servidor';

  @override
  String get noServersConfigured => 'No hay servidores configurados.';

  @override
  String get addAServerInSettings => 'Añada un servidor en Configuración.';

  @override
  String get addFirstServerHint => 'Añada su primer servidor para continuar.';

  @override
  String get noServersConfiguredYet => 'Aún no hay servidores configurados.';

  @override
  String get crowleysCloudSetup => 'Configuración de Crowley\'s Cloud';

  @override
  String get connect => 'Conectar';

  @override
  String get connecting => 'Conectando...';

  @override
  String get connected => 'Conectado';

  @override
  String get disconnected => 'Desconectado';

  @override
  String get switchServer => 'Cambiar servidor';

  @override
  String get chooseOtherServer => 'Elegir otro servidor';

  @override
  String get switchServerTitle => '¿Cambiar de servidor?';

  @override
  String switchServerBody(String serverName) {
    return '¿Cambiar el servidor activo a «$serverName»?';
  }

  @override
  String get chooseServer => 'Elegir servidor';

  @override
  String get authenticationRequired => 'Se requiere autenticación';

  @override
  String signInToAccess(String serverName) {
    return 'Inicie sesión para acceder a los archivos de $serverName';
  }

  @override
  String get signInWithPassword => 'Iniciar sesión con contraseña';

  @override
  String get useBiometrics => 'Usar biometría';

  @override
  String get openingSignIn => 'Abriendo inicio de sesión...';

  @override
  String get serverConnectionFailed => 'Error de conexión con el servidor';

  @override
  String get unableToConnectToServer =>
      'No se puede conectar al servidor activo.';

  @override
  String unableToConnectTo(String serverName) {
    return 'No se puede conectar a $serverName.';
  }

  @override
  String get searchHint => 'Buscar...';

  @override
  String get searchFilesHint => 'Buscar archivos...';

  @override
  String get searchServerFilesHint => 'Buscar archivos del servidor...';

  @override
  String get searchTrashHint => 'Buscar en la papelera...';

  @override
  String get storagePermissionRequired =>
      'Se requiere permiso de almacenamiento';

  @override
  String get grantPermission => 'Conceder permiso';

  @override
  String get permissionDeniedOpenSettings =>
      'Permiso denegado. Conceda acceso al almacenamiento en Configuración.';

  @override
  String get manageStoragePermissionRequired =>
      'Se requiere permiso para administrar el almacenamiento y explorar carpetas.';

  @override
  String get storagePermissionsRequired =>
      'Se requieren permisos de almacenamiento para sincronizar.';

  @override
  String updateAvailableTitle(String version) {
    return 'Actualización disponible: v$version';
  }

  @override
  String get updateAvailableTapToSeeNew => 'Toque para ver las novedades';

  @override
  String get updateView => 'Ver';

  @override
  String get updateAvailableDialogTitle => 'Actualización disponible';

  @override
  String updateVersionSubtitle(String version) {
    return 'Versión $version';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'Actual: v$version';
  }

  @override
  String updateNewVersion(String version) {
    return 'Nueva: v$version';
  }

  @override
  String get updateWhatsNew => 'Novedades:';

  @override
  String get updateGitHub => 'GitHub';

  @override
  String get updateNoReleaseNotes =>
      'No se proporcionaron notas de la versión.';

  @override
  String get updateLater => 'Más tarde';

  @override
  String get updateDownloadApk => 'Descargar APK';

  @override
  String get updateInstall => 'Actualizar';

  @override
  String get shareLinkTitle => 'Enlace para compartir';

  @override
  String get shareViaLink => 'Compartir mediante enlace';

  @override
  String get shareInServer => 'Compartir en el servidor';

  @override
  String get expiryDays => 'Caducidad (días)';

  @override
  String get expiryNever => 'Nunca';

  @override
  String get expiry1Day => '1 día';

  @override
  String get expiry7Days => '7 días';

  @override
  String get expiry30Days => '30 días';

  @override
  String get expiry90Days => '90 días';

  @override
  String get expiry180Days => '180 días';

  @override
  String get expiry365Days => '365 días';

  @override
  String get createLink => 'Crear enlace';

  @override
  String get sharedLinkCopied => '¡Enlace compartido copiado al portapapeles!';

  @override
  String failedToCopySharedLink(String error) {
    return 'No se pudo copiar el enlace compartido: $error';
  }

  @override
  String get cannotShareThisFileType =>
      'No se puede compartir este tipo de archivo.';

  @override
  String failedToCreateShare(String error) {
    return 'No se pudo crear el recurso compartido: $error';
  }

  @override
  String get newFolderTitle => 'Crear carpeta';

  @override
  String get newFolderHint => 'Nombre de la carpeta';

  @override
  String get newFolder => 'Nueva carpeta';

  @override
  String get folderCreated => 'Carpeta creada.';

  @override
  String failedToCreateFolder(String error) {
    return 'No se pudo crear la carpeta: $error';
  }

  @override
  String get creatingFolder => 'Creando carpeta...';

  @override
  String get renameDialogTitle => 'Renombrar';

  @override
  String get renameHint => 'Nuevo nombre';

  @override
  String get enterNewName => 'Introduzca el nuevo nombre';

  @override
  String get renamedSuccessfully => 'Se cambió el nombre correctamente.';

  @override
  String renameFailed(String error) {
    return 'No se pudo cambiar el nombre: $error';
  }

  @override
  String get moveDialogTitle => 'Mover a';

  @override
  String moveTo(String path) {
    return 'Mover a: $path';
  }

  @override
  String get moveHere => 'Mover aquí';

  @override
  String moveFailed(String error) {
    return 'No se pudo mover: $error';
  }

  @override
  String get movedToFolder => 'Movido a la carpeta.';

  @override
  String copyFailed(String error) {
    return 'No se pudo copiar: $error';
  }

  @override
  String get selectFolder => 'Seleccionar carpeta';

  @override
  String get useThisFolder => 'Usar esta carpeta';

  @override
  String get storageRoot => 'Almacenamiento';

  @override
  String get serverRoot => 'raíz';

  @override
  String deleteNItemsTitle(int count) {
    return '¿Eliminar $count elementos?';
  }

  @override
  String get deleteFilesTitle => '¿Eliminar archivos?';

  @override
  String deleteFilesBody(int count) {
    return '¿Seguro que desea eliminar los $count elementos seleccionados? Esta acción no se puede deshacer.';
  }

  @override
  String get deletePermanently => 'Eliminar definitivamente';

  @override
  String get deletePermanentlyTitle => '¿Eliminar permanentemente?';

  @override
  String deletePermanentlyBody(String filename) {
    return '$filename se eliminará permanentemente.';
  }

  @override
  String get deleteFileTitle => '¿Eliminar archivo?';

  @override
  String deleteFileBody(String filename) {
    return '¿Seguro que desea eliminar $filename? Esta acción no se puede deshacer.';
  }

  @override
  String get deleteServerFileTitle => 'Eliminar definitivamente';

  @override
  String deleteServerFileBody(String filename) {
    return '¿Seguro que desea eliminar permanentemente «$filename»? Esta acción no se puede deshacer.';
  }

  @override
  String get unshareItemsTitle => '¿Dejar de compartir elementos?';

  @override
  String unshareItemsBody(int count) {
    return '¿Seguro que desea dejar de compartir $count elementos seleccionados? Se eliminarán de la carpeta Compartidos.';
  }

  @override
  String get unshare => 'Dejar de compartir';

  @override
  String get moveToTrash => 'Mover a la papelera';

  @override
  String get movedToTrash => 'Movido a la papelera.';

  @override
  String movedNItemsToTrash(int count) {
    return 'Se movieron $count elementos a la papelera.';
  }

  @override
  String failedToMoveToTrash(String error) {
    return 'No se pudo mover a la papelera: $error';
  }

  @override
  String deletedNItems(int count) {
    return 'Se eliminaron $count elementos.';
  }

  @override
  String failedToDelete(String error) {
    return 'No se pudo eliminar: $error';
  }

  @override
  String failedToDeleteItem(String error) {
    return 'Error al eliminar: $error';
  }

  @override
  String deletedFilename(String filename) {
    return 'Se eliminó $filename.';
  }

  @override
  String get failedToOpenFile => 'No se pudo abrir el archivo';

  @override
  String fileDownloadFailed(String error) {
    return 'Error al descargar el archivo: $error';
  }

  @override
  String get downloading => 'Descargando...';

  @override
  String get downloadingFile => 'Descargando archivo...';

  @override
  String downloadComplete(String filename) {
    return 'Descarga completada: $filename';
  }

  @override
  String downloadFailed(String error) {
    return 'Error en la descarga: $error';
  }

  @override
  String get failedToDownloadPreview =>
      'No se pudo descargar la vista previa del archivo';

  @override
  String uploadComplete(String filename) {
    return 'Carga completada: $filename';
  }

  @override
  String uploadFailed(String error) {
    return 'Error en la carga: $error';
  }

  @override
  String get failedToPickFiles => 'No se pudieron seleccionar archivos';

  @override
  String uploadedNItems(int count) {
    return 'Se cargaron $count elementos';
  }

  @override
  String get copiedLinkToClipboard => 'Enlace copiado al portapapeles.';

  @override
  String failedToCopyLink(String error) {
    return 'No se pudo copiar el enlace: $error';
  }

  @override
  String get selectingAll => 'Seleccionando todo...';

  @override
  String get allItemsSelected => 'Todos los elementos seleccionados.';

  @override
  String get failedToLoadSearchResults =>
      'No se pudieron cargar los resultados de búsqueda';

  @override
  String get shareNotSupportedForType =>
      'No se admite compartir este tipo de archivo.';

  @override
  String nSelected(int count) {
    return '$count seleccionados';
  }

  @override
  String get noServerSelected => 'No hay servidor seleccionado';

  @override
  String get pleaseConnectToServerFirst => 'Conéctese primero a un servidor.';

  @override
  String get signInRequired => 'Se requiere iniciar sesión';

  @override
  String pleaseSignInToServer(String serverName) {
    return 'Inicie sesión primero en $serverName.';
  }

  @override
  String get connectingToServer => 'Conectando al servidor...';

  @override
  String connectedToServer(String serverName) {
    return 'Conectado a $serverName.';
  }

  @override
  String connectionFailed(String error) {
    return 'Error de conexión: $error';
  }

  @override
  String failedToConnect(String error) {
    return 'No se pudo conectar: $error';
  }

  @override
  String authFailed(String error) {
    return 'Error de autenticación: $error';
  }

  @override
  String get authFailedGeneric => 'La autenticación falló. Inténtelo de nuevo.';

  @override
  String biometricLoginFailed(String error) {
    return 'El inicio de sesión biométrico falló: $error';
  }

  @override
  String get biometricLoginFailedGeneric =>
      'El inicio de sesión biométrico falló.';

  @override
  String get noServerSessionToken =>
      'No hay token de sesión del servidor. Vuelva a autenticar el servidor.';

  @override
  String failedToSaveServer(String error) {
    return 'No se pudo guardar el servidor: $error';
  }

  @override
  String get addToFolder => 'Añadir a carpeta';

  @override
  String get loginTabLabel => 'Iniciar sesión';

  @override
  String get registerTabLabel => 'Registrarse';

  @override
  String get welcomeBack => 'Bienvenido de nuevo';

  @override
  String get signInToContinue => 'Inicie sesión para continuar';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get joinTheServer => 'Unirse al servidor';

  @override
  String get usernameLabel => 'Nombre de usuario';

  @override
  String get usernameHint => 'Introduzca su nombre de usuario';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get passwordHint => 'Introduzca su contraseña';

  @override
  String get showPassword => 'Mostrar contraseña';

  @override
  String get hidePassword => 'Ocultar contraseña';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get logIn => 'Iniciar sesión';

  @override
  String get loggingIn => 'Iniciando sesión...';

  @override
  String get registering => 'Registrando...';

  @override
  String get forgotPassword => '¿Olvidó la contraseña?';

  @override
  String get doNotHaveAccount => '¿No tiene cuenta? Cambie a Registro.';

  @override
  String get alreadyHaveAccount => '¿Ya tiene cuenta? Cambie a Iniciar sesión.';

  @override
  String get usernameCannotBeEmpty =>
      'El nombre de usuario no puede estar vacío.';

  @override
  String get passwordCannotBeEmpty => 'La contraseña no puede estar vacía.';

  @override
  String get usernameInvalid =>
      'El nombre de usuario debe tener entre 3 y 32 caracteres: letras, números, _ o -.';

  @override
  String get passwordTooShort =>
      'La contraseña debe tener al menos 8 caracteres.';

  @override
  String loginFailed(String error) {
    return 'Error al iniciar sesión: $error';
  }

  @override
  String registrationFailed(String error) {
    return 'Error de registro: $error';
  }

  @override
  String get resetPasswordTitle => 'Restablecer contraseña';

  @override
  String get enterResetCodeTitle => 'Introducir código de restablecimiento';

  @override
  String get resetPasswordStep1Body =>
      'Introduzca su nombre de usuario. El código de verificación de 6 dígitos aparecerá en los registros o consola del servidor.';

  @override
  String get resetPasswordStep2Body =>
      'El código de verificación se ha mostrado en la consola del servidor. Introduzca el código de 6 dígitos y la nueva contraseña.';

  @override
  String get resetCodeLabel => 'Código de restablecimiento';

  @override
  String get resetCodeHint => 'Introduzca el código de 6 dígitos';

  @override
  String get newPasswordLabel => 'Nueva contraseña';

  @override
  String get newPasswordHint => 'Introduzca la nueva contraseña';

  @override
  String get passwordResetSuccessfully =>
      '¡Contraseña restablecida correctamente!';

  @override
  String get usernameIsRequired => 'El nombre de usuario es obligatorio.';

  @override
  String get codeAndPasswordRequired =>
      'El código y la nueva contraseña son obligatorios.';

  @override
  String get failedToRequestReset =>
      'No se pudo solicitar el restablecimiento. Verifique la URL del servidor.';

  @override
  String get failedToResetPassword =>
      'No se pudo restablecer la contraseña. Compruebe el código.';

  @override
  String get pleaseEnterServerUrlFirst =>
      'Introduzca primero una URL de servidor.';

  @override
  String get sendCode => 'Enviar código';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get sectionBackupSync => 'Copia de seguridad y sincronización';

  @override
  String get sectionStorageCache => 'Almacenamiento y caché';

  @override
  String get sectionSecurityBehavior => 'Seguridad y comportamiento';

  @override
  String get sectionAboutUpdates => 'Información y actualizaciones';

  @override
  String get sectionAppearance => 'Apariencia y personalización';

  @override
  String get noServersConfiguredSync => 'No hay servidores configurados';

  @override
  String get addServerBeforeSync =>
      'Añada un servidor antes de configurar la sincronización.';

  @override
  String get selectServerToConfigureSync =>
      'Seleccione un servidor para configurar su sincronización.';

  @override
  String get activeServerSuffix => '· activo';

  @override
  String get folderAndCategorySync => 'Sincronización de carpetas y categorías';

  @override
  String get keepCategoriesSynced =>
      'Mantenga sincronizadas con este servidor las categorías o carpetas locales seleccionadas.';

  @override
  String get addServerBeforeSyncEnable =>
      'Añada un servidor antes de activar la sincronización.';

  @override
  String get onlyOnWifi => 'Solo por Wi‑Fi';

  @override
  String get onlyWhileCharging => 'Solo durante la carga';

  @override
  String get serverTargetDirectory => 'Directorio de destino del servidor';

  @override
  String get serverTargetDirectoryHint => '/backup/mobile_phone';

  @override
  String get synchronizationFrequency => 'Frecuencia de sincronización';

  @override
  String get syncNow => 'Sincronizar ahora';

  @override
  String get syncing => 'Sincronizando...';

  @override
  String get categoriesToSynchronize => 'Categorías para sincronizar';

  @override
  String get noCategoriesSelected => 'No hay categorías seleccionadas.';

  @override
  String nCategoriesSelected(int count) {
    return '$count seleccionados';
  }

  @override
  String get foldersToSynchronize => 'Carpetas para sincronizar';

  @override
  String get noCustomFolders => 'No hay carpetas personalizadas configuradas.';

  @override
  String nFolders(int count) {
    return '$count carpeta(s)';
  }

  @override
  String get addFolder => 'Añadir carpeta';

  @override
  String get removeFolder => 'Eliminar carpeta';

  @override
  String get removeServer => 'Eliminar servidor';

  @override
  String get syncFreqEvery15Min => 'Cada 15 minutos';

  @override
  String get syncFreqEvery30Min => 'Cada 30 minutos';

  @override
  String get syncFreqEvery1Hour => 'Cada hora';

  @override
  String syncFreqEveryNHours(int hours) {
    return 'Cada $hours horas';
  }

  @override
  String syncFreqEveryNMin(int minutes) {
    return 'Cada $minutes minutos';
  }

  @override
  String get syncFreqDaily => 'Diariamente';

  @override
  String get chooseSyncFrequencyTitle => 'Elegir frecuencia de sincronización';

  @override
  String get cacheSize => 'Tamaño de caché';

  @override
  String get refreshTooltip => 'Actualizar';

  @override
  String get cacheLimit => 'Límite de caché';

  @override
  String get downloadPath => 'Ruta de descarga';

  @override
  String get defaultDownloadFolder => 'Carpeta predeterminada de CrowleysCloud';

  @override
  String get clearCache => 'Borrar caché';

  @override
  String get clearCacheTitle => '¿Borrar caché?';

  @override
  String get clearCacheBody =>
      'Esto elimina miniaturas locales y listas de servidor almacenadas en caché.';

  @override
  String get downloadPathDialogTitle => 'Ruta de descarga';

  @override
  String get downloadPathHint => '/storage/emulated/0/CrowleysCloud';

  @override
  String get useDefault => 'Usar predeterminado';

  @override
  String get serverTargetDirDialogTitle => 'Directorio de destino del servidor';

  @override
  String get requireLogin => 'Requerir inicio de sesión';

  @override
  String get biometricLogin => 'Inicio de sesión biométrico';

  @override
  String get biometricLoginSubtitle =>
      'Permitir iniciar sesión con credenciales guardadas mediante biometría.';

  @override
  String get biometricsNotAvailable =>
      'La biometría no está disponible en este dispositivo.';

  @override
  String get showHiddenFiles => 'Mostrar archivos ocultos';

  @override
  String get showHiddenFilesSubtitle =>
      'Mostrar archivos y carpetas que empiezan por punto.';

  @override
  String get changePassword => 'Cambiar contraseña';

  @override
  String changePasswordSubtitle(String serverName) {
    return 'Actualizar la contraseña de $serverName.';
  }

  @override
  String get addServerBeforeChangePassword =>
      'Añada un servidor antes de cambiar la contraseña.';

  @override
  String get deleteUserAccount => 'Eliminar cuenta de usuario';

  @override
  String get deleteUserAccountSubtitle =>
      'Elimina el usuario y todos los archivos privados en la nube.';

  @override
  String get deleteAccountTitle => '¿Eliminar cuenta?';

  @override
  String deleteAccountBody(String serverName) {
    return 'Esto elimina permanentemente su cuenta en $serverName y todos los archivos de su carpeta privada en la nube. Esta acción no se puede deshacer.';
  }

  @override
  String get deleteAccountButton => 'Eliminar cuenta';

  @override
  String get changePasswordDialogTitle => 'Cambiar contraseña';

  @override
  String get newPasswordFieldLabel => 'Nueva contraseña';

  @override
  String get confirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get enterNewPassword => 'Introduzca una nueva contraseña.';

  @override
  String get passwordUpdated => 'Contraseña actualizada.';

  @override
  String passwordChangeFailed(String error) {
    return 'No se pudo cambiar la contraseña: $error';
  }

  @override
  String get passwordChangeFailedGeneric => 'No se pudo cambiar la contraseña.';

  @override
  String get accountDeleted => 'Cuenta eliminada.';

  @override
  String accountDeletionFailed(String error) {
    return 'No se pudo eliminar la cuenta: $error';
  }

  @override
  String get accountDeletionFailedGeneric => 'No se pudo eliminar la cuenta.';

  @override
  String get checkForUpdates => 'Buscar actualizaciones';

  @override
  String get checkingForUpdates => 'Comprobando versiones de GitHub...';

  @override
  String versionLabel(String version) {
    return 'Versión $version';
  }

  @override
  String appIsUpToDate(String version) {
    return 'Crowley\'s Cloud está actualizado (v$version).';
  }

  @override
  String get updateCheckFailed =>
      'No se pudieron comprobar las actualizaciones. Inténtelo más tarde.';

  @override
  String get themeModeTitle => 'Modo de tema';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeCustom => 'Personalizado';

  @override
  String get themeDarkFull => 'Tema oscuro';

  @override
  String get themeLightFull => 'Tema claro';

  @override
  String get themeCustomFull => 'Tema personalizado';

  @override
  String get accentColor => 'Color de acento';

  @override
  String get primaryAccentColor => 'Color de acento principal';

  @override
  String get selectAccentColor => 'Seleccionar color de acento';

  @override
  String get backgroundColor => 'Color de fondo';

  @override
  String get surfaceColor => 'Color de superficie';

  @override
  String get textColor => 'Color del texto';

  @override
  String get subtextColor => 'Color del texto secundario';

  @override
  String get borderColor => 'Color del borde';

  @override
  String get fontSizeScale => 'Escala del tamaño de fuente';

  @override
  String selectColor(String title) {
    return 'Seleccionar $title';
  }

  @override
  String get categoriesToSyncDialogTitle => 'Categorías para sincronizar';

  @override
  String get categoriesToSyncBody =>
      'Elija una o más categorías. Es válido dejar todo sin marcar.';

  @override
  String get syncCategorySectionMedia => 'Multimedia';

  @override
  String get syncCategorySectionAudioDocs => 'Audio y documentos';

  @override
  String get syncCategorySectionOther => 'Otros';

  @override
  String get clearAll => 'Borrar todo';

  @override
  String get noSyncHasRunYet =>
      'Aún no se ha ejecutado ninguna sincronización.';

  @override
  String lastRunAt(String date) {
    return 'Última ejecución: $date';
  }

  @override
  String syncResultSuccess(int uploaded, int skipped) {
    return 'Sincronizados: $uploaded; omitidos: $skipped.';
  }

  @override
  String get syncResultNoFiles =>
      'No hay archivos seleccionados para sincronizar.';

  @override
  String syncResultPartial(int uploaded, int failed) {
    return 'Sincronizados: $uploaded; errores: $failed.';
  }

  @override
  String get syncResultAuthRequired => 'Inicie sesión antes de sincronizar.';

  @override
  String get syncResultUnreachable => 'Servidor inaccesible. Conexión perdida.';

  @override
  String get syncResultFailed => 'La sincronización falló.';

  @override
  String get serverSetupAddServer => 'Añadir servidor';

  @override
  String get serverSetupCardTitle => 'Conectar servidor';

  @override
  String get serverSetupCardSubtitle =>
      'Añada su servidor de archivos doméstico e inicie sesión.';

  @override
  String get serverSetupSubmitButton => 'Guardar servidor';

  @override
  String get serverNameLabel => 'Nombre del servidor';

  @override
  String get serverNameHint => 'NAS doméstico';

  @override
  String get baseUrlLabel => 'URL base';

  @override
  String get baseUrlHint => 'https://cloud.example.com';

  @override
  String get allFieldsRequired => 'Todos los campos son obligatorios.';

  @override
  String get localFilesTitle => 'Archivos locales';

  @override
  String get serverFilesTitle => 'Archivos del servidor';

  @override
  String get restoreItemsTitle => 'Restaurar elementos';

  @override
  String restoreItemsBody(int count) {
    return '¿Seguro que desea restaurar $count elementos?';
  }

  @override
  String get permanentlyDeleteTitle => 'Eliminar permanentemente';

  @override
  String permanentlyDeleteBody(int count) {
    return '¿Seguro que desea eliminar permanentemente $count elementos? Esta acción no se puede deshacer.';
  }

  @override
  String get trashIsEmpty => 'La papelera está vacía.';

  @override
  String trashRetentionInfo(int days) {
    return 'Los elementos de la papelera se eliminan automáticamente después de $days días.';
  }

  @override
  String get deletionDate => 'Fecha de eliminación';

  @override
  String get deletePermanentlyAction => 'Eliminar definitivamente';

  @override
  String get conflictFileAlreadyExists => 'El archivo ya existe';

  @override
  String conflictNofM(int current, int total) {
    return 'Conflicto $current de $total';
  }

  @override
  String get conflictAFileNamed => 'Un archivo llamado ';

  @override
  String get conflictAlreadyExistsAt => ' ya existe en ';

  @override
  String get conflictAlreadyExistsInFolder => ' ya existe en esta carpeta.';

  @override
  String get conflictInFolder => 'En la carpeta';

  @override
  String get conflictFromTrash => 'Desde la papelera';

  @override
  String get conflictExisting => 'Existente';

  @override
  String get conflictNewUpload => 'Nueva carga';

  @override
  String conflictSizeLabel(String size) {
    return 'Tamaño: $size';
  }

  @override
  String conflictDateLabel(String date) {
    return 'Fecha: $date';
  }

  @override
  String conflictDeletedLabel(String date) {
    return 'Eliminado: $date';
  }

  @override
  String conflictApplyToRemaining(int count) {
    return 'Aplicar a los $count conflictos restantes';
  }

  @override
  String get conflictKeepAllCopies => 'Conservar todas las copias';

  @override
  String get conflictOverwriteAll => 'Sobrescribir todo';

  @override
  String get conflictRestoreAllAsCopies => 'Restaurar todo como copias';

  @override
  String get conflictRestoreAsCopy => 'Restaurar como copia';

  @override
  String get conflictOverwriteAllRemaining =>
      'Sobrescribir todos los restantes';

  @override
  String get conflictSkipAll => 'Omitir todo';

  @override
  String get conflictSkipAllRemaining => 'Omitir todos los restantes';

  @override
  String get conflictSkip => 'Omitir';

  @override
  String get conflictOverwrite => 'Sobrescribir';

  @override
  String get transfersTitle => 'Transferencias';

  @override
  String get transferResume => 'Reanudar';

  @override
  String get transferPause => 'Pausar';

  @override
  String get transferCancel => 'Cancelar';

  @override
  String get transferResumeAll => 'Reanudar todo';

  @override
  String get transferPauseAll => 'Pausar todo';

  @override
  String get transferCancelAll => 'Cancelar todo';

  @override
  String get transferCancelFile => 'Cancelar archivo';

  @override
  String get noTransfers => 'No hay transferencias.';

  @override
  String get transferStatusQueued => 'En cola';

  @override
  String get transferStatusRunning => 'En curso';

  @override
  String get transferStatusPaused => 'En pausa';

  @override
  String get transferStatusCompleted => 'Completado';

  @override
  String get transferStatusFailed => 'Error';

  @override
  String get transferStatusCanceled => 'Cancelado';

  @override
  String get themePresetsSection => 'Preajustes';

  @override
  String get themeCustomPaletteSection => 'Paleta personalizada';

  @override
  String get themeHexRgbLabel => 'Código HEX RGB';

  @override
  String get themeHexRgbHint => '#FA5252';

  @override
  String get imageViewerNoFetchHandler =>
      'No hay controlador de carga configurado';

  @override
  String get imageViewerFailedToLoad => 'No se pudo cargar la imagen';

  @override
  String errorDeletingFile(String filename, String error) {
    return 'Error al eliminar $filename: $error';
  }

  @override
  String errorReadingFile(String error) {
    return 'Error al leer el archivo: $error';
  }

  @override
  String get syncChannelName => 'Sincronización en segundo plano';

  @override
  String get syncChannelDescription =>
      'Muestra el estado de los archivos que se sincronizan en segundo plano.';

  @override
  String get storageStatsTitle => 'Estadísticas de almacenamiento';

  @override
  String get storageStatsUsedSpace => 'Espacio usado';

  @override
  String get storageStatsTotalFiles => 'Total de archivos';

  @override
  String storageStatsNItems(int count) {
    return '$count elementos';
  }

  @override
  String userFallback(int userId) {
    return 'Usuario n.º $userId';
  }

  @override
  String get biometricUnlockReason =>
      'Desbloquee las credenciales guardadas para Crowley\'s Cloud.';

  @override
  String get tokenLifetimeEveryOpen => 'En cada apertura de la aplicación';

  @override
  String get tokenLifetimeOneHour => 'Después de 1 hora';

  @override
  String get tokenLifetime1Hour => 'Después de 1 hora';

  @override
  String get tokenLifetimeOneDay => 'Después de 1 día';

  @override
  String get tokenLifetime1Day => 'Después de 1 día';

  @override
  String get tokenLifetimeOneWeek => 'Después de 1 semana';

  @override
  String get tokenLifetime1Week => 'Después de 1 semana';

  @override
  String get tokenLifetimeOneMonth => 'Después de 1 mes';

  @override
  String get tokenLifetime1Month => 'Después de 1 mes';

  @override
  String get tokenLifetimeThreeMonths => 'Después de 3 meses';

  @override
  String get tokenLifetime3Months => 'Después de 3 meses';

  @override
  String get tokenLifetimeNever => 'Nunca en este dispositivo';

  @override
  String get cacheLimitUnlimited => 'Sin límite';

  @override
  String get syncCategoryOtherFiles => 'Otros archivos';

  @override
  String get internalStorage => 'Almacenamiento interno';

  @override
  String get localStorageRootName => 'Almacenamiento interno';

  @override
  String syncNotificationSyncingWith(String serverName) {
    return 'Sincronizando con $serverName';
  }

  @override
  String syncNotificationPausedTitle(String serverName) {
    return 'Sincronización con $serverName pausada';
  }

  @override
  String get syncNotificationUnreachableBody =>
      'El servidor no es accesible. La sincronización en segundo plano está pausada hasta abrir la aplicación.';

  @override
  String get syncNotificationAuthRequiredBody =>
      'Se requiere autenticación. Abra la aplicación para iniciar sesión.';

  @override
  String syncNotificationFailedTitle(String serverName) {
    return 'La sincronización con $serverName falló';
  }

  @override
  String get syncNotificationGenericErrorBody =>
      'Se produjo un error durante la sincronización.';

  @override
  String syncNotificationCompleteTitle(String serverName) {
    return 'Sincronización con $serverName completada';
  }

  @override
  String get syncNotificationCompleteBody => 'Sincronización completada.';

  @override
  String get syncStatusConnecting => 'Conectando al servidor...';

  @override
  String syncStatusConnectionLost(String serverName) {
    return 'No se pudo conectar a $serverName. Conexión perdida.';
  }

  @override
  String syncResultServerUnreachableWithServer(String serverName) {
    return 'No se pudo conectar a $serverName. Conexión perdida.';
  }

  @override
  String get syncStatusScanningFiles =>
      'Buscando archivos en el dispositivo...';

  @override
  String get syncStatusNoFilesFound =>
      'No se encontraron archivos para sincronizar.';

  @override
  String get syncStatusNoFilesSelected =>
      'No hay archivos seleccionados para sincronizar.';

  @override
  String syncStatusCalculatingChecksum(
    int current,
    int total,
    String filename,
  ) {
    return 'Calculando suma de verificación ($current/$total): $filename';
  }

  @override
  String get syncStatusCheckingDuplicates =>
      'Comprobando duplicados en el servidor...';

  @override
  String syncStatusSyncingFile(int current, int total, String filename) {
    return 'Sincronizando ($current/$total): $filename';
  }

  @override
  String get syncStatusCompleting => 'Completando sincronización...';

  @override
  String get showingCachedFiles => 'Mostrando archivos en caché.';

  @override
  String get showingCachedFilesRefreshFailed =>
      'Mostrando archivos en caché. La actualización falló.';

  @override
  String get downloadCanceled => 'Descarga cancelada.';

  @override
  String downloadedNFilesToPath(int count, String path) {
    return 'Se descargaron $count archivo(s) en $path';
  }

  @override
  String downloadedNFilesFailedM(int downloaded, int failed, String detail) {
    return 'Se descargaron $downloaded archivo(s), fallaron $failed: $detail';
  }

  @override
  String downloadedNFilesWithFailures(int count, int failed, String error) {
    return 'Se descargaron $count archivo(s), fallaron $failed: $error';
  }

  @override
  String createdNShareLinks(int count) {
    return 'Se crearon $count enlace(s) compartido(s).';
  }

  @override
  String get failedToCreateShareLinks =>
      'No se pudieron crear enlaces compartidos.';

  @override
  String get alreadyInSharedScope => 'Ya está en el ámbito compartido.';

  @override
  String sharedNItemsInServer(int count) {
    return 'Se compartieron $count elemento(s) en el servidor.';
  }

  @override
  String sharedNItemsWithFailures(int count, int failed) {
    return 'Se compartieron $count elemento(s), fallaron $failed.';
  }

  @override
  String sharedNItemsFailedM(int shared, int failed) {
    return 'Se compartieron $shared elemento(s), fallaron $failed.';
  }

  @override
  String get folderNameCannotBeEmpty =>
      'El nombre de la carpeta no puede estar vacío.';

  @override
  String get folderAlreadyExists => 'La carpeta ya existe.';

  @override
  String get folderCreationOnlyInAllFiles =>
      'La creación de carpetas solo está disponible en Todos los archivos.';

  @override
  String get currentDirectoryUnavailable =>
      'El directorio actual no está disponible.';

  @override
  String get nothingSelected => 'No hay nada seleccionado.';

  @override
  String get destinationFolderDoesNotExist =>
      'La carpeta de destino no existe.';

  @override
  String cannotMoveFolderIntoItself(String name) {
    return 'No se puede mover la carpeta «$name» dentro de sí misma.';
  }

  @override
  String failedToMoveItem(String name, String error) {
    return 'No se pudo mover $name: $error';
  }

  @override
  String movedNItems(int count) {
    return 'Se movieron $count elemento(s).';
  }

  @override
  String movedNItemsWithFailures(int count, int failed) {
    return 'Se movieron $count elemento(s), fallaron $failed.';
  }

  @override
  String movedNItemsFailedM(int moved, int failed) {
    return 'Se movieron $moved elemento(s), fallaron $failed.';
  }

  @override
  String get failedToMoveSelectedItems =>
      'No se pudieron mover los elementos seleccionados.';

  @override
  String get noFilesWereMoved => 'No se movió ningún archivo.';

  @override
  String renamedOldToNew(String oldName, String newName) {
    return 'Se cambió «$oldName» por «$newName».';
  }

  @override
  String renamedFileFromTo(String oldName, String newName) {
    return 'Se cambió «$oldName» por «$newName».';
  }

  @override
  String failedToRenameWithStatus(String name, int statusCode) {
    return 'No se pudo cambiar el nombre de «$name» ($statusCode).';
  }

  @override
  String failedToRenameFileWithCode(String name, int statusCode) {
    return 'No se pudo cambiar el nombre de «$name» ($statusCode).';
  }

  @override
  String failedToRenameWithError(String name, String error) {
    return 'No se pudo cambiar el nombre de «$name»: $error';
  }

  @override
  String failedToRenameFile(String name, String error) {
    return 'No se pudo cambiar el nombre de «$name»: $error';
  }

  @override
  String get renameConflictAlreadyExists =>
      'No se pudo cambiar el nombre: ya existe un archivo o carpeta con ese nombre.';

  @override
  String get renameFailedAlreadyExists =>
      'No se pudo cambiar el nombre: ya existe un archivo o carpeta con ese nombre.';

  @override
  String failedToCreateFolderWithCode(int statusCode) {
    return 'No se pudo crear la carpeta ($statusCode).';
  }

  @override
  String deletedNItemsFailedM(int deleted, int failed) {
    return 'Se eliminaron $deleted elemento(s), fallaron $failed.';
  }

  @override
  String transferSummaryFiles(int percent, int completed, int total) {
    return '$percent%  $completed/$total archivos';
  }

  @override
  String transferSummaryProgress(int percent, int completed, int total) {
    return '$percent%  $completed/$total archivos';
  }

  @override
  String get downloadFailedGeneric => 'La descarga falló';

  @override
  String uploadedNItemsWithFailures(int uploaded, int failed) {
    return 'Se cargaron $uploaded elemento(s), fallaron $failed';
  }

  @override
  String uploadedNItemsFailedM(int uploaded, int failed) {
    return 'Se cargaron $uploaded elemento(s), fallaron $failed.';
  }

  @override
  String uploadSummaryFailedCount(int count) {
    return ', fallaron $count';
  }

  @override
  String uploadLocalPathEmpty(String name) {
    return '$name: la ruta local está vacía';
  }

  @override
  String uploadErrorLocalPathEmpty(String name) {
    return '$name: la ruta local está vacía';
  }

  @override
  String get directoryUploadFailed => 'La carga del directorio falló';

  @override
  String get uploadDirectoryFailed => 'La carga del directorio falló';

  @override
  String get localFileNotFound => 'No se encontró el archivo local';

  @override
  String get uploadErrorLocalFileNotFound => 'No se encontró el archivo local';

  @override
  String get noSessionToken => 'No hay token de sesión activo';

  @override
  String get uploadErrorNoSessionToken => 'No hay token de sesión activo';

  @override
  String get serverDisconnectedStatus => 'Servidor desconectado';

  @override
  String get serverDisconnected => 'Servidor desconectado';

  @override
  String get serverIsUnreachable => 'El servidor no es accesible.';

  @override
  String get serverUnreachable => 'El servidor no es accesible.';

  @override
  String get uploadErrorLocalDirectoryNotFound =>
      'No se encontró el directorio local';

  @override
  String get uploadErrorFailedToScanDirectory =>
      'No se pudo explorar el directorio';

  @override
  String uploadErrorFolderCreateHttp(int statusCode) {
    return 'No se pudo crear la carpeta (HTTP $statusCode)';
  }

  @override
  String get authErrorMissingAccessToken =>
      'Falta el token de acceso en la respuesta';

  @override
  String get authErrorMissingRefreshToken =>
      'Falta el token de actualización en la respuesta';

  @override
  String get authErrorNoSavedCredentials =>
      'No hay credenciales guardadas disponibles';

  @override
  String get authErrorNoRefreshToken =>
      'No hay token de actualización disponible';

  @override
  String get authErrorNoActiveSession => 'No hay sesión activa disponible';

  @override
  String get authErrorNoSavedUsername =>
      'No hay nombre de usuario guardado disponible';

  @override
  String get updateNoReleasesPublished =>
      'Aún no se ha publicado ninguna versión.';

  @override
  String get language => 'Idioma';
}
