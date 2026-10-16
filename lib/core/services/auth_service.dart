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
import '../database/tables/consent_records_table.dart';
import '../config/app_config.dart';
import 'email_service.dart';
import '../utils/password_policy.dart';

/// Shared marker written to `users.passwordHash` for accounts that can only
/// authenticate through a federated provider.
///
/// Single source of truth for three call sites that previously disagreed:
/// `AuthService.login` (friendly "use Google" branch), `createUserFromCloud`
/// (previously wrote `''`) and `GoogleAuthService` (previously wrote
/// `'google_auth'`). Divergence meant the friendly branch only fired for one of
/// the two creation paths.
const String kGooglePasswordSentinel = 'google_auth';

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

    if (trimmedEmail.isEmpty) {
      return (
        success: false,
        message:
            'Enter a valid email and a password with at least ${PasswordPolicy.minLength} characters.',
        user: null,
      );
    }
    // Shared with resetPassword() so recovery cannot bypass signup rules.
    final passwordError = PasswordPolicy.validate(password);
    if (passwordError != null) {
      return (success: false, message: passwordError, user: null);
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
      // Persist acceptance. The sign-up checkbox was previously an in-memory
      // boolean, so it reset on every restart and nothing was ever written
      // down — consent could not be demonstrated after the fact. Recording the
      // exact policy version is what a store reviewer or regulator asks for.
      await _recordSignupConsent(user.id);

      // Verification email is advisory: a failed send must not block signup,
      // because the app is offline-first and the account works regardless.
      final address = user.email?.trim();
      if (address != null &&
          address.isNotEmpty &&
          _emailService != null &&
          _emailService.isConfigured) {
        try {
          await _emailService.send(
            to: address,
            template: EmailTemplate.emailVerification,
            purpose: EmailPurpose.emailVerification,
            username: user.username,
            code: _generateNumericCode(6),
          );
        } catch (_) {
          // Non-fatal.
        }
      }
    }

    return (success: true, message: 'Registered', user: user);
  }

  /// Writes the consent rows implied by a successful sign-up.
  ///
  /// The UI already gates sign-up on the checkbox, so by the time this runs the
  /// user has demonstrably accepted both documents at the current version.
  Future<void> _recordSignupConsent(int userId) async {
    for (final entry in const [
      (ConsentDocument.terms, ConsentDocument.termsVersion),
      (ConsentDocument.privacy, ConsentDocument.privacyVersion),
    ]) {
      try {
        await _db.recordConsent(userId, document: entry.$1, version: entry.$2);
      } catch (_) {
        // Never block registration on an audit write.
      }
    }
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

    // Check if account is locked
    if (await _db.isAccountLocked(user.id)) {
      return (
        success: false,
        message:
            'Account temporarily locked due to too many failed attempts. Try again in 15 minutes.',
        user: null,
      );
    }

    // Federated accounts carry the `google_auth` sentinel, not a real hash.
    // Checking for it explicitly is what turns a confusing "Incorrect
    // password" into an actionable "sign in with Google" — the account
    // genuinely has no password to mistype.
    if (user.passwordHash == kGooglePasswordSentinel ||
        user.passwordHash == null ||
        user.passwordHash!.isEmpty) {
      return (
        success: false,
        message:
            'This account was created with social sign-in. Use the original sign-in method or reset credentials.',
        user: null,
      );
    }

    final hash = _verifyPassword(password, user.passwordHash!);
    if (!hash) {
      await _db.incrementFailedLoginAttempts(user.id);
      return (success: false, message: 'Incorrect password.', user: null);
    }

    // Upgrade legacy hashes after a successful verification so old accounts
    // leave the weaker SHA-256 format without requiring a forced reset.
    if (_isLegacyPasswordHash(user.passwordHash!)) {
      await _db.updateUserPassword(user.id, _hashPassword(password));
    }

    // Reset failed attempts on successful login
    await _db.resetFailedLoginAttempts(user.id);
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

  /// Attempts to sign in with Supabase and creates/updates local user record.
  /// This enables login on a new device where the local database is empty.
  Future<({bool success, String message, db.User? user})> cloudLogin({
    required String email,
    required String password,
  }) async {
    final client = _supabaseClient;
    if (client == null) {
      return (
        success: false,
        message: 'Cloud authentication is not available.',
        user: null,
      );
    }

    try {
      final res = await client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final cloudUser = res.user;
      if (cloudUser == null) {
        return (success: false, message: 'Authentication failed.', user: null);
      }

      // Check if local user exists for this email
      final trimmedEmail = email.trim().toLowerCase();
      var localUser = await _db.getUserByEmail(trimmedEmail);

      if (localUser == null) {
        // Create new local user from cloud user
        final username = cloudUser.email?.split('@').first ?? 'user';
        final created = await _db.createUserFromCloud(
          email: trimmedEmail,
          username: username,
          supabaseId: cloudUser.id,
          fullName: cloudUser.userMetadata?['full_name'] as String?,
        );
        if (created == null) {
          return (
            success: false,
            message: 'Failed to create local user.',
            user: null,
          );
        }
        localUser = created;
      } else if (localUser.supabaseId != cloudUser.id) {
        // Link existing local user to cloud identity
        await _db.setSupabaseId(localUser.id, cloudUser.id);
        localUser = (await _db.getUserById(localUser.id))!;
      }

      // Sync profile
      await _upsertCloudProfile(client, localUser);

      await _db.updateLastLogin(localUser.id);
      await saveSession(localUser.id);

      return (success: true, message: 'Logged in via cloud', user: localUser);
    } on supabase.AuthException catch (e) {
      return (success: false, message: e.message, user: null);
    } catch (e) {
      return (success: false, message: 'Cloud login failed: $e', user: null);
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
    await deleteCloudAccountBySupabaseId(supabaseId);
  }

  /// Deletes the caller's cloud account via the `delete-account` Edge Function.
  ///
  /// Returns `true` when the cloud account was removed, `false` when the
  /// attempt failed. It deliberately does **not** throw.
  ///
  /// ## Why this must not throw
  /// The caller (see `AuthNotifier.deleteAccount`) must be able to wipe the
  /// local database even when the cloud call fails. The previous version threw
  /// on any non-200, and that exception propagated out of the notifier's `try`
  /// before `clearAllUserData()` ran — so a user with a `supabaseId` but an
  /// expired session, or an outage, could never delete their own local data.
  /// That is a data-retention problem, not a cosmetic one.
  ///
  /// The caller is expected to surface [message] so the user knows the cloud
  /// copy may still exist and should retry.
  Future<({bool success, String? message})> deleteCloudAccountBySupabaseId(
    String supabaseId,
  ) async {
    final client = _supabaseClient;
    if (client == null) {
      return (
        success: false,
        message: 'Cloud deletion is unavailable. Local data was removed.',
      );
    }

    // The Edge Function derives the target from the caller's JWT; the
    // supabaseId argument is retained only so callers keep their existing
    // signature and so an unlinked local account can short-circuit.
    if (supabaseId.isEmpty) {
      return (success: true, message: null);
    }

    try {
      final response = await client.functions.invoke('delete-account');
      if (response.status == 200) {
        return (success: true, message: null);
      }
      return (
        success: false,
        message:
            'Cloud account deletion failed (${response.status}). '
            'Your local data was removed; retry to finish deleting the '
            'cloud copy.',
      );
    } catch (error) {
      return (
        success: false,
        message:
            'Could not reach the cloud account service. '
            'Your local data was removed; retry to finish deleting the '
            'cloud copy.',
      );
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
    // ── Anti-enumeration ───────────────────────────────────────────────────
    // Every branch below must return the SAME message and the SAME success
    // value, otherwise this endpoint becomes an account-existence oracle: the
    // auth screen renders `message` verbatim, so any wording difference is
    // observable.
    //
    // It previously leaked four distinguishable states — unknown email, sent,
    // throttled, and "not configured" — which defeated the "don't reveal whether
    // email exists" intent that sat right above it in the source.
    const acknowledgement =
        'If an account exists for that email, a reset code has been sent.';

    // ── 1. Build-level check, before any account lookup ────────────────────
    // "This build has no email backend" is a fact about the *binary*, not the
    // account, so answering it identically for everyone leaks nothing. Checking
    // it after the lookup would turn it into an oracle: unknown → generic,
    // known → "not configured".
    if (_emailService == null || !_emailService.isConfigured) {
      return (
        success: false,
        message:
            'Email is not set up on this build, so a code cannot be sent. '
            'Use Google sign-in, or contact support.',
      );
    }

    final trimmedEmail = email.trim().toLowerCase();
    final user = await _db.getUserByEmail(trimmedEmail);

    // Unknown account: acknowledge and send nothing.
    if (user == null) return (success: true, message: acknowledgement);

    // A federated or unlinked account has no local password to reset. Same
    // answer, otherwise this endpoint enumerates which addresses use Google.
    if (user.passwordHash == kGooglePasswordSentinel ||
        user.passwordHash == null ||
        user.passwordHash!.isEmpty) {
      return (success: true, message: acknowledgement);
    }

    // ── 2. Resend cooldown ────────────────────────────────────────────────
    // Necessary for abuse control, and unavoidably a stronger signal than mere
    // existence — but it is only reachable *after* the account is known, so it
    // cannot be used to discover whether an address is registered.
    if (await _db.isPasswordResetResendThrottled(
      user.id,
      cooldown: _otpResendCooldown,
    )) {
      return (
        success: false,
        message:
            'Please wait before requesting another code. '
            'If you did not request it, you can ignore this.',
      );
    }

    final code = _generateNumericCode(6);
    final expiry = DateTime.now().add(_resetCodeTTL);

    try {
      final result = await _emailService.send(
        to: trimmedEmail,
        template: EmailTemplate.passwordReset,
        purpose: EmailPurpose.passwordReset,
        username: user.username,
        code: code,
      );
      if (!result.success) {
        return (success: false, message: result.message);
      }
    } catch (e) {
      return (
        success: false,
        message: 'Could not send reset email. Please try again later.',
      );
    }

    await _db.updateUserPasswordReset(user.id, code, expiry);
    await _db.markPasswordResetSent(user.id);
    // Identical to the unknown-account answer. Echoing the address back —
    // "Reset code sent to real@example.com" — confirmed existence, which is
    // exactly what the generic wording above exists to prevent.
    return (success: true, message: acknowledgement);
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

    // Enforces the guess budget and lockout — same threat model as 2FA.
    final outcome = await _db.verifyPasswordResetCode(
      user.id,
      code,
      maxAttempts: _otpMaxAttempts,
      lockout: _otpLockout,
    );
    if (outcome != db.OtpAttemptOutcome.verified) {
      // Identical message for wrong code and for lockout, so an attacker
      // cannot use the response to learn whether guesses are landing.
      return (
        success: false,
        message: 'Invalid or expired reset code.',
        user: null,
      );
    }

    final passwordError = PasswordPolicy.validate(newPassword);
    if (passwordError != null) {
      return (success: false, message: passwordError, user: null);
    }

    final passwordHash = _hashPassword(newPassword);
    await _db.updateUserPassword(user.id, passwordHash);
    await _db.clearPasswordReset(user.id);

    // Also update cloud password if user has a Supabase identity
    final client = _supabaseClient;
    if (client != null &&
        user.supabaseId != null &&
        user.supabaseId!.isNotEmpty) {
      try {
        await client.auth.updateUser(
          supabase.UserAttributes(password: newPassword),
        );
        // Sign out other sessions so a token stolen before the reset stops
        // working. Without this, resetting a password after a compromise leaves
        // the attacker's live session valid — the victim locks the door while
        // the intruder is still inside.
        //
        // Best-effort: the local password is already changed, and failing to
        // revoke must not fail the reset.
        await client.auth.signOut();
      } catch (e) {
        developer.log('Cloud password update/sign-out skipped: $e');
      }
    }

    // Tell the owner their password changed. A reset is the standard moment to
    // alert the legitimate user; without it, a silent reset is indistinguishable
    // from an attacker's.
    if (_emailService != null && _emailService.isConfigured) {
      try {
        await _emailService.send(
          to: trimmedEmail,
          template: EmailTemplate.securityNotice,
          purpose: EmailPurpose.securityNotice,
          username: user.username,
        );
      } catch (_) {
        // Notification is advisory; never block the reset on it.
      }
    }

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
      return (success: false, message: 'Email is not set up on this build.');
    }

    // Resend cooldown.
    //
    // This path previously had no throttle and never recorded a send, unlike
    // `sendPasswordReset` and `sendLogin2FAEmail`. Because it is keyed on an
    // arbitrary email string that the caller supplies, and because it wrote a
    // fresh code on every call, it was an unbounded amplifier: anyone who knew
    // a registered address could drive unlimited transactional mail at the
    // provider's cost and churn the live code indefinitely.
    if (await _db.isTwoFactorResendThrottled(
      user.id,
      cooldown: _otpResendCooldown,
    )) {
      return (
        success: false,
        message:
            'Please wait before requesting another code. '
            'If you did not request it, you can ignore this.',
      );
    }

    final code = _generateNumericCode(_twoFactorCodeLength);
    final expiry = DateTime.now().add(_twoFactorCodeTTL);

    final result = await _emailService.send(
      to: trimmedEmail,
      template: EmailTemplate.twoFactorEnable,
      purpose: EmailPurpose.twoFactorEnable,
      username: user.username,
      code: code,
    );
    if (!result.success) {
      return (success: false, message: result.message);
    }

    await _db.setTwoFactorCode(user.id, code, expiry);
    await _db.markTwoFactorSent(user.id);
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

    // Pass the explicit guess budget rather than relying on the database
    // defaults: those happened to equal _otpMaxAttempts/_otpLockout, so this
    // was silently diverging the moment either constant changed.
    final active = await _db.verifyTwoFactorCode(
      user.id,
      code,
      maxAttempts: _otpMaxAttempts,
      lockout: _otpLockout,
    );
    if (active != db.OtpAttemptOutcome.verified) {
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

    // A federated or unlinked row may have no email at all — GoogleAuthService
    // deliberately inserts `email: null` for a collision-avoidance bucket.
    // Force-unwrapping here would crash for exactly those accounts.
    final recipient = user.email?.trim() ?? '';
    if (recipient.isEmpty) {
      return (
        success: false,
        message:
            'This account has no email address on file, so a verification code '
            'cannot be sent.',
        user: null,
      );
    }

    if (_emailService == null || !_emailService.isConfigured) {
      return (
        success: false,
        message: 'Email is not set up on this build.',
        user: null,
      );
    }

    // Resend cooldown. Without it the login flow could drive unlimited
    // transactional email against the provider (cost amplification), and a live
    // code is exactly what the guess budget below protects.
    if (await _db.isTwoFactorResendThrottled(
      userId,
      cooldown: _otpResendCooldown,
    )) {
      return (
        success: false,
        message:
            'Please wait before requesting another code. '
            'If you did not request it, you can ignore this.',
        user: null,
      );
    }

    final code = _generateNumericCode(_twoFactorCodeLength);
    final expiry = DateTime.now().add(_twoFactorCodeTTL);

    final result = await _emailService.send(
      to: recipient,
      template: EmailTemplate.loginVerification,
      purpose: EmailPurpose.loginVerification,
      username: user.username,
      code: code,
    );
    if (!result.success) {
      return (success: false, message: result.message, user: null);
    }

    await _db.setTwoFactorCode(user.id, code, expiry);
    await _db.markTwoFactorSent(userId);
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

    // Enforces the guess budget and lockout. A 6-digit code has 10^6 candidates;
    // without this the local database alone was enough to brute force it, and
    // every miss was free to repeat.
    final outcome = await _db.verifyTwoFactorCode(
      userId,
      code,
      maxAttempts: _otpMaxAttempts,
      lockout: _otpLockout,
    );

    if (outcome != db.OtpAttemptOutcome.verified) {
      // Deliberately identical message for a wrong code and for a lockout:
      // distinguishing them would tell an attacker their guesses are landing.
      return (success: false, message: 'Invalid or expired code.', user: null);
    }

    await _db.clearTwoFactorCode(userId);
    await _db.updateLastLogin(user.id);
    final updated = await _db.getUserById(userId);
    return (success: true, message: 'Verified.', user: updated);
  }

  // ============= INTERNALS =============

  // ---------------------------------------------------------------------------
  // OTP throttling policy (2FA codes and password-reset codes).
  //
  // A 6-digit code is only 10^6 candidates and the hash lives in a local
  // SQLite file, so both code paths need a bounded guess budget, a lockout, and
  // a resend cooldown. Without these, OTP verification was an unlimited oracle.
  // ---------------------------------------------------------------------------

  /// Wrong guesses tolerated against a live code before lockout.
  static const int _otpMaxAttempts = 5;

  /// How long guessing stays blocked after the budget is exhausted.
  static const Duration _otpLockout = Duration(minutes: 15);

  /// Minimum gap between two code sends to the same account.
  static const Duration _otpResendCooldown = Duration(seconds: 60);

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

  /// True when [stored] uses the pre-PBKDF2 scheme, which must be rehashed on
  /// the next successful sign-in.
  static bool _isLegacyPasswordHash(String stored) =>
      !stored.startsWith('pbkdf2-sha256\$');

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

  // NOTE: `_buildResetEmailHtml` and `_build2FAEmailHtml` were removed.
  //
  // Both interpolated `users.username` into HTML **unescaped**, so a username of
  // `<img src=x onerror=…>` rendered as markup in every password-reset and 2FA
  // email the app delivered. `EmailService.escapeHtml` existed but was applied
  // only to `sendWelcomeEmail`, which nothing called.
  //
  // HTML now lives entirely in the `send-email` Edge Function and travels as a
  // template *name*, so there is no client-side path that can interpolate user
  // text into a security email. See EmailService.send and EmailTemplate.
}
