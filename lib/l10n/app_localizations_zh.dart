// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get helloWorld => '你好世界！';

  @override
  String get whatShouldWeCallYou => '我们该怎么称呼您？';

  @override
  String get next => '下一步';

  @override
  String get skip => '跳过';

  @override
  String get selectImage => '选择图片';

  @override
  String get unsupportedImageFormat => '不支持的图片格式';

  @override
  String get invalidPrivateKeyOrSeedPhrase => '无效的私钥或助记词';

  @override
  String get pleaseReadAndAcceptTerms => '请先阅读并接受条款和条件';

  @override
  String get pleaseImportPrivateKeyFirst => '请先导入您的私钥';

  @override
  String get publicKeyErrorMessage => '您输入了公钥，请输入私钥，它以nsec1开头';

  @override
  String wordNotValid(String word) {
    return '单词：$word无效，请检查拼写是否正确';
  }

  @override
  String get login => '登录';

  @override
  String get yourPublicKeyIs => '您的公钥是：';

  @override
  String get enterSeedPhraseOrNsec => '输入您的助记词或nsec1';

  @override
  String get paste => '粘贴';

  @override
  String get add => '添加';

  @override
  String get iHaveReadAndAccept => '我已阅读并接受';

  @override
  String get termsAndConditions => '条款和条件';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get settingUpYourAccount => '正在设置您的账户';

  @override
  String get followingPeople => '正在关注用户';

  @override
  String get movingData => '正在移动数据';

  @override
  String get cleaningUp => '正在清理';

  @override
  String get uploadingProfilePicture => '正在上传个人资料图片';

  @override
  String get recoveryPhrase => '恢复短语';

  @override
  String get newSeedPhraseGenerated => '已生成新的助记词';

  @override
  String get regenerate => '重新生成';

  @override
  String get copiedSeedPhraseToClipboard => '已将助记词复制到剪贴板';

  @override
  String get copy => '复制';

  @override
  String get hideWords => '隐藏单词';

  @override
  String get showWords => '显示单词';

  @override
  String get recoveryPhraseWarning => '您需要恢复短语才能再次登录。请务必妥善保管！';

  @override
  String get publishAccount => '发布账户';

  @override
  String get starterPacks => '新手包';

  @override
  String get additionalStarterPacks => '其他新手包';

  @override
  String continueWithAccounts(int count) {
    return '继续使用$count个账户';
  }

  @override
  String get selectStarterPack => '选择一个新手包';

  @override
  String by(String name) {
    return '由$name创建';
  }

  @override
  String get unselectAll => '取消全选';

  @override
  String get followAll => '全部关注';

  @override
  String followAccounts(int count) {
    return '关注$count个账户';
  }

  @override
  String get invitedYouToJoin => '邀请您加入';

  @override
  String get youWillFollowThesePeople => '您将立即关注这些人';

  @override
  String get noStarterPackFound => '👀 未找到新手包 ';

  @override
  String get noWorriesYouCanStillJoin => '不用担心，您仍然可以加入Camelus！';

  @override
  String get joinCamelus => '加入Camelus';

  @override
  String get signupWithoutStarterPack => '不使用新手包注册';

  @override
  String copiedToClipboard(String text) {
    return '已复制到剪贴板：$text';
  }

  @override
  String get shareYourProfile => '分享您的个人资料';

  @override
  String get following => '关注中';

  @override
  String get followers => '关注者';

  @override
  String get profile => '个人资料';

  @override
  String get bookmarks => '书签';

  @override
  String get removeBookmark => '删除此书签？';

  @override
  String get bookmarkRemoved => '书签已删除';

  @override
  String get noPrivateBookmarks => '还没有私密书签';

  @override
  String get noPublicBookmarks => '还没有公开书签';

  @override
  String get privateBookmarks => '私密';

  @override
  String get publicBookmarks => '公开';

  @override
  String get addToBookmarks => '添加到书签';

  @override
  String get removeFromBookmarks => '从书签中移除';

  @override
  String get addingToBookmarks => '正在添加到书签...';

  @override
  String get removingFromBookmarks => '正在从书签中移除...';

  @override
  String get failedToAddBookmark => '添加书签失败';

  @override
  String get failedToRemoveBookmark => '删除书签失败';

  @override
  String get notImplementedYet => '尚未实现';

  @override
  String get payments => '支付';

  @override
  String get blocklist => '黑名单';

  @override
  String get settings => '设置';

  @override
  String get termsOfService => '服务条款';

  @override
  String get languageSettings => '语言设置';

  @override
  String get initialRoute => '初始路由';

  @override
  String get moderation => '管理';

  @override
  String get fileServers => '文件服务器';

  @override
  String get logout => '退出登录';

  @override
  String get unsavedChanges => '未保存的更改';

  @override
  String get unsavedChangesMessage => '您有未保存的更改。要放弃它们吗？';

  @override
  String get cancel => '取消';

  @override
  String get discard => '放弃';

  @override
  String get saveChanges => '保存更改';

  @override
  String get saving => '正在保存...';

  @override
  String get changesSavedSuccessfully => '更改保存成功';

  @override
  String get failedToSaveChanges => '保存更改失败';

  @override
  String get setupDefaultServers => '设置默认服务器';

  @override
  String get defaultLabel => '（默认）';

  @override
  String get restoreDefaults => '恢复默认';

  @override
  String get restoreDefaultsMessage => '您确定要恢复默认服务器吗？这将删除所有自定义服务器。';

  @override
  String get restore => '恢复';

  @override
  String get enterBlossomUrl => '输入Blossom URL';

  @override
  String errorUpdatingFilter(String error) {
    return '更新过滤器时出错 $error';
  }

  @override
  String get moderationSettings => '管理设置';

  @override
  String get camelusContentFiltering => 'Camelus内容过滤';

  @override
  String get enableContentFilteringDescription => '启用内容过滤以隐藏可能不适当的内容。';

  @override
  String get enableContentFilter => '启用内容过滤器';

  @override
  String get contentFilterNote =>
      '注意：过滤器在本地（设备上）应用。当用户直接向camelus举报nostr内容时，它会被添加到过滤器中。';

  @override
  String get errorUploadingImage => '上传图片时出错，是否已配置上传服务器？';

  @override
  String get editProfile => '编辑个人资料';

  @override
  String get save => '保存';

  @override
  String get loadingProfile => '正在加载个人资料...';

  @override
  String get uploading => '正在上传...';

  @override
  String get uploadingCapitalized => '正在上传';

  @override
  String get name => '名称';

  @override
  String get bio => '简介';

  @override
  String get pronouns => '代词';

  @override
  String get website => '网站';

  @override
  String get username => '用户名（nip05）';

  @override
  String get lightningAddress => '闪电网络地址';

  @override
  String get editRelays => '编辑中继';

  @override
  String get error => '错误：';

  @override
  String get whatsOnYourMind => '您在想什么？';

  @override
  String get writePost => '写一篇帖子';

  @override
  String replyTo(String name) {
    return '回复$name';
  }

  @override
  String get addToStarterPack => '添加到新手包';

  @override
  String get blockReport => '屏蔽/举报';

  @override
  String get blockedUsers => '已屏蔽的用户';

  @override
  String get notImplemented => '未实现';

  @override
  String get impersonation => '冒充';

  @override
  String get spam => '垃圾信息';

  @override
  String get illegal => '非法';

  @override
  String get profanity => '亵渎';

  @override
  String get nudity => '裸露';

  @override
  String get malware => '恶意软件';

  @override
  String get other => '其他';

  @override
  String get reportSent => '举报已发送';

  @override
  String get thankYouForReport => '感谢您的举报';

  @override
  String get goBack => '返回';

  @override
  String get blockReportTitle => '屏蔽/举报';

  @override
  String get user => '用户';

  @override
  String get loading => '正在加载';

  @override
  String get unblock => '取消屏蔽';

  @override
  String get block => '屏蔽';

  @override
  String get whatIsWrongWithPost => '这篇帖子有什么问题？';

  @override
  String get whatIsWrongWithUser => '这个用户有什么问题？';

  @override
  String get reportsAreSentToRelays => '举报将发送到您收到笔记的中继。';

  @override
  String get additionallyReportToCamelus => '另外，直接向camelus举报';

  @override
  String get reportPost => '举报帖子';

  @override
  String get reportUser => '举报用户';

  @override
  String get relays => '中继';

  @override
  String get eventsRead => '已读事件';

  @override
  String get eventsWritten => '已写事件';

  @override
  String get connectionSource => '连接源';

  @override
  String get noDataAvailable => '没有可用数据';

  @override
  String get notifications => '通知';

  @override
  String get searchHelp => '搜索帮助';

  @override
  String get searchHelpMessage => '输入关键词以搜索帖子。';

  @override
  String get ok => '确定';

  @override
  String get thread => '话题';

  @override
  String get workInProgress => '正在进行中';

  @override
  String get update => '更新';

  @override
  String get initialRouteSettings => '初始路由设置';

  @override
  String get useSystemLanguage => '使用系统语言';

  @override
  String get edit => '编辑';

  @override
  String get postSettings => '帖子设置';

  @override
  String get enableContentWarning => '启用内容警告';

  @override
  String get warningType => '警告类型';

  @override
  String get customWarning => '自定义警告';

  @override
  String get specifyContentWarning => '指定内容警告';

  @override
  String get enableClientTag => '启用客户端标签';

  @override
  String get close => '关闭';

  @override
  String get sensitiveContent => '敏感内容';

  @override
  String get flashingLights => '闪烁灯光';

  @override
  String get loudNoises => '响亮噪音';

  @override
  String get graphicContent => '图形内容';

  @override
  String get discrimination => '歧视';

  @override
  String get health => '健康';

  @override
  String get abuse => '虐待';

  @override
  String get routeHome => '主页';

  @override
  String get routePostsAndReplies => '帖子和回复';

  @override
  String get routeSearch => '搜索';

  @override
  String get routeNotifications => '通知';

  @override
  String get scrollToTop => '滚动到顶部';

  @override
  String get home => '主页';

  @override
  String get search => '搜索';

  @override
  String get explore => '探索';

  @override
  String get more => '更多';

  @override
  String get posts => '帖子';

  @override
  String get postsAndReplies => '帖子和回复';

  @override
  String get themeSettings => '主题设置';

  @override
  String get themeMode => '主题模式';

  @override
  String get system => '系统';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get theme => '主题';

  @override
  String get camelus => 'Camelus';

  @override
  String get nostr => 'Nostr';

  @override
  String get customColorTheme => '自定义颜色主题';

  @override
  String get blue => '蓝色';

  @override
  String get purple => '紫色';

  @override
  String get green => '绿色';

  @override
  String get orange => '橙色';

  @override
  String get red => '红色';

  @override
  String get teal => '青色';

  @override
  String get pink => '粉色';

  @override
  String get indigo => '靛蓝色';

  @override
  String get welcome => '欢迎';

  @override
  String get pleaseLoginToManageFileServers => '请登录以管理文件服务器';

  @override
  String get welcomeTo => '欢迎来到';

  @override
  String get joinTheConversation => '加入对话';

  @override
  String get browseWithoutLogin => '无需登录即可浏览';

  @override
  String get loginRegistrationRequired => '需要登录/注册';

  @override
  String get pleaseLoginToInteract => '请登录/注册以与帖子互动';

  @override
  String get loginRegister => '登录/注册';
}
