import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';

class AccountBannedScreen extends ConsumerWidget {
  const AccountBannedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banReason = ref.watch(accountBannedProvider);

    return _AccountStatusLayout(
      icon: Icons.gavel_rounded,
      iconColor: AppColors.coral,
      title: 'Conta banida',
      body: banReason != null && banReason.isNotEmpty
          ? 'A tua conta foi banida permanentemente por violação das regras da comunidade.\n\nRazão: $banReason'
          : 'A tua conta foi banida permanentemente por violação das regras da comunidade.',
      onLogout: () async {
        ref.read(accountBannedProvider.notifier).set(null);
        await ref.read(authProvider.notifier).logout();
        if (context.mounted) context.go('/login');
      },
    );
  }
}

class AccountSuspendedScreen extends ConsumerWidget {
  const AccountSuspendedScreen({super.key});

  String _formatDateTime(DateTime dt) {
    final l = dt.toLocal();
    final date =
        '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
    final time =
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
    return '$date às $time';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suspendedUntil = ref.watch(accountSuspendedProvider);

    return _AccountStatusLayout(
      icon: Icons.hourglass_top_rounded,
      iconColor: AppColors.teal,
      title: 'Conta suspensa',
      body: suspendedUntil != null
          ? 'A tua conta está temporariamente suspensa até ${_formatDateTime(suspendedUntil)}.\n\nContinuas a poder ver as praias. Podes voltar a contribuir após esse período.'
          : 'A tua conta está temporariamente suspensa.\n\nContinuas a poder ver as praias.',
      onLogout: () async {
        ref.read(accountSuspendedProvider.notifier).set(null);
        await ref.read(authProvider.notifier).logout();
        if (context.mounted) context.go('/login');
      },
    );
  }
}

class _AccountStatusLayout extends StatelessWidget {
  const _AccountStatusLayout({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.onLogout,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: iconColor),
              ),
              const SizedBox(height: 28),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onLogout,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Terminar sessão',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
