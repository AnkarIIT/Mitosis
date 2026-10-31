/// Compile-time switches for features that ship in the binary but are not yet
/// safe to expose to students.
///
/// Usage: `flutter run --dart-define=PYQ_DOWNLOADS=true`
class FeatureFlags {
  const FeatureFlags._();

  /// The "PYQ Downloads" screen animates a progress bar and shows a success
  /// snackbar without downloading anything. It stays off until it is wired to
  /// `PyqPdfDownloaderService`, because a fake success message is worse than a
  /// hidden feature.
  static const bool pyqDownloads = bool.fromEnvironment(
    'PYQ_DOWNLOADS',
    defaultValue: false,
  );
}
