import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/models/chapter_model.dart' as lesson_chapter;
import 'package:neet_mitos/core/models/subject_model.dart' as catalog;
import 'package:neet_mitos/core/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Locks the contract between the two unrelated classes named `Chapter`.
///
/// `models/subject_model.dart` defines the legacy catalog chapter (name,
/// subjectId, topics) reached through `Subject.chapters`. `models/chapter_model.dart`
/// defines the newer lesson-based chapter (title, lessons, summaryQuiz) used by
/// the chapter feature. `content_providers.dart` imports both — the lesson
/// model unprefixed — so bare `Chapter` there resolves to the NEW type, and
/// any legacy provider that fails to spell out `subject_model.Chapter` silently
/// starts returning the wrong shape.
///
/// That mix-up has already broken the build once. These assertions pin which
/// provider yields which shape so a regression fails loudly here instead of
/// surfacing as a confusing type error somewhere downstream.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('catalog providers yield legacy catalog chapters with topics', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final subjects = container.read(subjectsProvider);
    expect(subjects, isNotEmpty, reason: 'sample subject catalog is empty');

    final first = subjects.first;
    final chapters = container.read(chaptersProvider(first.id));
    expect(chapters, isNotEmpty);
    // Statically a List<catalog.Chapter>; assert the shape that matters.
    expect(chapters.first, isA<catalog.Chapter>());
    expect(chapters.first.topics, isNotEmpty);

    final one = container.read(chapterByIdProvider(chapters.first.id));
    expect(one, isNotNull);
    expect(one!.id, chapters.first.id);
    expect(container.read(topicsProvider(chapters.first.id)), isNotEmpty);
  });

  test('chapter feature providers yield lesson-based chapters', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final all = container.read(allChaptersProvider);
    expect(all, isNotEmpty, reason: 'ChapterService catalog is empty');

    // The lesson-based model: it has `title` and `lessons`, which the legacy
    // catalog chapter does not.
    expect(all.first, isA<lesson_chapter.Chapter>());
    expect(all.first.title, isNotEmpty);

    // And it is genuinely a different type from the catalog chapter, so a
    // provider cannot quietly start returning the wrong shape.
    expect(all.first, isNot(isA<catalog.Chapter>()));

    // chapterProvider is a FutureProvider.
    final one = await container.read(chapterProvider(all.first.id).future);
    expect(one, isNotNull);
    expect(one!.id, all.first.id);
  });
}
