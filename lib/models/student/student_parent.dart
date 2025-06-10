import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/timestamp/timestamp_model.dart';

class StudentParent {
  final String id;
  final String parentId;
  final String studentId;
  final String relationshipType;
  final Timestamps timestamps;

  StudentParent({
    this.id = '',
    required this.parentId,
    required this.studentId,
    required this.relationshipType,
    required this.timestamps,
  });

  factory StudentParent.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return StudentParent(
      id: doc.id,
      parentId: data['parentId'] ?? '',
      studentId: data['studentId'] ?? '',
      relationshipType: data['relationshipType'] ?? '',
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
      'parentId': parentId,
      'studentId': studentId,
      'relationshipType': relationshipType,
      'createdAt': Timestamp.fromDate(timestamps.createdAt),
      'updatedAt': Timestamp.fromDate(timestamps.updatedAt),
      if (timestamps.deletedAt != null)
        'deletedAt': Timestamp.fromDate(timestamps.deletedAt!),
    };
  }

  StudentParent copyWith({
    String? id,
    String? parentId,
    String? studentId,
    String? relationshipType,
    Timestamps? timestamps,
  }) {
    return StudentParent(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      studentId: studentId ?? this.studentId,
      relationshipType: relationshipType ?? this.relationshipType,
      timestamps: timestamps ?? this.timestamps,
    );
  }
}
