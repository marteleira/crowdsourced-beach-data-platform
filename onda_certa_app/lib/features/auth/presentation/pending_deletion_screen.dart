import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../settings/data/settings_provider.dart';

class PendingDeletionScreen extends ConsumerStatefulWidget {
  const PendingDeletionScreen({super.key});

  @override
  ConsumerState<PendingDeletionScreen> createState() =>
      _PendingDeletionScreenState();
}

class _PendingDeletionScreenState extends ConsumerState<PendingDeletionScreen> {
  bool _cancelling = false;

  String _formatDate(DateTime dt) {
    final l = dt.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
  }

  Future<void> _cancelDeletion() async {
    setState(() => _cancelling = true);
    try {
      await ref.read(settingsRepositoryProvider).cancelDeletion();
      ref.read(pendingDeletionProvider.notifier).set(null);
      if (mounted) context.go('/home');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao cancelar a eliminação. Tenta de novo.'),
          ),
        );
        setState(() => _cancelling = false);
      }
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final scheduledAt = ref.watch(pendingDeletionProvider);

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
                  color: AppColors.coral.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_off_outlined,
                  size: 40,
                  color: AppColors.coral,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Conta agendada para eliminação',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                scheduledAt != null
                    ? 'A tua conta e todos os teus dados serão eliminados definitivamente a ${_formatDate(scheduledAt)}.\n\nPodes cancelar esta ação até essa data.'
                    : 'A tua conta está agendada para eliminação.\n\nPodes cancelar esta ação antes da data prevista.',
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
                child: FilledButton.icon(
                  onPressed: _cancelling ? null : _cancelDeletion,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _cancelling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.undo_rounded, size: 20),
                  label: Text(
                    _cancelling ? 'A cancelar…' : 'Cancelar eliminação da conta',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _cancelling ? null : _logout,
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
                  child: const Text('Terminar sessão', style: TextStyle(fontSize: 15)),
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
