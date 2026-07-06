import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';

final onboardingSeenProvider = FutureProvider<bool>((ref) {
  return ref.read(secureStorageProvider).getOnboardingSeen();
});
