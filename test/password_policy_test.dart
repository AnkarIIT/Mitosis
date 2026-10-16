import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/utils/password_policy.dart';

void main() {
  group('PasswordPolicy.validate', () {
    test('accepts a strong password', () {
      expect(PasswordPolicy.validate('C0rrect-Horse!'), isNull);
      expect(PasswordPolicy.validate('Str0ng#Pass'), isNull);
    });

    test('rejects passwords shorter than 8 characters', () {
      final result = PasswordPolicy.validate('Ab1!');
      expect(result, isNotNull);
      expect(result, contains('8'));
    });

    test('rejects passwords without uppercase', () {
      final result = PasswordPolicy.validate('c0rrect-horse!');
      expect(result, isNotNull);
      expect(result, contains('uppercase'));
    });

    test('rejects passwords without lowercase', () {
      final result = PasswordPolicy.validate('C0RRECT-HORSE!');
      expect(result, isNotNull);
      expect(result, contains('lowercase'));
    });

    test('rejects passwords without a digit', () {
      final result = PasswordPolicy.validate('Correct-Horse!');
      expect(result, isNotNull);
      expect(result, contains('number'));
    });

    test('rejects passwords without a special character', () {
      final result = PasswordPolicy.validate('C0rrectHorse');
      expect(result, isNotNull);
      expect(result, contains('special'));
    });

    test('rejects empty password', () {
      final result = PasswordPolicy.validate('');
      expect(result, isNotNull);
    });
  });
}
