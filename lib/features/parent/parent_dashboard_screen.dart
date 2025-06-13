import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/ui_constants.dart';
import '../../core/routing/app_navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/user_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_card.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
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
        title: 'Parent Dashboard',
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
        return _buildActivitiesTab();
      case 2:
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
            'Good Morning, Parent',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: UIConstants.spacing8),
          const Text(
            'Here\'s what\'s happening today',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: UIConstants.spacing24),
          
          // Child status card
          StatusCard(
            title: 'Emily\'s Status',
            status: 'Present',
            statusColor: AppTheme.accentColor1,
            icon: Icons.child_care,
            onTap: () {
              // TODO: Navigate to child detail
            },
            margin: const EdgeInsets.only(bottom: UIConstants.spacing16),
          ),
          
          // Today's schedule
          InfoCard(
            title: 'Today\'s Schedule',
            subtitle: 'View your child\'s activities for today',
            icon: Icons.calendar_today,
            onTap: () {
              // TODO: Navigate to schedule
            },
            margin: const EdgeInsets.only(bottom: UIConstants.spacing16),
          ),
          
          // Recent activities
          const Text(
            'Recent Activities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: UIConstants.spacing16),
          _buildRecentActivities(),
          
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

  Widget _buildRecentActivities() {
    return Column(
      children: [
        ActivityItem(
          title: 'Lunch',
          description: 'Emily had lunch at 12:30 PM',
          icon: Icons.restaurant,
          time: '12:30 PM',
          onTap: () {
            // TODO: Show activity details
          },
        ),
        ActivityItem(
          title: 'Nap Time',
          description: 'Emily slept for 1.5 hours',
          icon: Icons.hotel,
          time: '1:30 PM',
          onTap: () {
            // TODO: Show activity details
          },
        ),
        ActivityItem(
          title: 'Learning Activity',
          description: 'Participated in alphabet learning game',
          icon: Icons.school,
          time: '3:00 PM',
          onTap: () {
            // TODO: Show activity details
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.76, // Adjust the aspect ratio to provide more space for text
      children: [
        QuickActionButton(
          icon: Icons.message_outlined,
          label: 'Message',
          onTap: () {
            // TODO: Navigate to messages
            setState(() {
              _selectedIndex = 3;
            });
          },
        ),
        QuickActionButton(
          icon: Icons.note_alt_outlined,
          label: 'Absence Note',
          onTap: () {
            // TODO: Report absence
          },
        ),
        QuickActionButton(
          icon: Icons.admin_panel_settings_outlined,
          label: 'Test Roles',
          onTap: () {
            Navigator.pushNamed(context, '/example/user-roles');
          },
        ),
        QuickActionButton(
          icon: Icons.calendar_month_outlined,
          label: 'Calendar',
          onTap: () {
            // TODO: Navigate to calendar
          },
        ),
        QuickActionButton(
          icon: Icons.schedule_outlined,
          label: 'Pick Up',
          onTap: () {
            // TODO: Schedule pickup
          },
        ),
        QuickActionButton(
          icon: Icons.medication_outlined,
          label: 'Medications',
          onTap: () {
            // TODO: Navigate to medications
            AppNavigation.goToParentMedications(context);
          },
        ),
      ],
    );  }

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
          icon: Icon(Icons.child_care_outlined),
          activeIcon: Icon(Icons.child_care),
          label: 'Children',
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

class ActivityItem extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String time;
  final VoidCallback? onTap;

  const ActivityItem({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.time,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(UIConstants.spacing8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: UIConstants.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              time,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
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
