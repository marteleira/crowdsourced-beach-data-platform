import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
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
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.teal)),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Não foi possível carregar as definições',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(privacySettingsProvider),
                style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                child: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
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
            const SizedBox(height: 4),
          ],
        ),

        const SizedBox(height: 12),

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

        const SizedBox(height: 12),

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

        const SizedBox(height: 12),

        // Dados pessoais
        _Section(
          title: 'Os meus dados',
          children: [
            _ActionTile(
              icon: Icons.download_outlined,
              iconColor: AppColors.teal,
              label: 'Exportar os meus dados',
              subtitle: 'Recebe uma cópia de tudo o que guardamos',
              onTap: () => _showExportInfo(context),
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

  void _showExportInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exportar dados'),
        content: const Text(
          'Os teus dados (avisos, histórico de reputação) estão disponíveis via API.\n\n'
          'Endpoint: GET /users/me/data-export\n\n'
          'Integração com exportação direta em breve.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
              const SizedBox(height: 12),
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
      if (context.mounted) context.go('/login');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao apagar conta')),
        );
      }
    }
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
            borderRadius: BorderRadius.circular(16),
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
            const SizedBox(width: 12),
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
                      style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 15, color: AppColors.primary)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
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
            const SizedBox(width: 12),
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
                        style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
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
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
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
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
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
      const Divider(height: 1, indent: 48, color: Color(0xFFF3F4F6));
}
