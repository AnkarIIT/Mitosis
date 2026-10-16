import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique().nullable()();
  TextColumn get phone => text().unique().nullable()();
  TextColumn get username => text().unique()();
  TextColumn get passwordHash =>
      text().nullable()(); // Nullable for phone-only login
  TextColumn get fullName => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get lastLogin => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isEmailVerified =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isPhoneVerified =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isTwoFactorEnabled =>
      boolean().withDefault(const Constant(false))();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastActivityDate => dateTime().nullable()();

  // Batch onboarding triage (see lib/features/onboarding/batch_onboarding_screen.dart).
  TextColumn get batch =>
      text().nullable()(); // 'Class 11' | 'Class 12' | 'Dropper'
  IntColumn get targetYear => integer().nullable()();
  IntColumn get dailyCommitmentMinutes => integer().nullable()();
  TextColumn get passwordResetCode => text().nullable()();
  DateTimeColumn get passwordResetExpiresAt => dateTime().nullable()();
  TextColumn get twoFactorCode => text().nullable()();
  DateTimeColumn get twoFactorExpiresAt => dateTime().nullable()();
  TextColumn get supabaseId => text().nullable()();

  // Account lockout / brute-force protection
  IntColumn get failedLoginAttempts =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get lockedUntil => dateTime().nullable()();

  // Email-OTP throttling: caps guesses on a live code and rate-limits resends.
  //
  // These three were declared but never read or written by any query, so OTP
  // guessing was unbounded. Enforced by verifyTwoFactorCode() and
  // isTwoFactorResendThrottled().
  IntColumn get twoFactorAttempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get twoFactorLockedUntil => dateTime().nullable()();
  DateTimeColumn get twoFactorLastSentAt => dateTime().nullable()();

  // Password-reset OTP throttling: same threat model as the 2FA columns above.
  // A 6-digit reset code is 10^6 candidates, so the guess count must be bounded
  // independently of the password-login lockout.
  IntColumn get passwordResetAttempts =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get passwordResetLockedUntil => dateTime().nullable()();
  DateTimeColumn get passwordResetLastSentAt => dateTime().nullable()();
}
