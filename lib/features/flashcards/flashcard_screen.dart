import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/flashcard_model.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  const FlashcardScreen({super.key});

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen> {
  final PageController _pageController = PageController();
  bool _isFlipped = false;
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final flashcards = ref.watch(flashcardsProvider);

    if (flashcards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Flashcards')),
        body: const Center(child: Text('No flashcards available yet.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revision Flashcards'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / flashcards.length,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              borderRadius: BorderRadius.circular(10),
              minHeight: 8,
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: flashcards.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _isFlipped = false;
                });
              },
              itemBuilder: (context, index) {
                return _buildFlashcard(flashcards[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _currentIndex > 0
                      ? () => _pageController.previousPage(
                            duration: 300.ms,
                            curve: Curves.easeInOut,
                          )
                      : null,
                  icon: const Icon(Icons.arrow_back_ios),
                  color: AppColors.primary,
                ),
                Text(
                  '${_currentIndex + 1} / ${flashcards.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  onPressed: _currentIndex < flashcards.length - 1
                      ? () => _pageController.nextPage(
                            duration: 300.ms,
                            curve: Curves.easeInOut,
                          )
                      : null,
                  icon: const Icon(Icons.arrow_forward_ios),
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcard(Flashcard card) {
    return GestureDetector(
      onTap: () => setState(() => _isFlipped = !_isFlipped),
      child: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          height: MediaQuery.of(context).size.height * 0.5,
          child: AnimatedSwitcher(
            duration: 400.ms,
            transitionBuilder: (Widget child, Animation<double> animation) {
              final rotate = Tween(begin: pi, end: 0.0).animate(animation);
              return AnimatedBuilder(
                animation: rotate,
                child: child,
                builder: (context, child) {
                  final isBack = child?.key == const ValueKey('back');
                  final value = isBack ? min(rotate.value, pi / 2) : rotate.value;
                  return Transform(
                    transform: Matrix4.rotationY(value),
                    alignment: Alignment.center,
                    child: value > pi / 2 ? const SizedBox() : child,
                  );
                },
              );
            },
            child: _isFlipped ? _buildBack(card) : _buildFront(card),
          ),
        ),
      ),
    );
  }

  Widget _buildFront(Flashcard card) {
    return Card(
      key: const ValueKey('front'),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              card.subject.toUpperCase(),
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              card.front,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            const Icon(Icons.touch_app, color: Colors.white54, size: 24),
            const SizedBox(height: 8),
            const Text(
              'Tap to flip',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBack(Flashcard card) {
    return Card(
      key: const ValueKey('back'),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context).cardColor,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
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
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              card.back,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 48),
            OutlinedButton(
              onPressed: () => setState(() => _isFlipped = false),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Show Question'),
            ),
          ],
        ),
      ),
    );
  }
}
