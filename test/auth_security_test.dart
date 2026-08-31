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
          password: 'correct-horse-battery',
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
          password: 'correct-horse-battery',
        );

        final ok = await auth.login(
          email: 'sec@example.com',
          password: 'correct-horse-battery',
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
  });
}
