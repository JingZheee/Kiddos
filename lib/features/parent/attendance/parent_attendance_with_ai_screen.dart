import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/services/student_service.dart';
import '../../../core/services/student_parent_service.dart';
import '../../../core/providers/user_provider.dart';
import '../../../models/student/student.dart';
import '../../../widgets/ai_photo_attendance_widget.dart';

class ParentAttendanceWithAiScreen extends StatefulWidget {
  const ParentAttendanceWithAiScreen({super.key});

  @override
  State<ParentAttendanceWithAiScreen> createState() => _ParentAttendanceWithAiScreenState();
}

class _ParentAttendanceWithAiScreenState extends State<ParentAttendanceWithAiScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Student> _registeredStudents = [];
  bool _isLoadingStudents = false;

  // Mock attendance records for demo
  final List<AttendanceRecord> _attendanceRecords = [
    AttendanceRecord(
      date: DateTime.now(),
      studentName: 'Emma Johnson',
      isPresent: true,
      arrivalTime: '8:30 AM',
      photoProofUrl: 'dummy_photo_1.jpg',
      teacher: 'Ms. Sarah',
      recordType: AttendanceRecordType.manual,
    ),
    AttendanceRecord(
      date: DateTime.now().subtract(const Duration(days: 1)),
      studentName: 'Emma Johnson',
      isPresent: true,
      arrivalTime: '8:45 AM',
      photoProofUrl: 'dummy_photo_2.jpg',
      teacher: 'AI Detection',
      recordType: AttendanceRecordType.aiDetected,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchRegisteredStudents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchRegisteredStudents() async {
    setState(() {
      _isLoadingStudents = true;
    });

    try {
      final userProvider = context.read<UserProvider>();
      final parentId = userProvider.userModel?.id;
      
      if (parentId != null) {
        final studentParentService = StudentParentService();
        final studentService = StudentService();
        
        // Get all StudentParent records for this parent
        final allStudentParents = await studentParentService.getStudentParents().first;
        final myStudentParents = allStudentParents.where((sp) => sp.parentId == parentId).toList();
        
        // Fetch all students for these studentIds
        List<Student> students = [];
        for (final sp in myStudentParents) {
          final student = await studentService.getStudent(sp.studentId);
          if (student != null) students.add(student);
        }
        
        setState(() {
          _registeredStudents = students;
        });
      }
    } catch (e) {
      debugPrint('Error fetching students: $e');
    } finally {
      setState(() {
        _isLoadingStudents = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTakeAttendanceTab(),
                  _buildAttendanceRecordsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.how_to_reg,
                color: AppTheme.primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Smart Attendance',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      'AI-powered attendance marking',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.textSecondaryColor,
        indicatorColor: AppTheme.primaryColor,
        tabs: const [
          Tab(
            icon: Icon(Icons.camera_alt),
            text: 'Take Attendance',
          ),
          Tab(
            icon: Icon(Icons.history),
            text: 'Records',
          ),
        ],
      ),
    );
  }

  Widget _buildTakeAttendanceTab() {
    if (_isLoadingStudents) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_registeredStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.child_care_outlined,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No students found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please register students first',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textLightColor,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttendanceOptions(),
          const SizedBox(height: UIConstants.spacing24),
          _buildStudentsList(),
        ],
      ),
    );
  }

  Widget _buildAttendanceOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attendance Options',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: UIConstants.spacing16),
        
        // AI Photo Attendance Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
          ),
          child: InkWell(
            onTap: _showAiPhotoAttendance,
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
            child: Container(
              padding: const EdgeInsets.all(UIConstants.spacing16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: UIConstants.spacing16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'AI Photo Attendance',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Text(
                                'NEW',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Take a photo and let AI automatically identify and mark the student present',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Fast & Accurate',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'One-tap solution',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.textSecondaryColor,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Students',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: UIConstants.spacing16),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _registeredStudents.length,
          itemBuilder: (context, index) {
            final student = _registeredStudents[index];
            return _buildStudentCard(student);
          },
        ),
      ],
    );
  }

  Widget _buildStudentCard(Student student) {
    // Check if student is already marked present today
    final isMarkedToday = _attendanceRecords.any((record) => 
      record.studentName == '${student.firstName} ${student.lastName}' &&
      record.isPresent &&
      _isSameDay(record.date, DateTime.now())
    );

    return Container(
      margin: const EdgeInsets.only(bottom: UIConstants.spacing12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        border: Border.all(
          color: isMarkedToday 
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: isMarkedToday ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(UIConstants.spacing12),
        leading: CircleAvatar(
          backgroundColor: isMarkedToday 
              ? Colors.green 
              : AppTheme.primaryColor.withOpacity(0.1),
          child: isMarkedToday
              ? const Icon(Icons.check, color: Colors.white)
              : Text(
                  student.firstName[0],
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        title: Text(
          '${student.firstName} ${student.lastName}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: isMarkedToday 
                ? TextDecoration.lineThrough 
                : TextDecoration.none,
            color: isMarkedToday 
                ? AppTheme.textSecondaryColor 
                : AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Class: ${student.classroomId ?? "Not assigned"}',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
            if (isMarkedToday) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Present Today',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: isMarkedToday
            ? const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              )
            : SizedBox(
                width: 120,
                height: 36,
                child: ElevatedButton(
                  onPressed: () => _showManualAttendanceOptions(student),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    textStyle: const TextStyle(fontSize: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt, size: 14),
                      SizedBox(width: 4),
                      Text('Mark Present'),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAttendanceRecordsTab() {
    if (_attendanceRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No attendance records yet',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start marking attendance to see records here',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textLightColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      itemCount: _attendanceRecords.length,
      itemBuilder: (context, index) {
        final record = _attendanceRecords[index];
        return _buildAttendanceRecordCard(record);
      },
    );
  }

  Widget _buildAttendanceRecordCard(AttendanceRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: UIConstants.spacing12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(record.date),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Row(
                  children: [
                    if (record.recordType == AttendanceRecordType.aiDetected) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.smart_toy,
                              size: 12,
                              color: Colors.purple,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'AI',
                              style: TextStyle(
                                color: Colors.purple,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: record.isPresent 
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        record.isPresent ? 'Present' : 'Absent',
                        style: TextStyle(
                          color: record.isPresent ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Text(
              record.studentName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            
            if (record.isPresent) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.access_time, 'Arrival Time', record.arrivalTime!),
              const SizedBox(height: 4),
              _buildInfoRow(Icons.person, 'Recorded by', record.teacher!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  void _showAiPhotoAttendance() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AiPhotoAttendanceWidget(
          availableStudents: _registeredStudents,
          onStudentIdentified: (student, photo) {
            _markStudentPresentWithAi(student, photo);
            Navigator.of(context).pop();
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  void _showManualAttendanceOptions(Student student) {
    // For now, just mark present manually
    // In a real app, this might show more options
    _markStudentPresent(student);
  }

  void _markStudentPresentWithAi(Student student, XFile photo) {
    setState(() {
      _attendanceRecords.insert(0, AttendanceRecord(
        date: DateTime.now(),
        studentName: '${student.firstName} ${student.lastName}',
        isPresent: true,
        arrivalTime: _formatTime(DateTime.now()),
        photoProofUrl: photo.path,
        teacher: 'AI Detection',
        recordType: AttendanceRecordType.aiDetected,
      ));
    });
    
    _showSuccessSnackBar('${student.firstName} ${student.lastName} marked present via AI detection');
  }

  void _markStudentPresent(Student student) {
    setState(() {
      _attendanceRecords.insert(0, AttendanceRecord(
        date: DateTime.now(),
        studentName: '${student.firstName} ${student.lastName}',
        isPresent: true,
        arrivalTime: _formatTime(DateTime.now()),
        photoProofUrl: null,
        teacher: 'Manual Entry',
        recordType: AttendanceRecordType.manual,
      ));
    });
    
    _showSuccessSnackBar('${student.firstName} ${student.lastName} marked present');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
}

// Enhanced AttendanceRecord model with record type
class AttendanceRecord {
  final DateTime date;
  final String studentName;
  final bool isPresent;
  final String? arrivalTime;
  final String? photoProofUrl;
  final String? teacher;
  final AttendanceRecordType recordType;

  AttendanceRecord({
    required this.date,
    required this.studentName,
    required this.isPresent,
    this.arrivalTime,
    this.photoProofUrl,
    this.teacher,
    this.recordType = AttendanceRecordType.manual,
  });
}

enum AttendanceRecordType {
  manual,
  aiDetected,
}
