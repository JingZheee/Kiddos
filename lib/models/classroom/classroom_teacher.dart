import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/timestamp/timestamp_model.dart';

class ClassroomTeacher extends Timestamps {
  final String classroomId;
  final String teacherId;

  ClassroomTeacher({
    required this.classroomId,
    required this.teacherId,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory ClassroomTeacher.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ClassroomTeacher(
      classroomId: data['classroomId'] ?? '',
      teacherId: data['teacherId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'classroomId': classroomId,
      'teacherId': teacherId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (deletedAt != null) 'deletedAt': Timestamp.fromDate(deletedAt!),
    };
  }

  ClassroomTeacher copyWith({
    String? classroomId,
    String? teacherId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ClassroomTeacher(
      classroomId: classroomId ?? this.classroomId,
      teacherId: teacherId ?? this.teacherId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
