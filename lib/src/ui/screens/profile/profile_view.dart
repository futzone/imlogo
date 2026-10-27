import 'package:dication/main.dart';
import 'package:dication/src/core/config/app_router.dart';
import 'package:dication/src/core/constants/app_constants.dart';
import 'package:dication/src/core/services/account_service.dart';
import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/providers/account_provider.dart';
import 'package:dication/src/ui/pages/results_page.dart';
import 'package:dication/src/ui/screens/account/auth_sheet.dart';
import 'package:dication/src/ui/screens/account/feedback_sheet.dart';
import 'package:dication/src/ui/screens/additional_screens/about_app_screen.dart';
import 'package:dication/src/ui/screens/additional_screens/app_info_screen.dart';
import 'package:dication/src/ui/widgets/app_badge.dart';
import 'package:dication/src/ui/widgets/app_buttons.dart';
import 'package:dication/src/ui/widgets/app_card.dart';
import 'package:dication/src/ui/widgets/app_scaffold.dart';
import 'package:dication/src/ui/widgets/app_ui.dart';
import 'package:dication/src/ui/widgets/stat_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

String _formatDay(DateTime date) {
  final d = date.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.year}.${two(d.month)}.${two(d.day)}';
}

/// "Profil": hisob ma'lumotlari, tahrirlash, natijalar tarixi, loyiha
/// haqida, murojaat va yordam.
class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(authProvider);
    final history = ref.watch(userHistoryProvider).valueOrNull;

    return SectionScroll(
      maxWidth: 760,
      onRefresh: () async => invalidateHistory(ref),
      children: [
        account == null ? const _GuestCard() : _AccountCard(account: account, history: history),
        const SizedBox(height: 16),
        if (history != null) _Stats(history: history),
        if (account != null) ...[
          const SizedBox(height: 16),
          _EditCard(account: account),
        ],
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              _MenuItem(
                icon: Icons.history,
                label: 'Natijalarim',
                hint: 'Diktant va tez yoziş tarixi',
                onTap: () => AppRouter.go(context, const ResultsPage()),
              ),
              _MenuItem(
                icon: Icons.info_outline,
                label: 'Loyiha haqida',
                onTap: () => AppInfoScreen.show(context),
              ),
              _MenuItem(
                icon: Icons.app_shortcut_outlined,
                label: 'Ilovalarimiz',
                hint: 'Android, iOS, Windows',
                onTap: () => AboutAppScreen.show(context),
              ),
              _MenuItem(
                icon: Icons.bug_report_outlined,
                label: 'Xatolik haqida xabar beriş',
                onTap: () => FeedbackSheet.show(context),
              ),
              _MenuItem(
                icon: Icons.support_agent,
                label: 'Yordam',
                hint: 'Telegram orqali savol bering',
                onTap: () => _showSupport(context),
              ),
              _MenuItem(
                icon: Icons.public,
                label: 'Saytga ötiş',
                hint: 'imlogo.uz',
                external: true,
                onTap: () => launchUrlString(AppConstants.website),
              ),
            ],
          ),
        ),
        if (account != null) ...[
          const SizedBox(height: 16),
          Center(
            child: AppButton(
              label: 'Hisobdan çiqiş',
              icon: Icons.logout,
              variant: AppButtonVariant.danger,
              onPressed: () => _confirmSignOut(context),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Center(child: Text('$appName $appVersion', style: AppText.label())),
      ],
    );
  }

  void _showSupport(BuildContext context) {
    AppSheet.show(
      context,
      AppSheet(
        title: 'Yordam',
        subtitle: 'Savol, taklif yoki muammo bölsa, bizga yozing — tezda javob beramiz.',
        children: [
          AppButton(
            label: 'Telegram bot orqali yoziş',
            icon: Icons.telegram,
            expand: true,
            onPressed: () => launchUrlString(AppConstants.telegramBot),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Telegram kanal — @imlogo',
            icon: Icons.campaign_outlined,
            variant: AppButtonVariant.outline,
            expand: true,
            onPressed: () => launchUrlString(AppConstants.telegramChannel),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Qöllanma',
            icon: Icons.menu_book_outlined,
            variant: AppButtonVariant.outline,
            expand: true,
            onPressed: () => launchUrlString(AppConstants.docs),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hisobdan çiqasizmi?', style: AppText.heading(20)),
        content: Text(
          'Natijalaringiz hisobingizda saqlanib qoladi. Qayta kirsangiz, ular yana körinadi.',
          style: AppText.body(14, color: AppColors.muted),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Bekor qiliş')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Çiqiş', style: AppText.body(14, weight: FontWeight.w600, color: AppColors.error)),
          ),
        ],
      ),
    );
    if (yes == true) AccountService.signOut();
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      corners: true,
      child: Column(
        children: [
          const IconNode(icon: Icons.person_outline, size: 56),
          const SizedBox(height: 12),
          Text('Mehmon', style: AppText.heading(22)),
          const SizedBox(height: 6),
          Text(
            'Hisobingizga kiring: natijalaringiz istalgan qurilmada saqlanadi, hamjamiyat reytingida qatnaşasiz.',
            textAlign: TextAlign.center,
            style: AppText.body(14, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          AppButton(label: 'Kiriş yoki röyxatdan ötiş', icon: Icons.login, onPressed: () => AuthSheet.show(context)),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Account account;
  final UserHistory? history;

  const _AccountCard({required this.account, required this.history});

  @override
  Widget build(BuildContext context) {
    final streak = history == null ? null : computeStreak(history!);
    return AppCard(
      corners: true,
      child: Row(
        children: [
          UserAvatar.of(account, size: 64),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.name, style: AppText.heading(22), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(account.email,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(14, color: AppColors.muted)),
                if (account.createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text('A’zo bölgan: ${_formatDay(account.createdAt!)}', style: AppText.mono(11, color: AppColors.muted)),
                ],
              ],
            ),
          ),
          if (streak != null && streak.current > 0)
            Tooltip(
              message: '${streak.current} kun ketma-ket',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department, color: Color(0xFFF97316)),
                  Text('${streak.current}', style: AppText.mono(18, color: const Color(0xFFF97316))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  final UserHistory history;

  const _Stats({required this.history});

  @override
  Widget build(BuildContext context) {
    final typing = history.typing;
    final works = history.works;
    final bestWpm = typing.isEmpty ? 0.0 : typing.map((r) => r.wpm).reduce((a, b) => a > b ? a : b);
    final avgBaho = works.isEmpty ? null : works.map((w) => w.baho).reduce((a, b) => a + b) / works.length;
    final streak = computeStreak(history);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        StatTile(label: 'Eng yaxşi (WPM)', value: '${bestWpm.round()}', valueColor: AppColors.primary, width: 140),
        StatTile(label: 'Maşqlar', value: '${typing.length} ta', width: 140),
        StatTile(label: 'Diktantlar', value: '${works.length} ta', width: 140),
        StatTile(label: 'Örtaça baho', value: avgBaho == null ? '—' : avgBaho.toStringAsFixed(1), width: 140),
        StatTile(label: 'Eng uzun streak', value: '${streak.best} kun', width: 140),
      ],
    );
  }
}

/// Ismni o'zgartirish va parol (almashtirish yoki emailga tiklash havolasi).
class _EditCard extends StatefulWidget {
  final Account account;

  const _EditCard({required this.account});

  @override
  State<_EditCard> createState() => _EditCardState();
}

class _EditCardState extends State<_EditCard> {
  late final _name = TextEditingController(text: widget.account.name);
  final _oldPassword = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _name.dispose();
    _oldPassword.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await action();
      if (mounted) setState(() => _notice = success);
    } catch (error) {
      if (mounted) setState(() => _error = accountErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(label: 'Profilni tahrirlaş'),
          const SizedBox(height: 12),
          AppTextField(label: 'Ism (reytingda körinadi)', controller: _name, maxLength: 60),
          Align(
            alignment: Alignment.centerRight,
            child: SmallButton(
              label: 'Saqlaş',
              onPressed: _busy || _name.text.trim().isEmpty
                  ? null
                  : () => _run(() => AccountService.updateName(account.id, _name.text), 'Ism saqlandi'),
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.line),
          const SizedBox(height: 12),
          AppTextField(label: 'Joriy parol', controller: _oldPassword, obscure: true),
          const SizedBox(height: 12),
          AppTextField(label: 'Yangi parol', controller: _password, obscure: true, hint: 'Kamida 8 ta belgi'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              SmallButton(
                label: 'Parolni bilmayman — emailga havola',
                outline: true,
                onPressed: _busy
                    ? null
                    : () => _run(
                          () => AccountService.requestPasswordReset(account.email),
                          'Parolni tiklaş havolasi ${account.email} manziliga yuborildi',
                        ),
              ),
              SmallButton(
                label: 'Parolni almaştiriş',
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                          await AccountService.changePassword(account, _oldPassword.text, _password.text);
                          _oldPassword.clear();
                          _password.clear();
                        }, 'Parol almaştirildi'),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: AppText.body(14, color: AppColors.error)),
          ],
          if (_notice != null) ...[
            const SizedBox(height: 10),
            Text(_notice!, style: AppText.body(14, color: AppColors.success)),
          ],
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback onTap;
  final bool external;

  const _MenuItem({required this.icon, required this.label, this.hint, required this.onTap, this.external = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.body(15, weight: FontWeight.w500, height: 1.3)),
                  if (hint != null) Text(hint!, style: AppText.body(12, color: AppColors.muted, height: 1.3)),
                ],
              ),
            ),
            Icon(external ? Icons.open_in_new : Icons.chevron_right, size: 20, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
