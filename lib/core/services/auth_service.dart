import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/drift_database.dart' as db;
import '../config/app_config.dart';
import 'email_service.dart';

class AuthService {
  final db.AppDatabase _db;
  final EmailService? _emailService;
  static const _resetCodeTTL = Duration(minutes: 15);

  AuthService(this._db, [this._emailService]);

  Future<({bool success, String message, db.User? user})> register({
    required String email,
    required String password,
    String? username,
    String? fullName,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    final trimmedUsername =
        (username ?? trimmedEmail.split('@').first).trim();

    if (trimmedEmail.isEmpty || password.length < 6) {
      return (success: false, message: 'Enter a valid email and a password with at least 6 characters.', user: null);
    }

    final existing = await _db.getUserByEmail(trimmedEmail);
    if (existing != null) {
      return (success: false, message: 'An account with this email already exists.', user: null);
    }

    final passwordHash = _hashPassword(password);
    final now = DateTime.now();

    final user = await _db.registerUser(
      db.UsersCompanion.insert(
        email: Value(trimmedEmail),
        username: trimmedUsername,
        fullName: Value(fullName),
        passwordHash: Value(passwordHash),
        createdAt: Value(now),
        lastLogin: Value(now),
      ),
    );

    return (success: true, message: 'Registered', user: user);
  }

  Future<({bool success, String message, db.User? user})> login({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();

    final user = await _db.getUserByEmail(trimmedEmail);
    if (user == null) {
      return (success: false, message: 'No account found for this email.', user: null);
    }

    if (user.passwordHash == null || user.passwordHash!.isEmpty) {
      return (success: false, message: 'This account was created with social sign-in. Use the original sign-in method or reset credentials.', user: null);
    }

    final hash = _hashPassword(password);
    if (!_constantTimeEquals(hash, user.passwordHash!)) {
      return (success: false, message: 'Incorrect password.', user: null);
    }

    await _db.updateLastLogin(user.id);
    final updated = await _db.getUserById(user.id);
    return (success: true, message: 'Logged in', user: updated);
  }

  Future<db.User?> tryAutoLogin() async {
    final session = await _loadSession();
    if (session == null) return null;

    final user = await _db.getUserById(session['userId'] as int);
    if (user == null) {
      await _clearSession();
      return null;
    }
    return user;
  }

  Future<void> logout() async {
    await _clearSession();
  }

  Future<({bool success, String message})> sendPasswordReset({
    required String email,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    final user = await _db.getUserByEmail(trimmedEmail);
    if (user == null) {
      // Don't reveal whether email exists.
      return (success: true, message: 'If an account exists, a reset code has been sent.');
    }

    if (_emailService == null || !_emailService.isConfigured) {
      return (success: false, message: 'Password reset email is not configured in Settings.');
    }

    final code = _generateNumericCode(6);
    final expiry = DateTime.now().add(_resetCodeTTL);

    try {
      await _emailService.sendTransactionalEmail(
        to: trimmedEmail,
        subject: 'Reset your NEET Mitos password',
        html: _buildResetEmailHtml(user.username, code),
        text: 'Your NEET Mitos password reset code is: $code. It expires in 15 minutes.',
      );
    } catch (e) {
      return (success: false, message: 'Could not send reset email. Please try again later.');
    }

    await _db.updateUserPasswordReset(user.id, code, expiry);
    return (success: true, message: 'Reset code sent to $trimmedEmail');
  }

  Future<({bool success, String message, db.User? user})> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    final user = await _db.getUserByEmail(trimmedEmail);
    if (user == null) {
      return (success: false, message: 'Invalid request.', user: null);
    }

    final reset = await _db.getActivePasswordReset(user.id);
    if (reset == null ||
        reset.code != code ||
        reset.expiresAt.isBefore(DateTime.now())) {
      return (success: false, message: 'Invalid or expired reset code.', user: null);
    }

    final passwordHash = _hashPassword(newPassword);
    await _db.updateUserPassword(user.id, passwordHash);
    await _db.clearPasswordReset(user.id);

    final updated = await _db.getUserById(user.id);
    return (success: true, message: 'Password updated', user: updated);
  }

  Future<void> saveSession(int userId) async {
    final prefs = await _loadPrefs();
    await prefs.setInt('auth_user_id', userId);
  }

  // ============= INTERNALS =============

  static String _hashPassword(String password) {
    final bytes = utf8.encode('neet_mitos_local:$password');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool _constantTimeEquals(String a, String b) {
    final aBytes = utf8.encode(a);
    final bBytes = utf8.encode(b);
    var result = 0;
    for (var i = 0; i < aBytes.length && i < bBytes.length; i++) {
      result |= aBytes[i] ^ bBytes[i];
    }
    return result == 0 && aBytes.length == bBytes.length;
  }

  static String _generateNumericCode(int length) {
    final random = DateTime.now().microsecondsSinceEpoch % 1000000;
    final padded = random.toString().padLeft(6, '0');
    return padded.substring(0, length);
  }

  Future<SharedPreferences> _loadPrefs() async {
    return await AppConfig.sharedPreferences;
  }

  Future<Map<String, dynamic>?> _loadSession() async {
    final prefs = await _loadPrefs();
    final userId = prefs.getInt('auth_user_id');
    if (userId == null) return null;
    return {'userId': userId};
  }

  Future<void> _clearSession() async {
    final prefs = await _loadPrefs();
    await prefs.remove('auth_user_id');
  }

  String _buildResetEmailHtml(String username, String code) {
    return '''
      <div style="font-family: Arial, sans-serif; color: #1f2937;">
        <h2 style="color: #2563eb;">Reset your NEET Mitos password</h2>
        <p>Hi $username,</p>
        <p>Use this code to reset your password:</p>
        <p style="font-size: 28px; font-weight: 700; letter-spacing: 4px; color: #111827;">$code</p>
        <p>This code expires in 15 minutes. If you did not request this, you can ignore this message.</p>
      </div>
    ''';
  }
}
