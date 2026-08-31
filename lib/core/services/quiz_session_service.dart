import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../database/drift_database.dart' as db;
import '../models/question_model.dart';

class QuizSessionService {
  final db.AppDatabase _db;

  QuizSessionService(this._db);

  /// Saves the current quiz state to the database.
  Future<void> saveSession({
    required String sessionId,
    required String topicId,
    required String subject,
    required String testType,
    required String quizMode,
    required int timeLimitSeconds,
    required int seed,
    required int currentIndex,
    required Map<int, String> selectedAnswers,
    required Map<int, bool> answerResults,
    required Map<int, int> timeSpentPerQuestion,
    required Set<int> flaggedQuestions,
    required Set<int> visitedQuestions,
    required int score,
    required int incorrectCount,
    required int elapsedSeconds,
    required bool isCompleted,
    required List<String> questionIds,
    List<Question>? questions,
  }) async {
    final companion = db.QuizSessionsCompanion(
      sessionId: Value(sessionId),
      topicId: Value(topicId),
      subject: Value(subject),
      testType: Value(testType),
      quizMode: Value(quizMode),
      timeLimitSeconds: Value(timeLimitSeconds),
      seed: Value(seed),
      currentIndex: Value(currentIndex),
      selectedAnswers: Value(jsonEncode(
        selectedAnswers.map((k, v) => MapEntry(k.toString(), v)),
      )),
      answerResults: Value(jsonEncode(
        answerResults.map((k, v) => MapEntry(k.toString(), v)),
      )),
      timeSpentPerQuestion: Value(jsonEncode(
        timeSpentPerQuestion.map((k, v) => MapEntry(k.toString(), v)),
      )),
      flaggedQuestions: Value(jsonEncode(flaggedQuestions.toList())),
      visitedQuestions: Value(jsonEncode(visitedQuestions.toList())),
      score: Value(score),
      incorrectCount: Value(incorrectCount),
      elapsedSeconds: Value(elapsedSeconds),
      isCompleted: Value(isCompleted),
      questionIds: Value(jsonEncode(questionIds)),
      questionData: questions != null
          ? Value(jsonEncode(questions.map((q) => q.toMap()).toList()))
          : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );

    await _db.upsertQuizSession(companion);
  }

  /// Restores a quiz session from the database.
  Future<QuizSessionData?> restoreSession(String sessionId) async {
    final session = await _db.getQuizSession(sessionId);
    if (session == null) return null;

    try {
      final selectedAnswers = (jsonDecode(session.selectedAnswers) as Map)
          .map((k, v) => MapEntry(int.parse(k), v as String));
      final answerResults = (jsonDecode(session.answerResults) as Map)
          .map((k, v) => MapEntry(int.parse(k), v as bool));
      final timeSpentPerQuestion = (jsonDecode(session.timeSpentPerQuestion) as Map)
          .map((k, v) => MapEntry(int.parse(k), v as int));
      final flaggedQuestions = Set<int>.from(
        (jsonDecode(session.flaggedQuestions) as List).cast<int>());
      final visitedQuestions = Set<int>.from(
        (jsonDecode(session.visitedQuestions) as List).cast<int>());
      final questionIds = (jsonDecode(session.questionIds) as List).cast<String>();

      List<Question>? questions;
      if (session.questionData != null && session.questionData!.isNotEmpty) {
        questions = (jsonDecode(session.questionData!) as List)
            .map((m) => Question.fromMap((m as Map).cast<String, dynamic>()))
            .toList();
      }

      return QuizSessionData(
        sessionId: session.sessionId,
        topicId: session.topicId,
        subject: session.subject,
        testType: session.testType,
        quizMode: session.quizMode,
        timeLimitSeconds: session.timeLimitSeconds,
        seed: session.seed,
        currentIndex: session.currentIndex,
        selectedAnswers: selectedAnswers,
        answerResults: answerResults,
        timeSpentPerQuestion: timeSpentPerQuestion,
        flaggedQuestions: flaggedQuestions,
        visitedQuestions: visitedQuestions,
        score: session.score,
        incorrectCount: session.incorrectCount,
        elapsedSeconds: session.elapsedSeconds,
        isCompleted: session.isCompleted,
        questionIds: questionIds,
        questions: questions,
      );
    } catch (e) {
      debugPrint('❌ Error restoring quiz session: $e');
      return null;
    }
  }

