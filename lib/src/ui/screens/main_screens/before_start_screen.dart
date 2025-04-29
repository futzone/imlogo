import 'package:animate_gradient/animate_gradient.dart';
import 'package:dication/src/core/config/app_device.dart';
import 'package:dication/src/core/config/app_fonts.dart';
import 'package:dication/src/core/config/app_router.dart';
import 'package:dication/src/ui/pages/dictation_page.dart';
import 'package:dication/src/ui/widgets/app_buttons.dart';
import 'package:dication/src/ui/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class BeforeStartScreen extends StatelessWidget {
  const BeforeStartScreen({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        return BeforeStartScreen();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.isMobile ? null : 600,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(left: 16, right: 16, top: 8),
        child: Column(
          spacing: 8,
          children: [
            Text(
              "Diktantni boshlash",
              style: TextStyle(
                fontSize: context.isMobile ? 18 : 28,
                fontFamily: extraBoldFamily,
              ),
            ),
            Text(
              "Boshlashdan avval quyidagi qoidalar bilan tanishib chiqing 👇",
              style: TextStyle(
                fontSize: 16,
                fontFamily: mediumFamily,
              ),
            ),
            Text(
              _data,
              style: TextStyle(fontFamily: regularFamily),
            ),
            SizedBox(height: 16),
            SimpleButton(
              onPressed: (){
                AppRouter.go(context, DictationPage());
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(48),
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.red],
                  ),
                ),
                padding: EdgeInsets.only(
                  left: 32,
                  right: 32,
                  top: 12,
                  bottom: 12,
                ),
                child: Text(
                  "Diktantni boshlash".toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: mediumFamily,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () => AppRouter.close(context),
                child: Text(
                  "Yopish",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: regularFamily,
                  ),
                ),
              ),
            ),
            SizedBox(height: 0),
          ],
        ),
      ),
    );
  }
}

const _data = """1. ✅ Diktant boshlangandan so‘ng sahifani tark etishga ruxsat yo‘q. Agar chiqib ketsangiz, diktant bekor qilinadi.
2. ⏰ Diktant uchun belgilangan vaqt mavjud. Vaqt tugashi bilan audio avtomatik to‘xtaydi va topshirish imkoniyati yopiladi.
3. 🎧 Diktant faqat bir marta eshitiladi. Qayta eshitish imkoniyati berilmaydi.
4. 🖊 Matnni tinglab darhol yozishingiz kerak. Xotiradan yozishga harakat qiling.
5. 🛑 Yozish davomida internet uzilib qolsa, diktant natijalari saqlanmaydi.
6. 📵 Telefon yoki kompyuterning ovozini o‘chirib qo‘ymang. Tinglash uchun qurilmaning ovozi yetarli darajada baland bo‘lishi kerak.
7. 🔒 Firibgarlik (masalan, boshqa sahifani ochish, boshqa yordam so‘rash) aniqlansa, diktant avtomatik tarzda tugatiladi.
8. 📝 Diktant yakunlangach, natijani ko‘rish va xatolarni tahlil qilish imkoniyati mavjud.""";
