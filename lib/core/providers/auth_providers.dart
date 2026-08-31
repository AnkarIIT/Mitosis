import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/drift_database.dart' as db;
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import 'core_providers.dart';
import 'service_providers.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  awaiting2FA,
  error,
}

class AuthState {
  final db.User? user;
  final AuthStatus status;
  final String? error;
  final bool isGuest;

  AuthState({
    this.user,
    this.status = AuthStatus.initial,
    this.error,
    this.isGuest = false,
  });

  bool get isLoggedIn => user != null || isGuest;

  AuthState copyWith({
    db.User? user,
    AuthStatus? status,
    String? error,
    bool? isGuest,
  }) {
    return AuthState(
      user: user ?? this.user,
      status: status ?? this.status,
      error: error,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final GoogleAuthService _googleAuthService;
  final db.AppDatabase _db;
  AuthNotifier(this._authService, this._googleAuthService, this._db)
    : super(AuthState()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    final user = await _authService.tryAutoLogin();
    if (user != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isGuest: false,
      );
      return;
    }

    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      isGuest: false,
      user: null,
    );
  }

  Future<void> continueAsGuest() async {
    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: null,
      isGuest: true,
      error: null,
    );
  }

  Future<bool> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    final result = await _authService.register(
      email: email,
      username: username,
      password: password,
      fullName: fullName,
    );

    if (result.success) {
      await _authService.saveSession(result.user!.id);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        isGuest: false,
        error: null,
      );
      return true;
    }

    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      error: result.message,
      isGuest: false,
    );
    return false;
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    final result = await _authService.login(email: email, password: password);

    if (result.success) {
      if (result.user?.isTwoFactorEnabled == true) {
        final otpResult = await _authService.sendLogin2FAEmail(result.user!.id);
        if (otpResult.success) {
          state = state.copyWith(
            status: AuthStatus.awaiting2FA,
            user: result.user,
            isGuest: false,
            error: null,
          );
          return true;
        } else {
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            error: otpResult.message,
            isGuest: false,
          );
          return false;
        }
      }

      await _authService.saveSession(result.user!.id);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        isGuest: false,
        error: null,
      );
      return true;
    }

    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      error: result.message,
      isGuest: false,
    );
    return false;
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    final result = await _googleAuthService.signInWithGoogle();

    if (result.success && result.user != null) {
      await _authService.saveSession(result.user!.id);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        isGuest: false,
        error: null,
      );
      return true;
    }

    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      error: result.message,
      isGuest: false,
    );
    return false;
  }

  Future<bool> verifyLogin2FA(String code) async {
    final user = state.user;
    if (user == null) return false;

    state = state.copyWith(status: AuthStatus.loading, error: null);
    final result = await _authService.verifyLogin2FA(user.id, code);

    if (result.success) {
      await _authService.saveSession(result.user!.id);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        isGuest: false,
        error: null,
      );
      return true;
    }

    state = state.copyWith(
      status: AuthStatus.awaiting2FA,
      error: result.message,
    );
    return false;
  }

  Future<bool> resendLogin2FA() async {
    final user = state.user;
    if (user == null) return false;

    state = state.copyWith(status: AuthStatus.loading, error: null);
    final result = await _authService.sendLogin2FAEmail(user.id);
    state = state.copyWith(
      status: AuthStatus.awaiting2FA,
      error: result.success ? null : result.message,
    );
    return result.success;
  }

  Future<bool> enable2FA(String email) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    final result = await _authService.enable2FA(email);
    state = state.copyWith(
      status: AuthStatus.authenticated,
      error: result.message,
    );
    return result.success;
  }

  Future<bool> confirmEnable2FA(String email, String code) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    final result = await _authService.confirmEnable2FA(email, code);

    if (result.success) {
      final user = await _db.getUserByEmail(email.trim().toLowerCase());
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isGuest: false,
        error: null,
      );
      return true;
    }

    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      error: result.message,
    );
    return false;
  }

  Future<bool> disable2FA() async {
    final user = state.user;
    if (user == null) return false;

    final result = await _authService.disable2FA(user.id);
    if (result.success) {
      final updated = await _db.getUserById(user.id);
      state = state.copyWith(user: updated, error: null);
    } else {
      state = state.copyWith(error: result.message);
    }
    return result.success;
  }

  Future<bool> toggle2FA(bool enabled) async {
    if (state.user == null) return false;

    if (enabled) {
      return await enable2FA(state.user!.email!);
    } else {
      return await disable2FA();
    }
  }

  Future<bool> resetPassword(String email) async {
    final result = await _authService.sendPasswordReset(email: email);
    state = state.copyWith(error: result.message);
    return result.success;
  }

  Future<bool> verifyResetCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    final result = await _authService.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );

    if (result.success) {
      await _authService.saveSession(result.user!.id);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        isGuest: false,
        error: null,
      );
      return true;
    }

    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      error: result.message,
    );
    return false;
  }

  Future<void> logout() async {
    await _googleAuthService.signOut();
    await _authService.logout();
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  Future<({bool success, String message})> deleteAccount() async {
    try {
      final user = state.user;
      if (user == null) {
        return (success: false, message: 'No account is signed in.');
      }

      await _db.clearUserData(user.id);
      await _authService.logout();
      state = AuthState(status: AuthStatus.unauthenticated);
      return (success: true, message: 'Account deleted');
    } catch (e) {
      return (success: false, message: 'Could not delete account: $e');
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final googleAuthService = ref.watch(googleAuthServiceProvider);
  final db = ref.watch(databaseProvider);
  return AuthNotifier(authService, googleAuthService, db);
});
