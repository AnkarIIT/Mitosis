import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/subject_model.dart';
import '../../../core/models/user_progress_model.dart';
import '../../../core/services/exam_engine_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import 'package:go_router/go_router.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> with TickerProviderStateMixin {
  int _selectedChip = 0;
  bool _initialized = false;
  late AnimationController _progressAnimController;
  Animation<double>? _progressAnim;

  @override
  void initState() {
    super.initState();
    _progressAnimController = AnimationController(
      vsync: this,
      duration: AppDuration.slow,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _initialized = true);
      final dailyGoal = ref.read(dailyGoalProvider);
      final progress = (dailyGoal['percent'] as double).clamp(0.0, 1.0);
      _progressAnim = Tween<double>(begin: 0.0, end: progress).animate(
        CurvedAnimation(parent: _progressAnimController, curve: Curves.easeOutCubic),
      );
      _progressAnimController.forward();
    });
  }

  @override
  void dispose() {
    _progressAnimController.dispose();
    super.dispose();
  }

  static const _chipLabels = ['All', 'Botany', 'Zoology', 'Physics', 'Chemistry', 'Error Book'];

  String? _chipSubjectFilter(int index) {
    switch (index) {
      case 0: return null;
      case 1: return 'biology';
      case 2: return 'biology';
      case 3: return 'phys';
      case 4: return 'chem';
      case 5: return null;
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider);
    final stats = ref.watch(overallStatsProvider);
    final streak = ref.watch(userProgressProvider.select((s) => s.currentStreak));
    final dailyGoal = ref.watch(dailyGoalProvider);
    final recentActivity = ref.watch(recentActivityProvider);
    final weakTopics = ref.watch(weakTopicsProvider);
    final dueCardsAsync = ref.watch(dueCardsProvider);
    final dueCount = dueCardsAsync.value?.length ?? 0;

    return Scaffold(
      backgroundColor: AdaptiveColors.background(context),
      body: _initialized
          ? _buildHomeBody(context, subjects, stats, streak, dailyGoal, recentActivity, weakTopics, dueCount)
          : _buildShimmerSkeleton(context),
    );
  }

  // ────────────────────────────────────────────────────────────
  // HOME BODY
  // ────────────────────────────────────────────────────────────
  Widget _buildHomeBody(
    BuildContext context,
    List<Subject> subjects,
    Map<String, dynamic> stats,
    int streak,
    Map<String, dynamic> dailyGoal,
    List recentActivity,
    List weakTopics,
    int dueCount,
  ) {
    final totalMCQs = subjects.fold<int>(0, (sum, s) {
      return sum + s.chapters.fold<int>(0, (cSum, ch) {
        return cSum + ch.topics.fold<int>(0, (tSum, t) => tSum + t.questionCount);
      });
    });

    final chipFilter = _chipSubjectFilter(_selectedChip);
    final filteredSubjects = chipFilter == null
        ? subjects
        : subjects.where((s) => s.id == chipFilter).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileRow(context, streak, stats),
            const SizedBox(height: 20),
            _buildSearchBar(context),
            const SizedBox(height: 16),
            _buildChipRow(context),
            const SizedBox(height: 24),
            _buildFeaturedSubjectsHeader(),
            const SizedBox(height: 14),
            _buildFeaturedCards(context, filteredSubjects, totalMCQs),
            const SizedBox(height: 28),
            _buildOngoingSectionHeader(),
            const SizedBox(height: 14),
            _buildDailyGoalCard(context, dailyGoal),
            const SizedBox(height: 12),
            _buildContinueStudyingCard(context, recentActivity, subjects),
            const SizedBox(height: 12),
            _buildOngoingRevisionCards(context, recentActivity, subjects),
            const SizedBox(height: 12),
            // Resume an in-progress CBT mock (only shows when a checkpoint exists)
            _buildResumeMockCard(context),
            // CBT Mock Test CTA
            _buildCbtMockTestCard(context, subjects),
            if (dueCount > 0) ...[
              const SizedBox(height: 12),
              _buildDueReviewBanner(context, dueCount),
            ],
            if (weakTopics.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildWeakTopicsBanner(context, weakTopics),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // PROFILE ROW
  // ────────────────────────────────────────────────────────────
  Widget _buildProfileRow(BuildContext context, int streak, Map<String, dynamic> stats) {
    final accuracy = (stats['accuracy'] as double);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final displayName = user?.fullName ?? user?.username ?? 'Guest';
    final avatarLetter = displayName[0].toUpperCase();
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AdaptiveColors.surface(context),
          child: Text(
            avatarLetter,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $displayName',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'NEET 2026 Aspirant',
                style: TextStyle(
                  color: AppColors.textSubtle,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Streak badge
        AnimatedScale(
          scale: streak > 0 ? 1.0 : 0.8,
          duration: AppDuration.normal,
          curve: Curves.elasticOut,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department, size: 14, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  '$streak',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Accuracy badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: SubjectColors.physics.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SubjectColors.physics.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.trending_up, size: 14, color: SubjectColors.physics),
              const SizedBox(width: 4),
              Text(
                '${accuracy.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: SubjectColors.physics,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        // Notifications
        IconButton(
          icon: Icon(Icons.notifications_none_rounded, color: Colors.grey.shade600, size: 24),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No new notifications'), duration: Duration(seconds: 1)),
            );
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    ).animate().fade(duration: 400.ms).slideY(begin: 0.15, end: 0);
  }

  // ────────────────────────────────────────────────────────────
  // SEARCH BAR
  // ────────────────────────────────────────────────────────────
  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => showSearch(
        context: context,
        delegate: _NeetSearchDelegate(ref),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: AdaptiveColors.surface(context),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey.shade400, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Search NCERT chapters, PYQs…',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
            ),
            Icon(Icons.tune_rounded, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    ).animate().fade(delay: 100.ms, duration: 400.ms);
  }

  // ────────────────────────────────────────────────────────────
  // CHIP ROW
  // ────────────────────────────────────────────────────────────
  Widget _buildChipRow(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _chipLabels.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedChip == index;
          return GestureDetector(
            onTap: () {
              if (_chipLabels[index] == 'Error Book') {
                context.push('/error-book');
                return;
              }
              setState(() => _selectedChip = index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AdaptiveColors.surface(context),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))]
                    : [],
              ),
              child: Text(
                _chipLabels[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fade(delay: 150.ms, duration: 400.ms);
  }

  // ────────────────────────────────────────────────────────────
  // FEATURED SUBJECTS
  // ────────────────────────────────────────────────────────────
  Widget _buildFeaturedSubjectsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Featured Subjects',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _selectedChip = 0),
          child: Text(
            'See all',
            style: TextStyle(
              color: SubjectColors.physics,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ).animate().fade(delay: 180.ms, duration: 400.ms).slideX(begin: -0.06, end: 0);
  }

  Widget _buildFeaturedCards(BuildContext context, List<Subject> subjects, int totalMCQs) {
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = screenHeight < 600 ? 150.0 : 175.0;

    return SizedBox(
      height: cardHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final subject = subjects[index];
          final chapterCount = subject.chapters.length;
          final mcqCount = subject.chapters.fold<int>(0, (sum, ch) {
            return sum + ch.topics.fold<int>(0, (tSum, t) => tSum + t.questionCount);
          });

          final subjectStats = ref.watch(subjectStatsProvider(subject.name));
          final accuracy = subjectStats['accuracy'] as double;

          return _buildSubjectCard(
            context,
            subject: subject,
            chapterCount: chapterCount,
            mcqCount: mcqCount,
            accuracy: accuracy,
          ).animate(delay: (200 + index * 80).ms).fade(duration: 450.ms).scale(
                begin: const Offset(0.94, 0.94),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack,
              ).then().scale(
                begin: const Offset(1.03, 1.03),
                end: const Offset(1, 1),
                duration: AppDuration.normal,
                curve: Curves.elasticOut,
              );
        },
      ),
    );
  }

  Widget _buildSubjectCard(
    BuildContext context, {
    required Subject subject,
    required int chapterCount,
    required int mcqCount,
    required double accuracy,
  }) {
    final color = _getSubjectAccent(subject.id);
    return GestureDetector(
      onTap: () => context.push('/subjects/${subject.id}?subjectName=${Uri.encodeComponent(subject.name)}'),
      child: Container(
        width: 155,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.72)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thin accent bar
            Container(
              height: 3,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(_getSubjectIcon(subject.id), color: Colors.white, size: 30),
                Icon(Icons.bookmark_border_rounded, color: Colors.white70, size: 20),
              ],
            ),
            const Spacer(),
            Text(
              subject.name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              '$chapterCount Chapters • $mcqCount MCQs',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            if (accuracy > 0) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (accuracy / 100).clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // ONGOING SECTION
  // ────────────────────────────────────────────────────────────
  Widget _buildOngoingSectionHeader() {
    return Text(
      'Ongoing Progress',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    ).animate().fade(delay: 240.ms, duration: 400.ms);
  }

  // Daily Goal Card
  Widget _buildDailyGoalCard(BuildContext context, Map<String, dynamic> dailyGoal) {
    final completed = dailyGoal['completed'] as int;
    final target = dailyGoal['target'] as int;
    final progress = (dailyGoal['percent'] as double).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // Circular progress
          SizedBox(
            width: 56,
            height: 56,
            child: AnimatedBuilder(
              animation: _progressAnimController,
              builder: (context, child) {
                final animValue = _progressAnim?.value ?? 0.0;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: animValue,
                      strokeWidth: 5,
                      backgroundColor: AdaptiveColors.surface(context),
                      valueColor: AlwaysStoppedAnimation(
                        animValue >= 1.0 ? AppColors.success : SubjectColors.physics,
                      ),
                    ),
                    Center(
                      child: Text(
                        '${(animValue * 100).toInt()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: animValue >= 1.0 ? AppColors.success : SubjectColors.physics,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Goal',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completed / $target questions solved',
                  style: TextStyle(color: AppColors.textSubtle, fontSize: 12),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AdaptiveColors.surface(context),
                    valueColor: AlwaysStoppedAnimation(
                      progress >= 1.0 ? AppColors.success : SubjectColors.physics,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 260.ms, duration: 400.ms);
  }

  // Continue Studying CTA
  Widget _buildContinueStudyingCard(BuildContext context, List recentActivity, List<Subject> subjects) {
    final hasActivity = recentActivity.isNotEmpty;
    final lastAttempt = hasActivity ? recentActivity.first : null;
    final topicLabel = hasActivity ? _resolveTopicLabel(lastAttempt, subjects) : null;

    return GestureDetector(
      onTap: () {
        context.push('/study-plan');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              SubjectColors.physics.withValues(alpha: 0.9),
              SubjectColors.physics.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasActivity ? Icons.play_arrow_rounded : Icons.school_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasActivity ? 'Continue Studying' : 'Start Your First Quiz',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasActivity ? 'Pick up where you left off — $topicLabel' : 'Open Study Plan to begin your NEET prep',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white60, size: 16),
          ],
        ),
      ),
    ).animate().fade(delay: 280.ms, duration: 400.ms);
  }

  // Ongoing Revision Cards from recent activity
  Widget _buildOngoingRevisionCards(BuildContext context, List recentActivity, List<Subject> subjects) {
    if (recentActivity.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'Start a quiz to see your progress here!',
            style: TextStyle(color: AppColors.textSubtle, fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: recentActivity.take(3).map((attempt) {
        final topicLabel = _resolveTopicLabel(attempt, subjects);
        final subjectColor = _getSubjectAccent(attempt.subject.toLowerCase().replaceAll('y', '').trim());
        final accuracy = attempt.totalQuestions > 0
            ? ((attempt.score / attempt.totalQuestions) * 100)
            : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: subjectColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getSubjectIcon(attempt.subject.toLowerCase().replaceAll('y', '').trim()),
                  color: subjectColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topicLabel,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${attempt.score}/${attempt.totalQuestions} correct • ${_formatTime(attempt.timeSpentSeconds)}',
                      style: TextStyle(color: AppColors.textSubtle, fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (accuracy / 100).clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: AdaptiveColors.surface(context),
                        valueColor: AlwaysStoppedAnimation(
                          accuracy >= 70
                              ? AppColors.success
                              : accuracy >= 40
                                  ? AppColors.warning
                                  : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${accuracy.toStringAsFixed(0)}%',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // CBT Mock Test CTA
  Widget _buildCbtMockTestCard(BuildContext context, List<Subject> subjects) {
    // Subtitle derived from ExamConfig so it can't drift from the real pattern.
    final neet = ExamConfig.neet();
    final subtitle = '${neet.totalQuestionSlots} questions • '
        '${neet.totalDurationSeconds ~/ 60} minutes • '
        '+${neet.marksPerCorrect}/${neet.marksPerWrong}/0 marking';
    return GestureDetector(
      onTap: () {
        final allQuestions = ref.read(allQuestionsProvider).valueOrNull ?? [];
        final pool = ExamEngineService.validatePool(allQuestions);
        if (pool.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No valid questions available for the mock test.'),
            ),
          );
          return;
        }
        context.push('/cbt', extra: {
          'config': neet,
          'questionPool': pool,
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              SubjectColors.physics.withValues(alpha: 0.9),
              SubjectColors.physics.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.quiz_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start CBT Mock Test',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white60, size: 16),
          ],
        ),
      ),
    ).animate().fade(delay: 300.ms, duration: 400.ms);
  }

  // Resume Mock Test card — visible only while an in-progress checkpoint exists.
  Widget _buildResumeMockCard(BuildContext context) {
    final cp = ref.watch(activeCbtCheckpointProvider).valueOrNull;
    if (cp == null) return const SizedBox.shrink();

    final answered = cp.answersByIndex.values
        .where((v) => v != null && v.isNotEmpty)
        .length;
    final total =
        cp.sectionQuestionIds.fold<int>(0, (s, ids) => s + ids.length);
    final remaining = cp.remainingSecondsAt(DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          // Full pool so saved question IDs resolve on restore.
          final allQuestions =
              ref.read(allQuestionsProvider).valueOrNull ?? [];
          context.push('/cbt', extra: {
            'config': cp.config,
            'questionPool': allQuestions,
            'resumeCheckpoint': cp,
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.success.withValues(alpha: 0.9),
                AppColors.success.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history_toggle_off,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resume Mock Test',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$answered/$total answered • ${_fmtRemaining(remaining)} left',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Discard',
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                onPressed: () async {
                  await ref.read(examCheckpointServiceProvider).clear();
                  ref.invalidate(activeCbtCheckpointProvider);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtRemaining(int seconds) {
    if (seconds <= 0) return '0m';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    final s = seconds % 60;
    return m > 0 ? '${m}m' : '${s}s';
  }

  // Due Review Banner
  Widget _buildDueReviewBanner(BuildContext context, int dueCount) {
    return GestureDetector(
      onTap: () => context.push('/review'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              SubjectColors.chemistry.withValues(alpha: 0.9),
              SubjectColors.chemistry.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.replay_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spaced Repetition Due',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$dueCount cards due for review',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white60, size: 16),
          ],
        ),
      ),
    ).animate().fade(delay: 300.ms, duration: 400.ms);
  }

  // Weak Topics Banner
  Widget _buildWeakTopicsBanner(BuildContext context, List weakTopics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Weak Topics',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: weakTopics.take(4).map((topic) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                ),
                child: Text(
                  topic.name,
                  style: TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fade(delay: 320.ms, duration: 400.ms);
  }

  // ────────────────────────────────────────────────────────────
  // SHIMMER LOADING SKELETON
  // ────────────────────────────────────────────────────────────
  Widget _buildShimmerSkeleton(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile row skeleton
              Row(
                children: [
                  CircleAvatar(radius: 22, backgroundColor: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 14, width: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(7))),
                        const SizedBox(height: 6),
                        Container(height: 10, width: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5))),
                      ],
                    ),
                  ),
                  Container(width: 48, height: 28, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
                  const SizedBox(width: 8),
                  Container(width: 48, height: 28, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
                ],
              ),
              const SizedBox(height: 20),
              // Search bar skeleton
              Container(height: 46, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30))),
              const SizedBox(height: 16),
              // Chip row skeleton
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, __) => Container(width: 70, height: 34, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                ),
              ),
              const SizedBox(height: 24),
              // Featured subjects header skeleton
              Container(height: 18, width: 160, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9))),
              const SizedBox(height: 14),
              // Featured cards skeleton
              SizedBox(
                height: 175,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (_, __) => Container(
                    width: 155,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Ongoing header skeleton
              Container(height: 18, width: 140, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9))),
              const SizedBox(height: 14),
              // Daily goal card skeleton
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade200)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(height: 14, width: 100, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(7))),
                          const SizedBox(height: 8),
                          Container(height: 6, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(3))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // ────────────────────────────────────────────────────────────
  // HELPERS
  // ────────────────────────────────────────────────────────────
  Color _getSubjectAccent(String id) {
    switch (id.toLowerCase()) {
      case 'biology':
      case 'bio':
        return SubjectColors.biology;
      case 'physics':
      case 'phys':
        return SubjectColors.physics;
      case 'chemistry':
      case 'chem':
        return SubjectColors.chemistry;
      default:
        return SubjectColors.physics;
    }
  }

  IconData _getSubjectIcon(String id) {
    switch (id.toLowerCase()) {
      case 'biology':
      case 'bio':
        return Icons.eco_rounded;
      case 'physics':
      case 'phys':
        return Icons.bolt_rounded;
      case 'chemistry':
      case 'chem':
        return Icons.science_rounded;
      default:
        return Icons.school;
    }
  }

  String _resolveTopicLabel(QuizAttempt attempt, List<Subject> subjects) {
    if (attempt.testType == 'mock') return 'Mock Test';
    for (final subject in subjects) {
      for (final chapter in subject.chapters) {
        for (final topic in chapter.topics) {
          if (topic.id == attempt.topicId) return topic.name;
        }
      }
    }
    return attempt.subject.isNotEmpty ? attempt.subject : 'Practice';
  }

  String _formatTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s > 0 ? '${m}m ${s}s' : '${m}m';
  }
}

