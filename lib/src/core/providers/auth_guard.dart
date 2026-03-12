import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/user/presentation/providers/user_provider.dart';

/// 用户是否已登录
final isLoggedInProvider = Provider<bool>((ref) {
  final userState = ref.watch(currentUserProvider);
  return userState.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});

/// 认证守卫
class AuthGuard {
  static String? redirect(Ref ref, String location) {
    final isLoggedIn = ref.read(isLoggedInProvider);
    if (!isLoggedIn && location != '/login') {
      return '/login';
    }
    return null;
  }
}
