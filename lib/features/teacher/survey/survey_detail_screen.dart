import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/survey_service.dart';
import '../../../models/survey/survey_model.dart';
import '../../../models/survey/survey_response_model.dart';
import '../../../widgets/custom_app_bar.dart';

class SurveyDetailScreen extends StatefulWidget {
  final String surveyId;

  const SurveyDetailScreen({
    super.key,
    required this.surveyId,
  });

  @override
  State<SurveyDetailScreen> createState() => _SurveyDetailScreenState();
}

class _SurveyDetailScreenState extends State<SurveyDetailScreen> {
  final SurveyService _surveyService = SurveyService();
  SurveyModel? _survey;
  List<SurveyResponse> _responses = [];
  SurveySummary? _surveySummary;
  bool _isLoading = true;
  bool _isLoadingResponses = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSurvey();
  }
  Future<void> _loadSurvey() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final survey = await _surveyService.fetchSurveyById(widget.surveyId);
      setState(() {
        _survey = survey;
      });
      
      // Load responses and summary if survey exists
      if (survey != null) {
        await _loadSurveyResponses();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load survey: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }  Future<void> _loadSurveyResponses() async {
    if (_survey == null) return;
    
    setState(() {
      _isLoadingResponses = true;
    });

    try {
      final responses = await _surveyService.fetchSurveyResponses(widget.surveyId);
      final summary = await _surveyService.getSurveySummary(widget.surveyId);
      
      setState(() {
        _responses = responses;
        _surveySummary = summary;
      });
    } catch (e) {
      // Don't set error for responses, just log it
      print('Failed to load survey responses: $e');
    } finally {
      setState(() {
        _isLoadingResponses = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Survey Details',
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined),
                    SizedBox(width: 8),
                    Text('Edit Survey'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy_outlined),
                    SizedBox(width: 8),
                    Text('Duplicate Survey'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download_outlined),
                    SizedBox(width: 8),
                    Text('Export Results'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Survey', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading survey',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSurvey,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_survey == null) {
      return const Center(
        child: Text('Survey not found'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSurveyHeader(_survey!),
          const SizedBox(height: UIConstants.spacing24),
          _buildSurveyOverview(_survey!),
          const SizedBox(height: UIConstants.spacing24),
          _buildQuestionsSection(_survey!),
          const SizedBox(height: UIConstants.spacing24),
          _buildResponsesSection(_survey!),
        ],
      ),
    );
  }

  Widget _buildSurveyHeader(SurveyModel survey) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    survey.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(survey.status),
              ],
            ),
            if (survey.description != null && survey.description!.isNotEmpty) ...[
              const SizedBox(height: UIConstants.spacing8),
              Text(
                survey.description!,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ],
            const SizedBox(height: UIConstants.spacing16),
            _buildSurveyMetadata(survey),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(SurveyStatus status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case SurveyStatus.draft:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        label = 'Draft';
        break;
      case SurveyStatus.published:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        label = 'Published';
        break;
      case SurveyStatus.closed:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        label = 'Closed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSurveyMetadata(SurveyModel survey) {
    return Row(
      children: [
        Expanded(
          child: _buildMetadataItem(
            icon: Icons.people_outline,
            label: 'Target Audience',
            value: _getTargetAudienceText(survey.targetAudience),
          ),
        ),
        Expanded(
          child: _buildMetadataItem(
            icon: Icons.calendar_today_outlined,
            label: 'Duration',
            value: '${_formatDate(survey.startDate)} - ${_formatDate(survey.endDate)}',
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSurveyOverview(SurveyModel survey) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Survey Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: UIConstants.spacing16),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewCard(
                    icon: Icons.quiz_outlined,
                    title: 'Questions',
                    value: survey.questions.length.toString(),
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: UIConstants.spacing12),                Expanded(
                  child: _buildOverviewCard(
                    icon: Icons.people_outline,
                    title: 'Responses',
                    value: _surveySummary?.totalResponses.toString() ?? '0',
                    color: AppTheme.secondaryColor,
                  ),
                ),
                const SizedBox(width: UIConstants.spacing12),
                Expanded(
                  child: _buildOverviewCard(
                    icon: Icons.analytics_outlined,
                    title: 'Response Rate',
                    value: _calculateResponseRate(),
                    color: AppTheme.accentColor1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: UIConstants.spacing8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsSection(SurveyModel survey) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Questions (${survey.questions.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: UIConstants.spacing16),
            if (survey.questions.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.quiz_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No questions added yet',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...survey.questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                return _buildQuestionCard(index + 1, question);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int questionNumber, SurveyQuestion question) {
    return Container(
      margin: const EdgeInsets.only(bottom: UIConstants.spacing12),
      padding: const EdgeInsets.all(UIConstants.spacing12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Q$questionNumber',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getQuestionTypeText(question.questionType),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
              if (question.isRequired)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Required',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.questionText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (question.options.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...question.options.map((option) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                children: [
                  Icon(
                    question.questionType == QuestionType.multipleChoiceSingle
                        ? Icons.radio_button_unchecked
                        : Icons.check_box_outline_blank,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    option.optionText,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }  Widget _buildResponsesSection(SurveyModel survey) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Survey Responses',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isLoadingResponses)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: UIConstants.spacing16),
            if (_isLoadingResponses)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(UIConstants.spacing32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_responses.isEmpty && (_surveySummary?.totalResponses ?? 0) == 0)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No responses yet',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Responses will appear here once parents submit the survey',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Response summary header
                  Container(
                    padding: const EdgeInsets.all(UIConstants.spacing12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.people, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          '${_surveySummary?.totalResponses ?? _responses.length} total responses',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (_surveySummary?.lastResponseAt != null)
                          Text(
                            'Last: ${_formatDate(_surveySummary!.lastResponseAt)}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: UIConstants.spacing16),
                  // Question-by-question analysis
                  ...survey.questions.map((question) => _buildQuestionAnalysis(question)).toList(),
                ],
              ),
          ],
        ),
      ),
    );  }
  Widget _buildQuestionAnalysis(SurveyQuestion question) {
    final totalResponses = _surveySummary?.totalResponses ?? _responses.length;
    if (totalResponses == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: UIConstants.spacing16),
      padding: const EdgeInsets.all(UIConstants.spacing16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Q${question.orderIndex + 1}',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question.questionText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: UIConstants.spacing12),
          // Question type indicator
          Row(
            children: [
              Icon(
                _getQuestionTypeIcon(question.questionType),
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                question.questionType.displayName,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: UIConstants.spacing16),
          // Response analysis based on question type
          if (question.questionType == QuestionType.multipleChoiceSingle || question.questionType == QuestionType.multipleChoiceMultiple)
            _buildChoiceAnalysis(question, totalResponses)
          else if (question.questionType == QuestionType.openText)
            _buildTextResponseAnalysis(question),
        ],
      ),
    );
  }  Widget _buildChoiceAnalysis(SurveyQuestion question, int totalResponses) {
    final questionAnswers = _getAnswersForQuestion(question.id);
    final choiceCounts = <String, int>{};
    
    // Create a map of option values to option text for lookup
    final optionValueToText = <String, String>{};
    for (final option in question.options) {
      optionValueToText[option.id] = option.optionText;
    }
    
    // Count responses for each choice
    for (final answer in questionAnswers) {
      if (question.questionType == QuestionType.multipleChoiceMultiple) {
        // Multiple choice - check selectedOptions
        if (answer.selectedOptions != null && answer.selectedOptions!.isNotEmpty) {
          for (final choiceValue in answer.selectedOptions!) {
            final optionText = optionValueToText[choiceValue];
            if (optionText != null) {
              choiceCounts[optionText] = (choiceCounts[optionText] ?? 0) + 1;
            }
          }
        }
      } else {
        // Single choice - check answerValue
        if (answer.answerValue != null && answer.answerValue!.isNotEmpty) {
          final optionText = optionValueToText[answer.answerValue!];
          if (optionText != null) {
            choiceCounts[optionText] = (choiceCounts[optionText] ?? 0) + 1;
          }
        }
      }
    }

    if (question.options.isEmpty) {
      return Text(
        'No options defined for this question',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontStyle: FontStyle.italic,
        ),
      );
    }    return Column(
      children: question.options.map((option) {
        final count = choiceCounts[option.optionText] ?? 0;
        final percentage = totalResponses > 0 ? (count / totalResponses * 100) : 0.0;
        
        return Container(
          margin: const EdgeInsets.only(bottom: UIConstants.spacing8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      option.optionText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '$count (${percentage.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: totalResponses > 0 ? count / totalResponses : 0.0,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }  Widget _buildTextResponseAnalysis(SurveyQuestion question) {
    final questionAnswers = _getAnswersForQuestion(question.id);
    
    final textResponses = questionAnswers
        .where((answer) => answer.answerValue != null && answer.answerValue!.isNotEmpty)
        .map((answer) => answer.answerValue!)
        .toList();

    if (textResponses.isEmpty) {
      return Text(
        'No text responses yet',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${textResponses.length} text response${textResponses.length != 1 ? 's' : ''}:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: UIConstants.spacing8),
        ...textResponses.map((response) => Container(
          margin: const EdgeInsets.only(bottom: UIConstants.spacing8),
          padding: const EdgeInsets.all(UIConstants.spacing12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.format_quote,
                size: 16,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  response,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }  List<SurveyAnswer> _getAnswersForQuestion(String questionId) {
    final answers = <SurveyAnswer>[];
    for (final response in _responses) {
      final questionAnswers = response.answers.where((answer) => answer.surveyQuestionId == questionId);
      answers.addAll(questionAnswers);
    }
    return answers;
  }

  IconData _getQuestionTypeIcon(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoiceSingle:
        return Icons.radio_button_checked;
      case QuestionType.multipleChoiceMultiple:
        return Icons.check_box;
      case QuestionType.openText:
        return Icons.text_fields;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _editSurvey();
        break;
      case 'duplicate':
        _duplicateSurvey();
        break;
      case 'export':
        _exportResults();
        break;
      case 'delete':
        _showDeleteDialog();
        break;
    }
  }

  void _editSurvey() {
    context.push('/teacher/surveys/create', extra: {'surveyId': widget.surveyId});
  }

  void _duplicateSurvey() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Duplicate survey feature coming soon'),
      ),
    );
  }

  void _exportResults() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export results feature coming soon'),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Survey'),
        content: const Text(
          'Are you sure you want to delete this survey? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSurvey();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSurvey() async {
    try {
      await _surveyService.deleteSurvey(widget.surveyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Survey deleted successfully'),
            backgroundColor: AppTheme.accentColor1,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete survey: $e'),
            backgroundColor: AppTheme.accentColor2,
          ),
        );
      }
    }
  }

  String _getTargetAudienceText(TargetAudience audience) {
    switch (audience) {
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
  String _getQuestionTypeText(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoiceSingle:
        return 'Multiple Choice (Single)';
      case QuestionType.multipleChoiceMultiple:
        return 'Multiple Choice (Multiple)';
      case QuestionType.openText:
        return 'Open Text';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return '${date.day}/${date.month}/${date.year}';
  }


  String _calculateResponseRate() {
    if (_surveySummary == null || _surveySummary!.totalResponses == 0) {
      return '0%';
    }
    
    // For now, just show the response count since we don't have target audience size
    // In a real app, you'd calculate based on the target audience
    final responses = _surveySummary!.totalResponses;
    if (responses == 0) return '0%';
    if (responses < 10) return '${(responses * 10)}%'; // Rough estimation
    return '100%'; // Cap at 100%
  }
}
