import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_task_manager/controllers/auth_controller.dart';
import 'package:todo_task_manager/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});
final currentUserProvider = StreamProvider.autoDispose<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final authService = ref.watch(authServiceProvider);
    return AuthController(authService);
  },
);
