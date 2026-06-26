import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../features/beaches/data/beach_provider.dart';
import '../../../features/beaches/domain/beach_models.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../shared/utils/format_helpers.dart';
import '../../../shared/widgets/user_avatar.dart';

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
        final avatarId = profile.avatarId;
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(userProfileProvider),
          color: AppColors.teal,
          child: CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverToBoxAdapter(
                child: _ProfileHeader(
                  profile: profile,
                  avatarId: avatarId,
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
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.onSettingsTap,
    this.avatarId,
  });
  final UserProfile profile;
  final VoidCallback onSettingsTap;
  final String? avatarId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = profile.displayName ?? (profile.isAnonymous ? l10n.guestUser : l10n.registeredUser);
    final initials = getInitials(name);
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
              UserAvatarWidget(
                size: 84,
                avatarId: avatarId,
                initials: initials,
                showGlow: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                profile.isAnonymous
                    ? l10n.guestMode
                    : l10n.reputationPoints(profile.reputation),
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
                  borderRadius: AppRadii.cardXl,
                  border: Border.all(color: lvlColor.withValues(alpha: 0.6), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_levelIcon(profile.level), color: lvlColor, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      _levelLabel(l10n, profile.level),
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

  String _levelLabel(AppLocalizations l10n, String level) => switch (level) {
    'novo'         => l10n.levelNew,
    'regular'      => l10n.levelRegular,
    'contribuidor' => l10n.levelContributor,
    'veterano'     => l10n.levelVeteran,
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
    final l10n = context.l10n;
    final info = _levelInfo(l10n, profile.level);
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
                      l10n.levelNextLabel,
                      style: AppTextStyles.hintSm,
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
                      l10n.levelPointsLeft(ptsToGo),
                      style: AppTextStyles.secondary,
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: AppRadii.cardSm,
                  ),
                  child: Text(
                    l10n.levelMaxReached,
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
            borderRadius: AppRadii.cardXs,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, val, _) => LinearProgressIndicator(
                value: val,
                backgroundColor: AppColors.borderLight,
                valueColor: const AlwaysStoppedAnimation(AppColors.teal),
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${info.label} (${info.min})',
                style: AppTextStyles.secondarySm,
              ),
              if (info.next != null)
                Text(
                  '${info.next} (${info.max})',
                  style: AppTextStyles.secondarySm,
                ),
            ],
          ),
        ],
      ),
    );
  }

  ({String label, String? next, int min, int max, int range}) _levelInfo(AppLocalizations l10n, String level) =>
      switch (level) {
        'novo'         => (label: l10n.levelNew,         next: l10n.levelRegular,      min: 0,   max: 10,  range: 10),
        'regular'      => (label: l10n.levelRegular,     next: l10n.levelContributor,  min: 10,  max: 50,  range: 40),
        'contribuidor' => (label: l10n.levelContributor, next: l10n.levelVeteran,      min: 50,  max: 150, range: 100),
        _              => (label: l10n.levelVeteran,     next: null,                    min: 150, max: 150, range: 0),
      };
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
            label: l10n.statReports,
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatTile(
            icon: Icons.local_fire_department_outlined,
            iconColor: AppColors.amber,
            value: profile.streak > 0 ? '${profile.streak}d' : 'N/A',
            label: l10n.statStreak,
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatTile(
            icon: Icons.gps_fixed,
            iconColor: AppColors.teal,
            value: accuracy,
            label: l10n.statAccuracy,
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
          borderRadius: AppRadii.cardButton,
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
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.secondary,
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
          borderRadius: AppRadii.cardButton,
          border: Border.all(color: AppColors.teal.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.tealDark, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.guestBannerTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.guestSaveContribs,
                    style: AppTextStyles.secondary,
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = {
      'first_report': l10n.achievementFirstReport,
      'tide_watcher': l10n.achievementTideWatcher,
      '10_reports':   l10n.achievement10Reports,
      'accurate':     l10n.achievementAccurate,
      'streak_10':    l10n.achievementStreak10,
      'regular':      l10n.achievementRegular,
      'contributor':  l10n.achievementContributor,
      'veteran':      l10n.achievementVeteran,
    };
    final earned = profile.achievements.where((a) => a.earned).length;
    return _Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.achievementsTitle,
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
                  borderRadius: AppRadii.cardMd,
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
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.achievements.map((a) {
              final label = labels[a.id] ?? a.label;
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

  @override
  Widget build(BuildContext context) {
    final earned = achievement.earned;
    return AnimatedContainer(
      duration: AppDurations.medium,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: earned ? AppColors.teal.withValues(alpha: 0.1) : AppColors.backgroundLight,
        borderRadius: AppRadii.cardXl,
        border: Border.all(
          color: earned ? AppColors.teal.withValues(alpha: 0.4) : AppColors.borderLight,
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.recentActivityTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...profile.recentEvents.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            return Column(
              children: [
                if (i > 0) const _Divider(),
                _EventRow(event: e),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});
  final UserReputationEvent event;

  static const _positiveBg   = Color(0xFFD1FAE5);
  static const _positiveText = Color(0xFF059669);
  static const _negativeBg   = Color(0xFFFEE2E2);
  static const _negativeText = Color(0xFFDC2626);

  String _alertTypeName(AppLocalizations l10n, String? type) => switch (type) {
    'jellyfish'      => l10n.alertTypeJellyfish,
    'strong_current' => l10n.alertTypeStrongCurrent,
    'pollution'      => l10n.alertTypePollution,
    'rough_sea'      => l10n.alertTypeRoughSea,
    'other_alert'    => l10n.alertTypeOther,
    _                => type ?? '',
  };

  String _flagColorLabel(AppLocalizations l10n, String? color) => switch (color) {
    'green'  => l10n.flagColorGreenCap,
    'yellow' => l10n.flagColorYellowCap,
    'red'    => l10n.flagColorRedCap,
    'purple' => l10n.flagColorPurpleCap,
    _        => color ?? '',
  };

  String _formatEventLabel(AppLocalizations l10n) {
    final p = event.params;
    switch (event.event) {
      case 'report_submitted':
        final type = _alertTypeName(l10n, p?['alert_type'] as String?);
        return type.isNotEmpty ? '${l10n.eventReportSubmitted}: $type' : l10n.eventReportSubmitted;
      case 'first_report_bonus':
        return l10n.eventFirstReportBonus;
      case 'report_confirmed':
        final type = _alertTypeName(l10n, p?['alert_type'] as String?);
        return type.isNotEmpty ? '${l10n.eventReportConfirmed}: $type' : l10n.eventReportConfirmed;
      case 'report_contradicted':
        final type = _alertTypeName(l10n, p?['alert_type'] as String?);
        return type.isNotEmpty ? '${l10n.eventReportContradicted}: $type' : l10n.eventReportContradicted;
      case 'flag_confirmed':
        final color = _flagColorLabel(l10n, p?['color'] as String?);
        return color.isNotEmpty ? '${l10n.eventFlagConfirmed}: $color' : l10n.eventFlagConfirmed;
      case 'flag_contradicted':
        final color = _flagColorLabel(l10n, p?['color'] as String?);
        return color.isNotEmpty ? '${l10n.eventFlagContradicted}: $color' : l10n.eventFlagContradicted;
      case 'confirmation_accurate':
        final color = _flagColorLabel(l10n, p?['color'] as String?);
        final outcome = p?['outcome'] as String? ?? '';
        if (outcome == 'contradicted') return l10n.eventConfirmationContradicted(color);
        if (outcome == 'verified')     return l10n.eventConfirmationVerified(color);
        return l10n.eventConfirmationAccurate;
      case 'spam_penalty':
        return l10n.eventSpamPenalty;
      default:
        return event.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final positive = event.delta > 0;
    final deltaText = positive ? '+${event.delta}' : '${event.delta}';
    final label = _formatEventLabel(l10n);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 34,
            decoration: BoxDecoration(
              color: positive ? _positiveBg : _negativeBg,
              borderRadius: AppRadii.cardSm,
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
          const SizedBox(width: AppSpacing.md),
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
                  timeAgoFromString(l10n, event.createdAt),
                  style: AppTextStyles.hint,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.manage_accounts_outlined,
            iconColor: AppColors.teal,
            label: l10n.settingsAccountTitle,
            onTap: () => context.push(AppRoutes.settingsAccount),
          ),
          const _Divider(indent: 58),
          _SettingsTile(
            icon: Icons.star_outline_rounded,
            iconColor: AppColors.amber,
            label: l10n.settingsFavouritesTitle,
            onTap: () => context.push(AppRoutes.favourites),
          ),
          const _Divider(indent: 58),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            iconColor: AppColors.teal,
            label: l10n.notificationsTitle,
            onTap: () => context.push(AppRoutes.settingsNotifications),
          ),
          const _Divider(indent: 58),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            iconColor: AppColors.textSecondary,
            label: l10n.settingsPrivacyTitle,
            onTap: () => context.push(AppRoutes.settingsPrivacy),
          ),
          const _Divider(indent: 58),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.primary,
            label: l10n.settingsAboutTitle,
            onTap: () => context.push(AppRoutes.terms),
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
                borderRadius: AppRadii.cardChip,
              ),
              child: Icon(icon, color: iconColor, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.primaryMd,
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
            shape: RoundedRectangleBorder(borderRadius: AppRadii.cardButton),
          ),
          child: Text(
            context.l10n.signOut,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.signOutTitle),
        content: Text(l10n.signOutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.signOutCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.coral),
            child: Text(l10n.signOutConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go(AppRoutes.login);
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
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.errorLoadProfile,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
            child: Text(context.l10n.tryAgain),
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
        borderRadius: AppRadii.cardLg,
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
      Divider(height: 1, indent: indent, color: AppColors.backgroundLight);
}
