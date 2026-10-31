import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/constants/feature_flags.dart';
import 'package:neet_mitos/core/router/app_router.dart';

/// The "PYQ Downloads" screen showed a fake progress bar and a success
/// snackbar without downloading anything. These tests keep it unreachable
/// until it is wired to a real downloader.
void main() {
  group('PYQ Downloads stays hidden', () {
    test('the feature flag defaults to off', () {
      expect(
        FeatureFlags.pyqDownloads,
        isFalse,
        reason: 'a fake "downloaded" message is worse than a hidden feature',
      );
    });

    test('/pyq redirects away while the flag is off', () {
      expect(pyqRouteRedirect(), '/practice');
    });
  });
}
