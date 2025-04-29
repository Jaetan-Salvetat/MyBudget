import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/data/repositories/auth_repository_impl.dart';
import 'package:mybudget/domain/entities/user.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final authRepositoryProvider;

  AuthNotifier(this.authRepositoryProvider) : super(const AsyncValue.loading()) {
    getCurrentUser();
  }

  Future<void> getCurrentUser() async {
    try {
      state = const AsyncValue.loading();
      final user = await authRepositoryProvider.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> login(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      final user = await authRepositoryProvider.login(email, password);
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      state = const AsyncValue.loading();
      final user = await authRepositoryProvider.register(name, email, password);
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> logout() async {
    try {
      state = const AsyncValue.loading();
      await authRepositoryProvider.logout();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
