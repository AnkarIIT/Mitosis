import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/question_model.dart';
import '../../core/services/adaptive_engine_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class AdaptiveTestScreen extends ConsumerStatefulWidget {
  final List<Question> initialPool;
  final String subject;
  final int targetCount;

  const AdaptiveTestScreen({
    super.key,
    required this.initialPool,
    required this.subject,
    this.targetCount = 10,
  });

  @override
  ConsumerState<AdaptiveTestScreen> createState() => _AdaptiveTestScreenState();
}

class _AdaptiveTestScreenState extends ConsumerState<AdaptiveTestScreen> {
  late List<Question> _pool;
  final List<Question> _sessionQuestions = [];
  final List<bool> _correctnessHistory = [];
  QuestionBand _currentBand = QuestionBand.medium;
  int _currentIndex = 0;
  String? _selectedOption;
  bool _submitted = false;
  int _score = 0;
  final Set<String> _usedIds = {};

  @override
  void initState() {
    super.initState();
    _pool = List<Question>.from(widget.initialPool);
    _pickNextQuestion();
  }

  void _pickNextQuestion() {
    if (_sessionQuestions.length >= widget.targetCount || _pool.isEmpty) {
      setState(() {
        _submitted = true;
      });
      return;
    }

    // Try to find a question matching current band
    Question? nextQ;
    final bandStr = _currentBand.name.toLowerCase();

    final exactMatches = _pool.where((q) =>
        q.difficulty.toLowerCase() == bandStr && !_usedIds.contains(q.id)
    ).toList();

    if (exactMatches.isNotEmpty) {
      exactMatches.shuffle();
      nextQ = exactMatches.first;
    } else {
      // Fallback to any unused question in pool
      final available = _pool.where((q) => !_usedIds.contains(q.id)).toList();
      if (available.isNotEmpty) {
        available.shuffle();
        nextQ = available.first;
      }
    }

    if (nextQ != null) {
      _usedIds.add(nextQ.id);
      _sessionQuestions.add(nextQ);
    }
  }

  void _submitAnswer() {
    if (_selectedOption == null) return;
    final currentQ = _sessionQuestions[_currentIndex];
    final isCorrect = _selectedOption == currentQ.correctAnswer;

    setState(() {
      _correctnessHistory.add(isCorrect);
      if (isCorrect) _score += 4; else _score -= 1;
      _currentBand = AdaptiveEngineService.nextBand(_currentBand, isCorrect);
    });

    // Check if finished
    if (_currentIndex + 1 >= widget.targetCount || _sessionQuestions.length >= widget.targetCount) {
      setState(() {
        _submitted = true;
      });
    } else {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _pickNextQuestion();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted || _sessionQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Adaptive Practice Result')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, size: 80, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'Session Completed!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Final Score: $_score / ${_sessionQuestions.length * 4}'),
                const SizedBox(height: 16),
                Text('Ending Difficulty Band: ${_currentBand.name.toUpperCase()}'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Back to Practice Hub'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = _sessionQuestions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Adaptive ${widget.subject} • Band: ${_currentBand.name.toUpperCase()}'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Q ${_currentIndex + 1} / ${widget.targetCount}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: (_currentIndex + 1) / widget.targetCount),
            const SizedBox(height: 20),
            Text(
              question.questionText,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: question.options.map((option) {
                  final isSelected = _selectedOption == option;
                  return RadioListTile<String>(
                    title: Text(option),
                    value: option,
                    groupValue: _selectedOption,
                    onChanged: (val) {
                      setState(() {
                        _selectedOption = val;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedOption == null ? null : _submitAnswer,
                child: Text(_currentIndex + 1 >= widget.targetCount ? 'Finish Session' : 'Next Question'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
