import 'package:dication/src/core/services/account_service.dart';
import 'package:dication/src/core/services/profile_service.dart';
import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/core/utils/get_rate_color.dart';
import 'package:dication/src/providers/account_provider.dart';
import 'package:dication/src/ui/widgets/app_card.dart';
import 'package:dication/src/ui/widgets/app_scaffold.dart';
import 'package:dication/src/ui/widgets/app_ui.dart';
import 'package:dication/src/ui/widgets/stat_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileProvider =
    FutureProvider.autoDispose.family<ProfileDetails?, String>((ref, userId) => ProfileService.fetchProfile(userId));

String _formatDay(DateTime? date) {
  if (date == null) return '';
  final d = date.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.year}.${two(d.month)}.${two(d.day)}';
}

/// Boshqa foydalanuvchining ochiq profili: rasm, ism, faollik va natijalar
/// (veb-saytdagi `/app/foydalanuvchi/[id]` bilan bir xil).
class PublicProfilePage extends ConsumerWidget {
  final String userId;

  const PublicProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(profileProvider(userId));
    final myId = ref.watch(authProvider.select((a) => a?.id));

    return AppPageScaffold(
      title: 'Profil',
      maxWidth: 760,
      body: details.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => EmptyState(
          icon: Icons.person_off_outlined,
          color: AppColors.error,
          text: 'Profilni yuklab bölmadi. Birozdan söng qayta urinib köring.',
          action: SmallButton(label: 'Qayta uriniş', onPressed: () => ref.invalidate(profileProvider(userId))),
        ),
        data: (details) => details == null
            ? const EmptyState(icon: Icons.person_off_outlined, text: 'Bunday foydalanuvçi topilmadi.')
            : SectionScroll(
                maxWidth: 760,
                onRefresh: () async => ref.invalidate(profileProvider(userId)),
                children: [
                  _Header(profile: details.profile, isMe: details.profile.id == myId),
                  const SizedBox(height: 20),
                  _TypingSection(details: details),
                  const SizedBox(height: 20),
                  _DictationSection(details: details),
                ],
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final PublicProfile profile;
  final bool isMe;

  const _Header({required this.profile, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final lastSeen = formatLastSeen(profile.lastSeen);
    final online = lastSeen == 'Hozir onlayn';
    return AppCard(
      corners: true,
      child: Column(
        children: [
          Stack(
            children: [
              UserAvatar(name: profile.name, imageUrl: profile.avatarUrl, size: 96),
              if (online)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: Text(profile.name, textAlign: TextAlign.center, style: AppText.heading(24))),
              if (isMe) ...[
                const SizedBox(width: 8),
                Text('SIZ', style: AppText.label(size: 10, color: AppColors.primary)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            online ? 'Hozir onlayn' : 'Oxirgi marta onlayn: $lastSeen',
            style: AppText.body(14, color: online ? AppColors.success : AppColors.muted),
          ),
          if (profile.createdAt != null) ...[
            const SizedBox(height: 4),
            Text('A’zo bölgan: ${_formatDay(profile.createdAt)}', style: AppText.mono(11, color: AppColors.muted)),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: AppText.heading(18, weight: FontWeight.w600)),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;

  const _Empty(this.text);

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(16),
        child: Text(text, style: AppText.body(14, color: AppColors.muted)),
      );
}

class _ListRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final String trailing;
  final Color trailingColor;

  const _ListRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.trailingColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(14, weight: FontWeight.w600)),
                Text(subtitle, style: AppText.mono(11, color: AppColors.muted)),
              ],
            ),
          ),
          Text(trailing, style: AppText.mono(16, color: trailingColor)),
        ],
      ),
    );
  }
}

Widget _rows(List<Widget> rows) => AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.line),
            rows[i],
          ],
        ],
      ),
    );

class _TypingSection extends StatelessWidget {
  final ProfileDetails details;

  const _TypingSection({required this.details});

  @override
  Widget build(BuildContext context) {
    final typing = details.typing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(icon: Icons.keyboard_outlined, title: 'Tez yoziş'),
        const SizedBox(height: 10),
        if (typing == null)
          const _Empty('Hali reytingga kiradigan maşq yöq.')
        else ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              StatTile(
                label: 'Eng yaxşi (WPM)',
                value: '${typing.value('best_wpm').round()}',
                valueColor: AppColors.primary,
                width: 140,
              ),
              StatTile(label: 'Örtaça (WPM)', value: '${typing.value('avg_wpm').round()}', width: 140),
              StatTile(label: 'Aniqlik', value: '${typing.value('avg_accuracy').round()}%', width: 140),
              StatTile(
                label: 'Reytingda',
                value: details.typingRank == null ? '—' : '${details.typingRank}-örin',
                width: 140,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${typing.value('games').round()} ta maşq · ${(typing.value('total_seconds') / 60).round()} daqiqa',
            style: AppText.mono(11, color: AppColors.muted),
          ),
          if (details.bestTyping.isNotEmpty) ...[
            const SizedBox(height: 10),
            _rows([
              for (final result in details.bestTyping)
                _ListRow(
                  leading: Icon(Icons.emoji_events_outlined, size: 18, color: AppColors.primary.withValues(alpha: 0.7)),
                  title: result.modeLabel,
                  subtitle: '${_formatDay(result.createdAt)} · ${result.accuracy.round()}% aniqlik',
                  trailing: '${result.wpm.round()} WPM',
                ),
            ]),
          ],
        ],
      ],
    );
  }
}

class _DictationSection extends StatelessWidget {
  final ProfileDetails details;

  const _DictationSection({required this.details});

  @override
  Widget build(BuildContext context) {
    final LeaderRow? dictation = details.dictation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(icon: Icons.headphones_outlined, title: 'Diktant'),
        const SizedBox(height: 10),
        if (dictation == null)
          const _Empty('Hali diktant topşirilmagan.')
        else ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              StatTile(
                label: 'Jami ball',
                value: '${dictation.value('total_ball').round()}',
                valueColor: AppColors.primary,
                width: 140,
              ),
              StatTile(label: 'Diktantlar', value: '${dictation.value('dictations').round()} ta', width: 140),
              StatTile(label: 'Örtaça baho', value: dictation.value('avg_baho').toStringAsFixed(1), width: 140),
              StatTile(
                label: 'Reytingda',
                value: details.dictationRank == null ? '—' : '${details.dictationRank}-örin',
                width: 140,
              ),
            ],
          ),
          if (details.recentDictations.isNotEmpty) ...[
            const SizedBox(height: 10),
            _rows([
              for (final work in details.recentDictations)
                _ListRow(
                  leading: CircleAvatar(
                    radius: 15,
                    backgroundColor: getRateColor(work.baho),
                    child: Text('${work.baho}', style: AppText.mono(13, color: Colors.white)),
                  ),
                  title: work.title,
                  subtitle: _formatDay(work.updatedAt),
                  trailing: '${work.ball.round()} ball',
                  trailingColor: AppColors.muted,
                ),
            ]),
          ],
        ],
      ],
    );
  }
}
