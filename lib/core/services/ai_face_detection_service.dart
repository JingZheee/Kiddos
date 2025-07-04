import 'package:flutter/foundation.dart';
import '../../models/student/student.dart';
import '../../models/timestamp/timestamp_model.dart';

class AiFaceDetectionService {
  static final AiFaceDetectionService _instance = AiFaceDetectionService._internal();
  
  factory AiFaceDetectionService() {
    return _instance;
  }
  
  AiFaceDetectionService._internal();

  /// Simulated AI face detection and student identification with multiple matches
  /// Returns students ordered by confidence score (highest first)
  Future<MultipleStudentDetectionResult> detectAndIdentifyStudents({
    required String imagePath,
    required List<Student> availableStudents,
  }) async {
    try {
      // Simulate processing time
      await Future.delayed(const Duration(seconds: 1));

      // For demo purposes, always succeed and return matches
      List<Student> studentsToMatch = availableStudents.isNotEmpty 
          ? availableStudents 
          : _createDemoStudents();

      // Simulate multiple student matches with decreasing confidence
      final List<StudentMatch> matches = [];
      final List<Student> shuffledStudents = List.from(studentsToMatch)..shuffle();
      
      // Take up to 3 students for matching simulation
      final int maxMatches = shuffledStudents.length > 3 ? 3 : shuffledStudents.length;
      
      for (int i = 0; i < maxMatches; i++) {
        // Simulate confidence scores: 95%, 85%, 75% for first, second, third matches
        double confidence = 0.95 - (i * 0.10);
        matches.add(StudentMatch(
          student: shuffledStudents[i],
          confidenceScore: confidence,
        ));
      }

      // Sort by confidence (highest first)
      matches.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));

      return MultipleStudentDetectionResult(
        isSuccessful: true,
        errorMessage: null,
        studentMatches: matches,
      );

    } catch (e) {
      debugPrint('AI Face Detection Error: $e');
      // Even on error, return demo matches for testing
      return MultipleStudentDetectionResult(
        isSuccessful: true,
        errorMessage: null,
        studentMatches: _createDemoMatches(),
      );
    }
  }

  List<Student> _createDemoStudents() {
    return [
      Student(
        id: 'demo1',
        firstName: 'Alex',
        lastName: 'Demo',
        dateOfBirth: DateTime(2018, 1, 1),
        timestamps: Timestamps.now(),
      ),
      Student(
        id: 'demo2',
        firstName: 'Sam',
        lastName: 'Test',
        dateOfBirth: DateTime(2018, 2, 1),
        timestamps: Timestamps.now(),
      ),
      Student(
        id: 'demo3',
        firstName: 'Jordan',
        lastName: 'Example',
        dateOfBirth: DateTime(2018, 3, 1),
        timestamps: Timestamps.now(),
      ),
    ];
  }

  List<StudentMatch> _createDemoMatches() {
    final demoStudents = _createDemoStudents();
    return [
      StudentMatch(student: demoStudents[0], confidenceScore: 0.95),
      StudentMatch(student: demoStudents[1], confidenceScore: 0.85),
      StudentMatch(student: demoStudents[2], confidenceScore: 0.75),
    ];
  }

  /// Legacy method for backwards compatibility
  Future<StudentDetectionResult> detectAndIdentifyStudent({
    required String imagePath,
    required List<Student> availableStudents,
  }) async {
    final result = await detectAndIdentifyStudents(
      imagePath: imagePath,
      availableStudents: availableStudents,
    );
    
    if (result.isSuccessful && result.studentMatches.isNotEmpty) {
      final topMatch = result.studentMatches.first;
      return StudentDetectionResult(
        isSuccessful: true,
        errorMessage: null,
        detectedStudent: topMatch.student,
        confidenceScore: topMatch.confidenceScore,
      );
    }
    
    return StudentDetectionResult(
      isSuccessful: false,
      errorMessage: result.errorMessage ?? 'No matches found',
      detectedStudent: null,
      confidenceScore: 0.0,
    );
  }

  /// Get recommended photo guidelines for best AI detection results
  List<String> getPhotoGuidelines() {
    return [
      'Ensure the student is facing the camera directly',
      'Take the photo in good lighting conditions',
      'Make sure the face is clearly visible and not obscured',
      'Avoid shadows on the face',
      'Hold the camera steady and take a clear, focused photo',
      'Ensure the student is the only person in the frame',
    ];
  }

  /// Check if AI detection is available/enabled
  bool isAiDetectionAvailable() {
    // In real implementation, this might check for:
    // - Internet connectivity for cloud-based AI
    // - Local model availability
    // - Device capabilities
    return true;
  }
}

class StudentDetectionResult {
  final bool isSuccessful;
  final String? errorMessage;
  final Student? detectedStudent;
  final double confidenceScore;

  StudentDetectionResult({
    required this.isSuccessful,
    required this.errorMessage,
    required this.detectedStudent,
    required this.confidenceScore,
  });

  String get confidencePercentage => '${(confidenceScore * 100).toStringAsFixed(1)}%';
}

class StudentMatch {
  final Student student;
  final double confidenceScore;

  StudentMatch({
    required this.student,
    required this.confidenceScore,
  });

  String get confidencePercentage => '${(confidenceScore * 100).toStringAsFixed(1)}%';
}

class MultipleStudentDetectionResult {
  final bool isSuccessful;
  final String? errorMessage;
  final List<StudentMatch> studentMatches;

  MultipleStudentDetectionResult({
    required this.isSuccessful,
    required this.errorMessage,
    required this.studentMatches,
  });

  bool get hasMatches => studentMatches.isNotEmpty;
  StudentMatch? get topMatch => hasMatches ? studentMatches.first : null;
}
