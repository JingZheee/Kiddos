import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/ui_constants.dart';

class CameraGuideWidget extends StatelessWidget {
  final String studentName;
  final VoidCallback onTakePhoto;
  final VoidCallback onCancel;

  const CameraGuideWidget({
    Key? key,
    required this.studentName,
    required this.onTakePhoto,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(UIConstants.spacing16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onCancel,
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Taking photo for $studentName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 44), // Balance the close button
                ],
              ),
            ),
            
            // Camera Guidelines
            Expanded(
              child: Stack(
                children: [
                  // Main content area
                  Center(
                    child: Container(
                      width: 250,
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withOpacity(0.8),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          // Corner guides
                          ...List.generate(4, (index) {
                            return Positioned(
                              top: index < 2 ? 8 : null,
                              bottom: index >= 2 ? 8 : null,
                              left: index % 2 == 0 ? 8 : null,
                              right: index % 2 == 1 ? 8 : null,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: index < 2
                                        ? BorderSide(color: AppTheme.primaryColor, width: 3)
                                        : BorderSide.none,
                                    bottom: index >= 2
                                        ? BorderSide(color: AppTheme.primaryColor, width: 3)
                                        : BorderSide.none,
                                    left: index % 2 == 0
                                        ? BorderSide(color: AppTheme.primaryColor, width: 3)
                                        : BorderSide.none,
                                    right: index % 2 == 1
                                        ? BorderSide(color: AppTheme.primaryColor, width: 3)
                                        : BorderSide.none,
                                  ),
                                ),
                              ),
                            );
                          }),
                          
                          // Center guide
                          Center(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primaryColor.withOpacity(0.6),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.person,
                                color: AppTheme.primaryColor.withOpacity(0.6),
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Instructions
                  Positioned(
                    top: 50,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '📸 Position the child\'s face in the center\n👀 Ensure good lighting\n✋ Child should look at camera',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom Controls
            Container(
              padding: const EdgeInsets.all(UIConstants.spacing20),
              child: Column(
                children: [
                  // Tips
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.yellow.shade300,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This photo will be sent to ${studentName}\'s parent as arrival evidence',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: UIConstants.spacing20),
                  
                  // Camera Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                        ),
                        child: GestureDetector(
                          onTap: onTakePhoto,
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: AppTheme.primaryColor,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
