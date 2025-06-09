import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/timestamp/timestamp_model.dart';

class StudentParent extends Timestamps {
  final String parentId;
  final String studentId;
  final String relationshipType;

  StudentParent({
    required this.parentId,
    required this.studentId,
    required this.relationshipType,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory StudentParent.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return StudentParent(
      parentId: data['parentId'] ?? '',
      studentId: data['studentId'] ?? '',
      relationshipType: data['relationshipType'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'parentId': parentId,
      'studentId': studentId,
      'relationshipType': relationshipType,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (deletedAt != null) 'deletedAt': Timestamp.fromDate(deletedAt!),
    };
  }

  StudentParent copyWith({
    String? parentId,
    String? studentId,
    String? relationshipType,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return StudentParent(
      parentId: parentId ?? this.parentId,
      studentId: studentId ?? this.studentId,
      relationshipType: relationshipType ?? this.relationshipType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
