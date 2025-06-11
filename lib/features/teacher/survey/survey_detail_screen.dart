import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/survey_service.dart';
import '../../../models/survey/survey_model.dart';
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
  bool _isLoading = true;
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
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load survey: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
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
                const SizedBox(width: UIConstants.spacing12),
                Expanded(
                  child: _buildOverviewCard(
                    icon: Icons.people_outline,
                    title: 'Responses',
                    value: '0', // TODO: Calculate actual responses
                    color: AppTheme.secondaryColor,
                  ),
                ),
                const SizedBox(width: UIConstants.spacing12),
                Expanded(
                  child: _buildOverviewCard(
                    icon: Icons.analytics_outlined,
                    title: 'Response Rate',
                    value: '0%', // TODO: Calculate actual response rate
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
  }

  Widget _buildResponsesSection(SurveyModel survey) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Survey Responses',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: UIConstants.spacing16),
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
                    'Responses will appear here once the survey is published',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
}
