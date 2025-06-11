import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/ui_constants.dart';
import '../../core/routing/app_navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/user_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_card.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int _selectedIndex = 0;

  void _signOut() async {
    final userProvider = context.read<UserProvider>();
    
    try {
      await userProvider.signOut();
      // No need for manual navigation - AuthenticationWrapper will handle it
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error signing out. Please try again.'),
            backgroundColor: AppTheme.accentColor2,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Teacher Dashboard',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildClassroomTab();
      case 2:
        return _buildActivitiesTab();
      case 3:
        return _buildMessagesTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hello, Teacher',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: UIConstants.spacing8),
          const Text(
            'Welcome to your classroom dashboard',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: UIConstants.spacing24),
          
          // Class summary card
          InfoCard(
            title: 'Class Summary',
            subtitle: '12 children present, 3 absent',
            icon: Icons.groups_outlined,
            iconColor: AppTheme.primaryColor,
            onTap: () {
              // TODO: Navigate to attendance detail
            },
            margin: const EdgeInsets.only(bottom: UIConstants.spacing16),
          ),
          
          // Today's schedule
          InfoCard(
            title: 'Today\'s Schedule',
            subtitle: '5 activities planned',
            icon: Icons.calendar_today,
            iconColor: AppTheme.secondaryColor,
            onTap: () {
              // TODO: Navigate to schedule
            },
            margin: const EdgeInsets.only(bottom: UIConstants.spacing16),
          ),
          
          // Pending tasks
          const Text(
            'Pending Tasks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: UIConstants.spacing16),
          _buildPendingTasks(),
          
          const SizedBox(height: UIConstants.spacing24),
          
          // Quick actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: UIConstants.spacing16),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildPendingTasks() {
    return Column(
      children: [
        TaskItem(
          title: 'Take Attendance',
          dueTime: 'Due 9:15 AM',
          isCompleted: true,
          onTap: () {
            // TODO: Navigate to attendance
          },
        ),
        TaskItem(
          title: 'Log Meal Activities',
          dueTime: 'Due 1:00 PM',
          isCompleted: false,
          onTap: () {
            // TODO: Navigate to meal activities
          },
        ),
        TaskItem(
          title: 'Update Parent Messages',
          dueTime: 'Due 4:00 PM',
          isCompleted: false,
          onTap: () {
            // TODO: Navigate to messaging
          },
        ),
      ],
    );
  }
  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        QuickActionButton(
          icon: Icons.add_task_outlined,
          label: 'Activity',
          onTap: () {
            // TODO: Add new activity
            setState(() {
              _selectedIndex = 2;
            });
          },
        ),        QuickActionButton(
          icon: Icons.poll_outlined,
          label: 'Surveys',
          onTap: () {
            context.push('/teacher/dashboard/surveys');
          },
        ),
        QuickActionButton(
          icon: Icons.person_add_outlined,
          label: 'Attendance',
          onTap: () {
            // TODO: Take attendance
          },
        ),
        QuickActionButton(
          icon: Icons.message_outlined,
          label: 'Message',
          onTap: () {
            // TODO: Send new message
            setState(() {
              _selectedIndex = 3;
            });
          },
        ),
        QuickActionButton(
          icon: Icons.medication_outlined,
          label: 'Medications',
          onTap: () {
            // TODO: Update Medication
            AppNavigation.goToTeacherMedications(context);
          },
        ),
      ],
    );
  }

  Widget _buildClassroomTab() {
    // Placeholder for classroom tab
    return const Center(
      child: Text('Classroom Tab - Coming Soon'),
    );
  }

  Widget _buildActivitiesTab() {
    // Placeholder for activities tab
    return const Center(
      child: Text('Activities Tab - Coming Soon'),
    );
  }

  Widget _buildMessagesTab() {
    // Placeholder for messages tab
    return const Center(
      child: Text('Messages Tab - Coming Soon'),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: AppTheme.textSecondaryColor,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.groups_outlined),
          activeIcon: Icon(Icons.groups),
          label: 'Classroom',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: 'Activities',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message_outlined),
          activeIcon: Icon(Icons.message),
          label: 'Messages',
        ),
      ],
    );
  }
}

class TaskItem extends StatelessWidget {
  final String title;
  final String dueTime;
  final bool isCompleted;
  final VoidCallback? onTap;

  const TaskItem({
    Key? key,
    required this.title,
    required this.dueTime,
    required this.isCompleted,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: UIConstants.spacing8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? AppTheme.accentColor1 : Colors.transparent,
                border: Border.all(
                  color: isCompleted ? AppTheme.accentColor1 : AppTheme.textSecondaryColor,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: UIConstants.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isCompleted
                          ? AppTheme.textSecondaryColor
                          : AppTheme.textPrimaryColor,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dueTime,
                    style: TextStyle(
                      fontSize: 14,
                      color: isCompleted
                          ? AppTheme.textLightColor
                          : AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isCompleted
                  ? AppTheme.textLightColor
                  : AppTheme.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: UIConstants.spacing8,
          vertical: UIConstants.spacing12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(UIConstants.spacing12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: UIConstants.spacing8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
