import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/database/drift_database.dart';
import 'package:neet_mitos/core/models/subject_model.dart';
import 'package:neet_mitos/core/models/user_preferences_model.dart';
import 'package:neet_mitos/core/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Subject _subject(List<Chapter> chapters) =>
    Subject(id: 'bio', name: 'Biology', icon: '🧬', chapters: chapters);

Chapter _chapter(String id, String? classLevel, List<Topic> topics) => Chapter(
  id: id,
  name: id,
  subjectId: 'bio',
  classLevel: classLevel,
  topics: topics,
);

Topic _topic(String id, String chapterId) =>
    Topic(id: id, name: id, chapterId: chapterId, questionCount: 10);

void main() {
  group('UserPreferences batch filtering', () {
    final t11 = _topic('t11', 'c11');
    final t12 = _topic('t12', 'c12');
    final subjects = [
      _subject([
        _chapter('c11', 'Class 11', [t11]),
        _chapter('c12', 'Class 12', [t12]),
      ]),
    ];

    test('Class 11 sees only Class 11 chapters', () {
      final filtered = UserPreferences.filterTopicsByBatch(
        [t11, t12],
        batch: 'Class 11',
        subjects: subjects,
      );
      expect(filtered, [t11]);
    });

    test('Class 12 sees only Class 12 chapters', () {
      final filtered = UserPreferences.filterTopicsByBatch(
        [t11, t12],
        batch: 'Class 12',
        subjects: subjects,
      );
      expect(filtered, [t12]);
    });

    test('Dropper sees the full syllabus', () {
      final filtered = UserPreferences.filterTopicsByBatch(
        [t11, t12],
        batch: 'Dropper',
        subjects: subjects,
      );
      expect(filtered.length, 2);
    });

    test('un-triaged users (null batch) see everything', () {
      final filtered = UserPreferences.filterTopicsByBatch(
        [t11, t12],
        batch: null,
        subjects: subjects,
      );
      expect(filtered.length, 2);
    });

    test(
      'topics from chapters without a classLevel are excluded for 11/12',
      () {
        final tFree = _topic('tFree', 'cFree');
        final subjectsWithFree = [
          _subject([
            _chapter('cFree', null, [tFree]),
            _chapter('c11', 'Class 11', [t11]),
          ]),
        ];
        final filtered = UserPreferences.filterTopicsByBatch(
          [tFree, t11],
          batch: 'Class 11',
          subjects: subjectsWithFree,
        );
        expect(filtered, [t11]);
      },
    );
  });

  group('UserPreferences recommended daily target', () {
    test('defaults to 50 without a commitment', () {
      expect(const UserPreferences().recommendedDailyTarget, 50);
      expect(
        const UserPreferences(
          dailyCommitmentMinutes: 60,
        ).recommendedDailyTarget,
        50,
      );
    });

    test('maps commitment bands to targets', () {
      expect(
        const UserPreferences(
          dailyCommitmentMinutes: 30,
        ).recommendedDailyTarget,
        25,
      );
      expect(
        const UserPreferences(
          dailyCommitmentMinutes: 90,
        ).recommendedDailyTarget,
        75,
      );
      expect(
        const UserPreferences(
          dailyCommitmentMinutes: 120,
        ).recommendedDailyTarget,
        100,
      );
    });
  });

  group('UserPreferences database (v19)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('users table persists batch onboarding fields', () async {
      await db.registerUser(
        UsersCompanion.insert(
          username: 'ankara',
          email: const Value('ankara@test.com'),
        ),
      );
      final user = await db.getUserByEmail('ankara@test.com');
      expect(user, isNotNull);
      expect(user!.batch, isNull);
      expect(user.targetYear, isNull);
      expect(user.dailyCommitmentMinutes, isNull);

      await db.updateUserPreferences(
        user.id,
        batch: 'Class 12',
        targetYear: 2028,
        dailyCommitmentMinutes: 60,
      );

      final updated = await db.getUserById(user.id);
      expect(updated!.batch, 'Class 12');
      expect(updated.targetYear, 2028);
      expect(updated.dailyCommitmentMinutes, 60);
    });
  });

  group('UserPreferencesNotifier', () {
    test('save writes to prefs and updates state', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(
            AppDatabase(NativeDatabase.memory()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(userPreferencesProvider.notifier);
      await notifier.save(
        batch: 'Dropper',
        targetYear: 2028,
        dailyCommitmentMinutes: 90,
      );

      expect(container.read(userPreferencesProvider).batch, 'Dropper');
      expect(container.read(userPreferencesProvider).targetYear, 2028);
      expect(
        container.read(userPreferencesProvider).dailyCommitmentMinutes,
        90,
      );
      expect(container.read(userPreferencesProvider).isOnboarded, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('neet_batch'), 'Dropper');
      expect(prefs.getInt('neet_target_year'), 2028);
      expect(prefs.getInt('neet_daily_commitment_minutes'), 90);
      expect(prefs.getBool('batch_onboarding_complete'), isTrue);
    });
  });
}