// ────────────────────────────────────────────────────────────
// SEARCH DELEGATE
// ────────────────────────────────────────────────────────────
class _NeetSearchDelegate extends SearchDelegate<String?> {
  final WidgetRef _ref;

  _NeetSearchDelegate(this._ref);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchBody(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchBody(context);
  }

  Widget _buildSearchBody(BuildContext context) {
    final subjects = _ref.read(subjectsProvider);
    final q = query.toLowerCase().trim();

    final results = <_SearchResult>[];

    for (final subject in subjects) {
      for (final chapter in subject.chapters) {
        for (final topic in chapter.topics) {
          if (q.isEmpty ||
              topic.name.toLowerCase().contains(q) ||
              chapter.name.toLowerCase().contains(q) ||
              subject.name.toLowerCase().contains(q)) {
            results.add(_SearchResult(
              topic: topic,
              subject: subject,
              chapter: chapter,
            ));
          }
        }
      }
    }

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              q.isEmpty ? 'Type to search chapters & topics' : 'No results for "$query"',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final r = results[index];
        final color = _getSubjectColor(r.subject.id);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(_getSubjectIconData(r.subject.id), color: color, size: 20),
          ),
          title: Text(r.topic.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${r.chapter.name} • ${r.subject.name}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          trailing: Text(
            '${r.topic.questionCount} Q',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          onTap: () {
            close(context, null);
            context.push('/topic/${r.topic.id}?subjectName=${Uri.encodeComponent(r.subject.name)}&chapterName=${Uri.encodeComponent(r.chapter.name)}');
          },
        );
      },
    );
  }

  static Color _getSubjectColor(String id) {
    switch (id.toLowerCase()) {
      case 'biology':
      case 'bio':
        return SubjectColors.biology;
      case 'physics':
      case 'phys':
        return SubjectColors.physics;
      case 'chemistry':
      case 'chem':
        return SubjectColors.chemistry;
      default:
        return SubjectColors.physics;
    }
  }

  static IconData _getSubjectIconData(String id) {
    switch (id.toLowerCase()) {
      case 'biology':
      case 'bio':
        return Icons.eco_rounded;
      case 'physics':
      case 'phys':
        return Icons.bolt_rounded;
      case 'chemistry':
      case 'chem':
        return Icons.science_rounded;
      default:
        return Icons.school;
    }
  }
}

class _SearchResult {
  final Topic topic;
  final Subject subject;
  final Chapter chapter;

  _SearchResult({required this.topic, required this.subject, required this.chapter});
}
