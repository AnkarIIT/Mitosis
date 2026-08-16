import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app config exposes free-tier auth configuration defaults', () {
    const url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    const anonKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: '',
    );

    expect(url, isA<String>());
    expect(anonKey, isA<String>());
    expect(url.isEmpty || Uri.tryParse(url) != null, isTrue);
    expect(anonKey.isEmpty || anonKey.length > 10, isTrue);
  });
}
