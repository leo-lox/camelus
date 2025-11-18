// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get helloWorld => 'こんにちは世界！';

  @override
  String get whatShouldWeCallYou => '何とお呼びすればよろしいでしょうか？';

  @override
  String get next => '次へ';

  @override
  String get skip => 'スキップ';

  @override
  String get selectImage => '画像を選択';

  @override
  String get unsupportedImageFormat => 'サポートされていない画像形式';

  @override
  String get invalidPrivateKeyOrSeedPhrase => '無効な秘密鍵またはシードフレーズ';

  @override
  String get pleaseReadAndAcceptTerms => 'まず利用規約をお読みになり、同意してください';

  @override
  String get pleaseImportPrivateKeyFirst => 'まず秘密鍵をインポートしてください';

  @override
  String get publicKeyErrorMessage => '公開鍵を入力しました。nsec1で始まる秘密鍵を入力してください';

  @override
  String wordNotValid(String word) {
    return '単語：$wordは無効です。正しく入力されているか確認してください';
  }

  @override
  String get login => 'ログイン';

  @override
  String get yourPublicKeyIs => 'あなたの公開鍵：';

  @override
  String get enterSeedPhraseOrNsec => 'シードフレーズまたはnsec1を入力してください';

  @override
  String get paste => '貼り付け';

  @override
  String get add => '追加';

  @override
  String get iHaveReadAndAccept => '私は';

  @override
  String get termsAndConditions => '利用規約';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get settingUpYourAccount => 'アカウントをセットアップ中';

  @override
  String get followingPeople => 'フォロー中';

  @override
  String get movingData => 'データを移動中';

  @override
  String get cleaningUp => 'クリーンアップ中';

  @override
  String get uploadingProfilePicture => 'プロフィール画像をアップロード中';

  @override
  String get recoveryPhrase => 'リカバリーフレーズ';

  @override
  String get newSeedPhraseGenerated => '新しいシードフレーズが生成されました';

  @override
  String get regenerate => '再生成';

  @override
  String get copiedSeedPhraseToClipboard => 'シードフレーズをクリップボードにコピーしました';

  @override
  String get copy => 'コピー';

  @override
  String get hideWords => '単語を非表示';

  @override
  String get showWords => '単語を表示';

  @override
  String get recoveryPhraseWarning => '再度ログインするにはリカバリーフレーズが必要です。安全に保管してください！';

  @override
  String get publishAccount => 'アカウントを公開';

  @override
  String get starterPacks => 'スターターパック';

  @override
  String get additionalStarterPacks => '追加のスターターパック';

  @override
  String continueWithAccounts(int count) {
    return '$count個のアカウントで続ける';
  }

  @override
  String get selectStarterPack => 'スターターパックを選択';

  @override
  String by(String name) {
    return '$nameによる';
  }

  @override
  String get unselectAll => 'すべて選択解除';

  @override
  String get followAll => 'すべてフォロー';

  @override
  String followAccounts(int count) {
    return '$count個のアカウントをフォロー';
  }

  @override
  String get invitedYouToJoin => 'があなたを招待しました';

  @override
  String get youWillFollowThesePeople => 'これらの人々をすぐにフォローします';

  @override
  String get noStarterPackFound => '👀 スターターパックが見つかりません ';

  @override
  String get noWorriesYouCanStillJoin => 'ご心配なく、Camelusにまだ参加できます！';

  @override
  String get joinCamelus => 'Camelusに参加';

  @override
  String get signupWithoutStarterPack => 'スターターパックなしで登録';

  @override
  String copiedToClipboard(String text) {
    return 'クリップボードにコピーしました：$text';
  }

  @override
  String get shareYourProfile => 'プロフィールを共有';

  @override
  String get following => 'フォロー中';

  @override
  String get followers => 'フォロワー';

  @override
  String get profile => 'プロフィール';

  @override
  String get bookmarks => 'ブックマーク';

  @override
  String get removeBookmark => 'このブックマークを削除しますか？';

  @override
  String get bookmarkRemoved => 'ブックマークを削除しました';

  @override
  String get noPrivateBookmarks => 'まだプライベートブックマークはありません';

  @override
  String get noPublicBookmarks => 'まだパブリックブックマークはありません';

  @override
  String get privateBookmarks => 'プライベート';

  @override
  String get publicBookmarks => 'パブリック';

  @override
  String get addToBookmarks => 'ブックマークに追加';

  @override
  String get removeFromBookmarks => 'ブックマークから削除';

  @override
  String get addingToBookmarks => 'ブックマークに追加中...';

  @override
  String get removingFromBookmarks => 'ブックマークから削除中...';

  @override
  String get failedToAddBookmark => 'ブックマークの追加に失敗しました';

  @override
  String get failedToRemoveBookmark => 'ブックマークの削除に失敗しました';

  @override
  String get notImplementedYet => 'まだ実装されていません';

  @override
  String get payments => '支払い';

  @override
  String get blocklist => 'ブロックリスト';

  @override
  String get settings => '設定';

  @override
  String get termsOfService => '利用規約';

  @override
  String get languageSettings => '言語設定';

  @override
  String get initialRoute => '初期ルート';

  @override
  String get moderation => 'モデレーション';

  @override
  String get fileServers => 'ファイルサーバー';

  @override
  String get logout => 'ログアウト';

  @override
  String get unsavedChanges => '未保存の変更';

  @override
  String get unsavedChangesMessage => '未保存の変更があります。破棄しますか？';

  @override
  String get cancel => 'キャンセル';

  @override
  String get discard => '破棄';

  @override
  String get saveChanges => '変更を保存';

  @override
  String get saving => '保存中...';

  @override
  String get changesSavedSuccessfully => '変更が正常に保存されました';

  @override
  String get failedToSaveChanges => '変更の保存に失敗しました';

  @override
  String get setupDefaultServers => 'デフォルトサーバーをセットアップ';

  @override
  String get defaultLabel => ' (デフォルト)';

  @override
  String get restoreDefaults => 'デフォルトに戻す';

  @override
  String get restoreDefaultsMessage =>
      'デフォルトサーバーに戻してもよろしいですか？すべてのカスタムサーバーが削除されます。';

  @override
  String get restore => '復元';

  @override
  String get enterBlossomUrl => 'Blossom URLを入力';

  @override
  String errorUpdatingFilter(String error) {
    return 'フィルターの更新エラー $error';
  }

  @override
  String get moderationSettings => 'モデレーション設定';

  @override
  String get camelusContentFiltering => 'Camelus コンテンツフィルタリング';

  @override
  String get enableContentFilteringDescription =>
      '不適切な可能性のあるコンテンツを非表示にするには、コンテンツフィルタリングを有効にします。';

  @override
  String get enableContentFilter => 'コンテンツフィルターを有効にする';

  @override
  String get contentFilterNote =>
      '注：フィルターはローカル（デバイス上）で適用されます。ユーザーがnostrコンテンツをcamelusに直接報告すると、フィルターに追加されます。';

  @override
  String get errorUploadingImage => '画像のアップロードエラー、アップロードサーバーは設定されていますか？';

  @override
  String get editProfile => 'プロフィールを編集';

  @override
  String get save => '保存';

  @override
  String get loadingProfile => 'プロフィールを読み込み中...';

  @override
  String get uploading => 'アップロード中...';

  @override
  String get uploadingCapitalized => 'アップロード中';

  @override
  String get name => '名前';

  @override
  String get bio => '自己紹介';

  @override
  String get pronouns => '代名詞';

  @override
  String get website => 'ウェブサイト';

  @override
  String get username => 'ユーザー名 (nip05)';

  @override
  String get lightningAddress => 'Lightningアドレス';

  @override
  String get editRelays => 'リレーを編集';

  @override
  String get error => 'エラー：';

  @override
  String get whatsOnYourMind => '今何を考えていますか？';

  @override
  String get writePost => '投稿を書く';

  @override
  String replyTo(String name) {
    return '$nameに返信';
  }

  @override
  String get addToStarterPack => 'スターターパックに追加';

  @override
  String get blockReport => 'ブロック/報告';

  @override
  String get blockedUsers => 'ブロック済みユーザー';

  @override
  String get notImplemented => '実装されていません';

  @override
  String get impersonation => 'なりすまし';

  @override
  String get spam => 'スパム';

  @override
  String get illegal => '違法';

  @override
  String get profanity => '冒涜';

  @override
  String get nudity => 'ヌード';

  @override
  String get malware => 'マルウェア';

  @override
  String get other => 'その他';

  @override
  String get reportSent => '報告を送信しました';

  @override
  String get thankYouForReport => '報告ありがとうございます';

  @override
  String get goBack => '戻る';

  @override
  String get blockReportTitle => 'ブロック/報告';

  @override
  String get user => 'ユーザー';

  @override
  String get loading => '読み込み中';

  @override
  String get unblock => 'ブロック解除';

  @override
  String get block => 'ブロック';

  @override
  String get whatIsWrongWithPost => 'この投稿の何が問題ですか？';

  @override
  String get whatIsWrongWithUser => 'このユーザーの何が問題ですか？';

  @override
  String get reportsAreSentToRelays => '報告は、ノートを受信したリレーに送信されます。';

  @override
  String get additionallyReportToCamelus => 'さらに、camelusに直接報告する';

  @override
  String get reportPost => '投稿を報告';

  @override
  String get reportUser => 'ユーザーを報告';

  @override
  String get relays => 'リレー';

  @override
  String get eventsRead => '読み込んだイベント';

  @override
  String get eventsWritten => '書き込んだイベント';

  @override
  String get connectionSource => '接続元';

  @override
  String get noDataAvailable => '利用可能なデータがありません';

  @override
  String get notifications => '通知';

  @override
  String get searchHelp => '検索ヘルプ';

  @override
  String get searchHelpMessage => 'キーワードを入力して投稿を検索します。';

  @override
  String get ok => 'OK';

  @override
  String get thread => 'スレッド';

  @override
  String get workInProgress => '作業中';

  @override
  String get update => '更新';

  @override
  String get initialRouteSettings => '初期ルート設定';

  @override
  String get useSystemLanguage => 'システム言語を使用';

  @override
  String get edit => '編集';

  @override
  String get postSettings => '投稿設定';

  @override
  String get enableContentWarning => 'コンテンツ警告を有効にする';

  @override
  String get warningType => '警告タイプ';

  @override
  String get customWarning => 'カスタム警告';

  @override
  String get specifyContentWarning => 'コンテンツ警告を指定';

  @override
  String get enableClientTag => 'クライアントタグを有効にする';

  @override
  String get close => '閉じる';

  @override
  String get sensitiveContent => 'センシティブなコンテンツ';

  @override
  String get flashingLights => '点滅する光';

  @override
  String get loudNoises => '大きな音';

  @override
  String get graphicContent => 'グラフィックコンテンツ';

  @override
  String get discrimination => '差別';

  @override
  String get health => '健康';

  @override
  String get abuse => '虐待';

  @override
  String get routeHome => 'ホーム';

  @override
  String get routePostsAndReplies => '投稿と返信';

  @override
  String get routeSearch => '検索';

  @override
  String get routeNotifications => '通知';

  @override
  String get scrollToTop => 'トップへスクロール';

  @override
  String get home => 'ホーム';

  @override
  String get search => '検索';

  @override
  String get explore => '探検する';

  @override
  String get more => 'その他';

  @override
  String get posts => '投稿';

  @override
  String get postsAndReplies => '投稿と返信';

  @override
  String get themeSettings => 'テーマ設定';

  @override
  String get themeMode => 'テーマモード';

  @override
  String get system => 'システム';

  @override
  String get light => 'ライト';

  @override
  String get dark => 'ダーク';

  @override
  String get theme => 'テーマ';

  @override
  String get camelus => 'Camelus';

  @override
  String get nostr => 'Nostr';

  @override
  String get customColorTheme => 'カスタムカラーテーマ';

  @override
  String get blue => '青';

  @override
  String get purple => '紫';

  @override
  String get green => '緑';

  @override
  String get orange => 'オレンジ';

  @override
  String get red => '赤';

  @override
  String get teal => 'ティール';

  @override
  String get pink => 'ピンク';

  @override
  String get indigo => 'インディゴ';

  @override
  String get welcome => 'ようこそ';

  @override
  String get pleaseLoginToManageFileServers => 'ファイルサーバーを管理するにはログインしてください';
}
