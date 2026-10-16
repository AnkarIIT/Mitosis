import 'package:drift/drift.dart';

import 'users_table.dart';

/// Records acceptance of a legal document.
///
/// Consent used to be an in-memory boolean on the sign-up screen: it reset on
/// every app restart and was never written down, so acceptance could not be
/// demonstrated if it were ever disputed. Each row pins the exact *version*
/// accepted at a timestamp, which is what a regulator or store reviewer asks
/// for — "did they accept" is much weaker than "which text did they accept".
///
/// This is a local record. It is not sent to the server, because the app does
/// not use consent for anything server-side.
class ConsentRecords extends Table {
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();

  /// Which document: `terms`, `privacy`, or `ai_processing`.
  TextColumn get document => text()();

  /// The version string shown to the user, e.g. `2026-08`.
  TextColumn get version => text()();

  DateTimeColumn get acceptedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId, document, version};
}

/// Version strings for the documents the app gates on.
///
/// Bumping a version is what causes re-consent: [AppDatabase.hasAcceptedConsent]
/// compares against the current version, so a user who accepted `2026-08` is
/// asked again once the screen moves to `2026-10`.
class ConsentDocument {
  const ConsentDocument._();

  static const String terms = 'terms';
  static const String privacy = 'privacy';
  static const String aiProcessing = 'ai_processing';

  /// Must match the "Last updated" date shown on the corresponding screen.
  static const String termsVersion = '2026-08';
  static const String privacyVersion = '2026-08';
  static const String aiProcessingVersion = '2026-08';
}
