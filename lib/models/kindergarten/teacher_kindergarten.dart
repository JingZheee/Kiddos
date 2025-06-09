import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/timestamp/timestamp_model.dart';

class TeacherKindergarten {
  final String teacherId;
  final String kindergartenId;
  final Timestamps timestamps;

  TeacherKindergarten({
    required this.teacherId,
    required this.kindergartenId,
    required this.timestamps,
  });

  factory TeacherKindergarten.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TeacherKindergarten(
      teacherId: data['teacherId'] ?? '',
      kindergartenId: data['kindergartenId'] ?? '',
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
      'teacherId': teacherId,
      'kindergartenId': kindergartenId,
      'createdAt': Timestamp.fromDate(timestamps.createdAt),
      'updatedAt': Timestamp.fromDate(timestamps.updatedAt),
      if (timestamps.deletedAt != null)
        'deletedAt': Timestamp.fromDate(timestamps.deletedAt!),
    };
  }

  TeacherKindergarten copyWith({
    String? teacherId,
    String? kindergartenId,
    Timestamps? timestamps,
  }) {
    return TeacherKindergarten(
      teacherId: teacherId ?? this.teacherId,
      kindergartenId: kindergartenId ?? this.kindergartenId,
      timestamps: timestamps ?? this.timestamps,
    );
  }
}
