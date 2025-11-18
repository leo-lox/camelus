// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get helloWorld => '¡Hola Mundo!';

  @override
  String get whatShouldWeCallYou => '¿cómo deberíamos llamarte?';

  @override
  String get next => 'siguiente';

  @override
  String get skip => 'omitir';

  @override
  String get selectImage => 'seleccionar imagen';

  @override
  String get unsupportedImageFormat => 'formato de imagen no compatible';

  @override
  String get invalidPrivateKeyOrSeedPhrase =>
      'Clave privada o frase semilla inválida';

  @override
  String get pleaseReadAndAcceptTerms =>
      'Por favor, lee y acepta los términos y condiciones primero';

  @override
  String get pleaseImportPrivateKeyFirst =>
      'Por favor, importa tu clave privada primero';

  @override
  String get publicKeyErrorMessage =>
      'ingresaste una clave pública, por favor ingresa una clave privada, comienza con nsec1';

  @override
  String wordNotValid(String word) {
    return 'palabra: $word no es válida, verifica si está escrita correctamente';
  }

  @override
  String get login => 'iniciar sesión';

  @override
  String get yourPublicKeyIs => 'tu clave pública es:';

  @override
  String get enterSeedPhraseOrNsec => 'ingresa tu frase semilla o nsec1';

  @override
  String get paste => 'pegar';

  @override
  String get add => 'agregar';

  @override
  String get iHaveReadAndAccept => 'He leído y acepto los ';

  @override
  String get termsAndConditions => 'términos y condiciones';

  @override
  String get privacyPolicy => 'política de privacidad';

  @override
  String get settingUpYourAccount => 'configurando tu cuenta';

  @override
  String get followingPeople => 'siguiendo personas';

  @override
  String get movingData => 'moviendo datos';

  @override
  String get cleaningUp => 'limpiando';

  @override
  String get uploadingProfilePicture => 'subiendo foto de perfil';

  @override
  String get recoveryPhrase => 'frase de recuperación';

  @override
  String get newSeedPhraseGenerated => 'se ha generado una nueva frase semilla';

  @override
  String get regenerate => 'regenerar';

  @override
  String get copiedSeedPhraseToClipboard =>
      'frase semilla copiada al portapapeles';

  @override
  String get copy => 'copiar';

  @override
  String get hideWords => 'Ocultar palabras';

  @override
  String get showWords => 'Mostrar palabras';

  @override
  String get recoveryPhraseWarning =>
      'Necesitas la frase de recuperación para iniciar sesión nuevamente. ¡Asegúrate de mantenerla segura!';

  @override
  String get publishAccount => 'publicar cuenta';

  @override
  String get starterPacks => 'Paquetes Iniciales';

  @override
  String get additionalStarterPacks => 'Paquetes Iniciales Adicionales';

  @override
  String continueWithAccounts(int count) {
    return 'continuar con $count cuentas';
  }

  @override
  String get selectStarterPack => 'seleccionar un paquete inicial';

  @override
  String by(String name) {
    return 'por $name';
  }

  @override
  String get unselectAll => 'deseleccionar todo';

  @override
  String get followAll => 'seguir a todos';

  @override
  String followAccounts(int count) {
    return 'seguir $count cuentas';
  }

  @override
  String get invitedYouToJoin => ' te invitó a unirte';

  @override
  String get youWillFollowThesePeople =>
      'Seguirás a estas personas de inmediato';

  @override
  String get noStarterPackFound => '👀 no se encontró paquete inicial ';

  @override
  String get noWorriesYouCanStillJoin =>
      'no te preocupes, ¡aún puedes unirte a Camelus!';

  @override
  String get joinCamelus => 'Unirse a Camelus';

  @override
  String get signupWithoutStarterPack => 'Registrarse sin un paquete inicial';

  @override
  String copiedToClipboard(String text) {
    return 'Copiado al portapapeles: $text';
  }

  @override
  String get shareYourProfile => 'Compartir tu Perfil';

  @override
  String get following => 'Siguiendo';

  @override
  String get followers => 'Seguidores';

  @override
  String get profile => 'Perfil';

  @override
  String get bookmarks => 'Marcadores';

  @override
  String get removeBookmark => '¿Eliminar este marcador?';

  @override
  String get bookmarkRemoved => 'Marcador eliminado';

  @override
  String get noPrivateBookmarks => 'Aún no hay marcadores privados';

  @override
  String get noPublicBookmarks => 'Aún no hay marcadores públicos';

  @override
  String get privateBookmarks => 'Privado';

  @override
  String get publicBookmarks => 'Público';

  @override
  String get addToBookmarks => 'Agregar a marcadores';

  @override
  String get removeFromBookmarks => 'Eliminar de marcadores';

  @override
  String get addingToBookmarks => 'Agregando a marcadores...';

  @override
  String get removingFromBookmarks => 'Eliminando de marcadores...';

  @override
  String get failedToAddBookmark => 'No se pudo agregar el marcador';

  @override
  String get failedToRemoveBookmark => 'No se pudo eliminar el marcador';

  @override
  String get notImplementedYet => 'Aún no implementado';

  @override
  String get payments => 'Pagos';

  @override
  String get blocklist => 'Lista de Bloqueados';

  @override
  String get settings => 'Ajustes';

  @override
  String get termsOfService => 'Términos de Servicio';

  @override
  String get languageSettings => 'Configuración de Idioma';

  @override
  String get initialRoute => 'Ruta inicial';

  @override
  String get moderation => 'Moderación';

  @override
  String get fileServers => 'Servidores de archivos';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get unsavedChanges => 'Cambios Sin Guardar';

  @override
  String get unsavedChangesMessage =>
      'Tienes cambios sin guardar. ¿Quieres descartarlos?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get discard => 'Descartar';

  @override
  String get saveChanges => 'guardar cambios';

  @override
  String get saving => 'Guardando...';

  @override
  String get changesSavedSuccessfully => 'Cambios guardados exitosamente';

  @override
  String get failedToSaveChanges => 'Error al guardar cambios';

  @override
  String get setupDefaultServers => 'configurar servidores predeterminados';

  @override
  String get defaultLabel => ' (predeterminado)';

  @override
  String get restoreDefaults => 'Restaurar Predeterminados';

  @override
  String get restoreDefaultsMessage =>
      '¿Estás seguro de que quieres restaurar los servidores predeterminados? Esto eliminará todos los servidores personalizados.';

  @override
  String get restore => 'Restaurar';

  @override
  String get enterBlossomUrl => 'Ingresa URL de blossom';

  @override
  String errorUpdatingFilter(String error) {
    return 'Error al actualizar filtro $error';
  }

  @override
  String get moderationSettings => 'Configuración de Moderación';

  @override
  String get camelusContentFiltering => 'Filtrado de Contenido Camelus';

  @override
  String get enableContentFilteringDescription =>
      'Habilita el filtrado de contenido para ocultar contenido potencialmente inapropiado.';

  @override
  String get enableContentFilter => 'Habilitar Filtro de Contenido';

  @override
  String get contentFilterNote =>
      'Nota: Los filtros se aplican localmente (en el dispositivo). Cuando los usuarios reportan contenido nostr directamente a camelus, se agrega al filtro.';

  @override
  String get errorUploadingImage =>
      'error al subir imagen, ¿servidores de carga configurados?';

  @override
  String get editProfile => 'Editar Perfil';

  @override
  String get save => 'guardar';

  @override
  String get loadingProfile => 'Cargando perfil...';

  @override
  String get uploading => 'Subiendo...';

  @override
  String get uploadingCapitalized => 'Subiendo';

  @override
  String get name => 'Nombre';

  @override
  String get bio => 'Biografía';

  @override
  String get pronouns => 'Pronombres';

  @override
  String get website => 'Sitio web';

  @override
  String get username => 'Nombre de usuario (nip05)';

  @override
  String get lightningAddress => 'Dirección Lightning';

  @override
  String get editRelays => 'Editar Relays';

  @override
  String get error => 'error:';

  @override
  String get whatsOnYourMind => '¿Qué estás pensando?';

  @override
  String get writePost => 'escribir una publicación';

  @override
  String replyTo(String name) {
    return 'responder a $name';
  }

  @override
  String get addToStarterPack => 'agregar al paquete inicial';

  @override
  String get blockReport => 'Bloquear/Reportar';

  @override
  String get blockedUsers => 'Usuarios Bloqueados';

  @override
  String get notImplemented => 'no implementado';

  @override
  String get impersonation => 'suplantación de identidad';

  @override
  String get spam => 'spam';

  @override
  String get illegal => 'ilegal';

  @override
  String get profanity => 'lenguaje obsceno';

  @override
  String get nudity => 'desnudez';

  @override
  String get malware => 'malware';

  @override
  String get other => 'otro';

  @override
  String get reportSent => 'reporte enviado';

  @override
  String get thankYouForReport => 'gracias por tu reporte';

  @override
  String get goBack => 'volver';

  @override
  String get blockReportTitle => 'bloquear/reportar';

  @override
  String get user => 'usuario';

  @override
  String get loading => 'cargando';

  @override
  String get unblock => 'desbloquear';

  @override
  String get block => 'bloquear';

  @override
  String get whatIsWrongWithPost => '¿qué está mal con esta publicación?';

  @override
  String get whatIsWrongWithUser => '¿qué está mal con este usuario?';

  @override
  String get reportsAreSentToRelays =>
      'Los reportes se envían a los relays donde recibiste la nota.';

  @override
  String get additionallyReportToCamelus =>
      'Adicionalmente, reportar directamente a camelus';

  @override
  String get reportPost => 'reportar publicación';

  @override
  String get reportUser => 'reportar usuario';

  @override
  String get relays => 'Relays';

  @override
  String get eventsRead => 'Eventos Leídos';

  @override
  String get eventsWritten => 'Eventos Escritos';

  @override
  String get connectionSource => 'Fuente de Conexión';

  @override
  String get noDataAvailable => 'No hay datos disponibles';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get searchHelp => 'Ayuda de Búsqueda';

  @override
  String get searchHelpMessage =>
      'Ingresa palabras clave para buscar publicaciones.';

  @override
  String get ok => 'OK';

  @override
  String get thread => 'hilo';

  @override
  String get workInProgress => 'trabajo en progreso';

  @override
  String get update => 'Actualizar';

  @override
  String get initialRouteSettings => 'Configuración de Ruta Inicial';

  @override
  String get useSystemLanguage => 'Usar idioma del sistema';

  @override
  String get edit => 'editar';

  @override
  String get postSettings => 'Configuración de publicación';

  @override
  String get enableContentWarning => 'Habilitar advertencia de contenido';

  @override
  String get warningType => 'Tipo de advertencia';

  @override
  String get customWarning => 'Advertencia personalizada';

  @override
  String get specifyContentWarning => 'Especificar advertencia de contenido';

  @override
  String get enableClientTag => 'Habilitar etiqueta de cliente';

  @override
  String get close => 'Cerrar';

  @override
  String get sensitiveContent => 'Contenido sensible';

  @override
  String get flashingLights => 'Luces intermitentes';

  @override
  String get loudNoises => 'Ruidos fuertes';

  @override
  String get graphicContent => 'Contenido gráfico';

  @override
  String get discrimination => 'Discriminación';

  @override
  String get health => 'Salud';

  @override
  String get abuse => 'Abuso';

  @override
  String get routeHome => 'Inicio';

  @override
  String get routePostsAndReplies => 'Publicaciones y Respuestas';

  @override
  String get routeSearch => 'Buscar';

  @override
  String get routeNotifications => 'Notificaciones';

  @override
  String get scrollToTop => 'Desplazarse hacia arriba';

  @override
  String get home => 'Inicio';

  @override
  String get search => 'Buscar';

  @override
  String get explore => 'Explorar';

  @override
  String get more => 'Más';

  @override
  String get posts => 'Publicaciones';

  @override
  String get postsAndReplies => 'Publicaciones y Respuestas';

  @override
  String get themeSettings => 'Configuración de Tema';

  @override
  String get themeMode => 'Modo de Tema';

  @override
  String get system => 'Sistema';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Oscuro';

  @override
  String get theme => 'Tema';

  @override
  String get camelus => 'Camelus';

  @override
  String get nostr => 'Nostr';

  @override
  String get customColorTheme => 'Tema de Color Personalizado';

  @override
  String get blue => 'Azul';

  @override
  String get purple => 'Morado';

  @override
  String get green => 'Verde';

  @override
  String get orange => 'Naranja';

  @override
  String get red => 'Rojo';

  @override
  String get teal => 'Verde Azulado';

  @override
  String get pink => 'Rosa';

  @override
  String get indigo => 'Índigo';

  @override
  String get welcome => 'Bienvenido';

  @override
  String get pleaseLoginToManageFileServers =>
      'Por favor, inicia sesión para administrar servidores de archivos';
}
