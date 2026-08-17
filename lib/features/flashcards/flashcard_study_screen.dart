import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/flashcard_model.dart';
import '../../core/providers/providers.dart';
import '../../core/services/flashcard_scheduler_service.dart';
import '../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

/// Dedicated study screen: flip card → rate → next.
///
/// Consumes [dueFlashcardsProvider] so it only shows cards that are due
/// for review. Each rating persists the new schedule via the database and
/// invalidates the provider to refresh the queue.
class FlashcardStudyScreen extends ConsumerStatefulWidget {
  const FlashcardStudyScreen({super.key});

  @override
  ConsumerState<FlashcardStudyScreen> createState() =>
      _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends ConsumerState<FlashcardStudyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFlipped = false;
  bool _showRatingBar = false;
  int _currentIndex = 0;
  int _reviewed = 0;
  List<Flashcard> _queue = [];

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
      _showRatingBar = _isFlipped;
    });
  }

  Future<void> _rate(FlashcardRating rating) async {
    if (_currentIndex >= _queue.length) return;
    final card = _queue[_currentIndex];
    final db = ref.read(databaseProvider);

    final result = FlashcardScheduler.review(
      rating: rating,
      box: card.box,
      easeFactor: card.easeFactor,
      intervalDays: card.intervalDays,
      repetitions: card.repetitions,
      lapses: card.lapses,
    );

    await db.updateFlashcardSchedule(
      card.id,
      box: result.box,
      easeFactor: result.easeFactor,
      intervalDays: result.intervalDays,
      repetitions: result.repetitions,
      lapses: result.lapses,
      dueAt: result.dueAt,
      lastReviewedAt: DateTime.now(),
    );

    setState(() {
      _reviewed += 1;
      _isFlipped = false;
      _showRatingBar = false;
      _currentIndex += 1;
    });
    _flipController.reset();
    ref.invalidate(flashcardsFromDbProvider);
    ref.invalidate(dueFlashcardsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final dueAsync = ref.watch(dueFlashcardsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcard Review'),
        elevation: 0,
      ),
      body: dueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cards) {
          _queue = cards;
          if (cards.isEmpty) {
            return _buildEmptyState();
          }
          if (_currentIndex >= cards.length) {
            return _buildSessionComplete();
          }
          return _buildStudyBody(cards[_currentIndex]);
        },
      ),
    );
  }

  Widget _buildStudyBody(Flashcard card) {
    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / _queue.length,
                    minHeight: 6,
                    backgroundColor: AppColors.premiumChipBg,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.physicsBlue),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_currentIndex + 1}/${_queue.length}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Reviewed: $_reviewed',
          style: TextStyle(color: AppColors.textSubtle, fontSize: 12),
        ),

        // Card area
        Expanded(
          child: GestureDetector(
            onTap: _flipCard,
            child: Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.88,
                height: MediaQuery.of(context).size.height * 0.48,
                child: AnimatedBuilder(
                  animation: _flipAnimation,
                  builder: (context, child) {
                    final angle = _flipAnimation.value * pi;
                    final isBack = angle > pi / 2;
                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(isBack ? pi - angle : angle),
                      alignment: Alignment.center,
                      child: isBack
                          ? Transform(
                              transform: Matrix4.identity()..rotateY(pi),
                              alignment: Alignment.center,
                              child: _buildBack(card),
                            )
                          : _buildFront(card),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        // Rating bar — only visible after flip
        if (_showRatingBar)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Row(
              children: [
                _buildRatingButton(
                  label: 'Again',
                  icon: Icons.close_rounded,
                  color: AppColors.error,
                  onTap: () => _rate(FlashcardRating.again),
                ),
                const SizedBox(width: 8),
                _buildRatingButton(
                  label: 'Hard',
                  icon: Icons.sentiment_dissatisfied_rounded,
                  color: AppColors.warning,
                  onTap: () => _rate(FlashcardRating.hard),
                ),
                const SizedBox(width: 8),
                _buildRatingButton(
                  label: 'Good',
                  icon: Icons.sentiment_satisfied_rounded,
                  color: AppColors.physicsBlue,
                  onTap: () => _rate(FlashcardRating.good),
                ),
                const SizedBox(width: 8),
                _buildRatingButton(
                  label: 'Easy',
                  icon: Icons.sentiment_very_satisfied_rounded,
                  color: AppColors.success,
                  onTap: () => _rate(FlashcardRating.easy),
                ),
              ],
            ),
          ),

        // Hint when not flipped
        if (!_showRatingBar)
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Text(
              'Tap to flip',
              style: TextStyle(color: AppColors.textSubtle, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _buildFront(Flashcard card) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              card.subject.toUpperCase(),
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              card.front,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const Spacer(),
            if (card.difficulty.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  card.difficulty,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBack(Flashcard card) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context).cardColor,
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'ANSWER',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  card.back,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
                ),
              ),
            ),
            if (card.ncertReference.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _openNcertReference(card),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.physicsBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.book_outlined,
                          size: 14, color: AppColors.physicsBlue),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          card.ncertReference,
                          style: TextStyle(
                            color: AppColors.physicsBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 72, color: AppColors.success),
          const SizedBox(height: 20),
          const Text(
            'All caught up!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'No flashcards due for review right now.',
            style: TextStyle(color: AppColors.textSubtle, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Generated cards will appear here when due.',
            style: TextStyle(color: AppColors.textSubtle, fontSize: 12),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('BACK TO FLASHCARDS'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionComplete() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.celebration_rounded,
              size: 72, color: AppColors.physicsBlue),
          const SizedBox(height: 20),
          Text(
            'Session Complete!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'You reviewed $_reviewed card${_reviewed == 1 ? '' : 's'}',
            style: TextStyle(color: AppColors.textSubtle, fontSize: 14),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('BACK TO FLASHCARDS'),
          ),
        ],
      ),
    );
  }

  void _openNcertReference(Flashcard card) {
    if (card.sourcePage <= 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('NCERT Reference: ${card.ncertReference} (p.${card.sourcePage})'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
