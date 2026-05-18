import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import 'heartbeat_service.dart';

/// True when the user has denied location permission.
/// Watched by HomeScreen to show a persistent warning banner.
final locationPermissionDeniedProvider =
    NotifierProvider<_PermissionNotifier, bool>(_PermissionNotifier.new);

class _PermissionNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setDenied(bool value) => state = value;
}

final heartbeatProvider = Provider<HeartbeatService>((ref) {
  final service = HeartbeatService();

  ref.listen<AsyncValue<AuthState>>(
    authProvider,
    (_, next) {
      if (next.value is AuthAuthenticated) {
        service.start(ref);
      } else {
        service.stop();
      }
    },
    fireImmediately: true,
  );

  ref.onDispose(service.stop);
  return service;
});
