// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get helloWorld => 'Привет, мир!';

  @override
  String get whatShouldWeCallYou => 'как нам вас называть?';

  @override
  String get next => 'далее';

  @override
  String get skip => 'пропустить';

  @override
  String get selectImage => 'выбрать изображение';

  @override
  String get unsupportedImageFormat => 'неподдерживаемый формат изображения';

  @override
  String get invalidPrivateKeyOrSeedPhrase =>
      'Неверный приватный ключ или seed-фраза';

  @override
  String get pleaseReadAndAcceptTerms =>
      'Пожалуйста, прочитайте и примите условия использования';

  @override
  String get pleaseImportPrivateKeyFirst =>
      'Пожалуйста, сначала импортируйте ваш приватный ключ';

  @override
  String get publicKeyErrorMessage =>
      'вы ввели публичный ключ, пожалуйста, введите приватный ключ, он начинается с nsec1';

  @override
  String wordNotValid(String word) {
    return 'слово: $word недействительно, проверьте правильность написания';
  }

  @override
  String get login => 'войти';

  @override
  String get yourPublicKeyIs => 'ваш публичный ключ:';

  @override
  String get enterSeedPhraseOrNsec => 'введите вашу seed-фразу или nsec1';

  @override
  String get paste => 'вставить';

  @override
  String get add => 'добавить';

  @override
  String get iHaveReadAndAccept => 'Я прочитал(а) и принимаю ';

  @override
  String get termsAndConditions => 'условия использования';

  @override
  String get privacyPolicy => 'политику конфиденциальности';

  @override
  String get settingUpYourAccount => 'настройка вашего аккаунта';

  @override
  String get followingPeople => 'подписка на людей';

  @override
  String get movingData => 'перенос данных';

  @override
  String get cleaningUp => 'очистка';

  @override
  String get uploadingProfilePicture => 'загрузка фото профиля';

  @override
  String get recoveryPhrase => 'фраза восстановления';

  @override
  String get newSeedPhraseGenerated => 'создана новая seed-фраза';

  @override
  String get regenerate => 'сгенерировать заново';

  @override
  String get copiedSeedPhraseToClipboard =>
      'seed-фраза скопирована в буфер обмена';

  @override
  String get copy => 'копировать';

  @override
  String get hideWords => 'Скрыть слова';

  @override
  String get showWords => 'Показать слова';

  @override
  String get recoveryPhraseWarning =>
      'Фраза восстановления нужна для повторного входа. Храните её в безопасности!';

  @override
  String get publishAccount => 'опубликовать аккаунт';

  @override
  String get starterPacks => 'Стартовые наборы';

  @override
  String get additionalStarterPacks => 'Дополнительные стартовые наборы';

  @override
  String continueWithAccounts(int count) {
    return 'продолжить с $count аккаунтами';
  }

  @override
  String get selectStarterPack => 'выберите стартовый набор';

  @override
  String by(String name) {
    return 'от $name';
  }

  @override
  String get unselectAll => 'снять выделение';

  @override
  String get followAll => 'подписаться на всех';

  @override
  String followAccounts(int count) {
    return 'подписаться на $count аккаунтов';
  }

  @override
  String get invitedYouToJoin => ' пригласил(а) вас присоединиться';

  @override
  String get youWillFollowThesePeople => 'Вы сразу подпишетесь на этих людей';

  @override
  String get noStarterPackFound => '👀 стартовый набор не найден ';

  @override
  String get noWorriesYouCanStillJoin =>
      'не переживайте, вы всё равно можете присоединиться к Camelus!';

  @override
  String get joinCamelus => 'Присоединиться к Camelus';

  @override
  String get signupWithoutStarterPack =>
      'Зарегистрироваться без стартового набора';

  @override
  String copiedToClipboard(String text) {
    return 'Скопировано в буфер обмена: $text';
  }

  @override
  String get shareYourProfile => 'Поделиться профилем';

  @override
  String get following => 'Подписки';

  @override
  String get followers => 'Подписчики';

  @override
  String get profile => 'Профиль';

  @override
  String get bookmarks => 'Закладки';

  @override
  String get removeBookmark => 'Удалить эту закладку?';

  @override
  String get bookmarkRemoved => 'Закладка удалена';

  @override
  String get noPrivateBookmarks => 'Пока нет приватных закладок';

  @override
  String get noPublicBookmarks => 'Пока нет публичных закладок';

  @override
  String get privateBookmarks => 'Приватные';

  @override
  String get publicBookmarks => 'Публичные';

  @override
  String get addToBookmarks => 'Добавить в закладки';

  @override
  String get removeFromBookmarks => 'Удалить из закладок';

  @override
  String get addingToBookmarks => 'Добавление в закладки...';

  @override
  String get removingFromBookmarks => 'Удаление из закладок...';

  @override
  String get failedToAddBookmark => 'Не удалось добавить закладку';

  @override
  String get failedToRemoveBookmark => 'Не удалось удалить закладку';

  @override
  String get notImplementedYet => 'Ещё не реализовано';

  @override
  String get payments => 'Платежи';

  @override
  String get blocklist => 'Список блокировок';

  @override
  String get settings => 'Настройки';

  @override
  String get termsOfService => 'Условия обслуживания';

  @override
  String get languageSettings => 'Настройки языка';

  @override
  String get initialRoute => 'Начальная страница';

  @override
  String get moderation => 'Модерация';

  @override
  String get fileServers => 'Файловые серверы';

  @override
  String get logout => 'Выйти';

  @override
  String get unsavedChanges => 'Несохранённые изменения';

  @override
  String get unsavedChangesMessage =>
      'У вас есть несохранённые изменения. Вы хотите отменить их?';

  @override
  String get cancel => 'Отмена';

  @override
  String get discard => 'Отменить';

  @override
  String get saveChanges => 'сохранить изменения';

  @override
  String get saving => 'Сохранение...';

  @override
  String get changesSavedSuccessfully => 'Изменения успешно сохранены';

  @override
  String get failedToSaveChanges => 'Не удалось сохранить изменения';

  @override
  String get setupDefaultServers => 'настроить серверы по умолчанию';

  @override
  String get defaultLabel => ' (по умолчанию)';

  @override
  String get restoreDefaults => 'Восстановить значения по умолчанию';

  @override
  String get restoreDefaultsMessage =>
      'Вы уверены, что хотите восстановить серверы по умолчанию? Это удалит все пользовательские серверы.';

  @override
  String get restore => 'Восстановить';

  @override
  String get enterBlossomUrl => 'Введите URL Blossom';

  @override
  String errorUpdatingFilter(String error) {
    return 'Ошибка обновления фильтра $error';
  }

  @override
  String get moderationSettings => 'Настройки модерации';

  @override
  String get camelusContentFiltering => 'Фильтрация контента Camelus';

  @override
  String get enableContentFilteringDescription =>
      'Включите фильтрацию контента, чтобы скрыть потенциально неприемлемый контент.';

  @override
  String get enableContentFilter => 'Включить фильтр контента';

  @override
  String get contentFilterNote =>
      'Примечание: Фильтры применяются локально (на устройстве). Когда пользователи сообщают о контенте nostr напрямую в camelus, он добавляется в фильтр.';

  @override
  String get errorUploadingImage =>
      'ошибка загрузки изображения, серверы загрузки настроены?';

  @override
  String get editProfile => 'Редактировать профиль';

  @override
  String get save => 'сохранить';

  @override
  String get loadingProfile => 'Загрузка профиля...';

  @override
  String get uploading => 'Загрузка...';

  @override
  String get uploadingCapitalized => 'Загрузка';

  @override
  String get name => 'Имя';

  @override
  String get bio => 'О себе';

  @override
  String get pronouns => 'Местоимения';

  @override
  String get website => 'Веб-сайт';

  @override
  String get username => 'Имя пользователя (nip05)';

  @override
  String get lightningAddress => 'Адрес Lightning';

  @override
  String get editRelays => 'Редактировать релеи';

  @override
  String get error => 'ошибка:';

  @override
  String get whatsOnYourMind => 'О чём вы думаете?';

  @override
  String get writePost => 'написать пост';

  @override
  String replyTo(String name) {
    return 'ответить $name';
  }

  @override
  String get addToStarterPack => 'добавить в стартовый набор';

  @override
  String get blockReport => 'Блокировать/Пожаловаться';

  @override
  String get blockedUsers => 'Заблокированные пользователи';

  @override
  String get notImplemented => 'не реализовано';

  @override
  String get impersonation => 'выдача себя за другого';

  @override
  String get spam => 'спам';

  @override
  String get illegal => 'незаконный контент';

  @override
  String get profanity => 'нецензурная лексика';

  @override
  String get nudity => 'обнажённое тело';

  @override
  String get malware => 'вредоносное ПО';

  @override
  String get other => 'другое';

  @override
  String get reportSent => 'жалоба отправлена';

  @override
  String get thankYouForReport => 'спасибо за вашу жалобу';

  @override
  String get goBack => 'вернуться';

  @override
  String get blockReportTitle => 'блокировать/пожаловаться';

  @override
  String get user => 'пользователь';

  @override
  String get loading => 'загрузка';

  @override
  String get unblock => 'разблокировать';

  @override
  String get block => 'заблокировать';

  @override
  String get whatIsWrongWithPost => 'что не так с этим постом?';

  @override
  String get whatIsWrongWithUser => 'что не так с этим пользователем?';

  @override
  String get reportsAreSentToRelays =>
      'Жалобы отправляются на релеи, откуда вы получили заметку.';

  @override
  String get additionallyReportToCamelus =>
      'Дополнительно отправить жалобу напрямую в camelus';

  @override
  String get reportPost => 'пожаловаться на пост';

  @override
  String get reportUser => 'пожаловаться на пользователя';

  @override
  String get relays => 'Релеи';

  @override
  String get eventsRead => 'События прочитаны';

  @override
  String get eventsWritten => 'События записаны';

  @override
  String get connectionSource => 'Источник подключения';

  @override
  String get noDataAvailable => 'Нет доступных данных';

  @override
  String get notifications => 'Уведомления';

  @override
  String get searchHelp => 'Помощь по поиску';

  @override
  String get searchHelpMessage => 'Введите ключевые слова для поиска постов.';

  @override
  String get ok => 'OK';

  @override
  String get thread => 'тред';

  @override
  String get workInProgress => 'в разработке';

  @override
  String get update => 'Обновить';

  @override
  String get initialRouteSettings => 'Настройки начальной страницы';

  @override
  String get useSystemLanguage => 'Использовать язык системы';

  @override
  String get edit => 'редактировать';

  @override
  String get postSettings => 'Настройки поста';

  @override
  String get enableContentWarning => 'Включить предупреждение о контенте';

  @override
  String get warningType => 'Тип предупреждения:';

  @override
  String get customWarning => 'Пользовательское предупреждение';

  @override
  String get specifyContentWarning => 'Укажите предупреждение о контенте';

  @override
  String get enableClientTag => 'Включить тег клиента';

  @override
  String get close => 'Закрыть';

  @override
  String get sensitiveContent => 'Деликатный контент';

  @override
  String get flashingLights => 'Мигающие огни/Узоры';

  @override
  String get loudNoises => 'Громкие звуки';

  @override
  String get graphicContent => 'Графический контент';

  @override
  String get discrimination => 'Дискриминация';

  @override
  String get health => 'Здоровье';

  @override
  String get abuse => 'Насилие';

  @override
  String get routeHome => 'Главная';

  @override
  String get routePostsAndReplies => 'Посты и ответы';

  @override
  String get routeSearch => 'Поиск';

  @override
  String get routeNotifications => 'Уведомления';

  @override
  String get scrollToTop => 'прокрутить наверх';

  @override
  String get home => 'главная';

  @override
  String get search => 'поиск';

  @override
  String get explore => 'Исследовать';

  @override
  String get more => 'Ещё';

  @override
  String get posts => 'Посты';

  @override
  String get postsAndReplies => 'Посты и ответы';

  @override
  String get themeSettings => 'Настройки Темы';

  @override
  String get themeMode => 'Режим Темы';

  @override
  String get system => 'Система';

  @override
  String get light => 'Светлая';

  @override
  String get dark => 'Тёмная';

  @override
  String get theme => 'Тема';

  @override
  String get camelus => 'Camelus';

  @override
  String get nostr => 'Nostr';

  @override
  String get customColorTheme => 'Пользовательская Цветовая Тема';

  @override
  String get blue => 'Синий';

  @override
  String get purple => 'Фиолетовый';

  @override
  String get green => 'Зелёный';

  @override
  String get orange => 'Оранжевый';

  @override
  String get red => 'Красный';

  @override
  String get teal => 'Бирюзовый';

  @override
  String get pink => 'Розовый';

  @override
  String get indigo => 'Индиго';

  @override
  String get welcome => 'Добро пожаловать';
}
