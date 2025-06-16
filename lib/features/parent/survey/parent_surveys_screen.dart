import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/survey_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/app_loading.dart';
import '../../../models/survey/survey_model.dart';

class ParentSurveysScreen extends StatefulWidget {
  const ParentSurveysScreen({super.key});

  @override
  State<ParentSurveysScreen> createState() => _ParentSurveysScreenState();
}

class _ParentSurveysScreenState extends State<ParentSurveysScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load surveys when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      if (userProvider.userModel != null) {        context.read<SurveyProvider>()
            .fetchParentSurveys(userProvider.userModel!.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshSurveys() async {
    final userProvider = context.read<UserProvider>();    if (userProvider.userModel != null) {
      await context.read<SurveyProvider>()
          .refreshParentSurveys(userProvider.userModel!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Surveys',        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pending_actions, size: 16),
                  const SizedBox(width: 4),                  const Text('Pending'),
                  Consumer<SurveyProvider>(
                    builder: (context, provider, child) {
                      final count = provider.pendingSurveyCount;
                      if (count > 0) {
                        return Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor2,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 16),
                  SizedBox(width: 4),
                  Text('Completed'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSurveys,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildPendingSurveysTab(),
            _buildCompletedSurveysTab(),
          ],
        ),
      ),
    );
  }
  Widget _buildPendingSurveysTab() {
    return Consumer<SurveyProvider>(
      builder: (context, provider, child) {
        if (provider.hasParentError) {
          return _buildErrorState(provider.parentErrorMessage);
        }

        if (provider.isParentLoading) {
          return const AppLoading(message: 'Loading surveys...');
        }

        if (provider.pendingSurveys.isEmpty) {
          return _buildEmptyState(
            icon: Icons.assignment_outlined,
            title: 'No Pending Surveys',
            subtitle: 'All surveys have been completed.\nNew surveys will appear here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(UIConstants.spacing16),
          itemCount: provider.pendingSurveys.length,
          itemBuilder: (context, index) {
            final survey = provider.pendingSurveys[index];
            return ParentSurveyCard(
              survey: survey,
              isPending: true,
              onTap: () => _navigateToSurveyForm(survey),
            );
          },
        );
      },
    );
  }
  Widget _buildCompletedSurveysTab() {
    return Consumer<SurveyProvider>(
      builder: (context, provider, child) {
        if (provider.hasParentError) {
          return _buildErrorState(provider.parentErrorMessage);
        }

        if (provider.isParentLoading) {
          return const AppLoading(message: 'Loading surveys...');
        }

        if (provider.completedSurveys.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            title: 'No Completed Surveys',
            subtitle: 'Surveys you complete will appear here for reference.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(UIConstants.spacing16),
          itemCount: provider.completedSurveys.length,
          itemBuilder: (context, index) {
            final survey = provider.completedSurveys[index];
            return ParentSurveyCard(
              survey: survey,
              isPending: false,
              onTap: () => _showCompletedSurveyDialog(survey),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorState(String? errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? 'Unknown error occurred',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshSurveys,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppTheme.textLightColor,
          ),
          const SizedBox(height: UIConstants.spacing16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: UIConstants.spacing8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textLightColor,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSurveyForm(SurveyModel survey) {
    context.push('/parent/dashboard/surveys/form/${survey.id}');
  }

  void _showCompletedSurveyDialog(SurveyModel survey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(survey.title),
        content: const Text('This survey has been completed. Thank you for your response!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class ParentSurveyCard extends StatelessWidget {
  final SurveyModel survey;
  final bool isPending;
  final VoidCallback onTap;

  const ParentSurveyCard({
    super.key,
    required this.survey,
    required this.isPending,
    required this.onTap,
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
                ],
              ),
              if (survey.description != null && survey.description!.isNotEmpty) ...[
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
                    Icons.quiz_outlined,
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
                  const SizedBox(width: UIConstants.spacing16),
                  if (survey.endDate != null) ...[
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: UIConstants.spacing4),
                    Text(
                      'Due ${_formatDueDate(survey.endDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    final backgroundColor = isPending 
        ? AppTheme.accentColor2.withOpacity(0.1)
        : AppTheme.accentColor1.withOpacity(0.1);
    final textColor = isPending ? AppTheme.accentColor2 : AppTheme.accentColor1;
    final text = isPending ? 'Pending' : 'Completed';
    final icon = isPending ? Icons.pending_actions : Icons.check_circle;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacing8,
        vertical: UIConstants.spacing4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference < 0) {
      return 'Overdue';
    } else if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference < 7) {
      return '${difference} days';
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }
}
