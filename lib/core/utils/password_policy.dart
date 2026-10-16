/// Shared password validation policy for registration and reset.
///
/// Returns `null` when the password is acceptable, otherwise a
/// user-facing message describing the first unmet requirement.
class PasswordPolicy {
  const PasswordPolicy._();

  static const int minLength = 8;

  static final _uppercase = RegExp(r'[A-Z]');
  static final _lowercase = RegExp(r'[a-z]');
  static final _digit = RegExp(r'\d');
  static final _special = RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]');

  /// Returns `null` if [password] meets the policy, or an error message.
  static String? validate(String password) {
    if (password.length < minLength) {
      return 'Enter a valid email and a password with at least $minLength characters.';
    }
    if (!_uppercase.hasMatch(password)) {
      return 'Password must contain at least one uppercase letter.';
    }
    if (!_lowercase.hasMatch(password)) {
      return 'Password must contain at least one lowercase letter.';
    }
    if (!_digit.hasMatch(password)) {
      return 'Password must contain at least one number.';
    }
    if (!_special.hasMatch(password)) {
      return 'Password must contain at least one special character (!@#\$%^&*...).';
    }
    return null;
  }
}
