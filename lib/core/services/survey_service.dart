import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/survey/survey_model.dart';
import '../../models/survey/survey_response_model.dart';

class SurveyService {
  static final SurveyService _instance = SurveyService._internal();
  factory SurveyService() => _instance;
  SurveyService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Gets the current user's kindergarten ID
  String get _currentKindergartenId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    // TODO: Get kindergarten ID from user document or custom claims
    // For now, using a mock kindergarten ID
    return 'kindergarten_1';
  }

  /// Gets the current user ID
  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.uid;
  }

  /// Helper method to find Firestore document by string ID
  Future<DocumentSnapshot?> _findSurveyDocument(String surveyId) async {
    try {
      final doc = await _firestore
          .collection('surveys')
          .doc(surveyId)
          .get();

      // Check if document exists and belongs to current kindergarten
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['kindergarten_id'] == _currentKindergartenId) {
          return doc;
        }
      }
      return null;
    } catch (error) {
      if (kDebugMode) {
        print('Error finding survey document: $error');
      }
      return null;
    }
  }

  /// Helper method to save survey questions as separate documents
  Future<void> _saveSurveyQuestions(String surveyFirestoreId, List<SurveyQuestion> questions) async {
    final batch = _firestore.batch();
    
    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      // Convert options to JSON format
      final optionsJson = question.options.map((option) => {
        'value': option.id,
        'label': option.optionText,
        'order_index': option.orderIndex,
      }).toList();
      
      final questionData = {
        'survey_id': surveyFirestoreId,
        'question_text': question.questionText,
        'question_type': question.questionType.name,
        'order_index': i, // Use the index as order
        'is_required': question.isRequired,
        'validation_rules': question.validationRules,
        'options': optionsJson, // Store options as JSON array
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Create question document with embedded options
      final questionDocRef = _firestore.collection('survey_questions').doc();
      batch.set(questionDocRef, questionData);
    }
    
    await batch.commit();
  }

  /// Helper method to load survey questions for a survey
  Future<List<SurveyQuestion>> _loadSurveyQuestions(String surveyFirestoreId) async {
    try {
      // Use simple query without ordering to avoid index requirement
      final questionsSnapshot = await _firestore
          .collection('survey_questions')
          .where('survey_id', isEqualTo: surveyFirestoreId)
          .get();

      final List<SurveyQuestion> questions = [];
      
      for (final questionDoc in questionsSnapshot.docs) {
        try {
          final questionData = questionDoc.data();
          
          if (kDebugMode) {
            print('Processing question document: ${questionDoc.id}');
            print('Question data types: ${questionData.map((key, value) => MapEntry(key, value.runtimeType))}');
          }
          
          // Parse options from JSON with safe parsing
          final optionsData = questionData['options'] as List<dynamic>? ?? [];
          final options = optionsData.map((optionJson) {
            final optionMap = optionJson as Map<String, dynamic>;
            return QuestionOption(
              id: optionMap['value'] as String? ?? '0',
              questionId: questionDoc.id,
              optionText: optionMap['label'] as String? ?? '',
              orderIndex: _safeParseInt(optionMap['order_index']) ?? 0,
            );
          }).toList();
          
          questions.add(SurveyQuestion(
            id: questionDoc.id,
            surveyId: surveyFirestoreId,
            questionText: questionData['question_text'] as String? ?? '',
            questionType: QuestionType.values.byName(questionData['question_type'] as String? ?? 'openText'),
            orderIndex: _safeParseInt(questionData['order_index']) ?? 0,
            isRequired: questionData['is_required'] as bool? ?? false,
            validationRules: questionData['validation_rules'] as String?,
            options: options,
          ));
        } catch (questionError) {
          if (kDebugMode) {
            print('Error processing question ${questionDoc.id}: $questionError');
          }
          // Skip this question and continue
          continue;
        }
      }
      
      // Sort questions by order_index in memory
      questions.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      
      return questions;
    } catch (error) {
      if (kDebugMode) {
        print('Error loading survey questions: $error');
      }
      return [];
    }
  }
  
  /// Helper method to safely parse integers from dynamic values
  int? _safeParseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  /// Helper method to delete all questions and options for a survey
  Future<void> _deleteSurveyQuestions(String surveyFirestoreId) async {
    try {
      // Get all questions for this survey
      final questionsSnapshot = await _firestore
          .collection('survey_questions')
          .where('survey_id', isEqualTo: surveyFirestoreId)
          .get();

      final batch = _firestore.batch();

      // Delete questions (options are embedded, so no separate deletion needed)
      for (final questionDoc in questionsSnapshot.docs) {
        batch.delete(questionDoc.reference);
      }

      await batch.commit();
    } catch (error) {
      print('Error deleting survey questions: $error');
    }
  }

  /// Helper method to build SurveyModel objects from Firestore documents
  Future<List<SurveyModel>> _buildSurveyModelsFromDocs(List<QueryDocumentSnapshot> docs) async {
    final List<SurveyModel> surveys = [];
    
    for (final doc in docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        // Use Firestore document ID directly as string
        data['id'] = doc.id;
        
        if (kDebugMode) {
          print('Processing survey document: ${doc.id}');
          print('Raw data types: ${data.map((key, value) => MapEntry(key, value.runtimeType))}');
        }
        
        // Load questions for this survey
        final questions = await _loadSurveyQuestions(doc.id);
        data['questions'] = questions.map((q) => q.toJson()).toList();
        
        final survey = SurveyModel.fromJson(data);
        surveys.add(survey);
      } catch (error) {
        if (kDebugMode) {
          print('Error processing survey document ${doc.id}: $error');
          print('Document data: ${doc.data()}');
        }
        // Skip this document and continue with others
        continue;
      }
    }
    
    return surveys;
  }

  /// Fetches all surveys for the current kindergarten
  Future<List<SurveyModel>> fetchSurveys() async {
    try {
      // Try with ordering first - requires composite index
      var querySnapshot = await _firestore
          .collection('surveys')
          .where('kindergarten_id', isEqualTo: _currentKindergartenId)
          .orderBy('created_at', descending: true)
          .get();

      return await _buildSurveyModelsFromDocs(querySnapshot.docs);
    } catch (error) {
      // If composite index doesn't exist, fall back to simple query without ordering
      try {
        if (kDebugMode) {
          print('Firestore composite index not found, using simple query...');
        }
        var querySnapshot = await _firestore
            .collection('surveys')
            .where('kindergarten_id', isEqualTo: _currentKindergartenId)
            .get();

        var surveys = await _buildSurveyModelsFromDocs(querySnapshot.docs);
        
        // Sort in memory by created_at
        surveys.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return surveys;
      } catch (fallbackError) {
        if (kDebugMode) {
          print('Firestore error: $fallbackError');
        }
        // Throw the error instead of returning mock data
        throw Exception('Failed to fetch surveys from Firebase: $fallbackError');
      }
    }
  }

  /// Fetches a specific survey by ID
  Future<SurveyModel?> fetchSurveyById(String surveyId) async {
    try {
      // Try to fetch from Firebase first
      final doc = await _findSurveyDocument(surveyId);
      
      if (doc != null) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        // Load questions for this survey
        final questions = await _loadSurveyQuestions(doc.id);
        data['questions'] = questions.map((q) => q.toJson()).toList();
        
        return SurveyModel.fromJson(data);
      }

      // Return null if not found
      return null;
    } catch (error) {
      if (kDebugMode) {
        print('Error fetching survey by ID: $error');
      }
      throw Exception('Failed to fetch survey from Firebase: $error');
    }
  }

  /// Deletes a survey by ID
  Future<bool> deleteSurvey(String surveyId) async {
    try {
      // Find the survey document
      final doc = await _findSurveyDocument(surveyId);

      if (doc != null) {
        // Delete survey questions and options first (cascade delete)
        await _deleteSurveyQuestions(doc.id);
        
        // Then delete the survey document
        await doc.reference.delete();
        return true;
      }

      // If not found in Firebase, still return true (might be mock data)
      return true;
    } catch (error) {
      throw Exception('Failed to delete survey: $error');
    }
  }

  /// Saves a survey as draft
  Future<bool> saveSurveyDraft({
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    TargetAudience? targetAudience,
    List<int>? selectedClassIds,
    List<int>? selectedStudentIds,
    String? selectedYearGroup,
    List<SurveyQuestion>? questions,
  }) async {
    try {
      final now = DateTime.now();
      final surveyData = {
        'kindergarten_id': _currentKindergartenId,
        'title': title,
        'description': description,
        'created_by_user_id': _currentUserId,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'status': SurveyStatus.draft.name,
        'target_audience': (targetAudience ?? TargetAudience.allStudents).name,
        'target_class_ids': selectedClassIds ?? [],
        'target_student_ids': selectedStudentIds ?? [],
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      // Create survey document first
      final surveyDocRef = await _firestore.collection('surveys').add(surveyData);
      
      // Save questions as separate documents if provided
      if (questions != null && questions.isNotEmpty) {
        await _saveSurveyQuestions(surveyDocRef.id, questions);
      }
      
      return true;
    } catch (error) {
      throw Exception('Failed to save draft: $error');
    }
  }

  /// Publishes a survey
  Future<bool> publishSurvey({
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    required TargetAudience targetAudience,
    List<int>? selectedClassIds,
    List<int>? selectedStudentIds,
    String? selectedYearGroup,
    required List<SurveyQuestion> questions,
  }) async {
    try {
      final now = DateTime.now();
      final surveyData = {
        'kindergarten_id': _currentKindergartenId,
        'title': title,
        'description': description,
        'created_by_user_id': _currentUserId,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'status': SurveyStatus.published.name,
        'target_audience': targetAudience.name,
        'target_class_ids': selectedClassIds ?? [],
        'target_student_ids': selectedStudentIds ?? [],
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      // Create survey document first
      final surveyDocRef = await _firestore.collection('surveys').add(surveyData);
      
      // Save questions as separate documents
      await _saveSurveyQuestions(surveyDocRef.id, questions);
      
      return true;
    } catch (error) {
      throw Exception('Failed to publish survey: $error');
    }
  }

  /// Updates an existing survey
  Future<bool> updateSurvey({
    required String surveyId,
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    TargetAudience? targetAudience,
    List<int>? selectedClassIds,
    List<int>? selectedStudentIds,
    String? selectedYearGroup,
    List<SurveyQuestion>? questions,
  }) async {
    try {
      // Find the survey document
      final doc = await _findSurveyDocument(surveyId);

      if (doc != null) {
        final updateData = {
          'title': title,
          'description': description,
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
          'target_audience': targetAudience?.name,
          'target_class_ids': selectedClassIds ?? [],
          'target_student_ids': selectedStudentIds ?? [],
          'updated_at': DateTime.now().toIso8601String(),
        };

        await doc.reference.update(updateData);
        
        // Update questions if provided
        if (questions != null) {
          // Delete existing questions and options
          await _deleteSurveyQuestions(doc.id);
          
          // Save new questions
          await _saveSurveyQuestions(doc.id, questions);
        }
        
        return true;
      }

      // If document not found, create new one
      return await publishSurvey(
        title: title,
        description: description,
        startDate: startDate,
        endDate: endDate,
        targetAudience: targetAudience ?? TargetAudience.allStudents,
        selectedClassIds: selectedClassIds,
        selectedStudentIds: selectedStudentIds,
        selectedYearGroup: selectedYearGroup,
        questions: questions ?? [],
      );
    } catch (error) {
      throw Exception('Failed to update survey: $error');
    }
  }

  /// Updates the status of a survey
  Future<bool> updateSurveyStatus(String surveyId, SurveyStatus status) async {
    try {
      final doc = await _findSurveyDocument(surveyId);
      
      if (doc != null) {
        await doc.reference.update({
          'status': status.name,
          'updated_at': DateTime.now().toIso8601String(),
        });
        return true;
      }
      
      return false;
    } catch (error) {
      throw Exception('Failed to update survey status: $error');
    }
  }

  /// Duplicates an existing survey
  Future<String?> duplicateSurvey(String surveyId) async {
    try {
      final originalSurvey = await fetchSurveyById(surveyId);
      if (originalSurvey == null) {
        throw Exception('Survey not found');
      }

      final now = DateTime.now();
      final duplicatedSurveyData = {
        'kindergarten_id': _currentKindergartenId,
        'title': '${originalSurvey.title} (Copy)',
        'description': originalSurvey.description,
        'created_by_user_id': _currentUserId,
        'start_date': originalSurvey.startDate?.toIso8601String(),
        'end_date': originalSurvey.endDate?.toIso8601String(),
        'status': SurveyStatus.draft.name,
        'target_audience': originalSurvey.targetAudience.name,
        'target_class_ids': originalSurvey.targetClassIds,
        'target_student_ids': originalSurvey.targetStudentIds,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      // Create survey document first
      final docRef = await _firestore.collection('surveys').add(duplicatedSurveyData);
      
      // Duplicate questions as separate documents
      if (originalSurvey.questions.isNotEmpty) {
        await _saveSurveyQuestions(docRef.id, originalSurvey.questions);
      }
      
      return docRef.id;
    } catch (error) {
      throw Exception('Failed to duplicate survey: $error');
    }
  }

  /// Fetches surveys by status
  Future<List<SurveyModel>> fetchSurveysByStatus(SurveyStatus status) async {
    try {
      // Try with ordering first - requires composite index
      var querySnapshot = await _firestore
          .collection('surveys')
          .where('kindergarten_id', isEqualTo: _currentKindergartenId)
          .where('status', isEqualTo: status.name)
          .orderBy('created_at', descending: true)
          .get();

      return await _buildSurveyModelsFromDocs(querySnapshot.docs);
    } catch (error) {
      // If composite index doesn't exist, fall back to simple query
      try {
        print('Firestore composite index not found for status query, using simple query...');
        var querySnapshot = await _firestore
            .collection('surveys')
            .where('kindergarten_id', isEqualTo: _currentKindergartenId)
            .where('status', isEqualTo: status.name)
            .get();

        var surveys = await _buildSurveyModelsFromDocs(querySnapshot.docs);
        // Sort in memory by created_at
        surveys.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return surveys;
      } catch (fallbackError) {
        throw Exception('Failed to fetch surveys by status: $fallbackError');
      }
    }
  }

  /// Fetches active surveys (published and not yet ended)
  Future<List<SurveyModel>> fetchActiveSurveys() async {
    try {
      final now = DateTime.now();
      // Try with ordering first - requires composite index
      var querySnapshot = await _firestore
          .collection('surveys')
          .where('kindergarten_id', isEqualTo: _currentKindergartenId)
          .where('status', isEqualTo: SurveyStatus.published.name)
          .where('end_date', isGreaterThanOrEqualTo: now.toIso8601String())
          .orderBy('end_date')
          .get();

      return await _buildSurveyModelsFromDocs(querySnapshot.docs);
    } catch (error) {
      // If composite index doesn't exist, fall back to simple query
      try {
        print('Firestore composite index not found for active surveys, using simple query...');
        var querySnapshot = await _firestore
            .collection('surveys')
            .where('kindergarten_id', isEqualTo: _currentKindergartenId)
            .where('status', isEqualTo: SurveyStatus.published.name)
            .get();

        var surveys = await _buildSurveyModelsFromDocs(querySnapshot.docs);

        // Filter and sort in memory
        final now = DateTime.now();
        surveys = surveys.where((survey) {
          return survey.endDate != null && survey.endDate!.isAfter(now);
        }).toList();
        
        surveys.sort((a, b) => (a.endDate ?? DateTime.now()).compareTo(b.endDate ?? DateTime.now()));
        return surveys;
      } catch (fallbackError) {
        // Return empty list if query fails
        return [];
      }
    }
  }

  /// Submits a survey response from a parent/user
  Future<bool> submitSurveyResponse({
    required String surveyId,
    required String userId,
    required Map<String, dynamic> answers, // questionId -> answer value/selected options
  }) async {
    try {
      // Find the survey document
      final surveyDoc = await _findSurveyDocument(surveyId);
      if (surveyDoc == null) {
        throw Exception('Survey not found');
      }

      final now = DateTime.now();
      
      // Create survey response document
      final responseData = {
        'survey_id': surveyDoc.id,
        'user_id': userId,
        'submitted_at': now.toIso8601String(),
        'created_at': now.toIso8601String(),
      };

      final responseDocRef = await _firestore.collection('survey_responses').add(responseData);

      // Create survey answers
      final batch = _firestore.batch();
      
      for (final entry in answers.entries) {
        final questionId = entry.key;
        final answerValue = entry.value;
        
        final answerData = <String, dynamic>{
          'survey_response_id': responseDocRef.id,
          'survey_question_id': questionId,
          'created_at': now.toIso8601String(),
        };
        
        // Handle different answer types
        if (answerValue is List) {
          // Multiple choice multiple selection - store as JSON array
          answerData['selected_options'] = answerValue.cast<String>();
          answerData['answer_value'] = null;
        } else {
          // Single choice or text answer
          answerData['answer_value'] = answerValue.toString();
          answerData['selected_options'] = null;
        }

        final answerDocRef = _firestore.collection('survey_answers').doc();
        batch.set(answerDocRef, answerData);
      }

      await batch.commit();
      return true;
    } catch (error) {
      throw Exception('Failed to submit survey response: $error');
    }
  }

  /// Fetches survey responses for a specific survey
  Future<List<SurveyResponse>> fetchSurveyResponses(String surveyId) async {
    try {
      final surveyDoc = await _findSurveyDocument(surveyId);
      if (surveyDoc == null) {
        return [];
      }

      final responsesSnapshot = await _firestore
          .collection('survey_responses')
          .where('survey_id', isEqualTo: surveyDoc.id)
          .orderBy('submitted_at', descending: true)
          .get();

      final List<SurveyResponse> responses = [];

      for (final responseDoc in responsesSnapshot.docs) {
        final responseData = responseDoc.data();
        
        // Load answers for this response
        final answersSnapshot = await _firestore
            .collection('survey_answers')
            .where('survey_response_id', isEqualTo: responseDoc.id)
            .get();

        final answers = answersSnapshot.docs.map((answerDoc) {
          final answerData = answerDoc.data();
          return SurveyAnswer(
            id: answerDoc.id,
            surveyResponseId: responseDoc.id,
            surveyQuestionId: answerData['survey_question_id'] as String,
            answerValue: answerData['answer_value'] as String?,
            selectedOptions: answerData['selected_options'] != null
                ? List<String>.from(answerData['selected_options'])
                : null,
          );
        }).toList();

        responses.add(SurveyResponse(
          id: responseDoc.id,
          surveyId: surveyDoc.id,
          userId: responseData['user_id'] as String,
          submittedAt: DateTime.parse(responseData['submitted_at'] as String),
          answers: answers,
        ));
      }

      return responses;
    } catch (error) {
      print('Error fetching survey responses: $error');
      return [];
    }
  }

  /// Checks if a user has already responded to a survey
  Future<bool> hasUserRespondedToSurvey(String surveyId, String userId) async {
    try {
      final surveyDoc = await _findSurveyDocument(surveyId);
      if (surveyDoc == null) {
        return false;
      }

      final responseSnapshot = await _firestore
          .collection('survey_responses')
          .where('survey_id', isEqualTo: surveyDoc.id)
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      return responseSnapshot.docs.isNotEmpty;
    } catch (error) {
      print('Error checking user response: $error');
      return false;
    }
  }

  /// Gets survey statistics/summary
  Future<SurveySummary> getSurveySummary(String surveyId) async {
    try {
      final surveyDoc = await _findSurveyDocument(surveyId);
      if (surveyDoc == null) {
        throw Exception('Survey not found');
      }

      // Count total responses
      final responsesSnapshot = await _firestore
          .collection('survey_responses')
          .where('survey_id', isEqualTo: surveyDoc.id)
          .get();

      final totalResponses = responsesSnapshot.docs.length;

      // Load questions to get question count
      final questions = await _loadSurveyQuestions(surveyDoc.id);

      return SurveySummary(
        surveyId: surveyId,
        totalQuestions: questions.length,
        totalResponses: totalResponses,
        lastResponseAt: responsesSnapshot.docs.isNotEmpty
            ? responsesSnapshot.docs
                .map((doc) => DateTime.parse(doc.data()['submitted_at']))
                .reduce((a, b) => a.isAfter(b) ? a : b)
            : null,
      );
    } catch (error) {
      throw Exception('Failed to get survey summary: $error');
    }
  }
}
