import 'package:shared_preferences/shared_preferences.dart';

/// Stores first-run completion separately for each local account and guest mode.
///
/// Setup is device-local, so this marker is intentionally kept in
/// SharedPreferences rather than synced as account data.
class OnboardingCompletionService {
  static const _guestKey = 'onboarding_complete_guest';

  static String _userKey(int userId) => 'onboarding_complete_user_$userId';

  static Future<bool> isComplete({
    required int? userId,
    required bool isGuest,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) return prefs.getBool(_userKey(userId)) ?? false;
    if (isGuest) return prefs.getBool(_guestKey) ?? false;
    return false;
  }

  static Future<void> markComplete({
    required int? userId,
    required bool isGuest,
  }) async {
    final key = userId != null
        ? _userKey(userId)
        : isGuest
        ? _guestKey
        : null;
    if (key == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }
}
