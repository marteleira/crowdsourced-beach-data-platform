import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/app_routes.dart';
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
        title: const Text(
          'Privacidade & Dados',
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
                const Text('Não foi possível carregar as definições',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () => ref.invalidate(privacySettingsProvider),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                  child: const Text('Tentar de novo'),
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
    void patch(Map<String, dynamic> changes) =>
        ref.read(privacySettingsProvider.notifier).patch(changes);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [

        // Localização
        _Section(
          title: 'Localização',
          children: [
            _LabelRow(
              icon: Icons.location_on_outlined,
              iconColor: AppColors.teal,
              label: 'Precisão da localização',
              subtitle: 'Controla a precisão partilhada com outros utilizadores',
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SegmentedPicker(
                options: const [
                  ('exact',       'Exata'),
                  ('approximate', 'Aprox.'),
                  ('none',        'Nenhuma'),
                ],
                selected: settings.locationAccuracy,
                onChanged: (v) => patch({'location_accuracy': v}),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Perfil público
        _Section(
          title: 'Perfil público',
          children: [
            _SwitchTile(
              icon: Icons.badge_outlined,
              iconColor: AppColors.primary,
              label: 'Nome visível',
              subtitle: 'Outros utilizadores podem ver o teu nome',
              value: settings.namePublic,
              onChanged: (v) => patch({'name_public': v}),
            ),
            _Divider(),
            _SwitchTile(
              icon: Icons.account_circle_outlined,
              iconColor: AppColors.primary,
              label: 'Avatar visível',
              subtitle: 'As tuas iniciais aparecem nos avisos',
              value: settings.avatarPublic,
              onChanged: (v) => patch({'avatar_public': v}),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Presença
        _Section(
          title: 'Presença & Atividade',
          children: [
            _SwitchTile(
              icon: Icons.map_outlined,
              iconColor: AppColors.tealDark,
              label: 'Mostrar no mapa',
              subtitle: 'A tua presença conta para a lotação da praia',
              value: settings.sharePresence,
              onChanged: (v) => patch({'share_presence': v}),
            ),
            _Divider(),
            _SwitchTile(
              icon: Icons.bar_chart_outlined,
              iconColor: AppColors.textSecondary,
              label: 'Partilhar dados de utilização',
              subtitle: 'Ajuda a melhorar a app de forma anónima',
              value: settings.shareUsageData,
              onChanged: (v) => patch({'share_usage_data': v}),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Dados pessoais
        _Section(
          title: 'Os meus dados',
          children: [
            _ActionTile(
              icon: Icons.download_outlined,
              iconColor: AppColors.teal,
              label: 'Exportar os meus dados',
              subtitle: 'Recebe uma cópia de tudo o que guardamos',
              onTap: () => _doExport(context, ref),
            ),
            _Divider(),
            _ActionTile(
              icon: Icons.delete_sweep_outlined,
              iconColor: AppColors.coral,
              label: 'Apagar todos os avisos',
              subtitle: 'Remove os teus avisos da plataforma',
              onTap: () => _confirmDeleteReports(context, ref),
              isDanger: true,
            ),
            _Divider(),
            _ActionTile(
              icon: Icons.person_off_outlined,
              iconColor: AppColors.coral,
              label: 'Apagar conta',
              subtitle: 'Ação permanente e irreversível',
              onTap: () => _confirmDeleteAccount(context, ref),
              isDanger: true,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _doExport(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('A exportar dados…'), duration: Duration(seconds: 2)),
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
            content: Text('Guardado: $filename'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('exportData error: $e\n$st');
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteReports(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar todos os avisos?'),
        content: const Text(
          'Todos os teus avisos serão removidos da plataforma. '
          'Os teus pontos de reputação serão mantidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.coral),
            child: const Text('Apagar'),
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
          const SnackBar(content: Text('Avisos apagados com sucesso')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao apagar avisos')),
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Apagar conta?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Esta ação é permanente. Todos os teus dados serão eliminados.\n\n'
                'Escreve APAGAR para confirmar:',
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'APAGAR',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: controller.text == 'APAGAR'
                  ? () => Navigator.pop(ctx, true)
                  : null,
              style: TextButton.styleFrom(foregroundColor: AppColors.coral),
              child: const Text('Apagar conta'),
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
          const SnackBar(content: Text('Erro ao apagar conta')),
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
          const SnackBar(content: Text('Erro ao cancelar a eliminação. Tenta de novo.')),
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
            const Text(
              'Conta agendada para eliminação',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'A tua conta e todos os teus dados serão eliminados definitivamente a ${_formatDate(widget.scheduledAt)}.\n\nPodes cancelar esta ação até essa data.',
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
                label: Text(_cancelling ? 'A cancelar…' : 'Cancelar eliminação'),
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
                child: const Text('Terminar sessão'),
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

class _LabelRow extends StatelessWidget {
  const _LabelRow({
    required this.label,
    this.subtitle,
    required this.icon,
    required this.iconColor,
  });
  final String label;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.primaryMd),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: AppTextStyles.hint),
                ],
              ],
            ),
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

class _SegmentedPicker extends StatelessWidget {
  const _SegmentedPicker({
    required this.options,
    required this.selected,
    required this.onChanged,
  });
  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: AppRadii.cardChip,
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: options.map((opt) {
          final (value, label) = opt;
          final active = selected == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(value),
              child: AnimatedContainer(
                duration: AppDurations.fast,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: AppRadii.cardSm,
                  boxShadow: active
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))]
                      : [],
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 48, color: AppColors.backgroundLight);
}
