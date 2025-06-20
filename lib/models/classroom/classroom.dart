import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/timestamp/timestamp_model.dart';

class Classroom {
  final String id;
  final String name;
  final String? kindergartenId;
  final Timestamps timestamps;

  Classroom({
    required this.id,
    required this.name,
    this.kindergartenId,
    required this.timestamps,
  });

  factory Classroom.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Classroom(
      id: doc.id,
      name: data['name'] ?? '',
      kindergartenId: data['kindergartenId'],
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
      'name': name,
      'kindergartenId': kindergartenId,
      'createdAt': Timestamp.fromDate(timestamps.createdAt),
      'updatedAt': Timestamp.fromDate(timestamps.updatedAt),
      if (timestamps.deletedAt != null)
        'deletedAt': Timestamp.fromDate(timestamps.deletedAt!),
    };
  }

  Classroom copyWith({
    String? id,
    String? name,
    String? kindergartenId,
    Timestamps? timestamps,
  }) {
    return Classroom(
      id: id ?? this.id,
      name: name ?? this.name,
      kindergartenId: kindergartenId ?? this.kindergartenId,
      timestamps: timestamps ?? this.timestamps,
    );
  }
}
