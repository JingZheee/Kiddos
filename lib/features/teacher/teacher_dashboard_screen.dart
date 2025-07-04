import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/ui_constants.dart';
import '../../core/routing/app_navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/user_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/teacher_custom_bottom_nav.dart';
import '../../core/services/kindergarten_service.dart';
import '../../models/kindergarten/kindergarten.dart';
import '../../features/teacher/classroom_selection_screen.dart';
import '../../features/teacher/attendance/teacher_attendance_with_ai_screen.dart';
import '../../core/services/classroom_teacher_service.dart';
import '../../core/services/classroom_service.dart';
import '../../models/classroom/classroom.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int _selectedIndex = 0;
  Kindergarten? _kindergarten;
  final KindergartenService _kindergartenService = KindergartenService();
  List<Classroom> _registeredClassrooms = [];
  bool _isLoadingClassrooms = false;

  @override
  void initState() {
    super.initState();
    _fetchKindergarten();
    _fetchRegisteredClassrooms();
  }

  Future<void> _fetchKindergarten() async {
    final userProvider = context.read<UserProvider>();
    final kindergartenId = userProvider.userModel?.kindergartenId;

    if (kindergartenId != null) {
      _kindergartenService.getKindergarten(kindergartenId).then((kg) {
        if (mounted) {
          setState(() {
            _kindergarten = kg;
          });
        }
      });
    }
  }

  Future<void> _fetchRegisteredClassrooms() async {
    setState(() {
      _isLoadingClassrooms = true;
    });
    final userProvider = context.read<UserProvider>();
    final teacherId = userProvider.userModel?.id;
    if (teacherId == null) {
      setState(() {
        _isLoadingClassrooms = false;
      });
      return;
    }
    final classroomTeacherService = ClassroomTeacherService();
    final classroomService = ClassroomService();
    // Get all ClassroomTeacher records for this teacher
    final allClassroomTeachers =
        await classroomTeacherService.getClassroomTeachers().first;
    final myClassroomTeachers =
        allClassroomTeachers.where((ct) => ct.teacherId == teacherId).toList();
    // Fetch all classrooms for these classroomIds
    List<Classroom> classrooms = [];
    for (final ct in myClassroomTeachers) {
      final classroom = await classroomService.getClassroom(ct.classroomId);
      if (classroom != null) classrooms.add(classroom);
    }
    setState(() {
      _registeredClassrooms = classrooms;
      _isLoadingClassrooms = false;
    });
  }

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
        return _buildCalendarTab();
      case 2:
        return _buildAttendanceTab();
      case 3:
        return _buildTasksTab();
      case 4:
        return _buildProfileTab();
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
          Text(
            'Hello, ' +
                (context.read<UserProvider>().userModel?.userName ??
                    'Teacher') +
                '!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: UIConstants.spacing8),
          if (_kindergarten != null)
            Text(
              'Kindergarten: ${_kindergarten!.name}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondaryColor,
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
          // Add navigation button for classroom selection if kindergartenId exists
          Builder(
            builder: (context) {
              final kindergartenId =
                  context.read<UserProvider>().userModel?.kindergartenId;
              if (kindergartenId == null) return const SizedBox.shrink();
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ClassroomSelectionScreen(
                          kindergartenId: kindergartenId),
                    ),
                  );
                },
                child: const Text('Go to Classroom Selection'),
              );            },          ),
          const SizedBox(height: UIConstants.spacing24),

          // Quick actions (without title)
          _buildQuickActions(),
          
          const SizedBox(height: UIConstants.spacing24),

          // Registered classrooms section
          const Text(
            'Registered Classrooms',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          _isLoadingClassrooms
              ? const Center(child: CircularProgressIndicator())
              : _registeredClassrooms.isEmpty
                  ? const Text('No classrooms registered yet.')
                  : Column(
                      children: _registeredClassrooms
                          .map((classroom) => ListTile(
                                leading: CircleAvatar(
                                  child: Text(classroom.name[0]),
                                ),
                                title: Text(classroom.name),
                                subtitle: Text('ID: ${classroom.id}'),
                              ))
                          .toList(),
                    ),
        ],
      ),
    );
  }
  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.76,
      children: [
        QuickActionButton(
          icon: Icons.calendar_month_outlined,
          label: 'Calendar',
          onTap: () {
            setState(() {
              _selectedIndex = 1; // Calendar tab
            });
          },
        ),
        QuickActionButton(
          icon: Icons.poll_outlined,
          label: 'Surveys',
          onTap: () {
            context.push('/teacher/dashboard/surveys');
          },
        ),
        QuickActionButton(
          icon: Icons.campaign_outlined,
          label: 'Announcements',
          onTap: () {
            context.push('/teacher/dashboard/announcements');
          },
        ),
        QuickActionButton(
          icon: Icons.how_to_reg_outlined,
          label: 'Attendance',
          onTap: () {
            setState(() {
              _selectedIndex = 2; // Attendance tab
            });
          },
        ),
        QuickActionButton(
          icon: Icons.task_outlined,
          label: 'Tasks',
          onTap: () {
            setState(() {
              _selectedIndex = 3; // Tasks tab
            });
          },
        ),
        QuickActionButton(
          icon: Icons.medication_outlined,
          label: 'Medications',
          onTap: () {
            AppNavigation.goToTeacherMedications(context);
          },
        ),
        QuickActionButton(
          icon: Icons.note_alt_outlined,
          label: 'Take Leave',
          onTap: () {
            context.pushNamed('teacher-leave');
          },
        ),
      ],
    );
  }
  Widget _buildCalendarTab() {
    // Calendar tab content
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 64,
            color: AppTheme.primaryColor,
          ),
          SizedBox(height: 16),
          Text(
            'Calendar Tab',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab() {
    // Show the AI-enhanced attendance screen
    return const TeacherAttendanceWithAiScreen();
  }

  Widget _buildTasksTab() {
    // Tasks tab content
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task,
            size: 64,
            color: AppTheme.primaryColor,
          ),
          SizedBox(height: 16),
          Text(
            'Tasks',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Manage your daily tasks',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    // Profile tab content
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            size: 64,
            color: AppTheme.primaryColor,
          ),
          SizedBox(height: 16),
          Text(
            'Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Manage your profile settings',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildBottomNavigationBar() {
    return TeacherCustomBottomNav(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
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
