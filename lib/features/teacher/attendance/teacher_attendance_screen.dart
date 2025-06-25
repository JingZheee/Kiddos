import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/photo_assignment_dialog.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  
  // Mock data - replace with actual data from your backend
  final List<Student> _students = [
    Student(id: '001', name: 'Emma Johnson', parentName: 'Sarah Johnson', isPresent: false),
    Student(id: '002', name: 'Liam Smith', parentName: 'Mike Smith', isPresent: true),
    Student(id: '003', name: 'Olivia Brown', parentName: 'Lisa Brown', isPresent: false),
    Student(id: '004', name: 'Noah Davis', parentName: 'John Davis', isPresent: false),
    Student(id: '005', name: 'Ava Wilson', parentName: 'Maria Wilson', isPresent: true),
    Student(id: '006', name: 'Elijah Garcia', parentName: 'Carlos Garcia', isPresent: false),
  ];

  final List<AttendanceRecord> _attendanceRecords = [
    AttendanceRecord(
      studentId: '002',
      studentName: 'Liam Smith',
      parentName: 'Mike Smith',
      arrivalTime: DateTime.now().subtract(const Duration(minutes: 30)),
      photoPath: null, // In real app, this would be a file path or URL
    ),
    AttendanceRecord(
      studentId: '005',
      studentName: 'Ava Wilson',
      parentName: 'Maria Wilson',
      arrivalTime: DateTime.now().subtract(const Duration(minutes: 15)),
      photoPath: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto(Student student) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );
      
      if (photo != null) {
        _showPhotoConfirmationDialog(student, photo);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take photo: $e');
    }
  }

  void _showPhotoConfirmationDialog(Student student, XFile photo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PhotoAssignmentDialog(
          studentName: student.name,
          parentName: student.parentName,
          photo: photo,
          onConfirm: () {
            _markStudentPresent(student, photo);
            Navigator.of(context).pop();
          },
          onCancel: () {
            Navigator.of(context).pop();
            // Retake photo
            _takePhoto(student);
          },
        );
      },
    );
  }

  void _markStudentPresent(Student student, XFile photo) {
    setState(() {
      // Update student status
      final index = _students.indexWhere((s) => s.id == student.id);
      if (index != -1) {
        _students[index] = _students[index].copyWith(isPresent: true);
      }
      
      // Add attendance record
      _attendanceRecords.add(
        AttendanceRecord(
          studentId: student.id,
          studentName: student.name,
          parentName: student.parentName,
          arrivalTime: DateTime.now(),
          photoPath: photo.path,
        ),
      );
    });
    
    _showSuccessSnackBar('${student.name} marked as present');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Attendance',
        userRole: 'teacher',
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Export attendance report
              _showInfoSnackBar('Export feature coming soon');
            },
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export Report',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: Icon(Icons.people_outline),
              text: 'Take Attendance',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Today\'s Records',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTakeAttendanceTab(),
          _buildAttendanceRecordsTab(),
        ],
      ),
    );
  }

  Widget _buildTakeAttendanceTab() {
    final presentCount = _students.where((s) => s.isPresent).length;
    final totalCount = _students.length;
    
    return Column(
      children: [
        // Statistics Header
        Container(
          padding: const EdgeInsets.all(UIConstants.spacing16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withOpacity(0.1),
                AppTheme.secondaryColor.withOpacity(0.1),
              ],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Present',
                  presentCount.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: UIConstants.spacing12),
              Expanded(
                child: _buildStatCard(
                  'Absent',
                  (totalCount - presentCount).toString(),
                  Icons.cancel,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: UIConstants.spacing12),
              Expanded(
                child: _buildStatCard(
                  'Total',
                  totalCount.toString(),
                  Icons.groups,
                  AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
        
        // Students List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(UIConstants.spacing16),
            itemCount: _students.length,
            itemBuilder: (context, index) {
              final student = _students[index];
              return _buildStudentCard(student);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Student student) {
    return Container(
      margin: const EdgeInsets.only(bottom: UIConstants.spacing12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        border: Border.all(
          color: student.isPresent 
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: student.isPresent ? 2 : 1,
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
          backgroundColor: student.isPresent 
              ? Colors.green 
              : AppTheme.primaryColor.withOpacity(0.1),
          child: student.isPresent
              ? const Icon(Icons.check, color: Colors.white)
              : Text(
                  student.name[0],
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        title: Text(
          student.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: student.isPresent 
                ? TextDecoration.lineThrough 
                : TextDecoration.none,
            color: student.isPresent 
                ? AppTheme.textSecondaryColor 
                : AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parent: ${student.parentName}',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
            if (student.isPresent)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Present',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        trailing: student.isPresent
            ? const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              )
            : SizedBox(
                width: 100,
                height: 36,
                child: ElevatedButton(
                  onPressed: () => _takePhoto(student),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      Text('Photo'),
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
              'Start taking attendance to see records here',
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
        child: Row(
          children: [
            // Photo placeholder or actual photo
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: record.photoPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        File(record.photoPath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: AppTheme.primaryColor,
                      size: 30,
                    ),
            ),
            const SizedBox(width: UIConstants.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.studentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Parent: ${record.parentName}',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(record.arrivalTime),
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Present',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _viewPhoto(record),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.visibility,
                      color: AppTheme.primaryColor,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _viewPhoto(AttendanceRecord record) {
    if (record.photoPath == null) {
      _showInfoSnackBar('No photo available');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  record.studentName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                width: 300,
                height: 300,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(record.photoPath!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Arrived: ${_formatTime(record.arrivalTime)}',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// Models
class Student {
  final String id;
  final String name;
  final String parentName;
  final bool isPresent;

  Student({
    required this.id,
    required this.name,
    required this.parentName,
    required this.isPresent,
  });

  Student copyWith({
    String? id,
    String? name,
    String? parentName,
    bool? isPresent,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      parentName: parentName ?? this.parentName,
      isPresent: isPresent ?? this.isPresent,
    );
  }
}

class AttendanceRecord {
  final String studentId;
  final String studentName;
  final String parentName;
  final DateTime arrivalTime;
  final String? photoPath;

  AttendanceRecord({
    required this.studentId,
    required this.studentName,
    required this.parentName,
    required this.arrivalTime,
    this.photoPath,
  });
}
