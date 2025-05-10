import 'package:url_launcher/url_launcher_string.dart';

class AppConstants {
  static const String androidApp = "";
  static const String iOSApp = "";
  static const String windowsApp = "";
  static const String telegramChannel = "";
  static const String website = "";

  static Future<void> launchAppFor(platform) async {
    await launchUrlString("https://www.imlogo.uz/");
  }

  static const String aboutText =
      "Loyiha, Alisher Navoiy nomidagi Toshkent davlat o'zbek tili va adabiyoti universiteti, «Kompyuter lingvistikasi» yo'nalishi bitiruvchi kurs talabasi Abdumalikova Gulshoda tomonidan bitiruv malakaviy topshiriq ishi sifatida tayyorlandi.";

}
