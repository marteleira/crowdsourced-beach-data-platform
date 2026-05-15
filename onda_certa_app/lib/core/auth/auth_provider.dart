import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../storage/secure_storage.dart';
import 'auth_repository.dart';

final secureStorageProvider = Provider<SecureStorage>((_) => SecureStorage());

final dioProvider = Provider<Dio>((ref) {
  return createDio(ref.read(secureStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(dioProvider));
});

sealed class AuthState {
  const AuthState();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({
    required this.accessToken,
    required this.isAnonymous,
  });
  final String accessToken;
  final bool isAnonymous;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.getAccessToken();
    if (token == null) return const AuthUnauthenticated();
    final isAnon = await storage.getIsAnonymous();
    return AuthAuthenticated(accessToken: token, isAnonymous: isAnon);
  }

  Future<void> loginWithGoogle(String idToken) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final storage = ref.read(secureStorageProvider);
      final tokens = await repo.loginWithGoogle(idToken);
      await storage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        isAnonymous: tokens.isAnonymous,
      );
      return AuthAuthenticated(
        accessToken: tokens.accessToken,
        isAnonymous: tokens.isAnonymous,
      );
    });
  }

  Future<void> loginAsGuest(String deviceId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final storage = ref.read(secureStorageProvider);
      final tokens = await repo.loginAsGuest(deviceId);
      await storage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        isAnonymous: true,
      );
      return AuthAuthenticated(
        accessToken: tokens.accessToken,
        isAnonymous: true,
      );
    });
  }

  Future<void> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final storage = ref.read(secureStorageProvider);
      final tokens = await repo.registerWithEmail(email, password, displayName);
      await storage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        isAnonymous: false,
      );
      return AuthAuthenticated(
        accessToken: tokens.accessToken,
        isAnonymous: false,
      );
    });
  }

  Future<void> loginWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final storage = ref.read(secureStorageProvider);
      final tokens = await repo.loginWithEmail(email, password);
      await storage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        isAnonymous: false,
      );
      return AuthAuthenticated(
        accessToken: tokens.accessToken,
        isAnonymous: false,
      );
    });
  }

  Future<void> logout() async {
    final storage = ref.read(secureStorageProvider);
    final refreshToken = await storage.getRefreshToken();
    if (refreshToken != null) {
      try {
        await ref.read(authRepositoryProvider).logout(refreshToken);
      } catch (_) {}
    }
    await storage.clearTokens();
    state = const AsyncData(AuthUnauthenticated());
  }
}

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
