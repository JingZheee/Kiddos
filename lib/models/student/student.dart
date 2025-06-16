import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/timestamp/timestamp_model.dart';

class Student {
  final String id;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String? gender;
  final String? kindergartenId;
  final String? classroomId;
  final String? profilePictureUrl;
  final DateTime? admissionDate;
  final Timestamps timestamps;

  Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    this.gender,
    this.kindergartenId,
    this.classroomId,
    this.profilePictureUrl,
    this.admissionDate,
    required this.timestamps,
  });

  factory Student.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      dateOfBirth: (data['dateOfBirth'] as Timestamp).toDate(),
      gender: data['gender'],
      kindergartenId: data['kindergartenId'],
      classroomId: data['classroomId'],
      profilePictureUrl: data['profilePictureUrl'],
      admissionDate: (data['admissionDate'] as Timestamp?)?.toDate(),
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
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'gender': gender,
      'kindergartenId': kindergartenId,
      'classroomId': classroomId,
      'profilePictureUrl': profilePictureUrl,
      'admissionDate':
          admissionDate != null ? Timestamp.fromDate(admissionDate!) : null,
      'createdAt': Timestamp.fromDate(timestamps.createdAt),
      'updatedAt': Timestamp.fromDate(timestamps.updatedAt),
      if (timestamps.deletedAt != null)
        'deletedAt': Timestamp.fromDate(timestamps.deletedAt!),
    };
  }

  Student copyWith({
    String? id,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? gender,
    String? kindergartenId,
    String? classroomId,
    String? profilePictureUrl,
    DateTime? admissionDate,
    Timestamps? timestamps,
  }) {
    return Student(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      kindergartenId: kindergartenId ?? this.kindergartenId,
      classroomId: classroomId ?? this.classroomId,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      admissionDate: admissionDate ?? this.admissionDate,
      timestamps: timestamps ?? this.timestamps,
    );
  }
}
