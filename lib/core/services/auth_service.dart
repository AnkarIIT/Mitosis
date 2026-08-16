import 'dart:math';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../database/drift_database.dart' as db;
import '../config/app_config.dart';
import 'email_service.dart';

class AuthService {
  final db.AppDatabase _db;
  final EmailService? _emailService;

  AuthService(this._db, [this._emailService]);

  supabase.SupabaseClient? get _supabaseClient =>
      AppConfig.isCloudAuthConfigured ? supabase.Supabase.instance.client : null;

  bool get _cloudAuthEnabled => _supabaseClient != null;

  Future<void> _upsertLocalUser({
    required String email,
    required String username,
    String? fullName,
  }) async {
    final existing = await _db.getUserByEmail(email);

    if (existing != null) {
      await (_db.update(_db.users)..where((t) => t.id.equals(existing.id))).write(
        db.UsersCompanion(
          email: Value(email),
          username: Value(username),
          fullName: Value(fullName),
        ),
      );
      return;
    }

    await _db.registerUser(
      db.UsersCompanion.insert(
        username: username,
        email: Value(email),
        fullName: Value(fullName),
        passwordHash: const Value('cloud_auth'),
      ),
    );
  }

  Future<({bool success, String message})> sendOtp(String email) async {
    if (!_cloudAuthEnabled) {
      return (success: false, message: AppConfig.cloudAuthHelpText);
    }

    try {
      final client = _supabaseClient;
      if (client == null) return (success: false, message: 'Cloud auth disabled');
      await client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: true,
      );
      return (success: true, message: 'OTP sent to $email');
    } catch (e) {
      return (success: false, message: 'Error: $e');
    }
  }

  Future<({bool success, String message, db.User? user})> verifyOtp(
    String email,
    String code,
  ) async {
    final client = _supabaseClient;
    if (client == null) return (success: false, message: 'Cloud auth disabled', user: null);

    try {
      final response = await client.auth.verifyOTP(
        email: email,
        token: code,
        type: supabase.OtpType.email,
      );

      final user = response.user;
      if (user == null) return (success: false, message: 'Verification failed', user: null);

      final username = user.userMetadata?['username'] ?? email.split('@').first;
      await _upsertLocalUser(email: email, username: username);

      final localUser = await _db.getUserByEmail(email);
      return (success: true, message: 'Verified', user: localUser);
    } catch (e) {
      return (success: false, message: 'Error: $e', user: null);
    }
  }

  Future<({bool success, String message, db.User? user})> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
  }) async {
    if (!_cloudAuthEnabled) return (success: false, message: 'Cloud auth disabled', user: null);

    try {
      final response = await _supabaseClient!.auth.signUp(
        email: email,
        password: password,
        data: {'username': username, 'full_name': fullName},
      );

      if (response.user == null) return (success: false, message: 'Signup failed', user: null);

      await _upsertLocalUser(email: email, username: username, fullName: fullName);
      final localUser = await _db.getUserByEmail(email);
      return (success: true, message: 'Registered', user: localUser);
    } catch (e) {
      return (success: false, message: 'Error: $e', user: null);
    }
  }

  Future<({bool success, String message, db.User? user})> login({
    required String email,
    required String password,
  }) async {
    if (!_cloudAuthEnabled) return (success: false, message: 'Cloud auth disabled', user: null);

    try {
      final response = await _supabaseClient!.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) return (success: false, message: 'Login failed', user: null);

      final user = response.user!;
      final username = user.userMetadata?['username'] ?? email.split('@').first;
      await _upsertLocalUser(email: email, username: username);

      final localUser = await _db.getUserByEmail(email);
      
      // Check 2FA
      if (localUser != null && (localUser as dynamic).isTwoFactorEnabled == true) {
        return (success: true, message: '2FA_REQUIRED', user: localUser);
      }

      return (success: true, message: 'Logged in', user: localUser);
    } catch (e) {
      return (success: false, message: 'Error: $e', user: null);
    }
  }

  Future<db.User?> tryAutoLogin() async {
    if (!_cloudAuthEnabled) return null;
    final session = _supabaseClient!.auth.currentSession;
    if (session == null) return null;

    final email = session.user.email;
    if (email == null) return null;

    return await _db.getUserByEmail(email);
  }

  Future<void> logout() async {
    if (_cloudAuthEnabled) {
      await _supabaseClient!.auth.signOut();
    }
  }

  Future<({bool success, String message})> deleteAccount() async {
    if (!_cloudAuthEnabled) return (success: false, message: 'Cloud auth disabled');
    try {
      // 1. Clear local data
      await _db.clearAllProgress();
      // 2. Sign out
      await logout();
      return (success: true, message: 'Data cleared and signed out');
    } catch (e) {
      return (success: false, message: 'Error: $e');
    }
  }

  static const Duration _otpLifetime = Duration(minutes: 10);

  String? _pending2FACode;
  DateTime? _pending2FAExpiry;

  Future<({bool success, String message})> send2FAEmail(String email) async {
    final service = _emailService;
    if (service == null) return (success: false, message: 'Email service missing');
    final otp = _generateOtp();
    _pending2FACode = otp;
    _pending2FAExpiry = DateTime.now().add(_otpLifetime);
    final res = await service.sendOtpEmail(to: email, otp: otp, purpose: '2FA');
    return (success: res.success, message: res.message);
  }

  Future<({bool success, String message, db.User? user})> verify2FA(String email, String code) async {
    final pendingCode = _pending2FACode;
    final expiry = _pending2FAExpiry;

    if (pendingCode == null ||
        expiry == null ||
        DateTime.now().isAfter(expiry)) {
      _pending2FACode = null;
      _pending2FAExpiry = null;
      return (success: false, message: 'Code expired. Please request a new one.', user: null);
    }

    if (code != pendingCode) {
      return (success: false, message: 'Invalid code', user: null);
    }

    _pending2FACode = null;
    _pending2FAExpiry = null;
    final user = await _db.getUserByEmail(email);
    return (success: true, message: 'Verified', user: user);
  }

  String _generateOtp() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<({bool success, String message})> resetPassword(String email) async {
    if (!_cloudAuthEnabled) return (success: false, message: 'Cloud auth disabled');
    try {
      await _supabaseClient!.auth.resetPasswordForEmail(email);
      return (success: true, message: 'Reset link sent');
    } catch (e) {
      return (success: false, message: 'Error: $e');
    }
  }
}
