import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/ui_constants.dart';

class ParentAttendanceScreen extends StatefulWidget {
  const ParentAttendanceScreen({super.key});

  @override
  State<ParentAttendanceScreen> createState() => _ParentAttendanceScreenState();
}

class _ParentAttendanceScreenState extends State<ParentAttendanceScreen> {
  int _selectedChildIndex = 0;

  // Dummy data for children
  final List<ChildAttendanceData> _children = [
    ChildAttendanceData(
      childId: '1',
      name: 'Emma Johnson',
      className: 'Rose Class',
      profileImage: null,
      attendanceRecords: [
        AttendanceRecord(
          date: DateTime.now(),
          isPresent: true,
          arrivalTime: '8:30 AM',
          photoProofUrl: 'dummy_photo_1.jpg',
          teacher: 'Ms. Sarah',
        ),
        AttendanceRecord(
          date: DateTime.now().subtract(const Duration(days: 1)),
          isPresent: true,
          arrivalTime: '8:45 AM',
          photoProofUrl: 'dummy_photo_2.jpg',
          teacher: 'Ms. Sarah',
        ),
        AttendanceRecord(
          date: DateTime.now().subtract(const Duration(days: 2)),
          isPresent: false,
          arrivalTime: null,
          photoProofUrl: null,
          teacher: null,
          reason: 'Sick leave',
        ),
        AttendanceRecord(
          date: DateTime.now().subtract(const Duration(days: 3)),
          isPresent: true,
          arrivalTime: '8:25 AM',
          photoProofUrl: 'dummy_photo_3.jpg',
          teacher: 'Ms. Sarah',
        ),
        AttendanceRecord(
          date: DateTime.now().subtract(const Duration(days: 4)),
          isPresent: true,
          arrivalTime: '8:40 AM',
          photoProofUrl: 'dummy_photo_4.jpg',
          teacher: 'Ms. Sarah',
        ),
      ],
    ),
    ChildAttendanceData(
      childId: '2',
      name: 'Oliver Johnson',
      className: 'Lily Class',
      profileImage: null,
      attendanceRecords: [
        AttendanceRecord(
          date: DateTime.now(),
          isPresent: true,
          arrivalTime: '8:20 AM',
          photoProofUrl: 'dummy_photo_5.jpg',
          teacher: 'Ms. Anna',
        ),
        AttendanceRecord(
          date: DateTime.now().subtract(const Duration(days: 1)),
          isPresent: true,
          arrivalTime: '8:35 AM',
          photoProofUrl: 'dummy_photo_6.jpg',
          teacher: 'Ms. Anna',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_children.length > 1) _buildChildSelector(),
            Expanded(
              child: _buildAttendanceList(),
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
          const Text(
            'Attendance Records',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your child\'s daily attendance',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildSelector() {
    return Container(
      height: 120,
      margin: const EdgeInsets.all(UIConstants.spacing16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _children.length,
        itemBuilder: (context, index) {
          final child = _children[index];
          final bool isSelected = index == _selectedChildIndex;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedChildIndex = index;
              });
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      child.name[0],
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    child.name.split(' ')[0],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppTheme.textPrimaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    child.className,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAttendanceList() {
    final child = _children[_selectedChildIndex];
    
    if (child.attendanceRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No attendance records yet',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      itemCount: child.attendanceRecords.length,
      itemBuilder: (context, index) {
        final record = child.attendanceRecords[index];
        return _buildAttendanceCard(record);
      },
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 12),
            
            if (record.isPresent) ...[
              _buildInfoRow(Icons.access_time, 'Arrival Time', record.arrivalTime!),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.person, 'Recorded by', record.teacher!),
              
              if (record.photoProofUrl != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Photo Evidence',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showPhotoProof(record.photoProofUrl!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'View Photo',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ] else ...[
              if (record.reason != null)
                _buildInfoRow(Icons.info_outline, 'Reason', record.reason!),
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

  void _showPhotoProof(String photoUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo,
                      size: 64,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Photo Proof',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dummy photo: $photoUrl',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Data models
class ChildAttendanceData {
  final String childId;
  final String name;
  final String className;
  final String? profileImage;
  final List<AttendanceRecord> attendanceRecords;

  ChildAttendanceData({
    required this.childId,
    required this.name,
    required this.className,
    this.profileImage,
    required this.attendanceRecords,
  });
}

class AttendanceRecord {
  final DateTime date;
  final bool isPresent;
  final String? arrivalTime;
  final String? photoProofUrl;
  final String? teacher;
  final String? reason;

  AttendanceRecord({
    required this.date,
    required this.isPresent,
    this.arrivalTime,
    this.photoProofUrl,
    this.teacher,
    this.reason,
  });
}
