class SurveyResponse {
  final String id;
  final String surveyId;
  final String userId;
  final DateTime submittedAt;
  final DateTime createdAt;
  final List<SurveyAnswer> answers;

  const SurveyResponse({
    required this.id,
    required this.surveyId,
    required this.userId,
    required this.submittedAt,
    required this.createdAt,
    required this.answers,
  });

  SurveyResponse copyWith({
    String? id,
    String? surveyId,
    String? userId,
    DateTime? submittedAt,
    DateTime? createdAt,
    List<SurveyAnswer>? answers,
  }) {
    return SurveyResponse(
      id: id ?? this.id,
      surveyId: surveyId ?? this.surveyId,
      userId: userId ?? this.userId,
      submittedAt: submittedAt ?? this.submittedAt,
      createdAt: createdAt ?? this.createdAt,
      answers: answers ?? this.answers,
    );
  }

  // Convert to Firestore map (following database schema)
  Map<String, dynamic> toFirestoreMap() {
    return {
      'survey_id': surveyId,
      'user_id': userId,
      'submitted_at': submittedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'survey_id': surveyId,
      'user_id': userId,
      'submitted_at': submittedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'answers': answers.map((a) => a.toJson()).toList(),
    };
  }

  factory SurveyResponse.fromJson(Map<String, dynamic> json) {
    return SurveyResponse(
      id: json['id'] as String,
      surveyId: json['survey_id'] as String,
      userId: json['user_id'] as String,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      answers: (json['answers'] as List<dynamic>?)
              ?.map((a) => SurveyAnswer.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SurveyAnswer {
  final String id;
  final String surveyResponseId;
  final String surveyQuestionId;
  final String? answerValue;
  final List<String>? selectedOptions;
  final DateTime createdAt;

  const SurveyAnswer({
    required this.id,
    required this.surveyResponseId,
    required this.surveyQuestionId,
    this.answerValue,
    this.selectedOptions,
    required this.createdAt,
  });

  SurveyAnswer copyWith({
    String? id,
    String? surveyResponseId,
    String? surveyQuestionId,
    String? answerValue,
    List<String>? selectedOptions,
    DateTime? createdAt,
  }) {
    return SurveyAnswer(
      id: id ?? this.id,
      surveyResponseId: surveyResponseId ?? this.surveyResponseId,
      surveyQuestionId: surveyQuestionId ?? this.surveyQuestionId,
      answerValue: answerValue ?? this.answerValue,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convert to Firestore map (following database schema)
  Map<String, dynamic> toFirestoreMap() {
    return {
      'survey_response_id': surveyResponseId,
      'survey_question_id': surveyQuestionId,
      'answer_value': answerValue,
      'selected_options': selectedOptions,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'survey_response_id': surveyResponseId,
      'survey_question_id': surveyQuestionId,
      'answer_value': answerValue,
      'selected_options': selectedOptions,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SurveyAnswer.fromJson(Map<String, dynamic> json) {
    return SurveyAnswer(
      id: json['id'] as String,
      surveyResponseId: json['survey_response_id'] as String,
      surveyQuestionId: json['survey_question_id'] as String,
      answerValue: json['answer_value'] as String?,
      selectedOptions: json['selected_options'] != null
          ? List<String>.from(json['selected_options'])
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class SurveySummary {
  final String surveyId;
  final int totalQuestions;
  final int totalResponses;
  final DateTime? lastResponseAt;

  const SurveySummary({
    required this.surveyId,
    required this.totalQuestions,
    required this.totalResponses,
    this.lastResponseAt,
  });

  SurveySummary copyWith({
    String? surveyId,
    int? totalQuestions,
    int? totalResponses,
    DateTime? lastResponseAt,
  }) {
    return SurveySummary(
      surveyId: surveyId ?? this.surveyId,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      totalResponses: totalResponses ?? this.totalResponses,
      lastResponseAt: lastResponseAt ?? this.lastResponseAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'survey_id': surveyId,
      'total_questions': totalQuestions,
      'total_responses': totalResponses,
      'last_response_at': lastResponseAt?.toIso8601String(),
    };
  }

  factory SurveySummary.fromJson(Map<String, dynamic> json) {
    return SurveySummary(
      surveyId: json['survey_id'] as String,
      totalQuestions: json['total_questions'] as int,
      totalResponses: json['total_responses'] as int,
      lastResponseAt: json['last_response_at'] != null
          ? DateTime.parse(json['last_response_at'] as String)
          : null,
    );
  }
}
