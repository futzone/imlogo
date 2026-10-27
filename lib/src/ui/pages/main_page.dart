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
import 'package:dication/src/ui/screens/community/community_view.dart';
import 'package:dication/src/ui/screens/home/home_view.dart';
import 'package:dication/src/ui/screens/main_screens/app_header.dart';
import 'package:dication/src/ui/screens/main_screens/dictation_list.dart';
import 'package:dication/src/ui/screens/profile/profile_view.dart';
import 'package:dication/src/ui/screens/translator/translator_view.dart';
import 'package:dication/src/ui/screens/typing/typing_view.dart';
import 'package:dication/src/ui/shell/app_tab.dart';
import 'package:dication/src/ui/widgets/app_background.dart';
import 'package:dication/src/ui/widgets/app_scaffold.dart';
import 'package:dication/src/ui/widgets/app_ui.dart';
import 'package:dication/src/ui/widgets/hovered_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Ilova qolipi. Keng ekranda (veb, kompyuter, planshet) — veb-saytdagi kabi
/// chapda doimiy yon panel; telefonda — pastki menyu (Asosiy, Tez yozish,
/// Diktant, Translator, Profil).
class MainPage extends ConsumerStatefulWidget {
  final AppTab initialTab;

  const MainPage({super.key, this.initialTab = AppTab.home});

  /// Shu kenglikdan boshlab yon panel ko'rsatiladi.
  static const double sidebarBreakpoint = 1000;

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  late AppTab _tab = widget.initialTab;

  bool get _wide => MediaQuery.of(context).size.width >= MainPage.sidebarBreakpoint;

  void _open(AppTab tab) {
    // Telefonda hamjamiyat pastki menyuda yo'q — alohida sahifa sifatida ochiladi.
    if (!_wide && !AppTab.mobile.contains(tab)) {
      AppRouter.go(context, const AppPageScaffold(title: 'Hamjamiyat', body: CommunityView()));
      return;
    }
    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final wide = _wide;
    var tab = _tab;
    if (!wide && !AppTab.mobile.contains(tab)) tab = AppTab.home;

    final content = IndexedStack(
      index: AppTab.values.indexOf(tab),
      children: [
        for (final t in AppTab.values)
          switch (t) {
            AppTab.home => HomeView(onOpen: _open),
            AppTab.typing => TypingView(active: tab == AppTab.typing),
            AppTab.dictation => const DictationList(),
            AppTab.translator => const TranslatorView(),
            AppTab.community => const CommunityView(),
            AppTab.profile => const ProfileView(),
          },
      ],
    );

    if (wide) {
      return Scaffold(
        body: AppBackground(
          child: Row(
            children: [
              AppSidebar(tab: tab, onOpen: _open),
              Expanded(child: SafeArea(left: false, child: content)),
            ],
          ),
        ),
      );
    }

    // Klaviatura ochiq bo'lganda pastki menyu joy egallamasin.
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: _MobileHeader(onOpen: _open),
              ),
              Expanded(child: content),
              if (!keyboardOpen)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                  child: MobileNavBar(tab: tab, onOpen: _open),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Telefondagi sarlavha: logotip, ketma-ket kunlar va hisob.
class _MobileHeader extends ConsumerWidget {
  final OpenTab onOpen;

