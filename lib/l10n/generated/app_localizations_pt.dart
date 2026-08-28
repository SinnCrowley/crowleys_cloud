// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

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
  String get rename => 'Renomear';

  @override
  String get close => 'Fechar';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get loading => 'A carregar...';

  @override
  String get confirm => 'Confirmar';

  @override
  String get error => 'Erro';

  @override
  String errorWithMessage(String message) {
    return 'Erro: $message';
  }

  @override
  String get unknown => 'Desconhecido';

  @override
  String get upload => 'Carregar';

  @override
  String get download => 'Transferir';

  @override
  String get share => 'Partilhar';

  @override
  String get copy => 'Copiar';

  @override
  String get move => 'Mover';

  @override
  String get restore => 'Restaurar';

  @override
  String get apply => 'Aplicar';

  @override
  String get create => 'Criar';

  @override
  String get clear => 'Limpar';

  @override
  String get add => 'Adicionar';

  @override
  String get remove => 'Remover';

  @override
  String get edit => 'Editar';

  @override
  String get switchLabel => 'Alternar';

  @override
  String get search => 'Pesquisar';

  @override
  String get name => 'Nome';

  @override
  String get date => 'Data';

  @override
  String get size => 'Tamanho';

  @override
  String get type => 'Tipo';

  @override
  String get ascending => 'Crescente';

  @override
  String get descending => 'Decrescente';

  @override
  String get allFiles => 'Todos';

  @override
  String get categoryImages => 'Imagens';

  @override
  String get categoryPhotos => 'Fotos';

  @override
  String get categoryVideos => 'Vídeos';

  @override
  String get categoryAudio => 'Áudio';

  @override
  String get categoryDocuments => 'Documentos';

  @override
  String get categoryArchives => 'Ficheiros comprimidos';

  @override
  String get categoryShared => 'Partilhados';

  @override
  String get categoryOther => 'Outros';

  @override
  String get categoryOtherFiles => 'Outros ficheiros';

  @override
  String get noFilesFound => 'Nenhum ficheiro encontrado.';

  @override
  String get noFilesInFolder => 'Não existem ficheiros nesta pasta.';

  @override
  String get thisActionCannotBeUndone => 'Esta ação não pode ser anulada.';

  @override
  String get passwordsDoNotMatch => 'As palavras-passe não coincidem.';

  @override
  String get navLocalFiles => 'Ficheiros locais';

  @override
  String get navServerFiles => 'Ficheiros do servidor';

  @override
  String get navSettings => 'Definições';

  @override
  String get navTrash => 'Reciclagem';

  @override
  String get navLocal => 'Local';

  @override
  String get navServer => 'Servidor';

  @override
  String get addServer => 'Adicionar servidor';

  @override
  String get noServersConfigured => 'Nenhum servidor configurado.';

  @override
  String get addAServerInSettings => 'Adicione um servidor nas definições.';

  @override
  String get addFirstServerHint =>
      'Adicione o seu primeiro servidor para continuar.';

  @override
  String get noServersConfiguredYet => 'Ainda não há servidores configurados.';

  @override
  String get crowleysCloudSetup => 'Configuração do Crowley\'s Cloud';

  @override
  String get connect => 'Ligar';

  @override
  String get connecting => 'A ligar...';

  @override
  String get connected => 'Ligado';

  @override
  String get disconnected => 'Desligado';

  @override
  String get switchServer => 'Mudar de servidor';

  @override
  String get chooseOtherServer => 'Escolher outro servidor';

  @override
  String get switchServerTitle => 'Mudar de servidor?';

  @override
  String switchServerBody(String serverName) {
    return 'Mudar o servidor ativo para “$serverName”?';
  }

  @override
  String get chooseServer => 'Escolher servidor';

  @override
  String get authenticationRequired => 'Autenticação necessária';

  @override
  String signInToAccess(String serverName) {
    return 'Inicie sessão para aceder aos ficheiros em $serverName';
  }

  @override
  String get signInWithPassword => 'Iniciar sessão com palavra-passe';

  @override
  String get useBiometrics => 'Usar biometria';

  @override
  String get openingSignIn => 'A abrir o ecrã de início de sessão...';

  @override
  String get serverConnectionFailed => 'Falha na ligação ao servidor';

  @override
  String get unableToConnectToServer =>
      'Não foi possível ligar ao servidor ativo.';

  @override
  String unableToConnectTo(String serverName) {
    return 'Não foi possível ligar a $serverName.';
  }

  @override
  String get searchHint => 'Pesquisar...';

  @override
  String get searchFilesHint => 'Pesquisar ficheiros...';

  @override
  String get searchServerFilesHint => 'Pesquisar ficheiros do servidor...';

  @override
  String get searchTrashHint => 'Pesquisar na reciclagem...';

  @override
  String get storagePermissionRequired =>
      'Permissão de armazenamento necessária';

  @override
  String get grantPermission => 'Conceder permissão';

  @override
  String get permissionDeniedOpenSettings =>
      'Permissão recusada. Conceda acesso ao armazenamento nas definições.';

  @override
  String get manageStoragePermissionRequired =>
      'A permissão para gerir o armazenamento é necessária para navegar e selecionar pastas.';

  @override
  String get storagePermissionsRequired =>
      'São necessárias permissões de armazenamento para realizar a sincronização.';

  @override
  String updateAvailableTitle(String version) {
    return 'Atualização disponível: v$version';
  }

  @override
  String get updateAvailableTapToSeeNew => 'Toque para ver as novidades';

  @override
  String get updateView => 'Ver';

  @override
  String get updateAvailableDialogTitle => 'Atualização disponível';

  @override
  String updateVersionSubtitle(String version) {
    return 'Versão $version';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'Atual: v$version';
  }

  @override
  String updateNewVersion(String version) {
    return 'Nova: v$version';
  }

  @override
  String get updateWhatsNew => 'Novidades:';

  @override
  String get updateGitHub => 'GitHub';

  @override
  String get updateNoReleaseNotes => 'Nenhuma nota de versão fornecida.';

  @override
  String get updateLater => 'Mais tarde';

  @override
  String get updateDownloadApk => 'Transferir APK';

  @override
  String get updateInstall => 'Atualizar';

  @override
  String get shareLinkTitle => 'Ligação de partilha';

  @override
  String get shareViaLink => 'Partilhar por ligação';

  @override
  String get shareInServer => 'Partilhar no servidor';

  @override
  String get expiryDays => 'Expiração (dias)';

  @override
  String get expiryNever => 'Nunca';

  @override
  String get expiry1Day => '1 dia';

  @override
  String get expiry7Days => '7 dias';

  @override
  String get expiry30Days => '30 dias';

  @override
  String get expiry90Days => '90 dias';

  @override
  String get expiry180Days => '180 dias';

  @override
  String get expiry365Days => '365 dias';

  @override
  String get createLink => 'Criar ligação';

  @override
  String get sharedLinkCopied =>
      'Ligação de partilha copiada para a área de transferência!';

  @override
  String failedToCopySharedLink(String error) {
    return 'Não foi possível copiar a ligação de partilha: $error';
  }

  @override
  String get cannotShareThisFileType =>
      'Não é possível partilhar este tipo de ficheiro.';

  @override
  String failedToCreateShare(String error) {
    return 'Não foi possível criar a partilha: $error';
  }

  @override
  String get newFolderTitle => 'Criar pasta';

  @override
  String get newFolderHint => 'Nome da pasta';

  @override
  String get newFolder => 'Nova pasta';

  @override
  String get folderCreated => 'Pasta criada.';

  @override
  String failedToCreateFolder(String error) {
    return 'Não foi possível criar a pasta: $error';
  }

  @override
  String get creatingFolder => 'A criar pasta...';

  @override
  String get renameDialogTitle => 'Renomear';

  @override
  String get renameHint => 'Novo nome';

  @override
  String get enterNewName => 'Introduza o novo nome';

  @override
  String get renamedSuccessfully => 'Renomeado com sucesso.';

  @override
  String renameFailed(String error) {
    return 'Falha ao renomear: $error';
  }

  @override
  String get moveDialogTitle => 'Mover para';

  @override
  String moveTo(String path) {
    return 'Mover para: $path';
  }

  @override
  String get moveHere => 'Mover para aqui';

  @override
  String moveFailed(String error) {
    return 'Falha ao mover: $error';
  }

  @override
  String get movedToFolder => 'Movido para a pasta.';

  @override
  String copyFailed(String error) {
    return 'Falha ao copiar: $error';
  }

  @override
  String get selectFolder => 'Selecionar pasta';

  @override
  String get useThisFolder => 'Usar esta pasta';

  @override
  String get storageRoot => 'Armazenamento';

  @override
  String get serverRoot => 'Raiz';

  @override
  String deleteNItemsTitle(int count) {
    return 'Eliminar $count itens?';
  }

  @override
  String get deleteFilesTitle => 'Eliminar ficheiros?';

  @override
  String deleteFilesBody(int count) {
    return 'Tem a certeza de que pretende eliminar os $count itens selecionados? Esta ação não pode ser anulada.';
  }

  @override
  String get deletePermanently => 'Eliminar permanentemente';

  @override
  String get deletePermanentlyTitle => 'Eliminar permanentemente?';

  @override
  String deletePermanentlyBody(String filename) {
    return '$filename será eliminado permanentemente.';
  }

  @override
  String get deleteFileTitle => 'Eliminar ficheiro?';

  @override
  String deleteFileBody(String filename) {
    return 'Tem a certeza de que pretende eliminar $filename? Esta ação não pode ser anulada.';
  }

  @override
  String get deleteServerFileTitle => 'Eliminar permanentemente';

  @override
  String deleteServerFileBody(String filename) {
    return 'Tem a certeza de que pretende eliminar permanentemente “$filename”? Esta ação não pode ser anulada.';
  }

  @override
  String get unshareItemsTitle => 'Parar de partilhar itens?';

  @override
  String unshareItemsBody(int count) {
    return 'Tem a certeza de que pretende parar de partilhar os $count itens selecionados? Serão removidos da pasta Partilhados.';
  }

  @override
  String get unshare => 'Parar partilha';

  @override
  String get moveToTrash => 'Mover para a reciclagem';

  @override
  String get movedToTrash => 'Movido para a reciclagem.';

  @override
  String movedNItemsToTrash(int count) {
    return '$count itens movidos para a reciclagem.';
  }

  @override
  String failedToMoveToTrash(String error) {
    return 'Falha ao mover para a reciclagem: $error';
  }

  @override
  String deletedNItems(int count) {
    return '$count itens eliminados.';
  }

  @override
  String failedToDelete(String error) {
    return 'Falha ao eliminar: $error';
  }

  @override
  String failedToDeleteItem(String error) {
    return 'Falha ao eliminar: $error';
  }

  @override
  String deletedFilename(String filename) {
    return '$filename eliminado.';
  }

  @override
  String get failedToOpenFile => 'Não foi possível abrir o ficheiro';

  @override
  String fileDownloadFailed(String error) {
    return 'Falha ao transferir o ficheiro: $error';
  }

  @override
  String get downloading => 'A transferir...';

  @override
  String get downloadingFile => 'A transferir ficheiro...';

  @override
  String downloadComplete(String filename) {
    return 'Transferência concluída: $filename';
  }

  @override
  String downloadFailed(String error) {
    return 'Falha na transferência: $error';
  }

  @override
  String get failedToDownloadPreview =>
      'Não foi possível transferir a pré-visualização do ficheiro';

  @override
  String uploadComplete(String filename) {
    return 'Carregamento concluído: $filename';
  }

  @override
  String uploadFailed(String error) {
    return 'Falha no carregamento: $error';
  }

  @override
  String get failedToPickFiles => 'Não foi possível selecionar os ficheiros';

  @override
  String uploadedNItems(int count) {
    return '$count item(ns) carregado(s)';
  }

  @override
  String get copiedLinkToClipboard =>
      'Ligação copiada para a área de transferência.';

  @override
  String failedToCopyLink(String error) {
    return 'Não foi possível copiar a ligação: $error';
  }

  @override
  String get selectingAll => 'A selecionar tudo...';

  @override
  String get allItemsSelected => 'Todos os itens selecionados.';

  @override
  String get failedToLoadSearchResults =>
      'Não foi possível carregar os resultados da pesquisa';

  @override
  String get shareNotSupportedForType =>
      'A partilha não é compatível com este tipo de ficheiro.';

  @override
  String nSelected(int count) {
    return '$count selecionados';
  }

  @override
  String get noServerSelected => 'Nenhum servidor selecionado';

  @override
  String get pleaseConnectToServerFirst => 'Ligue-se primeiro a um servidor.';

  @override
  String get signInRequired => 'É necessário iniciar sessão';

  @override
  String pleaseSignInToServer(String serverName) {
    return 'Inicie sessão primeiro em $serverName.';
  }

  @override
  String get connectingToServer => 'A ligar ao servidor...';

  @override
  String connectedToServer(String serverName) {
    return 'Ligado a $serverName.';
  }

  @override
  String connectionFailed(String error) {
    return 'Falha na ligação: $error';
  }

  @override
  String failedToConnect(String error) {
    return 'Não foi possível ligar: $error';
  }

  @override
  String authFailed(String error) {
    return 'Falha na autenticação: $error';
  }

  @override
  String get authFailedGeneric => 'Falha na autenticação. Tente novamente.';

  @override
  String biometricLoginFailed(String error) {
    return 'Falha na autenticação biométrica: $error';
  }

  @override
  String get biometricLoginFailedGeneric => 'Falha na autenticação biométrica.';

  @override
  String get noServerSessionToken =>
      'Nenhum token de sessão do servidor. Autentique o servidor novamente.';

  @override
  String failedToSaveServer(String error) {
    return 'Não foi possível guardar o servidor: $error';
  }

  @override
  String get addToFolder => 'Adicionar à pasta';

  @override
  String get loginTabLabel => 'Iniciar sessão';

  @override
  String get registerTabLabel => 'Registar';

  @override
  String get welcomeBack => 'Bem-vindo de volta';

  @override
  String get signInToContinue => 'Inicie sessão para continuar';

  @override
  String get createAccount => 'Criar conta';

  @override
  String get joinTheServer => 'Aceder ao servidor';

  @override
  String get usernameLabel => 'Nome de utilizador';

  @override
  String get usernameHint => 'Introduza o seu nome de utilizador';

  @override
  String get passwordLabel => 'Palavra-passe';

  @override
  String get passwordHint => 'Introduza a sua palavra-passe';

  @override
  String get showPassword => 'Mostrar palavra-passe';

  @override
  String get hidePassword => 'Ocultar palavra-passe';

  @override
  String get confirmPassword => 'Confirmar palavra-passe';

  @override
  String get logIn => 'Iniciar sessão';

  @override
  String get loggingIn => 'A iniciar sessão...';

  @override
  String get registering => 'A registar...';

  @override
  String get forgotPassword => 'Esqueceu-se da palavra-passe?';

  @override
  String get doNotHaveAccount => 'Não tem conta? Mude para Registo.';

  @override
  String get alreadyHaveAccount => 'Já tem conta? Mude para Iniciar sessão.';

  @override
  String get usernameCannotBeEmpty =>
      'O nome de utilizador não pode estar vazio.';

  @override
  String get passwordCannotBeEmpty => 'A palavra-passe não pode estar vazia.';

  @override
  String get usernameInvalid =>
      'O nome de utilizador deve ter 3–32 carateres: letras, números, _ ou -.';

  @override
  String get passwordTooShort =>
      'A palavra-passe deve ter pelo menos 8 carateres.';

  @override
  String loginFailed(String error) {
    return 'Falha ao iniciar sessão: $error';
  }

  @override
  String registrationFailed(String error) {
    return 'Falha no registo: $error';
  }

  @override
  String get resetPasswordTitle => 'Repor palavra-passe';

  @override
  String get enterResetCodeTitle => 'Introduza o código de reposição';

  @override
  String get resetPasswordStep1Body =>
      'Introduza o seu nome de utilizador. O código de verificação de 6 dígitos será apresentado na consola/registos do servidor.';

  @override
  String get resetPasswordStep2Body =>
      'O código de verificação foi apresentado na consola do servidor. Introduza o código de 6 dígitos e a sua nova palavra-passe.';

  @override
  String get resetCodeLabel => 'Código de reposição';

  @override
  String get resetCodeHint => 'Introduza o código de 6 dígitos';

  @override
  String get newPasswordLabel => 'Nova palavra-passe';

  @override
  String get newPasswordHint => 'Introduza a nova palavra-passe';

  @override
  String get passwordResetSuccessfully => 'Palavra-passe reposta com sucesso!';

  @override
  String get usernameIsRequired => 'O nome de utilizador é obrigatório.';

  @override
  String get codeAndPasswordRequired =>
      'O código e a nova palavra-passe são obrigatórios.';

  @override
  String get failedToRequestReset =>
      'Não foi possível solicitar a reposição. Verifique o URL do servidor.';

  @override
  String get failedToResetPassword =>
      'Não foi possível repor a palavra-passe. Verifique o código.';

  @override
  String get pleaseEnterServerUrlFirst =>
      'Introduza primeiro o URL do servidor.';

  @override
  String get sendCode => 'Enviar código';

  @override
  String get settingsTitle => 'Definições';

  @override
  String get sectionBackupSync => 'Cópia de segurança e sincronização';

  @override
  String get sectionStorageCache => 'Armazenamento e cache';

  @override
  String get sectionSecurityBehavior => 'Segurança e comportamento';

  @override
  String get sectionAboutUpdates => 'Sobre e atualizações';

  @override
  String get sectionAppearance => 'Aparência e personalização';

  @override
  String get noServersConfiguredSync => 'Nenhum servidor configurado';

  @override
  String get addServerBeforeSync =>
      'Adicione um servidor antes de configurar a sincronização.';

  @override
  String get selectServerToConfigureSync =>
      'Selecione um servidor para configurar as suas opções de sincronização.';

  @override
  String get activeServerSuffix => '· ativo';

  @override
  String get folderAndCategorySync => 'Sincronização de pastas e categorias';

  @override
  String get keepCategoriesSynced =>
      'Mantenha as categorias ou pastas locais selecionadas sincronizadas com este servidor.';

  @override
  String get addServerBeforeSyncEnable =>
      'Adicione um servidor antes de ativar a sincronização.';

  @override
  String get onlyOnWifi => 'Apenas em Wi-Fi';

  @override
  String get onlyWhileCharging => 'Apenas durante o carregamento';

  @override
  String get serverTargetDirectory => 'Diretório de destino no servidor';

  @override
  String get serverTargetDirectoryHint => '/backup/mobile_phone';

  @override
  String get synchronizationFrequency => 'Frequência de sincronização';

  @override
  String get syncNow => 'Sincronizar agora';

  @override
  String get syncing => 'A sincronizar...';

  @override
  String get categoriesToSynchronize => 'Categorias para sincronizar';

  @override
  String get noCategoriesSelected => 'Nenhuma categoria selecionada.';

  @override
  String nCategoriesSelected(int count) {
    return '$count selecionados';
  }

  @override
  String get foldersToSynchronize => 'Pastas para sincronizar';

  @override
  String get noCustomFolders => 'Nenhuma pasta personalizada configurada.';

  @override
  String nFolders(int count) {
    return '$count pasta(s)';
  }

  @override
  String get addFolder => 'Adicionar pasta';

  @override
  String get removeFolder => 'Remover pasta';

  @override
  String get removeServer => 'Remover servidor';

  @override
  String get syncFreqEvery15Min => 'A cada 15 minutos';

  @override
  String get syncFreqEvery30Min => 'A cada 30 minutos';

  @override
  String get syncFreqEvery1Hour => 'A cada hora';

  @override
  String syncFreqEveryNHours(int hours) {
    return 'A cada $hours horas';
  }

  @override
  String syncFreqEveryNMin(int minutes) {
    return 'A cada $minutes minutos';
  }

  @override
  String get syncFreqDaily => 'Diariamente';

  @override
  String get chooseSyncFrequencyTitle => 'Escolher frequência de sincronização';

  @override
  String get cacheSize => 'Tamanho da cache';

  @override
  String get refreshTooltip => 'Atualizar';

  @override
  String get cacheLimit => 'Limite da cache';

  @override
  String get downloadPath => 'Caminho de transferência';

  @override
  String get defaultDownloadFolder => 'Pasta predefinida do CrowleysCloud';

  @override
  String get clearCache => 'Limpar cache';

  @override
  String get clearCacheTitle => 'Limpar cache?';

  @override
  String get clearCacheBody =>
      'Esta ação remove as miniaturas locais e as listas de servidores em cache.';

  @override
  String get downloadPathDialogTitle => 'Caminho de transferência';

  @override
  String get downloadPathHint => '/storage/emulated/0/CrowleysCloud';

  @override
  String get useDefault => 'Usar predefinição';

  @override
  String get serverTargetDirDialogTitle => 'Diretório de destino no servidor';

  @override
  String get requireLogin => 'Exigir início de sessão';

  @override
  String get biometricLogin => 'Autenticação biométrica';

  @override
  String get biometricLoginSubtitle =>
      'Permitir início de sessão com credenciais guardadas através de biometria.';

  @override
  String get biometricsNotAvailable =>
      'A biometria não está disponível neste dispositivo.';

  @override
  String get showHiddenFiles => 'Mostrar ficheiros ocultos';

  @override
  String get showHiddenFilesSubtitle =>
      'Mostrar ficheiros e pastas que comecem por ponto.';

  @override
  String get changePassword => 'Alterar palavra-passe';

  @override
  String changePasswordSubtitle(String serverName) {
    return 'Atualizar a palavra-passe de $serverName.';
  }

  @override
  String get addServerBeforeChangePassword =>
      'Adicione um servidor antes de alterar a palavra-passe.';

  @override
  String get deleteUserAccount => 'Eliminar conta de utilizador';

  @override
  String get deleteUserAccountSubtitle =>
      'Elimina o utilizador e todos os ficheiros da nuvem privada.';

  @override
  String get deleteAccountTitle => 'Eliminar conta?';

  @override
  String deleteAccountBody(String serverName) {
    return 'Esta ação elimina permanentemente a sua conta em $serverName e remove todos os ficheiros guardados na sua pasta de nuvem privada. Não é possível anular.';
  }

  @override
  String get deleteAccountButton => 'Eliminar conta';

  @override
  String get changePasswordDialogTitle => 'Alterar palavra-passe';

  @override
  String get newPasswordFieldLabel => 'Nova palavra-passe';

  @override
  String get confirmPasswordLabel => 'Confirmar palavra-passe';

  @override
  String get enterNewPassword => 'Introduza uma nova palavra-passe.';

  @override
  String get passwordUpdated => 'Palavra-passe atualizada.';

  @override
  String passwordChangeFailed(String error) {
    return 'Falha ao alterar a palavra-passe: $error';
  }

  @override
  String get passwordChangeFailedGeneric => 'Falha ao alterar a palavra-passe.';

  @override
  String get accountDeleted => 'Conta eliminada.';

  @override
  String accountDeletionFailed(String error) {
    return 'Falha ao eliminar a conta: $error';
  }

  @override
  String get accountDeletionFailedGeneric => 'Falha ao eliminar a conta.';

  @override
  String get checkForUpdates => 'Verificar atualizações';

  @override
  String get checkingForUpdates => 'A verificar versões no GitHub...';

  @override
  String versionLabel(String version) {
    return 'Versão $version';
  }

  @override
  String appIsUpToDate(String version) {
    return 'O Crowley\'s Cloud está atualizado (v$version).';
  }

  @override
  String get updateCheckFailed =>
      'Não foi possível verificar atualizações. Tente novamente mais tarde.';

  @override
  String get themeModeTitle => 'Modo do tema';

  @override
  String get themeDark => 'Escuro';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeCustom => 'Personalizado';

  @override
  String get themeDarkFull => 'Tema escuro';

  @override
  String get themeLightFull => 'Tema claro';

  @override
  String get themeCustomFull => 'Tema personalizado';

  @override
  String get accentColor => 'Cor de destaque';

  @override
  String get primaryAccentColor => 'Cor de destaque principal';

  @override
  String get selectAccentColor => 'Selecionar cor de destaque';

  @override
  String get backgroundColor => 'Cor de fundo';

  @override
  String get surfaceColor => 'Cor da superfície';

  @override
  String get textColor => 'Cor do texto';

  @override
  String get subtextColor => 'Cor do texto secundário';

  @override
  String get borderColor => 'Cor do contorno';

  @override
  String get fontSizeScale => 'Escala do tamanho da fonte';

  @override
  String selectColor(String title) {
    return 'Selecionar $title';
  }

  @override
  String get categoriesToSyncDialogTitle => 'Categorias para sincronizar';

  @override
  String get categoriesToSyncBody =>
      'Escolha uma ou mais categorias. Deixar tudo desmarcado também é válido.';

  @override
  String get syncCategorySectionMedia => 'Multimédia';

  @override
  String get syncCategorySectionAudioDocs => 'Áudio e documentos';

  @override
  String get syncCategorySectionOther => 'Outros';

  @override
  String get clearAll => 'Limpar tudo';

  @override
  String get noSyncHasRunYet => 'Nenhuma sincronização foi executada ainda.';

  @override
  String lastRunAt(String date) {
    return 'Última execução: $date';
  }

  @override
  String syncResultSuccess(int uploaded, int skipped) {
    return '$uploaded sincronizados, $skipped ignorados.';
  }

  @override
  String get syncResultNoFiles =>
      'Nenhum ficheiro selecionado para sincronização.';

  @override
  String syncResultPartial(int uploaded, int failed) {
    return '$uploaded sincronizados, $failed falharam.';
  }

  @override
  String get syncResultAuthRequired => 'Inicie sessão antes de sincronizar.';

  @override
  String get syncResultUnreachable => 'Servidor inacessível. Ligação perdida.';

  @override
  String get syncResultFailed => 'Falha na sincronização.';

  @override
  String get serverSetupAddServer => 'Adicionar servidor';

  @override
  String get serverSetupCardTitle => 'Ligar servidor';

  @override
  String get serverSetupCardSubtitle =>
      'Adicione o seu servidor de ficheiros pessoal e inicie sessão.';

  @override
  String get serverSetupSubmitButton => 'Guardar servidor';

  @override
  String get serverNameLabel => 'Nome do servidor';

  @override
  String get serverNameHint => 'NAS pessoal';

  @override
  String get baseUrlLabel => 'URL base';

  @override
  String get baseUrlHint => 'https://cloud.example.com';

  @override
  String get allFieldsRequired => 'Todos os campos são obrigatórios.';

  @override
  String get localFilesTitle => 'Ficheiros locais';

  @override
  String get serverFilesTitle => 'Ficheiros do servidor';

  @override
  String get restoreItemsTitle => 'Restaurar itens';

  @override
  String restoreItemsBody(int count) {
    return 'Tem a certeza de que pretende restaurar $count item(ns)?';
  }

  @override
  String get permanentlyDeleteTitle => 'Eliminar permanentemente';

  @override
  String permanentlyDeleteBody(int count) {
    return 'Tem a certeza de que pretende eliminar permanentemente $count item(ns)? Esta ação não pode ser anulada.';
  }

  @override
  String get trashIsEmpty => 'A reciclagem está vazia.';

  @override
  String trashRetentionInfo(int days) {
    return 'Os itens na reciclagem são eliminados automaticamente após $days dias.';
  }

  @override
  String get deletionDate => 'Data de eliminação';

  @override
  String get deletePermanentlyAction => 'Eliminar permanentemente';

  @override
  String get conflictFileAlreadyExists => 'O ficheiro já existe';

  @override
  String conflictNofM(int current, int total) {
    return 'Conflito $current de $total';
  }

  @override
  String get conflictAFileNamed => 'Um ficheiro chamado ';

  @override
  String get conflictAlreadyExistsAt => ' já existe em ';

  @override
  String get conflictAlreadyExistsInFolder => ' já existe nesta pasta.';

  @override
  String get conflictInFolder => 'Na pasta';

  @override
  String get conflictFromTrash => 'Da reciclagem';

  @override
  String get conflictExisting => 'Existente';

  @override
  String get conflictNewUpload => 'Novo carregamento';

  @override
  String conflictSizeLabel(String size) {
    return 'Tamanho: $size';
  }

  @override
  String conflictDateLabel(String date) {
    return 'Data: $date';
  }

  @override
  String conflictDeletedLabel(String date) {
    return 'Eliminado: $date';
  }

  @override
  String conflictApplyToRemaining(int count) {
    return 'Aplicar aos $count conflito(s) restantes';
  }

  @override
  String get conflictKeepAllCopies => 'Manter todas as cópias';

  @override
  String get conflictOverwriteAll => 'Substituir tudo';

  @override
  String get conflictRestoreAllAsCopies => 'Restaurar tudo como cópias';

  @override
  String get conflictRestoreAsCopy => 'Restaurar como cópia';

  @override
  String get conflictOverwriteAllRemaining => 'Substituir todos os restantes';

  @override
  String get conflictSkipAll => 'Ignorar tudo';

  @override
  String get conflictSkipAllRemaining => 'Ignorar todos os restantes';

  @override
  String get conflictSkip => 'Ignorar';

  @override
  String get conflictOverwrite => 'Substituir';

  @override
  String get transfersTitle => 'Transferências';

  @override
  String get transferResume => 'Retomar';

  @override
  String get transferPause => 'Pausar';

  @override
  String get transferCancel => 'Cancelar';

  @override
  String get transferResumeAll => 'Retomar tudo';

  @override
  String get transferPauseAll => 'Pausar tudo';

  @override
  String get transferCancelAll => 'Cancelar tudo';

  @override
  String get transferCancelFile => 'Cancelar ficheiro';

  @override
  String get noTransfers => 'Nenhuma transferência.';

  @override
  String get transferStatusQueued => 'Na fila';

  @override
  String get transferStatusRunning => 'Em execução';

  @override
  String get transferStatusPaused => 'Em pausa';

  @override
  String get transferStatusCompleted => 'Concluído';

  @override
  String get transferStatusFailed => 'Falhou';

  @override
  String get transferStatusCanceled => 'Cancelado';

  @override
  String get themePresetsSection => 'Predefinições';

  @override
  String get themeCustomPaletteSection => 'Paleta personalizada';

  @override
  String get themeHexRgbLabel => 'Código HEX RGB';

  @override
  String get themeHexRgbHint => '#FA5252';

  @override
  String get imageViewerNoFetchHandler =>
      'Nenhum processador de obtenção configurado';

  @override
  String get imageViewerFailedToLoad => 'Falha ao carregar a imagem';

  @override
  String errorDeletingFile(String filename, String error) {
    return 'Erro ao eliminar $filename: $error';
  }

  @override
  String errorReadingFile(String error) {
    return 'Erro ao ler o ficheiro: $error';
  }

  @override
  String get syncChannelName => 'Sincronização em segundo plano';

  @override
  String get syncChannelDescription =>
      'Mostra o estado dos ficheiros sincronizados em segundo plano.';

  @override
  String get storageStatsTitle => 'Estatísticas de armazenamento';

  @override
  String get storageStatsUsedSpace => 'Espaço utilizado';

  @override
  String get storageStatsTotalFiles => 'Total de ficheiros';

  @override
  String storageStatsNItems(int count) {
    return '$count itens';
  }

  @override
  String userFallback(int userId) {
    return 'Utilizador #$userId';
  }

  @override
  String get biometricUnlockReason =>
      'Desbloquear credenciais guardadas para o Crowley\'s Cloud.';

  @override
  String get tokenLifetimeEveryOpen => 'A cada abertura da aplicação';

  @override
  String get tokenLifetimeOneHour => 'Após 1 hora';

  @override
  String get tokenLifetime1Hour => 'Após 1 hora';

  @override
  String get tokenLifetimeOneDay => 'Após 1 dia';

  @override
  String get tokenLifetime1Day => 'Após 1 dia';

  @override
  String get tokenLifetimeOneWeek => 'Após 1 semana';

  @override
  String get tokenLifetime1Week => 'Após 1 semana';

  @override
  String get tokenLifetimeOneMonth => 'Após 1 mês';

  @override
  String get tokenLifetime1Month => 'Após 1 mês';

  @override
  String get tokenLifetimeThreeMonths => 'Após 3 meses';

  @override
  String get tokenLifetime3Months => 'Após 3 meses';

  @override
  String get tokenLifetimeNever => 'Nunca neste dispositivo';

  @override
  String get cacheLimitUnlimited => 'Ilimitado';

  @override
  String get syncCategoryOtherFiles => 'Outros ficheiros';

  @override
  String get internalStorage => 'Armazenamento interno';

  @override
  String get localStorageRootName => 'Armazenamento interno';

  @override
  String syncNotificationSyncingWith(String serverName) {
    return 'A sincronizar com $serverName';
  }

  @override
  String syncNotificationPausedTitle(String serverName) {
    return 'Sincronização com $serverName em pausa';
  }

  @override
  String get syncNotificationUnreachableBody =>
      'O servidor está inacessível. A sincronização em segundo plano está em pausa até a aplicação ser aberta.';

  @override
  String get syncNotificationAuthRequiredBody =>
      'Autenticação necessária. Abra a aplicação para iniciar sessão.';

  @override
  String syncNotificationFailedTitle(String serverName) {
    return 'Falha na sincronização com $serverName';
  }

  @override
  String get syncNotificationGenericErrorBody =>
      'Ocorreu um erro durante a sincronização.';

  @override
  String syncNotificationCompleteTitle(String serverName) {
    return 'Sincronização com $serverName concluída';
  }

  @override
  String get syncNotificationCompleteBody => 'Sincronização concluída.';

  @override
  String get syncStatusConnecting => 'A ligar ao servidor...';

  @override
  String syncStatusConnectionLost(String serverName) {
    return 'Não foi possível ligar a $serverName. Ligação perdida.';
  }

  @override
  String syncResultServerUnreachableWithServer(String serverName) {
    return 'Não foi possível ligar a $serverName. Ligação perdida.';
  }

  @override
  String get syncStatusScanningFiles =>
      'A verificar ficheiros no dispositivo...';

  @override
  String get syncStatusNoFilesFound =>
      'Nenhum ficheiro encontrado para sincronizar.';

  @override
  String get syncStatusNoFilesSelected =>
      'Nenhum ficheiro selecionado para sincronização.';

  @override
  String syncStatusCalculatingChecksum(
    int current,
    int total,
    String filename,
  ) {
    return 'A calcular o checksum ($current/$total): $filename';
  }

  @override
  String get syncStatusCheckingDuplicates =>
      'A verificar duplicados no servidor...';

  @override
  String syncStatusSyncingFile(int current, int total, String filename) {
    return 'A sincronizar ($current/$total): $filename';
  }

  @override
  String get syncStatusCompleting => 'A concluir a sincronização...';

  @override
  String get showingCachedFiles => 'A apresentar ficheiros em cache.';

  @override
  String get showingCachedFilesRefreshFailed =>
      'A apresentar ficheiros em cache. Falha ao atualizar.';

  @override
  String get downloadCanceled => 'Transferência cancelada.';

  @override
  String downloadedNFilesToPath(int count, String path) {
    return '$count ficheiro(s) transferido(s) para $path';
  }

  @override
  String downloadedNFilesFailedM(int downloaded, int failed, String detail) {
    return '$downloaded ficheiro(s) transferido(s), $failed falha(s): $detail';
  }

  @override
  String downloadedNFilesWithFailures(int count, int failed, String error) {
    return '$count ficheiro(s) transferido(s), $failed falha(s): $error';
  }

  @override
  String createdNShareLinks(int count) {
    return '$count ligação/ligações de partilha criada(s).';
  }

  @override
  String get failedToCreateShareLinks =>
      'Falha ao criar ligação/ligações de partilha.';

  @override
  String get alreadyInSharedScope => 'Já se encontra no espaço partilhado.';

  @override
  String sharedNItemsInServer(int count) {
    return '$count item(ns) partilhado(s) no servidor.';
  }

  @override
  String sharedNItemsWithFailures(int count, int failed) {
    return '$count item(ns) partilhado(s), $failed falha(s).';
  }

  @override
  String sharedNItemsFailedM(int shared, int failed) {
    return '$shared item(ns) partilhado(s), $failed falha(s).';
  }

  @override
  String get folderNameCannotBeEmpty => 'O nome da pasta não pode estar vazio.';

  @override
  String get folderAlreadyExists => 'A pasta já existe.';

  @override
  String get folderCreationOnlyInAllFiles =>
      'A criação de pastas apenas está disponível em Todos os ficheiros.';

  @override
  String get currentDirectoryUnavailable =>
      'O diretório atual não está disponível.';

  @override
  String get nothingSelected => 'Nada selecionado.';

  @override
  String get destinationFolderDoesNotExist => 'A pasta de destino não existe.';

  @override
  String cannotMoveFolderIntoItself(String name) {
    return 'Não é possível mover a pasta “$name” para dentro de si própria.';
  }

  @override
  String failedToMoveItem(String name, String error) {
    return 'Falha ao mover $name: $error';
  }

  @override
  String movedNItems(int count) {
    return '$count item(ns) movido(s).';
  }

  @override
  String movedNItemsWithFailures(int count, int failed) {
    return '$count item(ns) movido(s), $failed falha(s).';
  }

  @override
  String movedNItemsFailedM(int moved, int failed) {
    return '$moved item(ns) movido(s), $failed falha(s).';
  }

  @override
  String get failedToMoveSelectedItems =>
      'Falha ao mover os itens selecionados.';

  @override
  String get noFilesWereMoved => 'Nenhum ficheiro foi movido.';

  @override
  String renamedOldToNew(String oldName, String newName) {
    return '“$oldName” renomeado para “$newName”.';
  }

  @override
  String renamedFileFromTo(String oldName, String newName) {
    return '“$oldName” renomeado para “$newName”.';
  }

  @override
  String failedToRenameWithStatus(String name, int statusCode) {
    return 'Falha ao renomear “$name” ($statusCode).';
  }

  @override
  String failedToRenameFileWithCode(String name, int statusCode) {
    return 'Falha ao renomear “$name” ($statusCode).';
  }

  @override
  String failedToRenameWithError(String name, String error) {
    return 'Falha ao renomear “$name”: $error';
  }

  @override
  String failedToRenameFile(String name, String error) {
    return 'Falha ao renomear “$name”: $error';
  }

  @override
  String get renameConflictAlreadyExists =>
      'Falha ao renomear: já existe um ficheiro ou pasta com esse nome.';

  @override
  String get renameFailedAlreadyExists =>
      'Falha ao renomear: já existe um ficheiro ou pasta com esse nome.';

  @override
  String failedToCreateFolderWithCode(int statusCode) {
    return 'Falha ao criar pasta ($statusCode).';
  }

  @override
  String deletedNItemsFailedM(int deleted, int failed) {
    return '$deleted item(ns) eliminado(s), $failed falha(s).';
  }

  @override
  String transferSummaryFiles(int percent, int completed, int total) {
    return '$percent%  $completed/$total ficheiros';
  }

  @override
  String transferSummaryProgress(int percent, int completed, int total) {
    return '$percent%  $completed/$total ficheiros';
  }

  @override
  String get downloadFailedGeneric => 'Falha na transferência';

  @override
  String uploadedNItemsWithFailures(int uploaded, int failed) {
    return '$uploaded item(ns) carregado(s), $failed falha(s)';
  }

  @override
  String uploadedNItemsFailedM(int uploaded, int failed) {
    return '$uploaded item(ns) carregado(s), $failed falha(s).';
  }

  @override
  String uploadSummaryFailedCount(int count) {
    return ', $count falha(s)';
  }

  @override
  String uploadLocalPathEmpty(String name) {
    return '$name: o caminho local está vazio';
  }

  @override
  String uploadErrorLocalPathEmpty(String name) {
    return '$name: o caminho local está vazio';
  }

  @override
  String get directoryUploadFailed => 'Falha ao carregar diretório';

  @override
  String get uploadDirectoryFailed => 'Falha ao carregar diretório';

  @override
  String get localFileNotFound => 'Ficheiro local não encontrado';

  @override
  String get uploadErrorLocalFileNotFound => 'Ficheiro local não encontrado';

  @override
  String get noSessionToken => 'Nenhum token de sessão ativo';

  @override
  String get uploadErrorNoSessionToken => 'Nenhum token de sessão ativo';

  @override
  String get serverDisconnectedStatus => 'Servidor desligado';

  @override
  String get serverDisconnected => 'Servidor desligado';

  @override
  String get serverIsUnreachable => 'O servidor está inacessível.';

  @override
  String get serverUnreachable => 'O servidor está inacessível.';

  @override
  String get uploadErrorLocalDirectoryNotFound =>
      'Diretório local não encontrado';

  @override
  String get uploadErrorFailedToScanDirectory =>
      'Falha ao verificar o diretório';

  @override
  String uploadErrorFolderCreateHttp(int statusCode) {
    return 'Falha ao criar pasta (HTTP $statusCode)';
  }

  @override
  String get authErrorMissingAccessToken =>
      'Token de acesso ausente na resposta';

  @override
  String get authErrorMissingRefreshToken =>
      'Token de atualização ausente na resposta';

  @override
  String get authErrorNoSavedCredentials =>
      'Nenhuma credencial guardada disponível';

  @override
  String get authErrorNoRefreshToken =>
      'Nenhum token de atualização disponível';

  @override
  String get authErrorNoActiveSession => 'Nenhuma sessão ativa disponível';

  @override
  String get authErrorNoSavedUsername =>
      'Nenhum nome de utilizador guardado disponível';

  @override
  String get updateNoReleasesPublished => 'Nenhuma versão publicada ainda.';

  @override
  String get language => 'Idioma';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get appTitle => 'Crowley\'s Cloud';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Salvar';

  @override
  String get delete => 'Excluir';

  @override
  String get rename => 'Renomear';

  @override
  String get close => 'Fechar';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get loading => 'Carregando...';

  @override
  String get confirm => 'Confirmar';

  @override
  String get error => 'Erro';

  @override
  String errorWithMessage(String message) {
    return 'Erro: $message';
  }

  @override
  String get unknown => 'Desconhecido';

  @override
  String get upload => 'Enviar';

  @override
  String get download => 'Baixar';

  @override
  String get share => 'Compartilhar';

  @override
  String get copy => 'Copiar';

  @override
  String get move => 'Mover';

  @override
  String get restore => 'Restaurar';

  @override
  String get apply => 'Aplicar';

  @override
  String get create => 'Criar';

  @override
  String get clear => 'Limpar';

  @override
  String get add => 'Adicionar';

  @override
  String get remove => 'Remover';

  @override
  String get edit => 'Editar';

  @override
  String get switchLabel => 'Alternar';

  @override
  String get search => 'Pesquisar';

  @override
  String get name => 'Nome';

  @override
  String get date => 'Data';

  @override
  String get size => 'Tamanho';

  @override
  String get type => 'Tipo';

  @override
  String get ascending => 'Crescente';

  @override
  String get descending => 'Decrescente';

  @override
  String get allFiles => 'Todos';

  @override
  String get categoryImages => 'Imagens';

  @override
  String get categoryPhotos => 'Fotos';

  @override
  String get categoryVideos => 'Vídeos';

  @override
  String get categoryAudio => 'Áudio';

  @override
  String get categoryDocuments => 'Documentos';

  @override
  String get categoryArchives => 'Arquivos compactados';

  @override
  String get categoryShared => 'Compartilhados';

  @override
  String get categoryOther => 'Outros';

  @override
  String get categoryOtherFiles => 'Outros arquivos';

  @override
  String get noFilesFound => 'Nenhum arquivo encontrado.';

  @override
  String get noFilesInFolder => 'Não há arquivos nesta pasta.';

  @override
  String get thisActionCannotBeUndone => 'Esta ação não pode ser desfeita.';

  @override
  String get passwordsDoNotMatch => 'As senhas não coincidem.';

  @override
  String get navLocalFiles => 'Arquivos locais';

  @override
  String get navServerFiles => 'Arquivos do servidor';

  @override
  String get navSettings => 'Configurações';

  @override
  String get navTrash => 'Lixeira';

  @override
  String get navLocal => 'Local';

  @override
  String get navServer => 'Servidor';

  @override
  String get addServer => 'Adicionar servidor';

  @override
  String get noServersConfigured => 'Nenhum servidor configurado.';

  @override
  String get addAServerInSettings => 'Adicione um servidor nas configurações.';

  @override
  String get addFirstServerHint =>
      'Adicione seu primeiro servidor para continuar.';

  @override
  String get noServersConfiguredYet => 'Ainda não há servidores configurados.';

  @override
  String get crowleysCloudSetup => 'Configuração do Crowley\'s Cloud';

  @override
  String get connect => 'Conectar';

  @override
  String get connecting => 'Conectando...';

  @override
  String get connected => 'Conectado';

  @override
  String get disconnected => 'Desconectado';

  @override
  String get switchServer => 'Trocar de servidor';

  @override
  String get chooseOtherServer => 'Escolher outro servidor';

  @override
  String get switchServerTitle => 'Trocar de servidor?';

  @override
  String switchServerBody(String serverName) {
    return 'Trocar o servidor ativo para “$serverName”?';
  }

  @override
  String get chooseServer => 'Escolher servidor';

  @override
  String get authenticationRequired => 'Autenticação necessária';

  @override
  String signInToAccess(String serverName) {
    return 'Entre para acessar os arquivos em $serverName';
  }

  @override
  String get signInWithPassword => 'Entrar com senha';

  @override
  String get useBiometrics => 'Usar biometria';

  @override
  String get openingSignIn => 'Abrindo a tela de acesso...';

  @override
  String get serverConnectionFailed => 'Falha na conexão com o servidor';

  @override
  String get unableToConnectToServer =>
      'Não foi possível conectar ao servidor ativo.';

  @override
  String unableToConnectTo(String serverName) {
    return 'Não foi possível conectar a $serverName.';
  }

  @override
  String get searchHint => 'Pesquisar...';

  @override
  String get searchFilesHint => 'Pesquisar arquivos...';

  @override
  String get searchServerFilesHint => 'Pesquisar arquivos do servidor...';

  @override
  String get searchTrashHint => 'Pesquisar na lixeira...';

  @override
  String get storagePermissionRequired =>
      'Permissão de armazenamento necessária';

  @override
  String get grantPermission => 'Conceder permissão';

  @override
  String get permissionDeniedOpenSettings =>
      'Permissão negada. Conceda acesso ao armazenamento nas configurações.';

  @override
  String get manageStoragePermissionRequired =>
      'A permissão para gerenciar armazenamento é necessária para navegar e selecionar pastas.';

  @override
  String get storagePermissionsRequired =>
      'São necessárias permissões de armazenamento para realizar a sincronização.';

  @override
  String updateAvailableTitle(String version) {
    return 'Atualização disponível: v$version';
  }

  @override
  String get updateAvailableTapToSeeNew => 'Toque para ver as novidades';

  @override
  String get updateView => 'Ver';

  @override
  String get updateAvailableDialogTitle => 'Atualização disponível';

  @override
  String updateVersionSubtitle(String version) {
    return 'Versão $version';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'Atual: v$version';
  }

  @override
  String updateNewVersion(String version) {
    return 'Nova: v$version';
  }

  @override
  String get updateWhatsNew => 'Novidades:';

  @override
  String get updateGitHub => 'GitHub';

  @override
  String get updateNoReleaseNotes => 'Nenhuma nota de versão fornecida.';

  @override
  String get updateLater => 'Mais tarde';

  @override
  String get updateDownloadApk => 'Baixar APK';

  @override
  String get updateInstall => 'Atualizar';

  @override
  String get shareLinkTitle => 'Link de compartilhamento';

  @override
  String get shareViaLink => 'Compartilhar por link';

  @override
  String get shareInServer => 'Compartilhar no servidor';

  @override
  String get expiryDays => 'Expiração (dias)';

  @override
  String get expiryNever => 'Nunca';

  @override
  String get expiry1Day => '1 dia';

  @override
  String get expiry7Days => '7 dias';

  @override
  String get expiry30Days => '30 dias';

  @override
  String get expiry90Days => '90 dias';

  @override
  String get expiry180Days => '180 dias';

  @override
  String get expiry365Days => '365 dias';

  @override
  String get createLink => 'Criar link';

  @override
  String get sharedLinkCopied =>
      'Link de compartilhamento copiado para a área de transferência!';

  @override
  String failedToCopySharedLink(String error) {
    return 'Não foi possível copiar o link de compartilhamento: $error';
  }

  @override
  String get cannotShareThisFileType =>
      'Não é possível compartilhar este tipo de arquivo.';

  @override
  String failedToCreateShare(String error) {
    return 'Não foi possível criar o compartilhamento: $error';
  }

  @override
  String get newFolderTitle => 'Criar pasta';

  @override
  String get newFolderHint => 'Nome da pasta';

  @override
  String get newFolder => 'Nova pasta';

  @override
  String get folderCreated => 'Pasta criada.';

  @override
  String failedToCreateFolder(String error) {
    return 'Não foi possível criar a pasta: $error';
  }

  @override
  String get creatingFolder => 'Criando pasta...';

  @override
  String get renameDialogTitle => 'Renomear';

  @override
  String get renameHint => 'Novo nome';

  @override
  String get enterNewName => 'Digite o novo nome';

  @override
  String get renamedSuccessfully => 'Renomeado com sucesso.';

  @override
  String renameFailed(String error) {
    return 'Falha ao renomear: $error';
  }

  @override
  String get moveDialogTitle => 'Mover para';

  @override
  String moveTo(String path) {
    return 'Mover para: $path';
  }

  @override
  String get moveHere => 'Mover para cá';

  @override
  String moveFailed(String error) {
    return 'Falha ao mover: $error';
  }

  @override
  String get movedToFolder => 'Movido para a pasta.';

  @override
  String copyFailed(String error) {
    return 'Falha ao copiar: $error';
  }

  @override
  String get selectFolder => 'Selecionar pasta';

  @override
  String get useThisFolder => 'Usar esta pasta';

  @override
  String get storageRoot => 'Armazenamento';

  @override
  String get serverRoot => 'raiz';

  @override
  String deleteNItemsTitle(int count) {
    return 'Excluir $count itens?';
  }

  @override
  String get deleteFilesTitle => 'Excluir arquivos?';

  @override
  String deleteFilesBody(int count) {
    return 'Tem certeza de que deseja excluir os $count itens selecionados? Esta ação não pode ser desfeita.';
  }

  @override
  String get deletePermanently => 'Excluir permanentemente';

  @override
  String get deletePermanentlyTitle => 'Excluir permanentemente?';

  @override
  String deletePermanentlyBody(String filename) {
    return '$filename será excluído permanentemente.';
  }

  @override
  String get deleteFileTitle => 'Excluir arquivo?';

  @override
  String deleteFileBody(String filename) {
    return 'Tem certeza de que deseja excluir $filename? Esta ação não pode ser desfeita.';
  }

  @override
  String get deleteServerFileTitle => 'Excluir permanentemente';

  @override
  String deleteServerFileBody(String filename) {
    return 'Tem certeza de que deseja excluir permanentemente “$filename”? Esta ação não pode ser desfeita.';
  }

  @override
  String get unshareItemsTitle => 'Parar de compartilhar itens?';

  @override
  String unshareItemsBody(int count) {
    return 'Tem certeza de que deseja parar de compartilhar os $count itens selecionados? Eles serão removidos da pasta Compartilhados.';
  }

  @override
  String get unshare => 'Parar de compartilhar';

  @override
  String get moveToTrash => 'Mover para a lixeira';

  @override
  String get movedToTrash => 'Movido para a lixeira.';

  @override
  String movedNItemsToTrash(int count) {
    return '$count itens movidos para a lixeira.';
  }

  @override
  String failedToMoveToTrash(String error) {
    return 'Falha ao mover para a lixeira: $error';
  }

  @override
  String deletedNItems(int count) {
    return '$count itens excluídos.';
  }

  @override
  String failedToDelete(String error) {
    return 'Falha ao excluir: $error';
  }

  @override
  String failedToDeleteItem(String error) {
    return 'Falha ao excluir: $error';
  }

  @override
  String deletedFilename(String filename) {
    return '$filename excluído.';
  }

  @override
  String get failedToOpenFile => 'Não foi possível abrir o arquivo';

  @override
  String fileDownloadFailed(String error) {
    return 'Falha ao baixar o arquivo: $error';
  }

  @override
  String get downloading => 'Baixando...';

  @override
  String get downloadingFile => 'Baixando arquivo...';

  @override
  String downloadComplete(String filename) {
    return 'Download concluído: $filename';
  }

  @override
  String downloadFailed(String error) {
    return 'Falha no download: $error';
  }

  @override
  String get failedToDownloadPreview =>
      'Não foi possível baixar a prévia do arquivo';

  @override
  String uploadComplete(String filename) {
    return 'Upload concluído: $filename';
  }

  @override
  String uploadFailed(String error) {
    return 'Falha no upload: $error';
  }

  @override
  String get failedToPickFiles => 'Não foi possível selecionar os arquivos';

  @override
  String uploadedNItems(int count) {
    return '$count item(ns) enviado(s)';
  }

  @override
  String get copiedLinkToClipboard =>
      'Link copiado para a área de transferência.';

  @override
  String failedToCopyLink(String error) {
    return 'Não foi possível copiar o link: $error';
  }

  @override
  String get selectingAll => 'Selecionando tudo...';

  @override
  String get allItemsSelected => 'Todos os itens selecionados.';

  @override
  String get failedToLoadSearchResults =>
      'Não foi possível carregar os resultados da pesquisa';

  @override
  String get shareNotSupportedForType =>
      'O compartilhamento não é compatível com este tipo de arquivo.';

  @override
  String nSelected(int count) {
    return '$count selecionados';
  }

  @override
  String get noServerSelected => 'Nenhum servidor selecionado';

  @override
  String get pleaseConnectToServerFirst => 'Conecte-se primeiro a um servidor.';

  @override
  String get signInRequired => 'É necessário entrar';

  @override
  String pleaseSignInToServer(String serverName) {
    return 'Entre primeiro em $serverName.';
  }

  @override
  String get connectingToServer => 'Conectando ao servidor...';

  @override
  String connectedToServer(String serverName) {
    return 'Conectado a $serverName.';
  }

  @override
  String connectionFailed(String error) {
    return 'Falha na conexão: $error';
  }

  @override
  String failedToConnect(String error) {
    return 'Não foi possível conectar: $error';
  }

  @override
  String authFailed(String error) {
    return 'Falha na autenticação: $error';
  }

  @override
  String get authFailedGeneric => 'Falha na autenticação. Tente novamente.';

  @override
  String biometricLoginFailed(String error) {
    return 'Falha no acesso biométrico: $error';
  }

  @override
  String get biometricLoginFailedGeneric => 'Falha no acesso biométrico.';

  @override
  String get noServerSessionToken =>
      'Nenhum token de sessão do servidor. Autentique o servidor novamente.';

  @override
  String failedToSaveServer(String error) {
    return 'Não foi possível salvar o servidor: $error';
  }

  @override
  String get addToFolder => 'Adicionar à pasta';

  @override
  String get loginTabLabel => 'Entrar';

  @override
  String get registerTabLabel => 'Cadastrar';

  @override
  String get welcomeBack => 'Bem-vindo de volta';

  @override
  String get signInToContinue => 'Entre para continuar';

  @override
  String get createAccount => 'Criar conta';

  @override
  String get joinTheServer => 'Participar do servidor';

  @override
  String get usernameLabel => 'Nome de usuário';

  @override
  String get usernameHint => 'Digite seu nome de usuário';

  @override
  String get passwordLabel => 'Senha';

  @override
  String get passwordHint => 'Digite sua senha';

  @override
  String get showPassword => 'Mostrar senha';

  @override
  String get hidePassword => 'Ocultar senha';

  @override
  String get confirmPassword => 'Confirmar senha';

  @override
  String get logIn => 'Entrar';

  @override
  String get loggingIn => 'Entrando...';

  @override
  String get registering => 'Cadastrando...';

  @override
  String get forgotPassword => 'Esqueceu a senha?';

  @override
  String get doNotHaveAccount => 'Não tem uma conta? Mude para Cadastro.';

  @override
  String get alreadyHaveAccount => 'Já tem uma conta? Mude para Entrar.';

  @override
  String get usernameCannotBeEmpty => 'O nome de usuário não pode ficar vazio.';

  @override
  String get passwordCannotBeEmpty => 'A senha não pode ficar vazia.';

  @override
  String get usernameInvalid =>
      'O nome de usuário deve ter 3–32 caracteres: letras, números, _ ou -.';

  @override
  String get passwordTooShort => 'A senha deve ter pelo menos 8 caracteres.';

  @override
  String loginFailed(String error) {
    return 'Falha ao entrar: $error';
  }

  @override
  String registrationFailed(String error) {
    return 'Falha no cadastro: $error';
  }

  @override
  String get resetPasswordTitle => 'Redefinir senha';

  @override
  String get enterResetCodeTitle => 'Digite o código de redefinição';

  @override
  String get resetPasswordStep1Body =>
      'Digite seu nome de usuário. O código de verificação de 6 dígitos será impresso nos logs/console do servidor.';

  @override
  String get resetPasswordStep2Body =>
      'O código de verificação foi impresso no console do servidor. Digite o código de 6 dígitos e sua nova senha.';

  @override
  String get resetCodeLabel => 'Código de redefinição';

  @override
  String get resetCodeHint => 'Digite o código de 6 dígitos';

  @override
  String get newPasswordLabel => 'Nova senha';

  @override
  String get newPasswordHint => 'Digite a nova senha';

  @override
  String get passwordResetSuccessfully => 'Senha redefinida com sucesso!';

  @override
  String get usernameIsRequired => 'O nome de usuário é obrigatório.';

  @override
  String get codeAndPasswordRequired =>
      'O código e a nova senha são obrigatórios.';

  @override
  String get failedToRequestReset =>
      'Não foi possível solicitar a redefinição. Verifique a URL do servidor.';

  @override
  String get failedToResetPassword =>
      'Não foi possível redefinir a senha. Verifique o código.';

  @override
  String get pleaseEnterServerUrlFirst => 'Digite primeiro a URL do servidor.';

  @override
  String get sendCode => 'Enviar código';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get sectionBackupSync => 'Backup e sincronização';

  @override
  String get sectionStorageCache => 'Armazenamento e cache';

  @override
  String get sectionSecurityBehavior => 'Segurança e comportamento';

  @override
  String get sectionAboutUpdates => 'Sobre e atualizações';

  @override
  String get sectionAppearance => 'Aparência e personalização';

  @override
  String get noServersConfiguredSync => 'Nenhum servidor configurado';

  @override
  String get addServerBeforeSync =>
      'Adicione um servidor antes de configurar a sincronização.';

  @override
  String get selectServerToConfigureSync =>
      'Selecione um servidor para configurar suas opções de sincronização.';

  @override
  String get activeServerSuffix => '· ativo';

  @override
  String get folderAndCategorySync => 'Sincronização de pastas e categorias';

  @override
  String get keepCategoriesSynced =>
      'Mantenha as categorias ou pastas locais selecionadas sincronizadas com este servidor.';

  @override
  String get addServerBeforeSyncEnable =>
      'Adicione um servidor antes de ativar a sincronização.';

  @override
  String get onlyOnWifi => 'Somente no Wi-Fi';

  @override
  String get onlyWhileCharging => 'Somente durante o carregamento';

  @override
  String get serverTargetDirectory => 'Diretório de destino do servidor';

  @override
  String get serverTargetDirectoryHint => '/backup/mobile_phone';

  @override
  String get synchronizationFrequency => 'Frequência de sincronização';

  @override
  String get syncNow => 'Sincronizar agora';

  @override
  String get syncing => 'Sincronizando...';

  @override
  String get categoriesToSynchronize => 'Categorias para sincronizar';

  @override
  String get noCategoriesSelected => 'Nenhuma categoria selecionada.';

  @override
  String nCategoriesSelected(int count) {
    return '$count selecionados';
  }

  @override
  String get foldersToSynchronize => 'Pastas para sincronizar';

  @override
  String get noCustomFolders => 'Nenhuma pasta personalizada configurada.';

  @override
  String nFolders(int count) {
    return '$count pasta(s)';
  }

  @override
  String get addFolder => 'Adicionar pasta';

  @override
  String get removeFolder => 'Remover pasta';

  @override
  String get removeServer => 'Remover servidor';

  @override
  String get syncFreqEvery15Min => 'A cada 15 minutos';

  @override
  String get syncFreqEvery30Min => 'A cada 30 minutos';

  @override
  String get syncFreqEvery1Hour => 'A cada hora';

  @override
  String syncFreqEveryNHours(int hours) {
    return 'A cada $hours horas';
  }

  @override
  String syncFreqEveryNMin(int minutes) {
    return 'A cada $minutes minutos';
  }

  @override
  String get syncFreqDaily => 'Diariamente';

  @override
  String get chooseSyncFrequencyTitle => 'Escolher frequência de sincronização';

  @override
  String get cacheSize => 'Tamanho do cache';

  @override
  String get refreshTooltip => 'Atualizar';

  @override
  String get cacheLimit => 'Limite do cache';

  @override
  String get downloadPath => 'Caminho de download';

  @override
  String get defaultDownloadFolder => 'Pasta padrão do CrowleysCloud';

  @override
  String get clearCache => 'Limpar cache';

  @override
  String get clearCacheTitle => 'Limpar cache?';

  @override
  String get clearCacheBody =>
      'Isso remove miniaturas locais e listagens de servidores armazenadas em cache.';

  @override
  String get downloadPathDialogTitle => 'Caminho de download';

  @override
  String get downloadPathHint => '/storage/emulated/0/CrowleysCloud';

  @override
  String get useDefault => 'Usar padrão';

  @override
  String get serverTargetDirDialogTitle => 'Diretório de destino do servidor';

  @override
  String get requireLogin => 'Exigir login';

  @override
  String get biometricLogin => 'Login biométrico';

  @override
  String get biometricLoginSubtitle =>
      'Permitir login com credenciais salvas usando biometria.';

  @override
  String get biometricsNotAvailable =>
      'A biometria não está disponível neste dispositivo.';

  @override
  String get showHiddenFiles => 'Mostrar arquivos ocultos';

  @override
  String get showHiddenFilesSubtitle =>
      'Exibir arquivos e pastas iniciados por ponto.';

  @override
  String get changePassword => 'Alterar senha';

  @override
  String changePasswordSubtitle(String serverName) {
    return 'Atualizar a senha de $serverName.';
  }

  @override
  String get addServerBeforeChangePassword =>
      'Adicione um servidor antes de alterar a senha.';

  @override
  String get deleteUserAccount => 'Excluir conta de usuário';

  @override
  String get deleteUserAccountSubtitle =>
      'Exclui o usuário e todos os arquivos da nuvem privada.';

  @override
  String get deleteAccountTitle => 'Excluir conta?';

  @override
  String deleteAccountBody(String serverName) {
    return 'Isso exclui permanentemente sua conta em $serverName e remove todos os arquivos armazenados na sua pasta de nuvem privada. Não é possível desfazer.';
  }

  @override
  String get deleteAccountButton => 'Excluir conta';

  @override
  String get changePasswordDialogTitle => 'Alterar senha';

  @override
  String get newPasswordFieldLabel => 'Nova senha';

  @override
  String get confirmPasswordLabel => 'Confirmar senha';

  @override
  String get enterNewPassword => 'Digite uma nova senha.';

  @override
  String get passwordUpdated => 'Senha atualizada.';

  @override
  String passwordChangeFailed(String error) {
    return 'Falha ao alterar a senha: $error';
  }

  @override
  String get passwordChangeFailedGeneric => 'Falha ao alterar a senha.';

  @override
  String get accountDeleted => 'Conta excluída.';

  @override
  String accountDeletionFailed(String error) {
    return 'Falha ao excluir a conta: $error';
  }

  @override
  String get accountDeletionFailedGeneric => 'Falha ao excluir a conta.';

  @override
  String get checkForUpdates => 'Verificar atualizações';

  @override
  String get checkingForUpdates => 'Verificando versões do GitHub...';

  @override
  String versionLabel(String version) {
    return 'Versão $version';
  }

  @override
  String appIsUpToDate(String version) {
    return 'O Crowley\'s Cloud está atualizado (v$version).';
  }

  @override
  String get updateCheckFailed =>
      'Não foi possível verificar atualizações. Tente novamente mais tarde.';

  @override
  String get themeModeTitle => 'Modo do tema';

  @override
  String get themeDark => 'Escuro';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeCustom => 'Personalizado';

  @override
  String get themeDarkFull => 'Tema escuro';

  @override
  String get themeLightFull => 'Tema claro';

  @override
  String get themeCustomFull => 'Tema personalizado';

  @override
  String get accentColor => 'Cor de destaque';

  @override
  String get primaryAccentColor => 'Cor de destaque principal';

  @override
  String get selectAccentColor => 'Selecionar cor de destaque';

  @override
  String get backgroundColor => 'Cor de fundo';

  @override
  String get surfaceColor => 'Cor da superfície';

  @override
  String get textColor => 'Cor do texto';

  @override
  String get subtextColor => 'Cor do texto secundário';

  @override
  String get borderColor => 'Cor da borda';

  @override
  String get fontSizeScale => 'Escala do tamanho da fonte';

  @override
  String selectColor(String title) {
    return 'Selecionar $title';
  }

  @override
  String get categoriesToSyncDialogTitle => 'Categorias para sincronizar';

  @override
  String get categoriesToSyncBody =>
      'Escolha uma ou mais categorias. Deixar tudo desmarcado também é válido.';

  @override
  String get syncCategorySectionMedia => 'Mídia';

  @override
  String get syncCategorySectionAudioDocs => 'Áudio e documentos';

  @override
  String get syncCategorySectionOther => 'Outros';

  @override
  String get clearAll => 'Limpar tudo';

  @override
  String get noSyncHasRunYet => 'Nenhuma sincronização foi executada ainda.';

  @override
  String lastRunAt(String date) {
    return 'Última execução: $date';
  }

  @override
  String syncResultSuccess(int uploaded, int skipped) {
    return '$uploaded sincronizados, $skipped ignorados.';
  }

  @override
  String get syncResultNoFiles =>
      'Nenhum arquivo selecionado para sincronização.';

  @override
  String syncResultPartial(int uploaded, int failed) {
    return '$uploaded sincronizados, $failed falharam.';
  }

  @override
  String get syncResultAuthRequired => 'Entre antes de sincronizar.';

  @override
  String get syncResultUnreachable => 'Servidor inacessível. Conexão perdida.';

  @override
  String get syncResultFailed => 'Falha na sincronização.';

  @override
  String get serverSetupAddServer => 'Adicionar servidor';

  @override
  String get serverSetupCardTitle => 'Conectar servidor';

  @override
  String get serverSetupCardSubtitle =>
      'Adicione seu servidor de arquivos doméstico e entre.';

  @override
  String get serverSetupSubmitButton => 'Salvar servidor';

  @override
  String get serverNameLabel => 'Nome do servidor';

  @override
  String get serverNameHint => 'NAS doméstico';

  @override
  String get baseUrlLabel => 'Base URL';

  @override
  String get baseUrlHint => 'https://cloud.example.com';

  @override
  String get allFieldsRequired => 'Todos os campos são obrigatórios.';

  @override
  String get localFilesTitle => 'Arquivos locais';

  @override
  String get serverFilesTitle => 'Arquivos do servidor';

  @override
  String get restoreItemsTitle => 'Restaurar itens';

  @override
  String restoreItemsBody(int count) {
    return 'Tem certeza de que deseja restaurar $count item(ns)?';
  }

  @override
  String get permanentlyDeleteTitle => 'Excluir permanentemente';

  @override
  String permanentlyDeleteBody(int count) {
    return 'Tem certeza de que deseja excluir permanentemente $count item(ns)? Esta ação não pode ser desfeita.';
  }

  @override
  String get trashIsEmpty => 'A lixeira está vazia.';

  @override
  String trashRetentionInfo(int days) {
    return 'Os itens na lixeira são excluídos automaticamente após $days dias.';
  }

  @override
  String get deletionDate => 'Data de exclusão';

  @override
  String get deletePermanentlyAction => 'Excluir permanentemente';

  @override
  String get conflictFileAlreadyExists => 'O arquivo já existe';

  @override
  String conflictNofM(int current, int total) {
    return 'Conflito $current de $total';
  }

  @override
  String get conflictAFileNamed => 'Um arquivo chamado ';

  @override
  String get conflictAlreadyExistsAt => ' já existe em ';

  @override
  String get conflictAlreadyExistsInFolder => ' já existe nesta pasta.';

  @override
  String get conflictInFolder => 'Na pasta';

  @override
  String get conflictFromTrash => 'Da lixeira';

  @override
  String get conflictExisting => 'Existente';

  @override
  String get conflictNewUpload => 'Novo upload';

  @override
  String conflictSizeLabel(String size) {
    return 'Tamanho: $size';
  }

  @override
  String conflictDateLabel(String date) {
    return 'Data: $date';
  }

  @override
  String conflictDeletedLabel(String date) {
    return 'Excluído: $date';
  }

  @override
  String conflictApplyToRemaining(int count) {
    return 'Aplicar aos $count conflito(s) restantes';
  }

  @override
  String get conflictKeepAllCopies => 'Manter todas as cópias';

  @override
  String get conflictOverwriteAll => 'Sobrescrever tudo';

  @override
  String get conflictRestoreAllAsCopies => 'Restaurar tudo como cópias';

  @override
  String get conflictRestoreAsCopy => 'Restaurar como cópia';

  @override
  String get conflictOverwriteAllRemaining => 'Substituir todos os restantes';

  @override
  String get conflictSkipAll => 'Pular tudo';

  @override
  String get conflictSkipAllRemaining => 'Ignorar todos os restantes';

  @override
  String get conflictSkip => 'Pular';

  @override
  String get conflictOverwrite => 'Sobrescrever';

  @override
  String get transfersTitle => 'Transferências';

  @override
  String get transferResume => 'Retomar';

  @override
  String get transferPause => 'Pausar';

  @override
  String get transferCancel => 'Cancelar';

  @override
  String get transferResumeAll => 'Retomar tudo';

  @override
  String get transferPauseAll => 'Pausar tudo';

  @override
  String get transferCancelAll => 'Cancelar tudo';

  @override
  String get transferCancelFile => 'Cancelar arquivo';

  @override
  String get noTransfers => 'Nenhuma transferência.';

  @override
  String get transferStatusQueued => 'Na fila';

  @override
  String get transferStatusRunning => 'Em execução';

  @override
  String get transferStatusPaused => 'Pausado';

  @override
  String get transferStatusCompleted => 'Concluído';

  @override
  String get transferStatusFailed => 'Falhou';

  @override
  String get transferStatusCanceled => 'Cancelado';

  @override
  String get themePresetsSection => 'Predefinições';

  @override
  String get themeCustomPaletteSection => 'Paleta personalizada';

  @override
  String get themeHexRgbLabel => 'Código HEX RGB';

  @override
  String get themeHexRgbHint => '#FA5252';

  @override
  String get imageViewerNoFetchHandler =>
      'Nenhum manipulador de busca configurado';

  @override
  String get imageViewerFailedToLoad => 'Falha ao carregar a imagem';

  @override
  String errorDeletingFile(String filename, String error) {
    return 'Erro ao excluir $filename: $error';
  }

  @override
  String errorReadingFile(String error) {
    return 'Erro ao ler o arquivo: $error';
  }

  @override
  String get syncChannelName => 'Sincronização em segundo plano';

  @override
  String get syncChannelDescription =>
      'Mostra o status dos arquivos sincronizados em segundo plano.';

  @override
  String get storageStatsTitle => 'Estatísticas de armazenamento';

  @override
  String get storageStatsUsedSpace => 'Espaço usado';

  @override
  String get storageStatsTotalFiles => 'Total de arquivos';

  @override
  String storageStatsNItems(int count) {
    return '$count itens';
  }

  @override
  String userFallback(int userId) {
    return 'Usuário #$userId';
  }

  @override
  String get biometricUnlockReason =>
      'Desbloquear credenciais salvas para o Crowley\'s Cloud.';

  @override
  String get tokenLifetimeEveryOpen => 'A cada abertura do aplicativo';

  @override
  String get tokenLifetimeOneHour => 'Após 1 hora';

  @override
  String get tokenLifetime1Hour => 'Após 1 hora';

  @override
  String get tokenLifetimeOneDay => 'Após 1 dia';

  @override
  String get tokenLifetime1Day => 'Após 1 dia';

  @override
  String get tokenLifetimeOneWeek => 'Após 1 semana';

  @override
  String get tokenLifetime1Week => 'Após 1 semana';

  @override
  String get tokenLifetimeOneMonth => 'Após 1 mês';

  @override
  String get tokenLifetime1Month => 'Após 1 mês';

  @override
  String get tokenLifetimeThreeMonths => 'Após 3 meses';

  @override
  String get tokenLifetime3Months => 'Após 3 meses';

  @override
  String get tokenLifetimeNever => 'Nunca neste dispositivo';

  @override
  String get cacheLimitUnlimited => 'Ilimitado';

  @override
  String get syncCategoryOtherFiles => 'Outros arquivos';

  @override
  String get internalStorage => 'Armazenamento interno';

  @override
  String get localStorageRootName => 'Armazenamento interno';

  @override
  String syncNotificationSyncingWith(String serverName) {
    return 'Sincronizando com $serverName';
  }

  @override
  String syncNotificationPausedTitle(String serverName) {
    return 'Sincronização com $serverName pausada';
  }

  @override
  String get syncNotificationUnreachableBody =>
      'O servidor está inacessível. A sincronização em segundo plano está pausada até o aplicativo ser aberto.';

  @override
  String get syncNotificationAuthRequiredBody =>
      'Autenticação necessária. Abra o aplicativo para entrar.';

  @override
  String syncNotificationFailedTitle(String serverName) {
    return 'Falha na sincronização com $serverName';
  }

  @override
  String get syncNotificationGenericErrorBody =>
      'Ocorreu um erro durante a sincronização.';

  @override
  String syncNotificationCompleteTitle(String serverName) {
    return 'Sincronização com $serverName concluída';
  }

  @override
  String get syncNotificationCompleteBody => 'Sincronização concluída.';

  @override
  String get syncStatusConnecting => 'Conectando ao servidor...';

  @override
  String syncStatusConnectionLost(String serverName) {
    return 'Não foi possível conectar a $serverName. Conexão perdida.';
  }

  @override
  String syncResultServerUnreachableWithServer(String serverName) {
    return 'Não foi possível conectar a $serverName. Conexão perdida.';
  }

  @override
  String get syncStatusScanningFiles =>
      'Verificando arquivos no dispositivo...';

  @override
  String get syncStatusNoFilesFound =>
      'Nenhum arquivo encontrado para sincronizar.';

  @override
  String get syncStatusNoFilesSelected =>
      'Nenhum arquivo selecionado para sincronização.';

  @override
  String syncStatusCalculatingChecksum(
    int current,
    int total,
    String filename,
  ) {
    return 'Calculando checksum ($current/$total): $filename';
  }

  @override
  String get syncStatusCheckingDuplicates =>
      'Verificando duplicatas no servidor...';

  @override
  String syncStatusSyncingFile(int current, int total, String filename) {
    return 'Sincronizando ($current/$total): $filename';
  }

  @override
  String get syncStatusCompleting => 'Concluindo a sincronização...';

  @override
  String get showingCachedFiles => 'Exibindo arquivos em cache.';

  @override
  String get showingCachedFilesRefreshFailed =>
      'Exibindo arquivos em cache. Falha ao atualizar.';

  @override
  String get downloadCanceled => 'Download cancelado.';

  @override
  String downloadedNFilesToPath(int count, String path) {
    return '$count arquivo(s) baixado(s) para $path';
  }

  @override
  String downloadedNFilesFailedM(int downloaded, int failed, String detail) {
    return '$downloaded arquivo(s) baixado(s), $failed falha(s): $detail';
  }

  @override
  String downloadedNFilesWithFailures(int count, int failed, String error) {
    return '$count arquivo(s) baixado(s), $failed falha(s): $error';
  }

  @override
  String createdNShareLinks(int count) {
    return '$count link(s) de compartilhamento criado(s).';
  }

  @override
  String get failedToCreateShareLinks =>
      'Falha ao criar link(s) de compartilhamento.';

  @override
  String get alreadyInSharedScope => 'Já está no espaço compartilhado.';

  @override
  String sharedNItemsInServer(int count) {
    return '$count item(ns) compartilhado(s) no servidor.';
  }

  @override
  String sharedNItemsWithFailures(int count, int failed) {
    return '$count item(ns) compartilhado(s), $failed falha(s).';
  }

  @override
  String sharedNItemsFailedM(int shared, int failed) {
    return '$shared item(ns) compartilhado(s), $failed falha(s).';
  }

  @override
  String get folderNameCannotBeEmpty => 'O nome da pasta não pode ficar vazio.';

  @override
  String get folderAlreadyExists => 'A pasta já existe.';

  @override
  String get folderCreationOnlyInAllFiles =>
      'A criação de pastas só está disponível em Todos os arquivos.';

  @override
  String get currentDirectoryUnavailable =>
      'O diretório atual não está disponível.';

  @override
  String get nothingSelected => 'Nada selecionado.';

  @override
  String get destinationFolderDoesNotExist => 'A pasta de destino não existe.';

  @override
  String cannotMoveFolderIntoItself(String name) {
    return 'Não é possível mover a pasta “$name” para dentro dela mesma.';
  }

  @override
  String failedToMoveItem(String name, String error) {
    return 'Falha ao mover $name: $error';
  }

  @override
  String movedNItems(int count) {
    return '$count item(ns) movido(s).';
  }

  @override
  String movedNItemsWithFailures(int count, int failed) {
    return '$count item(ns) movido(s), $failed falha(s).';
  }

  @override
  String movedNItemsFailedM(int moved, int failed) {
    return '$moved item(ns) movido(s), $failed falha(s).';
  }

  @override
  String get failedToMoveSelectedItems =>
      'Falha ao mover os itens selecionados.';

  @override
  String get noFilesWereMoved => 'Nenhum arquivo foi movido.';

  @override
  String renamedOldToNew(String oldName, String newName) {
    return '“$oldName” renomeado para “$newName”.';
  }

  @override
  String renamedFileFromTo(String oldName, String newName) {
    return '“$oldName” renomeado para “$newName”.';
  }

  @override
  String failedToRenameWithStatus(String name, int statusCode) {
    return 'Falha ao renomear “$name” ($statusCode).';
  }

  @override
  String failedToRenameFileWithCode(String name, int statusCode) {
    return 'Falha ao renomear “$name” ($statusCode).';
  }

  @override
  String failedToRenameWithError(String name, String error) {
    return 'Falha ao renomear “$name”: $error';
  }

  @override
  String failedToRenameFile(String name, String error) {
    return 'Falha ao renomear “$name”: $error';
  }

  @override
  String get renameConflictAlreadyExists =>
      'Falha ao renomear: já existe um arquivo ou pasta com esse nome.';

  @override
  String get renameFailedAlreadyExists =>
      'Falha ao renomear: já existe um arquivo ou pasta com esse nome.';

  @override
  String failedToCreateFolderWithCode(int statusCode) {
    return 'Falha ao criar pasta ($statusCode).';
  }

  @override
  String deletedNItemsFailedM(int deleted, int failed) {
    return '$deleted item(ns) excluído(s), $failed falha(s).';
  }

  @override
  String transferSummaryFiles(int percent, int completed, int total) {
    return '$percent%  $completed/$total arquivos';
  }

  @override
  String transferSummaryProgress(int percent, int completed, int total) {
    return '$percent%  $completed/$total arquivos';
  }

  @override
  String get downloadFailedGeneric => 'Falha no download';

  @override
  String uploadedNItemsWithFailures(int uploaded, int failed) {
    return '$uploaded item(ns) enviado(s), $failed falha(s)';
  }

  @override
  String uploadedNItemsFailedM(int uploaded, int failed) {
    return '$uploaded item(ns) enviado(s), $failed falha(s).';
  }

  @override
  String uploadSummaryFailedCount(int count) {
    return ', $count falha(s)';
  }

  @override
  String uploadLocalPathEmpty(String name) {
    return '$name: o caminho local está vazio';
  }

  @override
  String uploadErrorLocalPathEmpty(String name) {
    return '$name: o caminho local está vazio';
  }

  @override
  String get directoryUploadFailed => 'Falha ao enviar diretório';

  @override
  String get uploadDirectoryFailed => 'Falha ao enviar diretório';

  @override
  String get localFileNotFound => 'Arquivo local não encontrado';

  @override
  String get uploadErrorLocalFileNotFound => 'Arquivo local não encontrado';

  @override
  String get noSessionToken => 'Nenhum token de sessão ativo';

  @override
  String get uploadErrorNoSessionToken => 'Nenhum token de sessão ativo';

  @override
  String get serverDisconnectedStatus => 'Servidor desconectado';

  @override
  String get serverDisconnected => 'Servidor desconectado';

  @override
  String get serverIsUnreachable => 'O servidor está inacessível.';

  @override
  String get serverUnreachable => 'O servidor está inacessível.';

  @override
  String get uploadErrorLocalDirectoryNotFound =>
      'Diretório local não encontrado';

  @override
  String get uploadErrorFailedToScanDirectory =>
      'Falha ao verificar o diretório';

  @override
  String uploadErrorFolderCreateHttp(int statusCode) {
    return 'Falha ao criar pasta (HTTP $statusCode)';
  }

  @override
  String get authErrorMissingAccessToken =>
      'Token de acesso ausente na resposta';

  @override
  String get authErrorMissingRefreshToken =>
      'Token de atualização ausente na resposta';

  @override
  String get authErrorNoSavedCredentials =>
      'Nenhuma credencial salva disponível';

  @override
  String get authErrorNoRefreshToken =>
      'Nenhum token de atualização disponível';

  @override
  String get authErrorNoActiveSession => 'Nenhuma sessão ativa disponível';

  @override
  String get authErrorNoSavedUsername =>
      'Nenhum nome de usuário salvo disponível';

  @override
  String get updateNoReleasesPublished => 'Nenhuma versão publicada ainda.';

  @override
  String get language => 'Idioma';
}
