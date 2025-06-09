import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/timestamp/timestamp_model.dart';

class ClassroomKindergarten {
  final String classroomId;
  final String kindergartenId;
  final Timestamps timestamps;

  ClassroomKindergarten({
    required this.classroomId,
    required this.kindergartenId,
    required this.timestamps,
  });

  factory ClassroomKindergarten.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ClassroomKindergarten(
      classroomId: data['classroomId'] ?? '',
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
      'classroomId': classroomId,
      'kindergartenId': kindergartenId,
      'createdAt': Timestamp.fromDate(timestamps.createdAt),
      'updatedAt': Timestamp.fromDate(timestamps.updatedAt),
    };
  }

  ClassroomKindergarten copyWith({
    String? classroomId,
    String? kindergartenId,
    Timestamps? timestamps,
  }) {
    return ClassroomKindergarten(
      classroomId: classroomId ?? this.classroomId,
      kindergartenId: kindergartenId ?? this.kindergartenId,
      timestamps: timestamps ?? this.timestamps,
    );
  }
}