  /// Gets all saved sessions.
  Future<List<QuizSessionData>> getAllSessions() async {
    final sessions = await _db.getAllQuizSessions();
    return sessions.map((s) => _mapSession(s)).whereType<QuizSessionData>().toList();
  }

  QuizSessionData? _mapSession(db.QuizSession session) {
    try {
      final selectedAnswers = (jsonDecode(session.selectedAnswers) as Map)
          .map((k, v) => MapEntry(int.parse(k), v as String));
      final answerResults = (jsonDecode(session.answerResults) as Map)
          .map((k, v) => MapEntry(int.parse(k), v as bool));
      final timeSpentPerQuestion = (jsonDecode(session.timeSpentPerQuestion) as Map)
          .map((k, v) => MapEntry(int.parse(k), v as int));
      final flaggedQuestions = Set<int>.from(
        (jsonDecode(session.flaggedQuestions) as List).cast<int>());
      final visitedQuestions = Set<int>.from(
        (jsonDecode(session.visitedQuestions) as List).cast<int>());
      final questionIds = (jsonDecode(session.questionIds) as List).cast<String>();

      List<Question>? questions;
      if (session.questionData != null && session.questionData!.isNotEmpty) {
        questions = (jsonDecode(session.questionData!) as List)
            .map((m) => Question.fromMap((m as Map).cast<String, dynamic>()))
            .toList();
      }

      return QuizSessionData(
        sessionId: session.sessionId,
        topicId: session.topicId,
        subject: session.subject,
        testType: session.testType,
        quizMode: session.quizMode,
        timeLimitSeconds: session.timeLimitSeconds,
        seed: session.seed,
        currentIndex: session.currentIndex,
        selectedAnswers: selectedAnswers,
        answerResults: answerResults,
        timeSpentPerQuestion: timeSpentPerQuestion,
        flaggedQuestions: flaggedQuestions,
        visitedQuestions: visitedQuestions,
        score: session.score,
        incorrectCount: session.incorrectCount,
        elapsedSeconds: session.elapsedSeconds,
        isCompleted: session.isCompleted,
        questionIds: questionIds,
        questions: questions,
      );
    } catch (e) {
      debugPrint('❌ Error mapping quiz session: $e');
      return null;
    }
  }

  /// Deletes a session.
  Future<void> deleteSession(String sessionId) async {
    await _db.deleteQuizSession(sessionId);
  }

  /// Deletes all completed sessions.
  Future<void> deleteCompletedSessions() async {
    await _db.deleteCompletedQuizSessions();
  }
}

/// Data class for restored quiz session.
class QuizSessionData {
  final String sessionId;
  final String topicId;
  final String subject;
  final String testType;
  final String quizMode;
  final int timeLimitSeconds;
  final int seed;
  final int currentIndex;
  final Map<int, String> selectedAnswers;
  final Map<int, bool> answerResults;
  final Map<int, int> timeSpentPerQuestion;
  final Set<int> flaggedQuestions;
  final Set<int> visitedQuestions;
  final int score;
  final int incorrectCount;
  final int elapsedSeconds;
  final bool isCompleted;
  final List<String> questionIds;
  final List<Question>? questions;

  const QuizSessionData({
    required this.sessionId,
    required this.topicId,
    required this.subject,
    required this.testType,
    required this.quizMode,
    required this.timeLimitSeconds,
    required this.seed,
    required this.currentIndex,
    required this.selectedAnswers,
    required this.answerResults,
    required this.timeSpentPerQuestion,
    required this.flaggedQuestions,
    required this.visitedQuestions,
    required this.score,
    required this.incorrectCount,
    required this.elapsedSeconds,
    required this.isCompleted,
    required this.questionIds,
    this.questions,
  });
}