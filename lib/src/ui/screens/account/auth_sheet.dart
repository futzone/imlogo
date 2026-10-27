import 'package:dication/src/core/services/account_service.dart';
import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/ui/widgets/app_buttons.dart';
import 'package:dication/src/ui/widgets/app_scaffold.dart';
import 'package:dication/src/ui/widgets/app_ui.dart';
import 'package:flutter/material.dart';

enum _AuthMode { signIn, signUp }

/// Kirish va ro'yxatdan o'tish oynasi (Google yoki email + parol).
class AuthSheet extends StatefulWidget {
  const AuthSheet({super.key});

  /// Muvaffaqiyatli kirilsa `true` qaytaradi.
  static Future<bool> show(BuildContext context) async =>
      await AppSheet.show<bool>(context, const AuthSheet()) ?? false;

  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<AuthSheet> {
  static const _benefits = [
    'Natijalaringiz istalgan qurilmada saqlanadi',
    'Hamjamiyat reytingida boşqalar bilan bellaşasiz',
    'Profilda ketma-ket kunlar va tezlik ösişini körasiz',
  ];

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  _AuthMode _mode = _AuthMode.signIn;
  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await action();
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = accountErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submit() {
    if (_busy) return;
    final email = _email.text.trim();
    if (_mode == _AuthMode.signUp && _name.text.trim().isEmpty) {
      setState(() => _error = 'Ismingizni kiriting — u reytingda körinadi');
      return;
    }
    if (email.isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Email va parolni kiriting');
      return;
    }
    _run(() => _mode == _AuthMode.signIn
        ? AccountService.signIn(email, _password.text)
        : AccountService.signUp(_name.text, email, _password.text));
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Avval email manzilingizni kiriting');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AccountService.requestPasswordReset(email);
      if (mounted) setState(() => _notice = 'Parolni tiklaş havolasi $email manziliga yuborildi');
    } catch (error) {
      if (mounted) setState(() => _error = accountErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final signUp = _mode == _AuthMode.signUp;
    return AppSheet(
      title: signUp ? 'Röyxatdan ötiş' : 'Hisobga kiriş',
      subtitle: 'Majburiy emas — ilovadan mehmon sifatida ham töliq foydalaniş mumkin.',
      children: [
        for (final benefit in _benefits)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check, size: 18, color: AppColors.success),
                const SizedBox(width: 10),
                Expanded(child: Text(benefit, style: AppText.body(14))),
              ],
            ),
          ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Google orqali kiriş',
          icon: Icons.g_mobiledata,
          variant: AppButtonVariant.outline,
          expand: true,
          onPressed: _busy ? null : () => _run(AccountService.signInWithGoogle),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.line)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('yoki email orqali', style: AppText.body(13, color: AppColors.muted)),
            ),
            const Expanded(child: Divider(color: AppColors.line)),
          ],
        ),
        const SizedBox(height: 16),
        Segmented<_AuthMode>(
          options: const {_AuthMode.signIn: 'Kiriş', _AuthMode.signUp: 'Röyxatdan ötiş'},
          value: _mode,
          expand: true,
          onChanged: (mode) => setState(() {
            _mode = mode;
            _error = null;
            _notice = null;
          }),
        ),
        const SizedBox(height: 16),
        AutofillGroup(
          child: Column(
            children: [
              if (signUp) ...[
                AppTextField(
                  label: 'Ism',
                  controller: _name,
                  hint: 'Reytingda körinadi',
                  maxLength: 60,
                  autofillHints: const [AutofillHints.name],
                ),
                const SizedBox(height: 4),
              ],
              AppTextField(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Parol',
                controller: _password,
                obscure: true,
                hint: signUp ? 'Kamida 8 ta belgi' : null,
                autofillHints: [signUp ? AutofillHints.newPassword : AutofillHints.password],
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        if (!signUp)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy ? null : _resetPassword,
              child: Text('Parolni unutdingizmi?', style: AppText.body(13, color: AppColors.primary)),
            ),
          ),
        if (_error != null) _Message(text: _error!, color: AppColors.error),
        if (_notice != null) _Message(text: _notice!, color: AppColors.success),
        const SizedBox(height: 12),
        AppButton(
          label: _busy ? 'Kuting…' : (signUp ? 'Hisob yaratiş' : 'Kiriş'),
          expand: true,
          onPressed: _busy ? null : _submit,
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final Color color;

  const _Message({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Text(text, style: AppText.body(14, color: color)),
    );
  }
}
