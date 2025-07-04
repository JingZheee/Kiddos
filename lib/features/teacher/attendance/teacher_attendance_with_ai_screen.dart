import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../core/services/ai_face_detection_service.dart';
import '../../../models/student/student.dart';
import '../../../models/timestamp/timestamp_model.dart';
import 'ai_camera_attendance_screen.dart';

class TeacherAttendanceWithAiScreen extends StatefulWidget {
  const TeacherAttendanceWithAiScreen({Key? key}) : super(key: key);

  @override
  State<TeacherAttendanceWithAiScreen> createState() => _TeacherAttendanceWithAiScreenState();
}

class _TeacherAttendanceWithAiScreenState extends State<TeacherAttendanceWithAiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  final AiFaceDetectionService _aiService = AiFaceDetectionService();
  
  // Mock data - replace with actual data from your backend
  final List<Student> _students = [
    Student(
      id: '001',
      firstName: 'Emma',
      lastName: 'Johnson',
      dateOfBirth: DateTime(2019, 5, 15),
      kindergartenId: 'kg1',
      classroomId: 'class1',
      timestamps: Timestamps.now(),
    ),
    Student(
      id: '002',
      firstName: 'Liam',
      lastName: 'Smith',
      dateOfBirth: DateTime(2019, 8, 22),
      kindergartenId: 'kg1',
      classroomId: 'class1',
      timestamps: Timestamps.now(),
    ),
    Student(
      id: '003',
      firstName: 'Olivia',
      lastName: 'Brown',
      dateOfBirth: DateTime(2019, 3, 10),
      kindergartenId: 'kg1',
      classroomId: 'class1',
      timestamps: Timestamps.now(),
    ),
    Student(
      id: '004',
      firstName: 'Noah',
      lastName: 'Davis',
      dateOfBirth: DateTime(2019, 11, 5),
      kindergartenId: 'kg1',
      classroomId: 'class1',
      timestamps: Timestamps.now(),
    ),
    Student(
      id: '005',
      firstName: 'Ava',
      lastName: 'Wilson',
      dateOfBirth: DateTime(2019, 7, 18),
      kindergartenId: 'kg1',
      classroomId: 'class1',
      timestamps: Timestamps.now(),
    ),
    Student(
      id: '006',
      firstName: 'Elijah',
      lastName: 'Garcia',
      dateOfBirth: DateTime(2019, 9, 30),
      kindergartenId: 'kg1',
      classroomId: 'class1',
      timestamps: Timestamps.now(),
    ),
  ];

  final List<AttendanceRecord> _attendanceRecords = [];
  final Map<String, bool> _studentAttendance = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize attendance map
    for (final student in _students) {
      _studentAttendance[student.id] = false;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );
      
      if (photo != null) {
        _processPhotoWithAI(photo);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take photo: $e');
    }
  }

  Future<void> _processPhotoWithAI(XFile photo) async {
    // Get list of students who haven't been marked present yet
    final availableStudents = _students.where((student) => 
      !(_studentAttendance[student.id] ?? false)
    ).toList();

    if (availableStudents.isEmpty) {
      _showInfoSnackBar('All students have already been marked present');
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final result = await _aiService.detectAndIdentifyStudent(
        imagePath: photo.path,
        availableStudents: availableStudents,
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (result.isSuccessful && result.detectedStudent != null) {
        _markStudentPresent(result.detectedStudent!, photo);
        _showSuccessSnackBar(
          'AI detected ${result.detectedStudent!.firstName} ${result.detectedStudent!.lastName} with ${result.confidencePercentage} confidence'
        );
      } else {
        _showManualSelectionDialog(photo, result.errorMessage ?? 'AI detection failed');
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // Close loading dialog
      _showErrorSnackBar('AI processing failed: $e');
    }
  }

  void _showManualSelectionDialog(XFile photo, String aiError) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Detection Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(aiError),
            const SizedBox(height: 16),
            const Text('Please select the student manually:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showStudentSelectionDialog(photo);
            },
            child: const Text('Select Manually'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _takePhoto(); // Retake photo
            },
            child: const Text('Retake Photo'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showStudentSelectionDialog(XFile photo) {
    final availableStudents = _students.where((student) => 
      !(_studentAttendance[student.id] ?? false)
    ).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Student'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableStudents.length,
            itemBuilder: (context, index) {
              final student = availableStudents[index];
              return ListTile(
                title: Text('${student.firstName} ${student.lastName}'),
                onTap: () {
                  Navigator.of(context).pop();
                  _markStudentPresent(student, photo);
                  _showSuccessSnackBar('${student.firstName} ${student.lastName} marked as present');
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _markStudentPresent(Student student, XFile photo) {
    setState(() {
      _studentAttendance[student.id] = true;
      
      _attendanceRecords.add(
        AttendanceRecord(
          studentId: student.id,
          studentName: '${student.firstName} ${student.lastName}',
          arrivalTime: DateTime.now(),
          photoPath: photo.path,
        ),
      );
    });
  }

  void _toggleManualAttendance(Student student) async {
    final wasPresent = _studentAttendance[student.id] ?? false;
    
    if (!wasPresent) {
      // Student not present - require photo to mark as present
      await _takeManualPhoto(student);
    } else {
      // Student already present - toggle to absent (remove from records)
      setState(() {
        _studentAttendance[student.id] = false;
        _attendanceRecords.removeWhere((record) => record.studentId == student.id);
      });
      _showInfoSnackBar('${student.firstName} ${student.lastName} marked as absent');
    }
  }

  Future<void> _takeManualPhoto(Student student) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );
      
      if (photo != null) {
        // Mark student as present with photo proof
        setState(() {
          _studentAttendance[student.id] = true;
          
          _attendanceRecords.add(
            AttendanceRecord(
              studentId: student.id,
              studentName: '${student.firstName} ${student.lastName}',
              arrivalTime: DateTime.now(),
              photoPath: photo.path,
            ),
          );
        });
        _showSuccessSnackBar('${student.firstName} ${student.lastName} marked as present with photo proof');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take photo: $e');
    }
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Smart Attendance',
        userRole: 'teacher',
        actions: [
          IconButton(
            onPressed: () {
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
              icon: Icon(Icons.camera_alt_outlined),
              text: 'AI Attendance',
            ),
            Tab(
              icon: Icon(Icons.people_outline),
              text: 'Manual Check',
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
          _buildAiAttendanceTab(),
          _buildManualAttendanceTab(),
          _buildAttendanceRecordsTab(),
        ],
      ),
    );
  }

  Widget _buildAiAttendanceTab() {
    final presentCount = _studentAttendance.values.where((isPresent) => isPresent).length;
    final totalCount = _students.length;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100), // Add bottom padding for nav bar
      child: Column(
        children: [
          // Statistics Header
          Container(
            padding: const EdgeInsets.all(UIConstants.spacing16),
            margin: const EdgeInsets.all(UIConstants.spacing16),
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
                    'Remaining',
                    (totalCount - presentCount).toString(),
                    Icons.pending,
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
          
          // AI Camera Launch Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: UIConstants.spacing16),
            child: Column(
              children: [
                // AI Info Card
                Container(
                  padding: const EdgeInsets.all(UIConstants.spacing20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.1),
                        Colors.blue.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.smart_toy_outlined,
                            color: AppTheme.primaryColor,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Camera Attendance',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Smart face detection with Tinder-style confirmation',
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
                      
                      const SizedBox(height: 16),
                      
                      // Features
                      Row(
                        children: [
                          _buildFeatureChip('📸', 'Live Camera'),
                          const SizedBox(width: 8),
                          _buildFeatureChip('🤖', 'AI Detection'),
                          const SizedBox(width: 8),
                          _buildFeatureChip('👆', 'Swipe to Confirm'),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: UIConstants.spacing32),
                
                // Launch Camera Button
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(90),
                      onTap: _launchAiCamera,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 48,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Start AI\nAttendance',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: UIConstants.spacing24),
                
                // Instructions
                Container(
                  padding: const EdgeInsets.all(UIConstants.spacing16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'How it works:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInstructionStep('1', 'Take photo of student'),
                      _buildInstructionStep('2', 'AI shows student cards by confidence'),
                      _buildInstructionStep('3', 'Swipe right if correct, left if wrong'),
                      _buildInstructionStep('4', 'Continue with next student'),
                    ],
                  ),
                ),
                
                const SizedBox(height: UIConstants.spacing24),
                
                // Quick Stats
                Text(
                  '$presentCount of $totalCount students present',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _launchAiCamera() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AiCameraAttendanceScreen(
          onAttendanceMarked: _handleAiAttendanceMarked,
        ),
      ),
    );
  }

  void _handleAiAttendanceMarked(String studentId, String studentName, String imagePath) {
    setState(() {
      // Mark student as present
      _studentAttendance[studentId] = true;
      
      // Add attendance record
      _attendanceRecords.add(
        AttendanceRecord(
          studentId: studentId,
          studentName: studentName,
          arrivalTime: DateTime.now(),
          photoPath: imagePath,
        ),
      );
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('$studentName marked present via AI'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildManualAttendanceTab() {
    return ListView.builder(
      padding: const EdgeInsets.only(
        left: UIConstants.spacing16,
        right: UIConstants.spacing16,
        top: UIConstants.spacing16,
        bottom: 100, // Add bottom padding for nav bar
      ),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final isPresent = _studentAttendance[student.id] ?? false;
        
        return Container(
          margin: const EdgeInsets.only(bottom: UIConstants.spacing12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
            border: Border.all(
              color: isPresent 
                  ? Colors.green.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
              width: isPresent ? 2 : 1,
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
              backgroundColor: isPresent 
                  ? Colors.green 
                  : AppTheme.primaryColor.withOpacity(0.1),
              child: isPresent
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
                decoration: isPresent 
                    ? TextDecoration.lineThrough 
                    : TextDecoration.none,
                color: isPresent 
                    ? AppTheme.textSecondaryColor 
                    : AppTheme.textPrimaryColor,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student ID: ${student.id}',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
                if (isPresent)
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
            trailing: isPresent
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _toggleManualAttendance(student),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  )
                : SizedBox(
                    width: 100,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () => _toggleManualAttendance(student),
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
      },
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
      padding: const EdgeInsets.only(
        left: UIConstants.spacing16,
        right: UIConstants.spacing16,
        top: UIConstants.spacing16,
        bottom: 100, // Add bottom padding for nav bar
      ),
      itemCount: _attendanceRecords.length,
      itemBuilder: (context, index) {
        final record = _attendanceRecords[index];
        return _buildAttendanceRecordCard(record);
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
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
            // Photo or placeholder
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
                if (record.photoPath != null) ...[
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

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// Models
class AttendanceRecord {
  final String studentId;
  final String studentName;
  final DateTime arrivalTime;
  final String? photoPath;

  AttendanceRecord({
    required this.studentId,
    required this.studentName,
    required this.arrivalTime,
    this.photoPath,
  });
}
