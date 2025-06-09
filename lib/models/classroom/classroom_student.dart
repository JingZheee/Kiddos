import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/timestamp/timestamp_model.dart';

class ClassroomStudent extends Timestamps {
  final String studentId;
  final String classroomId;

  ClassroomStudent({
    required this.studentId,
    required this.classroomId,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory ClassroomStudent.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ClassroomStudent(
      studentId: data['studentId'] ?? '',
      classroomId: data['classroomId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'classroomId': classroomId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (deletedAt != null) 'deletedAt': Timestamp.fromDate(deletedAt!),
    };
  }

  ClassroomStudent copyWith({
    String? studentId,
    String? classroomId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ClassroomStudent(
      studentId: studentId ?? this.studentId,
      classroomId: classroomId ?? this.classroomId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
