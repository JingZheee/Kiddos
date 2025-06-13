import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/survey_provider.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/app_loading.dart';
import '../../../models/survey/survey_model.dart';

class SurveysScreen extends StatefulWidget {
  const SurveysScreen({super.key});

  @override
  State<SurveysScreen> createState() => _SurveysScreenState();
}

class _SurveysScreenState extends State<SurveysScreen> {
  @override
  void initState() {
    super.initState();
    // Load surveys when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SurveyProvider>().fetchSurveys();
    });
  }
  Future<void> _deleteSurvey(String surveyId) async {
    final surveyProvider = context.read<SurveyProvider>();
    final success = await surveyProvider.deleteSurvey(surveyId);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Survey deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete survey: ${surveyProvider.errorMessage}'),
            backgroundColor: AppTheme.accentColor2,
          ),
        );
      }
    }
  }
  Future<void> _navigateToCreateSurvey() async {
    await context.push('/teacher/dashboard/surveys/create');
    // Refresh surveys list when returning from create survey screen
    if (mounted) {
      await context.read<SurveyProvider>().fetchSurveys();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Surveys',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCreateSurvey(),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateSurvey(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
  Widget _buildBody() {
    return Consumer<SurveyProvider>(
      builder: (context, surveyProvider, child) {
        if (surveyProvider.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  surveyProvider.errorMessage ?? 'Unknown error occurred',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => surveyProvider.fetchSurveys(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (surveyProvider.isLoading) {
          return const AppLoading(message: 'Loading surveys...');
        }

        if (surveyProvider.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => surveyProvider.refreshSurveys(),
          child: ListView.builder(
            padding: const EdgeInsets.all(UIConstants.spacing16),
            itemCount: surveyProvider.surveys.length,
            itemBuilder: (context, index) {
              final survey = surveyProvider.surveys[index];
              return SurveyCard(
                survey: survey,
                onTap: () => _navigateToSurveyDetail(survey),
                onEdit: () => _navigateToEditSurvey(survey),
                onDelete: () => _showDeleteDialog(survey),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.poll_outlined,
            size: 64,
            color: AppTheme.textLightColor,
          ),
          const SizedBox(height: UIConstants.spacing16),
          Text(
            'No Surveys Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: UIConstants.spacing8),
          Text(
            'Create your first survey to gather\nfeedback from parents',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textLightColor,
            ),
          ),
          const SizedBox(height: UIConstants.spacing24),          ElevatedButton.icon(
            onPressed: () => _navigateToCreateSurvey(),
            icon: const Icon(Icons.add),
            label: const Text('Create Survey'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: UIConstants.spacing24,
                vertical: UIConstants.spacing12,
              ),
            ),
          ),
        ],
      ),    );
  }

  Future<void> _navigateToSurveyDetail(SurveyModel survey) async {
    await context.push('/teacher/dashboard/surveys/detail/${survey.id}');
    // Refresh surveys list when returning from detail screen (in case survey was edited/deleted)
    if (mounted) {
      await context.read<SurveyProvider>().fetchSurveys();
    }
  }
  
  Future<void> _navigateToEditSurvey(SurveyModel survey) async {
    await context.push('/teacher/dashboard/surveys/edit/${survey.id}');
    // Refresh surveys list when returning from edit survey screen
    if (mounted) {
      await context.read<SurveyProvider>().fetchSurveys();
    }
  }

  void _showDeleteDialog(SurveyModel survey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Survey'),
        content: Text(
          'Are you sure you want to delete "${survey.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSurvey(survey.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.accentColor2,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class SurveyCard extends StatelessWidget {
  final SurveyModel survey;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SurveyCard({
    super.key,
    required this.survey,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: UIConstants.spacing12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                  _buildStatusChip(),
                  const SizedBox(width: UIConstants.spacing8),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: AppTheme.accentColor2),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: AppTheme.accentColor2)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (survey.description != null) ...[
                const SizedBox(height: UIConstants.spacing8),
                Text(
                  survey.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: UIConstants.spacing12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: UIConstants.spacing4),
                  Text(
                    _buildDateRange(),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.help_outline,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: UIConstants.spacing4),
                  Text(
                    '${survey.questions.length} questions',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    Color textColor;
    String text;    switch (survey.status) {
      case SurveyStatus.published:
        backgroundColor = AppTheme.accentColor1.withOpacity(0.1);
        textColor = AppTheme.accentColor1;
        text = 'Active';
        break;      case SurveyStatus.draft:
        backgroundColor = AppTheme.secondaryColor.withOpacity(0.1);
        textColor = AppTheme.secondaryColor;
        text = 'Draft';
        break;      case SurveyStatus.closed:
        backgroundColor = AppTheme.textLightColor.withOpacity(0.1);
        textColor = AppTheme.textSecondaryColor;
        text = 'Closed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacing8,
        vertical: UIConstants.spacing4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  String _buildDateRange() {
    final dateFormat = DateFormat('MMM dd');
    
    if (survey.startDate == null && survey.endDate == null) {
      return 'No dates set';
    }
    
    if (survey.startDate != null && survey.endDate != null) {
      return '${dateFormat.format(survey.startDate!)} - ${dateFormat.format(survey.endDate!)}';
    }
    
    if (survey.startDate != null) {
      return 'Starts ${dateFormat.format(survey.startDate!)}';
    }
    
    if (survey.endDate != null) {
      return 'Ends ${dateFormat.format(survey.endDate!)}';
    }
    
    return 'No dates set';
  }
}
