import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/config/app_config.dart';

void main() {
  test('auth config flags whether free cloud auth is available', () {
    expect(AppConfig.isCloudAuthConfigured, isFalse);
  });
}
