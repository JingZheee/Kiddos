import 'package:flutter/foundation.dart';
import '../../models/survey/survey_model.dart';
import '../services/survey_service.dart';

enum SurveyLoadingState {
  initial,
  loading,
  loaded,
  error,
}

class SurveyProvider extends ChangeNotifier {
  final SurveyService _surveyService = SurveyService();
  
  // Teacher survey management
  List<SurveyModel> _surveys = [];
  SurveyLoadingState _loadingState = SurveyLoadingState.initial;
  String? _errorMessage;
  
  // Parent survey functionality
  List<SurveyModel> _pendingSurveys = [];
  List<SurveyModel> _completedSurveys = [];
  SurveyLoadingState _parentLoadingState = SurveyLoadingState.initial;
  String? _parentErrorMessage;
  bool _isSubmitting = false;
  // Teacher survey getters
  List<SurveyModel> get surveys => _surveys;
  SurveyLoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _loadingState == SurveyLoadingState.loading;
  bool get hasError => _loadingState == SurveyLoadingState.error;
  bool get isEmpty => _surveys.isEmpty && _loadingState == SurveyLoadingState.loaded;

  // Parent survey getters
  List<SurveyModel> get pendingSurveys => _pendingSurveys;
  List<SurveyModel> get completedSurveys => _completedSurveys;
  SurveyLoadingState get parentLoadingState => _parentLoadingState;
  String? get parentErrorMessage => _parentErrorMessage;
  bool get isParentLoading => _parentLoadingState == SurveyLoadingState.loading;
  bool get hasParentError => _parentLoadingState == SurveyLoadingState.error;
  bool get isParentEmpty => _pendingSurveys.isEmpty && _completedSurveys.isEmpty && _parentLoadingState == SurveyLoadingState.loaded;
  bool get isSubmitting => _isSubmitting;
  int get pendingSurveyCount => _pendingSurveys.length;

  /// Fetch surveys from Firebase
  Future<void> fetchSurveys() async {
    _setLoadingState(SurveyLoadingState.loading);
    
    try {
      _surveys = await _surveyService.fetchSurveys();
      _setLoadingState(SurveyLoadingState.loaded);
      _errorMessage = null;
    } catch (e) {
      _setLoadingState(SurveyLoadingState.error);
      _errorMessage = e.toString();
      if (kDebugMode) {
        print('Error fetching surveys: $e');
      }
    }
  }

  /// Refresh surveys (force refetch)
  Future<void> refreshSurveys() async {
    await fetchSurveys();
  }

