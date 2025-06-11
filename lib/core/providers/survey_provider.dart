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
  
  List<SurveyModel> _surveys = [];
  SurveyLoadingState _loadingState = SurveyLoadingState.initial;
  String? _errorMessage;

  // Getters
  List<SurveyModel> get surveys => _surveys;
  SurveyLoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _loadingState == SurveyLoadingState.loading;
  bool get hasError => _loadingState == SurveyLoadingState.error;
  bool get isEmpty => _surveys.isEmpty && _loadingState == SurveyLoadingState.loaded;

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
  SurveyModel? getSurveyById(int surveyId) {
    try {
      return _surveys.firstWhere((survey) => survey.id == surveyId);
    } catch (e) {
      return null;
    }
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

  void _setLoadingState(SurveyLoadingState state) {
    _loadingState = state;
    notifyListeners();
  }
}
