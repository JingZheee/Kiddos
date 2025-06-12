import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/survey_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../models/survey/survey_model.dart';

class ParentSurveyFormScreen extends StatefulWidget {
  final String surveyId;

  const ParentSurveyFormScreen({
    super.key,
    required this.surveyId,
  });

  @override
  State<ParentSurveyFormScreen> createState() => _ParentSurveyFormScreenState();
}

class _ParentSurveyFormScreenState extends State<ParentSurveyFormScreen> {
  final Map<String, dynamic> _answers = {};
  final Set<String> _requiredQuestions = {};
  bool _isSubmitting = false;
  SurveyModel? _survey;

  @override
  void initState() {
    super.initState();
    _loadSurvey();
  }
  void _loadSurvey() {
    final provider = context.read<SurveyProvider>();
    _survey = provider.getSurveyByIdUnified(widget.surveyId);
    
    if (_survey != null) {
      // Initialize required questions set
      _requiredQuestions.clear();
      for (final question in _survey!.questions) {
        if (question.isRequired) {
          _requiredQuestions.add(question.id);
        }
      }
    }
  }

  bool _isFormValid() {
    // Check if all required questions are answered
    for (final questionId in _requiredQuestions) {
      if (!_answers.containsKey(questionId) || 
          _answers[questionId] == null ||
          (_answers[questionId] is String && (_answers[questionId] as String).trim().isEmpty) ||
          (_answers[questionId] is List && (_answers[questionId] as List).isEmpty)) {
        return false;
      }
    }
    return true;
  }

  int _getUnansweredRequiredCount() {
    int count = 0;
    for (final questionId in _requiredQuestions) {
      if (!_answers.containsKey(questionId) || 
          _answers[questionId] == null ||
          (_answers[questionId] is String && (_answers[questionId] as String).trim().isEmpty) ||
          (_answers[questionId] is List && (_answers[questionId] as List).isEmpty)) {
        count++;
      }
    }
    return count;
  }

  Future<void> _submitSurvey() async {
    if (!_isFormValid()) {
      final unansweredCount = _getUnansweredRequiredCount();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You missed $unansweredCount required question${unansweredCount > 1 ? 's' : ''}'),
          backgroundColor: AppTheme.accentColor2,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {      final userProvider = context.read<UserProvider>();
      final success = await context.read<SurveyProvider>().submitSurveyResponse(
        surveyId: widget.surveyId,
        userId: userProvider.userModel!.id,
        answers: _answers,
      );

      if (success && mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: Icon(
              Icons.check_circle,
              color: AppTheme.accentColor1,
              size: 48,
            ),
            title: const Text('Thank You!'),
            content: const Text('Your response has been recorded successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  context.pop(); // Return to surveys list
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit survey. Please try again.'),
            backgroundColor: AppTheme.accentColor2,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.accentColor2,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Survey?'),
        content: const Text('Your progress will be lost if you exit now. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.pop(); // Exit survey
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.accentColor2),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_survey == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Survey'),
        body: const Center(
          child: Text('Survey not found'),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        _showExitDialog();
        return false;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: _survey!.title,
          actions: [
            TextButton(
              onPressed: _showExitDialog,
              child: const Text('Exit'),
            ),
          ],
        ),
        body: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),
            
            // Survey content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(UIConstants.spacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSurveyHeader(),
                    const SizedBox(height: UIConstants.spacing24),
                    _buildQuestions(),
                    const SizedBox(height: UIConstants.spacing24),
                  ],
                ),
              ),
            ),
            
            // Submit button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final answeredCount = _answers.length;
    final totalCount = _survey!.questions.length;
    final progress = totalCount > 0 ? answeredCount / totalCount : 0.0;

    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              Text(
                '$answeredCount of $totalCount questions',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: UIConstants.spacing8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _survey!.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        if (_survey!.description != null && _survey!.description!.isNotEmpty) ...[
          const SizedBox(height: UIConstants.spacing8),
          Text(
            _survey!.description!,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
        const SizedBox(height: UIConstants.spacing16),
        Container(
          padding: const EdgeInsets.all(UIConstants.spacing12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: UIConstants.spacing8),
              Expanded(
                child: Text(
                  'Questions marked with * are required',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestions() {
    return Column(
      children: _survey!.questions.asMap().entries.map((entry) {
        final index = entry.key;
        final question = entry.value;
        return Container(
          margin: EdgeInsets.only(
            bottom: index < _survey!.questions.length - 1 ? UIConstants.spacing24 : 0,
          ),
          child: _buildQuestionCard(question, index + 1),
        );
      }).toList(),
    );
  }

  Widget _buildQuestionCard(SurveyQuestion question, int questionNumber) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      questionNumber.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: UIConstants.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              question.questionText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                          if (question.isRequired)
                            Text(
                              ' *',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.accentColor2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: UIConstants.spacing16),
                      _buildQuestionInput(question),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionInput(SurveyQuestion question) {
    switch (question.questionType) {
      case QuestionType.multipleChoiceSingle:
        return _buildSingleChoiceInput(question);
      case QuestionType.multipleChoiceMultiple:
        return _buildMultipleChoiceInput(question);
      case QuestionType.openText:
        return _buildTextInput(question);
    }
  }

  Widget _buildSingleChoiceInput(SurveyQuestion question) {
    return Column(
      children: question.options.map((option) {
        final isSelected = _answers[question.id] == option.id;
        return Container(
          margin: const EdgeInsets.only(bottom: UIConstants.spacing8),
          child: InkWell(
            onTap: () {
              setState(() {
                _answers[question.id] = option.id;
              });
            },
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
            child: Container(
              padding: const EdgeInsets.all(UIConstants.spacing12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade500,
                  ),
                  const SizedBox(width: UIConstants.spacing12),
                  Expanded(
                    child: Text(
                      option.optionText,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultipleChoiceInput(SurveyQuestion question) {
    final selectedOptions = (_answers[question.id] as List<String>?) ?? [];
    
    return Column(
      children: question.options.map((option) {
        final isSelected = selectedOptions.contains(option.id);
        return Container(
          margin: const EdgeInsets.only(bottom: UIConstants.spacing8),
          child: InkWell(
            onTap: () {
              setState(() {
                final currentSelections = List<String>.from(selectedOptions);
                if (isSelected) {
                  currentSelections.remove(option.id);
                } else {
                  currentSelections.add(option.id);
                }
                _answers[question.id] = currentSelections;
              });
            },
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
            child: Container(
              padding: const EdgeInsets.all(UIConstants.spacing12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade500,
                  ),
                  const SizedBox(width: UIConstants.spacing12),
                  Expanded(
                    child: Text(
                      option.optionText,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextInput(SurveyQuestion question) {
    return TextFormField(
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Type your answer here...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
      onChanged: (value) {
        setState(() {
          _answers[question.id] = value;
        });
      },
    );
  }

  Widget _buildSubmitButton() {
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
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitSurvey,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentColor1,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: UIConstants.spacing16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Submit Survey',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