  /// Delete a survey
  Future<bool> deleteSurvey(String surveyId) async {
    try {
      final success = await _surveyService.deleteSurvey(surveyId);
      if (success) {
        _surveys.removeWhere((survey) => survey.id == surveyId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }  /// Create a new survey (save as draft)
  Future<bool> createSurvey(SurveyModel survey) async {
    try {
      final success = await _surveyService.saveSurveyDraft(
        title: survey.title,
        description: survey.description,
        startDate: survey.startDate,
        endDate: survey.endDate,
        targetAudience: survey.targetAudience,
        selectedClassIds: survey.targetClassIds,
        selectedStudentIds: survey.targetStudentIds,
        questions: survey.questions,
      );
      if (success) {
        // Refresh the list to get the new survey
        await fetchSurveys();
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update an existing survey
  Future<bool> updateSurvey(SurveyModel survey) async {
    try {
      final success = await _surveyService.updateSurvey(
        surveyId: survey.id,
        title: survey.title,
        description: survey.description,
        startDate: survey.startDate,
        endDate: survey.endDate,
        targetAudience: survey.targetAudience,
        selectedClassIds: survey.targetClassIds,
        selectedStudentIds: survey.targetStudentIds,
        questions: survey.questions,
      );
      if (success) {
        // Update the survey in the local list
        final index = _surveys.indexWhere((s) => s.id == survey.id);
        if (index != -1) {
          _surveys[index] = survey;
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  /// Get a survey by ID (from local cache first, then fetch if needed)
  /// Legacy method for backward compatibility - converts int to string
  SurveyModel? getSurveyById(dynamic surveyId) {
    final String id = surveyId.toString();
    return getSurveyByIdUnified(id);
  }

  /// Fetch a specific survey by ID from Firebase
  Future<SurveyModel?> fetchSurveyById(String surveyId) async {
    try {
      return await _surveyService.fetchSurveyById(surveyId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset provider state
  void reset() {
    _surveys = [];
    _loadingState = SurveyLoadingState.initial;
    _errorMessage = null;
    notifyListeners();
  }

  // ============================================================================
  // PARENT SURVEY METHODS
  // ============================================================================

  /// Fetch surveys available for parents
  Future<void> fetchParentSurveys(String userId) async {
    _setParentLoadingState(SurveyLoadingState.loading);
    
    try {
      // Get all active surveys
      final allActiveSurveys = await _surveyService.fetchActiveSurveys();
      
      // Separate pending and completed surveys
      final List<SurveyModel> pending = [];
      final List<SurveyModel> completed = [];
      
      for (final survey in allActiveSurveys) {
        final hasResponded = await _surveyService.hasUserRespondedToSurvey(survey.id, userId);
        if (hasResponded) {
          completed.add(survey);
        } else {
          pending.add(survey);
        }
      }
      
      _pendingSurveys = pending;
      _completedSurveys = completed;
      _setParentLoadingState(SurveyLoadingState.loaded);
      _parentErrorMessage = null;
    } catch (e) {
      _setParentLoadingState(SurveyLoadingState.error);
      _parentErrorMessage = e.toString();
      if (kDebugMode) {
        print('Error fetching parent surveys: $e');
      }
    }
  }

  /// Submit survey response
  Future<bool> submitSurveyResponse({
    required String surveyId,
    required String userId,
    required Map<String, dynamic> answers,
  }) async {
    _isSubmitting = true;
    notifyListeners();
    
    try {
      final success = await _surveyService.submitSurveyResponse(
        surveyId: surveyId,
        userId: userId,
        answers: answers,
      );
      
      if (success) {
        // Move survey from pending to completed
        final surveyIndex = _pendingSurveys.indexWhere((s) => s.id == surveyId);
        if (surveyIndex != -1) {
          final survey = _pendingSurveys.removeAt(surveyIndex);
          _completedSurveys.add(survey);
        }
      }
      
      return success;
    } catch (e) {
      _parentErrorMessage = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Get survey by ID (checks both teacher surveys and parent surveys)
  SurveyModel? getSurveyByIdUnified(String surveyId) {
    // First check teacher surveys
    try {
      return _surveys.firstWhere((survey) => survey.id == surveyId);
    } catch (e) {
      // If not found, check parent surveys
      try {
        // Check pending surveys first
        try {
          return _pendingSurveys.firstWhere((survey) => survey.id == surveyId);
        } catch (e) {
          // If not found in pending, check completed
          return _completedSurveys.firstWhere((survey) => survey.id == surveyId);
        }
      } catch (e) {
        return null;
      }
    }
  }

  /// Refresh parent surveys (force refetch)
  Future<void> refreshParentSurveys(String userId) async {
    await fetchParentSurveys(userId);
  }

  /// Clear parent error message
  void clearParentError() {
    _parentErrorMessage = null;
    notifyListeners();
  }

  /// Reset parent survey state
  void resetParent() {
    _pendingSurveys = [];
    _completedSurveys = [];
    _parentLoadingState = SurveyLoadingState.initial;
    _parentErrorMessage = null;
    _isSubmitting = false;
    notifyListeners();
  }

  void _setParentLoadingState(SurveyLoadingState state) {
    _parentLoadingState = state;
    notifyListeners();
  }

  void _setLoadingState(SurveyLoadingState state) {
    _loadingState = state;
    notifyListeners();
  }
}
