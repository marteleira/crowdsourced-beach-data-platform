import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/notifications/notification_model.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/format_helpers.dart';
import '../../../shared/widgets/empty_state.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifs = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Notificações',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: notifs.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2.5)),
        error: (_, _) => const Center(child: Text('Erro ao carregar notificações', style: TextStyle(color: AppColors.textSecondary))),
        data: (items) => items.isEmpty
            ? const EmptyState(
                icon: Icons.notifications_off_outlined,
                message: 'As notificações sobre as praias aparecem aqui.',
              )
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.borderLight),
                itemBuilder: (_, i) => _NotificationTile(notif: items[i]),
              ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notif});
  final AppNotification notif;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notif.isRead ? null : AppColors.teal.withValues(alpha: 0.06),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_outlined, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notif.title, style: AppTextStyles.titleSm),
                if (notif.body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(notif.body, style: AppTextStyles.secondary),
                ],
                const SizedBox(height: 4),
                Text(timeAgo(notif.receivedAt), style: AppTextStyles.hintXs),
              ],
            ),
          ),
          if (!notif.isRead) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 5),
              decoration: const BoxDecoration(color: AppColors.coral, shape: BoxShape.circle),
            ),
          ],
        ],
      ),
    );
  }

}
