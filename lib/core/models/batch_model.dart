import 'dart:convert';

enum BatchType {
  class11_2026,
  class12_2026,
  dropper_2026,
  class11_2027,
  class12_2027,
  dropper_2027,
}

extension BatchTypeExtension on BatchType {
  String get displayName {
    switch (this) {
      case BatchType.class11_2026:
        return 'Class 11 (2026)';
      case BatchType.class12_2026:
        return 'Class 12 (2026)';
      case BatchType.dropper_2026:
        return 'Dropper (2026)';
      case BatchType.class11_2027:
        return 'Class 11 (2027)';
      case BatchType.class12_2027:
        return 'Class 12 (2027)';
      case BatchType.dropper_2027:
        return 'Dropper (2027)';
    }
  }

  String get studyLevel {
    switch (this) {
      case BatchType.class11_2026:
      case BatchType.class11_2027:
        return 'Class 11';
      case BatchType.class12_2026:
      case BatchType.class12_2027:
        return 'Class 12';
      case BatchType.dropper_2026:
      case BatchType.dropper_2027:
        return 'Dropper';
    }
  }

  int get targetScoreBase {
    switch (this) {
      case BatchType.class11_2026:
      case BatchType.class11_2027:
        return 500;
      case BatchType.class12_2026:
      case BatchType.class12_2027:
        return 600;
      case BatchType.dropper_2026:
      case BatchType.dropper_2027:
        return 650;
    }
  }
}

class UserBatch {
  final BatchType type;
  final StudyMode studyMode;
  final int dailyGoalHours;
  final DateTime startDate;
  final DateTime examDate;

  UserBatch({
    required this.type,
    required this.studyMode,
    required this.dailyGoalHours,
    DateTime? startDate,
    DateTime? examDate,
  }) : startDate = startDate ?? DateTime.now(),
       examDate = examDate ?? DateTime.now().add(const Duration(days: 365));

  UserBatch copyWith({
    BatchType? type,
    StudyMode? studyMode,
    int? dailyGoalHours,
    DateTime? startDate,
    DateTime? examDate,
  }) {
    return UserBatch(
      type: type ?? this.type,
      studyMode: studyMode ?? this.studyMode,
      dailyGoalHours: dailyGoalHours ?? this.dailyGoalHours,
      startDate: startDate ?? this.startDate,
      examDate: examDate ?? this.examDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'studyMode': studyMode.toString().split('.').last,
      'dailyGoalHours': dailyGoalHours,
      'startDate': startDate.toIso8601String(),
      'examDate': examDate.toIso8601String(),
    };
  }

  factory UserBatch.fromJson(String json) {
    final map = jsonDecode(json);
    return UserBatch(
      type: BatchType.values.firstWhere(
        (b) => b.toString().split('.').last == map['type'],
      ),
      studyMode: StudyMode.values.firstWhere(
        (s) => s.toString().split('.').last == map['studyMode'],
      ),
      dailyGoalHours: map['dailyGoalHours'] ?? 2,
      startDate: DateTime.parse(map['startDate']),
      examDate: DateTime.parse(map['examDate']),
    );
  }
}

enum StudyMode { selfStudy, coachingStudent, onlineCourse }

extension StudyModeExtension on StudyMode {
  String get label {
    switch (this) {
      case StudyMode.selfStudy:
        return 'Self Study';
      case StudyMode.coachingStudent:
        return 'Coaching Student';
      case StudyMode.onlineCourse:
        return 'Online Course';
    }
  }
}
