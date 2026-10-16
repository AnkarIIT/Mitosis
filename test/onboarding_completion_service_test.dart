import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/services/onboarding_completion_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('account completion is isolated by local user id', () async {
    await OnboardingCompletionService.markComplete(userId: 12, isGuest: false);

    expect(
      await OnboardingCompletionService.isComplete(userId: 12, isGuest: false),
      isTrue,
    );
    expect(
      await OnboardingCompletionService.isComplete(userId: 34, isGuest: false),
      isFalse,
    );
    expect(
      await OnboardingCompletionService.isComplete(userId: null, isGuest: true),
      isFalse,
    );
  });

  test('guest completion does not mark any account complete', () async {
    await OnboardingCompletionService.markComplete(userId: null, isGuest: true);

    expect(
      await OnboardingCompletionService.isComplete(userId: null, isGuest: true),
      isTrue,
    );
    expect(
      await OnboardingCompletionService.isComplete(userId: 12, isGuest: false),
      isFalse,
    );
  });
}