  const _MobileHeader({required this.onOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(authProvider);
    final history = ref.watch(userHistoryProvider).valueOrNull;
    final streak = history == null ? 0 : computeStreak(history).current;

    return GlassBar(
      padding: const EdgeInsets.fromLTRB(18, 6, 6, 6),
      child: Row(
        children: [
          const Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(fit: BoxFit.scaleDown, child: AppLogo(size: 22)),
            ),
          ),
          if (streak > 0) _StreakChip(streak: streak),
          const SizedBox(width: 4),
          if (account == null)
            SmallButton(label: 'Kiriş', icon: Icons.login, onPressed: () => AuthSheet.show(context))
          else
            Tooltip(
              message: 'Profil',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => onOpen(AppTab.profile),
                child: Padding(padding: const EdgeInsets.all(4), child: UserAvatar.of(account, size: 34)),
              ),
            ),
        ],
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  final int streak;

  const _StreakChip({required this.streak});

  @override
  Widget build(BuildContext context) {
    const flame = Color(0xFFF97316);
    return Tooltip(
      message: '$streak kun ketma-ket',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department, size: 18, color: flame),
            Text('$streak', style: AppText.mono(13, color: flame, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Telefondagi pastki menyu.
class MobileNavBar extends StatelessWidget {
  final AppTab tab;
  final OpenTab onOpen;

  const MobileNavBar({super.key, required this.tab, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return GlassBar(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (final t in AppTab.mobile)
            Expanded(
              child: Semantics(
                button: true,
                selected: t == tab,
                child: HoveredWidget(
                  onPressed: () => onOpen(t),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  builder: (hovered) {
                    final selected = t == tab;
                    final color = selected ? AppColors.primary : (hovered ? AppColors.foreground : AppColors.muted);
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(selected ? t.activeIcon : t.icon, size: 22, color: color),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              t.label,
                              maxLines: 1,
                              style: AppText.body(11, weight: selected ? FontWeight.w600 : FontWeight.w500, color: color, height: 1.2),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Keng ekrandagi yon panel (veb-saytdagi `AppSidebar` bilan bir xil tuzilish).
class AppSidebar extends ConsumerStatefulWidget {
  final AppTab tab;
  final OpenTab onOpen;

  const AppSidebar({super.key, required this.tab, required this.onOpen});

  @override
  ConsumerState<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends ConsumerState<AppSidebar> {
  bool _aboutOpen = false;

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(authProvider);
    final history = ref.watch(userHistoryProvider).valueOrNull;
    final streak = history == null ? 0 : computeStreak(history).current;

    return Container(
      width: 272,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        border: const Border(right: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Align(alignment: Alignment.centerLeft, child: AppLogo(size: 24)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final t in AppTab.sidebar)
                    _SidebarLink(
                      icon: t == widget.tab ? t.activeIcon : t.icon,
                      label: t.label,
                      active: t == widget.tab,
                      onTap: () => widget.onOpen(t),
                    ),
                  _SidebarLink(
                    icon: Icons.info_outline,
                    label: 'Loyiha haqida',
                    trailing: AnimatedRotation(
                      turns: _aboutOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.expand_more, size: 18, color: AppColors.muted),
                    ),
                    onTap: () => setState(() => _aboutOpen = !_aboutOpen),
                  ),
                  if (_aboutOpen)
                    Container(
                      margin: const EdgeInsets.only(left: 22, bottom: 4),
                      padding: const EdgeInsets.only(left: 10),
                      decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppColors.line))),
                      child: Column(
                        children: [
                          _SidebarLink(
                            icon: Icons.auto_awesome_outlined,
                            label: 'Loyiha haqida',
                            small: true,
                            onTap: () => AppInfoScreen.show(context),
                          ),
                          _SidebarLink(
                            icon: Icons.description_outlined,
                            label: 'Loyiha docs',
                            small: true,
                            onTap: () => launchUrlString(AppConstants.docs),
                          ),
                          _SidebarLink(
                            icon: Icons.smartphone_outlined,
                            label: 'Ilovalarimiz',
                            small: true,
                            onTap: () => AboutAppScreen.show(context),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Container(height: 1, color: AppColors.line),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SidebarLink(
                    icon: Icons.history,
                    label: 'Natijalarim',
                    onTap: () => AppRouter.go(context, const ResultsPage()),
                  ),
                  _SidebarLink(
                    icon: Icons.chat_bubble_outline,
                    label: 'Murojaat qoldiriş',
                    onTap: () => FeedbackSheet.show(context),
                  ),
                  const SizedBox(height: 10),
                  account == null
                      ? _SignInCard(onSignIn: () => AuthSheet.show(context))
                      : _AccountTile(
                          account: account,
                          streak: streak,
                          active: widget.tab == AppTab.profile,
                          onOpen: () => widget.onOpen(AppTab.profile),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool small;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SidebarLink({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.small = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: HoveredWidget(
        onPressed: onTap,
        borderRadius: BorderRadius.circular(12),
        builder: (hovered) {
          final color = active || hovered ? AppColors.primary : AppColors.foreground;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints: BoxConstraints(minHeight: small ? 38 : 44),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : hovered
                      ? AppColors.primary.withValues(alpha: 0.05)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, size: small ? 16 : 19, color: color),
                SizedBox(width: small ? 10 : 12),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(small ? 14 : 15, weight: FontWeight.w500, color: color, height: 1.2),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SignInCard extends StatelessWidget {
  final VoidCallback onSignIn;

  const _SignInCard({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Kirsangiz, natijalaringiz saqlanadi va reytingda qatnaşasiz.',
            style: AppText.body(12, color: AppColors.muted, height: 1.35),
          ),
          const SizedBox(height: 10),
          SmallButton(label: 'Kiriş', icon: Icons.login, onPressed: onSignIn),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final Account account;
  final int streak;
  final bool active;
  final VoidCallback onOpen;

  const _AccountTile({required this.account, required this.streak, required this.active, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: active ? AppColors.primary.withValues(alpha: 0.5) : AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  UserAvatar.of(account, size: 38),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(account.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(14, weight: FontWeight.w600, height: 1.2)),
                        Text(account.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(12, color: AppColors.muted, height: 1.2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (streak > 0) _StreakChip(streak: streak),
          IconButton(
            tooltip: 'Hisobdan çiqiş',
            icon: const Icon(Icons.logout, size: 18, color: AppColors.muted),
            onPressed: AccountService.signOut,
          ),
        ],
      ),
    );
  }
}
