import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class TeacherCustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const TeacherCustomBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90, // Increased height to accommodate elevated button
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main navigation bar with notch
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: CustomPaint(
              painter: BottomNavPainter(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Home
                  _buildNavItem(
                    index: 0,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Home',
                  ),
                  // Calendar
                  _buildNavItem(
                    index: 1,
                    icon: Icons.calendar_today_outlined,
                    activeIcon: Icons.calendar_today,
                    label: 'Calendar',
                  ),
                  // Empty space for the floating attendance button
                  const SizedBox(width: 56),
                  // Tasks
                  _buildNavItem(
                    index: 3,
                    icon: Icons.task_outlined,
                    activeIcon: Icons.task,
                    label: 'Tasks',
                  ),
                  // Profile
                  _buildNavItem(
                    index: 4,
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
          // Floating attendance button - positioned higher
          Positioned(
            top: 0, // Moved to the very top for maximum contrast
            left: MediaQuery.of(context).size.width / 2 - 35, // Centered with larger button
            child: GestureDetector(
              onTap: () => onTap(2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 70, // Slightly larger for more prominence
                    height: 70,
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
                          color: AppTheme.primaryColor.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      currentIndex == 2
                          ? Icons.how_to_reg
                          : Icons.how_to_reg_outlined,
                      color: Colors.white,
                      size: 32, // Larger icon for better visibility
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Attendance',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: currentIndex == 2 ? FontWeight.w600 : FontWeight.w400,
                      color: currentIndex == 2
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isSelected = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12), // Increased padding to center better
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondaryColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomNavPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Create a subtle notch in the center
    final notchRadius = 40.0;
    final notchCenter = size.width / 2;
    final notchTop = 15.0;
    
    // Start from left edge
    path.moveTo(0, 0);
    path.lineTo(notchCenter - notchRadius, 0);
    
    // Create a subtle curve upward for the notch
    path.quadraticBezierTo(
      notchCenter - notchRadius / 2, -notchTop,
      notchCenter, -notchTop,
    );
    path.quadraticBezierTo(
      notchCenter + notchRadius / 2, -notchTop,
      notchCenter + notchRadius, 0,
    );
    
    // Continue to right edge
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
