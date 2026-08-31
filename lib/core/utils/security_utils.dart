import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Secure password hashing utilities using PBKDF2-HMAC-SHA256.
///
/// Hash format: `pbkdf2:<iterations>:<base64url-salt>:<base64url-hash>`
///
/// Legacy SHA-256 hashes (plain hex strings) are still accepted by
/// [verifyPassword] so that existing users can log in and have their
/// password transparently re-hashed on the next successful login.
class SecurityUtils {
  // 10 000 iterations ≈ 50-100 ms on mid-range mobile — a good balance
  // between security and UX.  Increase on each major release.
  static const int _iterations = 10000;
  static const int _saltLength = 16; // bytes
  static const int _keyLength = 32; // bytes (256-bit output)
  static const String _prefix = 'pbkdf2';

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns a self-describing hash string suitable for storing in the DB.
  ///
  /// Each call produces a **different** output because a new random salt is
  /// generated every time.
  static String hashPassword(String password) {
    final saltBytes = _randomBytes(_saltLength);
    final hashBytes = _pbkdf2HmacSha256(
      password,
      saltBytes,
      _iterations,
      _keyLength,
    );
    final salt = base64Url.encode(saltBytes);
    final hash = base64Url.encode(hashBytes);
    return '$_prefix:$_iterations:$salt:$hash';
  }

  /// Verifies [password] against a [storedHash] produced by [hashPassword].
  ///
  /// Also handles **legacy SHA-256 hashes** (plain 64-char hex strings) so
  /// that existing users are not locked out.  Returns `true` for valid
  /// credentials regardless of the hash format.
  static bool verifyPassword(String password, String storedHash) {
    if (storedHash.startsWith('$_prefix:')) {
      return _verifyPbkdf2(password, storedHash);
    }
    // Legacy: plain SHA-256 hex produced by the old `hashPassword`.
    return _legacySha256Match(password, storedHash);
  }

  /// Convenience wrapper kept for backward-compat call-sites.
  /// Prefer [hashPassword] / [verifyPassword] directly.
  static String hashPasswordLegacy(String password) =>
      sha256.convert(password.codeUnits).toString();

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static bool _verifyPbkdf2(String password, String stored) {
    final parts = stored.split(':');
    if (parts.length != 4) return false;

    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations <= 0) return false;

    Uint8List saltBytes;
    Uint8List expectedHash;
    try {
      saltBytes = Uint8List.fromList(base64Url.decode(parts[2]));
      expectedHash = Uint8List.fromList(base64Url.decode(parts[3]));
    } catch (_) {
      return false;
    }

    final candidateHash = _pbkdf2HmacSha256(
      password,
      saltBytes,
      iterations,
      expectedHash.length,
    );

    // Constant-time comparison to prevent timing attacks.
    return _constantTimeEquals(candidateHash, expectedHash);
  }

  static bool _legacySha256Match(String password, String storedHash) {
    final candidate = sha256.convert(password.codeUnits).toString();
    return _constantTimeEquals(
      Uint8List.fromList(candidate.codeUnits),
      Uint8List.fromList(storedHash.codeUnits),
    );
  }

  /// PBKDF2 using HMAC-SHA-256 as the pseudo-random function.
  ///
  /// Produces [keyLength] bytes derived from [password] and [salt].
  static Uint8List _pbkdf2HmacSha256(
    String password,
    Uint8List salt,
    int iterations,
    int keyLength,
  ) {
    final passwordBytes = utf8.encode(password);
    final hmac = Hmac(sha256, passwordBytes);

    final blockCount = (keyLength / 32).ceil();
    final result = Uint8List(blockCount * 32);

    for (int b = 1; b <= blockCount; b++) {
      // PRF input for the first iteration: salt || INT(b)
      final blockIndex = Uint8List(4)
        ..[0] = (b >> 24) & 0xff
        ..[1] = (b >> 16) & 0xff
        ..[2] = (b >> 8) & 0xff
        ..[3] = b & 0xff;

      final seedInput = Uint8List(salt.length + 4)
        ..setAll(0, salt)
        ..setAll(salt.length, blockIndex);

      // U1
      var u = Uint8List.fromList(hmac.convert(seedInput).bytes);
      final xored = Uint8List.fromList(u);

      // U2 … U_iterations
      for (int i = 1; i < iterations; i++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (int j = 0; j < 32; j++) {
          xored[j] ^= u[j];
        }
      }

      result.setAll((b - 1) * 32, xored);
    }

    return result.sublist(0, keyLength);
  }

  /// Constant-time byte comparison — prevents timing side-channel attacks.
  static bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  /// Cryptographically secure random bytes.
  static Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rng.nextInt(256)),
    );
  }
}
