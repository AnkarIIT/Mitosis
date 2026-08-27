import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../database/drift_database.dart' as db;
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../services/email_service.dart';
import '../services/cloud_sync_service.dart';
import 'core_providers.dart';

final emailServiceProvider = Provider<EmailService>((ref) {
  return EmailService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  final database = ref.watch(databaseProvider);
  final emailService = ref.watch(emailServiceProvider);
  return AuthService(database, emailService);
});

final cloudSyncServiceProvider = Provider<CloudSyncService?>((ref) {
  if (!AppConfig.enableCloudAuth || !AppConfig.isCloudAuthConfigured) return null;
  try {
    final database = ref.watch(databaseProvider);
    return CloudSyncService(database, supabase.Supabase.instance.client);
  } catch (e) {
    log('Supabase not initialized: $e');
    return null;
  }
});

enum AuthStatus {
  initial,
  loading,
  authenticating,
  awaitingOtp,
  awaiting2FA,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final db.User? user;
  final AuthStatus status;
  final String? error;
  final String? pendingPhone;
  final String? pendingEmail;
  final bool isGuest;

  AuthState({
    this.user,
    this.status = AuthStatus.initial,
    this.error,
    this.pendingPhone,
    this.pendingEmail,
    this.isGuest = false,
  });

  bool get isLoggedIn => user != null || isGuest;

  AuthState copyWith({
    db.User? user,
    AuthStatus? status,
    String? error,
    String? pendingPhone,
    String? pendingEmail,
    bool? isGuest,
  }) {
    return AuthState(
      user: user ?? this.user,
      status: status ?? this.status,
      error: error,
      pendingPhone: pendingPhone ?? this.pendingPhone,
      pendingEmail: pendingEmail ?? this.pendingEmail,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final db.AppDatabase _db;
  final Ref _ref;

  AuthNotifier(this._authService, this._db, this._ref) : super(AuthState()) {
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
      _ref.read(cloudSyncServiceProvider)?.syncAll();
      return;
    }

    if (!AppConfig.isCloudAuthConfigured) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: null,
        isGuest: true,
        error: null,
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

  Future<bool> toggle2FA(bool enabled) async {
    if (state.user == null) return false;
    await _db.updateTwoFactorStatus(state.user!.id, enabled);
    final updatedUser = await _db.getUserById(state.user!.id);
    state = state.copyWith(user: updatedUser);
    return true;
  }

  Future<bool> sendOtp(String email) async {
    state = state.copyWith(status: AuthStatus.authenticating, error: null);
    final result = await _authService.sendOtp(email);
    if (result.success) {
      state = state.copyWith(
        status: AuthStatus.awaitingOtp,
        pendingEmail: email,
        pendingPhone: email,
        isGuest: false,
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

  Future<bool> verifyOtp(String code) async {
    final email = state.pendingEmail ?? state.pendingPhone;
    if (email == null) return false;

    state = state.copyWith(status: AuthStatus.authenticating, error: null);
    final result = await _authService.verifyOtp(email, code);
    if (result.success) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        isGuest: false,
        error: null,
      );
      _ref.read(cloudSyncServiceProvider)?.syncAll();
      return true;
    }

    state = state.copyWith(
      status: AuthStatus.awaitingOtp,
      error: result.message,
    );
    return false;
  }

  Future<bool> verify2FA(String code) async {
    final email = state.pendingEmail;
    if (email == null) return false;

    state = state.copyWith(status: AuthStatus.authenticating, error: null);
    final result = await _authService.verify2FA(email, code);
    if (result.success) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        isGuest: false,
      );
      _ref.read(cloudSyncServiceProvider)?.syncAll();
      return true;
    }

    state = state.copyWith(
      status: AuthStatus.awaiting2FA,
      error: result.message,
    );
    return false;
  }

  Future<void> resend2FA() async {
    final email = state.pendingEmail;
    if (email == null) return;

    state = state.copyWith(status: AuthStatus.authenticating, error: null);
    final result = await _authService.send2FAEmail(email);
    if (result.success) {
      state = state.copyWith(status: AuthStatus.awaiting2FA, error: null);
    } else {
      state = state.copyWith(
        status: AuthStatus.awaiting2FA,
        error: result.message,
      );
    }
  }

  Future<bool> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
  }) async {
    state = state.copyWith(status: AuthStatus.authenticating, error: null);
    final result = await _authService.register(
      email: email,
      username: username,
      password: password,
      fullName: fullName,
    );

    if (result.success) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        isGuest: false,
      );
      _ref.read(cloudSyncServiceProvider)?.syncAll();
      return true;
    }

    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      error: result.message,
    );
    return false;
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.authenticating, error: null);
    final result = await _authService.login(email: email, password: password);

    if (result.success) {
      if (result.message == '2FA_REQUIRED') {
        final emailResult = await _authService.send2FAEmail(email);
        if (emailResult.success) {
          state = state.copyWith(status: AuthStatus.awaiting2FA, pendingEmail: email);
          return true;
        } else {
          state = state.copyWith(status: AuthStatus.unauthenticated, error: emailResult.message);
          return false;
        }
      }
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        isGuest: false,
      );
      _ref.read(cloudSyncServiceProvider)?.syncAll();
      return true;
    }

    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      error: result.message,
    );
    return false;
  }

  Future<bool> resetPassword(String email) async {
    final result = await _authService.resetPassword(email);
    state = state.copyWith(error: result.message);
    return result.success;
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final db = ref.watch(databaseProvider);
  return AuthNotifier(authService, db, ref);
});
