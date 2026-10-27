import 'package:url_launcher/url_launcher_string.dart';

class AppConstants {
  static const String androidApp = "";
  static const String iOSApp = "";
  static const String windowsApp = "";
  static const String telegramChannel = "https://t.me/imlogo";

  /// Xatolik haqida xabar berish va yordam uchun Telegram bot.
  static const String telegramBot = "https://t.me/Qahor0v_bot";
  static const String website = "https://imlogo.uz";
  static const String docs = "https://imlogo.uz/qollanma";

  static Future<void> launchAppFor(platform) async {
    await launchUrlString("https://www.imlogo.uz/");
  }

  static const String aboutText =
      "Loyiha, Alişer Navoiy nomidagi Toşkent davlat özbek tili va adabiyoti universiteti, «Kompyuter lingvistikasi» yönalişi bitiruvçi kurs talabasi Abdumalikova Gulşoda tomonidan bitiruv malakaviy topşiriq işi sifatida tayyorlandi.";

}
