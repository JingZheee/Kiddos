import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/survey_service.dart';
import '../../../models/survey/survey_model.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/question_builder_widget.dart';
import '../../../widgets/target_audience_selector_widget.dart';
import '../../../widgets/date_range_picker_widget.dart';

class CreateSurveyScreen extends StatefulWidget {
  final String? surveyId;

  const CreateSurveyScreen({
    super.key,
    this.surveyId,
  });

  @override
  State<CreateSurveyScreen> createState() => _CreateSurveyScreenState();
}

class _CreateSurveyScreenState extends State<CreateSurveyScreen> {
  final PageController _pageController = PageController();
  final SurveyService _surveyService = SurveyService();
    int _currentStep = 0;
  final int _totalSteps = 4;
  bool _isLoading = false;

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Survey data
  TargetAudience _selectedAudience = TargetAudience.allStudents;
  List<int> _selectedClassIds = [];
  List<int> _selectedStudentIds = [];
  String? _selectedYearGroup;
  DateTime? _startDate;
  DateTime? _endDate;
  List<SurveyQuestion> _questions = [];

  @override
  void initState() {
    super.initState();
    if (widget.surveyId != null) {
      _loadExistingSurvey();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  Future<void> _loadExistingSurvey() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final survey = await _surveyService.fetchSurveyById(widget.surveyId!);
      if (survey != null) {
        _titleController.text = survey.title;
        _descriptionController.text = survey.description ?? '';
        _selectedAudience = survey.targetAudience;
        _selectedClassIds = List.from(survey.targetClassIds);
        _selectedStudentIds = List.from(survey.targetStudentIds);
        _startDate = survey.startDate;
        _endDate = survey.endDate;
        _questions = List.from(survey.questions);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load survey: $e'),
            backgroundColor: AppTheme.accentColor2,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  bool get _canSaveDraft {
    return _titleController.text.trim().isNotEmpty || 
           _descriptionController.text.trim().isNotEmpty ||
           _questions.isNotEmpty;
  }
  bool get _canPublish {
    return _titleController.text.trim().isNotEmpty &&
           _questions.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.surveyId != null;
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: CustomAppBar(
        title: isEditing ? 'Edit Survey' : 'Create Survey',
        actions: [
          if (_canSaveDraft)
            TextButton(
              onPressed: _saveDraft,
              child: const Text('Save Draft'),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildBasicInfoStep(),
                _buildTargetAudienceStep(),
                _buildQuestionsStep(),
                _buildReviewStep(),
              ],
            ),
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: index < _totalSteps - 1 ? UIConstants.spacing8 : 0,
              ),
              child: Column(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isActive
                          ? AppTheme.primaryColor
                          : AppTheme.textLightColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: UIConstants.spacing8),
                  Text(
                    _getStepTitle(index),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  String _getStepTitle(int index) {
    switch (index) {
      case 0:
        return 'Basic Info';
      case 1:
        return 'Audience';
      case 2:
        return 'Questions';
      case 3:
        return 'Review';
      default:
        return '';
    }
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Survey Information',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: UIConstants.spacing8),
          const Text(
            'Provide basic information about your survey',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: UIConstants.spacing24),
          CustomTextField(
            label: 'Survey Title',
            hint: 'Enter a descriptive title for your survey',
            controller: _titleController,
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: UIConstants.spacing16),
          CustomTextField(
            label: 'Description (Optional)',
            hint: 'Provide additional context or instructions',
            controller: _descriptionController,
            onChanged: (value) => setState(() {}),
            maxLines: 3,
          ),
          const SizedBox(height: UIConstants.spacing24),
          DateRangePickerWidget(
            startDate: _startDate,
            endDate: _endDate,
            onStartDateChanged: (date) => setState(() => _startDate = date),
            onEndDateChanged: (date) => setState(() => _endDate = date),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetAudienceStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Target Audience',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: UIConstants.spacing8),
          const Text(
            'Select who should receive this survey',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: UIConstants.spacing24),
          TargetAudienceSelectorWidget(
            selectedAudience: _selectedAudience,
            selectedClassIds: _selectedClassIds,
            selectedStudentIds: _selectedStudentIds,
            selectedYearGroup: _selectedYearGroup ?? '',
            onAudienceChanged: (audience) => setState(() => _selectedAudience = audience),
            onClassSelectionChanged: (classIds) => setState(() => _selectedClassIds = classIds),
            onStudentSelectionChanged: (studentIds) => setState(() => _selectedStudentIds = studentIds),
            onYearGroupChanged: (yearGroup) => setState(() => _selectedYearGroup = yearGroup),
          ),
        ],
      ),
    );
  }
  Widget _buildQuestionsStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(UIConstants.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Survey Questions',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: UIConstants.spacing8),
                const Text(
                  'Build your survey questions',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacing16),
            child: QuestionBuilderWidget(
              questions: _questions,
              onQuestionsChanged: (questions) => setState(() => _questions = questions),
            ),
          ),
          const SizedBox(height: UIConstants.spacing16),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review & Publish',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: UIConstants.spacing8),
          const Text(
            'Review your survey before publishing',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: UIConstants.spacing24),
          _buildReviewSection('Basic Information', [
            _buildReviewItem('Title', _titleController.text),
            if (_descriptionController.text.isNotEmpty)
              _buildReviewItem('Description', _descriptionController.text),
            _buildReviewItem(
              'Duration',
              _formatDateRange(_startDate, _endDate),
            ),
          ]),
          const SizedBox(height: UIConstants.spacing16),
          _buildReviewSection('Target Audience', [
            _buildReviewItem(
              'Audience',
              _selectedAudience.displayName,
            ),
            if (_selectedClassIds.isNotEmpty)
              _buildReviewItem(
                'Selected Classes',
                '${_selectedClassIds.length} classes',
              ),
            if (_selectedStudentIds.isNotEmpty)
              _buildReviewItem(
                'Selected Students',
                '${_selectedStudentIds.length} students',
              ),
          ]),
          const SizedBox(height: UIConstants.spacing16),
          _buildReviewSection('Questions', [
            _buildReviewItem(
              'Total Questions',
              '${_questions.length} questions',
            ),
            ..._questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              return _buildReviewItem(
                'Question ${index + 1}',
                question.questionText,
                subtitle: question.questionType.displayName,
              );
            }),
          ]),
        ],
      ),
    );
  }

  Widget _buildReviewSection(String title, List<Widget> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: UIConstants.spacing12),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(String label, String value, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: UIConstants.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Previous'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: UIConstants.spacing12),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep == _totalSteps - 1
                    ? AppTheme.accentColor1
                    : AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_getNextButtonText()),
            ),
          ),
        ],
      ),
    );
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Next: Audience';
      case 1:
        return 'Next: Questions';
      case 2:
        return 'Next: Review';
      case 3:
        return 'Publish Survey';
      default:
        return 'Next';
    }
  }

  void _handleNextStep() {
    if (_currentStep < _totalSteps - 1) {
      if (_canProceedToNextStep()) {
        _nextStep();
      }
    } else {
      _publishSurvey();
    }
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        return _titleController.text.trim().isNotEmpty;
      case 1:
        return true; // Target audience selection is always valid
      case 2:
        return _questions.isNotEmpty;
      case 3:
        return _canPublish;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  Future<void> _saveDraft() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.surveyId != null) {
        await _surveyService.updateSurvey(
          surveyId: widget.surveyId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          targetAudience: _selectedAudience,
          selectedClassIds: _selectedClassIds,
          selectedStudentIds: _selectedStudentIds,
          selectedYearGroup: _selectedYearGroup,
          questions: _questions,
        );
      } else {
        await _surveyService.saveSurveyDraft(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          targetAudience: _selectedAudience,
          selectedClassIds: _selectedClassIds,
          selectedStudentIds: _selectedStudentIds,
          selectedYearGroup: _selectedYearGroup,
          questions: _questions,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Survey saved as draft'),
            backgroundColor: AppTheme.accentColor1,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save survey: $e'),
            backgroundColor: AppTheme.accentColor2,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }  Future<void> _publishSurvey() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.surveyId != null) {
        await _surveyService.updateSurvey(
          surveyId: widget.surveyId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          targetAudience: _selectedAudience,
          selectedClassIds: _selectedClassIds,
          selectedStudentIds: _selectedStudentIds,
          selectedYearGroup: _selectedYearGroup,
          questions: _questions,
        );
      } else {
        await _surveyService.publishSurvey(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          targetAudience: _selectedAudience,
          selectedClassIds: _selectedClassIds,
          selectedStudentIds: _selectedStudentIds,
          selectedYearGroup: _selectedYearGroup,
          questions: _questions,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Survey published successfully!'),
            backgroundColor: AppTheme.accentColor1,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish survey: $e'),
            backgroundColor: AppTheme.accentColor2,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDateRange(DateTime? startDate, DateTime? endDate) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    if (startDate == null && endDate == null) {
      return 'No dates set';
    }
    
    if (startDate != null && endDate != null) {
      return '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';
    }
    
    if (startDate != null) {
      return 'Starts ${dateFormat.format(startDate)}';
    }
    
    if (endDate != null) {
      return 'Ends ${dateFormat.format(endDate)}';
    }
    
    return 'No dates set';
  }
}
