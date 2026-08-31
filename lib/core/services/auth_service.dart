import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../database/drift_database.dart' as db;
import '../config/app_config.dart';
import 'email_service.dart';

class AuthService {
  final db.AppDatabase _db;
  final EmailService? _emailService;
  static const _resetCodeTTL = Duration(minutes: 15);
  static const _twoFactorCodeTTL = Duration(minutes: 15);
  static const int _twoFactorCodeLength = 6;

  AuthService(this._db, [this._emailService]);

  Future<({bool success, String message, db.User? user})> register({
    required String email,
    required String password,
    String? username,
    String? fullName,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    final trimmedUsername = (username ?? trimmedEmail.split('@').first).trim();

    if (trimmedEmail.isEmpty || password.length < 6) {
      return (
        success: false,
        message:
            'Enter a valid email and a password with at least 6 characters.',
        user: null,
      );
    }

    final existing = await _db.getUserByEmail(trimmedEmail);
    if (existing != null) {
      return (
        success: false,
        message: 'An account with this email already exists.',
        user: null,
      );
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

    if (user != null) {
      unawaited(
        _syncAccountToCloud(
          localUserId: user.id,
          email: trimmedEmail,
          password: password,
        ),
      );
    }

    return (success: true, message: 'Registered', user: user);
  }

  Future<({bool success, String message, db.User? user})> login({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();

    final user = await _db.getUserByEmail(trimmedEmail);
    if (user == null) {
      return (
        success: false,
        message: 'No account found for this email.',
        user: null,
      );
    }

    if (user.passwordHash == null || user.passwordHash!.isEmpty) {
      return (
        success: false,
        message:
            'This account was created with social sign-in. Use the original sign-in method or reset credentials.',
        user: null,
      );
    }

    final hash = _verifyPassword(password, user.passwordHash!);
    if (!hash) {
      return (success: false, message: 'Incorrect password.', user: null);
    }

    await _db.updateLastLogin(user.id);
    final updated = await _db.getUserById(user.id);

    unawaited(
      _syncAccountToCloud(
        localUserId: user.id,
        email: trimmedEmail,
        password: password,
      ),
    );

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

    // Provision anything missed earlier (e.g. Supabase was still initializing
    // when the account was registered) once a session is restored.
    unawaited(_syncProfileFromSession(user));
    return user;
  }

  Future<void> logout() async {
    await _clearSession();
    await _signOutCloud();
  }

  /// The cloud client is best-effort: only present when credentials are
  /// configured (`.env`) *and* `Supabase.initialize` has completed. Calls that
  /// depend on it must tolerate it being null (offline-first).
  supabase.SupabaseClient? get _supabaseClient {
    if (!AppConfig.enableCloudAuth) return null;
    try {
      return supabase.Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> _signOutCloud() async {
    final client = _supabaseClient;
    if (client == null) return;
    try {
      await client.auth.signOut();
    } catch (e) {
      developer.log('Cloud sign-out skipped: $e');
    }
  }

  /// Ensures a Supabase auth identity exists and syncs the profile row. Used by
  /// register/login: signUp first (throws if already registered), then falls
  /// back to signInWithPassword so pre-existing/legacy accounts get linked too.
  Future<void> _syncAccountToCloud({
    required int localUserId,
    required String email,
    required String password,
  }) async {
    final client = _supabaseClient;
    if (client == null) return;

    try {
      supabase.AuthResponse res;
      try {
        res = await client.auth.signUp(email: email, password: password);
      } on supabase.AuthException {
        res = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
      final cloudUser = res.user;
      if (cloudUser == null) return;

      final localUser = await _db.getUserById(localUserId);
      if (localUser == null) return;

      if (localUser.supabaseId != cloudUser.id) {
        await _db.setSupabaseId(localUserId, cloudUser.id);
      }
      final linked = await _db.getUserById(localUserId);
      await _upsertCloudProfile(client, linked ?? localUser);
    } catch (e) {
      // Never block local auth on cloud sync problems.
      developer.log('Cloud account sync skipped: $e');
    }
  }

  /// Re-syncs the profile using the already-persisted Supabase session (no
  /// password needed); used on auto-login so accounts created while the client
  /// was still initializing get provisioned on the next launch.
  Future<void> _syncProfileFromSession(db.User user) async {
    final client = _supabaseClient;
    final supabaseId = user.supabaseId;
    if (client == null || supabaseId == null || supabaseId.isEmpty) return;
    if (client.auth.currentSession == null) return;
    try {
      await _upsertCloudProfile(client, user);
    } catch (e) {
      developer.log('Cloud profile re-sync skipped: $e');
    }
  }

  Future<void> _upsertCloudProfile(
    supabase.SupabaseClient client,
    db.User user,
  ) async {
    final supabaseId = user.supabaseId;
    if (supabaseId == null || supabaseId.isEmpty) return;
    await client.from('profiles').upsert({
      'id': supabaseId,
      'email': user.email ?? '',
      'username': user.username,
      'full_name': user.fullName,
      'two_factor_enabled': user.isTwoFactorEnabled,
      'created_at': user.createdAt.toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'id');
  }

  Future<void> deleteCloudAccount(int userId) async {
    final client = _supabaseClient;
    final user = await _db.getUserById(userId);
    final supabaseId = user?.supabaseId;
    if (client == null || supabaseId == null || supabaseId.isEmpty) return;
    try {
      await client.from('profiles').delete().eq('id', supabaseId);
    } catch (e) {
      developer.log('Cloud profile delete skipped: $e');
    }
  }

  Future<void> _syncCloudTwoFactor(int userId, bool enabled) async {
    final client = _supabaseClient;
    final user = await _db.getUserById(userId);
    final supabaseId = user?.supabaseId;
    if (client == null || supabaseId == null || supabaseId.isEmpty) return;
    try {
      await client
          .from('profiles')
          .update({
            'two_factor_enabled': enabled,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', supabaseId);
    } catch (e) {
      developer.log('2FA flag sync skipped: $e');
    }
  }

  Future<({bool success, String message})> sendPasswordReset({
    required String email,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    final user = await _db.getUserByEmail(trimmedEmail);
    if (user == null) {
      // Don't reveal whether email exists.
      return (
        success: true,
        message: 'If an account exists, a reset code has been sent.',
      );
    }

    if (_emailService == null || !_emailService.isConfigured) {
      return (
        success: false,
        message: 'Password reset email is not configured in Settings.',
      );
    }

    final code = _generateNumericCode(6);
    final expiry = DateTime.now().add(_resetCodeTTL);

    try {
      await _emailService.sendTransactionalEmail(
        to: trimmedEmail,
        subject: 'Reset your NEET Mitos password',
        html: _buildResetEmailHtml(user.username, code),
        text:
            'Your NEET Mitos password reset code is: $code. It expires in 15 minutes.',
      );
    } catch (e) {
      return (
        success: false,
        message: 'Could not send reset email. Please try again later.',
      );
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
        !_constantTimeEquals(reset.code, code) ||
        reset.expiresAt.isBefore(DateTime.now())) {
      return (
        success: false,
        message: 'Invalid or expired reset code.',
        user: null,
      );
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

  Future<({bool success, String message})> enable2FA(String email) async {
    final trimmedEmail = email.trim().toLowerCase();
    final user = await _db.getUserByEmail(trimmedEmail);
    if (user == null) {
      return (success: false, message: 'Account not found.');
    }

    if (_emailService == null || !_emailService.isConfigured) {
      return (
        success: false,
        message: 'Email service is not configured in Settings.',
      );
    }

    final code = _generateNumericCode(_twoFactorCodeLength);
    final expiry = DateTime.now().add(_twoFactorCodeTTL);

    try {
      await _emailService.sendTransactionalEmail(
        to: trimmedEmail,
        subject: 'Enable two-factor authentication for NEET Mitos',
        html: _build2FAEmailHtml(user.username, code, 'enable'),
        text:
            'Your NEET Mitos 2FA verification code is: $code. It expires in 15 minutes.',
      );
    } catch (e) {
      return (
        success: false,
        message: 'Could not send email. Please try again later.',
      );
    }

    await _db.setTwoFactorCode(user.id, code, expiry);
    return (success: true, message: 'Verification code sent to $trimmedEmail');
  }

  Future<({bool success, String message})> confirmEnable2FA(
    String email,
    String code,
  ) async {
    final trimmedEmail = email.trim().toLowerCase();
    final user = await _db.getUserByEmail(trimmedEmail);
    if (user == null) {
      return (success: false, message: 'Account not found.');
    }

    final active = await _db.getActiveTwoFactorCode(user.id);
    if (active == null || !_constantTimeEquals(active.code, code)) {
      return (success: false, message: 'Invalid or expired verification code.');
    }

    await _db.updateTwoFactorStatus(user.id, true);
    await _db.clearTwoFactorCode(user.id);
    unawaited(_syncCloudTwoFactor(user.id, true));
    return (success: true, message: 'Two-factor authentication enabled.');
  }

  Future<({bool success, String message})> disable2FA(int userId) async {
    await _db.updateTwoFactorStatus(userId, false);
    await _db.clearTwoFactorCode(userId);
    unawaited(_syncCloudTwoFactor(userId, false));
    return (success: true, message: 'Two-factor authentication disabled.');
  }

  Future<({bool success, String message, db.User? user})> sendLogin2FAEmail(
    int userId,
  ) async {
    final user = await _db.getUserById(userId);
    if (user == null) {
      return (success: false, message: 'User not found.', user: null);
    }

    if (_emailService == null || !_emailService.isConfigured) {
      return (
        success: false,
        message: 'Email service is not configured.',
        user: null,
      );
    }

    final code = _generateNumericCode(_twoFactorCodeLength);
    final expiry = DateTime.now().add(_twoFactorCodeTTL);

    try {
      await _emailService.sendTransactionalEmail(
        to: user.email!,
        subject: 'Your NEET Mitos login verification code',
        html: _build2FAEmailHtml(user.username, code, 'login'),
        text: 'Your NEET Mitos login code is: $code. It expires in 15 minutes.',
      );
    } catch (e) {
      return (
        success: false,
        message: 'Could not send verification email.',
        user: null,
      );
    }

    await _db.setTwoFactorCode(user.id, code, expiry);
    return (success: true, message: 'Verification code sent.', user: user);
  }

  Future<({bool success, String message, db.User? user})> verifyLogin2FA(
    int userId,
    String code,
  ) async {
    final user = await _db.getUserById(userId);
    if (user == null) {
      return (success: false, message: 'User not found.', user: null);
    }

    final active = await _db.getActiveTwoFactorCode(userId);
    if (active == null || !_constantTimeEquals(active.code, code)) {
      return (success: false, message: 'Invalid or expired code.', user: null);
    }

    await _db.clearTwoFactorCode(userId);
    await _db.updateLastLogin(user.id);
    final updated = await _db.getUserById(userId);
    return (success: true, message: 'Verified.', user: updated);
  }

  // ============= INTERNALS =============

  // ---------------------------------------------------------------------------
  // Password hashing: PBKDF2-HMAC-SHA256 with a random per-user salt.
  // Stored format: "pbkdf2-sha256$<iterations>$<base64salt>$<base64key>".
  // Legacy "sha256('neet_mitos_local:$password')" hashes remain verifiable so
  // accounts created before this change can still sign in.
  // ---------------------------------------------------------------------------
  static const int _pbkdf2Iterations = 600000;
  static const int _saltLength = 16;
  static const int _keyLength = 32;

  static String _hashPassword(String password) {
    final salt = _randomBytes(_saltLength);
    final key = _pbkdf2Sha256(
      utf8.encode(password),
      salt,
      _pbkdf2Iterations,
      _keyLength,
    );
    return 'pbkdf2-sha256\$$_pbkdf2Iterations\$'
        '${base64Encode(salt)}\$${base64Encode(key)}';
  }

  static bool _verifyPassword(String password, String stored) {
    final parts = stored.split('\$');
    if (parts.length == 4 && parts[0] == 'pbkdf2-sha256') {
      final iterations = int.tryParse(parts[1]) ?? _pbkdf2Iterations;
      final salt = base64Decode(parts[2]);
      final expected = base64Decode(parts[3]);
      final actual = _pbkdf2Sha256(
        utf8.encode(password),
        salt,
        iterations,
        expected.length,
      );
      return _constantTimeEqualsBytes(expected, actual);
    }

    // Legacy format: plain SHA-256 of "neet_mitos_local:$password".
    final legacy = sha256.convert(utf8.encode('neet_mitos_local:$password'));
    return _constantTimeEquals(legacy.toString(), stored);
  }

  static List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  static List<int> _pbkdf2Sha256(
    List<int> password,
    List<int> salt,
    int iterations,
    int keyLength,
  ) {
    final hmac = Hmac(sha256, password);
    final numBlocks = (keyLength / 32).ceil();
    final output = <int>[];

    for (var block = 1; block <= numBlocks; block++) {
      final blockIndexBytes = ByteData(4)..setUint32(0, block, Endian.big);
      final blockIndex = blockIndexBytes.buffer.asUint8List();
      final u0 = hmac.convert([...salt, ...blockIndex]).bytes;
      var u = List<int>.from(u0);
      final t = List<int>.from(u);

      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      output.addAll(t);
    }
    return output.sublist(0, keyLength);
  }

  static bool _constantTimeEqualsBytes(List<int> a, List<int> b) {
    var result = a.length ^ b.length;
    final maxLen = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < maxLen; i++) {
      result |= (i < a.length ? a[i] : 0) ^ (i < b.length ? b[i] : 0);
    }
    return result == 0;
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
    final random = Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(random.nextInt(10));
    }
    return buffer.toString();
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

  String _build2FAEmailHtml(String username, String code, String purpose) {
    final title = purpose == 'enable'
        ? 'Enable two-factor authentication'
        : 'Login verification';
    final body = purpose == 'enable'
        ? 'Use this code to enable two-factor authentication on your NEET Mitos account:'
        : 'Use this code to verify your login:';

    return '''
      <div style="font-family: Arial, sans-serif; color: #1f2937;">
        <h2 style="color: #2563eb;">$title</h2>
        <p>Hi $username,</p>
        <p>$body</p>
        <p style="font-size: 28px; font-weight: 700; letter-spacing: 4px; color: #111827;">$code</p>
        <p>This code expires in 15 minutes. If you did not request this, you can ignore this message.</p>
      </div>
    ''';
  }
}
