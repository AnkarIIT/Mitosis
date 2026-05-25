import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../database/drift_database.dart';

class AuthService {
  final AppDatabase _db;

  AuthService(this._db);

  /// Hash password using SHA-256 (for production, use bcrypt)
  static String hashPassword(String password) {
    return sha256.convert(password.codeUnits).toString();
  }

  /// Register a new user
  Future<({bool success, String message, User? user})> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
  }) async {
    try {
      // Validate inputs
      if (email.isEmpty || !email.contains('@')) {
        return (success: false, message: 'Invalid email format', user: null);
      }
      if (username.isEmpty || username.length < 3) {
        return (
          success: false,
          message: 'Username must be at least 3 characters',
          user: null,
        );
      }
      if (password.isEmpty || password.length < 6) {
        return (
          success: false,
          message: 'Password must be at least 6 characters',
          user: null,
        );
      }

      // Check if user already exists
      final existing = await _db.getUserByEmail(email);
      if (existing != null) {
        return (
          success: false,
          message: 'Email already registered',
          user: null,
        );
      }

      // Create user
      final passwordHash = hashPassword(password);
      await _db.registerUser(
        UsersCompanion.insert(
          email: email,
          username: username,
          passwordHash: passwordHash,
          fullName: Value(fullName),
        ),
      );

      final user = await _db.getUserByEmail(email);
      if (user != null) {
        debugPrint('✅ User registered: ${user.username}');
        return (success: true, message: 'Registration successful', user: user);
      }

      return (success: false, message: 'User creation failed', user: null);
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      return (success: false, message: 'Registration failed: $e', user: null);
    }
  }

  /// Login user
  Future<({bool success, String message, User? user})> login({
    required String email,
    required String password,
  }) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        return (
          success: false,
          message: 'Email and password required',
          user: null,
        );
      }

      final user = await _db.getUserByEmail(email);
      if (user == null) {
        return (success: false, message: 'User not found', user: null);
      }

      if (!user.isActive) {
        return (success: false, message: 'Account is inactive', user: null);
      }

      final passwordHash = hashPassword(password);
      if (user.passwordHash != passwordHash) {
        return (success: false, message: 'Invalid password', user: null);
      }

      // Update last login
      await _db.updateLastLogin(user.id);
      debugPrint('✅ User logged in: ${user.username}');
      return (success: true, message: 'Login successful', user: user);
    } catch (e) {
      debugPrint('❌ Login error: $e');
      return (success: false, message: 'Login failed: $e', user: null);
    }
  }

  /// Verify password
  static bool verifyPassword(String password, String hash) {
    return hashPassword(password) == hash;
  }
}
