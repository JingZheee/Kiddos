import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class AttendanceOptionsDialog {
  static void show({
    required BuildContext context,
    required VoidCallback onAiAttendanceSelected,
    required VoidCallback onRegularAttendanceSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                'Attendance Options',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 20),
              
              // AI Attendance Option
              _buildAttendanceOption(
                context: context,
                icon: Icons.smart_toy,
                title: 'AI Photo Attendance',
                subtitle: 'Take a photo and let AI identify the student',
                gradientColors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                badgeText: 'NEW',
                badgeColor: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  onAiAttendanceSelected();
                },
              ),
              
              const SizedBox(height: 12),
              
              // Regular Attendance Option
              _buildAttendanceOption(
                context: context,
                icon: Icons.fact_check,
                title: 'View Attendance Records',
                subtitle: 'Check attendance history and records',
                gradientColors: [Colors.blue, Colors.blue.withOpacity(0.8)],
                onTap: () {
                  Navigator.pop(context);
                  onRegularAttendanceSelected();
                },
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildAttendanceOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    String? badgeText,
    Color? badgeColor,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor!.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: badgeColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
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
    );
  }
}
