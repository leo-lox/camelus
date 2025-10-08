// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get helloWorld => 'Olá Mundo!';

  @override
  String get whatShouldWeCallYou => 'como devemos te chamar?';

  @override
  String get next => 'próximo';

  @override
  String get skip => 'pular';

  @override
  String get selectImage => 'selecionar imagem';

  @override
  String get unsupportedImageFormat => 'formato de imagem não suportado';

  @override
  String get invalidPrivateKeyOrSeedPhrase =>
      'Chave privada ou frase semente inválida';

  @override
  String get pleaseReadAndAcceptTerms =>
      'Por favor, leia e aceite os termos e condições primeiro';

  @override
  String get pleaseImportPrivateKeyFirst =>
      'Por favor, importe sua chave privada primeiro';

  @override
  String get publicKeyErrorMessage =>
      'você inseriu uma chave pública, por favor insira uma chave privada, ela começa com nsec1';

  @override
  String wordNotValid(String word) {
    return 'palavra: $word não é válida, verifique se está escrita corretamente';
  }

  @override
  String get login => 'entrar';

  @override
  String get yourPublicKeyIs => 'sua chave pública é:';

  @override
  String get enterSeedPhraseOrNsec => 'insira sua frase semente ou nsec1';

  @override
  String get paste => 'colar';

  @override
  String get add => 'adicionar';

  @override
  String get iHaveReadAndAccept => 'Eu li e aceito os ';

  @override
  String get termsAndConditions => 'termos e condições';

  @override
  String get privacyPolicy => 'política de privacidade';

  @override
  String get settingUpYourAccount => 'configurando sua conta';

  @override
  String get followingPeople => 'seguindo pessoas';

  @override
  String get movingData => 'movendo dados';

  @override
  String get cleaningUp => 'limpando';

  @override
  String get uploadingProfilePicture => 'enviando foto de perfil';

  @override
  String get recoveryPhrase => 'frase de recuperação';

  @override
  String get newSeedPhraseGenerated => 'uma nova frase semente foi gerada';

  @override
  String get regenerate => 'regenerar';

  @override
  String get copiedSeedPhraseToClipboard =>
      'frase semente copiada para a área de transferência';

  @override
  String get copy => 'copiar';

  @override
  String get hideWords => 'Ocultar palavras';

  @override
  String get showWords => 'Mostrar palavras';

  @override
  String get recoveryPhraseWarning =>
      'Você precisa da frase de recuperação para fazer login novamente. Certifique-se de mantê-la segura!';

  @override
  String get publishAccount => 'publicar conta';

  @override
  String get starterPacks => 'Pacotes Iniciais';

  @override
  String get additionalStarterPacks => 'Pacotes Iniciais Adicionais';

  @override
  String continueWithAccounts(int count) {
    return 'continuar com $count contas';
  }

  @override
  String get selectStarterPack => 'selecionar um pacote inicial';

  @override
  String by(String name) {
    return 'por $name';
  }

  @override
  String get unselectAll => 'desmarcar tudo';

  @override
  String get followAll => 'seguir todos';

  @override
  String followAccounts(int count) {
    return 'seguir $count contas';
  }

  @override
  String get invitedYouToJoin => ' convidou você para participar';

  @override
  String get youWillFollowThesePeople =>
      'Você seguirá essas pessoas imediatamente';

  @override
  String get noStarterPackFound => '👀 nenhum pacote inicial encontrado ';

  @override
  String get noWorriesYouCanStillJoin =>
      'não se preocupe, você ainda pode se juntar ao Camelus!';

  @override
  String get joinCamelus => 'Junte-se ao Camelus';

  @override
  String get signupWithoutStarterPack => 'Cadastrar sem um pacote inicial';

  @override
  String copiedToClipboard(String text) {
    return 'Copiado para a área de transferência: $text';
  }

  @override
  String get shareYourProfile => 'Compartilhar seu Perfil';

  @override
  String get following => 'Seguindo';

  @override
  String get followers => 'Seguidores';

  @override
  String get profile => 'Perfil';

  @override
  String get bookmarks => 'Favoritos';

  @override
  String get notImplementedYet => 'Ainda não implementado';

  @override
  String get payments => 'Pagamentos';

  @override
  String get blocklist => 'Lista de Bloqueados';

  @override
  String get settings => 'Configurações';

  @override
  String get termsOfService => 'Termos de Serviço';

  @override
  String get languageSettings => 'Configurações de Idioma';

  @override
  String get initialRoute => 'Rota inicial';

  @override
  String get moderation => 'Moderação';

  @override
  String get fileServers => 'Servidores de arquivos';

  @override
  String get logout => 'Sair';

  @override
  String get unsavedChanges => 'Alterações Não Salvas';

  @override
  String get unsavedChangesMessage =>
      'Você tem alterações não salvas. Deseja descartá-las?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get discard => 'Descartar';

  @override
  String get saveChanges => 'salvar alterações';

  @override
  String get saving => 'Salvando...';

  @override
  String get changesSavedSuccessfully => 'Alterações salvas com sucesso';

  @override
  String get failedToSaveChanges => 'Falha ao salvar alterações';

  @override
  String get setupDefaultServers => 'configurar servidores padrão';

  @override
  String get defaultLabel => ' (padrão)';

  @override
  String get restoreDefaults => 'Restaurar Padrões';

  @override
  String get restoreDefaultsMessage =>
      'Tem certeza de que deseja restaurar os servidores padrão? Isso removerá todos os servidores personalizados.';

  @override
  String get restore => 'Restaurar';

  @override
  String get enterBlossomUrl => 'Insira a URL do blossom';

  @override
  String errorUpdatingFilter(String error) {
    return 'Erro ao atualizar filtro $error';
  }

  @override
  String get moderationSettings => 'Configurações de Moderação';

  @override
  String get camelusContentFiltering => 'Filtragem de Conteúdo Camelus';

  @override
  String get enableContentFilteringDescription =>
      'Ative a filtragem de conteúdo para ocultar conteúdo potencialmente inadequado.';

  @override
  String get enableContentFilter => 'Ativar Filtro de Conteúdo';

  @override
  String get contentFilterNote =>
      'Nota: Os filtros são aplicados localmente (no dispositivo). Quando os usuários reportam conteúdo nostr diretamente ao camelus, ele é adicionado ao filtro.';

  @override
  String get errorUploadingImage =>
      'erro ao enviar imagem, servidores de upload configurados?';

  @override
  String get editProfile => 'Editar Perfil';

  @override
  String get save => 'salvar';

  @override
  String get loadingProfile => 'Carregando perfil...';

  @override
  String get uploading => 'Enviando...';

  @override
  String get uploadingCapitalized => 'Enviando';

  @override
  String get name => 'Nome';

  @override
  String get bio => 'Biografia';

  @override
  String get pronouns => 'Pronomes';

  @override
  String get website => 'Site';

  @override
  String get username => 'Nome de usuário (nip05)';

  @override
  String get lightningAddress => 'Endereço Lightning';

  @override
  String get editRelays => 'Editar Relays';

  @override
  String get error => 'erro:';

  @override
  String get whatsOnYourMind => 'O que você está pensando?';

  @override
  String get writePost => 'escrever uma publicação';

  @override
  String replyTo(String name) {
    return 'responder a $name';
  }

  @override
  String get addToStarterPack => 'adicionar ao pacote inicial';

  @override
  String get blockReport => 'Bloquear/Denunciar';

  @override
  String get blockedUsers => 'Usuários Bloqueados';

  @override
  String get notImplemented => 'não implementado';

  @override
  String get impersonation => 'personificação';

  @override
  String get spam => 'spam';

  @override
  String get illegal => 'ilegal';

  @override
  String get profanity => 'linguagem obscena';

  @override
  String get nudity => 'nudez';

  @override
  String get malware => 'malware';

  @override
  String get other => 'outro';

  @override
  String get reportSent => 'denúncia enviada';

  @override
  String get thankYouForReport => 'obrigado pela sua denúncia';

  @override
  String get goBack => 'voltar';

  @override
  String get blockReportTitle => 'bloquear/denunciar';

  @override
  String get user => 'usuário';

  @override
  String get loading => 'carregando';

  @override
  String get unblock => 'desbloquear';

  @override
  String get block => 'bloquear';

  @override
  String get whatIsWrongWithPost => 'o que há de errado com esta publicação?';

  @override
  String get whatIsWrongWithUser => 'o que há de errado com este usuário?';

  @override
  String get reportsAreSentToRelays =>
      'As denúncias são enviadas para os relays de onde você recebeu a nota.';

  @override
  String get additionallyReportToCamelus =>
      'Adicionalmente, denunciar diretamente ao camelus';

  @override
  String get reportPost => 'denunciar publicação';

  @override
  String get reportUser => 'denunciar usuário';

  @override
  String get relays => 'Relays';

  @override
  String get eventsRead => 'Eventos Lidos';

  @override
  String get eventsWritten => 'Eventos Escritos';

  @override
  String get connectionSource => 'Fonte de Conexão';

  @override
  String get noDataAvailable => 'Nenhum dado disponível';

  @override
  String get notifications => 'Notificações';

  @override
  String get searchHelp => 'Ajuda de Pesquisa';

  @override
  String get searchHelpMessage =>
      'Digite palavras-chave para pesquisar publicações.';

  @override
  String get ok => 'OK';

  @override
  String get thread => 'tópico';

  @override
  String get workInProgress => 'trabalho em andamento';

  @override
  String get update => 'Atualizar';

  @override
  String get initialRouteSettings => 'Configurações de Rota Inicial';

  @override
  String get useSystemLanguage => 'Usar idioma do sistema';

  @override
  String get edit => 'editar';

  @override
  String get postSettings => 'Configurações de publicação';

  @override
  String get enableContentWarning => 'Habilitar aviso de conteúdo';

  @override
  String get warningType => 'Tipo de aviso';

  @override
  String get customWarning => 'Aviso personalizado';

  @override
  String get specifyContentWarning => 'Especificar aviso de conteúdo';

  @override
  String get enableClientTag => 'Habilitar tag de cliente';

  @override
  String get close => 'Fechar';

  @override
  String get sensitiveContent => 'Conteúdo sensível';

  @override
  String get flashingLights => 'Luzes intermitentes';

  @override
  String get loudNoises => 'Ruídos altos';

  @override
  String get graphicContent => 'Conteúdo gráfico';

  @override
  String get discrimination => 'Discriminação';

  @override
  String get health => 'Saúde';

  @override
  String get abuse => 'Abuso';

  @override
  String get routeHome => 'Início';

  @override
  String get routePostsAndReplies => 'Publicações e Respostas';

  @override
  String get routeSearch => 'Pesquisar';

  @override
  String get routeNotifications => 'Notificações';

  @override
  String get scrollToTop => 'Rolar para o topo';

  @override
  String get home => 'Início';

  @override
  String get search => 'Pesquisar';

  @override
  String get explore => 'Explorar';

  @override
  String get more => 'Mais';

  @override
  String get posts => 'Publicações';

  @override
  String get postsAndReplies => 'Publicações e Respostas';
}
