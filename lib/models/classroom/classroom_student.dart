import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/timestamp/timestamp_model.dart';

class ClassroomStudent {
  final String studentId;
  final String classroomId;
  final Timestamps timestamps;

  ClassroomStudent({
    required this.studentId,
    required this.classroomId,
    required this.timestamps,
  });

  factory ClassroomStudent.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ClassroomStudent(
      studentId: data['studentId'] ?? '',
      classroomId: data['classroomId'] ?? '',
      timestamps: data['timestamps'] != null
          ? Timestamps.fromJson(data['timestamps'])
          : _timestampsFromFirestore(data),
    );
  }

  static Timestamps _timestampsFromFirestore(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    final updatedAt = data['updatedAt'];
    final deletedAt = data['deletedAt'];
    final now = DateTime.now();

    return Timestamps(
      createdAt: createdAt is Timestamp ? createdAt.toDate() : now,
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : now,
      deletedAt: deletedAt is Timestamp ? deletedAt.toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'classroomId': classroomId,
      'createdAt': Timestamp.fromDate(timestamps.createdAt),
      'updatedAt': Timestamp.fromDate(timestamps.updatedAt),
      if (timestamps.deletedAt != null)
        'deletedAt': Timestamp.fromDate(timestamps.deletedAt!),
    };
  }

  ClassroomStudent copyWith({
    String? studentId,
    String? classroomId,
    Timestamps? timestamps,
  }) {
    return ClassroomStudent(
      studentId: studentId ?? this.studentId,
      classroomId: classroomId ?? this.classroomId,
      timestamps: timestamps ?? this.timestamps,
    );
  }
}
