import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/timestamp/timestamp_model.dart';

class Student extends Timestamps {
  final String id;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String? gender;
  final String? kindergartenId;
  final String? classroomId;
  final String? profilePictureUrl;
  final DateTime? admissionDate;

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
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
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
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
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
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (deletedAt != null) 'deletedAt': Timestamp.fromDate(deletedAt!),
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
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
