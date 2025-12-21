import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_task_manager/core/data/models/user.dart';
import 'package:todo_task_manager/services/auth_service.dart';

class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final AsyncValue<AuthUser?> status;

  AuthState({
    required this.isAuthenticated,
    this.userId,
    this.status = const AsyncData(null),
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    AsyncValue<AuthUser>? status,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      status: status ?? this.status,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthController(this._authService) : super(AuthState(isAuthenticated: false));

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: const AsyncLoading());
    try {
      final userCredential = await _authService.signIn(email, password);
      final authUser = AuthUser(
        uid: userCredential.user!.uid,
        email: userCredential.user!.email!,
        displayName: userCredential.user!.displayName ?? '',
      );
      state = state.copyWith(
        isAuthenticated: true,
        userId: userCredential.user!.uid,
        status: AsyncData(authUser),
      );
    } catch (e, st) {
      state = state.copyWith(status: AsyncError(e, st));
    }
  }

  Future<void> register(String email, String password, String name) async {
    state = state.copyWith(status: const AsyncLoading());
    try {
      final userCredential = await _authService.signUp(email, password, name);
      final authUser = AuthUser(
        uid: userCredential.user!.uid,
        email: userCredential.user!.email!,
        displayName: userCredential.user!.displayName ?? '',
      );
      state = state.copyWith(
        isAuthenticated: true,
        userId: userCredential.user!.uid,
        status: AsyncData(authUser),
      );
    } catch (e, st) {
      state = state.copyWith(status: AsyncError(e, st));
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: const AsyncLoading());
    try {
      await _authService.signOut();
      state = AuthState(isAuthenticated: false);
    } catch (e, st) {
      state = state.copyWith(status: AsyncError(e, st));
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e, st) {
      state = state.copyWith(status: AsyncError(e, st));
    }
  }

  Future<void> updateUserName(String displayName) async {
    state = state.copyWith(status: const AsyncLoading());
    try {
      await _authService.updateDisplayName(displayName);
      state = state.copyWith(
        status: AsyncData(
          AuthUser(
            uid: state.userId!,
            email: (state.status.value)?.email ?? '',
            displayName: displayName,
          ),
        ),
      );
    } catch (e, st) {
      state = state.copyWith(status: AsyncError(e, st));
    }
  }
}
