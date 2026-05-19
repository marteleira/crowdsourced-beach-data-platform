import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../features/beaches/data/beach_provider.dart';
import '../../../features/beaches/domain/beach_models.dart';
import '../../../shared/theme/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToSettings() {
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.teal),
      ),
      error: (_, _) => _ErrorView(onRetry: () => ref.invalidate(userProfileProvider)),
      data: (profile) {
        if (profile == null) {
          return _ErrorView(onRetry: () => ref.invalidate(userProfileProvider));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(userProfileProvider),
          color: AppColors.teal,
          child: CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverToBoxAdapter(
                child: _ProfileHeader(
                  profile: profile,
                  onSettingsTap: _scrollToSettings,
                ),
              ),
              SliverToBoxAdapter(child: _ReputationCard(profile: profile)),
              SliverToBoxAdapter(child: _StatsRow(profile: profile)),
              if (profile.isAnonymous)
                const SliverToBoxAdapter(child: _GuestBanner()),
              if (profile.achievements.isNotEmpty)
                SliverToBoxAdapter(child: _AchievementsSection(profile: profile)),
              if (profile.recentEvents.isNotEmpty)
                SliverToBoxAdapter(child: _RecentActivity(profile: profile)),
              const SliverToBoxAdapter(child: _SettingsSection()),
              const SliverToBoxAdapter(child: _SignOutButton()),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.onSettingsTap});
  final UserProfile profile;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final name = profile.displayName ?? (profile.isAnonymous ? 'Convidado' : 'Utilizador');
    final initials = _initials(name);
    final lvlColor = _levelColor(profile.level);

    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, const Color(0xFF0F3D5C)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 64, 24, 36),
          child: Column(
            children: [
              // avatar
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.teal,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profile.isAnonymous
                    ? 'Modo convidado'
                    : '${profile.reputation} pontos de reputação',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              // level badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: lvlColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: lvlColor.withValues(alpha: 0.6), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_levelIcon(profile.level), color: lvlColor, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      _levelLabel(profile.level),
                      style: TextStyle(
                        color: lvlColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 8,
          right: 8,
          child: IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: Colors.white.withValues(alpha: 0.75),
              size: 22,
            ),
            onPressed: onSettingsTap,
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  String _levelLabel(String level) => switch (level) {
    'novo'         => 'Novo',
    'regular'      => 'Regular',
    'contribuidor' => 'Contribuidor',
    'veterano'     => 'Veterano',
    _              => level,
  };

  IconData _levelIcon(String level) => switch (level) {
    'veterano'     => Icons.surfing,
    'contribuidor' => Icons.waves,
    'regular'      => Icons.beach_access,
    _              => Icons.water_outlined,
  };

  Color _levelColor(String level) => switch (level) {
    'novo'         => AppColors.textHint,
    'regular'      => AppColors.teal,
    'contribuidor' => AppColors.sand,
    'veterano'     => AppColors.amber,
    _              => AppColors.textSecondary,
  };
}

class _ReputationCard extends StatelessWidget {
  const _ReputationCard({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final info = _levelInfo(profile.level);
    final progress = info.range == 0
        ? 1.0
        : ((profile.reputation - info.min) / info.range).clamp(0.0, 1.0);
    final ptsToGo = info.max - profile.reputation;

    return _Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${profile.reputation}',
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        height: 1,
                      ),
                    ),
                    const TextSpan(
                      text: ' pts',
                      style: TextStyle(
                        fontSize: 17,
                        color: AppColors.textSecondary,
                        height: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (info.next != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Próximo nível',
                      style: TextStyle(fontSize: 11, color: AppColors.textHint),
                    ),
                    Text(
                      info.next!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '$ptsToGo pts restantes',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '🏄 Nível máximo!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tealDark,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, val, _) => LinearProgressIndicator(
                value: val,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation(AppColors.teal),
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${info.label} (${info.min})',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              if (info.next != null)
                Text(
                  '${info.next} (${info.max})',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
            ],
          ),
        ],
      ),
    );
  }

  ({String label, String? next, int min, int max, int range}) _levelInfo(String level) =>
      switch (level) {
        'novo'         => (label: 'Novo',         next: 'Regular',      min: 0,   max: 10,  range: 10),
        'regular'      => (label: 'Regular',       next: 'Contribuidor', min: 10,  max: 50,  range: 40),
        'contribuidor' => (label: 'Contribuidor',  next: 'Veterano',     min: 50,  max: 150, range: 100),
        _              => (label: 'Veterano',       next: null,           min: 150, max: 150, range: 0),
      };
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final stats = profile.stats;
    final accuracy = (stats?.totalReports ?? 0) > 0
        ? '${(stats!.accuracyRate * 100).round()}%'
        : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _StatTile(
            icon: Icons.description_outlined,
            iconColor: AppColors.coral,
            value: '${stats?.totalReports ?? 0}',
            label: 'Avisos',
          ),
          const SizedBox(width: 8),
          _StatTile(
            icon: Icons.local_fire_department_outlined,
            iconColor: AppColors.amber,
            value: profile.streak > 0 ? '${profile.streak}d' : 'N/A',
            label: 'Streak',
          ),
          const SizedBox(width: 8),
          _StatTile(
            icon: Icons.gps_fixed,
            iconColor: AppColors.teal,
            value: accuracy,
            label: 'Precisão',
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestBanner extends StatelessWidget {
  const _GuestBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.teal.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.teal.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.tealDark, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estás em modo convidado',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Cria uma conta para guardar as tuas contribuições.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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

class _AchievementsSection extends StatelessWidget {
  const _AchievementsSection({required this.profile});
  final UserProfile profile;

  static const _ptLabels = {
    'first_report': 'Primeira Onda',
    'tide_watcher': 'Guardião das Marés',
    '10_reports':   '10 Avisos',
    'accurate':     'Preciso',
    'streak_10':    '10 Dias',
    'regular':      'Regular',
    'contributor':  'Contribuidor',
    'veteran':      'Veterano',
  };

  @override
  Widget build(BuildContext context) {
    final earned = profile.achievements.where((a) => a.earned).length;
    return _Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Conquistas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$earned/${profile.achievements.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tealDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.achievements.map((a) {
              final label = _ptLabels[a.id] ?? a.label;
              return _AchievementChip(achievement: a, label: label);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AchievementChip extends StatelessWidget {
  const _AchievementChip({required this.achievement, required this.label});
  final UserAchievement achievement;
  final String label;

  static const _unearnedBg = Color(0xFFF3F4F6);
  static const _unearnedBorder = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final earned = achievement.earned;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: earned ? AppColors.teal.withValues(alpha: 0.1) : _unearnedBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: earned ? AppColors.teal.withValues(alpha: 0.4) : _unearnedBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: earned ? 1.0 : 0.35,
            child: Text(achievement.emoji, style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: earned ? AppColors.primary : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.profile});
  final UserProfile profile;

  static const _fallbackLabels = {
    'report_confirmed':      'Aviso confirmado pela comunidade',
    'report_contradicted':   'Aviso rejeitado pela comunidade',
    'flag_confirmed':        'Proposta de bandeira confirmada',
    'flag_contradicted':     'Proposta de bandeira rejeitada',
    'confirmation_accurate': 'Confirmação correta',
    'spam_penalty':          'Penalidade por spam',
  };

  @override
  Widget build(BuildContext context) {
    return _Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Atividade Recente',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...profile.recentEvents.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            return Column(
              children: [
                if (i > 0) const _Divider(),
                _EventRow(event: e, fallback: _fallbackLabels),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.fallback});
  final UserReputationEvent event;
  final Map<String, String> fallback;

  static const _positiveBg   = Color(0xFFD1FAE5);
  static const _positiveText = Color(0xFF059669);
  static const _negativeBg   = Color(0xFFFEE2E2);
  static const _negativeText = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final positive = event.delta > 0;
    final deltaText = positive ? '+${event.delta}' : '${event.delta}';
    final label = event.reason ?? fallback[event.event] ?? event.event;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 34,
            decoration: BoxDecoration(
              color: positive ? _positiveBg : _negativeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                deltaText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: positive ? _positiveText : _negativeText,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _timeAgo(event.createdAt),
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso).toUtc();
      final diff = DateTime.now().toUtc().difference(dt);
      if (diff.inMinutes < 1) return 'agora mesmo';
      if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'há ${diff.inHours}h';
      if (diff.inDays == 1) return 'ontem';
      if (diff.inDays < 7) return 'há ${diff.inDays} dias';
      if (diff.inDays < 30) return 'há ${(diff.inDays / 7).round()} sem.';
      return 'há ${(diff.inDays / 30).round()} meses';
    } catch (_) {
      return '';
    }
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    return _Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.star_outline_rounded,
            iconColor: AppColors.amber,
            label: 'Praias Favoritas',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Em breve'), duration: Duration(seconds: 1)),
            ),
          ),
          const _Divider(indent: 58),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            iconColor: AppColors.teal,
            label: 'Notificações',
            onTap: () => context.push('/settings/notifications'),
          ),
          const _Divider(indent: 58),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            iconColor: AppColors.textSecondary,
            label: 'Privacidade & Dados',
            onTap: () => context.push('/settings/privacy'),
          ),
          const _Divider(indent: 58),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.primary,
            label: 'Sobre OndaCerta',
            onTap: () => context.push('/terms'),
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.isLast = false,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(16))
          : BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 15, color: AppColors.primary),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SignOutButton extends ConsumerWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => _confirmSignOut(context, ref),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.coral,
            side: BorderSide(color: AppColors.coral.withValues(alpha: 0.5)),
            backgroundColor: AppColors.coral.withValues(alpha: 0.05),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text(
            'Terminar Sessão',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminar sessão?'),
        content: const Text('Tens a certeza que queres sair da tua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.coral),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    }
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 52, color: AppColors.textHint),
          const SizedBox(height: 16),
          const Text(
            'Não foi possível carregar o perfil',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
            child: const Text('Tentar de novo'),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.margin, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.zero,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({this.indent = 0});
  final double indent;

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: indent, color: const Color(0xFFF3F4F6));
}
