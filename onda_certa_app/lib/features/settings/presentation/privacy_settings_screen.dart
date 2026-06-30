import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../shared/theme/app_theme.dart';
import '../data/settings_provider.dart';
import '../domain/settings_models.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(privacySettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          context.l10n.settingsPrivacyTitle,
          style: AppTextStyles.subtitle,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.teal)),
        error: (error, _) {
          final pendingDate = _parsePendingDeletionDate(error);
          if (pendingDate != null) {
            return _PendingDeletionView(scheduledAt: pendingDate);
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.errorLoadProfile,
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () => ref.invalidate(privacySettingsProvider),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                  child: Text(context.l10n.tryAgain),
                ),
              ],
            ),
          );
        },
        data: (s) => _PrivacyForm(settings: s),
      ),
    );
  }
}

class _PrivacyForm extends ConsumerWidget {
  const _PrivacyForm({required this.settings});
  final PrivacySettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    void patch(Map<String, dynamic> changes) =>
        ref.read(privacySettingsProvider.notifier).patch(changes);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _Section(
          title: l10n.privacyPublicProfile,
          children: [
            _SwitchTile(
              icon: Icons.badge_outlined,
              iconColor: AppColors.primary,
              label: l10n.privacyNameVisible,
              subtitle: l10n.privacyNameVisibleSub,
              value: settings.namePublic,
              onChanged: (v) => patch({'name_public': v}),
            ),
            _Divider(),
            _SwitchTile(
              icon: Icons.account_circle_outlined,
              iconColor: AppColors.primary,
              label: l10n.privacyAvatarVisible,
              subtitle: l10n.privacyAvatarVisibleSub,
              value: settings.avatarPublic,
              onChanged: (v) => patch({'avatar_public': v}),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        _Section(
          title: l10n.privacyPresence,
          children: [
            _SwitchTile(
              icon: Icons.map_outlined,
              iconColor: AppColors.tealDark,
              label: l10n.privacyShowOnMap,
              subtitle: l10n.privacyShowOnMapSub,
              value: settings.sharePresence,
              onChanged: (v) => patch({'share_presence': v}),
            ),
            _Divider(),
            _SwitchTile(
              icon: Icons.bar_chart_outlined,
              iconColor: AppColors.textSecondary,
              label: l10n.privacyShareUsage,
              subtitle: l10n.privacyShareUsageSub,
              value: settings.shareUsageData,
              onChanged: (v) => patch({'share_usage_data': v}),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        _Section(
          title: l10n.privacyMyData,
          children: [
            _ActionTile(
              icon: Icons.download_outlined,
              iconColor: AppColors.teal,
              label: l10n.privacyExportData,
              subtitle: l10n.privacyExportDataSub,
              onTap: () => _doExport(context, ref),
            ),
            _Divider(),
            _ActionTile(
              icon: Icons.delete_sweep_outlined,
              iconColor: AppColors.coral,
              label: l10n.privacyDeleteReports,
              subtitle: l10n.privacyDeleteReportsSub,
              onTap: () => _confirmDeleteReports(context, ref),
              isDanger: true,
            ),
            _Divider(),
            _ActionTile(
              icon: Icons.person_off_outlined,
              iconColor: AppColors.coral,
              label: l10n.privacyDeleteAccount,
              subtitle: l10n.privacyDeleteAccountSub,
              onTap: () => _confirmDeleteAccount(context, ref),
              isDanger: true,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _doExport(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.privacyExporting), duration: const Duration(seconds: 2)),
    );
    try {
      final data = await ref.read(settingsRepositoryProvider).exportData();
      final dir = (await getExternalStorageDirectory()) ?? await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final filename =
          'ondacerta_dados_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.json';
      final file = File('${dir.path}/$filename');
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.privacyExportSaved(filename)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('exportData error: $e\n$st');
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.privacyExportError(e.toString()))),
        );
      }
    }
  }

  Future<void> _confirmDeleteReports(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.privacyDeleteReportsConfirmTitle),
        content: Text(l10n.privacyDeleteReportsConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.coral),
            child: Text(l10n.privacyDeleteLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(settingsRepositoryProvider).deleteAllReports();
      ref.invalidate(privacySettingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.privacyDeleteReportsSuccess)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.privacyDeleteReportsError)),
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l10n.privacyDeleteAccountConfirmTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.privacyDeleteAccountConfirmBody),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: l10n.privacyDeleteAccountConfirmWord,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancelLabel),
            ),
            TextButton(
              onPressed: controller.text == l10n.privacyDeleteAccountConfirmWord
                  ? () => Navigator.pop(ctx, true)
                  : null,
              style: TextButton.styleFrom(foregroundColor: AppColors.coral),
              child: Text(l10n.privacyDeleteAccountConfirmBtn),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(settingsRepositoryProvider).deleteAccount();
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go(AppRoutes.login);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.privacyDeleteAccountError)),
        );
      }
    }
  }
}

// ── Pending-deletion helpers & view ───────────────────────────────────────────

DateTime? _parsePendingDeletionDate(Object error) {
  if (error is DioException) {
    final detail = error.response?.data?['detail'];
    if (detail is Map && detail['code'] == 'account_pending_deletion') {
      final raw = detail['scheduled_deletion_at'] as String?;
      if (raw != null) return DateTime.tryParse(raw);
    }
  }
  return null;
}

String _formatDate(DateTime dt) {
  final l = dt.toLocal();
  return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
}

class _PendingDeletionView extends ConsumerStatefulWidget {
  const _PendingDeletionView({required this.scheduledAt});
  final DateTime scheduledAt;

  @override
  ConsumerState<_PendingDeletionView> createState() => _PendingDeletionViewState();
}

class _PendingDeletionViewState extends ConsumerState<_PendingDeletionView> {
  bool _cancelling = false;

  Future<void> _cancel() async {
    setState(() => _cancelling = true);
    try {
      await ref.read(settingsRepositoryProvider).cancelDeletion();
      ref.invalidate(privacySettingsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.privacyCancelError)),
        );
        setState(() => _cancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.coral.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_off_outlined, size: 36, color: AppColors.coral),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.privacyPendingTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.privacyPendingBody(_formatDate(widget.scheduledAt)),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _cancelling ? null : _cancel,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: AppRadii.cardMd),
                ),
                icon: _cancelling
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.undo_rounded, size: 18),
                label: Text(_cancelling ? context.l10n.privacyCancelling : context.l10n.privacyCancelDeletion),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => ref.read(authProvider.notifier).logout().then((_) {
                  if (context.mounted) context.go(AppRoutes.login);
                }),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: AppRadii.cardMd),
                ),
                child: Text(context.l10n.signOut),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Shared widgets

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadii.cardLg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
    this.iconColor,
  });
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: iconColor ?? AppColors.primary),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.primary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: AppTextStyles.hint),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.teal,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.isDanger = false,
  });
  final String label;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDanger ? AppColors.coral : AppColors.primary,
                      fontWeight: isDanger ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: AppTextStyles.hint),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 48, color: AppColors.backgroundLight);
}
