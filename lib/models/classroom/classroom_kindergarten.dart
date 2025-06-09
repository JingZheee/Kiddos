import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/timestamp/timestamp_model.dart';

class ClassroomKindergarten extends Timestamps {
  final String classroomId;
  final String kindergartenId;

  ClassroomKindergarten({
    required this.classroomId,
    required this.kindergartenId,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory ClassroomKindergarten.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ClassroomKindergarten(
      classroomId: data['classroomId'] ?? '',
      kindergartenId: data['kindergartenId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'classroomId': classroomId,
      'kindergartenId': kindergartenId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (deletedAt != null) 'deletedAt': Timestamp.fromDate(deletedAt!),
    };
  }

  ClassroomKindergarten copyWith({
    String? classroomId,
    String? kindergartenId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ClassroomKindergarten(
      classroomId: classroomId ?? this.classroomId,
      kindergartenId: kindergartenId ?? this.kindergartenId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
