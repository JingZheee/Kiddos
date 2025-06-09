import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/timestamp/timestamp_model.dart';

class TeacherKindergarten extends Timestamps {
  final String teacherId;
  final String kindergartenId;

  TeacherKindergarten({
    required this.teacherId,
    required this.kindergartenId,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory TeacherKindergarten.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TeacherKindergarten(
      teacherId: data['teacherId'] ?? '',
      kindergartenId: data['kindergartenId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'teacherId': teacherId,
      'kindergartenId': kindergartenId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (deletedAt != null) 'deletedAt': Timestamp.fromDate(deletedAt!),
    };
  }

  TeacherKindergarten copyWith({
    String? teacherId,
    String? kindergartenId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return TeacherKindergarten(
      teacherId: teacherId ?? this.teacherId,
      kindergartenId: kindergartenId ?? this.kindergartenId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
