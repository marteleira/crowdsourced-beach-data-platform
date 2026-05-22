import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_theme.dart';
import '../data/settings_provider.dart';
import '../domain/settings_models.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Notificações',
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
              const Text('Não foi possível carregar as notificações',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(notificationSettingsProvider),
                style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                child: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
        data: (s) => _NotificationForm(settings: s),
      ),
    );
  }
}

class _NotificationForm extends ConsumerWidget {
  const _NotificationForm({required this.settings});
  final NotificationSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = settings.globalEnabled;

    void patch(Map<String, dynamic> changes) =>
        ref.read(notificationSettingsProvider.notifier).patch(changes);

    void patchAlertTypes(NotificationAlertTypes types) =>
        patch({'alert_types': types.toJson()});

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [

        // Master switch
        _Section(
          title: 'Geral',
          children: [
            _SwitchTile(
              icon: Icons.notifications_outlined,
              iconColor: AppColors.teal,
              label: 'Notificações ativadas',
              subtitle: 'Liga ou desliga todas as notificações',
              value: settings.globalEnabled,
              onChanged: (v) => patch({'global_enabled': v}),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Alertas de comunidade
        _Section(
          title: 'Alertas de comunidade',
          children: [
            _SwitchTile(
              icon: Icons.login_rounded,
              iconColor: AppColors.primary,
              label: 'Alertas ao fazer check-in',
              subtitle: 'Notifica quando chegares a uma praia com alertas',
              value: settings.checkinAlerts,
              enabled: on,
              onChanged: (v) => patch({'checkin_alerts': v}),
            ),
            _Divider(),
            _SwitchTile(
              icon: Icons.radar,
              iconColor: AppColors.primary,
              label: 'Alertas de proximidade',
              subtitle: 'Alertas quando estás perto de uma praia',
              value: settings.proximityAlerts,
              enabled: on,
              onChanged: (v) => patch({'proximity_alerts': v}),
            ),
            if (settings.proximityAlerts && on) ...[
              _Divider(),
              _SliderTile(
                icon: Icons.social_distance_outlined,
                iconColor: AppColors.textSecondary,
                label: 'Raio de proximidade',
                value: settings.proximityRadiusMeters.toDouble(),
                min: 100,
                max: 2000,
                divisions: 19,
                format: (v) => '${v.round()} m',
                onChanged: (v) => patch({'proximity_radius_meters': v.round()}),
              ),
            ],
          ],
        ),

        const SizedBox(height: 12),

        // Tipos de alerta
        _Section(
          title: 'Tipos de alerta',
          children: [
            _SwitchTile(
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFF6366F1),
              label: 'Medusas',
              value: settings.alertTypes.jellyfish,
              enabled: on,
              onChanged: (v) => patchAlertTypes(settings.alertTypes.copyWith(jellyfish: v)),
            ),
            _Divider(),
            _SwitchTile(
              icon: Icons.waves,
              iconColor: AppColors.tealDark,
              label: 'Corrente forte',
              value: settings.alertTypes.strongCurrent,
              enabled: on,
              onChanged: (v) => patchAlertTypes(settings.alertTypes.copyWith(strongCurrent: v)),
            ),
            _Divider(),
            _SwitchTile(
              icon: Icons.science_outlined,
              iconColor: AppColors.coral,
              label: 'Poluição',
              value: settings.alertTypes.pollution,
              enabled: on,
              onChanged: (v) => patchAlertTypes(settings.alertTypes.copyWith(pollution: v)),
            ),
            _Divider(),
            _SwitchTile(
              icon: Icons.storm_outlined,
              iconColor: AppColors.primary,
              label: 'Mar agitado',
              value: settings.alertTypes.roughSea,
              enabled: on,
              onChanged: (v) => patchAlertTypes(settings.alertTypes.copyWith(roughSea: v)),
            ),
            _Divider(),
            _SegmentTile(
              icon: Icons.low_priority_rounded,
              iconColor: AppColors.textSecondary,
              label: 'Severidade mínima',
              options: const [('1', 'Baixa'), ('2', 'Média'), ('3', 'Alta')],
              selected: '${settings.minSeverity}',
              enabled: on,
              onChanged: (v) => patch({'min_severity': int.parse(v)}),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Praias favoritas
        _Section(
          title: 'Praias favoritas',
          children: [
            _SwitchTile(
              icon: Icons.star_outline_rounded,
              iconColor: AppColors.amber,
              label: 'Alertas das minhas praias',
              subtitle: 'Recebe alertas das praias que tens guardadas',
              value: settings.favouriteAlertsEnabled,
              enabled: on,
              onChanged: (v) => patch({'favourite_alerts_enabled': v}),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Bandeira e marés
        _Section(
          title: 'Estado da praia',
          children: [
            _SwitchTile(
              icon: Icons.flag_outlined,
              iconColor: AppColors.flagGreen,
              label: 'Mudança de bandeira',
              subtitle: 'Notifica quando o estado de segurança muda',
              value: settings.flagChangeAlerts,
              enabled: on,
              onChanged: (v) => patch({'flag_change_alerts': v}),
            ),
            _Divider(),
            _SwitchTile(
              icon: Icons.water_outlined,
              iconColor: AppColors.teal,
              label: 'Alertas de maré',
              subtitle: 'Aviso antes de preia-mar e baixa-mar',
              value: settings.tideAlerts,
              enabled: on,
              onChanged: (v) => patch({'tide_alerts': v}),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Os meus avisos
        _Section(
          title: 'Os meus avisos',
          children: [
            _SwitchTile(
              icon: Icons.thumb_up_outlined,
              iconColor: const Color(0xFF059669),
              label: 'Aviso confirmado',
              subtitle: 'Quando a comunidade confirma um aviso teu',
              value: settings.reportConfirmed,
              enabled: on,
              onChanged: (v) => patch({'report_confirmed': v}),
            ),
            _Divider(),
            _SwitchTile(
              icon: Icons.thumb_down_outlined,
              iconColor: AppColors.coral,
              label: 'Aviso rejeitado',
              subtitle: 'Quando a comunidade rejeita um aviso teu',
              value: settings.reportRejected,
              enabled: on,
              onChanged: (v) => patch({'report_rejected': v}),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Horas de silêncio
        _Section(
          title: 'Horas de silêncio',
          children: [
            _SwitchTile(
              icon: Icons.bedtime_outlined,
              iconColor: const Color(0xFF6366F1),
              label: 'Ativar horas de silêncio',
              subtitle: 'Sem notificações durante o período definido',
              value: settings.quietHoursEnabled,
              enabled: on,
              onChanged: (v) => patch({'quiet_hours_enabled': v}),
            ),
            if (settings.quietHoursEnabled && on) ...[
              _Divider(),
              _TimeTile(
                icon: Icons.nights_stay_outlined,
                iconColor: AppColors.textSecondary,
                label: 'Início',
                time: settings.quietHoursStart,
                onChanged: (v) => patch({'quiet_hours_start': v}),
              ),
              _Divider(),
              _TimeTile(
                icon: Icons.wb_sunny_outlined,
                iconColor: AppColors.amber,
                label: 'Fim',
                time: settings.quietHoursEnd,
                onChanged: (v) => patch({'quiet_hours_end': v}),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

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
    this.enabled = true,
  });
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;
  final Color? iconColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: enabled ? (iconColor ?? AppColors.primary) : AppColors.textHint),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    color: enabled ? AppColors.primary : AppColors.textHint,
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
            onChanged: enabled ? onChanged : null,
            activeTrackColor: AppColors.teal,
          ),
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.format,
    required this.onChanged,
    this.icon,
    this.iconColor,
  });
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) format;
  final ValueChanged<double> onChanged;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: iconColor ?? AppColors.textSecondary),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label,
                        style: const TextStyle(fontSize: 15, color: AppColors.primary)),
                    Text(format(value),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.tealDark)),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.teal,
                    inactiveTrackColor: AppColors.borderLight,
                    thumbColor: AppColors.teal,
                    overlayColor: AppColors.teal.withValues(alpha: 0.12),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: divisions,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentTile extends StatelessWidget {
  const _SegmentTile({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.icon,
    this.iconColor,
    this.enabled = true,
  });
  final String label;
  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onChanged;
  final IconData? icon;
  final Color? iconColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: enabled ? (iconColor ?? AppColors.primary) : AppColors.textHint),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: enabled ? AppColors.primary : AppColors.textHint,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: options.map((opt) {
                final (value, label) = opt;
                final active = selected == value;
                return GestureDetector(
                  onTap: enabled ? () => onChanged(value) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: active
                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 3)]
                          : [],
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? (enabled ? AppColors.primary : AppColors.textHint)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.time,
    required this.onChanged,
    this.icon,
    this.iconColor,
  });
  final String label;
  final String time; // "HH:MM"
  final ValueChanged<String> onChanged;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pick(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: iconColor ?? AppColors.textSecondary),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 15, color: AppColors.primary)),
            ),
            Text(
              time,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.tealDark,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final parts = time.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 22,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      onChanged('$hh:$mm');
    }
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 48, color: AppColors.backgroundLight);
}
