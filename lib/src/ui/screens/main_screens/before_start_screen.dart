import 'package:dication/src/core/config/app_router.dart';
import 'package:dication/src/core/models/text_model.dart';
import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/ui/pages/dictation_page.dart';
import 'package:dication/src/ui/widgets/app_buttons.dart';
import 'package:dication/src/ui/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';

class BeforeStartScreen extends StatelessWidget {
  final TextModel model;

  const BeforeStartScreen({super.key, required this.model});

  static void show(BuildContext context, TextModel model) {
    AppSheet.show(context, BeforeStartScreen(model: model));
  }

  void _start(BuildContext context) {
    if (model.url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Audio tayyorlanish jarayonida. Iltimos, hozircha boshqa diktantni sinab ko'ring!",
          ),
        ),
      );
      return;
    }
    AppRouter.go(context, DictationPage(model: model));
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: "Diktantni boshlash",
      subtitle: "Boshlashdan avval quyidagi qoidalar bilan tanishib chiqing 👇",
      children: [
        for (var i = 0; i < _rules.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Text(
                    (i + 1).toString().padLeft(2, '0'),
                    style: AppText.mono(11, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(_rules[i], style: AppText.body(14)),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Center(
          child: AppButton(
            label: "Diktantni boshlash",
            trailingIcon: Icons.arrow_forward,
            onPressed: () => _start(context),
          ),
        ),
      ],
    );
  }
}

const _rules = [
  "✅ Diktant boshlangandan so‘ng sahifani tark etishga ruxsat yo‘q. Agar chiqib ketsangiz, diktant bekor qilinadi.",
  "⏰ Diktant uchun belgilangan vaqt mavjud. Vaqt tugashi bilan audio avtomatik to‘xtaydi va topshirish imkoniyati yopiladi.",
  "🎧 Diktant faqat bir marta eshitiladi. Qayta eshitish imkoniyati berilmaydi.",
  "🖊 Matnni tinglab darhol yozishingiz kerak. Xotiradan yozishga harakat qiling.",
  "🛑 Yozish davomida internet uzilib qolsa, diktant natijalari saqlanmaydi.",
  "📵 Telefon yoki kompyuterning ovozini o‘chirib qo‘ymang. Tinglash uchun qurilmaning ovozi yetarli darajada baland bo‘lishi kerak.",
  "🔒 Firibgarlik (masalan, boshqa sahifani ochish, boshqa yordam so‘rash) aniqlansa, diktant avtomatik tarzda tugatiladi.",
  "📝 Diktant yakunlangach, natijani ko‘rish va xatolarni tahlil qilish imkoniyati mavjud.",
];
