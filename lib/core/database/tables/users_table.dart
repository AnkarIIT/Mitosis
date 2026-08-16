import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique().nullable()();
  TextColumn get phone => text().unique().nullable()();
  TextColumn get username => text().unique()();
  TextColumn get passwordHash => text().nullable()(); // Nullable for phone-only login
  TextColumn get fullName => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get lastLogin => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isEmailVerified => boolean().withDefault(const Constant(false))();
  BoolColumn get isPhoneVerified => boolean().withDefault(const Constant(false))();
  BoolColumn get isTwoFactorEnabled => boolean().withDefault(const Constant(false))();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastActivityDate => dateTime().nullable()();

  // Batch onboarding triage (see lib/features/onboarding/batch_onboarding_screen.dart).
  TextColumn get batch => text().nullable()(); // 'Class 11' | 'Class 12' | 'Dropper'
  IntColumn get targetYear => integer().nullable()();
  IntColumn get dailyCommitmentMinutes => integer().nullable()();
}
