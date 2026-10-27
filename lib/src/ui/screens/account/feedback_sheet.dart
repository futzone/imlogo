import 'package:dication/src/core/constants/app_constants.dart';
import 'package:dication/src/core/services/account_service.dart';
import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/providers/account_provider.dart';
import 'package:dication/src/ui/screens/account/auth_sheet.dart';
import 'package:dication/src/ui/widgets/app_buttons.dart';
import 'package:dication/src/ui/widgets/app_scaffold.dart';
import 'package:dication/src/ui/widgets/app_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Murojaat (xatolik, taklif, savol) yuborish oynasi. Murojaatni faqat
/// kirgan foydalanuvchi yuboradi — javob uning emailiga yoziladi.
class FeedbackSheet extends ConsumerStatefulWidget {
  final FeedbackKind initialKind;

  const FeedbackSheet({super.key, this.initialKind = FeedbackKind.xatolik});

  static Future<void> show(BuildContext context, {FeedbackKind kind = FeedbackKind.xatolik}) =>
      AppSheet.show(context, FeedbackSheet(initialKind: kind));

  @override
  ConsumerState<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends ConsumerState<FeedbackSheet> {
  final _message = TextEditingController();
  late FeedbackKind _kind = widget.initialKind;
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send(Account account) async {
    if (_message.text.trim().length < 5) {
      setState(() => _error = 'Murojaatni batafsilroq yozing');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
      await AccountService.sendFeedback(account.id, _kind, _message.text, 'flutter:$platform');
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) setState(() => _error = accountErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(authProvider);

    if (account == null) {
      return AppSheet(
        title: 'Murojaat qoldiriş',
        subtitle: 'Murojaat qoldiriş uçun hisobingizga kiring — javobni email manzilingizga yuboramiz.',
        children: [
          AppButton(label: 'Kiriş', expand: true, onPressed: () => AuthSheet.show(context)),
          const SizedBox(height: 12),
          AppButton(
            label: 'Telegram orqali yoziş',
            icon: Icons.telegram,
            variant: AppButtonVariant.outline,
            expand: true,
            onPressed: () => launchUrlString(AppConstants.telegramBot),
          ),
        ],
      );
    }

    if (_sent) {
      return const AppSheet(
        title: 'Rahmat!',
        subtitle: 'Murojaatingiz yuborildi. Kerak bölsa, email manzilingizga javob yozamiz.',
        children: [EmptyState(icon: Icons.mark_email_read_outlined, text: 'Murojaat qabul qilindi')],
      );
    }

    return AppSheet(
      title: 'Murojaat qoldiriş',
      subtitle: 'Kerak bölsa, ${account.email} manziliga javob yozamiz.',
      children: [
        Segmented<FeedbackKind>(
          options: {for (final kind in FeedbackKind.values) kind: kind.label},
          value: _kind,
          expand: true,
          onChanged: (kind) => setState(() => _kind = kind),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Xabar',
          controller: _message,
          maxLines: 6,
          maxLength: 2000,
          hint: _kind == FeedbackKind.xatolik
              ? 'Qaysi sahifada, nima qilganda xatolik çiqdi?'
              : 'Fikringizni yozing…',
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_error!, style: AppText.body(14, color: AppColors.error)),
          ),
        const SizedBox(height: 12),
        AppButton(
          label: _busy ? 'Yuborilmoqda…' : 'Yuboriş',
          icon: Icons.send_outlined,
          expand: true,
          onPressed: _busy ? null : () => _send(account),
        ),
      ],
    );
  }
}
