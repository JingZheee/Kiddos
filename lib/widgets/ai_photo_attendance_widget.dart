import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../core/theme/app_theme.dart';
import '../core/constants/ui_constants.dart';
import '../core/services/ai_face_detection_service.dart';
import '../models/student/student.dart';

class AiPhotoAttendanceWidget extends StatefulWidget {
  final List<Student> availableStudents;
  final Function(Student, XFile) onStudentIdentified;
  final VoidCallback onCancel;

  const AiPhotoAttendanceWidget({
    super.key,
    required this.availableStudents,
    required this.onStudentIdentified,
    required this.onCancel,
  });

  @override
  State<AiPhotoAttendanceWidget> createState() => _AiPhotoAttendanceWidgetState();
}

class _AiPhotoAttendanceWidgetState extends State<AiPhotoAttendanceWidget> {
  final ImagePicker _picker = ImagePicker();
  final AiFaceDetectionService _aiService = AiFaceDetectionService();
  
  XFile? _capturedPhoto;
  bool _isProcessing = false;
  StudentDetectionResult? _detectionResult;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
      ),
      child: Container(
        padding: const EdgeInsets.all(UIConstants.spacing20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: UIConstants.spacing16),
            
            if (_capturedPhoto == null) ...[
              _buildPhotoGuidelines(),
              const SizedBox(height: UIConstants.spacing20),
              _buildCameraButton(),
            ] else if (_isProcessing) ...[
              _buildProcessingView(),
            ] else if (_detectionResult != null) ...[
              _buildResultView(),
            ],
            
            const SizedBox(height: UIConstants.spacing20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.smart_toy,
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
                'AI Photo Attendance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Text(
                'Take a photo to automatically identify the student',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoGuidelines() {
    final guidelines = _aiService.getPhotoGuidelines();
    
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        border: Border.all(
          color: Colors.blue.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Photo Guidelines',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...guidelines.map((guideline) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    guideline,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildCameraButton() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        color: AppTheme.primaryColor.withOpacity(0.05),
      ),
      child: InkWell(
        onTap: _takePhoto,
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Take Photo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            Text(
              'AI will identify the student',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(UIConstants.spacing24),
      child: Column(
        children: [
          // Photo preview
          if (_capturedPhoto != null) ...[
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(UIConstants.radiusMedium - 2),
                child: Image.file(
                  File(_capturedPhoto!.path),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: UIConstants.spacing16),
          ],
          
          // Processing indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
            ),
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Processing with AI...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Detecting face and identifying student',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final result = _detectionResult!;
    
    return Container(
      width: double.infinity,
      child: Column(
        children: [
          // Photo preview
          if (_capturedPhoto != null) ...[
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                border: Border.all(
                  color: result.isSuccessful 
                      ? Colors.green.withOpacity(0.5)
                      : Colors.red.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(UIConstants.radiusMedium - 2),
                child: Image.file(
                  File(_capturedPhoto!.path),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: UIConstants.spacing16),
          ],
          
          // Result container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(UIConstants.spacing16),
            decoration: BoxDecoration(
              color: result.isSuccessful 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
              border: Border.all(
                color: result.isSuccessful 
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  result.isSuccessful ? Icons.check_circle : Icons.error,
                  color: result.isSuccessful ? Colors.green : Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 12),
                
                if (result.isSuccessful && result.detectedStudent != null) ...[
                  Text(
                    'Student Identified!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${result.detectedStudent!.firstName} ${result.detectedStudent!.lastName}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Confidence: ${result.confidencePercentage}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ] else ...[
                  Text(
                    'Detection Failed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.errorMessage ?? 'Unable to identify student',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: widget.onCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: UIConstants.spacing12),
        
        if (_capturedPhoto == null) ...[
          // No buttons needed when no photo
        ] else if (_isProcessing) ...[
          // No action buttons during processing
        ] else if (_detectionResult?.isSuccessful == true) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                widget.onStudentIdentified(
                  _detectionResult!.detectedStudent!,
                  _capturedPhoto!,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Mark Present',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ] else ...[
          Expanded(
            child: ElevatedButton(
              onPressed: _retakePhoto,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front, // Better for selfies
        imageQuality: 85,
      );
      
      if (photo != null) {
        setState(() {
          _capturedPhoto = photo;
          _isProcessing = true;
          _detectionResult = null;
        });
        
        // Process with AI
        final result = await _aiService.detectAndIdentifyStudent(
          imagePath: photo.path,
          availableStudents: widget.availableStudents,
        );
        
        setState(() {
          _isProcessing = false;
          _detectionResult = result;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedPhoto = null;
      _detectionResult = null;
    });
  }
}
