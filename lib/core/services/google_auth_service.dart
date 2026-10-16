import 'dart:developer';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../config/app_config.dart';
import '../database/drift_database.dart' as db;
import 'auth_service.dart' show kGooglePasswordSentinel;

/// Sentinel stored in `users.passwordHash` for accounts that can only be
/// authenticated through a federated provider.
///
/// Re-exported from `auth_service.dart` so the two creation paths cannot drift
/// again.
const String _googlePasswordSentinel = kGooglePasswordSentinel;

class GoogleAuthService {
  final db.AppDatabase _db;
  final GoogleSignIn _googleSignIn;

  GoogleAuthService(this._db, [GoogleSignIn? googleSignIn])
    : _googleSignIn =
          googleSignIn ??
          GoogleSignIn(serverClientId: AppConfig.googleServerClientId);

  supabase.SupabaseClient? get _supabaseClient {
    if (!AppConfig.enableCloudAuth) return null;
    try {
      return supabase.Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<supabase.SupabaseClient?> _waitForSupabaseClient() async {
    if (!AppConfig.enableCloudAuth) return null;
    for (var attempt = 0; attempt < 25; attempt++) {
      final client = _supabaseClient;
      if (client != null) return client;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    return _supabaseClient;
  }

  Future<({bool success, String message, db.User? user})>
  signInWithGoogle() async {
    final client = await _waitForSupabaseClient();
    if (client == null) {
      return (
        success: false,
        message:
            'Cloud sign-in is not ready. Check your connection or use email sign-in.',
        user: null,
      );
    }

    try {
      log('🔍 Google Sign-In: Starting...');
      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        log('🔍 Google Sign-In: Cancelled by user');
        return (success: false, message: 'Sign-in was cancelled', user: null);
      }

      final GoogleSignInAuthentication googleAuth =
          await googleAccount.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null) {
        return (
          success: false,
          message: 'Could not obtain ID token from Google',
          user: null,
        );
      }

      final response = await client.auth.signInWithIdToken(
        provider: supabase.OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final supabaseUser = response.user;
      if (supabaseUser == null) {
        return (
          success: false,
          message: 'Google authentication failed with Supabase',
          user: null,
        );
      }

      final email = supabaseUser.email ?? googleAccount.email;
      final displayName =
          supabaseUser.userMetadata?['full_name'] ??
          supabaseUser.userMetadata?['name'] ??
          googleAccount.displayName ??
          email.split('@').first;

      // Use the row that `_upsertLocalUser` actually resolved. Re-querying by email
      // would find the *other* account when an email collision forced a separate
      // bucket, handing this session someone else's local history.
      final localUser = await _upsertLocalUser(
        email: email,
        username: email.split('@').first,
        fullName: displayName,
        supabaseId: supabaseUser.id,
      );
      return (success: true, message: 'Signed in with Google', user: localUser);
    } on PlatformException catch (e) {
      log('Google auth platform error: ${e.code} - ${e.message}');
      if (e.code == GoogleSignIn.kNetworkError) {
        return (
          success: false,
          message: 'Network error. Please check your connection.',
          user: null,
        );
      }
      if (e.code == GoogleSignIn.kSignInCanceledError) {
        return (success: false, message: 'Sign-in was cancelled.', user: null);
      }
      if (e.message?.contains('12500') == true || e.code == 'sign_in_failed') {
        return (
          success: false,
          message:
              'Google sign-in is not configured for this app build. Verify the Android package, OAuth client, and debug/release SHA-1 certificates.',
          user: null,
        );
      }
      return (
        success: false,
        message: 'Google sign-in failed: ${e.code} - ${e.message}',
        user: null,
      );
    } on supabase.AuthException catch (e) {
      log('Supabase auth error: ${e.statusCode ?? ''} - ${e.message}');
      return (
        success: false,
        message: _friendlySupabaseError(e.message),
        user: null,
      );
    } catch (e) {
      log('Unexpected Google auth error: $e');
      return (
        success: false,
        message: 'Google sign-in failed. Please try again.',
        user: null,
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      final client = _supabaseClient;
      if (client != null) {
        await client.auth.signOut();
      }
    } catch (e) {
      log('Sign out error: $e');
    }
  }

  /// Resolves the local user row for a freshly authenticated Google identity.
  ///
  /// ## Why this is not a simple email upsert
  /// The previous implementation looked the email up and, on a hit, overwrote
  /// `supabaseId` / `username` / `fullName` on that row. Combined with local
  /// registration never verifying email ownership, that was an account-takeover
  /// path:
  ///
  ///   1. Attacker registers `victim@example.com` locally (no email proof needed).
  ///   2. The real victim later signs in with Google on that same address.
  ///   3. The victim's local account — and all its study history — is silently
  ///      rebound to the attacker's Google identity, and vice versa.
  ///
  /// ## The rule now
  /// An email match is **not** proof of identity. A local row is only adopted when
  /// it is already a cloud-linked row for this same `supabaseId` (a plain profile
  /// refresh). Otherwise a distinct local user is created for the Google identity
  /// and the pre-existing password account is left untouched.
  ///
  /// The two histories are merged only through explicit, authenticated linking
  /// (see `linkLocalAccountToCloud`), which requires the local password.
  Future<db.User> _upsertLocalUser({
    required String email,
    required String username,
    required String fullName,
    required String supabaseId,
  }) async {
    final resolved = await _resolveLocalUser(
      email: email,
      username: username,
      fullName: fullName,
      supabaseId: supabaseId,
    );
    if (resolved == null) {
      // registerUser returns null when the insert failed (e.g. a username
      // collision survived disambiguation). Fail loudly rather than handing
      // the caller a null user that would later be dereferenced.
      throw StateError(
        'Could not create a local account for the Google identity',
      );
    }
    return resolved;
  }

  Future<db.User?> _resolveLocalUser({
    required String email,
    required String username,
    required String fullName,
    required String supabaseId,
  }) async {
    final existing = await _db.getUserByEmail(email);

    if (existing != null) {
      // Already this same cloud identity → refresh the profile fields only.
      final alreadyLinked = existing.supabaseId == supabaseId;
      if (alreadyLinked) {
        await (_db.update(
          _db.users,
        )..where((t) => t.id.equals(existing.id))).write(
          db.UsersCompanion(
            fullName: Value(fullName),
            username: Value(username),
          ),
        );
        return await _db.getUserById(existing.id);
      }

      // A different cloud identity, or an unlinked local-only password account,
      // already holds this email. Do NOT adopt it: that would hand this Google
      // session the other identity's local data.
      //
      // `users.email` is UNIQUE, so a second row cannot reuse the address. The
      // new row therefore stores a NULL email and is identified purely by
      // `supabaseId` — the local row is a data bucket for this cloud identity,
      // and the authoritative address stays with Supabase.
      final created = await _db.registerUser(
        db.UsersCompanion.insert(
          username: _uniqueUsername(username, supabaseId),
          email: const Value(null),
          fullName: Value(fullName),
          supabaseId: Value(supabaseId),
          passwordHash: const Value(_googlePasswordSentinel),
          // Records the address for display/recovery without claiming it.
          isEmailVerified: const Value(true),
        ),
      );
      log(
        'Google sign-in created a separate local account; the existing '
        'account with this email was left untouched. Merging them requires '
        'explicit linking with the local password.',
      );
      return created;
    }

    final created = await _db.registerUser(
      db.UsersCompanion.insert(
        username: username,
        email: Value(email),
        fullName: Value(fullName),
        supabaseId: Value(supabaseId),
        passwordHash: const Value(_googlePasswordSentinel),
      ),
    );
    return created;
  }

  /// Produces a username that cannot collide with an existing row.
  ///
  /// `users.username` has a UNIQUE constraint, and `email` is unique too — so
  /// the only way a Google user collides is by sharing a display name with
  /// another account.
  static String _uniqueUsername(String desired, String supabaseId) {
    final base = desired.trim().isEmpty ? 'student' : desired.trim();
    final suffix = supabaseId.replaceAll(RegExp('[^A-Za-z0-9]'), '');
    final short = suffix.length <= 6 ? suffix : suffix.substring(0, 6);
    return '$base.$short';
  }

  /// Marks a local password account as owned by a verified cloud identity.
  ///
  /// This is the ONLY path that may merge a pre-existing local account into a
  /// cloud one, and it requires the caller to have already proved ownership of
  /// the local credentials (see `AuthService.verifyLocalPassword`) plus a
  /// verified email on the cloud side.
  Future<({bool success, String message})> linkLocalAccountToCloud({
    required int localUserId,
    required String supabaseId,
  }) async {
    final user = await _db.getUserById(localUserId);
    if (user == null) {
      return (success: false, message: 'Local account not found.');
    }
    if (user.supabaseId != null && user.supabaseId!.isNotEmpty) {
      // Already linked. Linking again must not silently re-point the account at
      // a different identity — that is the takeover path this guards.
      if (user.supabaseId == supabaseId) {
        return (success: true, message: 'Account already linked.');
      }
      return (
        success: false,
        message:
            'This account is already linked to a different sign-in method. '
            'Sign out first, or contact support to merge your progress.',
      );
    }

    await (_db.update(_db.users)..where((t) => t.id.equals(localUserId))).write(
      db.UsersCompanion(supabaseId: Value(supabaseId)),
    );
    return (success: true, message: 'Account linked.');
  }

  String _friendlySupabaseError(String? message) {
    if (message == null || message.isEmpty) {
      return 'Authentication failed. Please try again.';
    }
    final lower = message.toLowerCase();

    if (lower.contains('provider') && lower.contains('not enabled')) {
      return 'Google sign-in is not enabled in the app settings. Please use email sign-in or enable Google auth.';
    }
    if (lower.contains('google') && lower.contains('not enabled')) {
      return 'Google sign-in is not enabled. Please use email sign-in.';
    }
    if (lower.contains('invalid credentials') ||
        lower.contains('invalid_grant') ||
        lower.contains('invalid id_token')) {
      return 'Google authentication was rejected. Please try again or use email sign-in.';
    }
    if (lower.contains('missing client') || lower.contains('client_id')) {
      return 'Google OAuth is not configured correctly. Please use email sign-in.';
    }
    if (lower.contains('rate limit') || lower.contains('too many requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }

    log('Unmapped Supabase auth error: $message');
    return 'Authentication failed. Please try again or use email sign-in.';
  }
}
