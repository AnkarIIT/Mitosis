import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/question_repository.dart';
import '../../core/models/question_model.dart';
import '../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String subject;
  const QuizScreen({super.key, required this.subject});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  List<Question> questions = [];
  int currentIndex = 0;
  int score = 0;
  String? selectedAnswer;
  bool isAnswered = false;

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    final repo = ref.read(questionRepositoryProvider);
    final loaded = await repo.getQuestionsBySubject(widget.subject);
    setState(() {
      questions = loaded.isEmpty ? [] : loaded;
    });
  }

  void selectAnswer(String answer) {
    if (isAnswered) return;
    setState(() {
      selectedAnswer = answer;
      isAnswered = true;
      if (answer == questions[currentIndex].correctAnswer) {
        score++;
      }
    });
  }

  void nextQuestion() {
    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedAnswer = null;
        isAnswered = false;
      });
    } else {
      // Show result
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Quiz Completed!"),
          content: Text("Your Score: $score / ${questions.length}"),
          actions: [
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text("Back to Home"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text("${widget.subject} Quiz")),
        body: const Center(child: Text("No questions available yet")),
      );
    }

    final q = questions[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.subject} - ${currentIndex + 1}/${questions.length}",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              q.questionText,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 30),
            ...q.options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  onPressed: () => selectAnswer(option),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedAnswer == option
                        ? AppColors.secondary.withValues(alpha: 0.5)
                        : null,
                    minimumSize: const Size(double.infinity, 60),
                  ),
                  child: Text(option, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),
            const Spacer(),
            if (isAnswered)
              ElevatedButton(
                onPressed: nextQuestion,
                child: Text(
                  currentIndex == questions.length - 1
                      ? "Finish Quiz"
                      : "Next Question",
                ),
              ),
          ],
        ),
      ),
    );
  }
}
