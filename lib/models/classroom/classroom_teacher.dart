import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/timestamp/timestamp_model.dart';

class ClassroomTeacher {
  final String classroomId;
  final String teacherId;
  final Timestamps timestamps;

  ClassroomTeacher({
    required this.classroomId,
    required this.teacherId,
    required this.timestamps,
  });

  factory ClassroomTeacher.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ClassroomTeacher(
      classroomId: data['classroomId'] ?? '',
      teacherId: data['teacherId'] ?? '',
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
      'classroomId': classroomId,
      'teacherId': teacherId,
      'createdAt': Timestamp.fromDate(timestamps.createdAt),
      'updatedAt': Timestamp.fromDate(timestamps.updatedAt),
      if (timestamps.deletedAt != null)
        'deletedAt': Timestamp.fromDate(timestamps.deletedAt!),
    };
  }

  ClassroomTeacher copyWith({
    String? classroomId,
    String? teacherId,
    Timestamps? timestamps,
  }) {
    return ClassroomTeacher(
      classroomId: classroomId ?? this.classroomId,
      teacherId: teacherId ?? this.teacherId,
      timestamps: timestamps ?? this.timestamps,
    );
  }
}
