/// Service for loading chapters and managing chapter progress.
library chapter_service;

import '../models/chapter_model.dart';

/// Static chapter catalog (bundled in app).
///
/// In production, this would be loaded from assets/chapters/chapter_index.json
/// and lessons from assets/lessons/{chapterId}/{lessonId}.md
class ChapterService {
  ChapterService._();

  /// All chapters available in the app.
  static const List<Chapter> allChapters = [
    // Physics - Class 11
    Chapter(
      id: 'phy_ch1',
      subject: 'Physics',
      classLevel: 'Class 11',
      chapterNumber: 1,
      title: 'Physical World',
      learningOutcomes: [
        'Understand the scope and excitement of physics',
        'Appreciate the role of physics in technology and society',
        'Know about fundamental forces in nature',
      ],
      estimatedMinutes: 30,
      pdfEntryId: 'physics_class11_ch1',
      lessons: [
        Lesson(
          id: 'phy_ch1_l1',
          title: 'What is Physics?',
          order: 1,
          content: '''
Physics is the study of matter, energy, and their interactions. It seeks to understand the fundamental laws that govern the universe — from the smallest subatomic particles to the largest galaxies.

Physics is both a science and a way of thinking. It involves:
- **Observation** of natural phenomena
- **Hypothesis formation** to explain observations
- **Experimentation** to test hypotheses
- **Theory building** to create predictive models

The word "physics" comes from the Greek *physis*, meaning "nature". Physics is truly the study of nature at its most fundamental level.
''',
          workedExample: '''
**Example: The Scientific Method in Action**
Galileo's experiment on falling bodies:
1. **Observation**: Heavy and light objects seem to fall at different speeds
2. **Hypothesis**: All objects fall at the same rate in vacuum
3. **Experiment**: Drop objects from Leaning Tower (thought experiment)
4. **Conclusion**: Acceleration due to gravity is independent of mass
''',
          misconception:
              'Heavier objects fall faster than lighter ones. In reality, in vacuum, all objects fall with the same acceleration (g ≈ 9.8 m/s²). Air resistance causes the difference in everyday experience.',
          ncertSection: '1.1',
          ncertPage: 3,
          estimatedMinutes: 15,
          quickChecks: [
            QuickCheck(
              id: 'phy_ch1_l1_q1',
              questionText:
                  'Physics is derived from the Greek word "physis" which means:',
              options: ['Motion', 'Nature', 'Energy', 'Force'],
              correctAnswer: 'Nature',
              explanation:
                  '"Physis" in Greek means nature. Physics is the study of nature.',
            ),
            QuickCheck(
              id: 'phy_ch1_l1_q2',
              questionText:
                  'In vacuum, a feather and a hammer dropped from the same height will:',
              options: [
                'Hit ground at different times',
                'Hit ground at same time',
                'Float',
                'Depends on mass',
              ],
              correctAnswer: 'Hit ground at same time',
              explanation:
                  'In vacuum, there is no air resistance. All objects experience the same gravitational acceleration.',
            ),
          ],
        ),
        Lesson(
          id: 'phy_ch1_l2',
          title: 'Scope and Excitement of Physics',
          order: 2,
          content: '''
Physics has an enormous scope, covering phenomena from the subatomic scale (10⁻¹⁵ m) to the cosmic scale (10²⁶ m). 

Major domains:
1. **Classical Mechanics** — Motion of macroscopic objects (Newton's laws)
2. **Thermodynamics** — Heat, work, and energy transfer
3. **Electromagnetism** — Electric and magnetic phenomena
4. **Quantum Mechanics** — Behavior of particles at atomic scale
5. **Relativity** — Space, time, and gravity at high speeds

Physics drives technology: semiconductors (quantum mechanics), GPS (relativity), medical imaging (electromagnetism + quantum).
''',
          workedExample: '''
**Example: Physics in Your Pocket**
Your smartphone uses:
- **Quantum mechanics**: Transistors, flash memory, LED screen
- **Electromagnetism**: Radio waves (4G/5G/WiFi), speaker, microphone
- **Relativity**: GPS timing corrections (satellite clocks run faster due to weaker gravity)
- **Thermodynamics**: Battery chemistry, heat dissipation
''',
          misconception:
              'Physics is only for scientists. In fact, physics principles are used in every modern technology you use daily.',
          ncertSection: '1.2',
          ncertPage: 5,
          estimatedMinutes: 20,
          quickChecks: [
            QuickCheck(
              id: 'phy_ch1_l2_q1',
              questionText:
                  'Which domain of physics explains the working of a transistor?',
              options: [
                'Thermodynamics',
                'Quantum Mechanics',
                'Classical Mechanics',
                'Relativity',
              ],
              correctAnswer: 'Quantum Mechanics',
              explanation:
                  'Transistors rely on quantum mechanical behavior of electrons in semiconductors.',
            ),
          ],
        ),
      ],
      summaryQuiz: [
        QuickCheck(
          id: 'phy_ch1_sq1',
          questionText:
              'The word "physics" comes from the Greek word "physis" meaning:',
          options: ['Motion', 'Nature', 'Energy', 'Force'],
          correctAnswer: 'Nature',
          explanation: 'Physis = nature in Greek.',
        ),
        QuickCheck(
          id: 'phy_ch1_sq2',
          questionText:
              'GPS satellites require relativistic corrections because:',
          options: [
            'They move fast (special relativity)',
            'They are in weaker gravity (general relativity)',
            'Both A and B',
            'Neither A nor B',
          ],
          correctAnswer: 'Both A and B',
          explanation:
              'Special relativity (speed) makes clocks run slower; general relativity (weaker gravity) makes them run faster. Net effect: +38 μs/day.',
        ),
        QuickCheck(
          id: 'phy_ch1_sq3',
          questionText: 'Which fundamental force has the shortest range?',
          options: [
            'Gravitational',
            'Electromagnetic',
            'Weak nuclear',
            'Strong nuclear',
          ],
          correctAnswer: 'Strong nuclear',
          explanation:
              'Strong nuclear force acts only within atomic nucleus (~10⁻¹⁵ m).',
        ),
      ],
    ),
  ];

  /// Get chapter by ID.
  static Chapter? getChapter(String id) {
    try {
      return allChapters.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get chapters by subject.
  static List<Chapter> getChaptersBySubject(String subject) {
    return allChapters.where((c) => c.subject == subject).toList();
  }

  /// Get chapters by class level.
  static List<Chapter> getChaptersByClass(String classLevel) {
    return allChapters.where((c) => c.classLevel == classLevel).toList();
  }
}
