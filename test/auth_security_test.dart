import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/database/drift_database.dart';
import 'package:neet_mitos/core/services/auth_service.dart';

void main() {
  group('AuthService password hashing & reset', () {
    late AppDatabase db;
    late AuthService auth;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      auth = AuthService(db);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'register stores a PBKDF2-hashed password (not legacy SHA-256)',
      () async {
        final result = await auth.register(
          email: 'sec@example.com',
          username: 'sec',
          password: 'C0rrect-Horse!',
        );
        expect(result.success, isTrue);

        final user = await db.getUserByEmail('sec@example.com');
        final stored = user!.passwordHash!;
        expect(stored, startsWith('pbkdf2-sha256\$'));
        expect(stored, isNot(contains('neet_mitos_local')));
        // Format: "pbkdf2-sha256$<iterations>$<salt>$<key>" — exactly 4 parts.
        expect(stored.split('\$').length, 4);
      },
    );

    test(
      'login succeeds with correct password and rejects the wrong one',
      () async {
        await auth.register(
          email: 'sec@example.com',
          username: 'sec',
          password: 'C0rrect-Horse!',
        );

        final ok = await auth.login(
          email: 'sec@example.com',
          password: 'C0rrect-Horse!',
        );
        expect(ok.success, isTrue);

        final bad = await auth.login(
          email: 'sec@example.com',
          password: 'wrong-password',
        );
        expect(bad.success, isFalse);
      },
    );

    test(
      'legacy unsalted SHA-256 hashes still verify (backward compatible)',
      () async {
        // Reconstruct the old scheme exactly as it was before the fix so we can
        // confirm accounts created prior to the migration can still sign in.
        const legacyPassword = 'legacy-pw';
        final legacyHash = sha256
            .convert(utf8.encode('neet_mitos_local:$legacyPassword'))
            .toString();

        await db.registerUser(
          UsersCompanion.insert(
            email: const Value('legacy@example.com'),
            username: 'legacy',
            passwordHash: Value(legacyHash),
          ),
        );

        final ok = await auth.login(
          email: 'legacy@example.com',
          password: legacyPassword,
        );
        expect(ok.success, isTrue);

        final bad = await auth.login(
          email: 'legacy@example.com',
          password: 'nope',
        );
        expect(bad.success, isFalse);
      },
    );

    test(
      'a successful legacy-hash login is upgraded to PBKDF2 in place',
      () async {
        // Without this, an account created before the PBKDF2 migration keeps
        // its unsalted SHA-256 hash forever, because the legacy path only had to
        // stay *verifiable*. Verifiability is not the same as being fixed: the
        // stored hash remains crackable at SHA-256 speed.
        const legacyPassword = 'upgrade-me';
        final legacyHash = sha256
            .convert(utf8.encode('neet_mitos_local:$legacyPassword'))
            .toString();

        final user = await db.registerUser(
          UsersCompanion.insert(
            email: const Value('upgrade@example.com'),
            username: 'upgrade',
            passwordHash: Value(legacyHash),
          ),
        );
        final userId = user!.id;

        // Precondition: stored in the weak format.
        final before = await db.getUserById(userId);
        expect(before!.passwordHash, legacyHash);
        expect(before.passwordHash, isNot(startsWith('pbkdf2-sha256\$')));

        final ok = await auth.login(
          email: 'upgrade@example.com',
          password: legacyPassword,
        );
        expect(ok.success, isTrue);

        // Postcondition: rehashed with the current scheme.
        final after = await db.getUserById(userId);
        expect(after!.passwordHash, startsWith('pbkdf2-sha256\$'));
        expect(after.passwordHash, isNot(legacyHash));

        // And the new hash still authenticates, plus is salted so the same
        // password hashes differently per account.
        final again = await auth.login(
          email: 'upgrade@example.com',
          password: legacyPassword,
        );
        expect(again.success, isTrue);
      },
    );

    test(
      'a failed legacy-hash login does not rewrite the stored hash',
      () async {
        // The upgrade must happen only after a *verified* password, otherwise an
        // attacker could lock a user out by submitting wrong guesses.
        const legacyPassword = 'keep-legacy';
        final legacyHash = sha256
            .convert(utf8.encode('neet_mitos_local:$legacyPassword'))
            .toString();

        final user = await db.registerUser(
          UsersCompanion.insert(
            email: const Value('norwite@example.com'),
            username: 'norwite',
            passwordHash: Value(legacyHash),
          ),
        );
        final userId = user!.id;

        await auth.login(email: 'norwite@example.com', password: 'wrong');

        final after = await db.getUserById(userId);
        expect(after!.passwordHash, legacyHash);
      },
    );

    test('a federated account cannot be signed into with a password', () async {
      // Google-created rows carry the sentinel, not a hash. A user who taps
      // "sign in" instead of "continue with Google" must be told that, not shown
      // a misleading "Incorrect password".
      await db.registerUser(
        UsersCompanion.insert(
          email: const Value('social@example.com'),
          username: 'social',
          passwordHash: const Value(kGooglePasswordSentinel),
          supabaseId: const Value('supabase-uuid-1'),
        ),
      );

      final result = await auth.login(
        email: 'social@example.com',
        password: 'anything at all',
      );

      expect(result.success, isFalse);
      expect(result.message.toLowerCase(), contains('social sign-in'));
    });

    test(
      'a cloud account with an empty hash is also refused a password login',
      () async {
        // Historical rows were created with '' rather than the sentinel. Both must
        // take the friendly branch, not the generic failure.
        await db.registerUser(
          UsersCompanion.insert(
            email: const Value('emptyhash@example.com'),
            username: 'emptyhash',
            passwordHash: const Value(''),
          ),
        );

        final result = await auth.login(
          email: 'emptyhash@example.com',
          password: 'anything',
        );

        expect(result.success, isFalse);
        expect(result.message.toLowerCase(), contains('social sign-in'));
      },
    );
  });
}
