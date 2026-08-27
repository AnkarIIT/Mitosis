import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_preferences_model.dart';
import '../models/subject_model.dart';
import '../database/drift_database.dart' as db;
import 'core_providers.dart';
import 'auth_providers.dart';
import 'content_providers.dart';
import 'user_providers.dart';

// ============= USER PREFERENCES =============
final userPreferencesProvider =
    StateNotifierProvider<UserPreferencesNotifier, UserPreferences>((ref) {
      return UserPreferencesNotifier(ref.watch(databaseProvider), ref);
    });

final studyPlanTopicsProvider = Provider<List<Topic>>((ref) {
  final weak = ref.watch(weakTopicsProvider);
  final prefs = ref.watch(userPreferencesProvider);
  final subjects = ref.watch(subjectsProvider);
  return UserPreferences.filterTopicsByBatch(
    weak,
    batch: prefs.batch,
    subjects: subjects,
  );
});

class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  UserPreferencesNotifier(this._db, this._ref)
    : super(const UserPreferences()) {
    _load();
  }

  static const _batchKey = 'neet_batch';
  static const _yearKey = 'neet_target_year';
  static const _commitmentKey = 'neet_daily_commitment_minutes';
  static const _onboardedKey = 'batch_onboarding_complete';

  final db.AppDatabase _db;
  final Ref _ref;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = UserPreferences(
        batch: prefs.getString(_batchKey),
        targetYear: prefs.getInt(_yearKey),
        dailyCommitmentMinutes: prefs.getInt(_commitmentKey),
        isOnboarded: prefs.getBool(_onboardedKey) ?? false,
      );
    } catch (e) {
      debugPrint('❌ Error loading user preferences: $e');
    }
  }

  Future<void> save({
    required String? batch,
    required int? targetYear,
    required int? dailyCommitmentMinutes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (batch != null) await prefs.setString(_batchKey, batch);
      if (targetYear != null) await prefs.setInt(_yearKey, targetYear);
      if (dailyCommitmentMinutes != null) {
        await prefs.setInt(_commitmentKey, dailyCommitmentMinutes);
      }
      await prefs.setBool(_onboardedKey, true);

      final user = _ref.read(authProvider).user;
      if (user != null) {
        await _db.updateUserPreferences(
          user.id,
          batch: batch,
          targetYear: targetYear,
          dailyCommitmentMinutes: dailyCommitmentMinutes,
        );
      }

      state = state.copyWith(
        batch: batch ?? state.batch,
        targetYear: targetYear ?? state.targetYear,
        dailyCommitmentMinutes:
            dailyCommitmentMinutes ?? state.dailyCommitmentMinutes,
        isOnboarded: true,
      );
    } catch (e) {
      debugPrint('❌ Error saving user preferences: $e');
    }
  }
}

// ============= THEME =============
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }
  static const _themeKey = 'theme_mode';
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey);
    if (themeIndex != null) {
      state = ThemeMode.values[themeIndex];
    }
  }
  Future<void> toggleTheme(bool isDark) async {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, state.index);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

// ============= ONBOARDING =============
// Preloaded synchronously before runApp so GoRouter redirect can read it.
final onboardingCompleteProvider = StateProvider<bool>((ref) => false);
