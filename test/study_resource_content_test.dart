import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/models/study_resource_content.dart';

void main() {
  test('authored priority chapters contain usable revision sections', () {
    for (final chapterId in ['bio_ch1', 'bio_ch8', 'chem_ch1', 'phys_ch2']) {
      final content = studyResourceContent[chapterId];
      expect(content, isNotNull, reason: chapterId);
      expect(content!.overview, isNotEmpty);
      expect(content.hasAuthoredContent, isTrue);
      expect(content.keyFacts, isNotEmpty);
      expect(content.revisionRules, isNotEmpty);
    }
  });

  test('formula sheets are not shown for biology priority content', () {
    expect(studyResourceContent['bio_ch1']!.formulas, isEmpty);
    expect(studyResourceContent['chem_ch1']!.formulas, isNotEmpty);
    expect(studyResourceContent['phys_ch2']!.formulas, isNotEmpty);
  });
}
