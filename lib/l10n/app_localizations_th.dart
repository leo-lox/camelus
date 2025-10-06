// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get helloWorld => 'สวัสดีชาวโลก!';

  @override
  String get whatShouldWeCallYou => 'เราควรเรียกคุณว่าอะไร?';

  @override
  String get next => 'ถัดไป';

  @override
  String get skip => 'ข้าม';

  @override
  String get selectImage => 'เลือกรูปภาพ';

  @override
  String get unsupportedImageFormat => 'รูปแบบรูปภาพที่ไม่รองรับ';

  @override
  String get invalidPrivateKeyOrSeedPhrase =>
      'คีย์ส่วนตัวหรือวลีกู้คืนไม่ถูกต้อง';

  @override
  String get pleaseReadAndAcceptTerms =>
      'โปรดอ่านและยอมรับข้อกำหนดและเงื่อนไขก่อน';

  @override
  String get pleaseImportPrivateKeyFirst => 'โปรดนำเข้าคีย์ส่วนตัวของคุณก่อน';

  @override
  String get publicKeyErrorMessage =>
      'คุณป้อนคีย์สาธารณะ โปรดป้อนคีย์ส่วนตัว ซึ่งเริ่มต้นด้วย nsec1';

  @override
  String wordNotValid(String word) {
    return 'คำ: $word ไม่ถูกต้อง โปรดตรวจสอบการสะกดคำ';
  }

  @override
  String get login => 'เข้าสู่ระบบ';

  @override
  String get yourPublicKeyIs => 'คีย์สาธารณะของคุณคือ:';

  @override
  String get enterSeedPhraseOrNsec => 'ป้อนวลีกู้คืนหรือ nsec1 ของคุณ';

  @override
  String get paste => 'วาง';

  @override
  String get add => 'เพิ่ม';

  @override
  String get iHaveReadAndAccept => 'ฉันได้อ่านและยอมรับ';

  @override
  String get termsAndConditions => 'ข้อกำหนดและเงื่อนไข';

  @override
  String get privacyPolicy => 'นโยบายความเป็นส่วนตัว';

  @override
  String get settingUpYourAccount => 'กำลังตั้งค่าบัญชีของคุณ';

  @override
  String get followingPeople => 'กำลังติดตามผู้คน';

  @override
  String get movingData => 'กำลังย้ายข้อมูล';

  @override
  String get cleaningUp => 'กำลังทำความสะอาด';

  @override
  String get uploadingProfilePicture => 'กำลังอัปโหลดรูปโปรไฟล์';

  @override
  String get recoveryPhrase => 'วลีกู้คืน';

  @override
  String get newSeedPhraseGenerated => 'สร้างวลีกู้คืนใหม่แล้ว';

  @override
  String get regenerate => 'สร้างใหม่';

  @override
  String get copiedSeedPhraseToClipboard => 'คัดลอกวลีกู้คืนไปยังคลิปบอร์ดแล้ว';

  @override
  String get copy => 'คัดลอก';

  @override
  String get hideWords => 'ซ่อนคำ';

  @override
  String get showWords => 'แสดงคำ';

  @override
  String get recoveryPhraseWarning =>
      'คุณต้องใช้วลีกู้คืนเพื่อเข้าสู่ระบบอีกครั้ง โปรดเก็บรักษาไว้อย่างปลอดภัย!';

  @override
  String get publishAccount => 'เผยแพร่บัญชี';

  @override
  String get starterPacks => 'แพ็คเกจเริ่มต้น';

  @override
  String get additionalStarterPacks => 'แพ็คเกจเริ่มต้นเพิ่มเติม';

  @override
  String continueWithAccounts(int count) {
    return 'ดำเนินการต่อด้วย $count บัญชี';
  }

  @override
  String get selectStarterPack => 'เลือกแพ็คเกจเริ่มต้น';

  @override
  String by(String name) {
    return 'โดย $name';
  }

  @override
  String get unselectAll => 'ยกเลิกการเลือกทั้งหมด';

  @override
  String get followAll => 'ติดตามทั้งหมด';

  @override
  String followAccounts(int count) {
    return 'ติดตาม $count บัญชี';
  }

  @override
  String get invitedYouToJoin => ' เชิญคุณเข้าร่วม';

  @override
  String get youWillFollowThesePeople => 'คุณจะติดตามคนเหล่านี้ทันที';

  @override
  String get noStarterPackFound => '👀 ไม่พบแพ็คเกจเริ่มต้น ';

  @override
  String get noWorriesYouCanStillJoin =>
      'ไม่ต้องกังวล คุณยังสามารถเข้าร่วม Camelus ได้!';

  @override
  String get joinCamelus => 'เข้าร่วม Camelus';

  @override
  String get signupWithoutStarterPack => 'ลงทะเบียนโดยไม่ใช้แพ็คเกจเริ่มต้น';

  @override
  String copiedToClipboard(String text) {
    return 'คัดลอกไปยังคลิปบอร์ดแล้ว: $text';
  }

  @override
  String get shareYourProfile => 'แบ่งปันโปรไฟล์ของคุณ';

  @override
  String get following => 'กำลังติดตาม';

  @override
  String get followers => 'ผู้ติดตาม';

  @override
  String get profile => 'โปรไฟล์';

  @override
  String get bookmarks => 'บุ๊คมาร์ก';

  @override
  String get notImplementedYet => 'ยังไม่ได้นำไปใช้';

  @override
  String get payments => 'การชำระเงิน';

  @override
  String get blocklist => 'รายการบล็อก';

  @override
  String get settings => 'การตั้งค่า';

  @override
  String get termsOfService => 'ข้อกำหนดการให้บริการ';

  @override
  String get languageSettings => 'การตั้งค่าภาษา';

  @override
  String get initialRoute => 'เส้นทางเริ่มต้น';

  @override
  String get moderation => 'การกลั่นกรอง';

  @override
  String get fileServers => 'เซิร์ฟเวอร์ไฟล์';

  @override
  String get logout => 'ออกจากระบบ';

  @override
  String get unsavedChanges => 'การเปลี่ยนแปลงที่ยังไม่ได้บันทึก';

  @override
  String get unsavedChangesMessage =>
      'คุณมีการเปลี่ยนแปลงที่ยังไม่ได้บันทึก คุณต้องการยกเลิกหรือไม่?';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get discard => 'ทิ้ง';

  @override
  String get saveChanges => 'บันทึกการเปลี่ยนแปลง';

  @override
  String get saving => 'กำลังบันทึก...';

  @override
  String get changesSavedSuccessfully => 'บันทึกการเปลี่ยนแปลงสำเร็จ';

  @override
  String get failedToSaveChanges => 'บันทึกการเปลี่ยนแปลงล้มเหลว';

  @override
  String get setupDefaultServers => 'ตั้งค่าเซิร์ฟเวอร์เริ่มต้น';

  @override
  String get defaultLabel => ' (ค่าเริ่มต้น)';

  @override
  String get restoreDefaults => 'คืนค่าเริ่มต้น';

  @override
  String get restoreDefaultsMessage =>
      'คุณแน่ใจหรือไม่ว่าต้องการคืนค่าเซิร์ฟเวอร์เริ่มต้น? นี่จะลบเซิร์ฟเวอร์ที่กำหนดเองทั้งหมด';

  @override
  String get restore => 'คืนค่า';

  @override
  String get enterBlossomUrl => 'ป้อน URL ของ Blossom';

  @override
  String errorUpdatingFilter(String error) {
    return 'เกิดข้อผิดพลาดในการอัปเดตตัวกรอง $error';
  }

  @override
  String get moderationSettings => 'การตั้งค่าการกลั่นกรอง';

  @override
  String get camelusContentFiltering => 'การกรองเนื้อหา Camelus';

  @override
  String get enableContentFilteringDescription =>
      'เปิดใช้งานการกรองเนื้อหาเพื่อซ่อนเนื้อหาที่อาจไม่เหมาะสม';

  @override
  String get enableContentFilter => 'เปิดใช้งานตัวกรองเนื้อหา';

  @override
  String get contentFilterNote =>
      'หมายเหตุ: ตัวกรองจะถูกนำไปใช้ในเครื่อง (บนอุปกรณ์) เมื่อผู้ใช้รายงานเนื้อหา nostr โดยตรงไปยัง camelus มันจะถูกเพิ่มลงในตัวกรอง';

  @override
  String get errorUploadingImage =>
      'เกิดข้อผิดพลาดในการอัปโหลดรูปภาพ มีการกำหนดค่าเซิร์ฟเวอร์อัปโหลดหรือไม่?';

  @override
  String get editProfile => 'แก้ไขโปรไฟล์';

  @override
  String get save => 'บันทึก';

  @override
  String get loadingProfile => 'กำลังโหลดโปรไฟล์...';

  @override
  String get uploading => 'กำลังอัปโหลด...';

  @override
  String get uploadingCapitalized => 'กำลังอัปโหลด';

  @override
  String get name => 'ชื่อ';

  @override
  String get bio => 'ชีวประวัติ';

  @override
  String get pronouns => 'สรรพนาม';

  @override
  String get website => 'เว็บไซต์';

  @override
  String get username => 'ชื่อผู้ใช้ (nip05)';

  @override
  String get lightningAddress => 'ที่อยู่ Lightning';

  @override
  String get editRelays => 'แก้ไขรีเลย์';

  @override
  String get error => 'ข้อผิดพลาด:';

  @override
  String get whatsOnYourMind => 'คุณกำลังคิดอะไรอยู่?';

  @override
  String get writePost => 'เขียนโพสต์';

  @override
  String replyTo(String name) {
    return 'ตอบกลับ $name';
  }

  @override
  String get addToStarterPack => 'เพิ่มไปยังแพ็คเกจเริ่มต้น';

  @override
  String get blockReport => 'บล็อก/รายงาน';

  @override
  String get blockedUsers => 'ผู้ใช้ที่ถูกบล็อก';

  @override
  String get notImplemented => 'ยังไม่ได้นำไปใช้';

  @override
  String get impersonation => 'แอบอ้าง';

  @override
  String get spam => 'สแปม';

  @override
  String get illegal => 'ผิดกฎหมาย';

  @override
  String get profanity => 'คำหยาบคาย';

  @override
  String get nudity => 'ภาพลามก';

  @override
  String get malware => 'มัลแวร์';

  @override
  String get other => 'อื่นๆ';

  @override
  String get reportSent => 'ส่งรายงานแล้ว';

  @override
  String get thankYouForReport => 'ขอบคุณสำหรับรายงานของคุณ';

  @override
  String get goBack => 'ย้อนกลับ';

  @override
  String get blockReportTitle => 'บล็อก/รายงาน';

  @override
  String get user => 'ผู้ใช้';

  @override
  String get loading => 'กำลังโหลด';

  @override
  String get unblock => 'ยกเลิกการบล็อก';

  @override
  String get block => 'บล็อก';

  @override
  String get whatIsWrongWithPost => 'โพสต์นี้มีอะไรผิดปกติ?';

  @override
  String get whatIsWrongWithUser => 'ผู้ใช้คนนี้มีอะไรผิดปกติ?';

  @override
  String get reportsAreSentToRelays =>
      'รายงานจะถูกส่งไปยังรีเลย์ที่คุณได้รับบันทึกจาก';

  @override
  String get additionallyReportToCamelus =>
      'นอกจากนี้ รายงานโดยตรงไปยัง camelus';

  @override
  String get reportPost => 'รายงานโพสต์';

  @override
  String get reportUser => 'รายงานผู้ใช้';

  @override
  String get relays => 'รีเลย์';

  @override
  String get eventsRead => 'เหตุการณ์ที่อ่าน';

  @override
  String get eventsWritten => 'เหตุการณ์ที่เขียน';

  @override
  String get connectionSource => 'แหล่งการเชื่อมต่อ';

  @override
  String get noDataAvailable => 'ไม่มีข้อมูล';

  @override
  String get notifications => 'การแจ้งเตือน';

  @override
  String get searchHelp => 'ความช่วยเหลือการค้นหา';

  @override
  String get searchHelpMessage => 'ป้อนคำหลักเพื่อค้นหาโพสต์';

  @override
  String get ok => 'ตกลง';

  @override
  String get thread => 'เธรด';

  @override
  String get workInProgress => 'กำลังดำเนินการ';

  @override
  String get update => 'อัปเดต';

  @override
  String get initialRouteSettings => 'การตั้งค่าเส้นทางเริ่มต้น';

  @override
  String get useSystemLanguage => 'ใช้ภาษาระบบ';

  @override
  String get edit => 'แก้ไข';

  @override
  String get postSettings => 'การตั้งค่าโพสต์';

  @override
  String get enableContentWarning => 'เปิดใช้งานคำเตือนเนื้อหา';

  @override
  String get warningType => 'ประเภทคำเตือน';

  @override
  String get customWarning => 'คำเตือนแบบกำหนดเอง';

  @override
  String get specifyContentWarning => 'ระบุคำเตือนเนื้อหา';

  @override
  String get enableClientTag => 'เปิดใช้งานแท็กไคลเอนต์';

  @override
  String get close => 'ปิด';

  @override
  String get sensitiveContent => 'เนื้อหาที่ละเอียดอ่อน';

  @override
  String get flashingLights => 'แสงกะพริบ';

  @override
  String get loudNoises => 'เสียงดัง';

  @override
  String get graphicContent => 'เนื้อหากราฟิก';

  @override
  String get discrimination => 'การเลือกปฏิบัติ';

  @override
  String get health => 'สุขภาพ';

  @override
  String get abuse => 'การล่วงละเมิด';

  @override
  String get routeHome => 'หน้าแรก';

  @override
  String get routePostsAndReplies => 'โพสต์และการตอบกลับ';

  @override
  String get routeSearch => 'ค้นหา';

  @override
  String get routeNotifications => 'การแจ้งเตือน';

  @override
  String get scrollToTop => 'เลื่อนไปด้านบน';

  @override
  String get home => 'หน้าแรก';

  @override
  String get search => 'ค้นหา';

  @override
  String get more => 'เพิ่มเติม';

  @override
  String get posts => 'โพสต์';

  @override
  String get postsAndReplies => 'โพสต์และการตอบกลับ';
}
