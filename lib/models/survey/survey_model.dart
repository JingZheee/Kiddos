import 'package:flutter/material.dart';

enum SurveyStatus {
  draft,
  published,
  closed;

  String get displayName {
    switch (this) {
      case SurveyStatus.draft:
        return 'Draft';
      case SurveyStatus.published:
        return 'Published';
      case SurveyStatus.closed:
        return 'Closed';
    }
  }

  Color get color {
    switch (this) {
      case SurveyStatus.draft:
        return Colors.orange;
      case SurveyStatus.published:
        return Colors.green;
      case SurveyStatus.closed:
        return Colors.grey;
    }
  }
}

enum TargetAudience {
  allStudents,
  specificClasses,
  yearGroups,
  individualStudents;

  String get displayName {
    switch (this) {
      case TargetAudience.allStudents:
        return 'All Students';
      case TargetAudience.specificClasses:
        return 'Specific Classes';
      case TargetAudience.yearGroups:
        return 'Year Groups';
      case TargetAudience.individualStudents:
        return 'Individual Students';
    }
  }

  IconData get icon {
    switch (this) {
      case TargetAudience.allStudents:
        return Icons.groups;
      case TargetAudience.specificClasses:
        return Icons.class_;
      case TargetAudience.yearGroups:
        return Icons.cake;
      case TargetAudience.individualStudents:
        return Icons.person;
    }
  }
}

enum QuestionType {
  multipleChoiceSingle,
  multipleChoiceMultiple,
  openText;

  String get displayName {
    switch (this) {
      case QuestionType.multipleChoiceSingle:
        return 'Multiple Choice (Single)';
      case QuestionType.multipleChoiceMultiple:
        return 'Multiple Choice (Multiple)';
      case QuestionType.openText:
        return 'Open Text';
    }
  }

  IconData get icon {
    switch (this) {
      case QuestionType.multipleChoiceSingle:
        return Icons.radio_button_checked;
      case QuestionType.multipleChoiceMultiple:
        return Icons.check_box;
      case QuestionType.openText:
        return Icons.short_text;
    }
  }
}

class SurveyModel {
  final String id;
  final int kindergartenId;
  final String title;
  final String? description;
  final int createdByUserId;
  final DateTime? startDate;
  final DateTime? endDate;
  final SurveyStatus status;
  final TargetAudience targetAudience;
  final List<int> targetClassIds;
  final List<int> targetStudentIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SurveyQuestion> questions;
  const SurveyModel({
    required this.id,
    required this.kindergartenId,
    required this.title,
    this.description,
    required this.createdByUserId,
    this.startDate,
    this.endDate,
    required this.status,
    required this.targetAudience,
    required this.targetClassIds,
    required this.targetStudentIds,
    required this.createdAt,
    required this.updatedAt,
    required this.questions,
  });
  SurveyModel copyWith({
    String? id,
    int? kindergartenId,
    String? title,
    String? description,
    int? createdByUserId,
    DateTime? startDate,
    DateTime? endDate,
    SurveyStatus? status,
    TargetAudience? targetAudience,
    List<int>? targetClassIds,
    List<int>? targetStudentIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SurveyQuestion>? questions,
  }) {
    return SurveyModel(
      id: id ?? this.id,
      kindergartenId: kindergartenId ?? this.kindergartenId,
      title: title ?? this.title,
      description: description ?? this.description,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      targetAudience: targetAudience ?? this.targetAudience,
      targetClassIds: targetClassIds ?? this.targetClassIds,
      targetStudentIds: targetStudentIds ?? this.targetStudentIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      questions: questions ?? this.questions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kindergarten_id': kindergartenId,
      'title': title,
      'description': description,
      'created_by_user_id': createdByUserId,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'status': status.name,
      'target_audience': targetAudience.name,
      'target_class_ids': targetClassIds,
      'target_student_ids': targetStudentIds,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }

  factory SurveyModel.fromJson(Map<String, dynamic> json) {
    return SurveyModel(
      id: json['id'] as String,
      kindergartenId: _parseToInt(json['kindergarten_id']),
      title: json['title'] as String,
      description: json['description'] as String?,
      createdByUserId: _parseToInt(json['created_by_user_id']),
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      status: SurveyStatus.values.byName(json['status'] as String),
      targetAudience:
          TargetAudience.values.byName(json['target_audience'] as String),
      targetClassIds: _parseToIntList(json['target_class_ids']),
      targetStudentIds: _parseToIntList(json['target_student_ids']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      questions: (json['questions'] as List<dynamic>?)
              ?.map((q) => SurveyQuestion.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  // Helper method to safely parse to int
  static int _parseToInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Helper method to safely parse to int list
  static List<int> _parseToIntList(dynamic value) {
    if (value is List) {
      return value.map((item) => _parseToInt(item)).toList();
    }
    return [];
  }
}

class SurveyQuestion {
  final String id;
  final String surveyId;
  final String questionText;
  final QuestionType questionType;
  final int orderIndex;
  final bool isRequired;
  final String? validationRules;
  final List<QuestionOption> options;
  const SurveyQuestion({
    required this.id,
    required this.surveyId,
    required this.questionText,
    required this.questionType,
    required this.orderIndex,
    required this.isRequired,
    this.validationRules,
    required this.options,
  });
  SurveyQuestion copyWith({
    String? id,
    String? surveyId,
    String? questionText,
    QuestionType? questionType,
    int? orderIndex,
    bool? isRequired,
    String? validationRules,
    List<QuestionOption>? options,
  }) {
    return SurveyQuestion(
      id: id ?? this.id,
      surveyId: surveyId ?? this.surveyId,
      questionText: questionText ?? this.questionText,
      questionType: questionType ?? this.questionType,
      orderIndex: orderIndex ?? this.orderIndex,
      isRequired: isRequired ?? this.isRequired,
      validationRules: validationRules ?? this.validationRules,
      options: options ?? this.options,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'survey_id': surveyId,
      'question_text': questionText,
      'question_type': questionType.name,
      'order_index': orderIndex,
      'is_required': isRequired,
      'validation_rules': validationRules,
      'options': options.map((o) => o.toJson()).toList(),
    };
  }

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) {
    return SurveyQuestion(
      id: json['id'] as String,
      surveyId: json['survey_id'] as String,
      questionText: json['question_text'] as String,
      questionType: QuestionType.values.byName(json['question_type'] as String),
      orderIndex: SurveyModel._parseToInt(json['order_index']),
      isRequired: json['is_required'] as bool? ?? false,
      validationRules: json['validation_rules'] as String?,
      options: (json['options'] as List<dynamic>?)
              ?.map((o) => QuestionOption.fromJson(o as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class QuestionOption {
  final String id;
  final String questionId;
  final String optionText;
  final int orderIndex;
  const QuestionOption({
    required this.id,
    required this.questionId,
    required this.optionText,
    required this.orderIndex,
  });
  QuestionOption copyWith({
    String? id,
    String? questionId,
    String? optionText,
    int? orderIndex,
  }) {
    return QuestionOption(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      optionText: optionText ?? this.optionText,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_id': questionId,
      'option_text': optionText,
      'order_index': orderIndex,
    };
  }

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      id: json['id'] as String,
      questionId: json['question_id'] as String,
      optionText: json['option_text'] as String,
      orderIndex: SurveyModel._parseToInt(json['order_index']),
    );
  }
}
