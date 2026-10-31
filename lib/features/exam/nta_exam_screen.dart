import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/theme/app_colors.dart';
import '../../core/models/exam_model.dart';
import '../../core/models/question_model.dart';

class NTAExamScreen extends StatefulWidget {
  final List<Question> questions;
  final String title;
  final Duration examDuration;

  const NTAExamScreen({
    required this.questions,
    required this.title,
    this.examDuration = const Duration(minutes: 180),
    super.key,
  });

  @override
  State<NTAExamScreen> createState() => _NTAExamScreenState();
}

class _NTAExamScreenState extends State<NTAExamScreen> {
  late ExamSession _examSession;
  late Timer _timer;
  int _currentQuestion = 0;
  bool _showQuestionPalette = true;

  final Map<String, int> sectionCount = {
    'Biology': 0,
    'Chemistry': 0,
    'Physics': 0,
  };
  
  late List<Question> biologyQs;
  late List<Question> chemistryQs;
  late List<Question> physicsQs;

  @override
  void initState() {
    super.initState();

    biologyQs = widget.questions
        .where((q) => q.subject.toLowerCase() == 'biology')
        .toList();
    chemistryQs = widget.questions
        .where((q) => q.subject.toLowerCase() == 'chemistry')
        .toList();
    physicsQs = widget.questions
        .where((q) => q.subject.toLowerCase() == 'physics')
        .toList();

    sectionCount['Biology'] = biologyQs.length;
    sectionCount['Chemistry'] = chemistryQs.length;
    sectionCount['Physics'] = physicsQs.length;

    _examSession = ExamSession(
      id: 'neet_${DateTime.now().millisecondsSinceEpoch}',
      title: widget.title,
      questions: widget.questions
          .map((q) => ExamQuestion(question: q))
          .toList(),
      sectionedQuestions: {},
      totalDuration: widget.examDuration,
    );

    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        if (_examSession.remainingTime.inSeconds > 0) {
          _examSession.remainingTime =
              Duration(seconds: _examSession.remainingTime.inSeconds - 1);
        } else {
          _autoSubmit();
        }
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInstructions();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _showExitConfirmation();
        return false;
      },
      child: Scaffold(
        backgroundColor: Color(0xFF1a1a1a),
        appBar: _buildNTAAppBar(),
        body: _examSession.isSubmitted
            ? _buildResultScreen()
            : Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildQuestionPanel(),
                  ),
                  if (_showQuestionPalette)
                    Container(
                      width: 280,
                      color: Color(0xFF2a2a2a),
                      child: _buildQuestionPalette(),
                    ),
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget _buildNTAAppBar() {
    return AppBar(
      backgroundColor: Color(0xFF1a3a52),
      elevation: 0,
      title: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'National Test Abhyas | NEET (UG)',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 16),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _getTimerStatusColor(),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                _formatTime(_examSession.remainingTime),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionPanel() {
    final question = _examSession.questions[_currentQuestion];

    return Column(
      children: [
        Container(
          color: Color(0xFF2a2a2a),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${_currentQuestion + 1} of ${_examSession.questions.length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${question.question.subject} • ${question.question.chapter}',
                    style: TextStyle(
                      color: Color(0xFFB0B0B0),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: question.isMarkedForReview
                      ? Color(0xFFFCD34D).withOpacity(0.2)
                      : Colors.transparent,
                  border: Border.all(
                    color: question.isMarkedForReview
                        ? Color(0xFFFCD34D)
                        : Color(0xFF555555),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      question.isMarkedForReview
                          ? Icons.bookmark
                          : Icons.bookmark_outline,
                      color: question.isMarkedForReview
                          ? Color(0xFFFCD34D)
                          : Color(0xFF888888),
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Marked for Review',
                      style: TextStyle(
                        color: question.isMarkedForReview
                            ? Color(0xFFFCD34D)
                            : Color(0xFF888888),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.question.questionText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.6,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 28),
                ...List.generate(
                  question.question.options.length,
                  (index) => Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: _buildOptionButton(
                      letter: String.fromCharCode(65 + index),
                      text: question.question.options[index],
                      isSelected:
                          question.selectedAnswer ==
                          question.question.options[index],
                      onTap: () => _selectAnswer(
                        question.question.options[index],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          color: Color(0xFF2a2a2a),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: _currentQuestion > 0 ? _previousQuestion : null,
                icon: Icon(Icons.arrow_back, size: 16),
                label: Text('Previous'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF3a3a3a),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Color(0xFF2a2a2a),
                  disabledForegroundColor: Color(0xFF666666),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _toggleReview,
                    icon: Icon(
                      question.isMarkedForReview
                          ? Icons.bookmark
                          : Icons.bookmark_outline,
                      size: 16,
                    ),
                    label: Text('Mark for Review'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFFFCD34D),
                      side: BorderSide(color: Color(0xFFFCD34D)),
                      padding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _currentQuestion <
                            _examSession.questions.length - 1
                        ? _nextQuestion
                        : _showSubmitConfirmation,
                    icon: Icon(
                      _currentQuestion <
                              _examSession.questions.length - 1
                          ? Icons.arrow_forward
                          : Icons.done,
                      size: 16,
                    ),
                    label: Text(
                      _currentQuestion <
                              _examSession.questions.length - 1
                          ? 'Next'
                          : 'Submit',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0084D4),
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required String letter,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Color(0xFF0084D4) : Color(0xFF444444),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
          color: isSelected
              ? Color(0xFF0084D4).withOpacity(0.1)
              : Color(0xFF2a2a2a),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Color(0xFF0084D4) : Color(0xFF555555),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(2),
                color: isSelected ? Color(0xFF0084D4) : Colors.transparent,
              ),
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Color(0xFF888888),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isSelected ? Colors.white : Color(0xFFCCCCCC),
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionPalette() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(14),
          color: Color(0xFF1a1a1a),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Question Palette',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLegendItem('Answered', Color(0xFF10B981)),
                  _buildLegendItem('Not Ans.', Color(0xFF555555)),
                  _buildLegendItem('Marked', Color(0xFFFCD34D)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                _examSession.questions.length,
                (index) => _buildQuestionBox(index),
              ),
            ),
          ),
        ),
        Container(
          color: Color(0xFF1a1a1a),
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statistics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              _buildStatRow('Answered',
                  _getAnsweredCount().toString(), Color(0xFF10B981)),
              _buildStatRow('Not Answered',
                  _getUnansweredCount().toString(), Color(0xFF555555)),
              _buildStatRow('Marked Review',
                  _getMarkedCount().toString(), Color(0xFFFCD34D)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionBox(int index) {
    final q = _examSession.questions[index];
    final isCurrentQuestion = index == _currentQuestion;

    Color bgColor;
    if (q.status == QuestionStatus.attempted ||
        q.status == QuestionStatus.attemptedReview) {
      bgColor = Color(0xFF10B981);
    } else if (q.status == QuestionStatus.markedReview ||
        q.status == QuestionStatus.attemptedReview) {
      bgColor = Color(0xFFFCD34D);
    } else {
      bgColor = Color(0xFF555555);
    }

    return GestureDetector(
      onTap: () => setState(() => _currentQuestion = index),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: isCurrentQuestion ? Color(0xFF0084D4) : bgColor,
            width: isCurrentQuestion ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: bgColor == Color(0xFF555555) ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Color(0xFF888888),
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    final stats = _examSession.getStats();

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.check_circle, size: 80, color: Color(0xFF10B981)),
            SizedBox(height: 20),
            Text(
              'Exam Submitted!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 30),
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0084D4), Color(0xFF005AA8)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Your Score',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '${stats['score']} / 720',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Accuracy: ${((stats['correct'] / stats['totalQuestions']) * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildResultStat('Correct', '${stats['correct']}',
                    Color(0xFF10B981)),
                _buildResultStat('Incorrect', '${stats['incorrect']}',
                    Color(0xFFEF4444)),
                _buildResultStat('Unanswered',
                    '${stats['unanswered']}', Color(0xFF888888)),
                _buildResultStat('Marked Review',
                    '${stats['markedReview']}', Color(0xFFFCD34D)),
              ],
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Back to Home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0084D4),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultStat(String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF2a2a2a),
        border: Border.all(color: Color(0xFF444444)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Color(0xFF888888),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTimerStatusColor() {
    final seconds = _examSession.remainingTime.inSeconds;
    if (seconds > 900) return Color(0xFF059669);
    if (seconds > 300) return Color(0xFFD97706);
    return Color(0xFFDC2626);
  }

  String _formatTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _selectAnswer(String answer) {
    setState(() {
      _examSession.questions[_currentQuestion].updateStatus(answer);
    });
  }

  void _toggleReview() {
    setState(() {
      _examSession.questions[_currentQuestion].toggleReview();
    });
  }

  void _nextQuestion() {
    if (_currentQuestion < _examSession.questions.length - 1) {
      setState(() => _currentQuestion++);
    }
  }

  void _previousQuestion() {
    if (_currentQuestion > 0) {
      setState(() => _currentQuestion--);
    }
  }

  int _getAnsweredCount() {
    return _examSession.questions
        .where((q) =>
            q.status == QuestionStatus.attempted ||
            q.status == QuestionStatus.attemptedReview)
        .length;
  }

  int _getUnansweredCount() {
    return _examSession.questions
        .where((q) => q.status == QuestionStatus.unanswered)
        .length;
  }

  int _getMarkedCount() {
    return _examSession.questions.where((q) => q.isMarkedForReview).length;
  }

  void _showInstructions() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2a2a2a),
        title: Text(
          'NEET Exam Instructions',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInstructionText('✓ Correct Answer: +4 marks'),
              _buildInstructionText('✓ Wrong Answer: -1 mark'),
              _buildInstructionText('✓ Unanswered: 0 marks'),
              SizedBox(height: 12),
              _buildInstructionText('• Total Questions: ${_examSession.questions.length}'),
              _buildInstructionText('• Total Duration: 195 minutes'),
              _buildInstructionText('• Total Marks: 720'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Start Exam'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF0084D4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionText(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white70,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2a2a2a),
        title: Text('Exit Exam?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Your progress will be saved. You can resume later.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _showSubmitConfirmation() {
    final stats = _examSession.getStats();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2a2a2a),
        title: Text('Submit Exam?', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review your answers before submitting:',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            SizedBox(height: 12),
            _buildReviewStat('Attempted', '${stats['attempted']}'),
            _buildReviewStat('Not Attempted', '${stats['unanswered']}'),
            _buildReviewStat('Marked for Review', '${stats['markedReview']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Continue'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _examSession.submitExam());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF0084D4),
            ),
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStat(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
          Text(value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  void _autoSubmit() {
    _examSession.submitExam();
    setState(() {});
  }
}
