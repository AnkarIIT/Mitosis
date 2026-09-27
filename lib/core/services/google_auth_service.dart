import 'dart:developer';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../config/app_config.dart';
import '../database/drift_database.dart' as db;

class GoogleAuthService {
  final db.AppDatabase _db;
  final GoogleSignIn _googleSignIn;

  GoogleAuthService(this._db, [GoogleSignIn? googleSignIn])
    : _googleSignIn =
          googleSignIn ??
          GoogleSignIn(serverClientId: AppConfig.googleServerClientId);

  supabase.SupabaseClient? get _supabaseClient =>
      AppConfig.enableCloudAuth ? supabase.Supabase.instance.client : null;

  bool get _cloudAuthEnabled => _supabaseClient != null;

  Future<({bool success, String message, db.User? user})>
  signInWithGoogle() async {
    if (!_cloudAuthEnabled) {
      return (
        success: false,
        message: 'Cloud auth is not configured',
        user: null,
      );
    }

    try {
      log('🔍 Google Sign-In: Starting...');
      log('🔍 Google Server Client ID: ${AppConfig.googleServerClientId}');
      log('🔍 Supabase URL: ${AppConfig.supabaseUrl}');

      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        log('🔍 Google Sign-In: Cancelled by user');
        return (success: false, message: 'Sign-in was cancelled', user: null);
      }

      log('🔍 Google Sign-In: Got account: ${googleAccount.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleAccount.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      log(
        '🔍 Google Sign-In: ID Token: ${idToken != null ? 'present (${idToken.length} chars)' : 'NULL'}',
      );
      log(
        '🔍 Google Sign-In: Access Token: ${accessToken != null ? 'present' : 'NULL'}',
      );

      if (idToken == null) {
        return (
          success: false,
          message: 'Could not obtain ID token from Google',
          user: null,
        );
      }

      final client = _supabaseClient!;
      log('🔑 Attempting Supabase Google sign-in with ID token');

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

      await _upsertLocalUser(
        email: email,
        username: email.split('@').first,
        fullName: displayName,
      );

      final localUser = await _db.getUserByEmail(email);
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
              'Google sign-in failed with code 12500. This usually means the app signing certificate is not registered in Google Cloud/Firebase. Add this debug SHA-1 to your Android OAuth client: 49162e9ff8e0a2f61a7fd4b1ea1d37ca2c00e553',
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
      return (success: false, message: 'Something went wrong: $e', user: null);
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      if (_cloudAuthEnabled) {
        await _supabaseClient!.auth.signOut();
      }
    } catch (e) {
      log('Sign out error: $e');
    }
  }

  Future<void> _upsertLocalUser({
    required String email,
    required String username,
    required String fullName,
  }) async {
    final existing = await _db.getUserByEmail(email);

    if (existing != null) {
      await (_db.update(
        _db.users,
      )..where((t) => t.id.equals(existing.id))).write(
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
        passwordHash: const Value('google_auth'),
      ),
    );
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
    return message;
  }
}
